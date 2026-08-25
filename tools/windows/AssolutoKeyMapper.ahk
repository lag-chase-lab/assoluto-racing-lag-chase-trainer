#Requires AutoHotkey v2.0
#SingleInstance Force

; Remap only while the Android Emulator window is active.
#HotIf WinActive("ahk_exe qemu-system-x86_64.exe") || WinActive("ahk_exe qemu-system-aarch64.exe")
a::Left
d::Right
#HotIf
