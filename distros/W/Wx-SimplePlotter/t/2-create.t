use Test::More tests => 1;

use Wx;
use Wx::SimplePlotter;

my $frame = Wx::Frame->new(undef, -1, "Wx::SimplePlotter test", 
    Wx::Point->new(1,1), Wx::Size->new(1, 1));

my $ctl = Wx::SimplePlotter->new($frame, -1);

ok(ref($ctl));
