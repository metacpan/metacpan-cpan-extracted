######################################################################
#
# 1025_s.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for jperl only. You are using $^X.\n" if $^X !~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

@test = (
# 1
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s/BCD/xyz/;                         $r == 1                     },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s/BCD/xyz/;                         $_ eq 'AxyzABCDABCD'        },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/BCD/]}><xyz>;  $r == 1                     },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/BCD/]}><xyz>;  $_ eq 'AxyzABCDABCD'        },
    sub { $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/‚¢D/]}><12‚©>; $r == 1                     },
    sub { $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/‚¢D/]}><12‚©>; $_ eq 'A‚ 12‚©A‚ ‚¢DA‚ ‚¢D' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s/BCD/xyz/g;                         $r == 3                       },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s/BCD/xyz/g;                         $_ eq 'AxyzAxyzAxyz'          },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/BCD/]}><xyz>g;  $r == 3                       },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/BCD/]}><xyz>g;  $_ eq 'AxyzAxyzAxyz'          },
    sub { $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/‚¢D/]}><12‚©>g; $r == 3                       },
    sub { $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/‚¢D/]}><12‚©>g; $_ eq 'A‚ 12‚©A‚ 12‚©A‚ 12‚©' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { ($] < 5.014) or eval q{ $_='ABCDABCDABCD';       my $r= $_ =~ s/BCD/xyz/r;                         $r eq 'AxyzABCDABCD'        }},
    sub { ($] < 5.014) or eval q{ $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/BCD/]}><xyz>r;  $r eq 'AxyzABCDABCD'        }},
    sub { ($] < 5.014) or eval q{ $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/‚¢D/]}><12‚©>r; $r eq 'A‚ 12‚©A‚ ‚¢DA‚ ‚¢D' }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { ($] < 5.014) or eval q{ $_='ABCDABCDABCD';       my $r= $_ =~ s/BCD/xyz/gr;                         $r eq 'AxyzAxyzAxyz'          }},
    sub { ($] < 5.014) or eval q{ $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/BCD/]}><xyz>gr;  $r eq 'AxyzAxyzAxyz'          }},
    sub { ($] < 5.014) or eval q{ $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/‚¢D/]}><12‚©>gr; $r eq 'A‚ 12‚©A‚ 12‚©A‚ 12‚©' }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s/number/$one/;    $_ eq '$two'   },
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s/number/$one/e;   $_ eq '$two'   },
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s/number/$one/ee;  $_ eq '$three' },
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s/number/$one/eee; $_ eq 'four'   },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>;    $_ eq '$two'   },
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>e;   $_ eq '$two'   },
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>ee;  $_ eq '$three' },
    sub { my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>eee; $_ eq 'four'   },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 61
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>r;    $r eq '$two'   }},
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>er;   $r eq '$two'   }},
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>eer;  $r eq '$three' }},
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='number'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>eeer; $r eq 'four'   }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 71
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='numbernumbernumber'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>gr;    $r eq '$two$two$two'       }},
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='numbernumbernumber'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>ger;   $r eq '$two$two$two'       }},
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='numbernumbernumber'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>geer;  $r eq '$three$three$three' }},
    sub { ($] < 5.014) or eval q{ my $one='$two'; my $two='$three'; my $three='four'; $_='numbernumbernumber'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/number/]}><$one>geeer; $r eq 'fourfourfour'       }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 81
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s/(B)(C)(D)/$3$2$1/;                         $r == 1                    },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s/(B)(C)(D)/$3$2$1/;                         $_ eq 'ADCBABCDABCD'       },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/(B)(C)(D)/]}><$3$2$1>;  $r == 1                    },
    sub { $_='ABCDABCDABCD';       my $r= $_ =~ s<@{[UTF8::R2::qr qr/(B)(C)(D)/]}><$3$2$1>;  $_ eq 'ADCBABCDABCD'       },
    sub { $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/(‚¢)(D)/]}><$2$1>;      $r == 1                    },
    sub { $_='A‚ ‚¢DA‚ ‚¢DA‚ ‚¢D'; my $r= $_ =~ s<@{[UTF8::R2::qr qr/(‚¢)(D)/]}><$2$1>;      $_ eq 'A‚ D‚¢A‚ ‚¢DA‚ ‚¢D' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
