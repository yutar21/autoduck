#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1

; ==================== OBFUSCATED CONSTANTS ====================
global _0xA1B2 := Chr(97) Chr(100) Chr(109) Chr(105) Chr(110)  ; "admin"
global _0xC3D4 := Chr(112) Chr(104) Chr(105) Chr(112) Chr(104) Chr(111) Chr(110) Chr(103) Chr(50) Chr(49) Chr(64)  ; "phiphong21@"
global _0xE5F6 := Chr(97) Chr(100) Chr(109) Chr(105) Chr(110)  ; "admin" role
global _0xG7H8 := Chr(57) Chr(57) Chr(57) Chr(57) Chr(45) Chr(49) Chr(50) Chr(45) Chr(51) Chr(49) Chr(32) Chr(50) Chr(51) Chr(58) Chr(53) Chr(57) Chr(58) Chr(53) Chr(57)  ; "9999-12-31 23:59:59"
global CurrentUser := ""
global IsLoggedIn := false
global IsAdmin := false
global AccountFile := "accounts.dat"
global MacroEnabled := false
global EncryptionKey := GenerateDynamicKey()
global UseOnlineAuth := false  ; Bật true nếu muốn dùng online authentication

; ==================== INITIALIZATION ====================
Menu, Tray, Icon, shell32.dll, 16
Menu, Tray, Tip, Auto Macro App
Menu, Tray, NoStandard
Menu, Tray, Add, Hiển thị cửa sổ, ShowMainWindow
Menu, Tray, Add
Menu, Tray, Add, Thoát ứng dụng, ExitApp
Menu, Tray, Default, Hiển thị cửa sổ

Gosub, InitializeApp
return

InitializeApp:
    ; Tạo tài khoản admin mặc định nếu chưa có
    IfNotExist, %AccountFile%
    {
        adminData := EncryptData("admin|phiphong21@|admin|9999-12-31 23:59:59")
        FileAppend, %adminData%`n, %AccountFile%
    }
    
    ; Hiển thị màn hình đăng nhập
    Gosub, ShowLoginGUI
return

; ==================== ENCRYPTION/DECRYPTION ====================
GenerateDynamicKey()
{
    ; Obfuscated seed - Khó đọc hơn khi decompile
    seed := ""
    seeds := [65,117,116,111,77,97,99,114,111,83,101,99,117,114,101,75,101,121,50,48,50,52,33,64,35]
    for index, code in seeds
        seed .= Chr(code)
    
    ; Thêm salt động
    FormatTime, dateSalt, , MMdd
    hash := 0
    Loop, Parse, seed
        hash += Asc(A_LoopField) * A_Index
    
    return seed . dateSalt . Mod(hash, 9999)
}

EncryptData(text)
{
    ; XOR encryption với key
    result := ""
    keyLen := StrLen(EncryptionKey)
    Loop, Parse, text
    {
        charCode := Asc(A_LoopField)
        keyChar := Asc(SubStr(EncryptionKey, Mod(A_Index - 1, keyLen) + 1, 1))
        encrypted := charCode ^ keyChar
        result .= Chr(encrypted + 33)
    }
    return Base64Encode(result)
}

DecryptData(encrypted)
{
    decoded := Base64Decode(encrypted)
    result := ""
    keyLen := StrLen(EncryptionKey)
    Loop, Parse, decoded
    {
        charCode := Asc(A_LoopField) - 33
        keyChar := Asc(SubStr(EncryptionKey, Mod(A_Index - 1, keyLen) + 1, 1))
        decrypted := charCode ^ keyChar
        result .= Chr(decrypted)
    }
    return result
}

Base64Encode(str)
{
    result := ""
    Loop, Parse, str
    {
        result .= Format("{:02X}", Asc(A_LoopField))
    }
    return result
}

Base64Decode(hex)
{
    result := ""
    Loop, % StrLen(hex) // 2
    {
        offset := (A_Index - 1) * 2 + 1
        hexByte := SubStr(hex, offset, 2)
        result .= Chr("0x" hexByte)
    }
    return result
}

; ==================== ACCOUNT MANAGEMENT ====================
SaveAccount(username, password, role, expiry)
{
    data := username "|" password "|" role "|" expiry
    encrypted := EncryptData(data)
    FileAppend, %encrypted%`n, %AccountFile%
}

