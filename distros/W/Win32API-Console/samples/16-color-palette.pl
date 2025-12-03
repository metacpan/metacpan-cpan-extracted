# Using the GetConsoleScreenBufferInfoEx function, the Win32 console palette is 
# read, compared to ANSI 256 colors, and visualized.

use strict;
use warnings;
use utf8;

use lib '../lib', 'lib';
use version;
use Win32;
use Win32API::Console qw(
  GetStdHandle
  GetConsoleOutputCP
  GetConsoleScreenBufferInfoEx
  GetOSVersion
  SetConsoleOutputCP
  CONSOLE_SCREEN_BUFFER_INFOEX
  INVALID_HANDLE_VALUE
  STD_OUTPUT_HANDLE
);

use constant ERROR_NOT_SUPPORTED => 50;

# Extract RGB components from COLORREF
sub GetRValue { $_[0]       & 0xff }
sub GetGValue { $_[0] >> 8  & 0xff }
sub GetBValue { $_[0] >> 16 & 0xff }

# Convert ANSI color index to RGB
sub ansi_rgb {
  my ($i) = @_;
  return (0, 0, 0)       if $i == 0;
  return (128, 0, 0)     if $i == 1;
  return (0, 128, 0)     if $i == 2;
  return (128, 128, 0)   if $i == 3;
  return (0, 0, 128)     if $i == 4;
  return (128, 0, 128)   if $i == 5;
  return (0, 128, 128)   if $i == 6;
  return (192, 192, 192) if $i == 7;
  return (128, 128, 128) if $i == 8;
  return (255, 0, 0)     if $i == 9;
  return (0, 255, 0)     if $i == 10;
  return (255, 255, 0)   if $i == 11;
  return (0, 0, 255)     if $i == 12;
  return (255, 0, 255)   if $i == 13;
  return (0, 255, 255)   if $i == 14;
  return (255, 255, 255) if $i == 15;

  if ($i >= 16 && $i <= 231) {
    my $idx = $i - 16;
    my $r = int($idx / 36);
    my $g = int(($idx % 36) / 6);
    my $b = $idx % 6;
    return (55 + $r * 40, 55 + $g * 40, 55 + $b * 40);
  }

  if ($i >= 232 && $i <= 255) {
    my $gray = 8 + ($i - 232) * 10;
    return ($gray, $gray, $gray);
  }

  return (0, 0, 0);
}

# Calculate the RGB distance
sub rgb_dist {
  my ($r1, $g1, $b1, $r2, $g2, $b2) = @_;
  return sqrt(($r1 - $r2)**2 + ($g1 - $g2)**2 + ($b1 - $b2)**2);
}

# Find closest Win32 palette color
sub closest_win32 {
  my ($r,$g,$b,$palette) = @_;
  my ($best,$min) = (0,1e9);
  for my $i (0..15) {
    my ($wr,$wg,$wb) = @{$palette->[$i]};
    my $d = rgb_dist($r,$g,$b,$wr,$wg,$wb);
    if ($d < $min) {
      $min = $d;
      $best = $i;
    }
  }
  return ($best,$min);
}

# Choose unicode character based on color distance
sub dither_char {
  my ($dist) = @_;
  return '█' if $dist < 20;
  return '▓' if $dist < 40;
  return '▒' if $dist < 80;
  return '░';
}

sub main {
  # Starting with Windows 10 version 1909, ANSI colors are supported by default 
  # in the standard terminal (called conhost).
  my $os = version->declare(sprintf('v%2$d.%3$d.%4$d', GetOSVersion()));
  return ERROR_NOT_SUPPORTED 
    if $os < v10.0.1909;

  # Get the console output handle
  my $hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
  return Win32::GetLastError()
    if $hConsole == INVALID_HANDLE_VALUE;

  # Get Win32 color palette
  my $csbiex = CONSOLE_SCREEN_BUFFER_INFOEX;
  GetConsoleScreenBufferInfoEx($hConsole, $csbiex)
    or return Win32::GetLastError();

  # Extract Win32 color palette
  my @palette;
  for my $i (0..15) {
    my $c = $csbiex->{ColorTable}[$i];
    $palette[$i] = [GetRValue($c), GetGValue($c), GetBValue($c)];
  }

  # Set UTF-8 for output
  my $cp = GetConsoleOutputCP();
  SetConsoleOutputCP(65001)
    or return Win32::GetLastError();
  binmode(STDOUT, ":utf8");

  # Print header
  print "\nANSI 256 → Win32 16 Color Mapping with Unicode Dithering\n";
  printf "%-5s %-15s %-20s %-6s %-7s\n", "ANSI", "RGB", "Best Match", "ΔRGB", 
    "Mix";
  print "-" x 70 . "\n";

  # Loop through all ANSI color
  for my $i (0..255) {
    my ($r, $g, $b)  = ansi_rgb($i);
    my ($best, $min) = closest_win32($r,$g,$b, \@palette);
    my $char         = dither_char($min);

    printf "%-5d rgb(%3d,%3d,%3d)  idx %2d rgb(%3d,%3d,%3d)  %5.1f  ",
      $i, $r, $g, $b, $best, @{$palette[$best]}, $min;

    # Foreground = ANSI color, Background = closest Win32 color
    print "\e[48;5;${best}m\e[38;5;${i}m$char\e[0m\n";
  }

  # Restore original output codepage
  SetConsoleOutputCP($cp);
  return 0;
}

exit main();

__END__

=pod

This script retrieves the current Win32 console 16 color palette using the 
L<GetConsoleScreenBufferInfoEx|Win32API::Console/GetConsoleScreenBufferInfoEx> 
function and compares it with the ANSI 256 color table, calculating the best 
match for each color.

It then outputs a Unicode-block visualization of the mapping, showing RGB 
values, best matches, and color differences in a formatted table.

The ANSI color is displayed in the foreground, while the closest Win32 color 
is used as the background. The block character visually indicates the accuracy 
of the mapping to the Win32 console 16 color palette.

B<Note>: Only works with Windows 10 version 1909 or later.
