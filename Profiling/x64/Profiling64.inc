
proc Profiling.getTime

locals
  st SYSTEMTIME
endl

        frame
        lea     rcx,[st]
        invoke  GetSystemTime,rcx

; Converting seconds to milliseconds.
        movzx   rcx,[st.wSecond]
        movzx   rdx,[st.wMilliseconds]
        imul    rax,rcx,1000
        add     rax,rdx
        endf
        ret
endp

proc Profiling.showResult StartTime

locals
  buffer rb 80h
endl

        frame
        mov     [StartTime],rcx

; Получаем конечное значение времени.
        stdcall Profiling.getTime

; Получаем разницу между начальным и конечным значением времени,
; если необходимо, то корректируем.
        mov     rdx,[StartTime]
        cmp     rax,rdx
        jae     @F
        add     rax,60000
    @@:
        sub     rax,rdx

; Получим отдельно секунды и миллисекунды.
        xor     rdx,rdx
        mov     rcx,1000
        div     rcx

; Формируем строку и показываем результат.
        lea     rcx,[buffer]
        mov     r9,rdx
        mov     r8,rax
        mov     rdx,_format
        cinvoke wsprintf,rcx,rdx,r8,r9

        lea     rdx,[buffer]
        invoke  MessageBox,0,rdx,_profiling,MB_OK
        endf
        ret

  _profiling TCHAR 'Profiling',0
  _format    TCHAR 'Time profiling %u.%03u seconds.',0
endp