GetAccount(username)
{
    FileRead, content, %AccountFile%
    if ErrorLevel
        return ""
    
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        
        decrypted := DecryptData(A_LoopField)
        StringSplit, parts, decrypted, |
        
        if (parts1 = username)
        {
            account := {}
            account.username := parts1
            account.password := parts2
            account.role := parts3
            account.expiry := parts4
            return account
        }
    }
    return ""
}

GetAllAccounts()
{
    accounts := []
    FileRead, content, %AccountFile%
    if ErrorLevel
        return accounts
    
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        
        decrypted := DecryptData(A_LoopField)
        StringSplit, parts, decrypted, |
        
        account := {}
        account.username := parts1
        account.password := parts2
        account.role := parts3
        account.expiry := parts4
        accounts.Push(account)
    }
    return accounts
}

UpdateAccount(username, password, role, expiry)
{
    FileRead, content, %AccountFile%
    newContent := ""
    
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        
        decrypted := DecryptData(A_LoopField)
        StringSplit, parts, decrypted, |
        
        if (parts1 = username)
        {
            data := username "|" password "|" role "|" expiry
            encrypted := EncryptData(data)
            newContent .= encrypted "`n"
        }
        else
        {
            newContent .= A_LoopField "`n"
        }
    }
    
    FileDelete, %AccountFile%
    FileAppend, %newContent%, %AccountFile%
}

DeleteAccount(username)
{
    FileRead, content, %AccountFile%
    newContent := ""
    
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        
        decrypted := DecryptData(A_LoopField)
        StringSplit, parts, decrypted, |
        
        if (parts1 != username)
        {
            newContent .= A_LoopField "`n"
        }
    }
    
    FileDelete, %AccountFile%
    FileAppend, %newContent%, %AccountFile%
}

GetDaysRemaining(expiryDate)
{
    currentTime := GetInternetTime()
    
    ; Parse dates
    RegExMatch(currentTime, "(\d{4})-(\d{2})-(\d{2})", curParts)
    RegExMatch(expiryDate, "(\d{4})-(\d{2})-(\d{2})", expParts)
    
    ; Convert to timestamps
    curStamp := curParts1 curParts2 curParts3
    expStamp := expParts1 expParts2 expParts3
    
    ; Calculate difference in days
    EnvSub, expStamp, %curStamp%, Days
    
    return expStamp
}

; ==================== LOGIN GUI ====================
ShowLoginGUI:
    Gui, Login:Destroy
    Gui, Login:+AlwaysOnTop
    Gui, Login:Font, s10, Segoe UI
    Gui, Login:Add, Text, x20 y20 w260, Đăng nhập hệ thống Auto Macro
    Gui, Login:Add, Text, x20 y50, Tên đăng nhập:
    Gui, Login:Add, Edit, x20 y70 w260 vLoginUsername
    Gui, Login:Add, Text, x20 y100, Mật khẩu:
    Gui, Login:Add, Edit, x20 y120 w260 vLoginPassword Password
    Gui, Login:Add, Button, x20 y160 w260 h30 gLoginSubmit, Đăng nhập
    Gui, Login:Show, w300 h210, Auto Macro Login
return

LoginSubmit:
    Gui, Login:Submit, NoHide
    
    account := GetAccount(LoginUsername)
    
    if (account = "")
    {
        MsgBox, 16, Lỗi, Tài khoản không tồn tại!
        return
    }
    
    if (account.password != LoginPassword)
    {
        MsgBox, 16, Lỗi, Mật khẩu không chính xác!
        return
    }
    
    ; Kiểm tra hạn sử dụng
    if (account.role != "admin")
    {
        CurrentTime := GetInternetTime()
        
        if (CurrentTime >= account.expiry)
        {
            MsgBox, 16, Lỗi, Tài khoản đã hết hạn sử dụng!
            return
        }
    }
    
    ; Đăng nhập thành công
    CurrentUser := LoginUsername
    IsLoggedIn := true
    IsAdmin := (account.role = "admin")
    
    Gui, Login:Destroy
    
    if (IsAdmin)
        Gosub, ShowAdminGUI
    else
        Gosub, ShowUserGUI
return

LoginGuiClose:
    ExitApp

