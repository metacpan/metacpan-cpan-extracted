# Testing of some API methods;

use strict;
use warnings;

use lib 't/lib/';
use Test::More 0.88;
use SubtestCompat;
use TestBridge;
use YAML::As::Parsed;

subtest "default exports" => sub {
    ok( defined(&Load),         'Found exported Load function'   );
    ok( defined(&Dump),         'Found exported Dump function'   );
    ok( \&main::Load == \&YAML::As::Parsed::Load, 'Load is YAML::As::Parsed' );
    ok( \&main::Dump == \&YAML::As::Parsed::Dump, 'Dump is YAML::As::Parsed' );
    ok( !defined(&LoadFile), 'LoadFile function not exported' );
    ok( !defined(&DumpFile), 'DumpFile function not exported' );
    ok( !defined(&freeze),   'freeze function not exported'   );
    ok( !defined(&thaw),     'thaw functiona not exported'    );
};

subtest "all exports" => sub {
    package main::all_exports;
    use Test::More 0.88;
    use YAML::As::Parsed qw/Load Dump LoadFile DumpFile freeze thaw/;
    ok( defined(&Load),         'Found exported Load function'     );
    ok( defined(&Dump),         'Found exported Dump function'     );
    ok( defined(&LoadFile), 'Found exported LoadFile function' );
    ok( defined(&DumpFile), 'Found exported DumpFile function' );
    ok( defined(&freeze),   'Found exported freeze function'   );
    ok( defined(&thaw),     'Found exported thaw functiona'    );
};

subtest "constructor and documents" => sub {
    my @docs = ( { one => 'two' }, { three => 'four' } );
    ok( my $yaml = YAML::As::Parsed->new( @docs ), "constructor" );
    cmp_deeply( [ @$yaml ], \@docs, "the object is an arrayref of documents" );
};

done_testing;
