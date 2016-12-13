
format PE64 GUI

  include 'win64w.inc'

section '.text' code readable executable

  start:
        sub     rsp,8
        stdcall Profiling.getTime
        mov     [ValueTime],rax

        invoke  Sleep,999

        stdcall Profiling.showResult,[ValueTime]
        invoke  ExitProcess,0

  include 'Profiling64.inc'

section '.data' data readable writeable

  ValueTime dq ?

section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          gdi32,'GDI32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\gdi32.inc'
  include 'api\user32.inc'