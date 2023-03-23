# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(rfc2279);
use vars qw(@test);

@test = (

# 1
    sub { defined(&RFC2279::chop)        },
    sub { defined(&RFC2279::chr)         },
    sub { defined(&RFC2279::do)          },
    sub { defined(&RFC2279::eval)        },
    sub { defined(&RFC2279::getc)        },
    sub { defined(&RFC2279::length)      },
    sub { defined(&RFC2279::ord)         },
    sub { defined(&RFC2279::require)     },
    sub { defined(&RFC2279::reverse)     },
    sub { defined(&RFC2279::substr)      },

# 11
    sub { defined(&RFC2279::tr)          },
    sub { defined(&RFC2279::dosglob)     },
    sub { defined(&RFC2279::index)       },
    sub { defined(&RFC2279::index_byte)  },
    sub { defined(&RFC2279::rindex)      },
    sub { defined(&RFC2279::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
