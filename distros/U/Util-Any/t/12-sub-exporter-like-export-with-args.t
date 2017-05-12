use Test::More qw/no_plan/;
use strict;

use lib qw(./lib t/lib);

use SubExporterGenerator -test => [-args => { hoge => "fuga"}];

is_deeply(check_default(), {hoge => "fuga"});

1;
