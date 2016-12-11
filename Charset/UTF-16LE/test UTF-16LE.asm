
format PE GUI 4.0

include 'win32w.inc'

        stdcall FileToMemory,_file_name,_file_buffer,60
        test    eax,eax
        je      .exit

        stdcall UTF16LE_TO_UTF8,_file_buffer,_buffer,100h,1
        test    eax,eax
        je      .exit

        stdcall MemoryToFile,_out_file_name,_buffer,38
        test    eax,eax
        je      .exit

        invoke  MessageBox,0,_file_buffer+2,0,MB_ICONINFORMATION

  .exit:
        invoke  ExitProcess,0

proc UTF16LE_TO_UTF8 lpString,lpBuffer,nSizeBuffer,boolBOM
        push    esi edi
        mov     esi,[lpString]
        mov     edi,[lpBuffer]
        mov     ecx,edi
        add     ecx,[nSizeBuffer]
        sub     ecx,4                   ; Конец буфера данных

; Пропускаем сигнатуру UTF-16LE, если есть (0xFF, 0xFE)
        mov     eax,[esi]
        and     eax,0x0000FFFF
        cmp     eax,0x0000FEFF
        jne     @F
        add     esi,2
    @@:

; Добавляем сигнатуру UTF-8, если нужно (0xEF,0xBB,0xBF)
        cmp     [boolBOM],0
        je      @F
        mov     eax,0x00BFBBEF
        stosd
        dec     edi
    @@:

  .next_word:
        xor     eax,eax
        lodsw
        test    eax,eax
        je      .exit
        cmp     eax,0x7F
        jbe     .1_byte
        cmp     eax,0x7FF
        jbe     .2_byte

  .3_byte:
        mov     edx,eax
        shr     eax,12
        or      eax,0000000011100000b
        stosb
        mov     eax,edx
        shl     edx,2
        and     edx,0011111100000000b
        or      edx,1000000010000000b
        and     eax,0000000000111111b
        jmp     .write_word

  .2_byte:
        mov     edx,eax
        shl     edx,2
        and     edx,0001111100000000b
        or      edx,1100000010000000b
        and     eax,0000000000111111b
    .write_word:
        or      eax,edx
        xchg    ah,al
        stosw
        jmp     .check_overflow

  .1_byte:
        stosb
    .check_overflow:
        cmp     edi,ecx
        jb      .next_word      ; Если выход за пределы буфера не произошел
        xor     eax,eax
        jmp     .finish

  .exit:
        stosb
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

proc MemoryToFile lpFileName,lpMemory,nSize

  locals
  hFile                 dd ?
  lpNumberOfBytesRead   dd ?
  endl

        invoke  CreateFile,[lpFileName],GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
        cmp     eax,-1
        je      .error_create_file
        mov     [hFile],eax

        lea     eax,[lpNumberOfBytesRead]
        invoke  WriteFile,[hFile],[lpMemory],[nSize],eax,0
        test    eax,eax
        je      .error_write_file

        invoke  CloseHandle,[hFile]
        mov     eax,1
        ret

  .error_write_file:
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

  _file_name     TCHAR 'test UTF-16LE.txt',0
  _out_file_name TCHAR 'UTF-8.txt',0
  _file_buffer   rb 100h
  _buffer        rb 100h
