
format PE GUI

  include 'win32w.inc'

section '.text' code readable executable

  start:
        stdcall Profiling.getTime
        mov     [ValueTime],eax

        invoke  Sleep,999

        stdcall Profiling.showResult,[ValueTime]
        invoke  ExitProcess,0

  include 'Profiling.inc'

section '.data' data readable writeable

  ValueTime dd ?

section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          gdi32,'GDI32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\gdi32.inc'
  include 'api\user32.inc'