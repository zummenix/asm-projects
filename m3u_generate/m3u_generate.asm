
  ; m3u-generate by Zummenix

format PE GUI 4.0

  include 'win32a.inc'

  M3U_LIST      = 65536 ;byte

  ; Ищем первый mp3 файл, сохраняем дескриптор поиска.
        invoke  FindFirstFile,lpFile,lpwfd
        cmp     eax,-1
        je      .exit
        mov     [hFind],eax

  ; Формируем имя файла по типу: <Имя директории запуска программы>.m3u
        invoke  GetCurrentDirectory,MAX_PATH-1,m3u_name
        mov     ecx,m3u_name+MAX_PATH
        xor     eax,eax

  @@:
        mov     al,[ecx]
        cmp     eax,'\'
        jz      @F      ; down
        dec     ecx
        jmp     @R      ; up

  @@:
        mov     edx,m3u_name
        xor     eax,eax
        inc     ecx

  @@:
        mov     al,[ecx]
        test    eax,eax
        jz      @F      ; down
        mov     [edx],al
        inc     ecx
        inc     edx
        jmp     @R      ; up

  @@:
        mov     dword [edx],'.m3u'
        add     edx,4
        mov     dword [edx],0

  ; Создаём m3u файл с готовым именем.
        invoke  CreateFile,m3u_name,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
        cmp     eax,-1
        jz      .exit
        mov     [m3u_handle],eax

  ; Добавляем первый найденный файл в m3u-список.
        mov     [m3u_mem_selector],m3u_list
        call    .add_string_in_list

  .next_file:

  ; Ищем последующие файлы в цикле и добавляем их в список.
        invoke  FindNextFile,[hFind],lpwfd
        test    eax,eax
        je      .find_close

        call    .add_string_in_list
        jmp     .next_file

  .find_close:

  ; Закрываем дескриптор поиска и сохраняем список в файл.
        invoke  FindClose,[hFind]

        sub     [num_to_write],2
        invoke  WriteFile,[m3u_handle],m3u_list,[num_to_write],num_to_write,0
        test    eax,eax
        jz      .exit

  ; Закрываем дескриптор файла и выдаём сообщение об успешном завершении программы.
        invoke  CloseHandle,[m3u_handle]

        invoke  MessageBox,0,mes,mes-1,0

  .exit:

        invoke  ExitProcess,0


  .add_string_in_list:  ;CALL FUNC

        push    esi edi
        mov     esi,lpwfd.cFileName
        mov     edi,[m3u_mem_selector]
        xor     eax,eax

    .next_symbol:

        mov     al,[esi]
        test    eax,eax
        jz      .the_end
        mov     [edi],al
        inc     esi
        inc     edi
        inc     [num_to_write]
        jmp     .next_symbol

    .the_end:

        mov     word [edi],0A0Dh
        mov     [m3u_mem_selector],edi
        add     [m3u_mem_selector],2
        add     [num_to_write],2
        pop     edi esi
        ret

data import

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

end data

  lpFile                db '*.mp3',0
  mes                   db 'm3u-list is generate!',13,10
                        db 'Press OK',0

  hFind                 dd ?
  m3u_handle            dd ?
  num_to_write          dd ?
  m3u_mem_selector      dd ?
  m3u_name_selector     dd ?

  lpwfd                 WIN32_FIND_DATA

  m3u_name              rb MAX_PATH
  m3u_list              rb M3U_LIST
