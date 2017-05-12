# spit.t

use lib '/home/eekim/devel/IDCommons';
use Test::More tests => 2;
BEGIN { use_ok('XDI::SPIT') };

my $spit = XDI::SPIT;
my ($idBroker, $inumber) = $spit->resolveBroker('@blueoxen*eekim');
is($idBroker, 'http://2idi.com/xridb');