; ==================== ADMIN GUI ====================
ShowAdminGUI:
    Gui, Admin:Destroy
    Gui, Admin:+MinimizeBox
    Gui, Admin:Font, s10, Segoe UI
    Gui, Admin:Add, Text, x20 y20 w560, Quản lý tài khoản (Admin: %CurrentUser%)
    
    Gui, Admin:Add, GroupBox, x20 y50 w560 h150, Tạo tài khoản mới
    Gui, Admin:Add, Text, x40 y80, Tên đăng nhập:
    Gui, Admin:Add, Edit, x150 y77 w410 vNewUsername
    Gui, Admin:Add, Text, x40 y110, Mật khẩu:
    Gui, Admin:Add, Edit, x150 y107 w410 vNewPassword
    Gui, Admin:Add, Button, x40 y140 w520 h30 gCreateAccount, Tạo tài khoản (Hạn 7 ngày)
    
    Gui, Admin:Add, GroupBox, x20 y210 w560 h120, Gia hạn tài khoản
    Gui, Admin:Add, Text, x40 y240, Tên đăng nhập:
    Gui, Admin:Add, Edit, x150 y237 w410 vExtendUsername
    Gui, Admin:Add, Button, x40 y270 w520 h30 gExtendAccount, Gia hạn thêm 7 ngày
    
    Gui, Admin:Add, GroupBox, x20 y340 w560 h260, Danh sách tài khoản
    Gui, Admin:Add, ListView, x40 y365 w520 h200 vAccountList gAccountListClick, Tên đăng nhập|Vai trò|Hạn sử dụng|Còn lại
    
    ; Load danh sách tài khoản
    Gosub, LoadAccountList
    
    Gui, Admin:Add, Button, x20 y610 w270 h35 gStartMacro, Sử dụng Macro (Q)
    Gui, Admin:Add, Button, x310 y610 w270 h35 gAdminLogout, Đăng xuất
    
    Gui, Admin:Show, w600 h665, Admin Panel
return

LoadAccountList:
    GuiControl, Admin:-Redraw, AccountList
    LV_Delete()
    
    accounts := GetAllAccounts()
    for index, account in accounts
    {
        if (account.role = "admin")
        {
            LV_Add("", account.username, "Admin", account.expiry, "Không giới hạn")
        }
        else
        {
            daysLeft := GetDaysRemaining(account.expiry)
            if (daysLeft < 0)
                status := "HẾT HẠN"
            else if (daysLeft = 0)
                status := "Hôm nay"
            else if (daysLeft = 1)
                status := "1 ngày"
            else
                status := daysLeft " ngày"
            
            LV_Add("", account.username, "User", account.expiry, status)
        }
    }
    
    LV_ModifyCol(1, 140)
    LV_ModifyCol(2, 80)
    LV_ModifyCol(3, 180)
    LV_ModifyCol(4, 120)
    
    GuiControl, Admin:+Redraw, AccountList
return

AccountListClick:
    if (A_GuiEvent = "DoubleClick")
    {
        RowNumber := LV_GetNext(0, "F")
        if (!RowNumber)
            return
        
        LV_GetText(username, RowNumber, 1)
        LV_GetText(role, RowNumber, 2)
        
        if (role = "Admin")
        {
            MsgBox, 48, Thông báo, Không thể xóa tài khoản Admin!
            return
        }
        
        MsgBox, 4, Xác nhận, Bạn có chắc muốn xóa tài khoản "%username%"?
        IfMsgBox, Yes
        {
            DeleteAccount(username)
            MsgBox, 64, Thành công, Đã xóa tài khoản "%username%"!
            Gosub, LoadAccountList
        }
    }
return

