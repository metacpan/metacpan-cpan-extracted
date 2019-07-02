######################################################################
#
# 1011_rindex.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

@test = (
# 1
    sub { $_='ABCDABCDABCD';                my $r=          rindex($_,'CD');      $r == 10 },
    sub { $_='ABCDABCDABCD';                my $r=          rindex($_,'CD',9);    $r == 6  },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::rindex($_,'CD');      $r == 10 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::rindex($_,'CD',9);    $r == 6  },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::rindex($_,'Bう1');    $r == 16 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::rindex($_,'Bう1',14); $r == 9  },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='ABCDABCDABCD';                my $r=          rindex($_,'XY');      $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=          rindex($_,'XY',9);    $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::rindex($_,'XY');      $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::rindex($_,'XY',9);    $r == -1 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::rindex($_,'か3Z');    $r == -1 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::rindex($_,'か3Z',14); $r == -1 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
