; AutoHotkey v2 script for PICO-8 GIF recording and character movement
#SingleInstance Force
SendMode("Input")

; Wait for script to load
Sleep(1000)

; Check if PICO-8 is running
if (!ProcessExist("pico8.exe")) {
    MsgBox("PICO-8 is not running!", "Error")
    ExitApp()
}

; Activate PICO-8 window
WinActivate("ahk_exe pico8.exe")
try {
    WinWaitActive("ahk_exe pico8.exe", , 3)
} catch {
    MsgBox("Could not activate PICO-8 window!", "Error")
    ExitApp()
}

Sleep(1000)  ; Wait for window to be ready

; START GIF RECORDING with Ctrl+8
Send("^8")
Sleep(2000)  ; Wait for recording to start

; Move character through walk cycle demonstration
; Move RIGHT to show walk animation
Loop 8 {
    Send("{Right down}")
    Sleep(100)
    Send("{Right up}")
    Sleep(150)  ; Slower for better animation visibility
}

Sleep(500)

; Move DOWN 
Loop 4 {
    Send("{Down down}")
    Sleep(100)
    Send("{Down up}")
    Sleep(150)
}

Sleep(500)

; Move LEFT to show walk animation in opposite direction
Loop 8 {
    Send("{Left down}")
    Sleep(100)
    Send("{Left up}")
    Sleep(150)
}

Sleep(500)

; Move UP
Loop 4 {
    Send("{Up down}")
    Sleep(100)
    Send("{Up up}")
    Sleep(150)
}

Sleep(1000)  ; Pause to show idle animation

; STOP GIF RECORDING with Ctrl+9
Send("^9")
Sleep(2000)  ; Wait for recording to finish


ExitApp()