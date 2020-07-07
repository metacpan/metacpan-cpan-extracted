# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

mb::eval <<'END';
    mkdir "6014.777.A",0777;
    mkdir "6014.000.A",0000;
    open FILE,">6014.0B.A";          print FILE '';                          close FILE;
    open FILE,">6014.1B.binary.A";   print FILE "\x00";                      close FILE;
    open FILE,">6014.1B.text.A";     print FILE "A";                         close FILE;
    open FILE,">6014.512B.binary.A"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
    open FILE,">6014.512B.text.A";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
    chmod 0555, "6014.777.A";
    chmod 0555, "6014.000.A";
    chmod 0555, "6014.0B.A";
    chmod 0555, "6014.1B.binary.A";
    chmod 0555, "6014.1B.text.A";
    chmod 0555, "6014.512B.binary.A";
    chmod 0555, "6014.512B.text.A";
    if ($^O =~ /MSWin32/) {
        mkdir "6014.777.ソ",0777;
        mkdir "6014.000.ソ",0000;
        open FILE,">6014.0B.ソ";          print FILE '';                          close FILE;
        open FILE,">6014.1B.binary.ソ";   print FILE "\x00";                      close FILE;
        open FILE,">6014.1B.text.ソ";     print FILE "A";                         close FILE;
        open FILE,">6014.512B.binary.ソ"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
        open FILE,">6014.512B.text.ソ";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
        chmod 0555, "6014.777.ソ";
        chmod 0555, "6014.000.ソ";
        chmod 0555, "6014.0B.ソ";
        chmod 0555, "6014.1B.binary.ソ";
        chmod 0555, "6014.1B.text.ソ";
        chmod 0555, "6014.512B.binary.ソ";
        chmod 0555, "6014.512B.text.ソ";
    }
END

END {
    mb::eval <<'END';
        close FH1;
        close FH2;
        chmod 0777, "6014.777.A";
        chmod 0777, "6014.000.A";
        chmod 0777, "6014.0B.A";
        chmod 0777, "6014.1B.binary.A";
        chmod 0777, "6014.1B.text.A";
        chmod 0777, "6014.512B.binary.A";
        chmod 0777, "6014.512B.text.A";
        unlink "6014.0B.A";
        unlink "6014.1B.binary.A";
        unlink "6014.1B.text.A";
        unlink "6014.512B.binary.A";
        unlink "6014.512B.text.A";
        if ($^O =~ /MSWin32/) {
            closedir DH1;
            closedir DH2;
            chmod 0777, "6014.777.ソ";
            chmod 0777, "6014.000.ソ";
            chmod 0777, "6014.0B.ソ";
            chmod 0777, "6014.1B.binary.ソ";
            chmod 0777, "6014.1B.text.ソ";
            chmod 0777, "6014.512B.binary.ソ";
            chmod 0777, "6014.512B.text.ソ";
            rmdir "6014.777.ソ";
            rmdir "6014.000.ソ";
            unlink "6014.0B.ソ";
            unlink "6014.1B.binary.ソ";
            unlink "6014.1B.text.ソ";
            unlink "6014.512B.binary.ソ";
            unlink "6014.512B.text.ソ";
        }
        rmdir "6014.777.A";
        rmdir "6014.000.A";
END
}

@test = (
# 1
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.NOTEXIST.A"    }) xor mb::eval(q{ -w "6014.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.777.A"         }) xor mb::eval(q{ -w "6014.777.ソ"         }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.000.A"         }) xor mb::eval(q{ -w "6014.000.ソ"         }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.0B.A"          }) xor mb::eval(q{ -w "6014.0B.ソ"          }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.1B.binary.A"   }) xor mb::eval(q{ -w "6014.1B.binary.ソ"   }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.1B.text.A"     }) xor mb::eval(q{ -w "6014.1B.text.ソ"     }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.512B.binary.A" }) xor mb::eval(q{ -w "6014.512B.binary.ソ" }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.512B.text.A"   }) xor mb::eval(q{ -w "6014.512B.text.ソ"   }) },
    sub {1},
    sub {1},
# 11
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.NOTEXIST.A"   ) xor (-w "6014.NOTEXIST.ソ"   ) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.777.A"        ) xor (-w "6014.777.ソ"        ) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.000.A"        ) xor (-w "6014.000.ソ"        ) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.0B.A"         ) xor (-w "6014.0B.ソ"         ) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.1B.binary.A"  ) xor (-w "6014.1B.binary.ソ"  ) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.1B.text.A"    ) xor (-w "6014.1B.text.ソ"    ) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.512B.binary.A") xor (-w "6014.512B.binary.ソ") }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.512B.text.A"  ) xor (-w "6014.512B.text.ソ"  ) }) },
    sub {1},
    sub {1},
