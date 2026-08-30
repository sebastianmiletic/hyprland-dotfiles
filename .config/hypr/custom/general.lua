hl.config({
    general = {
        -- A little more breathing room around tiled windows and screen edges.
        gaps_out = 10,
    },
    input = {
        kb_layout = "us",
        kb_options = "ctrl:swap_lalt_lctl",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        follow_mouse = 1,
        off_window_axis_events = 2,
        sensitivity = 0,
        accel_profile = "flat",
        -- Allow input devices to work without restrictions
        float_switch_override_focus = 0,
        -- Mouse settings for smooth tracking
        mouse_refocus = true,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7,
            tap_to_click = true,
            drag_lock = false,
            tap_and_drag = true,
        }
    },
    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1,
        no_hardware_cursors = true,
        enable_hyprcursor = false,
        warp_on_change_workspace = 2,
        no_warps = true,
        hide_on_key_press = false
    },
    -- Keep a light blur for shell surfaces without making ordinary app redraws expensive.
    decoration = {
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 8,
            passes = 1,
            brightness = 1,
            noise = 0.02,
            contrast = 0.89,
            vibrancy = 0.25,
            vibrancy_darkness = 0.25,
            popups = false,
            popups_ignorealpha = 0.6,
            input_methods = false,
            input_methods_ignorealpha = 0.8,
            ignore_opacity = true  -- KEY: blur behind transparent kitty windows
        },
        shadow = {
            enabled = true,
            range = 10,
            render_power = 3,
            color = "rgba(00000018)"
        }
    },
    debug = {
        -- Variable frame rate stops Hyprland continuously rendering an idle desktop.
        vfr = true
    },
    misc = {
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        focus_on_activate = true,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
    }
})

-- Device-specific rules for mice/trackpads
-- Generic mouse: standard sensitivity, no accel
hl.device({
    name = "*mouse*",
    sensitivity = 0,
    accel_profile = "flat",
    natural_scroll = false,
})

-- Generic trackpad
hl.device({
    name = "*touchpad*",
    sensitivity = 0,
    accel_profile = "flat",
    natural_scroll = true,
    tap_to_click = true,
    clickfinger_behavior = true,
    disable_while_typing = true,
    scroll_factor = 0.7,
})

-- Wacom tablets (finger + pen)
hl.device({
    name = "*wacom*finger*",
    enabled = true,
    sensitivity = 0,
    natural_scroll = false,
})
hl.device({
    name = "*wacom*pen*",
    enabled = true,
    sensitivity = 0,
})

-- Bluetooth input devices (allow all)
hl.device({
    name = "*bluetooth*",
    enabled = true,
    sensitivity = 0,
    accel_profile = "flat",
})

-- Generic USB HID keyboards/mice
hl.device({
    name = "*hid*",
    enabled = true,
})

-- Clean, smooth animations for windows (terminals, apps) and layers (menus, popups)
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3.2,
    bezier = "emphasizedDecel",
    style = "popin 94%"
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 2.5,
    bezier = "emphasizedDecel",
    style = "popin 96%"
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 3.5,
    bezier = "emphasizedDecel",
    style = "slide"
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 2.5,
    bezier = "standardDecel"
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 2,
    bezier = "standardDecel"
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 2.5,
    bezier = "emphasizedDecel",
    style = "popin 97%"
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 2,
    bezier = "menu_accel",
    style = "popin 97%"
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 10,
    bezier = "standardDecel"
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 6,
    bezier = "menu_decel",
    style = "slide"
})
hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 2.5,
    bezier = "emphasizedDecel",
    style = "slidevert"
})
hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 1.5,
    bezier = "emphasizedAccel",
    style = "slidevert"
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 0.5,
    bezier = "menu_decel"
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 2.5,
    bezier = "stall"
})
