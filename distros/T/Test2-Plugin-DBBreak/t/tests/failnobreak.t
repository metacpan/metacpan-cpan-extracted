use Test2::V0;
use Test2::Plugin::DBBreak;

our $curr_dir;

BEGIN {
  $0 =~ '(.*[\\\/])\w+\.\w+$';
  $curr_dir = $1 || "./";
}

use lib "${curr_dir}../";
use Trace;

$| = 1;

    my $x = 'X';
    my $y = 'Y';

$Test2::Plugin::DBBreak::disable = 1;
    is($x, $y);
$Test2::Plugin::DBBreak::disable = 0;

done_testing;
exit;
