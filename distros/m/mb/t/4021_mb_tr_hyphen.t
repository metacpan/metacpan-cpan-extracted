######################################################################
#
# 4021_mb_tr_hyphen.t
#
# Copyright (c) 2020 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AReplacement list is longer than search list at /             ? return :
        /\AUseless use of \/d modifier in transliteration operator at / ? return :
        warn $_[0];
    };
}

@test = (
##############################################################################
# 1
    sub { $_='ABCDE'; my $r= $_ =~ tr/B-D/123/; $r == 3                 },
    sub { $_='ABCDE'; my $r= $_ =~ tr/B-D/123/; $_ eq 'A123E'           },
    sub { $_='ABCDE'; my $r= $_ =~ tr/BCD/1-3/; $r == 3                 },
    sub { $_='ABCDE'; my $r= $_ =~ tr/BCD/1-3/; $_ eq 'A123E'           },
    sub { $_='ABCDE'; my $r= $_ =~ tr/B-D/1-3/; $r == 3                 },
    sub { $_='ABCDE'; my $r= $_ =~ tr/B-D/1-3/; $_ eq 'A123E'           },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#-----------------------------------------------------------------------------
# 11
    sub { $_='ABCDE'; my $r=mb::tr($_,'B-D','123'); $r == 3       },
    sub { $_='ABCDE'; my $r=mb::tr($_,'B-D','123'); $_ eq 'A123E' },
    sub { $_='ABCDE'; my $r=mb::tr($_,'BCD','1-3'); $r == 3       },
    sub { $_='ABCDE'; my $r=mb::tr($_,'BCD','1-3'); $_ eq 'A123E' },
    sub { $_='ABCDE'; my $r=mb::tr($_,'B-D','1-3'); $r == 3       },
    sub { $_='ABCDE'; my $r=mb::tr($_,'B-D','1-3'); $_ eq 'A123E' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
##############################################################################
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
