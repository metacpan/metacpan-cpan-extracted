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
$MSWin32_MBCS = 0; # ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

open FILE,">6012.0B.A";          print FILE '';                          close FILE;
open FILE,">6012.1B.binary.A";   print FILE "\x00";                      close FILE;
open FILE,">6012.1B.text.A";     print FILE "A";                         close FILE;
open FILE,">6012.512B.binary.A"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
open FILE,">6012.512B.text.A";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
if ($MSWin32_MBCS) {
    mb::eval <<'END';
        open FILE,">6012.0B.ソ";          print FILE '';                          close FILE;
        open FILE,">6012.1B.binary.ソ";   print FILE "\x00";                      close FILE;
        open FILE,">6012.1B.text.ソ";     print FILE "A";                         close FILE;
        open FILE,">6012.512B.binary.ソ"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
        open FILE,">6012.512B.text.ソ";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
END
}

END {
    mb::eval sprintf <<'END', $MSWin32_MBCS;
        close FH1;
        close FH2;
        unlink "6012.0B.A";
        unlink "6012.1B.binary.A";
        unlink "6012.1B.text.A";
        unlink "6012.512B.binary.A";
        unlink "6012.512B.text.A";
        if (%s) {
            unlink "6012.0B.ソ";
            unlink "6012.1B.binary.ソ";
            unlink "6012.1B.text.ソ";
            unlink "6012.512B.binary.ソ";
            unlink "6012.512B.text.ソ";
        }
END
}

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AUse of uninitialized value in numeric eq \(==\) at / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -s "6012.NOTEXIST.A"    }) xor mb::eval(q{ -s "6012.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.777.A"         }) ==  mb::eval(q{ -s "6012.777.ソ"         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.000.A"         }) ==  mb::eval(q{ -s "6012.000.ソ"         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.0B.A"          }) ==  mb::eval(q{ -s "6012.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.1B.binary.A"   }) ==  mb::eval(q{ -s "6012.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.1B.text.A"     }) ==  mb::eval(q{ -s "6012.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.512B.binary.A" }) ==  mb::eval(q{ -s "6012.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.512B.text.A"   }) ==  mb::eval(q{ -s "6012.512B.text.ソ"   }) },
    sub {1},
    sub {1},
# 11
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-s "6012.NOTEXIST.A"   ) xor (-s "6012.NOTEXIST.ソ"   ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.777.A"        ) ==  (-s "6012.777.ソ"        ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.000.A"        ) ==  (-s "6012.000.ソ"        ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.0B.A"         ) ==  (-s "6012.0B.ソ"         ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.1B.binary.A"  ) ==  (-s "6012.1B.binary.ソ"  ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.1B.text.A"    ) ==  (-s "6012.1B.text.ソ"    ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.512B.binary.A") ==  (-s "6012.512B.binary.ソ") }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.512B.text.A"  ) ==  (-s "6012.512B.text.ソ"  ) }) },
    sub {1},
    sub {1},
# 21
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6012.NOTEXIST.A"   ); my $r = -s FH1; close FH1;    $r }) xor mb::eval(q{ -s "6012.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6012.0B.A"         ); my $r = -s FH1; close FH1;    $r }) ==  mb::eval(q{ -s "6012.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6012.1B.binary.A"  ); my $r = -s FH1; close FH1;    $r }) ==  mb::eval(q{ -s "6012.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6012.1B.text.A"    ); my $r = -s FH1; close FH1;    $r }) ==  mb::eval(q{ -s "6012.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6012.512B.binary.A"); my $r = -s FH1; close FH1;    $r }) ==  mb::eval(q{ -s "6012.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ open(FH1,"6012.512B.text.A"  ); my $r = -s FH1; close FH1;    $r }) ==  mb::eval(q{ -s "6012.512B.text.ソ"   }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -s "6012.NOTEXIST.A"    }) xor mb::eval(q{ open(FH2,"6012.NOTEXIST.ソ"   ); -s FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.0B.A"          }) ==  mb::eval(q{ open(FH2,"6012.0B.ソ"         ); -s FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.1B.binary.A"   }) ==  mb::eval(q{ open(FH2,"6012.1B.binary.ソ"  ); -s FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.1B.text.A"     }) ==  mb::eval(q{ open(FH2,"6012.1B.text.ソ"    ); -s FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.512B.binary.A" }) ==  mb::eval(q{ open(FH2,"6012.512B.binary.ソ"); -s FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     CORE::eval(q{ -s "6012.512B.text.A"   }) ==  mb::eval(q{ open(FH2,"6012.512B.text.ソ"  ); -s FH2 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6012.NOTEXIST.A"   ); open(FH2,"6012.NOTEXIST.ソ"   ); (-s FH1) xor (-s FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6012.0B.A"         ); open(FH2,"6012.0B.ソ"         ); (-s FH1) ==  (-s FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6012.1B.binary.A"  ); open(FH2,"6012.1B.binary.ソ"  ); (-s FH1) ==  (-s FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6012.1B.text.A"    ); open(FH2,"6012.1B.text.ソ"    ); (-s FH1) ==  (-s FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6012.512B.binary.A"); open(FH2,"6012.512B.binary.ソ"); (-s FH1) ==  (-s FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ open(FH1,"6012.512B.text.A"  ); open(FH2,"6012.512B.text.ソ"  ); (-s FH1) ==  (-s FH2) }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { not CORE::eval(q{ (-s "6012.NOTEXIST.A"   ) xor (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.777.A"        ) ==  (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.000.A"        ) ==  (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.0B.A"         ) ==  (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.1B.binary.A"  ) ==  (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.1B.text.A"    ) ==  (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.512B.binary.A") ==  (-s _) }) },
    sub {     CORE::eval(q{ (-s "6012.512B.text.A"  ) ==  (-s _) }) },
    sub {1},
    sub {1},
# 61
    sub { not mb::eval(q{ (-s "6012.NOTEXIST.A"   ) xor (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.777.A"        ) ==  (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.000.A"        ) ==  (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.0B.A"         ) ==  (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.1B.binary.A"  ) ==  (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.1B.text.A"    ) ==  (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.512B.binary.A") ==  (-s _) }) },
    sub {     mb::eval(q{ (-s "6012.512B.text.A"  ) ==  (-s _) }) },
    sub {1},
    sub {1},
# 71
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-s "6012.NOTEXIST.ソ"   ) xor (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.777.ソ"        ) ==  (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.000.ソ"        ) ==  (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.0B.ソ"         ) ==  (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.1B.binary.ソ"  ) ==  (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.1B.text.ソ"    ) ==  (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.512B.binary.ソ") ==  (-s _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ (-s "6012.512B.text.ソ"  ) ==  (-s _) }) },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
