use strict;

use lib qw(./lib ./t/lib);

use UtilExporter qw/askme :us/;
use strict;

use Test::More qw/no_plan/;

ok(!defined &first,  'not defined first');
ok(!defined &min,    'not defined min');
ok(!defined &minstr, 'not defined minstr');
ok(!defined &hello, 'not defined hello');
ok(defined &askme, 'defined askme');
ok(defined &hi,    'defined hi');

is(askme(), "what you will", 'askme');
is(hi(), "hi there", 'hi');

