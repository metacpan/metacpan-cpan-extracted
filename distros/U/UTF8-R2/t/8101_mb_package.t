# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2 qw(*mb);
use vars qw(@test);

@test = (

# 1
    sub { defined($mb::ORIG_PROGRAM_NAME) },
    sub { defined($mb::PERL)              },
    sub { defined(&mb::chop)              },
    sub { defined(&mb::chr)               },
    sub { defined(&mb::do)                },
    sub { defined(&mb::eval)              },
    sub { defined(&mb::getc)              },
    sub { defined(&mb::index)             },
    sub { defined(&mb::index_byte)        },
    sub { defined(&mb::length)            },

# 11
    sub { defined(&mb::ord)               },
    sub { defined(&mb::require)           },
    sub { defined(&mb::reverse)           },
    sub { defined(&mb::rindex)            },
    sub { defined(&mb::rindex_byte)       },
    sub { defined(&mb::split)             },
    sub { defined(&mb::substr)            },
    sub { defined(&mb::tr)                },
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
