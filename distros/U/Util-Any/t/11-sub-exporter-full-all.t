use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilSubExporter ':all'";
  $err = $@;
}

use strict;
use Test::More qw/no_plan/;

SKIP: {
skip $err if $err;

ok(defined &first,  'defined first');
ok(defined &min,    'defined min');
ok(defined &minstr, 'defined instr');
ok(defined &hello,  'defined hello');
ok(defined &hi,     'defined hi');
ok(defined &askme,  'defined askme');

is(askme(), "what you will", 'askme');
is(hi(), "hi there", 'hi');
is((first {$_ >= 4} (2,10,4,3,5)), 10, 'list first');

}
