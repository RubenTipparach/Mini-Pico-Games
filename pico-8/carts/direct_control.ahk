; Direct AutoHotkey v2 script to control PICO-8 immediately
#SingleInstance Force
SendMode("Input")

; Wait a moment for script to load
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

; Move character - RIGHT 5 times
Loop 5 {
    Send("{Right down}")
    Sleep(100)
    Send("{Right up}")
    Sleep(200)
}

Sleep(500)

; Move character - DOWN 3 times
Loop 3 {
    Send("{Down down}")
    Sleep(100)
    Send("{Down up}")
    Sleep(200)
}

Sleep(500)

; Move character - LEFT 4 times  
Loop 4 {
    Send("{Left down}")
    Sleep(100)
    Send("{Left up}")
    Sleep(200)
}

Sleep(500)

; Take screenshot with Ctrl+6
Send("^6")
Sleep(2000)

; Check for screenshots
RunWait('cmd.exe /c "dir screenshots\*.png /b"', , "Hide")


ExitApp()