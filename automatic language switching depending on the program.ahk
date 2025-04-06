#Requires AutoHotkey v2.0

; Отключение стандартных диалоговых окон ошибок
#Warn All, Off
#SingleInstance Force

; Перехват и подавление всех ошибок
OnError(ErrorHandler)

ErrorHandler(exception, mode) {
    ; Только логируем ошибку в файл без прерывания работы скрипта
    FileAppend(
        FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Error: " . exception.Message . " at line " . exception.Line . "`n", 
        A_ScriptDir . "\keyboard_layout_errors.log"
    )
    return true  ; Возвращаем true, чтобы предотвратить стандартную обработку ошибки и продолжить выполнение
}

; Константы для переключения раскладки
WM_INPUTLANGCHANGEREQUEST := 0x0050
LANG_ENGLISH := 0x0409  ; Английский (США)
LANG_RUSSIAN := 0x0419  ; Русский

; Функция для смены языка с использованием PostMessage, с защитой от ошибок
SwitchLayout(langId) {
    try {
        hwnd := WinGetID("A")  ; Получаем ID активного окна
        if (hwnd) {
            PostMessage(WM_INPUTLANGCHANGEREQUEST, 0, langId, , "ahk_id " hwnd)
        }
    } catch as e {
        ; Игнорируем ошибку и позволяем скрипту продолжить работу
        return
    }
}

; Функция для смены языка на английский
SwitchToEnglish(*) {
    SwitchLayout(LANG_ENGLISH)
}

; Функция для смены языка на русский
SwitchToRussian(*) {
    SwitchLayout(LANG_RUSSIAN)
}

; Основная функция проверки смены окна
CheckWindowChange(*) {
    static lastWindow := 0
    
    try {
        activeWindow := WinExist("A")
        
        if (activeWindow != lastWindow) {
            try {
                ; Получаем имя процесса активного окна через ID окна
                if hwnd := WinExist("A") {
                    try {
                        activeProcess := WinGetProcessName(hwnd)
                        
                        ; Проверяем, является ли активное окно одним из указанных приложений
                        if (activeProcess = "Viber.exe" || activeProcess = "Telegram.exe" || 
                            activeProcess = "UpNote.exe") {
                            SwitchToRussian()
                        } else {
                            SwitchToEnglish()
                        }
                    } catch {
                        ; Если не удалось получить имя процесса, используем английскую раскладку по умолчанию
                        SwitchToEnglish()
                    }
                } else {
                    SwitchToEnglish()
                }
            } catch {
                ; Если произошла ошибка в процессе проверки окна, игнорируем и продолжаем
            }
            
            lastWindow := activeWindow
        }
    } catch {
        ; Если произошла ошибка при получении активного окна, просто игнорируем
        ; и позволяем таймеру запустить функцию снова через интервал
    }
}

; Функция для перезапуска таймера в случае ошибки
RestartTimer(*) {
    static timerRunning := false
    
    if (!timerRunning) {
        try {
            ; Запускаем таймер проверки окна
            SetTimer(CheckWindowChange, 1000)
            timerRunning := true
        } catch {
            ; Если не удалось запустить таймер, попробуем еще раз через 5 секунд
            SetTimer(RestartTimer, 5000, 1)  ; Однократный запуск через 5 секунд
        }
    }
}

; Начальный запуск таймера
RestartTimer()

; Дополнительный таймер для проверки работоспособности основного таймера
SetTimer(WatchdogTimer, 60000)  ; Каждую минуту проверяем

WatchdogTimer(*) {
    ; Перезапускаем основной таймер, если он по какой-то причине перестал работать
    RestartTimer()
}