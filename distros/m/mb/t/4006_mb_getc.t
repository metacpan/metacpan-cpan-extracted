# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
# always "0" because qx{chcp} cannot return right value on CPAN TEST
$MSWin32_MBCS = 0; # ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

BEGIN { open(FILE,">@{[__FILE__]}.txt"); print FILE "Aƒ¿‚ "; close(FILE); }
END   { unlink("@{[__FILE__]}.txt") }

@test = (
# 1
    sub { '‚ ' eq "\x82\xA0" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { my $r=qx!echo A     | $^X -e "use lib qq{$FindBin::Bin/../lib}; use mb; print mb::getc"!;                                                       $r eq 'A'     },
    sub { return 'SKIP' unless $MSWin32_MBCS; my $r=qx!echo Aƒ¿   | $^X -e "use lib qq{$FindBin::Bin/../lib}; use mb; print mb::getc.mb::getc"!;          $r eq 'Aƒ¿'   },
    sub { return 'SKIP' unless $MSWin32_MBCS; my $r=qx!echo Aƒ¿‚  | $^X -e "use lib qq{$FindBin::Bin/../lib}; use mb; print mb::getc.mb::getc.mb::getc"!; $r eq 'Aƒ¿‚ ' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { open(FILE,"@{[__FILE__]}.txt"); my $r=mb::getc(\*FILE);                                                 close(FILE); $r eq 'A'  },
    sub { open(FILE,"@{[__FILE__]}.txt"); my $a=mb::getc(\*FILE); my $r=mb::getc(\*FILE);                         close(FILE); $r eq 'ƒ¿' },
    sub { open(FILE,"@{[__FILE__]}.txt"); my $a=mb::getc(\*FILE); my $b=mb::getc(\*FILE); my $r=mb::getc(\*FILE); close(FILE); $r eq '‚ ' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { open(FILE,"@{[__FILE__]}.txt"); my $r=mb::getc \*FILE;                                               close(FILE); $r eq 'A'  },
    sub { open(FILE,"@{[__FILE__]}.txt"); my $a=mb::getc \*FILE; my $r=mb::getc \*FILE;                        close(FILE); $r eq 'ƒ¿' },
    sub { open(FILE,"@{[__FILE__]}.txt"); my $a=mb::getc \*FILE; my $b=mb::getc \*FILE; my $r=mb::getc \*FILE; close(FILE); $r eq '‚ ' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' if $] < 5.006; open(my $fh,"@{[__FILE__]}.txt"); my $r=mb::getc($fh);                                           close($fh); $r eq 'A'  },
    sub { return 'SKIP' if $] < 5.006; open(my $fh,"@{[__FILE__]}.txt"); my $a=mb::getc($fh); my $r=mb::getc($fh);                      close($fh); $r eq 'ƒ¿' },
    sub { return 'SKIP' if $] < 5.006; open(my $fh,"@{[__FILE__]}.txt"); my $a=mb::getc($fh); my $b=mb::getc($fh); my $r=mb::getc($fh); close($fh); $r eq '‚ ' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { return 'SKIP' if $] < 5.006; open(my $fh,"@{[__FILE__]}.txt"); my $r=mb::getc $fh;                                         close($fh); $r eq 'A'  },
    sub { return 'SKIP' if $] < 5.006; open(my $fh,"@{[__FILE__]}.txt"); my $a=mb::getc $fh; my $r=mb::getc $fh;                     close($fh); $r eq 'ƒ¿' },
    sub { return 'SKIP' if $] < 5.006; open(my $fh,"@{[__FILE__]}.txt"); my $a=mb::getc $fh; my $b=mb::getc $fh; my $r=mb::getc $fh; close($fh); $r eq '‚ ' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
