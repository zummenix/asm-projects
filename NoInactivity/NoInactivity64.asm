
format PE64 GUI
entry start

include 'win64w.inc'

  WM_SHELLNOTIFY = WM_USER + 1

  ID_TRAY       = 1

  IDM_About     = 2
  IDM_Exit      = 3

  IDB_OK        = 10

  WIDTH_BUTTON  = 90
  HEIGHT_BUTTON = 24

  ICON_SIZE     = 48
  INDENT_SIZE   = 12 ; Отступ по краям окна.

section '.text' code readable executable

  start:
        sub     rsp,8   ; Make stack dqword aligned

        invoke  FindWindow,szClass,szAbout
        test    rax,rax
        je      @F
        invoke  MessageBeep,MB_OK
        jmp     end_loop
    @@:

        invoke  GetModuleHandle,0
        mov     [wc.hInstance],rax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],rax
        invoke  RegisterClassEx,wc
        test    rax,rax
        je      error

        invoke  CreateWindowEx,0,szClass,szAbout,\
                WS_DLGFRAME,\
                0,0,256,128,\
                0,0,[wc.hInstance],0
        test    rax,rax
        je      error

  msg_loop:
        xor     rdx,rdx
        xor     r8,r8
        xor     r9,r9
        invoke  GetMessage,msg,rdx,r8,r9
        cmp     rax,1
        jb      end_loop
        jne     msg_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop

  error:
        xor     rcx,rcx
        xor     r8,r8
        invoke  MessageBox,rcx,szError,r8,MB_ICONERROR+MB_OK

  end_loop:
        invoke  ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
        frame

        mov     [hwnd],rcx
        mov     [wmsg],rdx
        mov     [wparam],r8
        mov     [lparam],r9

        cmp     rdx,WM_CREATE
        je      .wm_create
        cmp     rdx,WM_PAINT
        je      .wm_paint
        cmp     rdx,WM_COMMAND
        je      .wm_command
        cmp     rdx,WM_SHELLNOTIFY
        je      .wm_shellnotify
        cmp     rdx,WM_TIMER
        je      .wm_timer
        cmp     rdx,[msgTaskbarCreated]
        je      .wm_restore
        cmp     rdx,WM_DESTROY
        je      .wm_destroy
  .defwndproc:
        invoke  DefWindowProc,rcx,rdx,r8,r9
        jmp     .finish

  .wm_create:
        invoke  SetTimer,[hwnd],1,60000,0

; Иконку в трей.
        mov     [node.cbSize],sizeof.NOTIFYICONDATA
        mov     rax,[hwnd]
        mov     [node.hWnd],rax
        mov     [node.uID],ID_TRAY
        mov     [node.uFlags],NIF_ICON+NIF_MESSAGE+NIF_TIP
        mov     [node.uCallbackMessage],WM_SHELLNOTIFY
        invoke  LoadImage,[wc.hInstance],1,IMAGE_ICON,16,16,LR_DEFAULTCOLOR
        mov     [node.hIcon],rax

        push    rsi rdi
        cld
        mov     rsi,szTitle
        mov     rdi,node.szTip
        mov     rcx,sizeof.NOTIFYICONDATA.szTip / 8
        rep     movsq
        pop     rdi rsi

        invoke  Shell_NotifyIcon,NIM_ADD,node
        test    rax,rax
        je      .failed

; Создаем меню в трее.
        invoke  CreatePopupMenu
        mov     [hTrayMenu],rax

        invoke  AppendMenu,[hTrayMenu],MF_STRING,IDM_About,szAbout
        invoke  AppendMenu,[hTrayMenu],MF_STRING,IDM_Exit,szExit

; Регистрируем сообщение TaskbarCreated.
        invoke  RegisterWindowMessage,szTaskbarCreated
        mov     [msgTaskbarCreated],rax

; Загружаем иконку.
        invoke  LoadImage,[wc.hInstance],1,IMAGE_ICON,ICON_SIZE,ICON_SIZE,LR_DEFAULTCOLOR
        mov     [hAboutIcon],rax

