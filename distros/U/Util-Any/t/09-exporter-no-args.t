use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilExporter;";
  $err = $@;
}
use strict;

use Test::More qw/no_plan/;

SKIP: {
  skip $err if $err;
  ok(!defined &first,  'not defined first');
  ok(!defined &min,    'not defined min');
  ok(!defined &minstr, 'not defined minstr');
  ok(defined &hello,  'defined hello');
  ok(!defined &askme, 'not defined askme');
  ok(!defined &hi,    'not defined hi');

  is(hello(), "hello there", 'hello');
}
