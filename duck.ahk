#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1

; ==================== GLOBAL VARIABLES ====================
global MacroEnabled := false

; ==================== SYSTEM TRAY ====================
Menu, Tray, Icon, shell32.dll, 16
Menu, Tray, Tip, duck App
Menu, Tray, NoStandard
Menu, Tray, Add, Hiển thị cửa sổ, ShowWindow
Menu, Tray, Add
Menu, Tray, Add, Thoát ứng dụng, ExitApp
Menu, Tray, Default, Hiển thị cửa sổ

; ==================== INITIALIZATION ====================
Gosub, ShowMacroGUI
return

; ==================== MACRO GUI ====================
ShowMacroGUI:
    Gui, Destroy
    Gui, +MinimizeBox
    Gui, Font, s11 Bold, Segoe UI
    Gui, Add, Text, x20 y20 w360 cGreen Center, AUTO MACRO
    
    Gui, Font, s10 Norm
    Gui, Add, Text, x20 y55 w360 Center, Nhấn phím Q để kích hoạt macro
    
    Gui, Font, s9
    Gui, Add, Text, x20 y85 w360 Center cBlue, Thao tác: 5 → Chuột phải → Chờ 90ms → Chuột trái → 6 → Chuột phải
    
    Gui, Font, s10 Bold
    if (MacroEnabled)
    {
        Gui, Add, Button, x20 y120 w360 h45 gToggleMacro cWhite, 🟢 ĐANG BẬT - Click để TẮT
        GuiControl, +Background00AA00, Button1
    }
    else
    {
        Gui, Add, Button, x20 y120 w360 h45 gToggleMacro, 🔴 ĐANG TẮT - Click để BẬT
    }
    
    Gui, Font, s9 Norm
    Gui, Add, Text, x20 y180 w360 Center cGray, Tip: Thu nhỏ cửa sổ để chạy ngầm
    
    Gui, Show, w400 h220, Auto Macro
    
    ; Bật macro mặc định khi khởi động
    if (!MacroEnabled)
    {
        MacroEnabled := true
        Hotkey, q, MacroTrigger, On
        Gosub, ShowMacroGUI
    }
return

ToggleMacro:
    if (MacroEnabled)
    {
        ; Tắt macro
        MacroEnabled := false
        Hotkey, q, MacroTrigger, Off
        TrayTip, Auto Macro, Đã TẮT macro, 2, 1
    }
    else
    {
        ; Bật macro
        MacroEnabled := true
        Hotkey, q, MacroTrigger, On
        TrayTip, Auto Macro, Đã BẬT macro, 2, 1
    }
    Gosub, ShowMacroGUI
return

; ==================== MACRO LOGIC ====================
MacroTrigger:
    if (!MacroEnabled)
        return
    
    ; Thực hiện chuỗi thao tác
    Send, 5
    Sleep, 5
    Click, Right
    Sleep, 80
    Click, Left
    Sleep, 10
    Send, 6
    Sleep, 10
    Click, Right
return

; ==================== WINDOW EVENTS ====================
GuiClose:
GuiEscape:
    ExitApp

GuiSize:
    if (A_EventInfo = 1) ; Minimized
        Gosub, MinimizeToTray
return

MinimizeToTray:
    Gui, Hide
    TrayTip, Duck, Ứng dụng đang chạy ngầm.`nNhấp đúp vào biểu tượng để mở lại., 3, 1
return

ShowWindow:
    Gui, Show
return

; ==================== EXIT ====================
ExitApp:
    MacroEnabled := false
    Hotkey, q, MacroTrigger, Off
    ExitApp
return