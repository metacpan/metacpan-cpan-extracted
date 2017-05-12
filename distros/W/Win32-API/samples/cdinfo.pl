#perl -w
use strict;
use Win32::API;

Win32::API->Import("kernel32", "UINT GetWindowsDirectory(LPTSTR lpBuffer, UINT uSize)",)
    or die "Can't import the GetWindowsDirectory API:\n$!";

Win32::API::Type->typedef(MCIERROR => 'DWORD');

Win32::API->Import(
    "winmm",
    q(
    	MCIERROR mciSendString(
    		LPCTSTR lpszCommand, 
    		LPTSTR lpszReturnString,
    		UINT cchReturn,
    		HANDLE hwndCallback
    	)
    )
) or die "Can't import the mciSendString API:\n$!";

doMM("close cdaudio");
doMM("open cdaudio shareable");

if (doMM("status cdaudio media present") eq "true") {

    my $cdi = doMM("info cdaudio identity");
    printf("CD identifier:    %X\n", $cdi);

    my ($artist, $title, %track) = GetCDinfo($cdi);

    print "Artist:           $artist\n" if $artist;
    print "Title:            $title\n"  if $title;

    my $not = doMM("status cdaudio number of tracks");
    printf("Number of tracks: %d\n", $not);

    my $i;
    my $tt;
    for $i (1 .. $not) {
        printf("Track %d: ", $i);
        $tt = doMM("status cdaudio type track $i");
        if ($tt eq "audio") {
            printf("(%s) ", $track{$i - 1}) if exists($track{$i - 1});
            doMM("set cdaudio time format msf");
            printf("%s\n", doMM("status cdaudio length track $i"));
        }
        else {
            printf("(data) ");
            doMM("set cdaudio time format milliseconds");
            printf("%.02f Mb\n",
                doMM("status cdaudio length track $i") * (150 * 1024 / 1000) / 1024**2);
        }
    }
}
else {
    print "No disc loaded.\n";
}
doMM("close cdaudio");

sub doMM {
    my ($cmd) = @_;
    my $ret = "\0" x 1025;
    my $rc = mciSendString($cmd, $ret, 1024, 0);
    if ($rc == 0) {
        $ret =~ s/\0*$//;
        return $ret;
    }
    else {
        return "error '$cmd': $rc";
    }
}

sub GetCDinfo {
    my ($cdi) = @_;
    my $xcdi = sprintf("%X", $cdi);
    my $artist;
    my $title;
    my %track;
    my $windir = "\0" x 1025;
    if (GetWindowsDirectory($windir, 1024)) {
        $windir =~ s/\0*$//;
        open(INI, "<$windir\\cdplayer.ini");
        my $insec = 0;
        while (<INI>) {
            if (/\[$xcdi\]/) {
                $insec = 1;
            }
            else {
                if ($insec) {
                    if (/^artist=(.*)$/) {
                        $artist = $1;
                    }
                    elsif (/^title=(.*)$/) {
                        $title = $1;
                    }
                    elsif (/^(\d+)=(.*)$/) {
                        $track{$1} = $2;
                    }
                    elsif (/^\[/) {
                        $insec = 0;
                    }
                }
            }
        }
        close(INI);
        return ($artist, $title, %track);
    }
    else {
        return undef;
    }
}
