;
; hh1.nasm: 664-byte, tiny hello-world Win32 PE .exe
; by pts@fazekas.hu at Sat Jan 13 11:53:58 CET 2018
;
; How to compile hh1.exe:
;
;   $ nasm -f bin -o hh1.exe hh1.nasm
;   $ chmod 755 hh1.exe  # For QEMU Samba server.
;   $ ndisasm -b 32 -e 0x200 -o 0x403000 hh1.exe
;
; hh1.asm was inspired by the 268-byte .exe on
; https://www.codejuggle.dj/creating-the-smallest-possible-windows-executable-using-assembly-language/
; . The fundamental difference is that hh1.exe works on Windows XP ... Windows
; 10, while the program above doesn't work on Windows XP.
;
; The generated hh1.exe works on:
;
; * Wine 1.6.2 on Linux.
; * Windows XP SP3, 32-bit: Microsoft Windows XP [Version 5.1.2600]
; * Windows 10 64-bit: Microsoft Windows [Version 10.0.16299.192]
;
; Output .exe file size in bytes (approximately):
;
;   len(text_bytes) + len(data_bytes) + len(rodata_bytes) +
;   + 384
;   + sum(len(name) for name in imported_names) + 2 * len(imported_names) - 1
;   + 8 * len(imported_names) + 6
;   + sum(len(name) for name in library_names) + len(library_names)
;   + 20 * len(library_names)
;
; Assumptions:
;
; * len(imported_names) >= 1: ['ExitProcess']
; * len(library_names) >= 1: ['kernel32']
;
bits 32
imagebase equ 0x400000  ; Default base since Windows 95.
textbase equ imagebase + 0x3000
file_alignment equ 0x200
bits 32
org 0  ; Can be anything, this file doesn't depend on it.

_filestart:
;_text:

IMAGE_DOS_HEADER:  ; Truncated, breaks file(1) etc.
db 'MZ'
times 10 db 'x'

IMAGE_NT_HEADERS:
Signature: dw 'PE', 0

IMAGE_FILE_HEADER:
Machine: dw 0x14c  ; IMAGE_FILE_MACHINE_I386
NumberOfSections: dw (_headers_end - _sechead) / 40  ; Windows XP needs >= 3.
TimeDateStamp: dd 0x00000000
PointerToSymbolTable: dd 0x00000000
NumberOfSymbols: dd 0x00000000
SizeOfOptionalHeader: dw _datadir_end - _opthd  ; Windows XP needs >= 0x78.
Characteristics: dw 0x030f
_opthd:
IMAGE_OPTIONAL_HEADER32:
Magic: dw 0x10b  ; IMAGE_NT_OPTIONAL_HDR32_MAGIC
MajorLinkerVersion: db 0
MinorLinkerVersion: db 0
SizeOfCode: dd 0x00000000
SizeOfInitializedData: dd 0x00000000
SizeOfUninitializedData: dd 0x00000000
AddressOfEntryPoint: dd (textbase - imagebase) + (_entry - _text)
BaseOfCode: dd 0x00000000
BaseOfData: dd (IMAGE_NT_HEADERS - _filestart)  ; Overlaps with: IMAGE_DOS_HEADER.e_lfanew.
ImageBase: dd imagebase
SectionAlignment: dd 0x1000  ; Minimum value for Windows XP.
%if file_alignment == 0 || file_alignment & (file_alignment - 1)
%fatal Invalid file_alignment, must be a power of 2.
%endif
%if file_alignment < 0x200
%fatal Windows XP needs file_alignment >= 0x200
%endif
FileAlignment: dd file_alignment  ; Minimum value for Windows XP.
MajorOperatingSystemVersion: dw 4
MinorOperatingSystemVersion: dw 0
MajorImageVersion: dw 1
MinorImageVersion: dw 0
MajorSubsystemVersion: dw 4
MinorSubsystemVersion: dw 0
Win32VersionValue: dd 0
SizeOfImage: dd (textbase - imagebase) + (_eof + bss_size - _text)  ; Wine rounds it up to a multiple of 0x1000, and loads and maps that much.
SizeOfHeaders: dd _headers_end - _filestart  ; Windows XP needs > 0.
CheckSum: dd 0
Subsystem: dw 3  ; IMAGE_SUBSYSTEM_WINDOWS_CUI; gcc -mconsole
DllCharacteristics: dw 0
SizeOfStackReserve: dd 0x00100000
SizeOfStackCommit: dd 0x00001000
SizeOfHeapReserve: dd 0
SizeOfHeapCommit: dd 0
LoaderFlags: dd 0
; If we hardcode 2 here, on Windows XP we can put arbitrary bytes to
; IMAGE_DIRECTORY_ENTRY_RESOURCE.VirtualAddress and .Size. If we put
; 3 here (autogenerated), then the values must be 0.
;NumberOfRvaAndSizes: dd (_datadir_end - _datadir) / 8  ; Number of IMAGE_DATA_DIRECTORY entries below.
NumberOfRvaAndSizes: dd 2

