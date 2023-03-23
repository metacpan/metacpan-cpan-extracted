# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(sjis);
use vars qw(@test);

@test = (

# 1
    sub { defined(&Sjis::chop)        },
    sub { defined(&Sjis::chr)         },
    sub { defined(&Sjis::do)          },
    sub { defined(&Sjis::eval)        },
    sub { defined(&Sjis::getc)        },
    sub { defined(&Sjis::length)      },
    sub { defined(&Sjis::ord)         },
    sub { defined(&Sjis::require)     },
    sub { defined(&Sjis::reverse)     },
    sub { defined(&Sjis::substr)      },

# 11
    sub { defined(&Sjis::tr)          },
    sub { defined(&Sjis::dosglob)     },
    sub { defined(&Sjis::index)       },
    sub { defined(&Sjis::index_byte)  },
    sub { defined(&Sjis::rindex)      },
    sub { defined(&Sjis::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
