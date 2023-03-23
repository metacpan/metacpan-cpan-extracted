# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb qw(gbk);
use vars qw(@test);

@test = (

# 1
    sub { defined(&GBK::chop)        },
    sub { defined(&GBK::chr)         },
    sub { defined(&GBK::do)          },
    sub { defined(&GBK::eval)        },
    sub { defined(&GBK::getc)        },
    sub { defined(&GBK::length)      },
    sub { defined(&GBK::ord)         },
    sub { defined(&GBK::require)     },
    sub { defined(&GBK::reverse)     },
    sub { defined(&GBK::substr)      },

# 11
    sub { defined(&GBK::tr)          },
    sub { defined(&GBK::dosglob)     },
    sub { defined(&GBK::index)       },
    sub { defined(&GBK::index_byte)  },
    sub { defined(&GBK::rindex)      },
    sub { defined(&GBK::rindex_byte) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
