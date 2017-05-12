package Win32::Console::GetC;

use strict;
use warnings;
use threads;
use threads::shared;
use Win32::API;
use IO::Scalar;
our $VERSION = '0.01';

sub STD_INPUT_HANDLE      { 0xfffffff6 }
sub FILE_TYPE_CHAR        { 0x0002 }
sub FILE_TYPE_PIPE        { 0x0003 }
sub ENABLE_PROCESS_INPUT  { 0x0001 }
sub ENABLE_LINE_INPUT     { 0x0002 }
sub ENABLE_ECHO_INPUT     { 0x0004 }

my $GetStdHandle = Win32::API->new('kernel32.dll',
  'GetStdHandle',
  'N',
  'N',
) or die ": $^E";
my $GetFileType = Win32::API->new('kernel32.dll',
  'GetFileType',
  'N',
  'N',
) or die ": $^E";
my $_kbhit = Win32::API->new('msvcrt.dll',
  '_kbhit',
  '',
  'I',
) or die ": $^E";
my $ReadConsole = Win32::API->new('kernel32.dll',
  'ReadConsoleA',
  'NPNPP',
  'N',
) or die ": $^E";
my $GetConsoleMode = Win32::API->new('kernel32.dll',
  'GetConsoleMode',
  'NP',
  'I',
) or die ": $^E";
my $SetConsoleMode = Win32::API->new('kernel32.dll',
  'SetConsoleMode',
  'NN',
  'I',
) or die ": $^E";

my $inputs = &share([]);
tie *STDIN, 'Win32::Console::GetC::Tied', $inputs;

my $handle = $GetStdHandle->Call(STD_INPUT_HANDLE);
if ($GetFileType->Call($handle) eq FILE_TYPE_CHAR) {
  my $mode = 0;
  $GetConsoleMode->Call($handle, \$mode);
  $SetConsoleMode->Call( $handle,
    $mode &
    ~ENABLE_LINE_INPUT &
    ~ENABLE_ECHO_INPUT |
     ENABLE_PROCESS_INPUT );
  async {
    while (1) {
      if ($_kbhit->Call()) {
        my ($buf, $num) = (' ', 0);
        if ($ReadConsole->Call($handle, $buf, 1, \$num, 0)) {
          push @$inputs, $buf;
        }
      }
    }
  }->detach;
}

package Win32::Console::GetC::Tied;

sub TIEHANDLE {
  my ($class, $ref) = @_;
  bless { ref => $ref }, $class;
}

sub GETC {
  my $self = shift;
  shift @{$self->{ref}};
}

1;

__END__

=head1 NAME

Win32::Console::GetC - fixup getc() for windows.

=head1 SYNOPSIS

  use Win32::Console::GetC;

=head1 DESCRIPTION

Win32::Console::GetC fixup behavior of getc() for windows.

=head1 AUTHOR

mattn E<lt>mattn.jp@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
