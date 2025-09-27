#!/bin/bash

# The terminal command to launch your btop instance.
# We use kitty with a specific class 'btop-special' to identify it later.
# You can change 'kitty' to your preferred terminal (e.g., alacritty, foot).
TERMINAL_CMD="kitty --class btop-special -e btop"

# Function to check and launch btop if a workspace is empty
check_and_launch() {
    # Give Hyprland a moment to process the closed window
    sleep 0.1

    # Get the active workspace's ID
    local active_workspace_id=$(hyprctl activeworkspace -j | jq -r ".id")

    # Count the number of clients on that workspace
    local client_count=$(hyprctl clients -j | jq -r "[.[] | select(.workspace.id == ${active_workspace_id})] | length")

    # If there are 0 clients, launch our special btop
    if [ "$client_count" -eq 0 ]; then
        ${TERMINAL_CMD} &
    fi
}

# Function to kill the special btop instance
kill_btop() {
    # pkill is used with the -f flag to match the entire command line,
    # ensuring we only kill OUR special btop, not one you opened manually.
    pkill -f "${TERMINAL_CMD}"
}

# Listen for Hyprland events using socat
socat -U - "unix-connect:/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" | while read -r event; do
    case ${event%%>>*} in
        # When a window is opened, kill our btop
        openwindow)
            kill_btop
            ;;
        # When a window is closed, check if the workspace is now empty
        closewindow)
            check_and_launch
            ;;
    esac
done