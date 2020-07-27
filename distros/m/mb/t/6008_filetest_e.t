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

mkdir "6008.777.A",0777;
open FILE,">6008.0B.A";          print FILE '';                          close FILE;
open FILE,">6008.1B.binary.A";   print FILE "\x00";                      close FILE;
open FILE,">6008.1B.text.A";     print FILE "A";                         close FILE;
open FILE,">6008.512B.binary.A"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
open FILE,">6008.512B.text.A";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
if ($MSWin32_MBCS) {
    mb::eval <<'END';
        mkdir "6008.777.ソ",0777;
        open FILE,">6008.0B.ソ";          print FILE '';                          close FILE;
        open FILE,">6008.1B.binary.ソ";   print FILE "\x00";                      close FILE;
        open FILE,">6008.1B.text.ソ";     print FILE "A";                         close FILE;
        open FILE,">6008.512B.binary.ソ"; print FILE "\x00" x 52, "A" x (512-52); close FILE;
        open FILE,">6008.512B.text.ソ";   print FILE "\x00" x 51, "A" x (512-51); close FILE;
END
}

END {
    mb::eval sprintf <<'END', $MSWin32_MBCS;
        close FH1;
        close FH2;
        unlink "6008.0B.A";
        unlink "6008.1B.binary.A";
        unlink "6008.1B.text.A";
        unlink "6008.512B.binary.A";
        unlink "6008.512B.text.A";
        rmdir "6008.777.A";
        if (%s) {
            closedir DH1;
            closedir DH2;
            rmdir "6008.777.ソ";
            unlink "6008.0B.ソ";
            unlink "6008.1B.binary.ソ";
            unlink "6008.1B.text.ソ";
            unlink "6008.512B.binary.ソ";
            unlink "6008.512B.text.ソ";
        }
END
}

