
format PE GUI 4.0

include 'win32w.inc'

  SIZE_BUFFER   = 100h

        invoke  GetSystemMetrics,SM_CXSCREEN
        mov     [cxS],eax

        invoke  GetSystemMetrics,SM_CYSCREEN
        mov     [cyS],eax

        cinvoke wsprintf,_buffer,_fmt,[cxS],[cyS]

        invoke  MessageBox,0,_buffer,_caption,0
        invoke  ExitProcess,0

data import

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

end data

  _fmt          TCHAR 'Screen size: %u x %u pixels',0
  _caption      TCHAR 'ScreenSize',0
  _buffer       rb SIZE_BUFFER

  cxS   dd ?
  cyS   dd ?
