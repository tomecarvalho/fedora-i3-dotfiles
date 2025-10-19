Brightness (brightnessctl) i3blocks block
=========================================

Features
- Shows Nerd Font icon + brightness percentage using brightnessctl
- Scroll up/down to adjust by SCROLL_STEP (default 5%)
- Left click sets to LEFT_SET (default 70%), right click sets to RIGHT_SET (default 100%)
- Customizable icons via environment variables
- Optional DEVICE to target a specific backlight device (e.g., nvidia_wmi_ec_backlight)

Requirements
- brightnessctl
- A Nerd Font for the provided default icons

Configuration (in i3blocks config)
[brightnessctl]
interval=1
signal=3
# Optional overrides
# DEVICE=nvidia_wmi_ec_backlight
# SCROLL_STEP=5
# LEFT_SET=70
# RIGHT_SET=100
# BRIGHTNESS_ICONS=󰃚,󰃛,󰃜,󰃝,󰃞,󰃟,󰃠

Environment variables
- DEVICE: brightnessctl device (-d). Example: nvidia_wmi_ec_backlight
- SCROLL_STEP: Percentage step for scroll up/down. Default: 5
- LEFT_SET: Percentage to set on left click. Default: 70
- RIGHT_SET: Percentage to set on right click. Default: 100
- BRIGHTNESS_ICONS: Comma-separated list of 7 icons to use for levels
- BRIGHTNESS_ICON_1..7: Override individual icon slots (1-based)

Icon levels
The percentage is bucketed into 7 ranges: 0–14, 15–29, 30–44, 45–59, 60–74, 75–89, 90–100.

Notes
- This block is signal-aware; you can refresh it via: pkill -RTMIN+3 i3blocks
- Example i3 keybinds to refresh on brightness changes:
	bindsym XF86MonBrightnessUp exec brightnessctl set +10%
	bindsym XF86MonBrightnessUp --release exec pkill -RTMIN+3 i3blocks
	bindsym XF86MonBrightnessDown exec brightnessctl set 10%-
	bindsym XF86MonBrightnessDown --release exec pkill -RTMIN+3 i3blocks