; Получаем шрифт.
        stdcall CreateGUIFont64,szFontFace
        test    rax,rax
        je      .failed
        mov     [hFont],rax

; Получаем Необходимые размеры окна.
        invoke  GetDC,[hwnd]
        mov     [hDC],rax

        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],rax

        stdcall GetTextSize64,[hDC],szVersion,size
        test    rax,rax
        je      .failed

        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],rax

        invoke  ReleaseDC,[hwnd],[hDC]

; Получаем ширину клиентской области окна, неоходимую
; для нормального отображения иконки и текста.
        add     [size.cx],(INDENT_SIZE*3)+ICON_SIZE
        mov     eax,[size.cx]

; Получаем X координату кнопки.
        sub     eax,WIDTH_BUTTON
        shr     eax,1
        mov     [nXButton],rax

; Если высота иконки больше высоты текста, то для расчета общей
; высоты клиентской области окна, используем высоту иконки.
        cmp     [size.cy],ICON_SIZE
        ja      @F
        mov     [size.cy],ICON_SIZE
    @@:
        add     [size.cy],INDENT_SIZE*2

; Получаем Y координату кнопки.
        mov     eax,[size.cy]
        mov     [nYButton],rax

; Получаем общую высоту клиентской области окна.
        add     [size.cy],INDENT_SIZE+HEIGHT_BUTTON

; Переводим размеры клиентской области окна в общие размеры
; окна (добавляем размеры рамок окна).
        push    rsi rdi
        invoke  GetWindowRect,[hwnd],rect
        mov     edi,[rect.bottom]
        mov     esi,[rect.right]
        invoke  GetClientRect,[hwnd],rect
        sub     edi,[rect.bottom]
        sub     esi,[rect.right]
        add     [size.cy],edi
        add     [size.cx],esi
        pop     rdi rsi

        invoke  GetSystemMetrics,SM_CXSCREEN
        sub     eax,[size.cx]
        shr     eax,1
        mov     [pt.x],eax

        invoke  GetSystemMetrics,SM_CYSCREEN
        sub     eax,[size.cy]
        shr     eax,1
        mov     [pt.y],eax

        invoke  MoveWindow,[hwnd],[pt.x],[pt.y],[size.cx],[size.cy],1

        invoke  CreateWindowEx,0,szCButton,szOK,\
                WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,\
                [nXButton],[nYButton],WIDTH_BUTTON,HEIGHT_BUTTON,\
                [hwnd],IDB_OK,[wc.hInstance],0
        test    rax,rax
        je      error
        invoke  SendMessage,rax,WM_SETFONT,[hFont],1

        xor     rax,rax
        jmp     .finish

    .failed:
        mov     rax,-1
        jmp     .finish

  .wm_paint:
        invoke  BeginPaint,[hwnd],ps
        mov     [hDC],rax

; Рисуем иконку программы.
        invoke  DrawIconEx,[hDC],INDENT_SIZE,INDENT_SIZE,[hAboutIcon],ICON_SIZE,ICON_SIZE,0,0,DI_NORMAL

; Выводим информацию о программе.
        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],rax

        invoke  SetBkMode,[hDC],TRANSPARENT

        mov     [rect.left],(INDENT_SIZE*2)+ICON_SIZE
        mov     [rect.top],INDENT_SIZE
        mov     eax,[size.cx]
        mov     [rect.right],eax
        mov     eax,[size.cy]
        mov     [rect.bottom],eax
        invoke  DrawText,[hDC],szVersion,-1,rect,DT_WORDBREAK

        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],rax

        invoke  EndPaint,[hwnd],ps
        xor     rax,rax
        jmp     .finish

  .wm_command:
        cmp     r8,IDM_About                      ; [wparam]
        je      .idm_about
        cmp     r8,BN_CLICKED shl 16 + IDB_OK
        je      .idb_ok
        cmp     r8,IDM_Exit
        je      .idm_exit
        xor     rax,rax
        jmp     .finish

    .idm_about:
