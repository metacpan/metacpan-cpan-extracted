use 5.018;
use strict;
use warnings;
use Test::More;

use_ok('Voxgig::Struct');
ok(defined $Voxgig::Struct::VERSION, 'version defined');
ok(defined &Voxgig::Struct::isnode, 'isnode defined');
ok(defined &Voxgig::Struct::merge, 'merge defined');
ok(defined &Voxgig::Struct::getpath, 'getpath defined');

done_testing();