_datadir:
DataDirectory:
IMAGE_DIRECTORY_ENTRY_EXPORT:
.VirtualAddress: dd 0x00000000
.Size: dd 0x00000000
IMAGE_DIRECTORY_ENTRY_IMPORT:
.VirtualAddress: dd (textbase - imagebase) + (_idescs - _text)
.Size: dd _idata_data_end - _idata
IMAGE_DIRECTORY_ENTRY_RESOURCE:
.VirtualAddress_AndSize: db 'tiny.exe'
%if 0
; Changing all 0x78787878 to 0 below may fix startup errors.
IMAGE_DIRECTORY_ENTRY_EXCEPTION:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_SECURITY:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_BASERELOC:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_DEBUG:
.VirtualAddress: dd 0x78787878
.Size: dd 0x00000000
IMAGE_DIRECTORY_ENTRY_ARCHITECTURE:
.VirtualAddress: dd 0x00000000
.Size: dd 0x00000000
IMAGE_DIRECTORY_ENTRY_GLOBALPTR:
.VirtualAddress: dd 0x00000000
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_TLS:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_IAT:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
 Missing:
IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
IMAGE_DIRECTORY_ENTRY_RESERVED:
.VirtualAddress: dd 0x78787878
.Size: dd 0x78787878
%endif
_datadir_end:

_sechead:

IMAGE_SECTION_HEADER__0:
.Name: db '.dummy1', 0
.VirtualSize: dd 0x000000001  ; Must be positive for Windows XP.
.VirtualAddress: dd 0x1000  ; Must be positive and divisible by 0x1000 for Windows XP.
.SizeOfRawData: dd 0x00000000
.PointerToRawData: dd 0x00000000
.PointerToRelocations: dd 0
.PointerToLineNumbers: dd 0
.NumberOfRelocations: dw 0
.NumberOfLineNumbers: dw 0
.Characteristics: dd 0xc0300040

IMAGE_SECTION_HEADER__1:
.Name: db '.dummy2', 0
.VirtualSize: dd 0x00000001  ; Must be positive for Windows XP.
.VirtualAddress: dd 0x2000  ; Must be positive, divisible by 0x1000, and larger then the prev .VirtualAddress for Windows XP.
.SizeOfRawData: dd 0x00000000
.PointerToRawData: dd 0x00000000
.PointerToRelocations: dd 0
.PointerToLineNumbers: dd 0
.NumberOfRelocations: dw 0
.NumberOfLineNumbers: dw 0
.Characteristics: dd 0xc0300040

IMAGE_SECTION_HEADER__2:
.Name: db '.text', 0, 0, 0
.VirtualSize: dd (_eof - _text) + bss_size
%if (textbase - imagebase) & 0xfff
%fatal _text doesn't start at page boundary, needed by Windows XP.
%endif
%if (textbase - imagebase) <= 0x2000
%fatal _text doesn't start later than the previous sections, needed by Windows XP.
%endif
.VirtualAddress: dd textbase - imagebase
.SizeOfRawData: dd _eof - _text
.PointerToRawData: dd _text - _filestart
.PointerToRelocations: dd 0
.PointerToLineNumbers: dd 0
.NumberOfRelocations: dw 0
.NumberOfLineNumbers: dw 0
.Characteristics: dd 0xe0300020

_headers_end:
; We can check it only this late, when _headers_end is defined.
%if (_headers_end - _sechead) % 40 != 0
%fatal Multiples of IMAGE_SECTION_HEADER needed.
%endif
%if (_headers_end - _sechead) / 40 < 3
%fatal Windows XP needs at least 3 sections.
%endif