; Показываем окно.
        invoke  ShowWindow,[hwnd],SW_SHOWNORMAL
        invoke  MessageBeep,MB_ICONINFORMATION
        xor     rax,rax
        jmp     .finish

    .idb_ok:
; Скрываем окно.
        invoke  ShowWindow,[hwnd],SW_HIDE
        xor     rax,rax
        jmp     .finish

    .idm_exit:
        invoke  DestroyWindow,[hwnd]
        xor     rax,rax
        jmp     .finish

  .wm_shellnotify:
        cmp     r8,ID_TRAY        ; [wparam]
        jne     .finish
        cmp     r9,WM_LBUTTONDOWN ; [lparam]
        je      .show_tray_popup
        cmp     r9,WM_RBUTTONDOWN ; [lparam]
        je      .show_tray_popup
        xor     rax,rax
        jmp     .finish

    .show_tray_popup:
; Покажем меню в трее.
        invoke  GetCursorPos,pt
        invoke  SetForegroundWindow,[hwnd]
        invoke  TrackPopupMenu,[hTrayMenu],TPM_RIGHTALIGN,[pt.x],[pt.y],0,[hwnd],0
        invoke  PostMessage,[hwnd],WM_NULL,0,0
        jmp     .finish

  .wm_timer:
; Сбросим счетчик бездействия системы.
        invoke  mouse_event,MOUSEEVENTF_MOVE,0,0,0,0
        xor     rax,rax
        jmp     .finish

  .wm_restore:
; Восстановим иконку в трее.
        invoke  Shell_NotifyIcon,NIM_ADD,node
        xor     rax,rax
        jmp     .finish

  .wm_destroy:
        invoke  Shell_NotifyIcon,NIM_DELETE,node
        invoke  DeleteObject,[hFont]
        invoke  DestroyMenu,[hTrayMenu]
        invoke  PostQuitMessage,0
        xor     rax,rax
  .finish:
        endf
        ret
endp

;--------------------------------------------------------------
; Функция создает шрифт.
; lpszFontFace - указатель на символьную строку с названием
; новой гарнитуры шрифта.
;--------------------------------------------------------------
proc CreateGUIFont64 uses rsi rdi, lpszFontFace

  CLEARTYPE_QUALITY = 5

locals
  lf LOGFONT
endl

        frame
        mov     [lpszFontFace],rcx

; Получаем шрифт, используемый по умолчанию.
        invoke  GetStockObject,DEFAULT_GUI_FONT

; Если название шрифта не указано, то выходим из функции,
; возвращая шрифт, используемый по умолчанию.
        cmp     [lpszFontFace],0
        je      .exit
        mov     rdx,[lpszFontFace]
        cmp     word [rdx],0
        je      .exit

; Получаем и изменяем атрибуты шрифта.
        lea     r8,[lf]
        invoke  GetObject,rax,sizeof.LOGFONT,r8
        test    rax,rax
        je      .exit

        mov     [lf.lfWeight],FW_NORMAL
        mov     [lf.lfQuality],CLEARTYPE_QUALITY

        cld
        mov     rsi,[lpszFontFace]
        lea     rdi,[lf.lfFaceName]
        mov     rcx,sizeof.LOGFONT.lfFaceName / 8
        rep     movsq

        lea     rcx,[lf]
        invoke  CreateFontIndirect,rcx
  .exit:
        endf
        ret
endp

;--------------------------------------------------------------
; Функция получает размеры блока текста.
; hDC - дескриптор устройства.
; lpszText - указатель на символьную строку с текстом.
; lpSIZE - указатель на структуру SIZE.
;--------------------------------------------------------------
proc GetTextSize64 hDC,lpszText,lpSIZE

locals
  rect RECT
endl

        frame
        mov     [lpSIZE],r8

