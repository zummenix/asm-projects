
format PE GUI 4.0

include 'win32a.inc'

include 'profiling.inc'

  start:
        ProfilingStart [lclock],[hclock]

        ProfilingEnd [lclock],[hclock],_text,_mask

        invoke  ExitProcess,0

data import

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

end data

; For Profiling :::::::::::::::::::::::::::::::::::::::::::::::
  _mask         TCHAR '[edx] = %u',13,10,\                    ;
                      '[eax] = %u',0                          ;
                                                              ;
  lclock        dd ?                                          ;
  hclock        dd ?                                          ;
                                                              ;
  _text         rb 100h                                       ;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
