
format PE GUI

  SIZE_MEMORY = 1*1024

  include 'win32w.inc'

        invoke  GetProcessHeap
        test    eax,eax
        je      exit
        mov     [hHeap],eax

        invoke  HeapAlloc,[hHeap],HEAP_ZERO_MEMORY,SIZE_MEMORY
        test    eax,eax
        je      exit
        mov     [pMemoryBlock],eax

        push    edi
        mov     edi,[pMemoryBlock]
        mov     ecx,SIZE_MEMORY
        xor     eax,eax
        rep     stosb
        pop     edi

        invoke  HeapFree,[hHeap],0,[pMemoryBlock]
        test    eax,eax
        je      exit

        invoke  MessageBox,0,_title,_caption,MB_ICONINFORMATION

  exit:
        invoke  ExitProcess,0

data import

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

end data

  _title        TCHAR 'Hello world',0
  _caption      TCHAR 'Example',0

  hHeap         dd ?
  pMemoryBlock  dd ?