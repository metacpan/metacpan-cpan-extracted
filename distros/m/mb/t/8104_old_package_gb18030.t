# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(gb18030);
use vars qw(@test);

@test = (

# 1
    sub { defined(&GB18030::chop)        },
    sub { defined(&GB18030::chr)         },
    sub { defined(&GB18030::do)          },
    sub { defined(&GB18030::eval)        },
    sub { defined(&GB18030::getc)        },
    sub { defined(&GB18030::length)      },
    sub { defined(&GB18030::ord)         },
    sub { defined(&GB18030::require)     },
    sub { defined(&GB18030::reverse)     },
    sub { defined(&GB18030::substr)      },

# 11
    sub { defined(&GB18030::tr)          },
    sub { defined(&GB18030::dosglob)     },
    sub { defined(&GB18030::index)       },
    sub { defined(&GB18030::index_byte)  },
    sub { defined(&GB18030::rindex)      },
    sub { defined(&GB18030::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
