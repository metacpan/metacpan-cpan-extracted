#ifndef H_IOCTLCMD
#define H_IOCTLCMD 1


#ifndef _WINDOWS
typedef UCHAR  BYTE;
typedef USHORT WORD;
typedef ULONG  DWORD;
#endif

#ifndef REPARSE_DATA_BUFFER_HEADER_SIZE
typedef struct _REPARSE_DATA_BUFFER {
    DWORD  ReparseTag;
    WORD   ReparseDataLength;
    WORD   Reserved;
    union {
        struct {
            WORD   SubstituteNameOffset;
            WORD   SubstituteNameLength;
            WORD   PrintNameOffset;
            WORD   PrintNameLength;
            ULONG  Flags; /* 0=絶対パス, 1=相対パス */
            WCHAR  PathBuffer[1];
        } SymbolicLinkReparseBuffer;
        struct {
            WORD   SubstituteNameOffset;
            WORD   SubstituteNameLength;
            WORD   PrintNameOffset;
            WORD   PrintNameLength;
            WCHAR  PathBuffer[1];
        } MountPointReparseBuffer;
        struct {
            BYTE   DataBuffer[1];
        } GenericReparseBuffer;
    };
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;

#define REPARSE_DATA_BUFFER_HEADER_SIZE   FIELD_OFFSET(REPARSE_DATA_BUFFER, GenericReparseBuffer)
#endif /* REPARSE_DATA_BUFFER_HEADER_SIZE */

#ifndef MAXIMUM_REPARSE_DATA_BUFFER_SIZE
#define MAXIMUM_REPARSE_DATA_BUFFER_SIZE (16 * 1024)
#endif

#ifndef IO_REPARSE_TAG_MOUNT_POINT
#define IO_REPARSE_TAG_MOUNT_POINT 0xA0000003L
#endif

#ifndef IO_REPARSE_TAG_SYMLINK
#define IO_REPARSE_TAG_SYMLINK 0xA000000CL
#endif

#undef FSCTL_SET_REPARSE_POINT
#undef FSCTL_GET_REPARSE_POINT
#undef FSCTL_DELETE_REPARSE_POINT
#define FSCTL_SET_REPARSE_POINT         CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 41, METHOD_BUFFERED, FILE_ANY_ACCESS) // REPARSE_DATA_BUFFER,
#define FSCTL_GET_REPARSE_POINT         CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 42, METHOD_BUFFERED, FILE_ANY_ACCESS) // , REPARSE_DATA_BUFFER
#define FSCTL_DELETE_REPARSE_POINT      CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 43, METHOD_BUFFERED, FILE_ANY_ACCESS) // REPARSE_DATA_BUFFER,

//
// Symlinkの定義
//
#define SYMLINKVERSION 0x106

#define IOCTL_SYMLINK_VERSION      (ULONG)CTL_CODE(FILE_DEVICE_UNKNOWN, 0x00, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_SYMLINK_READ_MEMORY  (ULONG)CTL_CODE(FILE_DEVICE_UNKNOWN, 0x01, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_SYMLINK_WRITE_MEMORY (ULONG)CTL_CODE(FILE_DEVICE_UNKNOWN, 0x02, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_SYMLINK_SETDRIVES    (ULONG)CTL_CODE(FILE_DEVICE_UNKNOWN, 0x03, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_SYMLINK_UNLOADQUERY  (ULONG)CTL_CODE(FILE_DEVICE_UNKNOWN, 0x04, METHOD_NEITHER, FILE_ANY_ACCESS)

typedef struct _SYMLINK_READ_MEMORY_PARAMETERS {
	PVOID addr;
	ULONG size;
} SYMLINK_READ_MEMORY_PARAMETERS;

typedef struct _SYMLINK_WRITE_MEMORY_PARAMETERS {
	PVOID addr;
	UCHAR buffer[1];
} SYMLINK_WRITE_MEMORY_PARAMETERS;


union REPARSE_DATA_BUFFER_UNION {
    REPARSE_DATA_BUFFER iobuf;
    TCHAR dummy[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];
};


#endif
