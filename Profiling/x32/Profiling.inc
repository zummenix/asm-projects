
proc Profiling.getTime

locals
  st SYSTEMTIME
endl

        lea     eax,[st]
        invoke  GetSystemTime,eax

; Converting seconds to milliseconds.
        movzx   ecx,[st.wSecond]
        movzx   edx,[st.wMilliseconds]
        imul    eax,ecx,1000
        add     eax,edx
        ret
endp

proc Profiling.showResult StartTime

locals
  buffer rb 80h
endl

; Получаем конечное значение времени.
        stdcall Profiling.getTime

; Получаем разницу между начальным и конечным значением времени,
; если необходимо, то корректируем.
        mov     edx,[StartTime]
        cmp     eax,edx
        jae     @F
        add     eax,60000
    @@:
        sub     eax,edx

; Получим отдельно секунды и миллисекунды.
        xor     edx,edx
        mov     ecx,1000
        div     ecx

; Формируем строку и показываем результат.
        lea     ecx,[buffer]
        cinvoke wsprintf,ecx,_format,eax,edx

        lea     eax,[buffer]
        invoke  MessageBox,0,eax,_profiling,MB_OK
        ret

  _profiling TCHAR 'Profiling',0
  _format    TCHAR 'Time profiling %u.%03u seconds.',0
endp
