package Win32API::Console;

# ABSTRACT: Win32 native Console API

# AUTHOR: J. Schneider <brickpool@cpan.org>
#
# LICENSE: MIT License - see LICENSE file for full text. However, this library 
# distributes and references code from other open source projects that have 
# their own licenses.

# SPDX-License-Identifier: MIT

#------------
# Boilerplate
#------------

use strict;
use warnings;
use version;

# version '...'
our $version = '0.10';
our $VERSION = 'v0.2.0';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'cpan:JDB';
our $AUTHORITY = 'cpan:BRICKPOOL';

#-------------
# Used Modules
#-------------

require bytes;
use Carp qw( croak );
use Encode ();
use Scalar::Util qw( readonly );
use Hash::Util qw( lock_ref_keys );
use Win32;
use Win32::API;
use Win32::Console ();
use Win32API::File ();

#--------
# Imports
#--------

# We use variables to avoid polluting the namespace when importing Win32 API 
# functions. 
my (
  $AllocConsoleWithOptions, 
  $AttachConsole,
  $FillConsoleOutputCharacterA,
  $FillConsoleOutputCharacterW,
  $FindWindow,
  $GetClientRect,
  $GetConsoleDisplayMode,
  $GetConsoleFontSize,
  $GetConsoleOriginalTitleA,
  $GetConsoleOriginalTitleW,
  $GetConsoleTitleA,
  $GetConsoleTitleW,
  $GetConsoleWindow,
  $GetCurrentConsoleFont,
  $GetCurrentConsoleFontEx,
  $GetNumberOfConsoleFonts,
  $PeekConsoleInputA,
  $PeekConsoleInputW,
  $MultiByteToWideChar,
  $ReadConsoleW,
  $ReadConsoleInputA,
  $ReadConsoleInputW,
  $ReadConsoleOutputA,
  $ReadConsoleOutputW,
  $ReadConsoleOutputCharacterA,
  $ReadConsoleOutputCharacterW,
  $RtlGetVersion,
  $ScrollConsoleScreenBufferW,
  $SetConsoleDisplayMode,
  $SetConsoleTitleA,
  $SetConsoleTitleW,
  $SetCurrentConsoleFontEx,
  $WideCharToMultiByte,
  $WriteConsoleA,
  $WriteConsoleW,
  $WriteConsoleInputA,
  $WriteConsoleInputW,
  $WriteConsoleOutputA,
  $WriteConsoleOutputW,
  $WriteConsoleOutputCharacterA,
  $WriteConsoleOutputCharacterW,
);

BEGIN {
  $AttachConsole = Win32::API::More->new('kernel32', 
    'BOOL AttachConsole(
      DWORD dwProcessId
    )'
  ) or die "Import AttachConsole failed: $^E";

  $FillConsoleOutputCharacterA = Win32::API::More->new('kernel32',
    'BOOL FillConsoleOutputCharacterA(
      HANDLE  hConsoleOutput,
      CHAR    cCharacter,
      DWORD   nLength,
      DWORD   dwWriteCoord,
      LPDWORD lpNumberOfCharsWritten
    )'
  ) or die "Import FillConsoleOutputCharacterA failed: $^E";

  $FillConsoleOutputCharacterW = Win32::API::More->new('kernel32',
    'BOOL FillConsoleOutputCharacterW(
      HANDLE  hConsoleOutput,
      WCHAR   cCharacter,
      DWORD   nLength,
      DWORD   dwWriteCoord,
      LPDWORD lpNumberOfCharsWritten
    )'
  ) or die "Import FillConsoleOutputCharacterW failed: $^E";

  $FindWindow = Win32::API::More->new('user32', 
    'HWND FindWindow(
      LPCSTR lpClassName,
      LPCSTR lpWindowName
    )'
  ) or die "Import FindWindow: $^E";

  $GetClientRect = Win32::API::More->new('user32', 
    'BOOL GetClientRect(
      HANDLE hWnd,
      LPVOID lpRect,
    )'
  ) or die "Import GetClientRect: $^E";

  $GetConsoleDisplayMode = Win32::API::More->new('kernel32',
    'BOOL GetConsoleDisplayMode(
      LPDWORD lpModeFlags
    )'
  ) or die "Import GetConsoleDisplayMode failed: $^E";

  $GetConsoleFontSize = Win32::API::More->new('kernel32',
    'DWORD GetConsoleFontSize(
      HANDLE hConsoleOutput,
      DWORD  nFont
    )'
  ) or die "Import GetConsoleFontSize failed: $^E";

  $GetConsoleOriginalTitleA = Win32::API::More->new('kernel32',
    'DWORD GetConsoleOriginalTitleA(
      LPSTR lpConsoleTitle,
      DWORD nSize
    )'
  ) or die "Import GetConsoleOriginalTitleA failed: $^E";

  $GetConsoleOriginalTitleW = Win32::API::More->new('kernel32',
    'DWORD GetConsoleOriginalTitleW(
      LPWSTR lpConsoleTitle,
      DWORD  nSize
    )'
  ) or die "Import GetConsoleOriginalTitleA failed: $^E";

  $GetConsoleTitleA = Win32::API::More->new('kernel32',
    'DWORD GetConsoleTitleA(
      LPSTR lpConsoleTitle,
      DWORD nSize
    )'
  ) or die "Import GetConsoleTitleA failed: $^E";

  $GetConsoleTitleW = Win32::API::More->new('kernel32',
    'DWORD GetConsoleTitleW(
      LPWSTR lpConsoleTitle,
      DWORD  nSize
    )'
  ) or die "Import GetConsoleTitleW failed: $^E";

  $GetConsoleWindow = Win32::API::More->new('kernel32',
    'HWND GetConsoleWindow()'
  ) or die "Import GetConsoleWindow: $^E";

  $GetCurrentConsoleFont = Win32::API::More->new('kernel32',
    'BOOL GetCurrentConsoleFont(
      HANDLE hConsoleOutput,
      BOOL   bMaximumWindow,
      LPVOID lpConsoleCurrentFont
    )'
  ) or die "Import GetCurrentConsoleFont failed: $^E";

  $GetNumberOfConsoleFonts = Win32::API::More->new('kernel32', 
    'DWORD GetNumberOfConsoleFonts()'
  ) or warn "Import GetNumberOfConsoleFonts failed: $^E";

  $MultiByteToWideChar = Win32::API::More->new('kernel32',
    'int MultiByteToWideChar(
      UINT   CodePage,
      DWORD  dwFlags,
      LPCSTR lpMultiByteStr,
      int    cbMultiByte,
      LPWSTR lpWideCharStr,
      int    cchWideChar
    )'
  ) or die "Import MultiByteToWideChar: $^E";

  $PeekConsoleInputA = Win32::API::More->new('kernel32',
    'BOOL PeekConsoleInputA(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsRead
    )'
  ) or die "Import PeekConsoleInputA failed: $^E";

  $PeekConsoleInputW = Win32::API::More->new('kernel32',
    'BOOL PeekConsoleInputW(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsRead
    )'
  ) or die "Import PeekConsoleInputW failed: $^E";

  $ReadConsoleW = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleW(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nNumberOfCharsToRead,
      LPDWORD lpNumberOfEventsRead,
      LPVOID  pInputControl
    )'
  ) or die "Import ReadConsoleW failed: $^E";

  $ReadConsoleInputA = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleInputA(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInputA failed: $^E";

  $ReadConsoleInputW = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleInputW(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInputW failed: $^E";

  $ReadConsoleOutputA = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleOutputA(
      HANDLE hConsoleInput,
      LPVOID lpBuffer,
      DWORD  dwBufferSize,
      DWORD  dwBufferCoord,
      LPVOID lpWriteRegion
    )'
  ) or die "Import ReadConsoleOutputA failed: $^E";

  $ReadConsoleOutputW = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleOutputW(
      HANDLE hConsoleInput,
      LPVOID lpBuffer,
      DWORD  dwBufferSize,
      DWORD  dwBufferCoord,
      LPVOID lpWriteRegion
    )'
  ) or die "Import ReadConsoleOutputW failed: $^E";

  $ReadConsoleOutputCharacterA = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleOutputCharacterA(
      HANDLE  hConsoleOutput,
      LPSTR   lpCharacter,
      DWORD   nLength,
      DWORD   dwReadCoord,
      LPDWORD lpNumberOfCharsRead
    )'
  ) or die "Import ReadConsoleOutputCharacterA failed: $^E";

  $ReadConsoleOutputCharacterW = Win32::API::More->new('kernel32',
    'BOOL ReadConsoleOutputCharacterW(
      HANDLE  hConsoleOutput,
      LPWSTR  lpCharacter,
      DWORD   nLength,
      DWORD   dwReadCoord,
      LPDWORD lpNumberOfCharsRead
    )'
  ) or die "Import ReadConsoleOutputCharacterW failed: $^E";

  $RtlGetVersion = Win32::API::More->new('ntdll',
    'NTSTATUS RtlGetVersion(
      LPVOID lpVersionInformation
    )'
  ) or die "Import RtlGetVersion: $^E";

  $ScrollConsoleScreenBufferW = Win32::API::More->new('kernel32',
    'BOOL ScrollConsoleScreenBufferW(
      HANDLE  hConsoleOutput,
      LPVOID  lpScrollRectangle,
      LPVOID  lpClipRectangle,
      DWORD   dwDestinationOrigin,
      LPDWORD lpFill
    )'
  ) or die "Import ScrollConsoleScreenBufferW failed: $^E";

  $SetConsoleDisplayMode = Win32::API::More->new('kernel32',
    'BOOL SetConsoleDisplayMode(
      HANDLE  hConsoleOutput,
      DWORD   dwFlags,
      LPDWORD lpNewScreenBufferDimensions
    )'
  ) or die "Import SetConsoleDisplayMode failed: $^E";

  $SetConsoleTitleA = Win32::API::More->new('kernel32',
    'DWORD SetConsoleTitleA(
      LPCSTR lpConsoleTitle,
    )'
  ) or die "Import SetConsoleTitleA failed: $^E";

  $SetConsoleTitleW = Win32::API::More->new('kernel32',
    'DWORD SetConsoleTitleW(
      LPCWSTR lpConsoleTitle,
    )'
  ) or die "Import SetConsoleTitleW failed: $^E";

  $WideCharToMultiByte = Win32::API::More->new('kernel32',
    'int WideCharToMultiByte(
      UINT    CodePage,
      DWORD   dwFlags,
      LPCWSTR lpWideCharStr,
      int     cchWideChar,
      LPSTR   lpMultiByteStr,
      int     cbMultiByte,
      LPCSTR  lpDefaultChar,
      LPBOOL  lpUsedDefaultChar
    )'
  ) or die "Import WideCharToMultiByte: $^E";

  $WriteConsoleA = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleA(
      HANDLE  hConsoleOutput,
      LPCSTR  lpBuffer,
      DWORD   nNumberOfCharsToWrite,
      LPDWORD lpNumberOfCharsWritten,
      LPVOID  lpReserved
    )'
  ) or die "Import WriteConsoleA: $^E";

  $WriteConsoleW = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleW(
      HANDLE  hConsoleOutput,
      LPCWSTR lpBuffer,
      DWORD   nNumberOfCharsToWrite,
      LPDWORD lpNumberOfCharsWritten,
      LPVOID  lpReserved
    )'
  ) or die "Import WriteConsoleW: $^E";

  $WriteConsoleInputA = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleInputA(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsWritten
    )'
  ) or die "Import WriteConsoleInputA: $^E";

  $WriteConsoleInputW = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleInputW(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsWritten
    )'
  ) or die "Import WriteConsoleInputW: $^E";

  $WriteConsoleOutputA = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleOutputA(
      HANDLE  hConsoleOutput,
      LPCWSTR lpBuffer,
      DWORD   dwBufferSize,
      DWORD   dwBufferCoord,
      LPVOID  lpWriteRegion
    )'
  ) or die "Import WriteConsoleOutputA: $^E";

  $WriteConsoleOutputW = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleOutputW(
      HANDLE  hConsoleOutput,
      LPCWSTR lpBuffer,
      DWORD   dwBufferSize,
      DWORD   dwBufferCoord,
      LPVOID  lpWriteRegion
    )'
  ) or die "Import WriteConsoleOutputW: $^E";

  $WriteConsoleOutputCharacterA = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleOutputCharacterA(
      HANDLE  hConsoleOutput,
      LPCSTR  lpCharacter,
      DWORD   nLength,
      DWORD   dwWriteCoord,
      LPDWORD lpNumberOfCharsWritten
    )'
  ) or die "Import WriteConsoleOutputCharacterA: $^E";

  $WriteConsoleOutputCharacterW = Win32::API::More->new('kernel32',
    'BOOL WriteConsoleOutputCharacterW(
      HANDLE  hConsoleOutput,
      LPCWSTR lpCharacter,
      DWORD   nLength,
      DWORD   dwWriteCoord,
      LPDWORD lpNumberOfCharsWritten
    )'
  ) or die "Import WriteConsoleOutputCharacterW: $^E";
}
RUNTIME: {
  # Minimum supported client: Windows 11 24H2 (build 26100)
  # Minimum supported server: Windows Server 2025 (build 26100)
  my $os = version->declare(sprintf('v%2$d.%3$d.%4$d', GetOSVersion()));
  if ($os >= v10.0.26100) {
    $AllocConsoleWithOptions = Win32::API::More->new('kernel32', 
      'DWORD AllocConsoleWithOptions(
        LPVOID  allocOptions,
        LPDWORD result
      )'
    ) or die "Import AllocConsoleWithOptions failed: $^E";
  }

  # Minimum supported client: Windows Vista
  # Minimum supported server: Windows Server 2008
  if ($os >= v6.0) {
    $GetCurrentConsoleFontEx = Win32::API::More->new('kernel32',
      'BOOL GetCurrentConsoleFontEx(
        HANDLE hConsoleOutput,
        BOOL   bMaximumWindow,
        LPVOID lpConsoleCurrentFontEx
      )'
    ) or die "Import GetCurrentConsoleFontEx failed: $^E";

    $SetCurrentConsoleFontEx = Win32::API::More->new('kernel32',
      'BOOL SetCurrentConsoleFontEx(
        HANDLE hConsoleOutput,
        BOOL   bMaximumWindow,
        LPVOID lpConsoleCurrentFontEx
      )'
    ) or die "Import SetCurrentConsoleFontEx failed: $^E";
  }
}

#--------
# Exports
#--------

use Exporter qw( import );

our @EXPORT_OK = ();

