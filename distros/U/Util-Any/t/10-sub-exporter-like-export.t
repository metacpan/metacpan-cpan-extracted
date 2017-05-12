use strict;

use lib qw(./lib ./t/lib);

use Util::Any
    -list => {-prefix => 'list__'},
    -string => {camelize => {-as => 'camel'}},
    -scalar => {-prefix => 'sss_'};
    
use strict;
use Test::More qw/no_plan/;

ok(defined &list__uniq, 'uniq as list__uniq');
ok(defined &camel, 'camelcase as camel');
ok(defined &sss_weaken, 'weaken as sss_weaken');
ok(defined &sss_isweak, 'isweak as sss_isweake');
ok(sss_blessed(bless {}), "blessed as Blessed");

package fuga;

use Test::More;
use lib qw(./lib ./t/lib);

use Util::Any
    -list => {-prefix => 'list__'},
    -string => {camelize => {-as => 'camel'}},
    -scalar => {-prefix => 'sss_', blessed => {-as => 'Blessed'}};
    
ok(defined &list__uniq, 'uniq as list__uniq');
ok(defined &camel, 'camelcase as camel');
ok(Blessed(bless {}), "blessed as Blessed");
ok(defined &sss_weaken, "weaken as sss_weaken");
