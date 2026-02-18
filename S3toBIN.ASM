format PE64 Console 5.0

entry Start

include 'win64a.inc'

section '.data' data readable writeable

IDR_ICON                     =  17

struct GdiplusStartupInput              ;cтруктура для работы с GDI+
       GdiplusVersion           dq ?
       DebugEventCallback       dq ?
       SuppressBackgroundThread dq ?
       SuppressExternalCodecs   dq ?
ends

        conTitle    db '*.S3 to *.BIN',0
        strY        db 'Drop firmware file *.s3 or *.sre into console and press Enter...',13,10,0
        anyKey      db 'Press any key to exit',13,10,0
        adressX     db '%x',0
align 8                 ;выравнивание адреса следующей строки до кратности 8 байт
        name        rq 50
        adress      dd ?
;данные для работы с консолью
        STD_INP_HNDL  dd -10
        STD_OUTP_HNDL dd -11
        hStdIn        dd 0
        hStdOut       dd 0
;для перевода из String в HEX
items:
        db 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,10,11,12,13,14,15   ;символ 0 для дистанции, так как в hex 0x40 - это @, 0x3F - это вопрос и т.д.
align 8
;для чтения файлов
_hHeap          dq 0          ;дескриптор системной кучи (адрес динамической памяти для приложения)
_hFile          dq 0          ;дескриптор файла
_hFile2         dq 0          ;дескриптор файла
_lpBuffer       dq 0          ;адрес буфера динамической памяти
_HiSizeFile     dq 00         ;для записи старшего двойного слова размера файла
_r              dq 00         ;для записи фактического число прочитанных (записанных) байт
_FileSize       dq 0

section '.text' code readable executable
 
Start:
        sub     rsp,8               ;Make stack dqword aligned
        invoke  SetConsoleTitleA,conTitle
        test    eax,eax
        jz      exit
        invoke  GetStdHandle,[STD_OUTP_HNDL]
        mov     [hStdOut],eax
        invoke  GetStdHandle,[STD_INP_HNDL]
        mov     [hStdIn],eax
;работа с командной строкой
        invoke  printf,strY
        invoke  gets,name
;убрать вторую кавычку при наличии
        mov     rdi,name
        mov     rcx,0x190
        xor     rax,rax                 ;rax = 0 - что ищем
        xor     rbx,rbx
nextReplacement:
        repne   scasb                   ;ищем 0
        mov     r14,rdi
        mov     bl,[rdi-2]              ;проверяем
        cmp     bl,0x22
        jne     noCopy
        xor     rbx,rbx
        mov     [rdi-2],bl              ;меняем на ноль
        mov     rsi,name+1              ;откуда копировать
        mov     rdi,name                ;куда копировать
        mov     rcx,0x18F               ;сколько копировать
        rep     movsb
        sub     r14,2                   ;минус 2 кавычки
noCopy:
;загружаем список
        call    [GetProcessHeap]   ;получаем дескриптор системной кучи (адрес динамической памяти для приложения)
        mov     [_hHeap],rax
;открытие файла и сохранение его дескриптора
        invoke  CreateFileA,name,GENERIC_READ,FILE_SHARE_READ,0,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
        mov     [_hFile],rax
;определение размера файла
        invoke  GetFileSize,rax,_HiSizeFile
        mov     r15,_FileSize
        mov     [r15],rax
        push    rax
        shl     rax,2           ;умножаем на 4, три четверти памяти пойдет под *.bin
;выделяем память под содержимое файла и сохраняем адрес буфера
        invoke  HeapAlloc,[_hHeap],HEAP_ZERO_MEMORY,rax
        mov     [_lpBuffer],rax
        pop     rax
;читаем содержимое файла
        invoke  ReadFile,[_hFile],[_lpBuffer],rax,_r,0
        invoke  CloseHandle,[_hFile]
        mov     [_hFile],0
;дальнейшие действия
        xor     r11,r11
        mov     rsi,r14          ;адрес файла (окончание)
;замена s3 на bin
        sub     rsi,4
        mov     bl,[rsi-1]       ;проверяем, вдруг расширение sre, а не s3
        cmp     bl,0x2E
        je      isSRE
        inc     rsi
isSRE:
        mov     rdi,0x006E6962
        mov     [esi],edi        ;bin
        mov     rdi,[_lpBuffer]
        mov     r15,[_FileSize]  ;для дальнейшего расчета длины строчки
        add     r15,rdi          ;для проверки окончания S3
        mov     rcx,16
again:
        mov     r14,r15
        mov     rax,r15          ;r14 - начало BIN
;выравнивание адреса *.bin до кратности 0x10
        xor     rdx,rdx
        idiv    rcx
        test    rdx,rdx
        jz      nextData
        inc     r15
        jmp     again
