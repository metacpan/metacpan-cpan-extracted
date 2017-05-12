use Test::More qw/no_plan/;

use lib 't/lib';
require SubExporterGenerator;

package A0;
use Test::More;

SubExporterGenerator->import( 'all');
ok(defined &min);
ok(defined &uniq);
ok(defined &shuffle);
ok(defined &max);
is(hoge(), "hogehoge");

package A01;
use Test::More;

SubExporterGenerator->import( ':all');
ok(defined &min);
ok(defined &uniq);
ok(defined &shuffle);
ok(defined &max);
is(hoge(), "hogehoge");

package A02;
use Test::More;

SubExporterGenerator->import( -all);
ok(defined &min);
ok(defined &uniq);
ok(defined &shuffle);
ok(defined &max);
is(hoge(), "hogehoge");

package A03;
use Test::More;

SubExporterGenerator->import( 'all', {prefix => 1});
ok(defined &test_min, 'min as test_min');
ok(defined &test_shuffle);
is(test_hoge(), "hogehoge");

package A04;
use Test::More;

SubExporterGenerator->import( {'-test' => ['uniq']});
ok(defined &uniq, "");
ok(!defined &camelize);
ok(!defined &test_hoge);

package A05;
use Test::More;

SubExporterGenerator->import( {'-test' => ['min']}, {prefix => 1});

ok(defined &test_min, "min as test_min");

package A1;
use Test::More;

SubExporterGenerator->import( -test => ['uniq', 'min'], {prefix => 1});
ok(defined &test_uniq, 'test_uniq');
ok(defined &test_min, 'test_min  defined');
ok(!defined &test_shuffle, 'test_shuffle is not defined');
ok(!defined &shuffle, 'shuffle is not defined');
ok(!defined &min, 'min is not defined');

package A2;

use Test::More;
SubExporterGenerator->import( -test, {prefix => 1});
ok(defined &test_uniq, 'test_uniq');
ok(defined &test_min,  'test_min');
ok(test_hoge, "hogehoge");
package AA;

use Test::More;

SubExporterGenerator->import( -test => {-prefix => "l_"});
is_deeply([l_uniq(qw/1 0 1 2 3 3/)], [1,0,2,3]);

package CC;

use Test::More;

SubExporterGenerator->import( -test => {uniq => {-as => 'listuniq'}});
is_deeply([listuniq(qw/1 0 1 2 3 3/)], [1,0,2,3]);

package DD;
use Test::More;

SubExporterGenerator->import( -test => {uniq => {-as => 'li_uniq'}, -prefix => "l_"});
is_deeply([li_uniq(qw/1 0 1 2 3 3/)], [1,0,2,3]);
is(l_min(qw/10 9 8 4 5 7/), 4);
ok(!defined &l_uniq);

package EE;
use Test::More;

SubExporterGenerator->import( -test => ["shuffle", "max", min => {-as, "minmin"} , uniq => {-as => 'li_uniq'},
			       hoge => {-as => "fuga"}, hoge => {-as => "hoge2"}, foo => {-as => "foo1"}, foo => {-as => "foo2"}]);
is_deeply([li_uniq(qw/1 0 1 2 3 3/)], [1,0,2,3]);
ok(defined &shuffle, 'defined shuffle');
ok(!defined &min, 'not defined min');
ok(defined &max, 'defined max');
ok(defined &minmin, 'min as minmin');
is(minmin(12,3,4,5), 3);
is(fuga(), "hogehoge");
is(hoge2(), "hogehoge");
is(foo1(), "foo");
is(foo2(), "foo");
ok(!defined &foo);
ok(!defined &hoge);
