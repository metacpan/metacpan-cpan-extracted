use ExtUtils::MakeMaker;
use ExtUtils::Constant qw (WriteConstants);

# Makefile.PL for Win32::NetPacket
# v 0.2 (11/02/2006)
# -------------------------------------
# Set the path to the WPcap library :

my $WPCAP = 'C:\WpdPack';

# **************************************

unless ( -e $WPCAP . '\Lib\Packet.lib' ) {
  print << 'ERR';
Error:  WinPcap library not found.
Set the path to this library in Makefile.PL and run 'perl Makefile.PL' again.
ERR
  exit;
}

# patching socket.h
my $sockfile;
foreach (@INC) {    # looking for socket.h
  if ( -e $_ . '/CORE/sys/socket.h' ) {
    $sockfile = $_ . '/CORE/sys/socket.h';
    last;
  }
}
die "file \"socket.h\" not found" unless $sockfile;
open H, "< $sockfile" or die $!;
my $h;
{
  local $/;
  $h = <H>;
}
close H;

my $ifdef = <<'IFDEF';    # patch for socket.h
/* patch for WinPCap
   original file renamed 'socket.h.orig'
*/
#ifdef WINSOCK2_H_REQUESTED
#include <winsock2.h>
#else
#include <winsock.h>
#endif
/* end of patch */
IFDEF

if ( $h =~ /\#include <winsock2.h>/ ) {
  print "socket.h already patched...Ok\n";
}
else {
  if ( rename $sockfile, $sockfile . '.orig' ) {
    $h =~ s/#include <winsock.h>/$ifdef/;
    open H, "> $sockfile" or die $!;
    print H $h;
    close H;
    print "socket.h patched...Ok\n";
  }
  else {
    print "Unable to patch socket.h\n";
  }
}
# end patching

WriteMakefile(
  'NAME'         => 'Win32::NetPacket',
  'VERSION_FROM' => 'lib/Win32/NetPacket.pm',       # finds $VERSION
  'PREREQ_PM'    => {},                   # e.g., Module::Name => 1.1
  ( $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM => 'lib/Win32/NetPacket.pm',    # retrieve abstract from module
      AUTHOR => 'Jean-Louis Morel <jl_morel@bribes.org>'
      )
    : ()
  ),
  'LIBS'   => ["$WPCAP\\Lib\\Packet.lib"],    # e.g., '-lm'
  'DEFINE' => '',                             # e.g., '-DHAVE_SOMETHING'
  'INC'    => "-I$WPCAP\\Include",            # e.g., '-I/usr/include/other'
);

# extracting constants from NetPacket.pm
my $content;
open my $pmfile, "lib/Win32/NetPacket.pm" or die $!;
{
  local $/;
  $content = <$pmfile>;
}
close $pmfile;

my @cst;
foreach my $name (qw/ ndis oid mode /) {
  ($_) = $content =~ /^\s*'$name'\s*=>\s*\[\s*qw\(\s*([A-Z_0-9\s]+)/m;
  push @cst, split;
}

WriteConstants(
  NAME  => 'Win32::NetPacket',
  NAMES => [@cst],
);