@test = (
# 1
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.NOTEXIST.A"    }) xor mb::eval(q{ -e "6008.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.777.A"         }) xor mb::eval(q{ -e "6008.777.ソ"         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.0B.A"          }) xor mb::eval(q{ -e "6008.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.1B.binary.A"   }) xor mb::eval(q{ -e "6008.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.1B.text.A"     }) xor mb::eval(q{ -e "6008.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.512B.binary.A" }) xor mb::eval(q{ -e "6008.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.512B.text.A"   }) xor mb::eval(q{ -e "6008.512B.text.ソ"   }) },
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.NOTEXIST.A"   ) xor (-e "6008.NOTEXIST.ソ"   ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.777.A"        ) xor (-e "6008.777.ソ"        ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.0B.A"         ) xor (-e "6008.0B.ソ"         ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.1B.binary.A"  ) xor (-e "6008.1B.binary.ソ"  ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.1B.text.A"    ) xor (-e "6008.1B.text.ソ"    ) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.512B.binary.A") xor (-e "6008.512B.binary.ソ") }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.512B.text.A"  ) xor (-e "6008.512B.text.ソ"  ) }) },
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6008.NOTEXIST.A"   ); my $r = -e FH1; close FH1;    $r }) xor mb::eval(q{ -e "6008.NOTEXIST.ソ"    }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ opendir(DH1,"6008.777.A"     ); my $r = eval q{ -e DH1 }; closedir DH1; $r                                   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6008.0B.A"         ); my $r = -e FH1; close FH1;    $r }) xor mb::eval(q{ -e "6008.0B.ソ"          }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6008.1B.binary.A"  ); my $r = -e FH1; close FH1;    $r }) xor mb::eval(q{ -e "6008.1B.binary.ソ"   }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6008.1B.text.A"    ); my $r = -e FH1; close FH1;    $r }) xor mb::eval(q{ -e "6008.1B.text.ソ"     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6008.512B.binary.A"); my $r = -e FH1; close FH1;    $r }) xor mb::eval(q{ -e "6008.512B.binary.ソ" }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ open(FH1,"6008.512B.text.A"  ); my $r = -e FH1; close FH1;    $r }) xor mb::eval(q{ -e "6008.512B.text.ソ"   }) },
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.NOTEXIST.A"    }) xor mb::eval(q{ open(FH2,"6008.NOTEXIST.ソ"   ); -e FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not                                              mb::eval(q{ opendir(DH2,"6008.777.ソ"     ); -e DH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.0B.A"          }) xor mb::eval(q{ open(FH2,"6008.0B.ソ"         ); -e FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.1B.binary.A"   }) xor mb::eval(q{ open(FH2,"6008.1B.binary.ソ"  ); -e FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.1B.text.A"     }) xor mb::eval(q{ open(FH2,"6008.1B.text.ソ"    ); -e FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.512B.binary.A" }) xor mb::eval(q{ open(FH2,"6008.512B.binary.ソ"); -e FH2 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not CORE::eval(q{ -e "6008.512B.text.A"   }) xor mb::eval(q{ open(FH2,"6008.512B.text.ソ"  ); -e FH2 }) },
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6008.NOTEXIST.A"   ); open(FH2,"6008.NOTEXIST.ソ"   ); (-e FH1) xor (-e FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ opendir(DH1,"6008.777.A"     ); opendir(DH2,"6008.777.ソ"     ); (-e DH1) xor (-e DH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6008.0B.A"         ); open(FH2,"6008.0B.ソ"         ); (-e FH1) xor (-e FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6008.1B.binary.A"  ); open(FH2,"6008.1B.binary.ソ"  ); (-e FH1) xor (-e FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6008.1B.text.A"    ); open(FH2,"6008.1B.text.ソ"    ); (-e FH1) xor (-e FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6008.512B.binary.A"); open(FH2,"6008.512B.binary.ソ"); (-e FH1) xor (-e FH2) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ open(FH1,"6008.512B.text.A"  ); open(FH2,"6008.512B.text.ソ"  ); (-e FH1) xor (-e FH2) }) },
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { not CORE::eval(q{ (-e "6008.NOTEXIST.A"   ) xor (-e _) }) },
    sub { not CORE::eval(q{ (-e "6008.777.A"        ) xor (-e _) }) },
    sub { not CORE::eval(q{ (-e "6008.0B.A"         ) xor (-e _) }) },
    sub { not CORE::eval(q{ (-e "6008.1B.binary.A"  ) xor (-e _) }) },
    sub { not CORE::eval(q{ (-e "6008.1B.text.A"    ) xor (-e _) }) },
    sub { not CORE::eval(q{ (-e "6008.512B.binary.A") xor (-e _) }) },
    sub { not CORE::eval(q{ (-e "6008.512B.text.A"  ) xor (-e _) }) },
    sub {1},
    sub {1},
    sub {1},
# 61
    sub { not mb::eval(q{ (-e "6008.NOTEXIST.A"   ) xor (-e _) }) },
    sub { not mb::eval(q{ (-e "6008.777.A"        ) xor (-e _) }) },
    sub { not mb::eval(q{ (-e "6008.0B.A"         ) xor (-e _) }) },
    sub { not mb::eval(q{ (-e "6008.1B.binary.A"  ) xor (-e _) }) },
    sub { not mb::eval(q{ (-e "6008.1B.text.A"    ) xor (-e _) }) },
    sub { not mb::eval(q{ (-e "6008.512B.binary.A") xor (-e _) }) },
    sub { not mb::eval(q{ (-e "6008.512B.text.A"  ) xor (-e _) }) },
    sub {1},
    sub {1},
    sub {1},
# 71
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.NOTEXIST.ソ"   ) xor (-e _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.777.ソ"        ) xor (-e _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.0B.ソ"         ) xor (-e _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.1B.binary.ソ"  ) xor (-e _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.1B.text.ソ"    ) xor (-e _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.512B.binary.ソ") xor (-e _) }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ (-e "6008.512B.text.ソ"  ) xor (-e _) }) },
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
