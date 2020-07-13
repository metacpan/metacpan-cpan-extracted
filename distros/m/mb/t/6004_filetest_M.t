# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AUse of uninitialized value in multiplication \(\*\) at / ? return :
        warn $_[0];
    };
}

mkdir "6004.777.A",0777;
mkdir "6004.000.A",0000;
open FILE,">6004.0B.A";          print FILE '';                          close FILE;
open FILE,">6004.1B.binary.A";   print FILE "\x00";                      close FILE;
open FILE,">6004.1B.text.A";     print FILE "A";                         close FILE;
open FILE,">6004.512B.binary.A"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
open FILE,">6004.512B.text.A";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
if ($MSWin32_MBCS) {
    mb::eval <<'END';
        mkdir "6004.777.ソ",0777;
        mkdir "6004.000.ソ",0000;
        open FILE,">6004.0B.ソ";          print FILE '';                          close FILE;
        open FILE,">6004.1B.binary.ソ";   print FILE "\x00";                      close FILE;
        open FILE,">6004.1B.text.ソ";     print FILE "A";                         close FILE;
        open FILE,">6004.512B.binary.ソ"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
        open FILE,">6004.512B.text.ソ";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
END
}

END {
    mb::eval sprintf <<'END', $MSWin32_MBCS;
        close FH1;
        close FH2;
        unlink "6004.0B.A";
        unlink "6004.1B.binary.A";
        unlink "6004.1B.text.A";
        unlink "6004.512B.binary.A";
        unlink "6004.512B.text.A";
        if (%s) {
            closedir DH1;
            closedir DH2;
            rmdir "6004.777.ソ";
            chmod 0777, "6004.000.ソ";
            rmdir "6004.000.ソ";
            unlink "6004.0B.ソ";
            unlink "6004.1B.binary.ソ";
            unlink "6004.1B.text.ソ";
            unlink "6004.512B.binary.ソ";
            unlink "6004.512B.text.ソ";
        }
        rmdir "6004.777.A";
        rmdir "6004.000.A";
END
}

@test = (
# 1
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ int 1000 * -M "6004.NOTEXIST.A"    }) xor mb::eval(q{ int 1000 * -M "6004.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.777.A"         }) ==  mb::eval(q{ int 1000 * -M "6004.777.ソ"         }) },
    sub {1}, # sub {     CORE::eval(q{ int 1000 * -M "6004.000.A"         }) ==  mb::eval(q{ int 1000 * -M "6004.000.ソ"         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.0B.A"          }) ==  mb::eval(q{ int 1000 * -M "6004.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.1B.binary.A"   }) ==  mb::eval(q{ int 1000 * -M "6004.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.1B.text.A"     }) ==  mb::eval(q{ int 1000 * -M "6004.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.512B.binary.A" }) ==  mb::eval(q{ int 1000 * -M "6004.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.512B.text.A"   }) ==  mb::eval(q{ int 1000 * -M "6004.512B.text.ソ"   }) },
    sub {1},
    sub {1},
# 11
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (int 1000 * -M "6004.NOTEXIST.A"   ) xor (int 1000 * -M "6004.NOTEXIST.ソ"   ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.777.A"        ) ==  (int 1000 * -M "6004.777.ソ"        ) }) },
    sub {1}, # sub {     mb::eval(q{ (int 1000 * -M "6004.000.A"        ) ==  (int 1000 * -M "6004.000.ソ"        ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.0B.A"         ) ==  (int 1000 * -M "6004.0B.ソ"         ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.1B.binary.A"  ) ==  (int 1000 * -M "6004.1B.binary.ソ"  ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.1B.text.A"    ) ==  (int 1000 * -M "6004.1B.text.ソ"    ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.512B.binary.A") ==  (int 1000 * -M "6004.512B.binary.ソ") }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.512B.text.A"  ) ==  (int 1000 * -M "6004.512B.text.ソ"  ) }) },
    sub {1},
    sub {1},
# 21
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6004.NOTEXIST.A"   ); my $r = int 1000 * -M FH1; close FH1;    $r }) xor mb::eval(q{ int 1000 * -M "6004.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ opendir(DH1,"6004.777.A"     ); my $r = eval q{ int 1000 * -M DH1 }; closedir DH1; $r                                              }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ opendir(DH1,"6004.000.A"     ); my $r = eval q{ int 1000 * -M DH1 }; closedir DH1; $r                                              }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6004.0B.A"         ); my $r = int 1000 * -M FH1; close FH1;    $r }) ==  mb::eval(q{ int 1000 * -M "6004.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6004.1B.binary.A"  ); my $r = int 1000 * -M FH1; close FH1;    $r }) ==  mb::eval(q{ int 1000 * -M "6004.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6004.1B.text.A"    ); my $r = int 1000 * -M FH1; close FH1;    $r }) ==  mb::eval(q{ int 1000 * -M "6004.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6004.512B.binary.A"); my $r = int 1000 * -M FH1; close FH1;    $r }) ==  mb::eval(q{ int 1000 * -M "6004.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6004.512B.text.A"  ); my $r = int 1000 * -M FH1; close FH1;    $r }) ==  mb::eval(q{ int 1000 * -M "6004.512B.text.ソ"   }) },
    sub {1},
    sub {1},
