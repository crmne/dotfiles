#!/bin/sh
# Run with sudo: lets memory protection reach the agent sessions.
set -e
install -D -m 644 /home/carmine/.local/share/agents-memory-low/user-slice.conf /etc/systemd/system/user.slice.d/50-agents-memory-low.conf
install -D -m 644 /home/carmine/.local/share/agents-memory-low/user-slice.conf /etc/systemd/system/user-1000.slice.d/50-agents-memory-low.conf
install -D -m 644 /home/carmine/.local/share/agents-memory-low/user-service.conf /etc/systemd/system/user@1000.service.d/50-agents-memory-low.conf
systemctl daemon-reload
