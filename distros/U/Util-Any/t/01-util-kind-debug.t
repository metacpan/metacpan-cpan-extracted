use Test::More qw/no_plan/;

use Util::Any 'debug';
use strict;

ok(defined &Dumper , 'defined &Dumper');
ok(!defined &DumeprX , 'not defined DumperX');
