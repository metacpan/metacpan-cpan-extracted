use strict;

if ( $^O =~ /cygwin|MSWin32/ ) {
    print 'Checking Win32::File::VersionInfo works on this Win32 system: ';
    eval {
        require Win32::File::VersionInfo;
        Win32::File::VersionInfo->import(qw/GetFileVersionInfo/);

        my $windir = $ENV{WINDIR};
        my @foo    = (
            grep { -e $_ } "${windir}\\system32\\notepad.exe",
            "${windir}\\system32\\kernel32.dll",
            "${windir}\\system32\\msxbde40.dll",
            "${windir}\\system\\KEYBOARD.DRV",
            "${windir}\\system32\\winspool.drv",
            "${windir}\\system32\\vga.drv",
            "${windir}\\system32\\mouse.drv",
            "${windir}\\system32\\lanman.drv",
            "${windir}\\system32\\sound.drv",
            "${windir}\\system32\\comm.drv",
            "${windir}\\Fonts\\COURE.FON",
        );

        my @attrs = qw[ FileVersion ProductVersion Flags OS Type ];

        print "1..", ( scalar(@foo) * ( 1 + scalar @attrs ) ), "\n";
        my $n = 1;

        for my $file (@foo) {
            my $bar = GetFileVersionInfo($file);
            if ( ref $bar ) {
                print "ok $n\n";
                $n++;
                for my $attr (@attrs) {
                    if ( exists $bar->{$attr} and defined $bar->{$attr} ) {
                        print "ok $n\n";
                        $n++;
                    }
                    else {
                        print "not ok $n # file=$file attr=$attr\n";
                        $n++;
                    }
                }
            }
            else {
                print "not ok $n # file=$file \n";
                $n++;
                for my $attr (@attrs) {
                    print "not ok $n # file=$file attr=$attr\n";
                    $n++;
                }
            }
        }
    };
    if ($@) {
        die "not ok\n";
    }
    else {
        print "ok\n";
    }
}
else {
    print
        'Checking Win32::File::VersionInfo throws an exception on a non-Win32 system: ';
    eval { require Win32::File::VersionInfo; };
    if ($@) {
        print "ok\n";
    }
    else {
        die "not ok\n";
    }
}