our %EXPORT_TAGS = (
  Func => [qw(
    AllocConsole
    AllocConsoleWithOptions
    AttachConsole
    CloseHandle
    CreateConsoleScreenBuffer
    FillConsoleOutputAttribute
    FillConsoleOutputCharacter
    FlushConsoleInputBuffer
    FreeConsole
    GenerateConsoleCtrlEvent
    GetConsoleCP
    GetConsoleCursorInfo
    GetConsoleDisplayMode
    GetConsoleFontSize
    GetConsoleMode
    GetConsoleOriginalTitle
    GetConsoleOutputCP
    GetConsoleScreenBufferInfo
    GetConsoleTitle
    GetConsoleWindow
    GetCurrentConsoleFont
    GetCurrentConsoleFontEx
    GetLargestConsoleWindowSize
    GetNumberOfConsoleFonts
    GetNumberOfConsoleInputEvents
    GetStdHandle
    PeekConsoleInput
    ReadConsole
    ReadConsoleInput
    ReadConsoleOutput
    ReadConsoleOutputAttribute
    ReadConsoleOutputCharacter
    ScrollConsoleScreenBuffer
    SetConsoleActiveScreenBuffer
    SetConsoleCtrlHandler
    SetConsoleCursorInfo
    SetConsoleCursorPosition
    SetConsoleDisplayMode
    SetConsoleIcon
    SetConsoleMode
    SetConsoleOutputCP
    SetConsoleScreenBufferSize
    SetConsoleTextAttribute
    SetConsoleTitle
    SetConsoleWindowInfo
    SetCurrentConsoleFontEx
    SetStdHandle
    WriteConsole
    WriteConsoleInput
    WriteConsoleOutput
    WriteConsoleOutputAttribute
    WriteConsoleOutputCharacter
  )],

  FuncA => [qw(
    FillConsoleOutputCharacterA
    GetConsoleOriginalTitleA
    GetConsoleTitleA
    PeekConsoleInputA
    ReadConsoleA
    ReadConsoleInputA
    ReadConsoleOutputA
    ReadConsoleOutputCharacterA
    ScrollConsoleScreenBufferA
    SetConsoleTitleA
    WriteConsoleA
    WriteConsoleInputA
    WriteConsoleOutputA
    WriteConsoleOutputCharacterA
  )],

  FuncW => [qw(
    FillConsoleOutputCharacterW
    GetConsoleOriginalTitleW
    GetConsoleTitleW
    PeekConsoleInputW
    ReadConsoleW
    ReadConsoleInputW
    ReadConsoleOutputW
    ReadConsoleOutputCharacterW
    ScrollConsoleScreenBufferW
    SetConsoleTitleW
    WriteConsoleW
    WriteConsoleInputW
    WriteConsoleOutputW
    WriteConsoleOutputCharacterW
  )],

  Struct => [qw(
    CONSOLE_CURSOR_INFO
    CONSOLE_FONT_INFO
    CONSOLE_FONT_INFOEX
    CONSOLE_READCONSOLE_CONTROL
    CONSOLE_SCREEN_BUFFER_INFO
    COORD
    SMALL_RECT
  )],

  Misc => [qw(
    GetOSVersion
    ATTACH_PARENT_PROCESS
    CONSOLE_TEXTMODE_BUFFER
    INVALID_HANDLE_VALUE
  )],

  ALLOC_CONSOLE_ => [qw(
    ALLOC_CONSOLE_MODE_DEFAULT
    ALLOC_CONSOLE_MODE_NEW_WINDOW
    ALLOC_CONSOLE_MODE_NO_WINDOW
    ALLOC_CONSOLE_RESULT_NO_CONSOLE
    ALLOC_CONSOLE_RESULT_NEW_CONSOLE
    ALLOC_CONSOLE_RESULT_EXISTING_CONSOLE
  )],

  CTRL_EVENT_ => [qw(
    CTRL_BREAK_EVENT
    CTRL_C_EVENT
  )],

  EVENT_TYPE_ => [qw(
    KEY_EVENT
    MOUSE_EVENT
    WINDOW_BUFFER_SIZE_EVENT
    MENU_EVENT
    FOCUS_EVENT
  )],

  MOUSE_ => [qw(
    MOUSE_MOVED
    DOUBLE_CLICK
    MOUSE_WHEELED
    MOUSE_HWHEELED
  )],

  CONTROL_KEY_STATE_ => [qw(
    CAPSLOCK_ON
    ENHANCED_KEY
    LEFT_ALT_PRESSED
    LEFT_CTRL_PRESSED
    NUMLOCK_ON
    RIGHT_ALT_PRESSED
    RIGHT_CTRL_PRESSED
    SCROLLLOCK_ON
    SHIFT_PRESSED
  )],

  FOREGROUND_ => [qw(
    FOREGROUND_BLUE
    FOREGROUND_GREEN
    FOREGROUND_RED
    FOREGROUND_INTENSITY
  )],

  BACKGROUND_ => [qw(
    BACKGROUND_BLUE
    BACKGROUND_GREEN
    BACKGROUND_RED
    BACKGROUND_INTENSITY
  )],

  COMMON_LVB_ => [qw(
    COMMON_LVB_LEADING_BYTE
    COMMON_LVB_TRAILING_BYTE
    COMMON_LVB_GRID_HORIZONTAL
    COMMON_LVB_GRID_LVERTICAL
    COMMON_LVB_GRID_RVERTICAL
    COMMON_LVB_REVERSE_VIDEO
    COMMON_LVB_UNDERSCORE
  )],

  # CONSOLE_WINDOWED - do not export this constant
  DISPLAY_MODE_ => [qw(
    CONSOLE_FULLSCREEN
    CONSOLE_FULLSCREEN_HARDWARE
    CONSOLE_FULLSCREEN_MODE
    CONSOLE_WINDOWED_MODE
  )],

  INPUT_MODE_ => [qw(
    ENABLE_INSERT_MODE
    ENABLE_PROCESSED_INPUT
    ENABLE_LINE_INPUT
    ENABLE_ECHO_INPUT
    ENABLE_WINDOW_INPUT
    ENABLE_MOUSE_INPUT
    ENABLE_QUICK_EDIT_MODE
    ENABLE_EXTENDED_FLAGS
    ENABLE_VIRTUAL_TERMINAL_INPUT
  )],

  OUTPUT_MODE_ => [qw(
    ENABLE_PROCESSED_OUTPUT
    ENABLE_WRAP_AT_EOL_OUTPUT
    ENABLE_VIRTUAL_TERMINAL_PROCESSING
    DISABLE_NEWLINE_AUTO_RETURN
    ENABLE_LVB_GRID_WORLDWIDE
  )],

  STD_HANDLE_ => [qw(
    STD_ERROR_HANDLE
    STD_INPUT_HANDLE
    STD_OUTPUT_HANDLE
  )],
);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

#----------
# Constants
#----------

# Windows Error Codes
use constant {
  ERROR_SUCCESS              => 0x0,
  ERROR_INVALID_FUNCTION     => 0x1,
  ERROR_INVALID_HANDLE       => 0x6,
  ERROR_GEN_FAILURE          => 0x1f,
  ERROR_INVALID_PARAMETER    => 0x57,
  ERROR_CALL_NOT_IMPLEMENTED => 0x78,
  ERROR_PROC_NOT_FOUND       => 0x7f,
  ERROR_BAD_ARGUMENTS        => 0xa0,
  ERROR_MR_MID_NOT_FOUND     => 0x13d,
  ERROR_INVALID_VARIANT      => 0x25c,
  ERROR_INVALID_USER_BUFFER  => 0x6f8,
};

# GetSystemMetrics
use constant {
  SM_CXFULLSCREEN => 16,
  SM_CYFULLSCREEN => 17,
  SM_CXMIN        => 28,
  SM_CYMIN        => 29,
};

# Lengths used
use constant {
  LF_FACESIZE        => 32,
  CONSOLE_TITLE_SIZE => 1024,
};

# Size in number of bytes
use constant {
  CONSOLE_FONT_INFOEX_SIZE => 20 + (2 * LF_FACESIZE),
  INPUT_RECORD_SIZE        => 20,
  OSVERSIONINFOEXW_SIZE    => 284,
};

# AttachConsole/AllocConsoleWithOptions/AllocConsole
use constant {
  ATTACH_PARENT_PROCESS => -1,
  STATUS_SUCCESS        => 0,
  FACILITY_WIN32        => 0x0007,
};

use constant {
  ALLOC_CONSOLE_MODE_DEFAULT            => 0,
  ALLOC_CONSOLE_MODE_NEW_WINDOW         => 1,
  ALLOC_CONSOLE_MODE_NO_WINDOW          => 2,

  ALLOC_CONSOLE_RESULT_NO_CONSOLE       => 0,
  ALLOC_CONSOLE_RESULT_NEW_CONSOLE      => 1,
  ALLOC_CONSOLE_RESULT_EXISTING_CONSOLE => 2,
};

# PeekConsoleInput/ReadConsoleInput/WriteConsoleInput
use constant {
  KEY_EVENT                => 0x0001,
  MOUSE_EVENT              => 0x0002,
  WINDOW_BUFFER_SIZE_EVENT => 0x0004,
  MENU_EVENT               => 0x0008,
  FOCUS_EVENT              => 0x0010,
};

use constant {
  MOUSE_MOVED    => 0x0001,
  DOUBLE_CLICK   => 0x0002,
  MOUSE_WHEELED  => 0x0004,
  MOUSE_HWHEELED => 0x0008,
};

use constant {
  RIGHT_ALT_PRESSED  => Win32::Console::constant("RIGHT_ALT_PRESSED",  0),
  LEFT_ALT_PRESSED   => Win32::Console::constant("LEFT_ALT_PRESSED",   0),
  RIGHT_CTRL_PRESSED => Win32::Console::constant("RIGHT_CTRL_PRESSED", 0),
  LEFT_CTRL_PRESSED  => Win32::Console::constant("LEFT_CTRL_PRESSED",  0),
  SHIFT_PRESSED      => Win32::Console::constant("SHIFT_PRESSED",      0),
  NUMLOCK_ON         => Win32::Console::constant("NUMLOCK_ON",         0),
  SCROLLLOCK_ON      => Win32::Console::constant("SCROLLLOCK_ON",      0),
  CAPSLOCK_ON        => Win32::Console::constant("CAPSLOCK_ON",        0),
  ENHANCED_KEY       => Win32::Console::constant("ENHANCED_KEY",       0),
};

use constant {
  FOREGROUND_BLUE      => Win32::Console::constant("FOREGROUND_BLUE",      0),
  FOREGROUND_GREEN     => Win32::Console::constant("FOREGROUND_GREEN",     0),
  FOREGROUND_RED       => Win32::Console::constant("FOREGROUND_RED",       0),
  FOREGROUND_INTENSITY => Win32::Console::constant("FOREGROUND_INTENSITY", 0),
  BACKGROUND_BLUE      => Win32::Console::constant("BACKGROUND_BLUE",      0),
  BACKGROUND_GREEN     => Win32::Console::constant("BACKGROUND_GREEN",     0),
  BACKGROUND_RED       => Win32::Console::constant("BACKGROUND_RED",       0),
  BACKGROUND_INTENSITY => Win32::Console::constant("BACKGROUND_INTENSITY", 0),
};

use constant {
  COMMON_LVB_LEADING_BYTE    => 0x0100,
  COMMON_LVB_TRAILING_BYTE   => 0x0200,
  COMMON_LVB_GRID_HORIZONTAL => 0x0400,
  COMMON_LVB_GRID_LVERTICAL  => 0x0800,
  COMMON_LVB_GRID_RVERTICAL  => 0x1000,
  COMMON_LVB_REVERSE_VIDEO   => 0x4000,
  COMMON_LVB_UNDERSCORE      => 0x8000,
};

# GetConsoleDisplayMode/SetConsoleDisplayMode
use constant {
  CONSOLE_WINDOWED            => 0,
  CONSOLE_FULLSCREEN          => 1,
  CONSOLE_FULLSCREEN_HARDWARE => 2,

  CONSOLE_FULLSCREEN_MODE     => 1,
  CONSOLE_WINDOWED_MODE       => 2,
};

# GetConsoleMode/SetConsoleMode 
use constant {
  ENABLE_PROCESSED_INPUT        => Win32::Console::constant("ENABLE_PROCESSED_INPUT", 0),
  ENABLE_LINE_INPUT             => Win32::Console::constant("ENABLE_LINE_INPUT",      0),
  ENABLE_ECHO_INPUT             => Win32::Console::constant("ENABLE_ECHO_INPUT",      0),
  ENABLE_WINDOW_INPUT           => Win32::Console::constant("ENABLE_WINDOW_INPUT",    0),
  ENABLE_MOUSE_INPUT            => Win32::Console::constant("ENABLE_MOUSE_INPUT",     0),
  ENABLE_INSERT_MODE            => 0x0020,
  ENABLE_QUICK_EDIT_MODE        => 0x0040,
  ENABLE_EXTENDED_FLAGS         => 0x0080,
  ENABLE_VIRTUAL_TERMINAL_INPUT => 0x0200,
};

use constant {
  ENABLE_PROCESSED_OUTPUT            => Win32::Console::constant("ENABLE_PROCESSED_OUTPUT",   0),
  ENABLE_WRAP_AT_EOL_OUTPUT          => Win32::Console::constant("ENABLE_WRAP_AT_EOL_OUTPUT", 0),
  ENABLE_VIRTUAL_TERMINAL_PROCESSING => 0x0004,
  DISABLE_NEWLINE_AUTO_RETURN        => 0x0008,
  ENABLE_LVB_GRID_WORLDWIDE          => 0x0010,
};

# GetStdHandle/SetStdHandle
use constant {
  STD_INPUT_HANDLE  => Win32API::File::STD_INPUT_HANDLE,
  STD_OUTPUT_HANDLE => Win32API::File::STD_OUTPUT_HANDLE,
  STD_ERROR_HANDLE  => Win32API::File::STD_ERROR_HANDLE,
};

# CreateConsoleScreenBuffer
use constant CONSOLE_TEXTMODE_BUFFER 
  => Win32::Console::constant("CONSOLE_TEXTMODE_BUFFER", 0);

# GenerateConsoleCtrlEvent/SetConsoleCtrlHandler
use constant {
  CTRL_BREAK_EVENT => Win32::Console::constant("CTRL_BREAK_EVENT", 0),
  CTRL_C_EVENT     => Win32::Console::constant("CTRL_C_EVENT", 0),
};

# GetStdHandle
use constant {
  INVALID_HANDLE_VALUE => Win32API::File::INVALID_HANDLE_VALUE,
};

# MultiByteToWideChar/WideCharToMultiByte
use constant {
  CP_ACP               => 0,
  CP_UTF8              => 65001,
  WC_NO_BEST_FIT_CHARS => 0x00000400,    # do not use best fit chars
};

# Win32::Console usually refers to the A-functions (ANSI). 
# To truly utilize WCHAR support, we need W-functions (wide char).
# Due to a bug, we can detect whether the XS code was compiled in UNICODE. 
# This bug is confirmed to exist up to and including version 0.10.
use constant UNICODE => do {
  my $version = $Win32::Console::VERSION || 0;
  if ($version > 0.10) {
    undef;
  }
  else {
    my $handle = Win32::Console::_GetStdHandle(STD_INPUT_HANDLE);
    if ($handle) {
      my @event = (
        1,  # EventType         => KEY_CODE,
        1,  # bKeyDown          => TRUE,
        1,  # wRepeatCount      => 1,
        65, # wVirtualKeyCode   => VK_KEY_A,
        30, # wVirtualScanCode  => VK_A,
        97, # uChar             => ord('a'),
        32, # dwControlKeyState => NUMLOCK_ON,
      );

      @event = Win32::Console::_ReadConsoleInput($handle) 
            if Win32::Console::_FlushConsoleInputBuffer($handle)
            && Win32::Console::_WriteConsoleInput($handle, @event);

      !defined($event[5]) ? undef : $event[5] == 32 ? 0 : 1;
    }
    else {
      undef;
    }
  }
};

# Use Types::Standard type checking if Type::Tiny is installed.
use constant HAS_TYPE_TINY => eval {
  require Types::Standard;
      exists &Types::Standard::is_Bool
  and exists &Types::Standard::is_CodeRef
  and exists &Types::Standard::is_HashRef
  and exists &Types::Standard::is_Int
  and exists &Types::Standard::is_ScalarRef
  and exists &Types::Standard::is_Str;
};

# Determine whether we want to emulate certain functions if the current 
# environment does not support them.
use constant {
  EMULATE_CTRL_HANDLER => 1,
  EMULATE_DISPLAY_MODE => 1,
  EMULATE_FONT_SIZE    => 0,
  EMULATE_GET_VERSION  => 1,
};

#-------------
# Declarations
#-------------

sub CONSOLE_CURSOR_INFO;
sub CONSOLE_FONT_INFO;
sub CONSOLE_READCONSOLE_CONTROL;
sub CONSOLE_SCREEN_BUFFER_INFO;
sub COORD;
sub SMALL_RECT;

sub __FUNCTION__;
sub _is_Bool;
sub _is_HashRef;
sub _is_Int;
sub _is_ScalarRef;
sub _is_Str;
sub _lock_ref_keys_recure;

#----------
# Variables
#----------

our $ProductName;
our @VersionInformation;

#-------------------
# Public Subroutines
#-------------------

