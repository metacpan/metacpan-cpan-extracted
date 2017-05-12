#perl -w
use strict;

use Win32::API;

my $mciSendString = new Win32::API("winmm", "mciSendString", ['P', 'P', 'N', 'N'], 'N')
    or die "Can't import the mciSendString API:\n$!";

doMM("close cdaudio");
doMM("open cdaudio shareable");
doMM("set cdaudio door open");
doMM("close cdaudio");

sub doMM {
    my ($cmd) = @_;
    my $ret = "\0" x 1025;
    my $rc = $mciSendString->Call($cmd, $ret, 1024, 0);
    if ($rc == 0) {
        $ret =~ s/\0*$//;
        return $ret;
    }
    else {
        return "error '$cmd': $rc";
    }
}
