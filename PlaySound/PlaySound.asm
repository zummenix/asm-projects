
format PE GUI 4.0

SND_FILENAME    = 0x20000
SND_ASYNC       = 0x1

include 'win32w.inc'

        invoke  MessageBox,0,_title,_caption,0
        invoke  PlaySound,_sound_file,0,SND_FILENAME+SND_ASYNC
        invoke  Sleep,2000

        invoke  ExitProcess,0

data import

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          winmm,'WINMM.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  import  winmm,\
          PlaySound,'PlaySoundA'

end data

  _caption      TCHAR 'FASM',0
  _title        TCHAR 'Hello World',0
  _sound_file   db    'Ok.wav',0