###
# C<AllocConsole> creates a new console for the calling process.
# Useful when running GUI applications that need to output to a console window.
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: After calling C<AllocConsole>, standard handles (C<STDIN>, 
# C<STDOUT>, C<STDERR>) can be redirected to the new console using 
# L</SetStdHandle>.
#
sub AllocConsole {    # $|undef ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 0 ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  return Win32::Console::Alloc() || undef;
}

###
# C<AllocConsoleWithOptions> wraps the Windows API function.
# It allocates a console with optional window display settings and returns the 
# result code.
#
#  - C<$mode>: console allocation mode (0 = default, 1 = new window, 2 = no win)
#  - C<$show>: optional showWindow flag (e.g. C<SW_SHOW>, C<SW_HIDE>)
#  - C<\$result>: result code (I<ALLOC_CONSOLE_RESULT>)
#
# B<Note>: We do not use the I<ALLOC_CONSOLE_OPTIONS> structure. Instead, we 
# use positional parameters. If $show is defined, it is used as a parameter 
# for displaying the console window. For more information, see C<ShowWindow>.
#
#  Returns: non-zero success, undef on failure
#  Use GetLastError() to retrieve extended error information.
#
# B<Note>: We do not return C<HRESULT>, but instead set C<SetLastError> 
# (extracting the Win32 error code if C<FACILITY_WIN32> flag is set).
# 
sub AllocConsoleWithOptions {    # $|undef ($mode, $show|undef, \$result)
  my ($mode, $show, $result) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3                          ? ERROR_BAD_ARGUMENTS
        : !_is_Int($mode)                  ? ERROR_INVALID_PARAMETER 
        : defined $show && !_is_Int($show) ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($result)          ? ERROR_INVALID_PARAMETER
        : readonly($$result)               ? ERROR_INVALID_PARAMETER
        : 0
        ;
  unless (defined $AllocConsoleWithOptions) {
    Win32::SetLastError(ERROR_PROC_NOT_FOUND);
    return undef;
  }
  my $use = 0;
  if   ( defined $show ) { $use  = 1 }
  else                   { $show = 0 }
  my $options = pack('LLL', $mode, $use, $show & 0xffff);
  my $r = $AllocConsoleWithOptions->Call($options, $$result = 0);
  my $err = ERROR_GEN_FAILURE;
  if (defined $r) {
    return 1 
      if $r == STATUS_SUCCESS;
    $err = _HRESULT_CODE($r) 
      if _HRESULT_FACILITY($r) == FACILITY_WIN32;
  } 
  Win32::SetLastError($err);
  return undef;
}

###
# C<AttachConsole> attaches the calling process to the console of another 
# process. Useful for redirecting output/input to an existing console window 
# (e.g. from a GUI app).
#
#  - C<$pid>: process ID of the target console owner
#  
# Use C<ATTACH_PARENT_PROCESS> (-1) to attach to the parent process's console.
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: After attaching, standard handles (C<STDIN>, C<STDOUT>, C<STDERR>) 
# can be used to interact with the attached console.
#
sub AttachConsole {    # $|undef ($pid)
  my ($pid) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1        ? ERROR_BAD_ARGUMENTS
        : !_is_Int($pid) ? ERROR_INVALID_PARAMETER 
        : 0
        ;
  my $r = $AttachConsole->Call($pid);
  return $r ? $r : undef;
}

###
# C<CloseHandle> closes an open console handle (but not only consoles; other 
# object handles such as files or processes can also be closed).
#
#  - C<$handle>: handle to be closed
#
#  Returns: non-zero on success, undef on failure.
#
sub CloseHandle {    # $|undef ($handle)
  my ($handle) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : 0
        ;
  return Win32::Console::_CloseHandle($handle) || undef;
}

###
# C<CreateConsoleScreenBuffer> creates a new console screen buffer.
# Useful for off-screen rendering or switching between buffers.
#
#  - C<$access>:    desired access (e.g. C<GENERIC_READ | GENERIC_WRITE>)
#  - C<$shareMode>: sharing mode (e.g. C<FILE_SHARE_READ | FILE_SHARE_WRITE>)
#
#  Returns: handle to the new buffer on success, undef on failure.
#  Use GetLastError() to retrieve extended error information.
#
sub CreateConsoleScreenBuffer {    # $|undef ($access, $shareMode)
  my ($access, $shareMode) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2              ? ERROR_BAD_ARGUMENTS
        : !_is_Int($access)    ? ERROR_INVALID_PARAMETER
        : !_is_Int($shareMode) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  Win32::SetLastError(0);
  my $handle = Win32::Console::_CreateConsoleScreenBuffer($access, $shareMode, 
    CONSOLE_TEXTMODE_BUFFER);
  return Win32::GetLastError() ? undef : $handle;
}

###
# C<FillConsoleOutputAttribute> sets character attributes (e.g. color) in the 
# console buffer.
#
#  - C<$handle>:   Console screen buffer handle
#  - C<$attr>:     Attribute value (e.g. C<FOREGROUND_RED | BACKGROUND_BLUE>)
#  - C<$length>:   Number of cells to fill
#  - C<\%coord>:   Starting coordinate (L</COORD> structure)
#  - C<\$written>: Number of attributes written
#
#  Returns: non-zero on success, undef on failure.
#
sub FillConsoleOutputAttribute {    # $|undef ($handle, $attr, $length, \%coord, \$written)
  my ($handle, $attr, $length, $coord, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Int($attr)          ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)           ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  Win32::SetLastError(0);
  $$written = Win32::Console::_FillConsoleOutputAttribute($handle, $attr, 
    $length, COORD::list($coord));
  return Win32::GetLastError() ? undef : 1;
}

###
# C<FillConsoleOutputCharacter> writes a repeated character to the console 
# buffer.
#
#  - C<$handle>:   Console screen buffer handle
#  - C<$char>:     Character to write
#  - C<$length>:   Number of cells to write the character
#  - C<\%coord>:   Starting coordinate (L</COORD> structure)
#  - C<\$written>: Number of characters written
#
#  Returns: non-zero on success, undef on failure.
#
sub FillConsoleOutputCharacter {    # $|undef ($handle, $char, $length, \%coord, \$written)
  no warnings;
  *FillConsoleOutputCharacter = UNICODE 
                              ? \&FillConsoleOutputCharacterW 
                              : \&FillConsoleOutputCharacterA;
  goto &FillConsoleOutputCharacter;
} 

sub FillConsoleOutputCharacterA {    # $|undef ($handle, $char, $length, \%coord, \$written)
  my ($handle, $char, $length, $coord, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($char)          ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)           ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $char = Encode::ANSI::encode(substr($char, 0, 1), 
    Win32::GetConsoleOutputCP());
  my $r = UNICODE
    ? $FillConsoleOutputCharacterA->Call($handle, $char, $length, 
        COORD::pack($coord), $$written = 0)
    : do {
      Win32::SetLastError(0);
      $$written = Win32::Console::_FillConsoleOutputCharacter($handle, $char, 
        $length, COORD::list($coord));
      Win32::GetLastError() ? 0 : 1;
    };
  return $r ? $r : undef;
}

sub FillConsoleOutputCharacterW {    # $|undef ($handle, $char, $length, \%coord, \$written)
  my ($handle, $char, $length, $coord, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($char)          ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)           ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return $FillConsoleOutputCharacterW->Call($handle, ord($char), $length, 
    COORD::pack($coord), $$written = 0) || undef;
}

###
# C<FlushConsoleInputBuffer> clears all pending input events from the console 
# input buffer.
#
#  - C<$handle>: handle to the console input buffer
#
#  Returns: non-zero on success, undef on failure.
#
sub FlushConsoleInputBuffer {    # $|undef ($handle)
  my ($handle) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : 0
        ;
  return Win32::Console::_FlushConsoleInputBuffer($handle) || undef;
}

###
# C<FreeConsole> detaches the calling process from its current console.
# Useful when a process no longer needs console I/O or wants to release the 
# console.
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: After calling C<FreeConsole>, C<STDIN>, C<STDOUT>, and C<STDERR> are 
# no longer valid unless a new console is allocated (via L</AllocConsole>) or 
# attached (via L</AttachConsole>).
#
sub FreeConsole {    # $|undef ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  return Win32::Console::Free() || undef;
}

###
# C<GenerateConsoleCtrlEvent> sends a C<CTRL+C> or C<CTRL+BREAK> signal to a 
# process group.
#
#  - C<$event>:   C<CTRL_C_EVENT> or C<CTRL_BREAK_EVENT>
#  - C<$groupId>: Process group ID to receive the signal
#
#  Returns: non-zero on success, undef on failure.
#
sub GenerateConsoleCtrlEvent {    # $|undef ($event, $groupId)
  my ($event, $groupId) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2            ? ERROR_BAD_ARGUMENTS
        : !_is_Int($event)   ? ERROR_INVALID_HANDLE
        : !_is_Int($groupId) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_GenerateConsoleCtrlEvent($event, $groupId) || undef;
}

###
# C<GetConsoleCP> retrieves the input code page used by the console.
#
#  Returns: code page identifier (e.g. 65001 for UTF-8).
#  Use GetLastError() to retrieve extended error information.
#
sub GetConsoleCP {    # $codepage ()
  return 0 if
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  goto &Win32::GetConsoleCP;
}

###
# C<GetConsoleCursorInfo> retrieves the size and visibility of the console 
# cursor.
#
#  - C<$handle>: Console screen buffer handle
#  - C<\%info>:  Hash reference to receive a L</CONSOLE_CURSOR_INFO> structure
#
#  Returns: non-zero on success, undef on failure.
#
sub GetConsoleCursorInfo {    # $|undef ($handle, \%info)
  my ($handle, $info) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2             ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)   ? ERROR_INVALID_HANDLE
        : !_is_HashRef($info) ? ERROR_INVALID_PARAMETER
        : readonly(%$info)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  Win32::SetLastError(0);
  my ($size, $visible) = Win32::Console::_GetConsoleCursorInfo($handle);

  # If the incorrect hash was passed (generated with one of our structures that 
  # have locked keys), the error should be detected.
  TRY: eval {
    %$info = (
      dwSize   => $size,
      bVisible => $visible,
    );
  };
  CATCH: if ($@) {
    $^E = ERROR_INVALID_PARAMETER;
    return undef;
  }
  return Win32::GetLastError() ? undef : 1;
}

###
# C<GetConsoleDisplayMode> retrieves the display mode of the current console.
#
#  - C<\$flags>: Reference to a scalar receiving the display mode
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: Since ~ Windows 10, the function does not deliver correct results. 
# If L<Win32::GuiTest> is available (and C<EMULATE_DISPLAY_MODE> is true), we 
# try to emulate the function by determining the mode based on the ratio of 
# window size to screen size.
#
sub GetConsoleDisplayMode {    # $|undef (\$flags)
  my ($flags) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1                 ? ERROR_BAD_ARGUMENTS
        : !_is_ScalarRef($flags)  ? ERROR_INVALID_PARAMETER
        : readonly($$flags)       ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $r;
  $$flags = 0;
  if (EMULATE_DISPLAY_MODE and (GetOSVersion())[1] >= 10) {
    TRY: eval {
      require Win32::GuiTest;
      my $hwnd =_GetConsoleHwnd();
      # warn "$hwnd";
      die unless $hwnd;

      my ($left, $top, $right, $bottom) = Win32::GuiTest::GetWindowRect($hwnd);
      # warn "$^E";
      die if Win32::GetLastError();

      my $wx = $right - $left;
      my $wy = $bottom - $top;
      # warn "$wx, $wy";
      die unless $wx > 0 && $wy > 0;

      my $sx = Win32::GetSystemMetrics(SM_CXFULLSCREEN);
      my $sy = Win32::GetSystemMetrics(SM_CYFULLSCREEN);
      # warn "$sx, $sy";
      die unless $sx > 0 && $sy > 0;

      my $mx = Win32::GetSystemMetrics(SM_CXMIN);
      my $my = Win32::GetSystemMetrics(SM_CYMIN);
      # warn "$mx, $my";
      die unless $mx >= 0 && $my >= 0;

      $$flags = $mx > ($sx - $wx) && $my > ($sy - $wy)
              ? CONSOLE_FULLSCREEN
              : CONSOLE_WINDOWED;
    };
    CATCH: if ($@) {
      $^E = ERROR_CALL_NOT_IMPLEMENTED;
      return undef;
    }
    $r = 1;
  }
  else {
    $r = $GetConsoleDisplayMode->Call($$flags) || undef;
  }
  return $r ? $r : undef;
}

###
# C<GetConsoleFontSize> retrieves the size of the font used by the console.
#
#  - C<$handle>: Handle to the console output buffer
#  - C<$index>:  Index of the font (usually from L</GetCurrentConsoleFont>)
#
#  Returns: COORD structure with width and height of the font, undef on failure.
#  Use GetLastError() to retrieve extended error information.
#
# B<Note>: C<GetConsoleFontSize()> returns the size C<(0,16)> in 
# Windows-Terminal. See: https://github.com/microsoft/terminal/issues/6395
#
# We therefore calculate the font size based on the pixels of the window 
# client width and height of the console area using C<GetClientRect> and 
# L</GetConsoleScreenBufferInfo> (prerequisite that C<EMULATE_FONT_SIZE> is 
# enabled).
#
sub GetConsoleFontSize {    # \%coord|undef ($handle, $index)
  my ($handle, $index) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : !_is_Int($index)  ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $dwFontSize = $GetConsoleFontSize->Call($handle, $index);

  # Extract the returned values: font width, height
  my ($width, $height) = COORD::unpack($dwFontSize);

  if (EMULATE_FONT_SIZE and !$width || !$height) {
    my $err = Win32::GetLastError();    # Encode may set $^E
    TRY: eval {
      require Win32::GuiTest;
      my $hwnd = _GetConsoleHwnd();
      # warn "$hwnd";
      die unless $hwnd;

      # Client rect does not include title bar, borders, scroll bars, status bar
      my $rect = pack('L4', (0) x 4);
      my $r = $GetClientRect->Call($hwnd, $rect);
      # warn "$r";
      die unless $r;

      my ($left, $top, $right, $bottom) = unpack('L4', $rect);
      my $cx = $right - $left;
      my $cy = $bottom - $top;
      # warn "$cx, $cy";
      die unless $cx > 0 && $cy > 0;

      my @info = Win32::Console::_GetConsoleScreenBufferInfo($handle);
      die unless @info > 1;

      ($left, $top, $right, $bottom) = @info[5..8];
      my $cols = $right - $left + 1;
      my $rows = $bottom - $top + 1;
      # warn "$cols, $rows";
      die unless $cols > 0 && $rows > 0;

      $width  = int($cx / $cols);
      $height = int($cy / $rows);
      # warn "$width, $height";
    };
    CATCH: if ($@) {
      Win32::SetLastError($err);
    }
  }

  return COORD($width, $height);
}

###
# C<GetConsoleOriginalTitle> retrieves the original title of the console window.
#
#  - C<\$buffer>: Reference to a buffer receiving the title string
#  - C<$size>:    Size of the buffer in characters
#
#  Returns: number of characters copied, undef on failure.
#  Use GetLastError() to retrieve extended error information.
#
sub GetConsoleOriginalTitle {    # $num|undef (\$buffer, $size)
  no warnings;
  *GetConsoleOriginalTitle = UNICODE 
    ? \&GetConsoleOriginalTitleW 
    : \&GetConsoleOriginalTitleA;
  goto &GetConsoleOriginalTitle;
}

sub GetConsoleOriginalTitleA {    # $num|undef ($handle, $index)
  my ($buffer, $size) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                 ? ERROR_BAD_ARGUMENTS
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($size)         ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x $size;
  my $r = $GetConsoleOriginalTitleA->Call($$buffer, $size) || return undef;
  substr($$buffer, $r) = '';

  # Convert the Windows ANSI string to a Perl string (UTF-8)
  $$buffer = Encode::ANSI::decode($$buffer, CP_ACP);
  return length($$buffer);
}

sub GetConsoleOriginalTitleW {    # $num|undef ($handle, $index)
  my ($buffer, $size) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                 ? ERROR_BAD_ARGUMENTS
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($size)         ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x (2 * $size);
  my $r = $GetConsoleOriginalTitleW->Call($$buffer, $size) || return undef;

  # Decode the UTF-16LE wide string into perl's internal string format (UTF-8)
  $$buffer = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::decode('UTF-16LE', bytes::substr($$buffer, 0, 2 * $r));
    Win32::SetLastError($err);
    $_;
  };
  return length($$buffer);
}

###
# C<GetConsoleMode> retrieves the current input or output mode of a console 
# handle.
#
#  - C<$handle>: Handle to console input or output
#  - C<\$mode>:  Reference to a scalar receiving the mode flags
#
#  Returns: non-zero on success, undef on failure.
#
sub GetConsoleMode {    # $|undef ($handle, \$mode)
  my ($handle, $mode) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($mode) ? ERROR_INVALID_PARAMETER
        : readonly($$mode)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  Win32::SetLastError(0);
  $$mode = Win32::Console::_GetConsoleMode($handle);
  return Win32::GetLastError() ? undef : 1;
}

###
# C<GetConsoleOutputCP> retrieves the output code page used by the console.
#
#  Returns: code page identifier (e.g. 65001 for UTF-8).
#  Use GetLastError() to retrieve extended error information.
#
sub GetConsoleOutputCP {    # $codepage ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  goto &Win32::GetConsoleOutputCP;
}

###
# C<GetConsoleScreenBufferInfo> retrieves information about the console screen 
# buffer.
#
#  - C<$handle>:  Handle to the console screen buffer
#  - C<\%info>:   Reference to L</CONSOLE_SCREEN_BUFFER_INFO> structure
#
# L</CONSOLE_SCREEN_BUFFER_INFO> structure used by 
# C<GetConsoleScreenBufferInfo> to receive the information about a console 
# screen buffer:
#
#  {dwSize}              Specifies the size of the screen buffer in character 
#                        columns and rows (COORD structure).
#  {dwCursorPosition}    Indicates the current position of the cursor within 
#                        the screen buffer (COORD structure).
#  {wAttributes}         Holds the current text attributes (like foreground and 
#                        background colors).
#  {srWindow}            Defines the coordinates of the visible window within 
#                        the screen buffer (SMALL_RECT structure).
#  {dwMaximumWindowSize} Specifies the maximum size the console window can be, 
#                        based on the current font and screen size (COORD).
#
# B<Return>:
#
#  Returns: non-zero on success, undef on failure.
#
sub GetConsoleScreenBufferInfo {    # $|undef ($handle, \%info)
  my ($handle, $info) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2             ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)   ? ERROR_INVALID_HANDLE
        : !_is_HashRef($info) ? ERROR_INVALID_PARAMETER
        : readonly(%$info)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my @info = Win32::Console::_GetConsoleScreenBufferInfo($handle);

  # If the incorrect hash was passed (generated with one of our structures that 
  # have locked keys), the error should be detected.
  TRY: eval {
    %$info = (
      dwSize => {
        X => $info[0],
        Y => $info[1],
      },
      dwCursorPosition => {
        X => $info[2],
        Y => $info[3],
      },
      wAttributes => $info[4],
      srWindow => {
        Left   => $info[5],
        Top    => $info[6],
        Right  => $info[7],
        Bottom => $info[8],
      },
      dwMaximumWindowSize => {
        X => $info[9],
        Y => $info[10],
      },
    );
  };
  CATCH: if ($@) {
    $^E = ERROR_INVALID_PARAMETER;
    return;
  }
  return @info > 1 ? 1 : undef;
}

###
# C<GetConsoleTitle> retrieves the title of the current console window.
#
#  - C<\$buffer>: Reference to a buffer receiving the title string
#  - C<$size>:    Size of the buffer in characters
#
#  Returns: number of characters copied, undef on failure.
#  Use GetLastError() to retrieve extended error information.
#
# B<Note>: The buffer for the ANSI version contains an empty string if the 
# specified length is greater than C<1024>, due to the limitation of the 
# underlying XS function of L<Win32::Console>.
#
sub GetConsoleTitle {    # $num|undef (\$buffer, $size)
  no warnings;
  *GetConsoleTitle = UNICODE ? \&GetConsoleTitleW : \&GetConsoleTitleA;
  goto &GetConsoleTitle;
}

