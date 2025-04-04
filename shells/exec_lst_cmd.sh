#!/bin/bash
# Store the provided command

# Get the number of panes in the current tmux window
pane_count=$(tmux display-message -p '#{window_panes}')

# Get the index of the current pane
current_pane=$(tmux display-message -p '#{pane_index}')

# Initialize target_pane with -1 (default no target)
target_pane=-1

PREV_TMUX_COMMAND=`cat /tmp/prev-tmux-command`

if [ "$pane_count" -gt 1 ]; then
    # If there are multiple panes, find a pane that's not the current one
    tmux list-panes -F "#{pane_index}" | while read -r index; do
        if [ "$index" -ne "$current_pane" ]; then
            tmux send-keys -t "$index" "$PREV_TMUX_COMMAND" Enter
            echo "$1" > /tmp/prev-tmux-command
            exit 0
        fi
    done
else
    # If only one pane exists, split the current pane horizontally
    tmux split-window -h
    # Get the index of the newly created pane
    new_pane=$(tmux display-message -p '#{pane_index}')
    # Send the command to the new pane and execute it
    tmux send-keys -t "$new_pane" "$PREV_TMUX_COMMAND" Enter
    echo "$1" > /tmp/prev-tmux-command
fi