nextData:
        mov     esi,[rdi]
        mov     r12,16
        cmp     esi,0x35313353           ;S315
        je      isS315
        mov     r12,15
        cmp     esi,0x34313353           ;S314
        je      isS315
        mov     r12,14
        cmp     esi,0x33313353           ;S313
        je      isS315
        mov     r12,13
        cmp     esi,0x32313353           ;S312
        je      isS315
        mov     r12,12
        cmp     esi,0x31313353           ;S311
        je      isS315
        mov     r12,11
        cmp     esi,0x30313353           ;S310
        je      isS315
        mov     r12,10
        cmp     esi,0x46303353           ;S30F
        je      isS315
        mov     r12,9
        cmp     esi,0x45303353           ;S30E
        je      isS315
        mov     r12,8
        cmp     esi,0x44303353           ;S30D
        je      isS315
        mov     r12,7
        cmp     esi,0x43303353           ;S30C
        je      isS315
        mov     r12,6
        cmp     esi,0x42303353           ;S30B
        je      isS315
        mov     r12,5
        cmp     esi,0x41303353           ;S30A
        je      isS315
        mov     r12,4
        cmp     esi,0x39303353           ;S309
        je      isS315
        mov     r12,3
        cmp     esi,0x38303353           ;S308
        je      isS315
        mov     r12,2
        cmp     esi,0x37303353           ;S307
        je      isS315
        mov     r12,1
        cmp     esi,0x36303353           ;S306
        je      isS315
        inc     rdi
        cmp     r15,rdi
        jb      subExit
        jmp     nextData
isS315:
        xor     rcx,rcx
        xor     rbx,rbx
        xor     rax,rax
;перевод адреса из String в HEX
        mov     esi,adress
        mov     cl,[rdi+4]               ;адрес после S315
        sub     cl,0x30
        mov     bl,[items+rcx]
        imul    rbx,0x10
        mov     cl,[rdi+4+1]             ;адрес после S315+1
        sub     cl,0x30
        mov     al,[items+rcx]
        add     rax,rbx
        mov     [esi+3],al               ;адрес в HEX

        mov     cl,[rdi+6]               ;адрес после S315+2
        sub     cl,0x30
        mov     bl,[items+rcx]
        imul    rbx,0x10
        mov     cl,[rdi+6+1]             ;адрес после S315+3
        sub     cl,0x30
        mov     al,[items+rcx]
        add     rax,rbx
        mov     [esi+2],al               ;адрес в HEX

        mov     cl,[rdi+8]               ;адрес после S315+4
        sub     cl,0x30
        mov     bl,[items+rcx]
        imul    rbx,0x10
        mov     cl,[rdi+8+1]             ;адрес после S315+5
        sub     cl,0x30
        mov     al,[items+rcx]
        add     rax,rbx
        mov     [esi+1],al               ;адрес в HEX

        mov     cl,[rdi+10]              ;адрес после S315+6
        sub     cl,0x30
        mov     bl,[items+rcx]
        imul    rbx,0x10
        mov     cl,[rdi+10+1]            ;адрес после S315+7
        sub     cl,0x30
        mov     al,[items+rcx]
        add     rax,rbx
        mov     [esi],al                 ;адрес в HEX

        xor     rsi,rsi
        mov     esi,[adress]
        mov     r13,rsi
        ;sub     r13,0x20000000
        shl     r13d,4                   ;затираем первую цифру адреса
        shr     r13d,4
        add     r13,r14
        mov     rsi,r13
        add     rsi,r12
        add     rdi,0xC
_isS315:
        mov     cl,[rdi]                 ;откуда
        sub     cl,0x30
        mov     bl,[items+rcx]
        imul    rbx,0x10
        mov     cl,[rdi+1]               ;откуда
        sub     cl,0x30
        mov     al,[items+rcx]
        add     rax,rbx
        mov     [r13],al
        inc     r13
        add     rdi,2
        cmp     r13,rsi
        jnz     _isS315
;определение границы BIN
        cmp     r11,r13
        ja      nextData
        mov     r11,r13
        jmp     nextData
subExit:
;сохраняем файл
        push    r11
        invoke  CreateFile,name,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
        mov     [_hFile],rax
        pop     r11
        sub     r11,r14
        invoke  WriteFile,rax,r14,r11,_r,0
        invoke  CloseHandle,[_hFile]
;освободим память
        invoke  HeapFree,[_hHeap],0,[_lpBuffer]
        mov     [_lpBuffer],0
;сообщение о завершении
        invoke  printf,anyKey
        sub     rsp,2048
        call    [getch]
        add     rsp,2048
exit:
        invoke  ExitProcess,0

section '.idata' import data readable
 
  library kernel32,'KERNEL32.DLL',\
          msvcrt,'msvcrt.dll'
 
  include 'api\kernel32.inc'

  import msvcrt,\
         printf,'printf',\
         gets,'gets',\
         sscanf,'sscanf',\
         scanf,'scanf',\
         getch, '_getch'