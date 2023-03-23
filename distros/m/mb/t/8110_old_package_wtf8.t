# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(wtf8);
use vars qw(@test);

@test = (

# 1
    sub { defined(&WTF8::chop)        },
    sub { defined(&WTF8::chr)         },
    sub { defined(&WTF8::do)          },
    sub { defined(&WTF8::eval)        },
    sub { defined(&WTF8::getc)        },
    sub { defined(&WTF8::length)      },
    sub { defined(&WTF8::ord)         },
    sub { defined(&WTF8::require)     },
    sub { defined(&WTF8::reverse)     },
    sub { defined(&WTF8::substr)      },

# 11
    sub { defined(&WTF8::tr)          },
    sub { defined(&WTF8::dosglob)     },
    sub { defined(&WTF8::index)       },
    sub { defined(&WTF8::index_byte)  },
    sub { defined(&WTF8::rindex)      },
    sub { defined(&WTF8::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
