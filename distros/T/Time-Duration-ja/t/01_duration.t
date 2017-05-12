use utf8;
use Test::More 'no_plan';
use Time::Duration::ja;

is duration(120), "2分";
is duration(121), "2分1秒";

is ago(3600), "1時間前";
is ago(-3600), "1時間後";
is ago(3601), "1時間1秒前";
is ago(-3660), "1時間1分後";

is ago(3661, 3), "1時間1分1秒前";

# need more tests!

