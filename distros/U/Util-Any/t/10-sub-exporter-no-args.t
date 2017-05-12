use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilSubExporter";
  $err = $@;
}

use strict;
use Test::More qw/no_plan/;

SKIP: {
skip $@ if $err;


ok(!defined &first,       'not defined first');
ok(!defined &min,         'not defined min');
ok(!defined &minstr,      'not defined minstr');
ok(!defined &hello,       'not defined hello');
ok(!defined &hi,          'not defined hi');
ok(!defined &askme,       'not defined askme');
}