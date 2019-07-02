######################################################################
#
# 1012_substr.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

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
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 3, 5,'おDEか2き'); $_ eq 'あい0おDEか2きえ' },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 3, 5,'おDEか2き'); $r eq '1abcう'           },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { $_='0123456789';    my $r=          substr($_, -4, 2,'abc');       $_ eq '012345abc89'       },
    sub { $_='0123456789';    my $r=          substr($_, -4, 2,'abc');       $r eq '67'                },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -4, 2,'abc');       $_ eq '012345abc89'       },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -4, 2,'abc');       $r eq '67'                },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -5, 4,'おDEか2き'); $_ eq 'あい01おDEか2きえ' },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -5, 4,'おDEか2き'); $r eq 'abcう'             },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { $_='0123456789';    my $r=          substr($_, 1, -5,'abc');       $_ eq '0abc56789'          },
    sub { $_='0123456789';    my $r=          substr($_, 1, -5,'abc');       $r eq '1234'               },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 1, -5,'abc');       $_ eq '0abc56789'          },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 1, -5,'abc');       $r eq '1234'               },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 1, -5,'おDEか2き'); $_ eq 'あおDEか2きabcうえ' },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 1, -5,'おDEか2き'); $r eq 'い01'               },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { $_='0123456789';    my $r=          substr($_, -5, -2,'abc');       $_ eq '01234abc89'          },
    sub { $_='0123456789';    my $r=          substr($_, -5, -2,'abc');       $r eq '567'                 },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -5, -2,'abc');       $_ eq '01234abc89'          },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, -5, -2,'abc');       $r eq '567'                 },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -6, -3,'おDEか2き'); $_ eq 'あい0おDEか2きcうえ' },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -6, -3,'おDEか2き'); $r eq '1ab'                 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { $_='0123456789';    my $r=          substr($_, 3, 2); $r eq '34'     },
    sub { $_='0123456789';    my $r=UTF8::R2::substr($_, 3, 2); $r eq '34'     },
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 3, 5); $r eq '1abcう' },
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
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -5, 4); $r eq 'abcう' },
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
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 1, -5); $r eq 'い01' },
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
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -6, -3); $r eq '1ab' },
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
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, 3); $r eq '1abcうえ' },
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
    sub { $_='あい01abcうえ'; my $r=UTF8::R2::substr($_, -5); $r eq 'abcうえ' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 111
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, 3, 2)='さ67しd'; $_ eq '012さ67しd56789' }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, 3, 2)='さ67しd'; $_ eq '012さ67しd56789' }},
    sub { ($] < 5.014) or eval q{ $_='あい01abcうえ'; UTF8::R2::substr($_, 3, 5)='さ67しd'; $_ eq 'あい0さ67しdえ'  }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 121
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, -4, 2)='さ67しd'; $_ eq '012345さ67しd89' }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, -4, 2)='さ67しd'; $_ eq '012345さ67しd89' }},
    sub { ($] < 5.014) or eval q{ $_='あい01abcうえ'; UTF8::R2::substr($_, -5, 4)='さ67しd'; $_ eq 'あい01さ67しdえ' }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 131
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, 1, -5)='さ67しd'; $_ eq '0さ67しd56789'    }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, 1, -5)='さ67しd'; $_ eq '0さ67しd56789'    }},
    sub { ($] < 5.014) or eval q{ $_='あい01abcうえ'; UTF8::R2::substr($_, 1, -5)='さ67しd'; $_ eq 'あさ67しdabcうえ' }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 141
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, -5, -2)='さ67しd'; $_ eq '01234さ67しd89'    }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, -5, -2)='さ67しd'; $_ eq '01234さ67しd89'    }},
    sub { ($] < 5.014) or eval q{ $_='あい01abcうえ'; UTF8::R2::substr($_, -6, -3)='さ67しd'; $_ eq 'あい0さ67しdcうえ' }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 151
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, 3)='efす9せ'; $_ eq '012efす9せ'   }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, 3)='efす9せ'; $_ eq '012efす9せ'   }},
    sub { ($] < 5.014) or eval q{ $_='あい01abcうえ'; UTF8::R2::substr($_, 3)='efす9せ'; $_ eq 'あい0efす9せ' }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 161
    sub { ($] < 5.014) or eval q{ $_='0123456789';              substr($_, -4)='efす9せ'; $_ eq '012345efす9せ' }},
    sub { ($] < 5.014) or eval q{ $_='0123456789';    UTF8::R2::substr($_, -4)='efす9せ'; $_ eq '012345efす9せ' }},
    sub { ($] < 5.014) or eval q{ $_='あい01abcうえ'; UTF8::R2::substr($_, -5)='efす9せ'; $_ eq 'あい01efす9せ' }},
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
