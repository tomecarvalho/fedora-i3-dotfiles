## Caffeine (keep presence)

This i3blocks module toggles a tiny daemon that prevents idle by gently jiggling the mouse every minute.

- Enabled icon: 󰅶
- Disabled icon: 󰾪
- Left-click: toggle on/off

### Files

- `caffeine` — main block script, prints icon/colour and handles clicks
- `caffeine-daemon.sh` — background process that moves the mouse by 1px every 60s
- `i3blocks.conf` — block entry wiring to `caffeine`

### Requirements

- `xdotool` (for mouse movement)

### Customisation

You can customise the icons and colors via environment variables in the block definition:

- `ICON_ON` (default 󰅶)
- `ICON_OFF` (default 󰾪)
- `COLOR_ON` (default #b8bb26)
- `COLOR_OFF` (default #7a7566)

Example:

	[caffeine]
	command=$SCRIPT_DIR/caffeine
	interval=5
	ICON_ON=󰅶
	ICON_OFF=󰾪
	COLOR_ON=#b8bb26
	COLOR_OFF=#7a7566

### Notes

- The daemon is detected via `pgrep -f caffeine-daemon.sh`. If you run it manually, the block will still reflect the status.
- Killing the daemon elsewhere updates the icon on the next interval or click.