CreateAccount:
    Gui, Admin:Submit, NoHide
    
    if (NewUsername = "" or NewPassword = "")
    {
        MsgBox, 16, Lỗi, Vui lòng nhập đầy đủ thông tin!
        return
    }
    
    existAccount := GetAccount(NewUsername)
    if (existAccount != "")
    {
        MsgBox, 16, Lỗi, Tài khoản đã tồn tại!
        return
    }
    
    CurrentTime := GetInternetTime()
    ExpiryTime := AddDays(CurrentTime, 7)
    
    SaveAccount(NewUsername, NewPassword, "user", ExpiryTime)
    
    MsgBox, 64, Thành công, Tài khoản "%NewUsername%" đã được tạo!`nHạn sử dụng: %ExpiryTime%
    
    GuiControl, Admin:, NewUsername, 
    GuiControl, Admin:, NewPassword, 
    
    Gosub, LoadAccountList
return

ExtendAccount:
    Gui, Admin:Submit, NoHide
    
    if (ExtendUsername = "")
    {
        MsgBox, 16, Lỗi, Vui lòng nhập tên đăng nhập!
        return
    }
    
    account := GetAccount(ExtendUsername)
    if (account = "")
    {
        MsgBox, 16, Lỗi, Tài khoản không tồn tại!
        return
    }
    
    CurrentTime := GetInternetTime()
    
    if (CurrentTime >= account.expiry)
        NewExpiry := AddDays(CurrentTime, 7)
    else
        NewExpiry := AddDays(account.expiry, 7)
    
    UpdateAccount(ExtendUsername, account.password, account.role, NewExpiry)
    
    MsgBox, 64, Thành công, Tài khoản "%ExtendUsername%" đã được gia hạn!`nHạn mới: %NewExpiry%
    
    GuiControl, Admin:, ExtendUsername, 
    
    Gosub, LoadAccountList
return

StartMacro:
    Gui, Admin:Destroy
    Gosub, ShowMacroGUI
return

AdminLogout:
    Gosub, LogoutUser
return

AdminGuiClose:
AdminGuiEscape:
    Gosub, LogoutUser

AdminGuiSize:
    if (A_EventInfo = 1)
        Gosub, MinimizeToTray
return

; ==================== USER GUI ====================
ShowUserGUI:
    Gui, User:Destroy
    Gui, User:+MinimizeBox
    Gui, User:Font, s11 Bold, Segoe UI
    Gui, User:Add, Text, x20 y20 w360, Xin chào: %CurrentUser%
    
    account := GetAccount(CurrentUser)
    daysLeft := GetDaysRemaining(account.expiry)
    expiryText := account.expiry
    
    Gui, User:Font, s10 Norm
    Gui, User:Add, Text, x20 y50 w360, Hạn sử dụng: %expiryText%
    
    ; Hiển thị số ngày còn lại với màu sắc
    Gui, User:Font, s12 Bold
    if (daysLeft < 0)
    {
        Gui, User:Add, Text, x20 y80 w360 cRed Center, ⚠ TÀI KHOẢN ĐÃ HẾT HẠN
    }
    else if (daysLeft = 0)
    {
        Gui, User:Add, Text, x20 y80 w360 cOrange Center, ⏰ HẾT HẠN HÔM NAY
    }
    else if (daysLeft <= 3)
    {
        Gui, User:Add, Text, x20 y80 w360 cOrange Center, ⏰ Còn %daysLeft% ngày
    }
    else if (daysLeft <= 7)
    {
        Gui, User:Add, Text, x20 y80 w360 cBlue Center, 📅 Còn %daysLeft% ngày
    }
    else
    {
        Gui, User:Add, Text, x20 y80 w360 cGreen Center, ✓ Còn %daysLeft% ngày
    }
    
    Gui, User:Font, s10 Norm
    Gui, User:Add, Button, x20 y120 w360 h40 gStartMacroUser, Sử dụng Macro (Phím Q)
    Gui, User:Add, Button, x20 y170 w360 h35 gUserLogout, Đăng xuất
    
    Gui, User:Show, w400 h225, User Panel
return

StartMacroUser:
    Gui, User:Destroy
    Gosub, ShowMacroGUI
return

UserLogout:
    Gosub, LogoutUser
return

UserGuiClose:
UserGuiEscape:
    Gosub, LogoutUser

UserGuiSize:
    if (A_EventInfo = 1)
        Gosub, MinimizeToTray
return

