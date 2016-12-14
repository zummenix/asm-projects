
format PE GUI 4.0
entry start

include 'win32w.inc'

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
        invoke  FindWindow,szClass,szAbout
        test    eax,eax
        je      @F
        invoke  MessageBeep,MB_OK
        jmp     end_loop
    @@:

        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        invoke  RegisterClass,wc
        test    eax,eax
        je      error

        invoke  CreateWindowEx,0,szClass,szAbout,\
                WS_DLGFRAME,\
                0,0,256,128,\
                0,0,[wc.hInstance],0
        test    eax,eax
        je      error

  msg_loop:
        invoke  GetMessage,msg,NULL,0,0
        cmp     eax,1
        jb      end_loop
        jne     msg_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop

  error:
        invoke  MessageBox,0,szError,0,MB_ICONERROR+MB_OK

  end_loop:
        invoke  ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
        mov     eax,[wmsg]
        cmp     eax,WM_CREATE
        je      .wm_create
        cmp     eax,WM_PAINT
        je      .wm_paint
        cmp     eax,WM_COMMAND
        je      .wm_command
        cmp     eax,WM_SHELLNOTIFY
        je      .wm_shellnotify
        cmp     eax,WM_TIMER
        je      .wm_timer
        cmp     eax,[msgTaskbarCreated]
        je      .wm_restore
        cmp     eax,WM_DESTROY
        je      .wm_destroy
  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish

  .wm_create:
        invoke  SetTimer,[hwnd],1,60000,0

; Иконку в трей.
        mov     [node.cbSize],sizeof.NOTIFYICONDATA
        mov     eax,[hwnd]
        mov     [node.hWnd],eax
        mov     [node.uID],ID_TRAY
        mov     [node.uFlags],NIF_ICON+NIF_MESSAGE+NIF_TIP
        mov     [node.uCallbackMessage],WM_SHELLNOTIFY
        invoke  LoadImage,[wc.hInstance],1,IMAGE_ICON,16,16,LR_DEFAULTCOLOR
        mov     [node.hIcon],eax

        push    esi edi
        cld
        mov     esi,szTitle
        mov     edi,node.szTip
        mov     ecx,sizeof.NOTIFYICONDATA.szTip / 4
        rep     movsd
        pop     edi esi

        invoke  Shell_NotifyIcon,NIM_ADD,node
        test    eax,eax
        je      .failed

; Создаем меню в трее.
        invoke  CreatePopupMenu
        mov     [hTrayMenu],eax

        invoke  AppendMenu,[hTrayMenu],MF_STRING,IDM_About,szAbout
        invoke  AppendMenu,[hTrayMenu],MF_STRING,IDM_Exit,szExit

; Регистрируем сообщение TaskbarCreated.
        invoke  RegisterWindowMessage,szTaskbarCreated
        mov     [msgTaskbarCreated],eax

; Загружаем иконку.
        invoke  LoadImage,[wc.hInstance],1,IMAGE_ICON,ICON_SIZE,ICON_SIZE,LR_DEFAULTCOLOR
        mov     [hAboutIcon],eax

; Получаем шрифт.
        stdcall CreateGUIFont,szFontFace
        test    eax,eax
        je      .failed
        mov     [hFont],eax

; Получаем Необходимые размеры окна.
        invoke  GetDC,[hwnd]
        mov     [hDC],eax

        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],eax

        stdcall GetTextSize,[hDC],szVersion,size
        test    eax,eax
        je      .failed

        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],eax

        invoke  ReleaseDC,[hwnd],[hDC]

; Получаем ширину клиентской области окна, неоходимую
; для нормального отображения иконки и текста.
        add     [size.cx],(INDENT_SIZE*3)+ICON_SIZE
        mov     eax,[size.cx]

; Получаем X координату кнопки.
        sub     eax,WIDTH_BUTTON
        shr     eax,1
        mov     [nXButton],eax

; Если высота иконки больше высоты текста, то для расчета общей
; высоты клиентской области окна, используем высоту иконки.
        cmp     [size.cy],ICON_SIZE
        ja      @F
        mov     [size.cy],ICON_SIZE
    @@:
        add     [size.cy],INDENT_SIZE*2

; Получаем Y координату кнопки.
        mov     eax,[size.cy]
        mov     [nYButton],eax

; Получаем общую высоту клиентской области окна.
        add     [size.cy],INDENT_SIZE+HEIGHT_BUTTON

; Переводим размеры клиентской области окна в общие размеры
; окна (добавляем размеры рамок окна).
        invoke  GetWindowRect,[hwnd],rect
        push    [rect.right]
        push    [rect.bottom]
        invoke  GetClientRect,[hwnd],rect
        pop     ecx
        pop     eax
        sub     ecx,[rect.bottom]
        sub     eax,[rect.right]
        add     [size.cy],ecx
        add     [size.cx],eax

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
        test    eax,eax
        je      error
        invoke  SendMessage,eax,WM_SETFONT,[hFont],1

        xor     eax,eax
        jmp     .finish

    .failed:
        mov     eax,-1
        jmp     .finish

  .wm_paint:
        invoke  BeginPaint,[hwnd],ps
        mov     [hDC],eax

; Рисуем иконку программы.
        invoke  DrawIconEx,[hDC],INDENT_SIZE,INDENT_SIZE,[hAboutIcon],ICON_SIZE,ICON_SIZE,0,0,DI_NORMAL

