package TestConsole;

use strict;
use warnings;

use Win32;
use Win32API::File qw(
  CreateFile
  GENERIC_READ
  GENERIC_WRITE
  FILE_SHARE_WRITE
  OPEN_EXISTING
  INVALID_HANDLE_VALUE
);
use Win32API::Console qw(
  GetConsoleMode
  AllocConsole
);

use Exporter qw( import );
our @EXPORT_OK = qw(
  GetConsoleOutputHandle
);

sub GetConsoleOutputHandle () {
  my $hCout = CreateFile(
    'CONOUT$',
    GENERIC_READ | GENERIC_WRITE,
    FILE_SHARE_WRITE,
    [],
    OPEN_EXISTING,
    0,
    []
  );

  if ($hCout && $hCout != INVALID_HANDLE_VALUE) {
    my $mode;
    return $hCout if GetConsoleMode($hCout, \$mode);
  }

  Win32::SetLastError(0);
  AllocConsole();
  return undef if Win32::GetLastError();

  $hCout = CreateFile(
    'CONOUT$',
    GENERIC_READ | GENERIC_WRITE,
    FILE_SHARE_WRITE,
    [],
    OPEN_EXISTING,
    0,
    []
  );
  return undef if Win32::GetLastError();

  if ($hCout && $hCout != INVALID_HANDLE_VALUE) {
    my $mode;
    return $hCout if GetConsoleMode($hCout, \$mode);
  }

  return undef;
}

1;
