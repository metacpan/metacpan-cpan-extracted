use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilSubExporter -l2s => {-prefix => 'list__',
                                     min => {-as => 'list___min'},
                                    },
                            -greet => {-prefix => 'greet_'}, 'askme' => {-as => 'ask_me'};";
  $err = $@;
}

use strict;
use Test::More qw/no_plan/;

SKIP: {
skip $err if $err;

ok(defined &list__first,  'defined list__first');
ok(defined &list___min,   'defined min as list___min');
ok(defined &list__minstr, 'defined list__minstr');
ok(defined &greet_hello,  'defined greet_hello');
ok(defined &greet_hi,     'defined greet_hi');
ok(defined &ask_me,       'defined askme as ask_me');

is(ask_me(), "what you will", 'askme');
is(greet_hi(), "hi there", 'hi');
is((list__first {$_ >= 4} (2,10,4,3,5)), 10, 'list first');

}
