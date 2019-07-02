######################################################################
#
# 1002_chr.t
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
    sub { $_=0x41; my $r=          chr($_); $r eq 'A' },
    sub { $_=0x41; my $r=          chr;     $r eq 'A' },
    sub { $_=0x41; my $r=UTF8::R2::chr($_); $r eq 'A' },
    sub { $_=0x41; my $r=UTF8::R2::chr;     $r eq 'A' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_=0xE38182; my $r=UTF8::R2::chr($_); $r eq 'あ'           },
    sub { $_=0xE38182; my $r=UTF8::R2::chr;     $r eq 'あ'           },
    sub { $_=-1;       my $r=UTF8::R2::chr($_); $r eq "\xEF\xBF\xBD" },
    sub { $_=-1;       my $r=UTF8::R2::chr;     $r eq "\xEF\xBF\xBD" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
