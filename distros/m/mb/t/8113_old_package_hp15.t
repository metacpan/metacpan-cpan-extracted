# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(hp15);
use vars qw(@test);

@test = (

# 1
    sub { defined(&HP15::chop)        },
    sub { defined(&HP15::chr)         },
    sub { defined(&HP15::do)          },
    sub { defined(&HP15::eval)        },
    sub { defined(&HP15::getc)        },
    sub { defined(&HP15::length)      },
    sub { defined(&HP15::ord)         },
    sub { defined(&HP15::require)     },
    sub { defined(&HP15::reverse)     },
    sub { defined(&HP15::substr)      },

# 11
    sub { defined(&HP15::tr)          },
    sub { defined(&HP15::dosglob)     },
    sub { defined(&HP15::index)       },
    sub { defined(&HP15::index_byte)  },
    sub { defined(&HP15::rindex)      },
    sub { defined(&HP15::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