sub GetConsoleTitleA {    # $num|undef (\$buffer, $size)
  my ($buffer, $size) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                 ? ERROR_BAD_ARGUMENTS
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($size)         ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $r;
  if (UNICODE) {
    $$buffer = "\0" x $size;
    $r = $GetConsoleTitleA->Call($$buffer, $size);
  }
  else {
    Win32::SetLastError(0);
    $$buffer = Win32::Console::_GetConsoleTitle();
    $r = Win32::GetLastError() ? 0 : 1;
    # The Win32::Console XS function only supports 1024 characters
    $size = CONSOLE_TITLE_SIZE if $size > CONSOLE_TITLE_SIZE;
  }
  return undef unless $r;

  # Convert the Windows ANSI string to a Perl string (UTF-8)
  $$buffer = Encode::ANSI::decode(substr($$buffer, 0, $size), CP_ACP);
  return length($$buffer);
}

sub GetConsoleTitleW {    # $num|undef (\$buffer, $size)
  my ($buffer, $size) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                 ? ERROR_BAD_ARGUMENTS
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($size)         ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $size++;    # TODO: No idea why we have to add +1 here.
  $$buffer = "\0" x (2 * $size);
  my $r = $GetConsoleTitleW->Call($$buffer, $size) || return undef;

  # Decode the UTF-16LE wide string into perl's internal string format (UTF-8)
  $$buffer = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::decode('UTF-16LE', bytes::substr($$buffer, 0, 2 * $r));
    Win32::SetLastError($err);
    $_;
  };
  return length($$buffer);
}

###
# C<GetConsoleWindow> retrieves the window handle used by the console 
# associated with the calling process.
#
#  Returns: handle to the window used by the console associated with 
#  the calling process or undef if there is no such associated console.
#
sub GetConsoleWindow {    # $hwnd|undef ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  Win32::SetLastError(0);
  my $handle = $GetConsoleWindow->Call();
  return Win32::GetLastError() ? undef : $handle;
}

###
# C<GetCurrentConsoleFont> retrieves information about the current console font.
#
#  - C<$handle>: Handle to the console output buffer
#  - C<$max>:    TRUE to retrieve maximum font size, FALSE for current
#  - C<\%info>:  L</CONSOLE_FONT_INFO> HashRef to receive the font information
#
#  Returns: non-zero on success, undef on failure.
#
sub GetCurrentConsoleFont {    # $|undef ($handle, $max, \%info)
  my ($handle, $max, $info) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)   ? ERROR_INVALID_HANDLE
        : !_is_Bool($max)     ? ERROR_INVALID_PARAMETER
        : !_is_HashRef($info) ? ERROR_INVALID_PARAMETER
        : readonly(%$info)    ? ERROR_INVALID_PARAMETER
        : 0
        ;

  # Pack a CONSOLE_FONT_INFO structure:
  # nFont (DWORD), dwFontSize.X (SHORT), dwFontSize.Y (SHORT)
  my $lpFontInfo = pack('LSS', 0 x 3);

  my $r = $GetCurrentConsoleFont->Call($handle, $max ? 1 : 0, $lpFontInfo);

  # Extract the returned values: font index, width, height
  my ($index, $width, $height) = unpack('LSS', $lpFontInfo);

  if (EMULATE_FONT_SIZE and !$width || !$height) {
    my $coord = GetConsoleFontSize($handle, $index);
    return undef unless $coord;
    $width  = $coord->{X};
    $height = $coord->{Y};
    # warn "$width, $height";
  }

  # If the incorrect hash was passed (generated with one of our structures that 
  # have locked keys), the error should be detected.
  TRY: eval {
    %$info = (
      nFont => $index,
      dwFontSize => {
        X => $width,
        Y => $height,
      }
    );
  };
  CATCH: if ($@) {
    $^E = ERROR_INVALID_PARAMETER;
    return undef;
  }
  return $r ? $r : undef;
}

###
# C<GetCurrentConsoleFontEx> retrieves extended information about the current 
# console font.
#
#  - C<$handle>: Handle to the console output buffer
#  - C<$max>:    TRUE to retrieve maximum font size, FALSE for current
#  - C<\%info>:  L</CONSOLE_FONT_INFOEX> HashRef to receive the information
#
# B<Note>: C<< $info->{cbSize} >> is set by this function and therefore does 
# not need to be passed.
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: C<GetCurrentConsoleFontEx> returns the size C<(0,16)> in 
# Windows-Terminal. See: L</GetConsoleFontSize> for further information.
#
sub GetCurrentConsoleFontEx {    # $|undef ($handle, $max, \%info)
  my ($handle, $max, $info) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)   ? ERROR_INVALID_HANDLE
        : !_is_Bool($max)     ? ERROR_INVALID_PARAMETER
        : !_is_HashRef($info) ? ERROR_INVALID_PARAMETER
        : readonly(%$info)    ? ERROR_INVALID_PARAMETER
        : 0
        ;

  unless (defined $GetCurrentConsoleFontEx) {
    $^E = ERROR_PROC_NOT_FOUND;
    return undef;
  }
 
  # Allocate a zero-initialized buffer for the CONSOLE_FONT_INFOEX structure
  my $lpFontInfoEx = "\0" x CONSOLE_FONT_INFOEX_SIZE;

  # Set the cbSize field (first 4 bytes) to the total size of the structure
  substr($lpFontInfoEx, 0, 4) = pack('L', CONSOLE_FONT_INFOEX_SIZE);
  
  my $r = $GetCurrentConsoleFontEx->Call($handle, $max ? 1 : 0, $lpFontInfoEx);

  # Extract the structure fields (skipping cbSize):
  # nFont (DWORD), dwFontSize.X (SHORT), dwFontSize.Y (SHORT),
  # FontFamily (UINT), FontWeight (UINT)
  my ($index, $x, $y, $family, $weight) = unpack('x4'.'LSSLL', $lpFontInfoEx);

  if (EMULATE_FONT_SIZE and !$x || !$y) {
    my $coord = GetConsoleFontSize($handle, $index);
    return undef unless $coord;
    
    # warn "$x, $y";
    $x = $coord->{X};
    $y = $coord->{Y};
  }

  # Extract and decode the FaceName field (WCHAR[LF_FACESIZE], 64 bytes)
  # at the end of the structure, interpreting it as UTF-16LE. 
  my $name = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = bytes::substr($lpFontInfoEx, 
      CONSOLE_FONT_INFOEX_SIZE - (2 * LF_FACESIZE), (2 * LF_FACESIZE)) 
        if defined $lpFontInfoEx;
    $_ = unpack('A*', $_) if defined;
    $_ = Encode::decode('UTF-16LE', $_) if defined;
    Win32::SetLastError($err);
    $_;
  };

  # If the incorrect hash was passed (generated with one of our structures that 
  # have locked keys), the error should be detected.
  TRY: eval {
    %$info = (
      cbSize => CONSOLE_FONT_INFOEX_SIZE,
      nFont  => $index,
      dwFontSize => {
        X => $x,
        Y => $y,
      },
      FontFamily => $family,
      FontWeight => $weight,
      FaceName   => $name,
    );
  };
  CATCH: if ($@) {
    $^E = ERROR_INVALID_PARAMETER;
    return undef;
  }
  return $r ? $r : undef;
}

###
# C<GetLargestConsoleWindowSize> returns the largest possible size for the 
# console window.
#
#  - C<$handle>: handle to the console screen buffer
#
#  Returns: COORD structure with maximum width and height, undef on failure.
#  Use GetLastError() to retrieve extended error information.
#
sub GetLargestConsoleWindowSize {    # \%coord|undef ($handle)
  my ($handle) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : 0
        ;
  return COORD(Win32::Console::_GetLargestConsoleWindowSize($handle));
}

###
# To identify the index of a font, call the C<GetCurrentConsoleFont> function.
# 
#  Returns: Number of console fonts on success, undef on failure.
#  Use GetLastError() to retrieve extended error information.
#
# B<Notes>: C<GetCurrentConsoleFont> returns the size C<(0,16)> in 
# Windows-Terminal. See: L</GetConsoleFontSize> for further information.
# This function is not documented and may not work with current 
# Windows versions.
#
sub GetNumberOfConsoleFonts {    # $num|undef ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  unless (defined $GetNumberOfConsoleFonts) {
    $^E = ERROR_CALL_NOT_IMPLEMENTED;
    return undef;
  }
  Win32::SetLastError(0);
  my $num = $GetNumberOfConsoleFonts->Call();
  Win32::GetLastError() ? undef : $num;
}

###
# C<GetNumberOfConsoleInputEvents> retrieves the number of unread input events 
# in the buffer.
#
#  - C<$handle>: Handle to the console input buffer
#  - C<\$count>: Reference to variable receiving the count
#
#  Returns: non-zero on success, undef on failure.
# 
sub GetNumberOfConsoleInputEvents {    # $|undef ($handle, \$count)
  my ($handle, $count) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)      ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($count) ? ERROR_INVALID_PARAMETER
        : readonly($$count)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  Win32::SetLastError(0);
  $$count = Win32::Console::_GetNumberOfConsoleInputEvents($handle);
  return Win32::GetLastError() ? undef : 1;
}

###
# I<GetStdHandle> retrieves a handle to the standard input, output, or error 
# device.
#
#  - C<$id>: identifier (e.g. C<STD_INPUT_HANDLE>, see L</":STD_HANDLE_">)
#
#  Returns: handle on success, INVALID_HANDLE_VALUE on failure.
#  Use GetLastError() to retrieve extended error information.
#
sub GetStdHandle {    # $handle ($id)
  my ($id) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1       ? ERROR_BAD_ARGUMENTS
        : !_is_Int($id) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  Win32::SetLastError(0);
  my $handle = Win32::Console::_GetStdHandle($id);
  return Win32::GetLastError() ? INVALID_HANDLE_VALUE : $handle;
}

###
# C<PeekConsoleInput> reads input events from the console input buffer without 
# removing them.
#
#  - C<$handle>:  Handle to the console input buffer
#  - C<\%buffer>: Reference to a I<INPUT_RECORD> structure
#
# I<INPUT_RECORD> structure used by C<PeekConsoleInput> and to represent a 
# single input event. See L</ReadConsoleInput> for the complete description of 
# I<INPUT_RECORD>.
#
#  Returns: non-zero on success, undef on failure.
#
sub PeekConsoleInput {    # $|undef ($handle, \%buffer)
  no warnings;
  *PeekConsoleInput = UNICODE ? \&PeekConsoleInputW : \&PeekConsoleInputA;
  goto &PeekConsoleInput;
}

sub PeekConsoleInputA {    # $|undef ($handle, \%buffer)
  my ($handle, $buffer) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_HashRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly(%$buffer)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $lpBuffer = "\0" x INPUT_RECORD_SIZE;
  my $read = 0;
  return undef
    unless $PeekConsoleInputA->Call($handle, $lpBuffer, 1, $read) && $read;

  my @ir   = unpack('S', $lpBuffer);
  my $type = $ir[0] || 0;
  SWITCH: for ($type) {
    KEY_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'LSSSCxL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bKeyDown          => $ir[1],
          wRepeatCount      => $ir[2],
          wVirtualKeyCode   => $ir[3],
          wVirtualScanCode  => $ir[4],
          uChar             => $ir[5],
          dwControlKeyState => $ir[6],
        },
      );
      last;
    };
    MOUSE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SSLLL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwMousePosition => {
            X => $ir[1],
            Y => $ir[2],
          },
          dwButtonState       => $ir[3],
          dwMeControlKeyState => $ir[4],
          dwEventFlags        => $ir[5],
        },
      );
      last;
    };
    WINDOW_BUFFER_SIZE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SS', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwSize => {
            X => $ir[1],
            Y => $ir[2],
          },
        },
      );
      last;
    };
    MENU_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwCommandId => $ir[1],
        },
      );
      last;
    };
    FOCUS_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bSetFocus => $ir[1],
        },
      );
      last;
    };
    DEFAULT: {
      %$buffer = ();
      return undef;
    }
  }
  return 1;
}

sub PeekConsoleInputW {    # $|undef ($handle, \%buffer)
  my ($handle, $buffer) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_HashRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly(%$buffer)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $lpBuffer = "\0" x INPUT_RECORD_SIZE;
  my $read = 0;
  return undef
    unless $PeekConsoleInputW->Call($handle, $lpBuffer, 1, $read) && $read;

  my @ir   = unpack('S', $lpBuffer);
  my $type = $ir[0] || 0;
  SWITCH: for ($type) {
    KEY_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'LSSSSL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bKeyDown          => $ir[1],
          wRepeatCount      => $ir[2],
          wVirtualKeyCode   => $ir[3],
          wVirtualScanCode  => $ir[4],
          uChar             => $ir[5],
          dwControlKeyState => $ir[6],
        },
      );
      last;
    };
    MOUSE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SSLLL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwMousePosition => {
            X => $ir[1],
            Y => $ir[2],
          },
          dwButtonState       => $ir[3],
          dwMeControlKeyState => $ir[4],
          dwEventFlags        => $ir[5],
        },
      );
      last;
    };
    WINDOW_BUFFER_SIZE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SS', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwSize => {
            X => $ir[1],
            Y => $ir[2],
          },
        },
      );
      last;
    };
    MENU_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwCommandId => $ir[1],
        },
      );
      last;
    };
    FOCUS_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bSetFocus => $ir[1],
        },
      );
      last;
    };
    DEFAULT: {
      %$buffer = ();
      return undef;
    }
  }
  return 1;
}

###
# C<ReadConsole> reads characters from the console input buffer.
#
#  - C<$handle>:   Handle to the console input buffer
#  - C<\$buffer>:  Reference to buffer receiving the input
#  - C<$length>:   Number of characters to read
#  - C<\$read>:    Reference to number of characters actually read
#  - C<\%control>: Optional HashRef (L</CONSOLE_READCONSOLE_CONTROL> structure)
#
#  Returns: non-zero on success, undef on failure.
#
sub ReadConsole {    # $|undef ($handle, \$buffer, $length, \$read, |\%control|undef)
  no warnings;
  *ReadConsole = UNICODE ? \&ReadConsoleW : \&ReadConsoleA;
  goto &ReadConsole;
}

sub ReadConsoleA {    # $|undef ($handle, \$buffer, $length, \$read, |undef)
  my ($handle, $buffer, $length, $read) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ >= 4 && @_ <= 5      ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)       ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($read)   ? ERROR_INVALID_PARAMETER
        : readonly($$read)        ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x $length;
  my $r = UNICODE
    ? $ReadConsoleW->Call($handle, $$buffer, $length, $$read = 0, undef)
    : do {
      Win32::SetLastError(0);
      $$read = Win32::Console::_ReadConsole($handle, $$buffer, $length) || 0;
      Win32::GetLastError() ? 0 : 1;
    };
  return undef unless $r;

  # Convert the Windows ANSI string to a Perl string (UTF-8)
  $$buffer = Encode::ANSI::decode(substr($$buffer, 0, $$read), 
    Win32::GetConsoleCP());
  $$read = length($$buffer);
  return $r;
}

sub ReadConsoleW {    # $|undef ($handle, \$buffer, $length, \$read, |\%control|undef)
  my ($handle, $buffer, $length, $read, $control) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ >= 4 && @_ <= 5      ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)       ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($read)   ? ERROR_INVALID_PARAMETER
        : readonly($$read)        ? ERROR_INVALID_PARAMETER
        : defined $control && !CONSOLE_READCONSOLE_CONTROL($control)
                                  ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x (2 * $length);
  my $pInputControl;
  if ($control) {
    $pInputControl = pack('L4', @{$control}{qw(
      nLength
      nInitialChars
      dwCtrlWakeupMask
      dwControlKeyState
    )});
  }
  return $ReadConsoleW->Call($handle, $$buffer, $length, $$read = 0, 
    $pInputControl) || undef;
}

