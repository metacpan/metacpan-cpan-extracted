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

open FILE,">6001.0B.A";           print FILE '';                          close FILE;
open FILE,">6001.1B.binary.A";    print FILE "\x00";                      close FILE;
open FILE,">6001.1B.text.A";      print FILE "A";                         close FILE;
open FILE,">6001.512B.binary.A";  print FILE "\x00" x 52, "A" x (512-52); close FILE;
open FILE,">6001.512B.text.A";    print FILE "\x00" x 51, "A" x (512-51); close FILE;
if ($MSWin32_MBCS) {
    mb::eval <<'END';
        open FILE,">6001.0B.ソ";          print FILE '';                          close FILE;
        open FILE,">6001.1B.binary.ソ";   print FILE "\x00";                      close FILE;
        open FILE,">6001.1B.text.ソ";     print FILE "A";                         close FILE;
        open FILE,">6001.512B.binary.ソ"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
        open FILE,">6001.512B.text.ソ";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
END
}

END {
    mb::eval sprintf <<'END', $MSWin32_MBCS;
        close FH1;
        close FH2;
        unlink "6001.0B.A";
        unlink "6001.1B.binary.A";
        unlink "6001.1B.text.A";
        unlink "6001.512B.binary.A";
        unlink "6001.512B.text.A";
        if (%s) {
            unlink "6001.0B.ソ";
            unlink "6001.1B.binary.ソ";
            unlink "6001.1B.text.ソ";
            unlink "6001.512B.binary.ソ";
            unlink "6001.512B.text.ソ";
        }
END
}

@test = (
# 1
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.NOTEXIST.A"    }) xor mb::eval(q{ -B "6001.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.777.A"         }) xor mb::eval(q{ -B "6001.777.ソ"         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.000.A"         }) xor mb::eval(q{ -B "6001.000.ソ"         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.0B.A"          }) xor mb::eval(q{ -B "6001.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.1B.binary.A"   }) xor mb::eval(q{ -B "6001.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.1B.text.A"     }) xor mb::eval(q{ -B "6001.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.512B.binary.A" }) xor mb::eval(q{ -B "6001.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.512B.text.A"   }) xor mb::eval(q{ -B "6001.512B.text.ソ"   }) },
    sub {1},
    sub {1},
# 11
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.NOTEXIST.A"   ) xor (-B "6001.NOTEXIST.ソ"   ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.777.A"        ) xor (-B "6001.777.ソ"        ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.000.A"        ) xor (-B "6001.000.ソ"        ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.0B.A"         ) xor (-B "6001.0B.ソ"         ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.1B.binary.A"  ) xor (-B "6001.1B.binary.ソ"  ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.1B.text.A"    ) xor (-B "6001.1B.text.ソ"    ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.512B.binary.A") xor (-B "6001.512B.binary.ソ") }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.512B.text.A"  ) xor (-B "6001.512B.text.ソ"  ) }) },
    sub {1},
    sub {1},
# 21
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6001.NOTEXIST.A"   ); my $r = -B FH1; close FH1;    $r }) xor mb::eval(q{ -B "6001.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6001.0B.A"         ); my $r = -B FH1; close FH1;    $r }) xor mb::eval(q{ -B "6001.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6001.1B.binary.A"  ); my $r = -B FH1; close FH1;    $r }) xor mb::eval(q{ -B "6001.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6001.1B.text.A"    ); my $r = -B FH1; close FH1;    $r }) xor mb::eval(q{ -B "6001.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6001.512B.binary.A"); my $r = -B FH1; close FH1;    $r }) xor mb::eval(q{ -B "6001.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6001.512B.text.A"  ); my $r = -B FH1; close FH1;    $r }) xor mb::eval(q{ -B "6001.512B.text.ソ"   }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.NOTEXIST.A"    }) xor mb::eval(q{ open(FH2,"6001.NOTEXIST.ソ"   ); -B FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.0B.A"          }) xor mb::eval(q{ open(FH2,"6001.0B.ソ"         ); -B FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.1B.binary.A"   }) xor mb::eval(q{ open(FH2,"6001.1B.binary.ソ"  ); -B FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.1B.text.A"     }) xor mb::eval(q{ open(FH2,"6001.1B.text.ソ"    ); -B FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.512B.binary.A" }) xor mb::eval(q{ open(FH2,"6001.512B.binary.ソ"); -B FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -B "6001.512B.text.A"   }) xor mb::eval(q{ open(FH2,"6001.512B.text.ソ"  ); -B FH2 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6001.NOTEXIST.A"   ); open(FH2,"6001.NOTEXIST.ソ"   ); (-B FH1) xor (-B FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6001.0B.A"         ); open(FH2,"6001.0B.ソ"         ); (-B FH1) xor (-B FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6001.1B.binary.A"  ); open(FH2,"6001.1B.binary.ソ"  ); (-B FH1) xor (-B FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6001.1B.text.A"    ); open(FH2,"6001.1B.text.ソ"    ); (-B FH1) xor (-B FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6001.512B.binary.A"); open(FH2,"6001.512B.binary.ソ"); (-B FH1) xor (-B FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6001.512B.text.A"  ); open(FH2,"6001.512B.text.ソ"  ); (-B FH1) xor (-B FH2) }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { not CORE::eval(q{ (-B "6001.NOTEXIST.A"   ) xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.777.A"        ) xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.000.A"        ) xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.0B.A"         ) xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.1B.binary.A"  ) xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.1B.text.A"    ) xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.512B.binary.A") xor (-B _) }) },
    sub { not CORE::eval(q{ (-B "6001.512B.text.A"  ) xor (-B _) }) },
    sub {1},
    sub {1},
# 61
    sub { not mb::eval(q{ (-B "6001.NOTEXIST.A"   ) xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.777.A"        ) xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.000.A"        ) xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.0B.A"         ) xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.1B.binary.A"  ) xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.1B.text.A"    ) xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.512B.binary.A") xor (-B _) }) },
    sub { not mb::eval(q{ (-B "6001.512B.text.A"  ) xor (-B _) }) },
    sub {1},
    sub {1},
# 71
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.NOTEXIST.ソ"   ) xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.777.ソ"        ) xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.000.ソ"        ) xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.0B.ソ"         ) xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.1B.binary.ソ"  ) xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.1B.text.ソ"    ) xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.512B.binary.ソ") xor (-B _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-B "6001.512B.text.ソ"  ) xor (-B _) }) },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
