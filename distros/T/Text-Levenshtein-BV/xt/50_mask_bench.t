#!perl
use 5.006;

use strict;
use warnings;
use utf8;

use Test::More;

use Benchmark qw(:all) ;

use integer;
no warnings 'portable'; # for 0xffffffffffffffff

our @masks = (
0x0000000000000000,
0x0000000000000001,0x0000000000000003,0x0000000000000007,0x000000000000000f,
0x000000000000001f,0x000000000000003f,0x000000000000007f,0x00000000000000ff,
0x00000000000001ff,0x00000000000003ff,0x00000000000007ff,0x0000000000000fff,
0x0000000000001fff,0x0000000000003fff,0x0000000000007fff,0x000000000000ffff,
0x000000000001ffff,0x000000000003ffff,0x000000000007ffff,0x00000000000fffff,
0x00000000001fffff,0x00000000003fffff,0x00000000007fffff,0x0000000000ffffff,
0x0000000001ffffff,0x0000000003ffffff,0x0000000007ffffff,0x000000000fffffff,
0x000000001fffffff,0x000000003fffffff,0x000000007fffffff,0x00000000ffffffff,
0x00000001ffffffff,0x00000003ffffffff,0x00000007ffffffff,0x0000000fffffffff,
0x0000001fffffffff,0x0000003fffffffff,0x0000007fffffffff,0x000000ffffffffff,
0x000001ffffffffff,0x000003ffffffffff,0x000007ffffffffff,0x00000fffffffffff,
0x00001fffffffffff,0x00003fffffffffff,0x00007fffffffffff,0x0000ffffffffffff,
0x0001ffffffffffff,0x0003ffffffffffff,0x0007ffffffffffff,0x000fffffffffffff,
0x001fffffffffffff,0x003fffffffffffff,0x007fffffffffffff,0x00ffffffffffffff,
0x01ffffffffffffff,0x03ffffffffffffff,0x07ffffffffffffff,0x0fffffffffffffff,
0x1fffffffffffffff,0x3fffffffffffffff,0x7fffffffffffffff,0xffffffffffffffff,
);

for my $i (0..63) {
	ok(
		$masks[$i+1] == myshift($i),
		"i: $i " . sprintf('%x',$masks[$i+1]) . ' ' . sprintf('%x',myshift($i))
	);
}

sub myshift {
	my $num = shift;
	my $res = 0;
	$res  |= 1 << $_  for 0..$num;

	return $res;
}

if (1) {
    cmpthese( -1, {
       'mask32' => sub {
            my $i = $masks[32];
        },
       'shift32' => sub {
            my $VP;
            $VP  |= 1 << $_  for 0 .. 32;
        },
       'mask10' => sub {
            my $i = $masks[10];
        },
       'shift10' => sub {
            my $VP;
            $VP  |= 1 << $_  for 0 .. 10;
        },
       'mask1' => sub {
            my $i = $masks[1];
        },
       'shift1' => sub {
            my $VP;
            $VP  |= 1 << $_  for 0 .. 1;
        },
    });
}

done_testing;

=pod

              Rate shift32 shift10  shift1  mask32   mask1  mask10
shift32   696486/s      --    -55%    -81%    -98%    -98%    -98%
shift10  1535999/s    121%      --    -57%    -95%    -95%    -95%
shift1   3574690/s    413%    133%      --    -88%    -89%    -89%
mask32  31079881/s   4362%   1923%    769%      --     -7%     -7%
mask1   33363781/s   4690%   2072%    833%      7%      --     -1%
mask10  33592824/s   4723%   2087%    840%      8%      1%      --

=cut