###
# C<ReadConsoleInput> reads input records (keyboard, mouse, buffer-resize, 
# etc.) from the console input buffer. It is useful for handling low-level 
# console input events in real-time.
#
#  - C<$handle>:  Handle to the console input buffer
#  - C<\%buffer>: HashRef that receives a I<INPUT_RECORD> structure
#
# I<INPUT_RECORD> structure used by C<ReadConsoleInput> to represent a single 
# input event. The structure is a union of different event types, distinguished 
# by the C<{EventType}> field.
#
#  {EventType} Specifies the type of the input event. Possible values:
#    0x0001: KEY_EVENT
#    0x0002: MOUSE_EVENT
#    0x0004: WINDOW_BUFFER_SIZE_EVENT
#    0x0008: MENU_EVENT
#    0x0010: FOCUS_EVENT
#
#  {Event} A I<union> of the following structures, depending on {EventType}:
#    KEY_EVENT_RECORD          KeyEvent
#    MOUSE_EVENT_RECORD        MouseEvent
#    WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent
#    MENU_EVENT_RECORD         MenuEvent
#    FOCUS_EVENT_RECORD        FocusEvent
#
# I<KEY_EVENT_RECORD> structure used when C<{EventType} == KEY_EVENT> 
# (C<0x0001>). Represents a keyboard event (key press or release).
#
#   {bKeyDown}          TRUE if the key is being pressed, FALSE if released.
#   {wRepeatCount}      Number of times the keystroke is repeated due to key 
#                       being held down.
#   {wVirtualKeyCode}   Virtual-key code of the key (e.g. VK_RETURN, VK_ESCAPE).
#   {wVirtualScanCode}  Hardware scan code of the key.
#   {uChar}             The character generated by the key press.
#   {dwControlKeyState} Bitmask indicating the state of control keys (SHIFT, 
#                       CTRL, ALT, CAPSLOCK, etc.)
#
# I<MOUSE_EVENT_RECORD> structure used when C<{EventType} == MOUSE_EVENT> 
# (C<0x0002>). Represents a mouse event in the console window.
#
#   {dwMousePosition}   X and Y coordinates of the mouse cursor in the console 
#                       screen buffer.
#   {dwButtonState}     Bitmask indicating which mouse buttons are pressed.
#                       e.g. FROM_LEFT_1ST_BUTTON_PRESSED
#   {dwControlKeyState} Bitmask indicating the state of control keys during 
#                       the mouse event.
#   {dwEventFlags}      Indicates the type of mouse event:
#                         0x0001: MOUSE_MOVED
#                         0x0002: DOUBLE_CLICK
#                         0x0004: MOUSE_WHEELED
#                         0x0008: MOUSE_HWHEELED
#
# I<WINDOW_BUFFER_SIZE_RECORD> structure used when 
# C<{EventType} == WINDOW_BUFFER_SIZE_EVENT> (C<0x0004>). Represents a change in 
# the size of the console screen buffer.
#
#  {dwSize}  New size of the screen buffer (width and height).
#
# I<MENU_EVENT_RECORD> structure used when C<{EventType} == MENU_EVENT> 
# (C<0x0008>). Represents a menu event in the console (rarely used in modern 
# applications).
#
#  {dwCommandId}  Identifier of the command selected from a system menu.
#                 Typically used in legacy console applications with system 
#                 menus.
#
# I<FOCUS_EVENT_RECORD> structure used when C<{EventType} == FOCUS_EVENT> 
# (C<0x0010>). Indicates a change in focus to or from the console window.
#
#  {bSetFocus}  TRUE if the console window has gained focus,
#               FALSE if it has lost focus.
#
# B<Return>:
#
#  Returns: non-zero on success, undef on failure.
#
sub ReadConsoleInput {    # $|undef ($handle, \%buffer)
  no warnings;
  *ReadConsoleInput = UNICODE ? \&ReadConsoleInputW : \&ReadConsoleInputA;
  goto &ReadConsoleInput;
}

sub ReadConsoleInputA {    # $|undef ($handle, \%buffer)
  my ($handle, $buffer) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_HashRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly(%$buffer)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $lpBuffer = "\0" x INPUT_RECORD_SIZE;
  my $read = 0;
  return undef
    unless $ReadConsoleInputA->Call($handle, $lpBuffer, 1, $read) && $read;

  my @ir   = unpack('S', $lpBuffer);
  my $type = $ir[0] || 0;
  SWITCH: for ($type) {
    KEY_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'LSSSCxL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bKeyDown          => $ir[1],
          wRepeatCount      => $ir[2],
          wVirtualKeyCode   => $ir[3],
          wVirtualScanCode  => $ir[4],
          uChar             => $ir[5],
          dwControlKeyState => $ir[6],
        },
      );
      last;
    };
    MOUSE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SSLLL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwMousePosition => {
            X => $ir[1],
            Y => $ir[2],
          },
          dwButtonState       => $ir[3],
          dwMeControlKeyState => $ir[4],
          dwEventFlags        => $ir[5],
        },
      );
      last;
    };
    WINDOW_BUFFER_SIZE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SS', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwSize => {
            X => $ir[1],
            Y => $ir[2],
          },
        },
      );
      last;
    };
    MENU_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwCommandId => $ir[1],
        },
      );
      last;
    };
    FOCUS_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bSetFocus => $ir[1],
        },
      );
      last;
    };
    DEFAULT: {
      %$buffer = ();
      return undef;
    }
  }
  return 1;
}

sub ReadConsoleInputW {    # $|undef ($handle, \%buffer)
  my ($handle, $buffer) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_HashRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly(%$buffer)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $lpBuffer = "\0" x INPUT_RECORD_SIZE;
  my $read     = 0;
  return undef
    unless $ReadConsoleInputW->Call($handle, $lpBuffer, 1, $read) && $read;

  my @ir   = unpack('S', $lpBuffer);
  my $type = $ir[0] || 0;
  SWITCH: for ($type) {
    KEY_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'LSSSSL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bKeyDown          => $ir[1],
          wRepeatCount      => $ir[2],
          wVirtualKeyCode   => $ir[3],
          wVirtualScanCode  => $ir[4],
          uChar             => $ir[5],
          dwControlKeyState => $ir[6],
        },
      );
      last;
    };
    MOUSE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SSLLL', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwMousePosition => {
            X => $ir[1],
            Y => $ir[2],
          },
          dwButtonState       => $ir[3],
          dwMeControlKeyState => $ir[4],
          dwEventFlags        => $ir[5],
        },
      );
      last;
    };
    WINDOW_BUFFER_SIZE_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'SS', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwSize => {
            X => $ir[1],
            Y => $ir[2],
          },
        },
      );
      last;
    };
    MENU_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          dwCommandId => $ir[1],
        },
      );
      last;
    };
    FOCUS_EVENT == $_ and do {
      @ir = ( @ir, unpack('x4'.'L', $lpBuffer) );
      %$buffer = (
        EventType => $ir[0],
        Event => {
          bSetFocus => $ir[1],
        },
      );
      last;
    };
    DEFAULT: {
      %$buffer = ();
    }
  }
  return @ir > 1 ? 1 : undef;
}

###
# C<ReadConsoleOutput> reads character and attribute data from the console 
# screen buffer.
#
#  - C<$handle>:  Handle to the console screen buffer
#  - C<\$buffer>: Reference to a packed string (of I<CHAR_INFO>'s)
#  - C<\%size>:   Size of C<$buffer> (L</COORD> hash as width and height)
#  - C<\%coord>:  Coordinates (L</COORD>) in C<$buffer> to start reading from
#  - C<\%region>: L</SMALL_RECT> hash defining the screen region to read
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: If successful, C<$buffer> returns a packed string containing 
# I<CHAR_INFO>'s - characters (C<S>) and attributes (C<S>) - and C<%region> 
# returns the rectangle actually used.
#
sub ReadConsoleOutput {    # $|undef ($handle, \$buffer, \%size, \%coord, \%region)
  no warnings;
  *ReadConsoleOutput = UNICODE ? \&ReadConsoleOutputW : \&ReadConsoleOutputA;
  goto &ReadConsoleOutput;
}

sub ReadConsoleOutputA {    # $|undef ($handle, \$buffer, \%size, \%coord, \%region)
  my ($handle, $buffer, $size, $coord, $region) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !COORD($size)           ? ERROR_INVALID_PARAMETER
        : !COORD($coord)          ? ERROR_INVALID_PARAMETER
        : !SMALL_RECT($region)    ? ERROR_INVALID_PARAMETER
        : readonly(%$region)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x (4 * $size->{X} * $size->{Y});
  my @rect = UNICODE 
    ? do {
        my $rect = SMALL_RECT::pack($region);
        my $r = $ReadConsoleOutputA->Call($handle, $$buffer, COORD::pack($size), 
          COORD::pack($coord), $rect);
        SMALL_RECT::unpack($rect);
      }
    : Win32::Console::_ReadConsoleOutput($handle, $$buffer, COORD::list($size), 
      COORD::list($coord), SMALL_RECT::list($region));
  %$region = (
    Left   => $rect[0],
    Top    => $rect[1],
    Right  => $rect[2],
    Bottom => $rect[3],
  );
  return @rect > 1 ? 1 : undef;
}

sub ReadConsoleOutputW {    # $|undef ($handle, \$buffer, \%size, \%coord, \%region)
  my ($handle, $buffer, $size, $coord, $region) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !COORD($size)           ? ERROR_INVALID_PARAMETER
        : !COORD($coord)          ? ERROR_INVALID_PARAMETER
        : !SMALL_RECT($region)    ? ERROR_INVALID_PARAMETER
        : readonly(%$region)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x (4 * $size->{X} * $size->{Y});
  my $rect = SMALL_RECT::pack($region);
  my $r = $ReadConsoleOutputW->Call($handle, $$buffer, COORD::pack($size), 
    COORD::pack($coord), $rect);
  my @rect = SMALL_RECT::unpack($rect);
  %$region = (
    Left   => $rect[0],
    Top    => $rect[1],
    Right  => $rect[2],
    Bottom => $rect[3],
  );
  return $r ? $r : undef;
}

###
# C<ReadConsoleOutputAttribute> reads character attributes from the console 
# screen buffer.
#
#  - C<$handle>:  Handle to the console screen buffer
#  - C<\$buffer>: Reference to a packed string (C<S*>) receiving the attributes
#  - C<$length>:  Number of attributes to read
#  - C<\%coord>:  Coordinates to start reading from (L</COORD> hash)
#  - C<\$read>:   Reference to number of attributes read
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: If successful, C<$buffer> returns the attributes in the form of a 
# packed string (C<S*>), and C<$read> returns the number of attributes.
#
# The L<Win32::Console> XS function has some limitations: the maximum supported 
# data length is C<80*999>. In addition, the return value only reflects the 
# color attributes (no C<DCBS> support).
#
sub ReadConsoleOutputAttribute {    # $|undef ($handle, \$buffer, $length, \%coord, \$read)
  my ($handle, $buffer, $length, $coord, $read) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)       ? ERROR_INVALID_PARAMETER
        : !COORD($coord)          ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($read)   ? ERROR_INVALID_PARAMETER
        : readonly($$read)        ? ERROR_INVALID_PARAMETER
        : 0
        ;
  if ($length > 80*999) {
    $^E = ERROR_INVALID_USER_BUFFER;
    return undef;
  }
  Win32::SetLastError(0);
  $$buffer = Win32::Console::_ReadConsoleOutputAttribute($handle, $length, 
    COORD::list($coord)) || '';
  $$read = bytes::length($$buffer);
  # Unfortunately, the XS function only processes lower bytes and not words.
  $$buffer = pack('S*', unpack('C*', $$buffer)) if $$read;
  return Win32::GetLastError() ? undef : 1;
}

###
# C<ReadConsoleOutputCharacter> reads characters from the console screen buffer.
#
#  - C<$handle>:  Handle to the console screen buffer
#  - C<\$buffer>: Reference to buffer receiving characters
#  - C<$length>:  Number of characters to read
#  - C<\%coord>:  Coordinates to start reading from (L</COORD> hash)
#  - C<\$read>:   Reference to number of attributes read
#
#  Returns: non-zero on success, undef on failure.
#
sub ReadConsoleOutputCharacter {    # $|undef ($handle, \$buffer, $length, \%coord, \$read)
  no warnings;
  *ReadConsoleOutputCharacter = UNICODE 
                              ? \&ReadConsoleOutputCharacterW 
                              : \&ReadConsoleOutputCharacterA;
  goto &ReadConsoleOutputCharacter;
}

sub ReadConsoleOutputCharacterA {    # $|undef ($handle, \$buffer, $length, \%coord, \$read)
  my ($handle, $buffer, $length, $coord, $read) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)       ? ERROR_INVALID_PARAMETER
        : !COORD($coord)          ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($read)   ? ERROR_INVALID_PARAMETER
        : readonly($$read)        ? ERROR_INVALID_PARAMETER
        : 0
        ;
  $$buffer = "\0" x $length;
  my $r = UNICODE
    ? $ReadConsoleOutputCharacterA->Call($handle, $$buffer, $length, 
        COORD::pack($coord), $$read = 0)
    : do { local $_;
      $_ = Win32::Console::_ReadConsoleOutputCharacter($handle, $$buffer, 
        $length, COORD::list($coord));
      $$read = length($$buffer);
      $_;
    };
  return undef unless $r;

  # Convert the Windows ANSI string to a Perl string (UTF-8)
  $$buffer = Encode::ANSI::decode(substr($$buffer, 0, $$read), 
    Win32::GetConsoleOutputCP());
  return $r;
}

sub ReadConsoleOutputCharacterW {    # $|undef ($handle, \$buffer, $length, \%coord, \$read)
  my ($handle, $buffer, $length, $coord, $read) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)       ? ERROR_INVALID_HANDLE
        : !_is_ScalarRef($buffer) ? ERROR_INVALID_PARAMETER
        : readonly($$buffer)      ? ERROR_INVALID_PARAMETER
        : !_is_Int($length)       ? ERROR_INVALID_PARAMETER
        : !COORD($coord)          ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($read)   ? ERROR_INVALID_PARAMETER
        : readonly($$read)        ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Allocate a buffer to receive WCHAR characters (2 bytes per character)
  $$buffer = "\0" x (2 * $length);

  # Pack COORD structure (X and Y) into a DWORD for the API call
  my $r = $ReadConsoleOutputCharacterW->Call($handle, $$buffer, $length, 
    COORD::pack($coord), $$read = 0) || undef;

  # Decode the UTF-16LE wide string into perl's internal string format (UTF-8)
  $$buffer = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::decode('UTF-16LE', bytes::substr($$buffer, 0, 2 * $$read));
    Win32::SetLastError($err);
    $_;
  };
  return defined $$buffer ? $r : undef;
}

###
# C<ScrollConsoleScreenBuffer> scrolls a region of the console screen buffer.
#
#  - C<$handle>:      Handle to the console screen buffer
#  - C<\%scrollRect>: L</SMALL_RECT> structure defining the region to scroll
#  - C<\%clipRect>:   Optional clipping rectangle (L</SMALL_RECT> or C<undef>)
#  - C<\%destCoord>:  Destination coordinate (L</COORD> struct)
#  - C<$fill>:        Packed string of I<CHAR_INFO> used to fill emptied space
#
#  Returns: non-zero on success, undef on failure.
#
sub ScrollConsoleScreenBuffer {    # $|undef ($handle, \%scrollRect, \%clipRect|undef, \%destCoord, $fill)
  no warnings;
  *ScrollConsoleScreenBuffer = UNICODE 
                              ? \&ScrollConsoleScreenBufferW 
                              : \&ScrollConsoleScreenBufferA;
  goto &ScrollConsoleScreenBuffer;
}

sub ScrollConsoleScreenBufferA {    # $|undef ($handle, \%scrollRect, \%clipRect|undef, \%destCoord, $fill)
  my ($handle, $scrollRect, $clipRect, $destCoord, $fill) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                                     ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)                           ? ERROR_INVALID_HANDLE
        : !SMALL_RECT($scrollRect)                    ? ERROR_INVALID_PARAMETER
        : defined $clipRect && !SMALL_RECT($clipRect) ? ERROR_INVALID_PARAMETER
        : !COORD($destCoord)                          ? ERROR_INVALID_PARAMETER
        : !_is_Str($fill)                             ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Unpack CHAR_INFO structure: character (2 bytes) and attribute (2 bytes)
  my ($codepoint, $attr) = unpack('SS', pack('L', $fill));

  # If the Win32::Console XS function is not an ANSI function, simply convert 
  # the Codepoint to WCHAR; otherwise, encode the Codepoint to ANSI format. 
  $codepoint = ord(
    UNICODE
      ? do { local $_;
          my $err = Win32::GetLastError();    # Encode may set $^E
          $_ = Encode::encode('UTF-16LE', chr($codepoint));
          Win32::SetLastError($err);
          $_;
        }
      : Encode::ANSI::encode(chr($codepoint), Win32::GetConsoleOutputCP())
  );

  # Calls the internal Win32::Console XS function, which uses a different order
  return Win32::Console::_ScrollConsoleScreenBuffer(
    $handle,                                    # console output handle
    SMALL_RECT::list($scrollRect),              # source rectangle to scroll
    COORD::list($destCoord),                    # destination coordinate
    $codepoint, $attr,                          # fill codepoint and attribute
    $clipRect                                   # optional clipping rectangle
      ? SMALL_RECT::list($clipRect)
      : SMALL_RECT::list($scrollRect)
  ) || undef;
}

sub ScrollConsoleScreenBufferW {    # $|undef ($handle, \%scrollRect, \%clipRect|undef, \%destCoord, $fill)
  my ($handle, $scrollRect, $clipRect, $destCoord, $fill) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5                                     ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)                           ? ERROR_INVALID_HANDLE
        : !SMALL_RECT($scrollRect)                    ? ERROR_INVALID_PARAMETER
        : defined $clipRect && !SMALL_RECT($clipRect) ? ERROR_INVALID_PARAMETER
        : !COORD($destCoord)                          ? ERROR_INVALID_PARAMETER
        : !_is_Str($fill)                             ? ERROR_INVALID_PARAMETER
        : 0
        ;

  # Call the Windows API ScrollConsoleScreenBufferW with all parameters
  return $ScrollConsoleScreenBufferW->Call(
    $handle,                                    # console output handle
    SMALL_RECT::pack($scrollRect),              # source rectangle to scroll
    $clipRect                                   # optional clipping rectangle
      ? SMALL_RECT::pack($clipRect) 
      : undef,                  
    COORD::pack($destCoord),                    # destination coordinate
    $fill                                       # CHAR_INFO struct for fill
  ) || undef;
}

###
# C<SetConsoleActiveScreenBuffer> sets the specified screen buffer as the 
# active one.
#
#  - C<$handle>: Handle to the screen buffer to activate
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleActiveScreenBuffer {    # $|undef ($handle)
  my ($handle) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : 0
        ;
  return Win32::Console::_SetConsoleActiveScreenBuffer($handle) || undef;
}

