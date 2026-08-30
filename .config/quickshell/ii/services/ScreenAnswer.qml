pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property string answer: ""
    property bool busy: false
    property bool queued: false
    property var answerParts: []
    property int answerPartIndex: 0
    property int displayedSteps: 0
    property bool multipleAnswerMode: false
    readonly property string displayText: busy
        ? "…"
        : (answerParts.length ? String(answerParts[answerPartIndex]) : "")

    function clearAnswer() {
        answerStepTimer.stop();
        clearAnswerTimer.stop();
        root.answer = "";
        root.answerParts = [];
        root.answerPartIndex = 0;
        root.displayedSteps = 0;
        root.multipleAnswerMode = false;
    }

    function showAnswer(text) {
        root.answer = text;
        const separatedAnswers = text.split("|").map(part => part.trim()).filter(part => part.length);
        root.multipleAnswerMode = separatedAnswers.length > 1;
        root.answerParts = separatedAnswers.length > 1
            ? separatedAnswers
            : text.split(/\s+/).filter(word => word.length);
        root.answerPartIndex = 0;
        root.displayedSteps = 0;

        if (!root.answerParts.length) {
            root.clearAnswer();
            return;
        }

        // Show every word (or each pipe-separated answer) twice in 15 seconds.
        answerStepTimer.interval = root.multipleAnswerMode
            ? 900
            : Math.max(80, Math.floor(15000 / (root.answerParts.length * 2)));
        answerStepTimer.restart();
        clearAnswerTimer.restart();
    }

    function ask() {
        if (root.busy)
            return;

        if (!KeyringStorage.loaded) {
            root.queued = true;
            root.busy = true;
            KeyringStorage.fetchKeyringData();
            return;
        }

        root.startRequest();
    }

    function startRequest() {
        const apiKey = KeyringStorage.keyringData?.apiKeys?.gemini ?? "";
        root.queued = false;

        if (!apiKey.length) {
            root.busy = false;
            root.showAnswer("No API key");
            return;
        }

        root.clearAnswer();
        root.busy = true;
        answerProcess.running = true;
    }

    Connections {
        target: KeyringStorage

        function onLoadedChanged() {
            if (KeyringStorage.loaded && root.queued)
                root.startRequest();
        }
    }

    Process {
        id: answerProcess
        command: [
            "bash",
            FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/screen-answer.sh`)
        ]
        environment: ({
            API_KEY: KeyringStorage.keyringData?.apiKeys?.gemini ?? ""
        })

        stdout: StdioCollector {
            id: answerOutput
        }

        onExited: (exitCode, exitStatus) => {
            const text = answerOutput.text.trim();
            root.busy = false;
            root.showAnswer(exitCode === 0 && text.length ? text : "Answer unavailable");
        }
    }

    Timer {
        id: answerStepTimer
        repeat: true
        onTriggered: {
            root.displayedSteps++;
            if (root.displayedSteps >= root.answerParts.length * 2) {
                root.clearAnswer();
                return;
            }
            root.answerPartIndex = (root.answerPartIndex + 1) % root.answerParts.length;
        }
    }

    Timer {
        id: clearAnswerTimer
        interval: 15000
        onTriggered: root.clearAnswer()
    }

    GlobalShortcut {
        name: "screenAnswer"
        description: "Answer highlighted text, or the question visible on screen"
        onPressed: root.ask()
    }
}
