# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
# 1
    sub { $_='ABCDABCDABCD';                my $r=    rindex($_,'CD');      $r == 10 },
    sub { $_='ABCDABCDABCD';                my $r=    rindex($_,'CD',9);    $r == 6  },
    sub { $_='ABCDABCDABCD';                my $r=mb::rindex($_,'CD');      $r == 10 },
    sub { $_='ABCDABCDABCD';                my $r=mb::rindex($_,'CD',9);    $r == 6  },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::rindex($_,'B‚¤1');    $r == 16 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::rindex($_,'B‚¤1',14); $r == 9  },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='ABCDABCDABCD';                my $r=    rindex($_,'XY');      $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=    rindex($_,'XY',9);    $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=mb::rindex($_,'XY');      $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=mb::rindex($_,'XY',9);    $r == -1 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::rindex($_,'‚©3Z');    $r == -1 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::rindex($_,'‚©3Z',14); $r == -1 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
