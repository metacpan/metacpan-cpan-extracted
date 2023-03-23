# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(utf8);
use vars qw(@test);

@test = (

# 1
    sub { defined(&UTF2::chop)        },
    sub { defined(&UTF2::chr)         },
    sub { defined(&UTF2::do)          },
    sub { defined(&UTF2::eval)        },
    sub { defined(&UTF2::getc)        },
    sub { defined(&UTF2::length)      },
    sub { defined(&UTF2::ord)         },
    sub { defined(&UTF2::require)     },
    sub { defined(&UTF2::reverse)     },
    sub { defined(&UTF2::substr)      },

# 11
    sub { defined(&UTF2::tr)          },
    sub { defined(&UTF2::dosglob)     },
    sub { defined(&UTF2::index)       },
    sub { defined(&UTF2::index_byte)  },
    sub { defined(&UTF2::rindex)      },
    sub { defined(&UTF2::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
