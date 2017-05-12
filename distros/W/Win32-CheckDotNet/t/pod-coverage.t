use strict;
use warnings;
use lib  ('./blib','../blib', './lib', '../lib');

# source: http://www.perlmonks.org/bare/?node_id=508109 - downloaded 2013-10-09 19:45 CEST

eval {
    require Test::More;
};
if ($@) {
    $|++;
    print "1..0 # Skipped: Test::More required for testing POD coverage\n";
    exit;
}
eval {
    require Test::Pod::Coverage;
};
if ($@ or (not defined $Test::Pod::Coverage::VERSION) or ($Test::Pod::Coverage::VERSION < 1.06)) {
    Test::More::plan(skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage");
    exit;
}

Test::More::plan( tests => 1 );
Test::Pod::Coverage::pod_coverage_ok('Win32::CheckDotNet');

