######################################################################
#
# 1012_substr.t
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

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\Asubstr outside of string at /   ? return :
        /\AUse of uninitialized value at / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub {                         $_='0123456789'; my $r=          substr($_,-11, 1,'abc'); $r eq ''         },
    sub { ($] > 5.005) or eval q{ $_='0123456789'; my $r=          substr($_, 12, 1,'abc'); $r eq ''        }},
    sub {                         $_='0123456789'; my $r=UTF8::R2::substr($_,-11, 1,'abc'); not defined($r)  },
    sub {                         $_='0123456789'; my $r=UTF8::R2::substr($_, 12, 1,'abc'); not defined($r)  },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='0123456789';    my $r=          substr($_, 3, 2,'abc');       $_ eq '012abc56789'      },
    sub { $_='0123456789';    my $r=          substr($_, 3, 2,'abc');       $r eq '34'               },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 3, 2,'abc');       $_ eq '012abc56789'      },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 3, 2,'abc');       $r eq '34'               },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 3, 5,'‚¨DE‚©2‚«'); $_ eq '‚ ‚¢0‚¨DE‚©2‚«‚¦' },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 3, 5,'‚¨DE‚©2‚«'); $r eq '1abc‚¤'           },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { $_='0123456789';    my $r=          substr($_, -4, 2,'abc');       $_ eq '012345abc89'       },
    sub { $_='0123456789';    my $r=          substr($_, -4, 2,'abc');       $r eq '67'                },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -4, 2,'abc');       $_ eq '012345abc89'       },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -4, 2,'abc');       $r eq '67'                },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -5, 4,'‚¨DE‚©2‚«'); $_ eq '‚ ‚¢01‚¨DE‚©2‚«‚¦' },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -5, 4,'‚¨DE‚©2‚«'); $r eq 'abc‚¤'             },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { $_='0123456789';    my $r=          substr($_, 1, -5,'abc');       $_ eq '0abc56789'          },
    sub { $_='0123456789';    my $r=          substr($_, 1, -5,'abc');       $r eq '1234'               },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 1, -5,'abc');       $_ eq '0abc56789'          },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 1, -5,'abc');       $r eq '1234'               },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 1, -5,'‚¨DE‚©2‚«'); $_ eq '‚ ‚¨DE‚©2‚«abc‚¤‚¦' },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 1, -5,'‚¨DE‚©2‚«'); $r eq '‚¢01'               },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { $_='0123456789';    my $r=          substr($_, -5, -2,'abc');       $_ eq '01234abc89'          },
    sub { $_='0123456789';    my $r=          substr($_, -5, -2,'abc');       $r eq '567'                 },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -5, -2,'abc');       $_ eq '01234abc89'          },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -5, -2,'abc');       $r eq '567'                 },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -6, -3,'‚¨DE‚©2‚«'); $_ eq '‚ ‚¢0‚¨DE‚©2‚«c‚¤‚¦' },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -6, -3,'‚¨DE‚©2‚«'); $r eq '1ab'                 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { $_='0123456789';    my $r=          substr($_, 3, 2); $r eq '34'     },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 3, 2); $r eq '34'     },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 3, 5); $r eq '1abc‚¤' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 61
    sub { $_='0123456789';    my $r=          substr($_, -4, 2); $r eq '67'    },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -4, 2); $r eq '67'    },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -5, 4); $r eq 'abc‚¤' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 71
    sub { $_='0123456789';    my $r=          substr($_, 1, -5); $r eq '1234' },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 1, -5); $r eq '1234' },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 1, -5); $r eq '‚¢01' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 81
    sub { $_='0123456789';    my $r=          substr($_, -5, -2); $r eq '567' },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -5, -2); $r eq '567' },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -6, -3); $r eq '1ab' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 91
    sub { $_='0123456789';    my $r=          substr($_, 3); $r eq '3456789'  },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 3); $r eq '3456789'  },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, 3); $r eq '1abc‚¤‚¦' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 101
    sub { $_='0123456789';    my $r=          substr($_, -4); $r eq '6789'    },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -4); $r eq '6789'    },
    sub { $_='‚ ‚¢01abc‚¤‚¦'; my $r=UTF8::R2::substr($_, -5); $r eq 'abc‚¤‚¦' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 111
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, 3, 2)='‚³67‚µd'; $_ eq '012‚³67‚µd56789' }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, 3, 2)='‚³67‚µd'; $_ eq '012‚³67‚µd56789' }},
    sub { ($] < 5.014) or eval q{ $_='‚ ‚¢01abc‚¤‚¦'; UTF8::R2::substr($_, 3, 5)='‚³67‚µd'; $_ eq '‚ ‚¢0‚³67‚µd‚¦'  }},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
# 121
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, -4, 2)='‚³67‚µd'; $_ eq '012345‚³67‚µd89' }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, -4, 2)='‚³67‚µd'; $_ eq '012345‚³67‚µd89' }},
    sub { ($] < 5.014) or eval q{ $_='‚ ‚¢01abc‚¤‚¦'; UTF8::R2::substr($_, -5, 4)='‚³67‚µd'; $_ eq '‚ ‚¢01‚³67‚µd‚¦' }},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
# 131
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, 1, -5)='‚³67‚µd'; $_ eq '0‚³67‚µd56789'    }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, 1, -5)='‚³67‚µd'; $_ eq '0‚³67‚µd56789'    }},
    sub { ($] < 5.014) or eval q{ $_='‚ ‚¢01abc‚¤‚¦'; UTF8::R2::substr($_, 1, -5)='‚³67‚µd'; $_ eq '‚ ‚³67‚µdabc‚¤‚¦' }},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
# 141
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, -5, -2)='‚³67‚µd'; $_ eq '01234‚³67‚µd89'    }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, -5, -2)='‚³67‚µd'; $_ eq '01234‚³67‚µd89'    }},
    sub { ($] < 5.014) or eval q{ $_='‚ ‚¢01abc‚¤‚¦'; UTF8::R2::substr($_, -6, -3)='‚³67‚µd'; $_ eq '‚ ‚¢0‚³67‚µdc‚¤‚¦' }},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
# 151
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, 3)='ef‚·9‚¹'; $_ eq '012ef‚·9‚¹'   }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, 3)='ef‚·9‚¹'; $_ eq '012ef‚·9‚¹'   }},
    sub { ($] < 5.014) or eval q{ $_='‚ ‚¢01abc‚¤‚¦'; UTF8::R2::substr($_, 3)='ef‚·9‚¹'; $_ eq '‚ ‚¢0ef‚·9‚¹' }},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
# 161
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, -4)='ef‚·9‚¹'; $_ eq '012345ef‚·9‚¹' }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, -4)='ef‚·9‚¹'; $_ eq '012345ef‚·9‚¹' }},
    sub { ($] < 5.014) or eval q{ $_='‚ ‚¢01abc‚¤‚¦'; UTF8::R2::substr($_, -5)='ef‚·9‚¹'; $_ eq '‚ ‚¢01ef‚·9‚¹' }},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
    sub { ($] < 5.014) or eval q{1}},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1;
if ($^X !~ /jperl/i) { ok(1,'PASS not on JPerl') for @test; exit; }
sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
