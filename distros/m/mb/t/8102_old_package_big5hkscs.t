# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(big5hkscs);
use vars qw(@test);

@test = (

# 1
    sub { defined(&Big5HKSCS::chop)        },
    sub { defined(&Big5HKSCS::chr)         },
    sub { defined(&Big5HKSCS::do)          },
    sub { defined(&Big5HKSCS::eval)        },
    sub { defined(&Big5HKSCS::getc)        },
    sub { defined(&Big5HKSCS::length)      },
    sub { defined(&Big5HKSCS::ord)         },
    sub { defined(&Big5HKSCS::require)     },
    sub { defined(&Big5HKSCS::reverse)     },
    sub { defined(&Big5HKSCS::substr)      },

# 11
    sub { defined(&Big5HKSCS::tr)          },
    sub { defined(&Big5HKSCS::dosglob)     },
    sub { defined(&Big5HKSCS::index)       },
    sub { defined(&Big5HKSCS::index_byte)  },
    sub { defined(&Big5HKSCS::rindex)      },
    sub { defined(&Big5HKSCS::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
