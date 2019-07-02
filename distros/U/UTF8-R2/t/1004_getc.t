######################################################################
#
# 1004_getc.t
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

BEGIN { open(FILE,">@{[__FILE__]}.txt"); print FILE "Aαあ","\xF0","\x9F","\x98","\x80"; close(FILE); }
END   { unlink("@{[__FILE__]}.txt") }

@test = (
# 1
    sub { 'あ' eq "\xE3\x81\x82"                                                 },
    sub { open(FILE,"@{[__FILE__]}.txt")                                         },
    sub { my $r=UTF8::R2::getc(FILE); $r eq 'A'                                  },
    sub { my $r=UTF8::R2::getc(FILE); $r eq 'α'                                 },
    sub { my $r=UTF8::R2::getc(FILE); $r eq 'あ'                                 },
    sub { my $r=UTF8::R2::getc(FILE); $r eq join('',"\xF0","\x9F","\x98","\x80") },
    sub { close(FILE)                                                            },
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { my $r=qx!$^X -e "use lib qq{$FindBin::Bin/../lib}; use UTF8::R2; print UTF8::R2::getc"                                              < @{[__FILE__]}.txt!; $r eq 'A'                                          },
    sub { my $r=qx!$^X -e "use lib qq{$FindBin::Bin/../lib}; use UTF8::R2; print UTF8::R2::getc.UTF8::R2::getc"                               < @{[__FILE__]}.txt!; $r eq 'Aα'                                        },
    sub { my $r=qx!$^X -e "use lib qq{$FindBin::Bin/../lib}; use UTF8::R2; print UTF8::R2::getc.UTF8::R2::getc.UTF8::R2::getc"                < @{[__FILE__]}.txt!; $r eq 'Aαあ'                                      },
    sub { my $r=qx!$^X -e "use lib qq{$FindBin::Bin/../lib}; use UTF8::R2; print UTF8::R2::getc.UTF8::R2::getc.UTF8::R2::getc.UTF8::R2::getc" < @{[__FILE__]}.txt!; $r eq join('',"Aαあ","\xF0","\x9F","\x98","\x80") },
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
