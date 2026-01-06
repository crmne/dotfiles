#!/bin/bash

show_system_menu() {
  case $(menu "System" "  Lock\n󱄄  Screensaver\n󰒲  Suspend\n➜] Logout\n󰜉  Restart\n󰐥  Shutdown") in
  *Lock*) omarchy-lock-screen ;;
  *Screensaver*) omarchy-launch-screensaver force ;;
  *Suspend*) systemctl suspend ;;
  *Logout*) loginctl kill-session ;;
  *Restart*) omarchy-cmd-reboot ;;
  *Shutdown*) omarchy-cmd-shutdown ;;
  *) back_to show_main_menu ;;
  esac
}
