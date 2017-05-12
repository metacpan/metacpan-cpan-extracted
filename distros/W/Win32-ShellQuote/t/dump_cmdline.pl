use strict;
use warnings;
use Win32::API;

BEGIN {
  my $gcl = Win32::API->new('kernel32', 'GetCommandLine', '', 'P');
  sub GetCommandLine {
    my $string = pack 'a1024', $gcl->Call;
    $string =~ s/\0*$//;
    return $string;
  }
}

my $cmdline = GetCommandLine();
$cmdline =~ s/.* -- //;
print $cmdline;
