# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(euctw);
use vars qw(@test);

@test = (

# 1
    sub { defined(&EUCTW::chop)        },
    sub { defined(&EUCTW::chr)         },
    sub { defined(&EUCTW::do)          },
    sub { defined(&EUCTW::eval)        },
    sub { defined(&EUCTW::getc)        },
    sub { defined(&EUCTW::length)      },
    sub { defined(&EUCTW::ord)         },
    sub { defined(&EUCTW::require)     },
    sub { defined(&EUCTW::reverse)     },
    sub { defined(&EUCTW::substr)      },

# 11
    sub { defined(&EUCTW::tr)          },
    sub { defined(&EUCTW::dosglob)     },
    sub { defined(&EUCTW::index)       },
    sub { defined(&EUCTW::index_byte)  },
    sub { defined(&EUCTW::rindex)      },
    sub { defined(&EUCTW::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