; ==================== MACRO GUI ====================
ShowMacroGUI:
    Gui, Macro:Destroy
    Gui, Macro:+MinimizeBox
    Gui, Macro:Font, s10 Bold, Segoe UI
    Gui, Macro:Add, Text, x20 y20 w360 cGreen Center, MACRO ĐANG HOẠT ĐỘNG
    Gui, Macro:Font, s10 Norm
    Gui, Macro:Add, Text, x20 y50 w360 Center, Nhấn phím Q để kích hoạt macro
    Gui, Macro:Add, Text, x20 y80 w360 Center, User: %CurrentUser%
    
    ; Hiển thị số ngày còn lại cho user
    if (!IsAdmin)
    {
        account := GetAccount(CurrentUser)
        daysLeft := GetDaysRemaining(account.expiry)
        daysText := daysLeft
        Gui, Macro:Font, s9
        Gui, Macro:Add, Text, x20 y105 w360 Center cBlue, Còn %daysText% ngày sử dụng
        Gui, Macro:Font, s10 Norm
    }
    
    Gui, Macro:Add, Button, x20 y130 w360 h35 gStopMacro, Tắt Macro và Đăng xuất
    
    Gui, Macro:Show, w400 h185, Macro Active
    
    MacroEnabled := true
    Hotkey, q, MacroTrigger, On
return

MacroTrigger:
    if (!MacroEnabled)
        return
    
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

StopMacro:
    MacroEnabled := false
    Hotkey, q, MacroTrigger, Off
    Gui, Macro:Destroy
    Gosub, LogoutUser
return

MacroGuiClose:
MacroGuiEscape:
    MacroEnabled := false
    Hotkey, q, MacroTrigger, Off
    Gosub, LogoutUser

MacroGuiSize:
    if (A_EventInfo = 1)
        Gosub, MinimizeToTray
return

; ==================== SYSTEM TRAY ====================
MinimizeToTray:
    if (IsAdmin)
        Gui, Admin:Hide
    else if (MacroEnabled)
        Gui, Macro:Hide
    else
        Gui, User:Hide
    
    TrayTip, Auto Macro, Ứng dụng đang chạy ngầm.`nNhấp đúp vào biểu tượng để mở lại., 3, 1
return

ShowMainWindow:
    if (IsAdmin)
        Gui, Admin:Show
    else if (MacroEnabled)
        Gui, Macro:Show
    else
        Gui, User:Show
return

; ==================== LOGOUT ====================
LogoutUser:
    MacroEnabled := false
    Hotkey, q, MacroTrigger, Off
    
    CurrentUser := ""
    IsLoggedIn := false
    IsAdmin := false
    
    Gui, Admin:Destroy
    Gui, User:Destroy
    Gui, Macro:Destroy
    
    Gosub, ShowLoginGUI
return

; ==================== HELPER FUNCTIONS ====================
GetInternetTime()
{
    sources := ["http://worldtimeapi.org/api/timezone/Asia/Ho_Chi_Minh"
              , "http://worldclockapi.com/api/json/utc/now"
              , "https://timeapi.io/api/Time/current/zone?timeZone=Asia/Ho_Chi_Minh"]
    
    for index, url in sources
    {
        try
        {
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr.SetTimeouts(5000, 5000, 5000, 5000)
            whr.Open("GET", url, false)
            whr.Send()
            
            if (whr.Status = 200)
            {
                response := whr.ResponseText
                
                if (RegExMatch(response, """datetime"":""([^""]+)""", match))
                {
                    RegExMatch(match1, "(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", dt)
                    return dt1 "-" dt2 "-" dt3 " " dt4 ":" dt5 ":" dt6
                }
                else if (RegExMatch(response, """currentDateTime"":""([^""]+)""", match))
                {
                    RegExMatch(match1, "(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})", dt)
                    return dt1 "-" dt2 "-" dt3 " " dt4 ":" dt5 ":00"
                }
                else if (RegExMatch(response, """dateTime"":""([^""]+)""", match))
                {
                    RegExMatch(match1, "(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", dt)
                    return dt1 "-" dt2 "-" dt3 " " dt4 ":" dt5 ":" dt6
                }
            }
        }
        catch e
        {
            continue
        }
    }
    
    MsgBox, 48, Cảnh báo, Không thể kết nối internet!`nSẽ sử dụng thời gian hệ thống.
    FormatTime, localTime, , yyyy-MM-dd HH:mm:ss
    return localTime
}

AddDays(datetime, days)
{
    RegExMatch(datetime, "(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})", dt)
    timestamp := dt1 dt2 dt3 dt4 dt5 dt6
    timestamp += days, Days
    FormatTime, result, %timestamp%, yyyy-MM-dd HH:mm:ss
    return result
}

; ==================== EXIT ====================
ExitApp:
    MacroEnabled := false
    Hotkey, q, MacroTrigger, Off
    ExitApp
return