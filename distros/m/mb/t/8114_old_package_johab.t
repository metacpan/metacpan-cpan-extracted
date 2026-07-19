# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(johab);
use vars qw(@test);

@test = (

# 1
    sub { defined(&JOHAB::chop)        },
    sub { defined(&JOHAB::chr)         },
    sub { defined(&JOHAB::do)          },
    sub { defined(&JOHAB::eval)        },
    sub { defined(&JOHAB::getc)        },
    sub { defined(&JOHAB::length)      },
    sub { defined(&JOHAB::ord)         },
    sub { defined(&JOHAB::require)     },
    sub { defined(&JOHAB::reverse)     },
    sub { defined(&JOHAB::substr)      },

# 11
    sub { defined(&JOHAB::tr)          },
    sub { defined(&JOHAB::dosglob)     },
    sub { defined(&JOHAB::index)       },
    sub { defined(&JOHAB::index_byte)  },
    sub { defined(&JOHAB::rindex)      },
    sub { defined(&JOHAB::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
