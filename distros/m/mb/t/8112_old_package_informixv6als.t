# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(informixv6als);
use vars qw(@test);

@test = (

# 1
    sub { defined(&INFORMIXV6ALS::chop)        },
    sub { defined(&INFORMIXV6ALS::chr)         },
    sub { defined(&INFORMIXV6ALS::do)          },
    sub { defined(&INFORMIXV6ALS::eval)        },
    sub { defined(&INFORMIXV6ALS::getc)        },
    sub { defined(&INFORMIXV6ALS::length)      },
    sub { defined(&INFORMIXV6ALS::ord)         },
    sub { defined(&INFORMIXV6ALS::require)     },
    sub { defined(&INFORMIXV6ALS::reverse)     },
    sub { defined(&INFORMIXV6ALS::substr)      },

# 11
    sub { defined(&INFORMIXV6ALS::tr)          },
    sub { defined(&INFORMIXV6ALS::dosglob)     },
    sub { defined(&INFORMIXV6ALS::index)       },
    sub { defined(&INFORMIXV6ALS::index_byte)  },
    sub { defined(&INFORMIXV6ALS::rindex)      },
    sub { defined(&INFORMIXV6ALS::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
