use strict;

package UtilOption;

use base qw/Util::Any/;
use strict;

our $Utils = {
              list  => [
                         [
                          'List::Util', '',
                          {
                           'first' => 'list_first',
                           'sum'   => 'lsum',
                           'min'   => 'lmin',
                           -select => ['first', 'sum', 'shuffle'],
                          }
                         ]
                        ],
             };


UtilOption->import(qw/list/);
use Test::More qw/no_plan/;

ok(defined &list_first, 'defined first as list_first');
ok(defined &lsum, 'defined sum as lsum');
ok(defined &lmin, 'defined min as lmin but not in select');
ok(defined &shuffle, 'not defined shuffle');
ok(!defined &min,    'not defined min');
ok(!defined &minstr, 'not defined minstr');
ok(!defined &reduce, 'not defined reduce');

