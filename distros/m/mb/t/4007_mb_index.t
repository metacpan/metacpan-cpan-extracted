# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

@test = (
# 1
    sub { $_='ABCDABCDABCD';                my $r=    index($_,'CD');     $r == 2 },
    sub { $_='ABCDABCDABCD';                my $r=    index($_,'CD',3);   $r == 6 },
    sub { $_='ABCDABCDABCD';                my $r=mb::index($_,'CD');     $r == 2 },
    sub { $_='ABCDABCDABCD';                my $r=mb::index($_,'CD',3);   $r == 6 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::index($_,'B‚¤1');   $r == 2 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::index($_,'B‚¤1',6); $r == 9 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='ABCDABCDABCD';                my $r=    index($_,'XY');     $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=    index($_,'XY',3);   $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=mb::index($_,'XY');     $r == -1 },
    sub { $_='ABCDABCDABCD';                my $r=mb::index($_,'XY',3);   $r == -1 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::index($_,'‚©3Z');   $r == -1 },
    sub { $_='‚ AB‚¤123‚ AB‚¤123‚ AB‚¤123'; my $r=mb::index($_,'‚©3Z',6); $r == -1 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