###
# C<SetConsoleCP> sets the input code page used by the console.
#
#  - C<$codepage>: Code page identifier (e.g. C<65001> for UTF-8)
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleCP {    # $|undef ($codepage)
  my ($codepage) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1             ? ERROR_BAD_ARGUMENTS
        : !_is_Int($codepage) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::SetConsoleCP($codepage) || undef;
}

my (@sigint, @sigbreak);

###
# C<SetConsoleCtrlHandler> adds or removes an user-defined I<handler> for 
# console control events.
#
#  - C<\&handler>: Code reference to a handler function or C<undef> when remove
#  - C<$add>:      TRUE to add, FALSE to remove
#
# A control signal is passed to the handler as a parameter. If the function 
# handles the control signal, TRUE should be returned. If FALSE is returned, 
# the next handler function in the list of handlers for this process is used.
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note:> We emulate this function using C<SIGINT> and C<SIGBREAK>, since Perl 
# itself has installed a handler. Currently, only the C<CTRL_C_EVENT> and 
# C<CTRL_BREAK_EVENT> control signals are supported. 
#
sub SetConsoleCtrlHandler {    # $|undef (\&handler|undef, $add)
  my ($handler, $add) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                        ? ERROR_BAD_ARGUMENTS
        : !_is_Bool($add)                ? ERROR_INVALID_PARAMETER
        : $add && !_is_CodeRef($handler) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  unless (EMULATE_CTRL_HANDLER) {
    $^E = ERROR_CALL_NOT_IMPLEMENTED;
    return undef;
  }
  TRY: eval {
    if ($add) {
      my $sigint = $SIG{INT};
      $SIG{INT}  = sub {
        my $r = $handler->(CTRL_C_EVENT);
        $sigint->() if $r && ref $sigint eq 'CODE';
      };
      push @sigint => $sigint;

      my $sigbreak = $SIG{BREAK};
      $SIG{BREAK}  = sub {
        my $r = $handler->(CTRL_BREAK_EVENT);
        $sigbreak->() if $r && ref $sigbreak eq 'CODE';
      };
      push @sigbreak => $sigbreak;
    }
    else {
      my $sigint = pop @sigint;
      $SIG{INT}  = defined $sigint ? $sigint : 'DEFAULT';

      my $sigbreak = pop @sigbreak;
      $SIG{BREAK}  = defined $sigbreak ? $sigbreak : 'DEFAULT';
    }
  };
  CATCH: if ($@) {
    $^E = ERROR_GEN_FAILURE;
    return undef;
  }
  return 1;
}

###
# C<SetConsoleCursorInfo> sets the size and visibility of the console cursor.
#
#  - C<$handle>: Handle to the console screen buffer
#  - C<\%info>:  Reference to a hash (L</CONSOLE_CURSOR_INFO> structure)
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleCursorInfo {    # $|undef ($handle, \%info)
  my ($handle, $info) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2                     ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)           ? ERROR_INVALID_HANDLE
        : !CONSOLE_CURSOR_INFO($info) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleCursorInfo($handle, 
    @{$info}{qw(dwSize bVisible)}) || undef;
}

###
# C<SetConsoleCursorPosition> moves the cursor to a specified location in the 
# console screen buffer.
#
#  - C<$handle>: Handle to the console screen buffer
#  - C<\%coord>: L</COORD> structure specifying the new cursor position
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleCursorPosition {    # $|undef ($handle, \%coord)
  my ($handle, $coord) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : !COORD($coord)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleCursorPosition($handle, 
    COORD::list($coord)) || undef;
}

###
# C<SetConsoleDisplayMode> sets the display mode of the specified console 
# screen buffer.
#
#  - C<$handle>: Handle to the console screen buffer
#  - C<$flags>:  The display mode of the console
#  - C<\%coord>: L</COORD> specifying the new dimensions of the screen buffer
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: If the function is no longer supported by the operating system, 
# C<GetLastError> returns C<120>. If L<Win32::GuiTest> is available, we 
# attempt to emulate the behavior of the API function using the C<Alt+Enter> 
# key combination. See: L<https://github.com/microsoft/terminal/issues/14885>
#
sub SetConsoleDisplayMode {    # $|undef ($handle, $flags, \%coord)
  my ($handle, $flags, $coord) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3              ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)    ? ERROR_INVALID_HANDLE
        : !_is_Int($flags)     ? ERROR_INVALID_PARAMETER
        : !_is_HashRef($coord) ? ERROR_INVALID_PARAMETER
        : readonly(%$coord)    ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my ($x, $y) = (0, 0);
  my $r;
  unless (EMULATE_DISPLAY_MODE) {
    my $dimension = COORD::pack($x, $y);
    if ($r = $SetConsoleDisplayMode->Call($handle, $flags, $dimension)) {
      ($x, $y) = COORD::unpack($dimension);
    }
  }
  else {
    TRY: eval {
      require Win32::GuiTest;
      my $mode;
      die unless $_ = GetConsoleDisplayMode(\$mode);
      if ( $flags == CONSOLE_WINDOWED_MODE && $mode != CONSOLE_WINDOWED
        || $flags != CONSOLE_WINDOWED_MODE && $mode == CONSOLE_WINDOWED
      ) {
        # warn 'send Alt+Enter';
        Win32::GuiTest::SendKeys('%~');
        die if Win32::GetLastError();
      }
      ($x, $y) = Win32::Console::_GetConsoleScreenBufferInfo($handle);
      die unless $x && $y;
    };
    CATCH: if ($@) {
      $^E = ERROR_CALL_NOT_IMPLEMENTED;
      return undef;
    }
    $r = 1;
  } 

  # If the incorrect hash was passed (generated with one of our structures that 
  # have locked keys), the error should be detected.
  TRY: eval {
    %$coord = (
      X => $x,
      Y => $y,
    );
  };
  CATCH: if ($@) {
    $^E = ERROR_INVALID_PARAMETER;
    return undef;
  }
  return $r ? $r : undef;
}

###
# C<SetConsoleIcon> sets the icon for the console window.
#
#  - C<$iconFile>: file name to an icon file
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: Not available in all Windows versions.
# 
sub SetConsoleIcon {    # $|undef ($iconFile)
  my ($iconFile) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1                             ? ERROR_BAD_ARGUMENTS
        : !defined $iconFile || ref $iconFile ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleIcon($iconFile) || undef;
}

###
# C<SetConsoleMode> sets the input or output mode of a console handle.
#
#  - C<$handle>: Handle to console input or output
#  - C<$mode>:   Mode flags (e.g. C<ENABLE_ECHO_INPUT>, C<ENABLE_LINE_INPUT>)
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleMode {    # $|undef ($handle, $mode)
  my ($handle, $mode) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : !_is_Int($mode)   ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleMode($handle, $mode) || undef;
}

###
# C<SetConsoleOutputCP> sets the output code page used by the console.
#
#  - C<$codepage>: Code page identifier (e.g. C<65001> for UTF-8)
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleOutputCP {    # $|undef ($codepage)
  my ($codepage) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1             ? ERROR_BAD_ARGUMENTS
        : !_is_Int($codepage) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::SetConsoleOutputCP($codepage) || undef;
}

###
# C<SetConsoleScreenBufferSize> sets the size of the console screen buffer.
#
#  - C<$handle>: Handle to the console screen buffer
#  - C<\%size>:  L</COORD> structure specifying new width and height
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleScreenBufferSize {    # \%coord|undef ($handle, \%size)
  my ($handle, $size) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : !COORD($size)     ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleScreenBufferSize($handle, 
    COORD::list($size)) || undef;
}

###
# C<SetConsoleTextAttribute> sets the text attributes (e.g. color) for 
# characters written to the console.
#
#  - C<$handle>:     Handle to the console screen buffer
#  - C<$attributes>: Attribute flags (e.g. C<FOREGROUND_RED | BACKGROUND_BLUE>)
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleTextAttribute {    # \%coord|undef ($handle, $attributes)
  my ($handle, $attributes) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_Int($attributes) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleTextAttribute($handle, 
    $attributes) || undef;
}

###
# C<SetConsoleTitle> sets the title of the console window.
#
#  - C<$title>: String to be displayed in the console window title bar
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleTitle {    # $|undef ($title)
  no warnings;
  *SetConsoleTitle = UNICODE ? \&SetConsoleTitleW : \&SetConsoleTitleA;
  goto &SetConsoleTitle;
}

sub SetConsoleTitleA {    # $|undef ($title)
  my ($title) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1          ? ERROR_BAD_ARGUMENTS
        : !_is_Str($title) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Convert the Perl internal string (UTF-8) to an ANSI string if necessary
  $title = Encode::ANSI::encode($title);
  my $r = UNICODE
    ? $SetConsoleTitleA->Call($title) 
    : Win32::Console::_SetConsoleTitle($title);
  return $r ? $r : undef;
}

sub SetConsoleTitleW {    # $|undef ($title)
  my ($title) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 1          ? ERROR_BAD_ARGUMENTS
        : !_is_Str($title) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Encode $title to WCHAR
  my $wide = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::encode('UTF-16LE', $title);
    Win32::SetLastError($err);
    $_;
  };
  return $SetConsoleTitleW->Call($wide) || undef;
}

###
# C<SetConsoleWindowInfo> sets the size and position of the console window.
#
#  - C<$handle>:   Handle to the console screen buffer
#  - C<$absolute>: TRUE for absolute coordinates, FALSE for relative
#  - C<\%rect>:    L</SMALL_RECT> structure defining the new window size
#
#  Returns: non-zero on success, undef on failure.
#
sub SetConsoleWindowInfo {    # \%coord|undef ($handle, $absolute, \%rect)
  my ($handle, $absolute, $rect) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3            ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)  ? ERROR_INVALID_HANDLE
        : !SMALL_RECT($rect) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  return Win32::Console::_SetConsoleWindowInfo($handle, $absolute ? 1 : 0, 
    SMALL_RECT::list($rect)) || undef;
}

###
# C<SetCurrentConsoleFontEx> sets the font used by the console.
#
#  - C<$handle>: Handle to the console output buffer
#  - C<$max>:    TRUE to retrieve maximum font size, FALSE for current
#  - C<\%info>:  Hash reference to a L</CONSOLE_FONT_INFOEX> structure
#
# B<Note>: C<< $info->{cbSize} >> is set by this function and therefore does 
# not need to be passed.
#
#  Returns: non-zero on success, undef on failure.
#
sub SetCurrentConsoleFontEx {    # $|undef ($handle, $max, \%info)
  my ($handle, $max, $info) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3 ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)           ? ERROR_INVALID_HANDLE
        : !_is_Bool($max)             ? ERROR_INVALID_PARAMETER
        : !CONSOLE_FONT_INFOEX($info) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  unless (defined $SetCurrentConsoleFontEx) {
    $^E = ERROR_PROC_NOT_FOUND;
    return undef;
  }

  # Encode FaceName to WCHAR
  my $wide = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::encode('UTF-16LE', $info->{FaceName});
    Win32::SetLastError($err);
    $_;
  };

  # Pack the CONSOLE_FONT_INFOEX structure with all required fields:
  # cbSize (DWORD), nFont (DWORD), dwFontSize.X (SHORT), dwFontSize.Y (SHORT),
  # FontFamily (UINT), FontWeight (UINT), FaceName (WCHAR[LF_FACESIZE])
  my $lpFontInfoEx = pack('LLSSLL' . 'a' . (2 * LF_FACESIZE),
    CONSOLE_FONT_INFOEX_SIZE,                    # Byte size of the structure
    $info->{nFont},                              # Font index
    $info->{dwFontSize}{X},                      # Font width
    $info->{dwFontSize}{Y},                      # Font height
    $info->{FontFamily},                         # Font family flags
    $info->{FontWeight},                         # Font weight (e.g. 400, 700)
    bytes::substr($wide, 0, 2 * LF_FACESIZE),
  );

  # Call the Windows API SetCurrentConsoleFontEx to apply the font settings
  my $r = $SetCurrentConsoleFontEx->Call($handle, $max ? 1 : 0, $lpFontInfoEx);
  return $r ? $r : undef;
}

###
# C<SetStdHandle> sets the handle for standard input, output, or error.
#
#  - C<$id>:     Identifier (e.g. C<STD_INPUT_HANDLE>, C<STD_OUTPUT_HANDLE>)
#  - C<$handle>: New handle to assign
#
#  Returns: non-zero on success, undef on failure.
#
sub SetStdHandle {    # $handle|undef ($id, $handle)
  my ($id, $handle) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2           ? ERROR_BAD_ARGUMENTS
        : !_is_Int($id)     ? ERROR_INVALID_PARAMETER
        : !_is_Int($handle) ? ERROR_INVALID_HANDLE
        : 0
        ;
  return Win32::Console::_SetStdHandle($id, $handle) || undef;
}

###
# C<WriteConsole> writes a string of characters to the console output buffer.
#
#  - C<$handle>:   Handle to the console output buffer
#  - C<$buffer>:   String to write
#  - C<\$written>: Reference to number of characters actually written
#
#  Returns: non-zero on success, undef on failure.
#
sub WriteConsole {    # $|undef ($handle, $buffer, \$written)
  no warnings;
  *WriteConsole = UNICODE ? \&WriteConsoleW : \&WriteConsoleA;
  goto &WriteConsole;
}

sub WriteConsoleA {    # $|undef ($handle, $buffer, \$written)
  my ($handle, $buffer, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)        ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Convert the Perl internal string (UTF-8) to an ANSI string if necessary
  $buffer = Encode::ANSI::encode($buffer, Win32::GetConsoleOutputCP());
  my $r = UNICODE 
    ? $WriteConsoleA->Call($handle, $buffer, length($buffer),
        $$written = 0, undef)
    : do {
      Win32::SetLastError(0);
      $$written = Win32::Console::_WriteConsole($handle, $buffer);
      Win32::GetLastError() ? 0 : 1;
    };
  return $r ? $r : undef;
}

sub WriteConsoleW {    # $|undef ($handle, $buffer, \$written)
  my ($handle, $buffer, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 3                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)        ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Encode $buffer to WCHAR
  my $wide = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::encode('UTF-16LE', $buffer);
    Win32::SetLastError($err);
    $_;
  };
  return $WriteConsoleW->Call($handle, $wide, length($buffer), $$written = 0, 
    undef) || undef;
}

###
# C<WriteConsoleInput> writes input records to the console input buffer.
#
#  - C<$handle>:  Handle to the console input buffer
#  - C<\%record>: Hash reference to a I<INPUT_RECORD> structure
#
#  Returns: non-zero on success, undef on failure.
#
sub WriteConsoleInput {    # $|undef ($handle, \%record)
  no warnings;
  *WriteConsoleInput = UNICODE ? \&WriteConsoleInputW : \&WriteConsoleInputA;
  goto &WriteConsoleInput;
}

sub WriteConsoleInputA {    # $|undef ($handle, \%record)
  my ($handle, $record) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_HashRef($record) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $buf = '';
  my $type = $record->{EventType} || 0;
  SWITCH: for ($type) {
    KEY_EVENT == $_ and do {
      my @ir = (
        $record->{EventType},
        $record->{Event}{bKeyDown}          || 0,
        $record->{Event}{wRepeatCount}      || 0,
        $record->{Event}{wVirtualKeyCode}   || 0,
        $record->{Event}{wVirtualScanCode}  || 0,
        $record->{Event}{uChar}             || 0,
        $record->{Event}{dwControlKeyState} || 0,
      );
      $buf = pack('L'.'LSSSSL', @ir);
      last;
    };
    MOUSE_EVENT == $_ and do {
      my @ir = (
        $record->{EventType}, 
        $record->{Event}{dwMousePosition}{X} || 0,
        $record->{Event}{dwMousePosition}{Y} || 0,
        $record->{Event}{dwButtonState}      || 0,
        $record->{Event}{dwControlKeyState}  || 0,
        $record->{Event}{dwEventFlags}       || 0,
      );
      unless (UNICODE) {
        return Win32::Console::_WriteConsoleInput($handle, @ir) || undef;
      }
      $buf = pack('L'.'SSLLL', @ir);
      last;
    };
    WINDOW_BUFFER_SIZE_EVENT == $_ and do {
      $buf = pack('L'.'SS', 
        $record->{EventType}, 
        $record->{Event}{dwSize}{X} || 0,
        $record->{Event}{dwSize}{Y} || 0,
      );
      last;
    };
    MENU_EVENT == $_ and do {
      $buf = pack('L'.'L', 
        $record->{EventType}, 
        $record->{Event}{dwCommandId} || 0,
      );
      last;
    };
    FOCUS_EVENT == $_ and do {
      $buf = pack('L'.'L', 
        $record->{EventType}, 
        $record->{Event}{bSetFocus} ? 1 : 0,
      );
      last;
    };
    DEFAULT: {
      $^E = ERROR_INVALID_VARIANT;
      return undef;
    }
  }
  my $n = 0;
  my $r = $WriteConsoleInputA->Call($handle, pack('a'.INPUT_RECORD_SIZE, $buf), 
    1, $n);
  return $r && $n ? $r : undef;
}