# 21
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ open(FH1,"6014.NOTEXIST.A"   ); my $r = -w FH1; close FH1;    $r }) xor mb::eval(q{ -w "6014.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ opendir(DH1,"6014.777.A"     ); my $r = eval q{ -w DH1 }; closedir DH1; $r                                   }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ opendir(DH1,"6014.000.A"     ); my $r = eval q{ -w DH1 }; closedir DH1; $r                                   }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ open(FH1,"6014.0B.A"         ); my $r = -w FH1; close FH1;    $r }) xor mb::eval(q{ -w "6014.0B.ソ"          }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ open(FH1,"6014.1B.binary.A"  ); my $r = -w FH1; close FH1;    $r }) xor mb::eval(q{ -w "6014.1B.binary.ソ"   }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ open(FH1,"6014.1B.text.A"    ); my $r = -w FH1; close FH1;    $r }) xor mb::eval(q{ -w "6014.1B.text.ソ"     }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ open(FH1,"6014.512B.binary.A"); my $r = -w FH1; close FH1;    $r }) xor mb::eval(q{ -w "6014.512B.binary.ソ" }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ open(FH1,"6014.512B.text.A"  ); my $r = -w FH1; close FH1;    $r }) xor mb::eval(q{ -w "6014.512B.text.ソ"   }) },
    sub {1},
    sub {1},
# 31
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.NOTEXIST.A"    }) xor mb::eval(q{ open(FH2,"6014.NOTEXIST.ソ"   ); -w FH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not                                              mb::eval(q{ opendir(DH2,"6014.777.ソ"     ); -w DH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not                                              mb::eval(q{ opendir(DH2,"6014.000.ソ"     ); -w DH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.0B.A"          }) xor mb::eval(q{ open(FH2,"6014.0B.ソ"         ); -w FH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.1B.binary.A"   }) xor mb::eval(q{ open(FH2,"6014.1B.binary.ソ"  ); -w FH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.1B.text.A"     }) xor mb::eval(q{ open(FH2,"6014.1B.text.ソ"    ); -w FH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.512B.binary.A" }) xor mb::eval(q{ open(FH2,"6014.512B.binary.ソ"); -w FH2 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not CORE::eval(q{ -w "6014.512B.text.A"   }) xor mb::eval(q{ open(FH2,"6014.512B.text.ソ"  ); -w FH2 }) },
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ open(FH1,"6014.NOTEXIST.A"   ); open(FH2,"6014.NOTEXIST.ソ"   ); (-w FH1) xor (-w FH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ opendir(DH1,"6014.777.A"     ); opendir(DH2,"6014.777.ソ"     ); (-w DH1) xor (-w DH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ opendir(DH1,"6014.000.A"     ); opendir(DH2,"6014.000.ソ"     ); (-w DH1) xor (-w DH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ open(FH1,"6014.0B.A"         ); open(FH2,"6014.0B.ソ"         ); (-w FH1) xor (-w FH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ open(FH1,"6014.1B.binary.A"  ); open(FH2,"6014.1B.binary.ソ"  ); (-w FH1) xor (-w FH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ open(FH1,"6014.1B.text.A"    ); open(FH2,"6014.1B.text.ソ"    ); (-w FH1) xor (-w FH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ open(FH1,"6014.512B.binary.A"); open(FH2,"6014.512B.binary.ソ"); (-w FH1) xor (-w FH2) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ open(FH1,"6014.512B.text.A"  ); open(FH2,"6014.512B.text.ソ"  ); (-w FH1) xor (-w FH2) }) },
    sub {1},
    sub {1},
# 51
    sub { not CORE::eval(q{ (-w "6014.NOTEXIST.A"   ) xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.777.A"        ) xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.000.A"        ) xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.0B.A"         ) xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.1B.binary.A"  ) xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.1B.text.A"    ) xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.512B.binary.A") xor (-w _) }) },
    sub { not CORE::eval(q{ (-w "6014.512B.text.A"  ) xor (-w _) }) },
    sub {1},
    sub {1},
# 61
    sub { not mb::eval(q{ (-w "6014.NOTEXIST.A"   ) xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.777.A"        ) xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.000.A"        ) xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.0B.A"         ) xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.1B.binary.A"  ) xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.1B.text.A"    ) xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.512B.binary.A") xor (-w _) }) },
    sub { not mb::eval(q{ (-w "6014.512B.text.A"  ) xor (-w _) }) },
    sub {1},
    sub {1},
# 71
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.NOTEXIST.ソ"   ) xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.777.ソ"        ) xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.000.ソ"        ) xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.0B.ソ"         ) xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.1B.binary.ソ"  ) xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.1B.text.ソ"    ) xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.512B.binary.ソ") xor (-w _) }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; not mb::eval(q{ (-w "6014.512B.text.ソ"  ) xor (-w _) }) },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
