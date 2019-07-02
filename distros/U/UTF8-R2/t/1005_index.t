######################################################################
#
# 1005_index.t
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
    sub { $_='ABCDABCDABCD';                my $r=          index($_,'CD');     $r == 2 },
    sub { $_='ABCDABCDABCD';                my $r=          index($_,'CD',3);   $r == 6 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::index($_,'CD');     $r == 2 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::index($_,'CD',3);   $r == 6 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::index($_,'Bう1');   $r == 2 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::index($_,'Bう1',6); $r == 9 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='ABCDABCDABCD';                my $r=          index($_,'XY');     $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=          index($_,'XY',3);   $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::index($_,'XY');     $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=UTF8::R2::index($_,'XY',3);   $r == -1 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::index($_,'か3Z');   $r == -1 },
    sub { $_='あABう123あABう123あABう123'; my $r=UTF8::R2::index($_,'か3Z',6); $r == -1 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
