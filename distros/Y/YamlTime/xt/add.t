my $xt; use lib ($xt = -e 'xt' ? 'xt' : 'test/devel');
use Test::More;

plan skip_all => 'For now';
use Test;

my $dir = "$xt/YT1";
rmtree($dir);
mkdir($dir) or die;
chdir($dir) or die;

run "yt init";
run "yt new Something special";

ok -l('_'), 'Current link exists';

chdir($HOME) or die;
rmtree($dir) or die;
