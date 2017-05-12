use Test::More qw/no_plan/;

package A0;
use Test::More;

use Util::Any 'all';
ok(defined &min);
ok(defined &camelize);

package A01;
use Test::More;

use Util::Any ':all';
ok(defined &min);
ok(defined &camelize);

package A02;
use Test::More;

use Util::Any -all;
ok(defined &min);
ok(defined &camelize);

package A03;
use Test::More;

use Util::Any 'all', {prefix => 1};
ok(defined &list_min);
ok(defined &string_camelize);

package A04;
use Test::More;

use Util::Any {'list' => ['uniq']};
ok(defined &uniq, "");
ok(!defined &camelize);

package A05;
use Test::More;

use Util::Any {'list' => ['min'], -string => ['camelize']}, {prefix => 1};
ok(defined &list_min, "");
ok(!defined &string_uniq);
ok(defined &string_camelize);

package A1;
use Test::More;

use Util::Any -list => ['uniq', 'min'], {prefix => 1};
ok(defined &list_uniq, 'list_uniq');
ok(defined &list_min, 'list_min  defined');
ok(!defined &list_shuffle, 'list_shuffle is not defined');
ok(!defined &shuffle, 'shuffle is not defined');
ok(!defined &min, 'min is not defined');

package A2;

use Test::More;
use Util::Any -list, {prefix => 1};
ok(defined &list_uniq, 'list_uniq');
ok(defined &list_min,  'list_min');

package AA;

use Test::More;

use Util::Any -list => {-prefix => "l_"};
is_deeply([l_uniq qw/1 0 1 2 3 3/], [1,0,2,3]);

package CC;

use Test::More;

use Util::Any -list => {uniq => {-as => 'listuniq'}};
is_deeply([listuniq qw/1 0 1 2 3 3/], [1,0,2,3]);

package DD;
use Test::More;

use Util::Any -list => {uniq => {-as => 'li_uniq'}, -prefix => "l_"};
is_deeply([li_uniq qw/1 0 1 2 3 3/], [1,0,2,3]);
is(l_min(qw/10 9 8 4 5 7/), 4);
ok(!defined &l_uniq);

package EE;
use Test::More;

use Util::Any -list => {uniq => {-as => 'li_uniq'}, -prefix => "ll_"}, {smart_rename => 1};
is_deeply([li_uniq qw/1 0 1 2 3 3/], [1,0,2,3]);
is(ll_min(qw/10 9 8 4 5 7/), 4);
ok(!defined &ll_uniq);

