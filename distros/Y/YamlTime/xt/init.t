my $xt; use lib ($xt = -e 'xt' ? 'xt' : 'test/devel');
use Test::More tests => 5;
use Test;

my $dir = "$xt/YT1";
rmtree($dir);
mkdir($dir) or die;
chdir($dir) or die;

$ENV{YAMLTIME_BASE} = '.';
run "yt init";

ok -d($YEAR), "$YEAR directory exists";
ok -e("conf/cust.yaml"), "conf/customer.yaml exists";
ok -e("conf/proj.yaml"), "conf/project.yaml exists";
ok -e("conf/tags.yaml"), "conf/tags.yaml exists";
ok -e("conf/yt.yaml"), "conf/yt.yaml exists";

chdir($HOME) or die;
rmtree($dir) or die;
