-- Custom window rules to override base rules
-- Terminals stay transparent, but skip compositor blur/shadows so typing and
-- scrolling do not trigger expensive full-window blur redraws.
hl.window_rule({
    match = {class = "kitty"},
    no_blur = true,
    no_shadow = true,
    border_size = 0
})

-- Brave: clearly visible glass effect while keeping fullscreen media opaque.
hl.window_rule({
    match = {class = "brave-browser"},
    opacity = "0.86 override 0.80 override 1.0 override",
    no_blur = false,
    no_shadow = true,
    border_size = 0
})

-- OpenCloud behaves like a normal maximized app: it fills the usable workspace
-- while keeping the desktop bar visible.
hl.window_rule({
    match = {class = "^opencloud$"},
    maximize = true,
    border_size = 0
})

-- TradingView fills the usable workspace without changing its Wayland buffer scale.
hl.window_rule({
    match = {class = "^TradingView$", title = "^.+ / .*$"},
    maximize = true,
    border_size = 0
})

-- Other terminals use the same low-overhead policy.
hl.window_rule({
    match = {class = "^(foot|alacritty|wezterm|ghostty)$"},
    no_blur = true,
    no_shadow = true,
    border_size = 0
})

-- These shell surfaces already draw opaque/material containers and gain no
-- useful detail from blurring the entire screen behind them.
hl.layer_rule({ match = { namespace = "quickshell:(bar|sidebarRight|wallpaperSelector)" }, blur = false })
