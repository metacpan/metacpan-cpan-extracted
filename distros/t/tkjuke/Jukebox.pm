$Tk::Jukebox::VERSION = '2.0';

package Jukebox;

# Jukebox and media definitions, dependant upon the master shell
# configuration file, 'juke.config'.  This ensures that declarations
# appear in only one file.  All configuration changes should be made
# to the shell file, and we'll inherit them here.

use Carp;
use Exporter;
use base qw/Exporter/;
@EXPORT = qw/%JUKE_CONFIG sys/;

our (%JUKE_CONFIG);

my (
    $changer, $eepos_open, $eepos_shut, $juke, $loaderinfo,
    $mt, $mtx, $nrtape, $tape, $version, $wait_tape_ready,
);

my $sconfig = 'JUKE_ROOT/juke.config';
if ( ! open S, $sconfig ) {
    $sconfig = 'juke.config';
    open S, $sconfig or die "Cannot open '$sconfig' for read: $!";
}
my (@setup) = <S>;
close S;

my $setup = join ' ', @setup;

($changer)              =  $setup =~ / CHANGER=(.*)/m;
($eepos_open)           =  $setup =~ / EEPOS_OPEN=(.*)/m;
($eepos_shut)           =  $setup =~ / EEPOS_SHUT=(.*)/m;
($eject_before_unload)  =  $setup =~ / EJECT_BEFORE_UNLOAD=(.*)/m;
($juke)                 =  $setup =~ / JUKE=(.*)/m;
($loaderinfo)           =  $setup =~ / LOADERINFO=(.*)/m;
($mt)                   =  $setup =~ / MT=(.*)/m;
($mtx)                  =  $setup =~ / MTX=(.*)/m;
($nrtape)               =  $setup =~ / NRTAPE=(.*)/m;
($tape)                 =  $setup =~ / TAPE=(.*)/m;
($version)              =  $setup =~ / VERSION=(.*)/m;
($wait_tape_ready)      =  $setup =~ / WAIT_TAPE_READY=(.*)/m;

%JUKE_CONFIG = (
    CHANGER             => $changer,
    EEPOS_OPEN          => $eepos_open,
    EEPOS_SHUT          => $eepos_shut,
    EJECT_BEFORE_UNLOAD => $eject_before_unload,
    JUKE                => $juke,
    LOADERINFO          => $loaderinfo,
    MT                  => $mt,
    MTX                 => $mtx,
    NRTAPE              => $nrtape,
    TAPE                => $tape,
    VERSION             => $version,
    WAIT_TAPE_READY     => $wait_tape_ready,
);

sub sys {

    # Execute a command.  If problems, die/warn as appropriate.

    my ($cmd, $warn) = @_;
    my (@out) = `$cmd`;
    return @out unless $?;
    my $err = "Failed : '$cmd' : " . ($? >> 8);
    $warn ? carp $err : croak $err;
    return @out;

} # end sys

1;
