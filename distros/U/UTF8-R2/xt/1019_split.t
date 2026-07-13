######################################################################
#
# 1019_split.t
#
# Copyright (c) 2019 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for jperl only. You are using $^X.\n" if $^X !~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AUse of implicit split to \@_ is deprecated at /   ? return :
        /\AUse of uninitialized value at /                   ? return :
        /\AUse of uninitialized value in join or string at / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { $_='ABCDE'; my @r=          split(//);        "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=          split(//,$_);     "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=          split(//,$_,3);   "@r" eq "A B CDE"    },
    sub { $_='ABCDE'; my @r=UTF8::R2::split('');        "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=UTF8::R2::split('',$_);     "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=UTF8::R2::split('',$_,3);   "@r" eq "A B CDE"    },
    sub { $_='ABCDE'; my @r=UTF8::R2::split(qr//);      "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=UTF8::R2::split(qr//,$_);   "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=UTF8::R2::split(qr//,$_,3); "@r" eq "A B CDE"    },
    sub {1},
# 11
    sub {              $_='ABCDE'; my $r=          split(//);        $r == 5 },
    sub {              $_='ABCDE'; my $r=          split(//,$_);     $r == 5 },
    sub {              $_='ABCDE'; my $r=          split(//,$_,3);   $r == 3 },
    sub { local $^W=0; $_='ABCDE'; my $r=UTF8::R2::split('');        $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=UTF8::R2::split('',$_);     $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=UTF8::R2::split('',$_,3);   $r == 3 },
    sub { local $^W=0; $_='ABCDE'; my $r=UTF8::R2::split(qr//);      $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=UTF8::R2::split(qr//,$_);   $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=UTF8::R2::split(qr//,$_,3); $r == 3 },
    sub {1},
# 21
    sub { $_='A‚ B±²‚¤‚¦C'; my @r=UTF8::R2::split('');        "@r" eq "A ‚  B ± ² ‚¤ ‚¦ C" },
    sub { $_='A‚ B±²‚¤‚¦C'; my @r=UTF8::R2::split('',$_);     "@r" eq "A ‚  B ± ² ‚¤ ‚¦ C" },
    sub { $_='A‚ B±²‚¤‚¦C'; my @r=UTF8::R2::split('',$_,5);   "@r" eq "A ‚  B ± ²‚¤‚¦C"    },
    sub { $_='A‚ B±²‚¤‚¦C'; my @r=UTF8::R2::split(qr//);      "@r" eq "A ‚  B ± ² ‚¤ ‚¦ C" },
    sub { $_='A‚ B±²‚¤‚¦C'; my @r=UTF8::R2::split(qr//,$_);   "@r" eq "A ‚  B ± ² ‚¤ ‚¦ C" },
    sub { $_='A‚ B±²‚¤‚¦C'; my @r=UTF8::R2::split(qr//,$_,5); "@r" eq "A ‚  B ± ²‚¤‚¦C"    },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { local $^W=0; $_='A‚ B±²‚¤‚¦C'; my $r=UTF8::R2::split('');        $r == 8 },
    sub { local $^W=0; $_='A‚ B±²‚¤‚¦C'; my $r=UTF8::R2::split('',$_);     $r == 8 },
    sub { local $^W=0; $_='A‚ B±²‚¤‚¦C'; my $r=UTF8::R2::split('',$_,5);   $r == 5 },
    sub { local $^W=0; $_='A‚ B±²‚¤‚¦C'; my $r=UTF8::R2::split(qr//);      $r == 8 },
    sub { local $^W=0; $_='A‚ B±²‚¤‚¦C'; my $r=UTF8::R2::split(qr//,$_);   $r == 8 },
    sub { local $^W=0; $_='A‚ B±²‚¤‚¦C'; my $r=UTF8::R2::split(qr//,$_,5); $r == 5 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { my $r=join(':',UTF8::R2::split(qr/b/,'abc'));             $r eq 'a:c'           },
    sub { my $r=join(':',UTF8::R2::split(qr//,'abc'));              $r eq 'a:b:c'         },
    sub { my $r=join(':',UTF8::R2::split(qr//,'abc',1));            $r eq 'abc'           },
    sub { my $r=join(':',UTF8::R2::split(qr//,'abc',2));            $r eq 'a:bc'          },
    sub { my $r=join(':',UTF8::R2::split(qr//,'abc',3));            $r eq 'a:b:c'         },
    sub { my $r=join(':',UTF8::R2::split(qr//,'abc',4));            $r eq 'a:b:c'         },
    sub { my $r=join(':',UTF8::R2::split(qr/,/,'a,b,c,,,'));        $r eq 'a:b:c'         },
    sub { my $r=join(':',UTF8::R2::split(qr/,/,'a,b,c,,,',-1));     $r eq 'a:b:c:::'      },
    sub { my $r=join(':',UTF8::R2::split(qr/ /, ' abc'));           $r eq ':abc'          },
    sub { my $r=join(':',UTF8::R2::split(qr//,' abc'));             $r eq ' :a:b:c'       },
# 51
    sub { my $r=join(':',UTF8::R2::split(qr//,' abc',-1));          $r eq ' :a:b:c'       },
    sub { my $r=join(':',UTF8::R2::split(qr/-|,/,"1-10,20",3));     $r eq '1:10:20'       },
    sub { my $r=join(':',UTF8::R2::split(qr/(-|,)/,"1-10,20",3));   $r eq '1:-:10:,:20'   },
    sub { my $r=join(':',UTF8::R2::split(qr/-|(,)/,"1-10,20",3));   $r eq '1::10:,:20'    },
    sub { my $r=join(':',UTF8::R2::split(qr/(-)|,/,"1-10,20",3));   $r eq '1:-:10::20'    },
    sub { my $r=join(':',UTF8::R2::split(qr/(-)|(,)/,"1-10,20",3)); $r eq '1:-::10::,:20' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 61
    sub { my $r=join('F',UTF8::R2::split(qr/‚‚/,'‚‚‚‚ƒ'));                  $r eq '‚F‚ƒ'                     },
    sub { my $r=join('F',UTF8::R2::split(qr//,'‚‚‚‚ƒ'));                    $r eq '‚F‚‚F‚ƒ'                 },
    sub { my $r=join('F',UTF8::R2::split(qr//,'‚‚‚‚ƒ',1));                  $r eq '‚‚‚‚ƒ'                     },
    sub { my $r=join('F',UTF8::R2::split(qr//,'‚‚‚‚ƒ',2));                  $r eq '‚F‚‚‚ƒ'                   },
    sub { my $r=join('F',UTF8::R2::split(qr//,'‚‚‚‚ƒ',3));                  $r eq '‚F‚‚F‚ƒ'                 },
    sub { my $r=join('F',UTF8::R2::split(qr//,'‚‚‚‚ƒ',4));                  $r eq '‚F‚‚F‚ƒ'                 },
    sub { my $r=join('F',UTF8::R2::split(qr/C/,'‚C‚‚C‚ƒCCC'));        $r eq '‚F‚‚F‚ƒ'                 },
    sub { my $r=join('F',UTF8::R2::split(qr/C/,'‚C‚‚C‚ƒCCC',-1));     $r eq '‚F‚‚F‚ƒFFF'           },
    sub { my $r=join('F',UTF8::R2::split(qr/@/, '@‚‚‚‚ƒ'));               $r eq 'F‚‚‚‚ƒ'                   },
    sub { my $r=join('F',UTF8::R2::split(qr//,'@‚‚‚‚ƒ'));                  $r eq '@F‚F‚‚F‚ƒ'             },
# 71
    sub { my $r=join('F',UTF8::R2::split(qr//,'@‚‚‚‚ƒ',-1));               $r eq '@F‚F‚‚F‚ƒ'             },
    sub { my $r=join('F',UTF8::R2::split(qr/||C/,"‚P|‚P‚OC‚Q‚O",3));     $r eq '‚PF‚P‚OF‚Q‚O'             },
    sub { my $r=join('F',UTF8::R2::split(qr/(||C)/,"‚P|‚P‚OC‚Q‚O",3));   $r eq '‚PF|F‚P‚OFCF‚Q‚O'     },
    sub { my $r=join('F',UTF8::R2::split(qr/||(C)/,"‚P|‚P‚OC‚Q‚O",3));   $r eq '‚PFF‚P‚OFCF‚Q‚O'       },
    sub { my $r=join('F',UTF8::R2::split(qr/(|)|C/,"‚P|‚P‚OC‚Q‚O",3));   $r eq '‚PF|F‚P‚OFF‚Q‚O'       },
    sub { my $r=join('F',UTF8::R2::split(qr/(|)|(C)/,"‚P|‚P‚OC‚Q‚O",3)); $r eq '‚PF|FF‚P‚OFFCF‚Q‚O' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