sub WriteConsoleInputW {    # $|undef ($handle, \%record)
  my ($handle, $record) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 2               ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)     ? ERROR_INVALID_HANDLE
        : !_is_HashRef($record) ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $buf = '';
  my $type = $record->{EventType} || 0;
  SWITCH: for ($type) {
    KEY_EVENT == $_ and do {
      $buf = pack('L'.'LSSSSL', 
        $record->{EventType},
        $record->{Event}{bKeyDown}          || 0,
        $record->{Event}{wRepeatCount}      || 0,
        $record->{Event}{wVirtualKeyCode}   || 0,
        $record->{Event}{wVirtualScanCode}  || 0,
        $record->{Event}{uChar}             || 0,
        $record->{Event}{dwControlKeyState} || 0,
      );
      last;
    };
    MOUSE_EVENT == $_ and do {
      $buf = pack('L'.'SSLLL', 
        $record->{EventType}, 
        $record->{Event}{dwMousePosition}{X} || 0,
        $record->{Event}{dwMousePosition}{Y} || 0,
        $record->{Event}{dwButtonState}      || 0,
        $record->{Event}{dwControlKeyState}  || 0,
        $record->{Event}{dwEventFlags}       || 0,
      );
      last;
    };
    WINDOW_BUFFER_SIZE_EVENT == $_ and do {
      $buf = pack('L'.'SS', 
        $record->{EventType}, 
        $record->{Event}{dwSize}{X} || 0,
        $record->{Event}{dwSize}{Y} || 0,
      );
      last;
    };
    MENU_EVENT == $_ and do {
      $buf = pack('L'.'L', 
        $record->{EventType}, 
        $record->{Event}{dwCommandId} || 0,
      );
      last;
    };
    FOCUS_EVENT == $_ and do {
      $buf = pack('L'.'L', 
        $record->{EventType}, 
        $record->{Event}{bSetFocus} ? 1 : 0,
      );
      last;
    };
    DEFAULT: {
      $^E = ERROR_INVALID_VARIANT;
      return undef;
    }
  }
  my $n = 0;
  my $r = $WriteConsoleInputW->Call($handle, pack('a'.INPUT_RECORD_SIZE, $buf), 
    1, $n);
  return $r && $n ? $r : undef;
}

###
# C<WriteConsoleOutput> function writes a block of character and attribute data 
# to a specified rectangular region of a console screen buffer. It is useful 
# for rendering formatted text directly to the console.
#
#  - C<$handle>:  Handle to the console screen buffer
#  - C<$buffer>:  Packed string of I<CHAR_INFO>'s - chars (S) and attributes (S)
#  - C<\%size>:   Size of I<CHAR_INFO>'s' (L<COORD> as width and height)
#  - C<\%coord>:  Coordinates in the buffer to start writing (L</COORD> hash)
#  - C<\%region>: L</SMALL_RECT> defining the target region in the screen buffer
# 
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: If successful, C<%region> returns the actual rectangle that was 
# used.
#
sub WriteConsoleOutput {    # $|undef ($handle, $buffer, \%size, \%coord, \%region)
  no warnings;
  *WriteConsoleOutput = UNICODE 
                      ? \&WriteConsoleOutputW 
                      : \&WriteConsoleOutputA;
  goto &WriteConsoleOutput;
} 

sub WriteConsoleOutputA {    # $|undef ($handle, $buffer, \%size, \%coord, \%region)
  my ($handle, $buffer, $size, $coord, $region) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5              ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)    ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)    ? ERROR_INVALID_PARAMETER
        : !COORD($size)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)       ? ERROR_INVALID_PARAMETER
        : !SMALL_RECT($region) ? ERROR_INVALID_PARAMETER
        : readonly(%$region)   ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my ($r, @rect);
  if (UNICODE) {
    my $rect = SMALL_RECT::pack($region);
    $r = $WriteConsoleOutputA->Call($handle, $buffer, COORD::pack($size), 
      COORD::pack($coord), $rect);
    @rect = SMALL_RECT::unpack($rect);
  }
  else {
    @rect = Win32::Console::_WriteConsoleOutput($handle, $buffer, 
      COORD::list($size), COORD::list($coord), SMALL_RECT::list($region));
    $r = @rect > 1 ? 1 : 0;
  }
  return undef unless $r;
  %$region = (
    Left   => $rect[0],
    Top    => $rect[1],
    Right  => $rect[2],
    Bottom => $rect[3],
  );
  return $r;
}

sub WriteConsoleOutputW {   # $|undef ($handle, $buffer, \%size, \%coord, \%region)
  my ($handle, $buffer, $size, $coord, $region) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 5              ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)    ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)    ? ERROR_INVALID_PARAMETER
        : !COORD($size)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)       ? ERROR_INVALID_PARAMETER
        : !SMALL_RECT($region) ? ERROR_INVALID_PARAMETER
        : readonly(%$region)   ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $rect = SMALL_RECT::pack($region);
  my $r = $WriteConsoleOutputW->Call($handle, $buffer, COORD::pack($size), 
    COORD::pack($coord), $rect);
  my @rect = SMALL_RECT::unpack($rect);
  %$region = (
    Left   => $rect[0],
    Top    => $rect[1],
    Right  => $rect[2],
    Bottom => $rect[3],
  );
  return $r ? $r : undef;
}

###
# C<WriteConsoleOutputAttribute> writes character attributes to the console 
# screen buffer.
#
#  - C<$handle>:   Handle to the console screen buffer
#  - C<$buffer>:   Packed string of attributes (C<S*>)
#  - C<\%coord>:   Starting coordinate (L</COORD> structure)
#  - C<\$written>: Reference to number of attributes written
#
#  Returns: non-zero on success, undef on failure.
#
# B<Note>: The L<Win32::Console> XS function has some limitations: the maximum 
# supported data length is C<80*999>. Furthermore, only the lower byte of the 
# attribute (the color component) is processed (no C<DCBS> support).
#
sub WriteConsoleOutputAttribute {    # $|undef ($handle, $buffer, \%coord, \$written)
  my ($handle, $buffer, $coord, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 4                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)           ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $length = bytes::length($buffer);
  if ($length > 80*999) {
    $^E = ERROR_INVALID_USER_BUFFER;
    return undef;
  }
  Win32::SetLastError(0);
  # Unfortunately, the XS function only processes lower bytes and not words.
  $$written = Win32::Console::_WriteConsoleOutputAttribute($handle, 
    pack('C*', unpack('S*', $buffer)), COORD::list($coord));
  return Win32::GetLastError() ? undef : 1;
}

###
# C<WriteConsoleOutputCharacter> writes characters to the console screen buffer.
#
#  - C<$handle>:   Handle to the console screen buffer
#  - C<$buffer>:   String of characters
#  - C<\%coord>:   Starting coordinate (L</COORD> structure)
#  - C<\$written>: Reference to number of attributes written
#
#  Returns: non-zero on success, undef on failure.
#
sub WriteConsoleOutputCharacter {    # $|undef ($handle, $buffer, \%coord, \$written)
  no warnings;
  *WriteConsoleOutputCharacter = UNICODE 
                              ? \&WriteConsoleOutputCharacterW 
                              : \&WriteConsoleOutputCharacterA;
  goto &WriteConsoleOutputCharacter;
}

sub WriteConsoleOutputCharacterA {    # $|undef ($handle, $buffer, \%coord, \$written)
  my ($handle, $buffer, $coord, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 4                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)           ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  # Convert the Perl internal string (UTF-8) to an ANSI string if necessary
  $buffer = Encode::ANSI::encode($buffer, Win32::GetConsoleOutputCP());
  my $r = UNICODE
    ? $WriteConsoleOutputCharacterA->Call($handle, $buffer, length($buffer), 
        COORD::pack($coord), $$written = 0)
    : do {
      Win32::SetLastError(0);
      $$written = Win32::Console::_WriteConsoleOutputCharacter($handle, 
        $buffer, COORD::list($coord));
      Win32::GetLastError() ? 0 : 1;
    };
  return $r ? $r : undef;
}

sub WriteConsoleOutputCharacterW {    # $|undef ($handle, $buffer, \%coord, \$written)
  my ($handle, $buffer, $coord, $written) = @_;
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ != 4                  ? ERROR_BAD_ARGUMENTS
        : !_is_Int($handle)        ? ERROR_INVALID_HANDLE
        : !_is_Str($buffer)        ? ERROR_INVALID_PARAMETER
        : !COORD($coord)           ? ERROR_INVALID_PARAMETER
        : !_is_ScalarRef($written) ? ERROR_INVALID_PARAMETER
        : readonly($$written)      ? ERROR_INVALID_PARAMETER
        : 0
        ;
  my $dwWriteCoord = COORD::pack($coord);
  # Encode $buffer to WCHAR
  my $wide = do { local $_;
    my $err = Win32::GetLastError();    # Encode may set $^E
    $_ = Encode::encode('UTF-16LE', $buffer);
    Win32::SetLastError($err);
    $_;
  };
  return $WriteConsoleOutputCharacterW->Call($handle, $wide, length($buffer),
    $dwWriteCoord, $$written = 0) || undef;
}

# C<GetOSVersion> retrieves information about the current Windows operating 
# system. This Version should also work for Version > 6.2.
#
#  Returns a list containing:
#   [0] OS description string (e.g. "Microsoft Windows 10")
#   [1] Major version number (e.g. 10)
#   [2] Minor version number (e.g. 0)
#   [3] Build number (e.g. 19041)
#   [4] Platform ID (e.g. 2 for Win32_NT)
#
#  On Windows NT 4 SP6 and later this function returns the following additional 
#  values:
#   [5] Service Pack Major version number
#   [6] Service Pack Minor version number
#   [7] Suite Mask
#   [8] Product Type
#
# In a scalar context, it returns only the Platform ID C<[4]>.
#
sub GetOSVersion {    # $|@ ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  goto RETURN if @VersionInformation;

  @VersionInformation = Win32::GetOSVersion();

  # Older Win32 Perl modules use a code that has not been manifested for 
  # Windows 8.1 and newer, and therefore returns a Windows 8 version (6.2) 
  # as a value. 
  my $bad_manifest = do {
    my ($os, $major, $minor, $build, $id) = @VersionInformation;
    !$os && $id && $major == 6 && $minor == 2;
  };
  goto RETURN unless $bad_manifest;

  if (EMULATE_GET_VERSION) {
    my $buffer = "\0" x OSVERSIONINFOEXW_SIZE;

    # Set dwOSVersionInfoSize
    substr($buffer, 0, 4) = pack("L", OSVERSIONINFOEXW_SIZE);
    my $status = $RtlGetVersion->Call($buffer);
    goto RETURN unless $status == 0;

    # Extract dwMajorVersion, dwMinorVersion, dwBuildNumber, dwPlatformId
    my ($major, $minor, $build, $id) = unpack('x4'.'L4', $buffer);
    goto RETURN unless $id;

    # Extract wServicePackMajor, wServicePackMinor, wSuiteMask, wProductType
    my ($spmajor, $spminor, $mask, $type) = unpack('x276'.'S4', $buffer);

    my $os = _GetEditionName();
    $os = '' unless defined $os;

    @VersionInformation = (
        $os, 
        $major, $minor, $build, $id, 
        $spmajor, $spminor, $mask, $type
    );
  }

RETURN:
  return wantarray ? @VersionInformation : $VersionInformation[4];
}

#--------------------
# Helper Subroutines
#--------------------

my $CONSOLE_CURSOR_INFO = { dwSize => 0, bVisible => 0 };

# Usage:
#
#  my \%hashref = CONSOLE_CURSOR_INFO();
#  my \%hashref = CONSOLE_CURSOR_INFO($size, $visible) // die;
#  my \%hashref = CONSOLE_CURSOR_INFO({
#    dwSize   => $size, 
#    bVisible => $visible,
#  }) // die;
sub CONSOLE_CURSOR_INFO { # $hashref|undef (|@|\%)
  return lock_ref_keys { %$CONSOLE_CURSOR_INFO } 
      if @_ == 0
      ;
  return lock_ref_keys { %{$_[0]} }
      if @_ == 1 
      && _is_HashRef($_[0])
      && keys(%{$_[0]}) == keys(%$CONSOLE_CURSOR_INFO)
      && grep(!exists($_[0]->{$_}), keys %$CONSOLE_CURSOR_INFO) == 0
      &&  _is_Int($_[0]->{dwSize})
      && _is_Bool($_[0]->{bVisible})
      ;
  return lock_ref_keys { 
      dwSize   => $_[0], 
      bVisible => $_[1] ? 1 : 0,
    } if @_ == 2
      &&  _is_Int($_[0])
      && _is_Bool($_[1]);
  return;
}

my $CONSOLE_FONT_INFO = { nFont => 0, dwFontSize => COORD() };

# Usage:
#
#  my \%hashref = CONSOLE_FONT_INFO();
#  my @fontSize = ($fontSizeX, $fontSizeY);
#  my \%hashref = CONSOLE_FONT_INFO($index, @fontSize) // die;
#  my \%hashref = CONSOLE_FONT_INFO({
#    nFont      => $index,
#    dwFontSize => COORD(@fontSize),
#  }) // die;
sub CONSOLE_FONT_INFO {    # $hashref|undef (|@|\%)
  return _lock_ref_keys_recure { %$CONSOLE_FONT_INFO }
      if @_ == 0
      ;
  return _lock_ref_keys_recure { %{$_[0]} }
      if @_ == 1
      && _is_HashRef($_[0])
      && keys(%{$_[0]}) == keys(%$CONSOLE_FONT_INFO)
      && grep(!exists($_[0]->{$_}), keys %$CONSOLE_FONT_INFO) == 0
      && _is_Int($_[0]->{nFont})
      &&   COORD($_[0]->{dwFontSize})
      ;
  return _lock_ref_keys_recure {
      nFont      => shift,
      dwFontSize => COORD(shift, shift),
    } if grep(_is_Int($_) => @_) == 3;
  return;
}

my $CONSOLE_FONT_INFOEX = {
  cbSize     => 0,
  nFont      => 0,
  dwFontSize => COORD(),
  FontFamily => 0,
  FontWeight => 0,
  FaceName   => "\0",
};

# Usage:
#
#  my \%hashref = CONSOLE_FONT_INFOEX();
#  my @fontSize = ($fontSizeX, $fontSizeY);
#  my \%hashref = CONSOLE_FONT_INFOEX($index, @fontSize) // die;
#  my \%hashref = CONSOLE_FONT_INFOEX({
#    cbSize     => CONSOLE_FONT_INFOEX_SIZE,
#    nFont      => $index,
#    dwFontSize => COORD(@fontSize),
#    FontFamily => $pitch,
#    FontWeight => $weight,
#    FaceName   => $string,
#  }) // die;
sub CONSOLE_FONT_INFOEX {    # $hashref|undef (|@|\%)
  return _lock_ref_keys_recure { %$CONSOLE_FONT_INFOEX }
      if @_ == 0
      ;
  return _lock_ref_keys_recure { %{$_[0]} }
      if @_ == 1
      && _is_HashRef($_[0])
      && keys(%{$_[0]}) == keys(%$CONSOLE_FONT_INFOEX)
      && grep(!exists($_[0]->{$_}), keys %$CONSOLE_FONT_INFOEX) == 0
      && _is_Int($_[0]->{cbSize})
      && _is_Int($_[0]->{nFont})
      &&   COORD($_[0]->{dwFontSize})
      && _is_Int($_[0]->{FontFamily})
      && _is_Int($_[0]->{FontWeight})
      && _is_Str($_[0]->{FaceName})
      ;
  return _lock_ref_keys_recure {
      cbSize     => shift,
      nFont      => shift,
      dwFontSize => COORD(shift, shift),
      FontFamily => shift,
      FontWeight => shift,
      FaceName   => shift,
    } if grep(_is_Int($_) => $_[0..5]) == 6
      && _is_Str($_[6]);
  return;
}

my $CONSOLE_READCONSOLE_CONTROL = { 
  nLength           => 0,
  nInitialChars     => 0,
  dwCtrlWakeupMask  => 0,
  dwControlKeyState => 0,
};

# Usage:
#
#  my \%hashref = CONSOLE_READCONSOLE_CONTROL();
#  my \%hashref = CONSOLE_READCONSOLE_CONTROL($len, $n, $mask, $state) // die;
#  my \%hashref = CONSOLE_READCONSOLE_CONTROL({
#    nLength           => $len,
#    nInitialChars     => $n,
#    dwCtrlWakeupMask  => $mask,
#    dwControlKeyState => $state,
#  }) // die;
sub CONSOLE_READCONSOLE_CONTROL { # $hashref|undef (|@|\%)
  return lock_ref_keys { %$CONSOLE_READCONSOLE_CONTROL } 
      if @_ == 0
      ;
  return lock_ref_keys { %{$_[0]} }
      if @_ == 1 
      && ref($_[0]) eq 'HASH'
      && keys(%{$_[0]}) == keys(%$CONSOLE_READCONSOLE_CONTROL)
      && grep(_is_Int($_[0]->{$_})
         => keys %$CONSOLE_READCONSOLE_CONTROL) == 4
      ;
  return lock_ref_keys { 
      nLength           => shift,
      nInitialChars     => shift,
      dwCtrlWakeupMask  => shift,
      dwControlKeyState => shift,
    } if grep(_is_Int($_) => @_) == 4;
  return;
}

my $CONSOLE_SCREEN_BUFFER_INFO = {
  dwSize              => COORD(),
  dwCursorPosition    => COORD(),
  wAttributes         => 0,
  srWindow            => SMALL_RECT(),
  dwMaximumWindowSize => COORD(),
};

