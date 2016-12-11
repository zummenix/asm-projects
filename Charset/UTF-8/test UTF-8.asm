
format PE GUI 4.0

include 'win32w.inc'

        stdcall FileToMemory,_file_name,_file_buffer,38
        test    eax,eax
        je      .exit

        stdcall UTF8_TO_UTF16LE,_file_buffer,_buffer,100h,0
        test    eax,eax
        je      .exit

        invoke  MessageBox,0,_buffer,0,MB_ICONINFORMATION

  .exit:
        invoke  ExitProcess,0

proc UTF8_TO_UTF16LE lpString,lpBuffer,nSizeBuffer,boolBOM
        push    esi edi
        mov     esi,[lpString]
        mov     edi,[lpBuffer]
        mov     ecx,edi
        add     ecx,[nSizeBuffer]
        sub     ecx,4                   ; Конец буфера данных

; Пропускаем сигнатуру UTF-8, если есть (0xEF,0xBB,0xBF)
        mov     eax,[esi]
        and     eax,0x00FFFFFF
        cmp     eax,0x00BFBBEF
        jne     @F
        add     esi,3
    @@:

; Добавляем сигнатуру UTF-16LE, если нужно (0xFF,0xFE)
        mov     eax,0xFEFF
        cmp     [boolBOM],1
        je      .write_word

  .next_byte:
        xor     eax,eax
        lodsb
        test    eax,eax
        je      .exit           ; Если конец строки
        test    eax,10000000b
        jnz     @F              ; Если 7й бит установлен

  .write_word:
        stosw
        cmp     edi,ecx
        jb      .next_byte      ; Если выход за пределы буфера не произошел
        ; FALSE
        xor     eax,eax
        stosw
        jmp     .finish

    @@:
        test    eax,00100000b
        jnz     @F              ; Если 5й бит установлен
        and     eax,00111111b
        mov     edx,eax
        shl     edx,6
        lodsb
        and     eax,01111111b
        or      eax,edx
        jmp     .write_word

    @@:
        test    eax,00010000b
        jnz     @F              ; Если 4й бит установлен
        and     eax,00011111b
        mov     edx,eax
        shl     edx,6
        lodsb
        and     eax,01111111b
        or      edx,eax
        shl     edx,6
        lodsb
        and     eax,01111111b
        or      edx,eax
        mov     eax,edx
        jmp     .write_word

    @@:
        xor     eax,eax
        stosw
        dec     eax
        jmp     .finish         ; Встретились символы, не входящие в UTF16

  .exit:
        stosw
        ; TRUE
        inc     eax
  .finish:
        pop     edi esi
        ret
endp

proc FileToMemory lpFileName,lpMemory,nSize

  locals
  hFile                 dd ?
  lpNumberOfBytesRead   dd ?
  endl

        invoke  CreateFile,[lpFileName],GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
        cmp     eax,-1
        je      .error_create_file
        mov     [hFile],eax

        lea     eax,[lpNumberOfBytesRead]
        invoke  ReadFile,[hFile],[lpMemory],[nSize],eax,0
        test    eax,eax
        je      .error_read_file

        invoke  CloseHandle,[hFile]
        mov     eax,1
        ret

  .error_read_file:
        invoke  CloseHandle,[hFile]
  .error_create_file:
        xor     eax,eax
        ret
endp

data import

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

end data

  _file_name    TCHAR 'test UTF-8.txt',0
  _file_buffer  rb 100h
  _buffer       rb 100h