times 0x200 - ($-$$) db 'x'

;times 0x100 db 'y'  ; Doesn't work, _text is not aligned properly.
;times 0x200 db 'y'  ; Works, making the .exe larger.

_text:

_entry:
; Arguments pushed in reverse order, popped by the callee.
; WINBASEAPI HANDLE WINAPI GetStdHandle (DWORD nStdHandle);
; HANDLE hfile = GetStdHandle(STD_OUTPUT_HANDLE);
push byte -11                ; STD_OUTPUT_HANDLE
call [textbase + (__imp__GetStdHandle@4 - _text)]
; Arguments pushed in reverse order, popped by the callee.
; WINBASEAPI WINBOOL WINAPI WriteFile (HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);
; DWORD bw;
push eax                     ; Value does't matter.
mov ecx, esp
push byte 0                  ; lpOverlapped
push ecx                     ; lpNumberOfBytesWritten = &dw
push byte (_msg_end - _msg)  ; nNumberOfBytesToWrite
push textbase + (_msg - _text)  ; lpBuffer
push eax                     ; hFile = hfile
call [textbase + (__imp__WriteFile@20 - _text)]
;pop eax                     ; This would pop dw. Needed for cleanup.
; Arguments pushed in reverse order, popped by the callee.
; WINBASEAPI DECLSPEC_NORETURN VOID WINAPI ExitProcess(UINT uExitCode);
push byte 0                  ; uExitCode
call [textbase + (__imp__ExitProcess@4 - _text)]

_data:
_msg:
db 'Hello, World!', 13, 10
_msg_end:

; This can be before of after _entry, it doesn't matter.
_idata:  ; Relocations, IMAGE_DIRECTORY_ENTRY_IMPORT data.
_hintnames:
dd (textbase - imagebase) + (IMAGE_IMPORT_BY_NAME_ExitProcess - _text)
dd (textbase - imagebase) + (IMAGE_IMPORT_BY_NAME_GetStdHandle - _text)
dd (textbase - imagebase) + (IMAGE_IMPORT_BY_NAME_WriteFile - _text)
dd 0  ; Marks end-of-list.
_iat:  ; Modified by the PE loader before jumping to _entry.
__imp__ExitProcess@4:  dd (textbase - imagebase) + (IMAGE_IMPORT_BY_NAME_ExitProcess - _text)
__imp__GetStdHandle@4: dd (textbase - imagebase) + (IMAGE_IMPORT_BY_NAME_GetStdHandle - _text)
__imp__WriteFile@20:   dd (textbase - imagebase) + (IMAGE_IMPORT_BY_NAME_WriteFile - _text)
dd 0  ; Marks end-of-list.
IMAGE_IMPORT_BY_NAME_ExitProcess:
.Hint: dw 0
.Name: db 'ExitProcess'  ; Terminated by the subsequent .Hint.
IMAGE_IMPORT_BY_NAME_GetStdHandle:
.Hint: dw 0
.Name: db 'GetStdHandle'  ; Terminated by the subsequent .Hint.
IMAGE_IMPORT_BY_NAME_WriteFile:
.Hint: dw 0
.Name: db 'WriteFile'  ; Terminated below.
db 0  ; Terminates last .Name.

_KERNEL32_str: db 'kernel32', 0  ; 'KERNEL32' and 'KERNEL32.dll' also work.
_idescs:
IMAGE_IMPORT_DESCRIPTOR__0:
.OriginalFirstThunk: dd (textbase - imagebase) + (_hintnames - _text)
.TimeDateStamp: dd 0
.ForwarderChain: dd 0
.Name: dd (textbase - imagebase) + (_KERNEL32_str - _text)
.FirstThunk: dd (textbase - imagebase) + (_iat - _text)

_idata_data_end:
_eof:
;bss_size equ 0
;IMAGE_IMPORT_DESCRIPTOR__1:  ; Empty, marks end-of-list.
;.OriginalFirstThunk: dd 0
;.TimeDateStamp: dd 0
;.ForwarderChain: dd 0
;.Name: dd 0
;.FirstThunk: dd 0
;_idata_end:
bss_size equ 20  ; _idata_end - _eof

%if (_text - _filestart) & (file_alignment - 1)
%fatal _text is not aligned to file_alignment, needed by Windows XP.
%endif

