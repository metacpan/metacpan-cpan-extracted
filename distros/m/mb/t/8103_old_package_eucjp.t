# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(eucjp);
use vars qw(@test);

@test = (

# 1
    sub { defined(&EUCJP::chop)        },
    sub { defined(&EUCJP::chr)         },
    sub { defined(&EUCJP::do)          },
    sub { defined(&EUCJP::eval)        },
    sub { defined(&EUCJP::getc)        },
    sub { defined(&EUCJP::length)      },
    sub { defined(&EUCJP::ord)         },
    sub { defined(&EUCJP::require)     },
    sub { defined(&EUCJP::reverse)     },
    sub { defined(&EUCJP::substr)      },

# 11
    sub { defined(&EUCJP::tr)          },
    sub { defined(&EUCJP::dosglob)     },
    sub { defined(&EUCJP::index)       },
    sub { defined(&EUCJP::index_byte)  },
    sub { defined(&EUCJP::rindex)      },
    sub { defined(&EUCJP::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
