# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(big5);
use vars qw(@test);

@test = (

# 1
    sub { defined(&Big5::chop)        },
    sub { defined(&Big5::chr)         },
    sub { defined(&Big5::do)          },
    sub { defined(&Big5::eval)        },
    sub { defined(&Big5::getc)        },
    sub { defined(&Big5::length)      },
    sub { defined(&Big5::ord)         },
    sub { defined(&Big5::require)     },
    sub { defined(&Big5::reverse)     },
    sub { defined(&Big5::substr)      },

# 11
    sub { defined(&Big5::tr)          },
    sub { defined(&Big5::dosglob)     },
    sub { defined(&Big5::index)       },
    sub { defined(&Big5::index_byte)  },
    sub { defined(&Big5::rindex)      },
    sub { defined(&Big5::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