# 31
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ int 1000 * -M "6004.NOTEXIST.A"    }) xor mb::eval(q{ open(FH2,"6004.NOTEXIST.ソ"   ); int 1000 * -M FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not                                              mb::eval(q{ opendir(DH2,"6004.777.ソ"     ); int 1000 * -M DH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not                                              mb::eval(q{ opendir(DH2,"6004.000.ソ"     ); int 1000 * -M DH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.0B.A"          }) ==  mb::eval(q{ open(FH2,"6004.0B.ソ"         ); int 1000 * -M FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.1B.binary.A"   }) ==  mb::eval(q{ open(FH2,"6004.1B.binary.ソ"  ); int 1000 * -M FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.1B.text.A"     }) ==  mb::eval(q{ open(FH2,"6004.1B.text.ソ"    ); int 1000 * -M FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.512B.binary.A" }) ==  mb::eval(q{ open(FH2,"6004.512B.binary.ソ"); int 1000 * -M FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ int 1000 * -M "6004.512B.text.A"   }) ==  mb::eval(q{ open(FH2,"6004.512B.text.ソ"  ); int 1000 * -M FH2 }) },
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6004.NOTEXIST.A"   ); open(FH2,"6004.NOTEXIST.ソ"   ); (int 1000 * -M FH1) xor (int 1000 * -M FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ opendir(DH1,"6004.777.A"     ); opendir(DH2,"6004.777.ソ"     ); (int 1000 * -M DH1) xor (int 1000 * -M DH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ opendir(DH1,"6004.000.A"     ); opendir(DH2,"6004.000.ソ"     ); (int 1000 * -M DH1) xor (int 1000 * -M DH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6004.0B.A"         ); open(FH2,"6004.0B.ソ"         ); (int 1000 * -M FH1) ==  (int 1000 * -M FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6004.1B.binary.A"  ); open(FH2,"6004.1B.binary.ソ"  ); (int 1000 * -M FH1) ==  (int 1000 * -M FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6004.1B.text.A"    ); open(FH2,"6004.1B.text.ソ"    ); (int 1000 * -M FH1) ==  (int 1000 * -M FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6004.512B.binary.A"); open(FH2,"6004.512B.binary.ソ"); (int 1000 * -M FH1) ==  (int 1000 * -M FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6004.512B.text.A"  ); open(FH2,"6004.512B.text.ソ"  ); (int 1000 * -M FH1) ==  (int 1000 * -M FH2) }) },
    sub {1},
    sub {1},
# 51
    sub { not CORE::eval(q{ (int 1000 * -M "6004.NOTEXIST.A"   ) xor (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.777.A"        ) ==  (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.000.A"        ) ==  (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.0B.A"         ) ==  (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.1B.binary.A"  ) ==  (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.1B.text.A"    ) ==  (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.512B.binary.A") ==  (int 1000 * -M _) }) },
    sub {     CORE::eval(q{ (int 1000 * -M "6004.512B.text.A"  ) ==  (int 1000 * -M _) }) },
    sub {1},
    sub {1},
# 61
    sub { not mb::eval(q{ (int 1000 * -M "6004.NOTEXIST.A"   ) xor (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.777.A"        ) ==  (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.000.A"        ) ==  (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.0B.A"         ) ==  (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.1B.binary.A"  ) ==  (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.1B.text.A"    ) ==  (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.512B.binary.A") ==  (int 1000 * -M _) }) },
    sub {     mb::eval(q{ (int 1000 * -M "6004.512B.text.A"  ) ==  (int 1000 * -M _) }) },
    sub {1},
    sub {1},
# 71
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (int 1000 * -M "6004.NOTEXIST.ソ"   ) xor (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.777.ソ"        ) ==  (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.000.ソ"        ) ==  (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.0B.ソ"         ) ==  (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.1B.binary.ソ"  ) ==  (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.1B.text.ソ"    ) ==  (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.512B.binary.ソ") ==  (int 1000 * -M _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (int 1000 * -M "6004.512B.text.ソ"  ) ==  (int 1000 * -M _) }) },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
