use strict;

use Test::More;

use lib  ('./blib','../blib', './lib', '../lib');

eval {
    require Test::Pod::Coverage;
};
if ($@ or (not defined $Test::Pod::Coverage::VERSION) or ($Test::Pod::Coverage::VERSION < 1.06)) {
    plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage";
    exit;
}

plan tests => 1;
Test::Pod::Coverage::pod_coverage_ok( 'Tie::FileLRUCache', { also_private => ['DEBUG', 'SCALAR'] });
