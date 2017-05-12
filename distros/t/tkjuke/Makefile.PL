our $VERSION = '2.2.1';

use Tk::MMutil;

use strict;

our (
     $PERL,
     $PREFIX,

     $JUKE_ROOT,
     $JUKE_EXE,

     $CHANGER,
     $EEPOS_OPEN,
     $EEPOS_SHUT,
     $EJECT_BEFORE_UNLOAD,
     $JUKE,
     $LOADERINFO,
     $MT,
     $MTX,
     $NRTAPE,
     $TAPE,
     $WAIT_TAPE_READY,
);

$PERL       = $^X;
$PREFIX     = '/opt'       if -d '/opt';
$PREFIX     = '/usr/local' if -d '/usr/local';
$PREFIX   ||= '/usr/local';

$JUKE_ROOT  = "$PREFIX/tkjuke/$VERSION";
$JUKE_EXE   = "$JUKE_ROOT/juke";

# juke.config variables.

$CHANGER             = '/dev/sch0';
$EEPOS_OPEN          = 1;
$EEPOS_SHUT          = 2;
$EJECT_BEFORE_UNLOAD = 'rewind';
$JUKE                = $JUKE_EXE;
$LOADERINFO          = '/usr/local/sbin/loaderinfo';
$MT                  = '/bin/mt';
$MTX                 = '/usr/local/sbin/mtx';
$NRTAPE              = '/dev/nst0';
$TAPE                = '/dev/st0';
$WAIT_TAPE_READY     = "$JUKE_ROOT/wait-tape-ready";

sub MY::post_initialize {

    my ($self) = @_;

    # Create juke.config

    &configure;

    return '';

}

sub MY::install {

    <<"END";
install::
\t-mkdir $PREFIX/tkjuke  2> /dev/null
\tcp -Rp blib/$VERSION $PREFIX/tkjuke/
END

}