; Выводим информацию о программе.
        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],eax

        invoke  SetBkMode,[hDC],TRANSPARENT

        mov     [rect.left],(INDENT_SIZE*2)+ICON_SIZE
        mov     [rect.top],INDENT_SIZE
        mov     eax,[size.cx]
        mov     [rect.right],eax
        mov     eax,[size.cy]
        mov     [rect.bottom],eax
        invoke  DrawText,[hDC],szVersion,-1,rect,DT_WORDBREAK

        invoke  SelectObject,[hDC],[hFont]
        mov     [hFont],eax

        invoke  EndPaint,[hwnd],ps
        xor     eax,eax
        jmp     .finish

  .wm_command:
        cmp     [wparam],IDM_About
        je      .idm_about
        cmp     [wparam],BN_CLICKED shl 16 + IDB_OK
        je      .idb_ok
        cmp     [wparam],IDM_Exit
        je      .idm_exit
        xor     eax,eax
        jmp     .finish

    .idm_about:
; Показываем окно.
        invoke  ShowWindow,[hwnd],SW_SHOWNORMAL
        invoke  MessageBeep,MB_ICONINFORMATION
        xor     eax,eax
        jmp     .finish

    .idb_ok:
; Скрываем окно.
        invoke  ShowWindow,[hwnd],SW_HIDE
        xor     eax,eax
        jmp     .finish

    .idm_exit:
        invoke  DestroyWindow,[hwnd]
        xor     eax,eax
        jmp     .finish

  .wm_shellnotify:
        cmp     [wparam],ID_TRAY
        jne     .finish
        cmp     [lparam],WM_LBUTTONDOWN
        je      .show_tray_popup
        cmp     [lparam],WM_RBUTTONDOWN
        je      .show_tray_popup
        xor     eax,eax
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
        xor     eax,eax
        jmp     .finish

  .wm_restore:
; Восстановим иконку в трее.
        invoke  Shell_NotifyIcon,NIM_ADD,node
        xor     eax,eax
        jmp     .finish

  .wm_destroy:
        invoke  Shell_NotifyIcon,NIM_DELETE,node
        invoke  DeleteObject,[hFont]
        invoke  DestroyMenu,[hTrayMenu]
        invoke  PostQuitMessage,0
        xor     eax,eax
  .finish:
        ret
endp

;--------------------------------------------------------------
; Функция создает шрифт.
; lpszFontFace - указатель на символьную строку с названием
; новой гарнитуры шрифта.
;--------------------------------------------------------------
proc CreateGUIFont uses esi edi, lpszFontFace

  CLEARTYPE_QUALITY = 5

locals
  lf LOGFONT
endl

; Получаем шрифт, используемый по умолчанию.
        invoke  GetStockObject,DEFAULT_GUI_FONT

; Если название шрифта не указано, то выходим из функции,
; возвращая шрифт, используемый по умолчанию.
        cmp     [lpszFontFace],0
        je      .exit
        mov     edx,[lpszFontFace]
        cmp     word [edx],0
        je      .exit

; Получаем и изменяем атрибуты шрифта.
        lea     edx,[lf]
        invoke  GetObject,eax,sizeof.LOGFONT,edx
        test    eax,eax
        je      .exit

        mov     [lf.lfWeight],FW_NORMAL
        mov     [lf.lfQuality],CLEARTYPE_QUALITY

        cld
        mov     esi,[lpszFontFace]
        lea     edi,[lf.lfFaceName]
        mov     ecx,sizeof.LOGFONT.lfFaceName / 4
        rep     movsd

        lea     eax,[lf]
        invoke  CreateFontIndirect,eax
  .exit:
        ret
endp

;--------------------------------------------------------------
; Функция получает размеры блока текста.
; hDC - дескриптор устройства.
; lpszText - указатель на символьную строку с текстом.
; lpSIZE - указатель на структуру SIZE.
;--------------------------------------------------------------
proc GetTextSize hDC,lpszText,lpSIZE

locals
  rect RECT
endl

; Если текст не указан, то выходим из функции, возвращая ноль.
        xor     eax,eax
        cmp     [lpszText],eax
        je      .exit

        mov     edx,[lpszText]
        cmp     [edx],ax
        je      .exit

; Обнуляем rect.left и rect.top.
        lea     edx,[rect]
        mov     [edx],eax
        mov     [edx+4],eax

; Получаем rect.right и rect.bottom размеры текста.
        invoke  DrawText,[hDC],[lpszText],-1,edx,DT_CALCRECT
        test    eax,eax
        je      .exit

; Если нет указателя на структуру SIZE, то выходим из функции,
; возвращая ширину текста.
        cmp     [lpSIZE],0
        je      .exit

; Копируем rect.right и rect.bottom в структуру SIZE,
; возвращаем на нее указатель.
        lea     eax,[rect+8]
        mov     edx,[eax]
        mov     ecx,[eax+4]

        mov     eax,[lpSIZE]
        mov     [eax],edx
        mov     [eax+4],ecx

  .exit:
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

  szVersion  du 'NoInactivity - version 1.7 (x86-32)',10,\
                'The program to reset the timer system inactivity.',10,\
                'Copyright © 2010-2012 Zummenix. All Rights Reserved.',0

; Имя сообщения для восстановления иконки после сбоя Explorer'а.
  szTaskbarCreated du 'TaskbarCreated',0

  align 4
  wc WNDCLASS 0,WindowProc,0,0,0,0,0,COLOR_BTNFACE+1,0,szClass

  pt   POINT
  ps   PAINTSTRUCT
  msg  MSG
  node NOTIFYICONDATA
  size SIZE
  rect RECT

  hTrayMenu      dd ?
  hAboutIcon     dd ?
  hFont          dd ?
  hDC            dd ?
  nXButton       dd ?
  nYButton       dd ?

; Идентификатор сообщения для восстановления иконки после сбоя Explorer'а.
  msgTaskbarCreated dd ?

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
        db 'type="win32"'
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
