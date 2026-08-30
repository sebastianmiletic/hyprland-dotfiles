#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:?Gemini API key is unavailable}"

umask 077
image_path="$(mktemp --suffix=.png /tmp/quickshell-screen-answer.XXXXXX)"
image_base64_path="$(mktemp /tmp/quickshell-screen-answer-base64.XXXXXX)"
payload_path="$(mktemp --suffix=.json /tmp/quickshell-screen-answer.XXXXXX)"
response_path="$(mktemp --suffix=.json /tmp/quickshell-screen-answer.XXXXXX)"
curl_config="$(mktemp /tmp/quickshell-screen-answer-curl.XXXXXX)"
trap 'rm -f "$image_path" "$image_base64_path" "$payload_path" "$response_path" "$curl_config"' EXIT
model_router="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/ai/model-quota-router.sh"

# Prefer the Wayland primary selection. This is the text currently highlighted
# with the mouse, even when it was not copied with Ctrl+C.
selected_text="$(wl-paste --primary --no-newline 2>/dev/null | head -c 12000 || true)"

if [[ -n "${selected_text//[[:space:]]/}" ]]; then
    prompt='Treat the selected text below as the user question and answer it directly. Output clean, natural, human-readable plain text only. For multiple-choice questions, output only each correct option letter in reading order, separated by |. For other questions, give a complete concise answer in at most 30 words unless the question explicitly requires more. Never use markdown, code fences, LaTeX delimiters, or terminal prompt characters. Selected question:'
    jq -n \
        --arg prompt "$prompt" \
        --arg selection "$selected_text" \
        '{
            contents: [{
                role: "user",
                parts: [{text: ($prompt + "\n\n" + $selection)}]
            }],
            generationConfig: {
                temperature: 0.1,
                maxOutputTokens: 240
            }
        }' > "$payload_path"
else
    grim "$image_path"
    base64 -w0 "$image_path" > "$image_base64_path"
    prompt='Analyze the screenshot and output clean, natural, human-readable plain text only. For multiple-choice questions, output only each correct option letter in reading order. Use | between answers, for example A|C. Never include numbers, option text, punctuation, explanations, or incomplete entries. For a non-multiple-choice question requesting several answers, output every complete answer separated by |. Otherwise output one complete direct answer in at most 20 words. Preserve requested quotations word for word. Never use dollar signs, LaTeX delimiters, markdown, code fences, or terminal prompt characters; write mathematics and commands as ordinary readable text. If there is no answerable question, output a useful summary in at most 12 words.'
    jq -n \
        --arg prompt "$prompt" \
        --rawfile image "$image_base64_path" \
        '{
            contents: [{
                role: "user",
                parts: [
                    {text: $prompt},
                    {inline_data: {mime_type: "image/png", data: $image}}
                ]
            }],
            generationConfig: {
                temperature: 0.1,
                maxOutputTokens: 160
            }
        }' > "$payload_path"
fi

printf 'header = "x-goog-api-key: %s"\n' "$API_KEY" > "$curl_config"

request_succeeded=false
while model="$(bash "$model_router" next screen 2>/dev/null)"; do
    http_code="$(curl --config "$curl_config" \
        --silent \
        --connect-timeout 10 \
        --max-time 45 \
        -H "Content-Type: application/json" \
        --data-binary "@${payload_path}" \
        "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent" \
        --output "$response_path" \
        --write-out '%{http_code}' 2>/dev/null || true)"

    if [[ "$http_code" =~ ^2 ]]; then
        request_succeeded=true
        break
    fi

    if [[ "$http_code" == 404 || "$http_code" == 429 ]]; then
        bash "$model_router" exhaust "$model"
        continue
    fi

    break
done

[[ "$request_succeeded" == true ]] || exit 1

answer="$(jq -r '[.candidates[0].content.parts[]?.text // empty] | join(" ")' "$response_path")"
answer="$(printf '%s' "$answer" | tr -d '$`' | tr '\n\r\t' '   ' | tr -s ' ' | sed -E 's/\\\(|\\\)|\\\[|\\\]//g; s/^[[:space:]]*//; s/[[:space:]]*$//')"

[[ -n "$answer" ]] || exit 1
printf '%.600s\n' "$answer"
