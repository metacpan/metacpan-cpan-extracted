use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilExporter qw/:all/;";
  $err = $@;
}
use strict;

use Test::More qw/no_plan/;

SKIP: {
  skip $err if $err;
  ok(defined &first,  'defined first');
  ok(defined &min,    'defined min');
  ok(defined &minstr, 'defined minstr');
  ok(defined &hello,  'defined hello');
  ok(defined &askme,  'defined askme');
  ok(defined &hi,     'defined hi');

  is((first { defined $_} ("abc","def", "ghi")), "abc", "first");
  is(min(20, 50, 10), 10, "min");
}
