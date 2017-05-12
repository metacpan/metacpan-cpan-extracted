use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilSubExporter2 -greet => {-prefix => 'greet_'},
                             -l2s   => {hello => {-as => 'hello_hogehoge'}},
                             'askme' => {-as => 'ask_me'};";
  $err = $@;
}

use strict;
use Test::More qw/no_plan/;

SKIP: {
skip $err if $err;

ok(!defined &list__first,  'not defined list__first');
ok(!defined &list___min,   'not defined min as list___min');
ok(!defined &list__minstr, 'not defined list__minstr');
ok(defined &greet_hello,  'defined greet_hello');
ok(defined &greet_hi,     'defined greet_hi');
ok(defined &ask_me,       'defined askme as ask_me');
ok(defined &hello_hogehoge, 'defined hello as hello_hogehoeg');
ok(!defined &hello,         'not defined hello');
ok(!defined &hogehoge,      'not defined hogehoge');


is(ask_me(), "what you will", 'askme');
is(greet_hi(), "hi there", 'hi');

}