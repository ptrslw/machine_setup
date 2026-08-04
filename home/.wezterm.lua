-- WezTerm config (Lua). Symlinked to ~/.wezterm.lua.
--
-- Architecture: WezTerm is the GPU terminal; tmux owns multiplexing.
-- We deliberately define no leader key and no pane/split bindings here, so
-- Ctrl+b and friends pass straight through to tmux. Fighting two multiplexers
-- for the same keys is worse than picking one — and tmux also works over SSH.

local wezterm = require 'wezterm'

-- config_builder gives clearer error messages on newer WezTerm versions.
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Appearance: opacity matched to the former iTerm2 Default profile
-- (transparency 0.26 → opacity 0.74, blur ~3).
config.window_background_opacity = 0.74
config.macos_window_background_blur = 3

config.color_scheme = 'rose-pine-moon'
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 12.0

-- Minimal chrome: plain tab bar, hidden when there is only one tab.
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Always start inside tmux, attaching to (or creating) a shared "main" session.
-- -A = attach-or-create: every new WezTerm window joins the same session.
--
-- Trade-off: with default_prog set to tmux, exiting tmux closes the WezTerm
-- pane. Detach with prefix+d if you want to keep the pane.
config.default_prog = {
  os.getenv 'SHELL' or '/bin/zsh',
  '-lc',
  'tmux new-session -A -s main',
}

return config
