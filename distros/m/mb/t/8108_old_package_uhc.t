# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(uhc);
use vars qw(@test);

@test = (

# 1
    sub { defined(&UHC::chop)        },
    sub { defined(&UHC::chr)         },
    sub { defined(&UHC::do)          },
    sub { defined(&UHC::eval)        },
    sub { defined(&UHC::getc)        },
    sub { defined(&UHC::length)      },
    sub { defined(&UHC::ord)         },
    sub { defined(&UHC::require)     },
    sub { defined(&UHC::reverse)     },
    sub { defined(&UHC::substr)      },

# 11
    sub { defined(&UHC::tr)          },
    sub { defined(&UHC::dosglob)     },
    sub { defined(&UHC::index)       },
    sub { defined(&UHC::index_byte)  },
    sub { defined(&UHC::rindex)      },
    sub { defined(&UHC::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
