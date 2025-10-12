#!/usr/bin/env sh

# Start gnome-keyring-daemon and dump its environment into a file
eval $(/usr/bin/gnome-keyring-daemon --start --components=secrets,ssh --daemonize)

# Save the environment variables so login shells & GUI apps can pick them up
echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.gnome-keyring-env
echo "export GPG_AGENT_INFO=$GPG_AGENT_INFO" >> ~/.gnome-keyring-env
echo "export DISPLAY=$DISPLAY" >> ~/.gnome-keyring-env