; Если текст не указан, то выходим из функции, возвращая ноль.
        xor     rax,rax
        cmp     rdx,rax
        je      .exit
        cmp     [rdx],ax
        je      .exit

; Обнуляем rect.left и rect.top.
        lea     r9,[rect]
        mov     [r9],rax

; Получаем rect.right и rect.bottom размеры текста.
        invoke  DrawText,rcx,rdx,-1,r9,DT_CALCRECT
        test    eax,eax
        je      .exit

; Если нет указателя на структуру SIZE, то выходим из функции,
; возвращая ширину текста.
        cmp     [lpSIZE],0
        je      .exit

; Копируем rect.right и rect.bottom в структуру SIZE,
; возвращаем на нее указатель.
        lea     rax,[rect+8]
        mov     rdx,[rax]

        mov     rax,[lpSIZE]
        mov     [rax],rdx

  .exit:
        endf
        ret
endp

section '.data' data readable writeable

  szClass    du 'NoInactivity Program',0
  szTitle    du 'NoInactivity',0
  szError    du 'Startup failed.',0

  szCButton  du 'button',0

  szFontFace du 'Verdana',0

  szAbout    du 'About',0
  szExit     du 'Exit',0
  szOK       du 'OK',0

  szVersion  du 'NoInactivity - version 1.7 (x86-64)',10,\
                'The program to reset the timer system inactivity.',10,\
                'Copyright © 2010-2012 Zummenix. All Rights Reserved.',0

; Имя сообщения для восстановления иконки после сбоя Explorer'а.
  szTaskbarCreated du 'TaskbarCreated',0

  align 8
  wc WNDCLASSEX sizeof.WNDCLASSEX,0,WindowProc,0,0,0,0,0,COLOR_BTNFACE+1,0,szClass,0

  pt   POINT
  ps   PAINTSTRUCT
  msg  MSG
  node NOTIFYICONDATA
  size SIZE
  rect RECT

  hTrayMenu      dq ?
  hAboutIcon     dq ?
  hFont          dq ?
  hDC            dq ?
  nXButton       dq ?
  nYButton       dq ?

; Идентификатор сообщения для восстановления иконки после сбоя Explorer'а.
  msgTaskbarCreated dq ?

section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          gdi32,'GDI32.DLL',\
          shell32,'SHELL32.DLL',\
          comctl32,'COMCTL32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\gdi32.inc'
  include 'api\shell32.inc'
  include 'api\comctl32.inc'

section '.rsrc' resource data readable

  directory RT_ICON,icons,\
            RT_GROUP_ICON,group_icons,\
            RT_MANIFEST,manifest

  resource icons,\
           1,LANG_NEUTRAL,icon_data1,\
           2,LANG_NEUTRAL,icon_data2,\
           3,LANG_NEUTRAL,icon_data3,\
           4,LANG_NEUTRAL,icon_data4

  resource group_icons,\
           1,LANG_NEUTRAL,main_icon

  resource manifest,1,LANG_NEUTRAL,style

  icon main_icon,\
       icon_data1,'Icon\64.ico',\
       icon_data2,'Icon\48.ico',\
       icon_data3,'Icon\32.ico',\
       icon_data4,'Icon\16.ico'

  resdata style
        db '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        db '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">'
        db '<assemblyIdentity '
        db 'version="0.0.0.0" '
        db 'processorArchitecture="*" '
        db 'name="No name" '
        db 'type="win64"'
        db '/>'
        db '<description>"No description"</description>'
        db '<dependency>'
        db '<dependentAssembly>'
        db '<assemblyIdentity '
        db 'type="win32" '
        db 'name="Microsoft.Windows.Common-Controls" '
        db 'version="6.0.0.0" '
        db 'processorArchitecture="*" '
        db 'publicKeyToken="6595b64144ccf1df" '
        db 'language="*"'
        db '/>'
        db '</dependentAssembly>'
        db '</dependency>'
        db '</assembly>'
  endres