Tk::MMutil::TkExtMakefile(
    NAME          => "tkjuke",
    DISTNAME      => "tkjuke",
    VERSION_FROM  => "Makefile.PL",
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Jukebox interface for mtx',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);

sub configure {

    # Define PERL and PREFIX.

    print "\nFirst, let's collect some general information about this install.\n";

    $PERL = get($PERL, << "END");
Please enter the pathname of Perl
END

    $PREFIX = get($PREFIX, << "END");
Please enter the prefix pathname for tkjuke and it's support
files. If you choose the default value '$PREFIX', then
the directory '$PREFIX/tkjuke/$VERSION' is created
END

    # Define all juke.config variables.

    $JUKE_ROOT   = "$PREFIX/tkjuke/$VERSION";
    $JUKE_EXE    = "$JUKE_ROOT/juke";
    $JUKE        = $JUKE_EXE;

    print "\nNow I need mtx, jukebox and tape device configuration data.\n";

    $CHANGER = get($CHANGER, << "END");
Please enter the device name of the changer
END

    $EEPOS_OPEN = get($EEPOS_OPEN, << "END");
Please enter the hardware code to open the mail slot
END

    $EEPOS_SHUT = get($EEPOS_SHUT, << "END");
Please enter the hardware code to close the mail slot
END

    $EJECT_BEFORE_UNLOAD = get($EJECT_BEFORE_UNLOAD, <<"END");
Some jukeboxes require that media be ejected from the
DTE before it can be physically unloaded and returned
to an SE. If this is the case then enter the "mt"
command to eject the media.  Frequently, the command
is "offline", but other possibilities are "rewoffl",
"unload" or "eject". Read your "mt" man page for the
proper value. A vaue of zero assumes that an eject is
not required before unloading a DTE. As a sanity check
the default value is "rewind" - this prevents media
from inadvertently being ejected from a drive if the
drive is busy, perhaps doing a backup or restore.
END

    $LOADERINFO = get($LOADERINFO, << "END");
Please enter the pathname of the 'loaderinfo' command
END

    $MT = get($MT, << "END");
Please enter the pathname of the 'mt' command
END

    $MTX = get($MTX, << "END");
Please enter the pathname of the 'mtx' command
END

    $NRTAPE = get($NRTAPE, << "END");
Please enter the device name of the no rewind tape(s). If the jukebox
has more than 1 drive, enter all the drive names separated by
spaces
END

    $TAPE = get($TAPE, << "END");
Please enter the device name of the rewind tape(s). If the jukebox
has more than 1 drive, enter all the drive names separated by
spaces.
END

    print <<"END";

perl                = $PERL
prefix              = $PREFIX
changer             = $CHANGER
eepos_open          = $EEPOS_OPEN
eepos_shut          = $EEPOS_SHUT
eject_before_unload = $EJECT_BEFORE_UNLOAD
juke                = $JUKE
loaderinfo          = $LOADERINFO
mt                  = $MT
mtx                 = $MTX
nrtape              = $NRTAPE
tape                = $TAPE
version             = $VERSION
wait-tape-ready     = $WAIT_TAPE_READY
END

    print "\nWriting juke.config.\n";
    open J, ">juke.config" or die "Cannot open juke.config: $!";
    print J <<"END";
export CHANGER=$CHANGER
export EEPOS_OPEN=$EEPOS_OPEN
export EEPOS_SHUT=$EEPOS_SHUT
export EJECT_BEFORE_UNLOAD=$EJECT_BEFORE_UNLOAD
export JUKE=$JUKE
export LOADERINFO=$LOADERINFO
export MT=$MT
export MTX=$MTX
export NRTAPE=$NRTAPE
export TAPE=$TAPE
export VERSION=$VERSION
export WAIT_TAPE_READY=$WAIT_TAPE_READY
END
    close J;

    print "\nPerforming string substitutions ...";
    my $blib_root = "./blib/$VERSION";
    system <<"END";
mkdir ./blib  2> /dev/null
mkdir $blib_root      2> /dev/null
mkdir $blib_root/Tk   2> /dev/null
$PERL -ne "s+JUKE_ROOT+$JUKE_ROOT+g; s+PERL+$PERL+; print"                           juke > $blib_root/juke
$PERL -ne "s+JUKE_ROOT+$JUKE_ROOT+g; s+PERL+$PERL+; print"                wait-tape-ready > $blib_root/wait-tape-ready
#$PERL -ne "s+JUKE_ROOT+$JUKE_ROOT+g; s+PERL+$PERL+; print"                       mtxatape > $blib_root/juke
$PERL -ne "s+JUKE_ROOT+$JUKE_ROOT+g; s+PERL+$PERL+; s+JUKE_EXE+$JUKE_EXE+g; print" tkjuke > $blib_root/tkjuke
$PERL -ne "s+JUKE_ROOT+$JUKE_ROOT+g; print"                                    Jukebox.pm > $blib_root/Jukebox.pm
cp -Rp juke.config*   $blib_root/
cp Tk/JukeboxSlot.pm  $blib_root/Tk/
cp Tk/JukeboxDrive.pm  $blib_root/Tk/
chmod -R 744 $blib_root
chmod    755 $blib_root/juke
#chmod    755 $blib_root/mtxatape
chmod    755 $blib_root/tkjuke
END

    print " (system error=$?) " if $?;
    print " done.\n";

    print "\nCreating a sample tkjuke.config file (please hand edit).\n";
    system <<"END";
cp tkjuke.config.samples/tkjuke.config .
cp tkjuke.config $blib_root/
END
    warn "cp failed: $?" if $?;

    print "\nConfiguration is complete.\n\n";

} # end configure

sub get {
    my ($def, $prompt) = @_;
    chomp $prompt;
    print "\n$prompt [$def]: ";
    my $ans = <STDIN>;
    chomp $ans;
    return $ans eq '' ? $def : $ans;
}