# Usage:
#
#  my \%hashref = CONSOLE_SCREEN_BUFFER_INFO();
#  my @size     = ($sizeX, $sizeY);
#  my @cursor   = ($cursorX, $cursorY);
#  my @win_rect = ($left, $top, $right, $bottom);
#  my @max_size = ($maxX, $maxY);
#  my \%hashref = CONSOLE_SCREEN_BUFFER_INFO(
#    @size,
#    @cursor,
#    $attr,
#    @win_rect,
#    @max_size,
#  ) // die;
#  my \%hashref = CONSOLE_SCREEN_BUFFER_INFO({
#    dwSize              => COORD(@size),
#    dwCursorPosition    => COORD(@cursor),
#    wAttributes         => $attr,
#    srWindow            => SMALL_RECT(@win_rect),
#    dwMaximumWindowSize => COORD(@max_size)
#  }) // die;
sub CONSOLE_SCREEN_BUFFER_INFO {    # $hashref|undef (|@|\%)
  return _lock_ref_keys_recure { %$CONSOLE_SCREEN_BUFFER_INFO }
      if @_ == 0
      ;
  return _lock_ref_keys_recure { %{$_[0]} }
      if @_ == 1 
      && _is_HashRef($_[0]) eq 'HASH'
      && keys(%{$_[0]}) == keys(%$CONSOLE_SCREEN_BUFFER_INFO)
      && grep(!exists($_[0]->{$_}), keys %$CONSOLE_SCREEN_BUFFER_INFO) == 0
      &&      COORD($_[0]->{dwSize})
      &&      COORD($_[0]->{dwCursorPosition})
      &&    _is_Int($_[0]->{wAttributes})
      && SMALL_RECT($_[0]->{srWindow})
      &&      COORD($_[0]->{dwMaximumWindowSize})
      ;
  return _lock_ref_keys_recure {
      dwSize              => COORD(shift, shift),
      dwCursorPosition    => COORD(shift, shift),
      wAttributes         => shift,
      srWindow            => SMALL_RECT(shift, shift, shift, shift),
      dwMaximumWindowSize => COORD(shift, shift),
    } if grep(_is_Int($_) => @_) == 11;
  return;
}

my $COORD; BEGIN { $COORD = { X => 0, Y => 0 } }

# Usage:
#
#  my \%hashref = COORD();
#  my \%hashref = COORD($x, $y) // die;
#  my \%hashref = COORD({X => $x, Y = $y}) // die;
sub COORD {    # $hashref|undef (|@|\%)
  return lock_ref_keys { %$COORD }
      if @_ == 0
      ;
  return lock_ref_keys { %{$_[0]} }
      if @_ == 1
      && _is_HashRef($_[0])
      && keys(%{$_[0]}) == keys(%$COORD)
      && grep(_is_Int($_[0]->{$_}) => keys(%$COORD)) == 2
      ;
  return lock_ref_keys {
      X => shift, 
      Y => shift,
    } if grep(_is_Int($_) => @_) == 2;
  return;
}

sub COORD::list ($) {    # @ (\%)
  return @{$_[0]}{qw(X Y)};
}

sub COORD::pack ($) {    # $ (\%)
  return unpack('L', pack('SS', @{$_[0]}{qw(X Y)}));
}

sub COORD::unpack ($) {    # @ ($)
  return unpack('SS', pack('L', $_[0]));
}

# Decode the ANSI string into a Perl string using the system code page or 
# C<$codepage>, if specified. 
#
# B<Note>: If the code page is CP_UTF8, no conversion takes place, but the UTF8 
# flag may be set.
sub Encode::ANSI::decode {    # $str ($ansi, |$codepage)
  my ($ansi, $cpi) = @_;
  $cpi ||= CP_ACP;
  if ($ansi =~ /[^\x00-\x7f]/) {
    if ($cpi != CP_UTF8) {
      my $wide = _MultiByteToWideChar($ansi, $cpi);
      if (defined $wide) {
        my $err = Win32::GetLastError();    # Encode may set $^E
        my $str = Encode::decode('UTF-16LE', $wide);
        Win32::SetLastError($err);
        return $str;
      }
    }
    _utf8_on($ansi);
    Win32::SetLastError(0);
  }
  return $ansi;
}

# Use the default system code page if none is specified, and encode the 
# character string only if the target C<$codepage> is not C<CP_UTF8>.
#
# First convert the UTF-8 string to a UTF-16LE wide string, then convert the 
# UTF-16LE wide string to a multibyte string using the target C<$codepage> and 
# return the encoded multibyte (ANSI) version.
#
# B<Note>: Only converts if C<$str> has UTF-8 characters, otherwise it is 
# already ANSI compatible. The returned string does not have the UTF8 flag set.
sub Encode::ANSI::encode {    # $ansi ($str, |$codepage)
  my ($str, $cpi) = @_;
  $cpi ||= CP_ACP;
  if ($str =~ /[\xC0-\xf7]/) {
    if ($cpi != CP_UTF8) {
      my $err = Win32::GetLastError();    # Encode may set $^E
      my $wide = Encode::encode('UTF-16LE', $str);
      Win32::SetLastError($err);
      my $ansi = _WideCharToMultiByte($wide, $cpi);
      return $ansi if defined $ansi;
    }
    _utf8_off($str);
    Win32::SetLastError(0);
  }
  return $str;
}

my $SMALL_RECT; BEGIN { $SMALL_RECT = { 
  Left => 0, Top => 0, Right => 0, Bottom => 0 }
}

# Usage:
#
#  my \%hashref = SMALL_RECT();
#  my \%hashref = SMALL_RECT(
#    $left, 
#    $top, 
#    $right, 
#    $bottom,
#  ) // die;
#  my \%hashref = SMALL_RECT({
#    Left    => $left, 
#    Top     => $top, 
#    Right   => $right, 
#    Bottom  => $bottom,
#  }) // die;
sub SMALL_RECT {    # $hashref|undef (|@|\%)
  return lock_ref_keys { %$SMALL_RECT } 
      if @_ == 0
      ;
  return lock_ref_keys { %{$_[0]} }
      if @_ == 1
      && _is_HashRef($_[0])
      && keys(%{$_[0]}) == keys(%$SMALL_RECT)
      && grep(_is_Int($_[0]->{$_}) => keys(%$SMALL_RECT)) == 4
      ;
  return lock_ref_keys {
      Left   => shift,
      Top    => shift,
      Right  => shift,
      Bottom => shift,
    } if grep(_is_Int($_) => @_) == 4;
  return;
}

sub SMALL_RECT::list ($) {    # @ (\%)
  return @{$_[0]}{qw(Left Top Right Bottom)};
}

sub SMALL_RECT::pack ($) {    # $ (\%)
  return pack('S4', @{$_[0]}{qw(Left Top Right Bottom)});
}

sub SMALL_RECT::unpack ($) {    # @ ($)
  return unpack('S4', $_[0]);
}

#--------------------
# Private Subroutines
#--------------------

# Returns the context of the current pure perl subroutine call.
sub __CALLER__ {    # \% ($level|undef)
  my $level = shift || 0;
  my %hash; 
  @hash{qw(
    package filename line subroutine hasargs 
    wantarray evaltext is_require hints bitmask hinthash
  )} = caller($level+1);
  return \%hash;
}

# Returns the subroutine name.
sub __FUNCTION__ () {    # $subname ()
  my $pkg = __CALLER__(0)->{package}    || 'main';
  my $sub = __CALLER__(1)->{subroutine} || 'main::__ANON__';
  my $__func__ = (split $pkg . '::', $sub)[-1];
  return $__func__;
}

sub _HRESULT_CODE ($) {    # $ ($hr)
  no warnings;
  $_[0] & 0xffff;
}

sub _HRESULT_FACILITY ($) {    # $ ($hr)
  no warnings;
  ($_[0] >> 16) & 0x1fff;
}

# This sub converts a Win32 error code to an HRESULT
sub __HRESULT_FROM_WIN32 ($) {
  no warnings;
  $_[0] <= 0 ? $_[0] : 
    (($_[0] & 0x0000ffff) | (FACILITY_WIN32 << 16) | 0x80000000)
}

# Create a cache so that the search routine does not have to be performed again.
my %hwndFound = (0 => 0);

# Get the handle of the current console window by using window's title. 
# See: http://support.microsoft.com/kb/124103 and
# https://metacpan.org/release/JDB/Win32-Console-0.10/source/Console.xs#L35
sub _GetConsoleHwnd {    # $ ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  my $tmpTitle;    # Contains fabricated WindowTitle
  my $oldTitle;    # Contains original WindowTitle
  
  # This is what is returned to the caller
  my $id = $GetConsoleWindow->Call();
  return $hwndFound{$id} if $hwndFound{$id};

  # Fetch current window title
  $oldTitle = Win32::Console::_GetConsoleTitle();

  # Format a "unique" temporary window title
  $tmpTitle = sprintf("%d/%d", 
    Win32::GetTickCount(), 
    Win32::GetCurrentThreadId()
  );

  # Change current window title
  my $success = Win32::Console::_SetConsoleTitle($tmpTitle);

  if ( $oldTitle && $success ) {
    # Ensure window title has been updated
    Win32::Sleep(40);

    # Look for temporary window title
    $hwndFound{$id} = $FindWindow->Call(undef, $tmpTitle);

    # Restore original window title
    Win32::Console::_SetConsoleTitle($oldTitle);
  }

  return $hwndFound{$id};
}

# Check for a reasonable boolean value. Accepts C<1>, C<0>, the empty string 
# and C<undef>.
# B<Note>: Fallback taken from L<Type::Nano>.
sub _is_Bool ($) {    # $bool ($)
  no warnings;
  *_is_Bool = HAS_TYPE_TINY ? \&Types::Standard::is_Bool : sub {
    return !defined($_[0]) 
        || !ref($_[0]) && { 1 => 1, 0 => 1, '' => 1 }->{$_[0]};
  };
  goto &_is_Bool;
}

# Get the product name from Windows Registry. Returns undef if an error occurs.
sub _GetEditionName {    # $|undef ()
  croak(_usage("$^E", __FILE__, __FUNCTION__)) if 
    $^E = @_ ? ERROR_BAD_ARGUMENTS
        : 0
        ;
  unless (defined $ProductName) {
    TRY: eval {
      require Win32API::Registry;
      my $hkey;
      my $path  = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion';
      my $value = 'ProductName';

      # Open registry key
      my $r = Win32API::Registry::RegOpenKeyEx(
        Win32API::Registry::HKEY_LOCAL_MACHINE(), $path, 0, 
          Win32API::Registry::KEY_READ(), $hkey);
      $^E = Win32API::Registry::regLastError() unless $r;
      die unless $r;

      # Prepare buffer
      my $data = "\0" x 256;
      my $size = pack("L", 256);
      my $type = pack("L", 0);

      # Query value
      $r = Win32API::Registry::RegQueryValueEx($hkey, $value, [], $type, 
        $data, $size);
      my $err = Win32API::Registry::regLastError() unless $r;  # save error code
      Win32API::Registry::RegCloseKey($hkey);
      $^E = $err if $err;    # restore old error code if necessary
      die unless $r;

      # Clean up and return string
      $data =~ s/\0+$//;
      $ProductName = $data;
    };
    CATCH: if ($@) {
      $ProductName = '';
    }
  }
  return $ProductName;
}

# Check for code reference.
# B<Note>: Returns FALSE on objects.
sub _is_CodeRef ($) {    # $bool (\%)
  no warnings;
  *_is_CodeRef = HAS_TYPE_TINY ? \&Types::Standard::is_CodeRef : sub {
    return ref($_[0]) eq 'CODE';
  };
  goto &_is_CodeRef;
}

# Check for hash reference. Allows the hash to be empty. 
# B<Note>: Returns FALSE on objects, TRUE for C<HashRef[Ref]>.
sub _is_HashRef ($) {    # $bool (\%)
  no warnings;
  *_is_HashRef = HAS_TYPE_TINY ? \&Types::Standard::is_HashRef : sub {
    return ref($_[0]) eq 'HASH';
  };
  goto &_is_HashRef;
}

# Check for a integer.
# B<Note>: Don't allow a preceding C<+>.
sub _is_Int ($) {    # $bool ($)
  no warnings;
  *_is_Int = HAS_TYPE_TINY ? \&Types::Standard::is_Int : sub {
    return defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A-?\d+\z/;
  };
  goto &_is_Int;
}

# Check for scalar reference.
# B<Note>: Returns FALSE on objects, TRUE for C<ScalarRef[Ref]>.
sub _is_ScalarRef ($) {    # $bool (\$)
  no warnings;
  *_is_ScalarRef = HAS_TYPE_TINY ? \&Types::Standard::is_ScalarRef : sub {
    return ref($_[0]) eq 'SCALAR';
  };
  goto &_is_ScalarRef;
}

# Check for a string. Allows the string to be empty.
sub _is_Str ($) {    # $bool ($)
  no warnings;
  *_is_Str = HAS_TYPE_TINY ? \&Types::Standard::is_Str : sub {
    return defined($_[0]) && !ref($_[0]);
  };
  goto &_is_Str;
}

# Converts a ANSI string in Unicode format (UTF-16).
# See: L<https://metacpan.org/release/JDB/Win32-0.59/source/Win32.xs#L130>
sub _MultiByteToWideChar {    # $wstr|undef ($str, |$cp)
  my ($str, $cp) = @_;
  return undef unless defined $str;
  return '' unless $str;
  $cp = CP_ACP unless defined $cp;
  my $raw = bytes::substr($str, 0);
  my $len = bytes::length($raw);
  my $wlen = $MultiByteToWideChar->Call($cp, 0, $raw, $len, undef, 0) 
    || return undef;
  my $wide = "\0" x (2 * $wlen);
  my $r = $MultiByteToWideChar->Call($cp, 0, $raw, $len, $wide, $wlen) 
    || return undef;
  return $wide;
}

# C<_lock_ref_keys_recure> locks an entire hash and any hashes it references 
# recursively, making all keys read-only. No keys can be added or deleted.
sub _lock_ref_keys_recure ($) {
  return unless _is_HashRef($_[0]);

  my $seen = $_[1] || {};
  my $addr = Scalar::Util::refaddr($_[0]);
  return if $seen->{$addr}++;  # Skip if already seen

  # Recursively go through all keys
  foreach (keys %{$_[0]}) {
    # next unless _is_HashRef($_[0]->{$_});
    _lock_ref_keys_recure($_[0]->{$_}, $seen);
  }

  # Lock the keys of the current hash
  return lock_ref_keys $_[0];
}

# Returns a usage message from the embedded (auto)pod of a file.
sub _usage {    # $string ($message, $filename, $subroutine)
  my ($msg, $file, $sub) = @_;
  local ($!, $@);

  my $autopod = eval {
    require Pod::Autopod;
    my $ap = Pod::Autopod->new();
    $ap->readFile($file);
    $ap->getPod();
  };

  my $usage = eval {
    require Pod::Usage;
    my $in;
    if ($autopod) {
      open($in, "<", \$autopod) or die $!;
    } else {
      open($in, "<", $file) or die $!;
    }
    my $text = '';
    open(my $out, ">", \$text) or die $!;
    Pod::Usage::pod2usage(
      -message  => $msg,
      -exitval  => 'NOEXIT',
      -verbose  => 99,
      -sections => "METHODS|FUNCTIONS/$sub",
      -output   => $out,
      -input    => $in,
    );
    close($in) or die $!;
    close($out) or die $!;
    # Adjust the output
    $text =~ s/\s*$sub:\s*/\nUsage: /s;
    $text = $1 if $text =~ /(.+?)\n\n/s;
    $text;
  } || $msg;

  return $usage;
}

# Turns the string's internal UTF8 flag off. See: L<Encode/_utf8_off>
sub _utf8_off ($) {
  no warnings;
  # Fallback if the internal routine is no longer available
  *_utf8_off = Encode->can('_utf8_off') || sub {
    my $is_utf8 = Encode::is_utf8($_[0]);
    $_[0] = Encode::encode('UTF-8', $_[0]) if $is_utf8;
    return $is_utf8;
  };
  goto &_utf8_off;
}

# Turns the string's internal UTF8 flag on. See: L<Encode/_utf8_on>
sub _utf8_on ($) {
  no warnings;
  # Fallback if the internal routine is no longer available
  *_utf8_on = Encode->can('_utf8_on') || sub {
    my $is_utf8 = Encode::is_utf8($_[0]);
    $_[0] = Encode::decode('UTF-8', $_[0]) unless $is_utf8;
    return $is_utf8;
  };
  goto &_utf8_on;
}

# Converts an Unicode string (UTF-16) to a ANSI string.
# See: L<https://metacpan.org/release/JDB/Win32-0.59/source/Win32.xs#L149>
sub _WideCharToMultiByte {    # $str|undef ($wstr, |$cp)
  my ($wstr, $cp) = @_;
  return undef unless defined $wstr;
  $cp = CP_ACP unless defined $cp;
  my $wlen = (bytes::length($wstr) >> 1) || return '';
  my $flags = $cp != CP_UTF8 ? WC_NO_BEST_FIT_CHARS : 0;
  my $use_default = 0;
  my $len = $WideCharToMultiByte->Call($cp, $flags, $wstr, $wlen, 
    undef, 0, undef, undef);
  my $str = "\0" x $len;
  $len = $WideCharToMultiByte->Call($cp, $flags, $wstr, $wlen, 
    $str, $len, undef, $use_default);
  if ($use_default) {
    $len = $WideCharToMultiByte->Call($cp, 0, $wstr, $wlen, 
      undef, 0, undef, undef);
    $str = "\0" x $len;
    $len = $WideCharToMultiByte->Call($cp, 0, $wstr, $wlen, 
      $str, $len, undef, undef);
  }
  substr($str, $len) = '';
  return $str;
}

1;
