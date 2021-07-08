# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

@test = (

# 1 $mb::PERL
    sub { defined $UTF8::R2::PERL      },
    sub { length($UTF8::R2::PERL) >= 1 },
    sub { $UTF8::R2::PERL eq $^X       },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 11 $mb::ORIG_PROGRAM_NAME
    sub { defined $UTF8::R2::ORIG_PROGRAM_NAME       },
    sub { length($UTF8::R2::ORIG_PROGRAM_NAME) >= 1  },
    sub { $UTF8::R2::ORIG_PROGRAM_NAME eq $0         },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
