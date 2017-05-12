use strict;
use warnings;
use Test::More tests => 9;
do "t/lib/helpers.pl";
use Storable qw(dclone);

BEGIN { use_ok('YAML::AppConfig') }

# TEST: Testing dynamically scoped variables
{
    my $app = YAML::AppConfig->new( file => 't/data/scoping.yaml' );
    ok( $app, "Created object." );
    is( $app->get_foo, "top scope", "Testing foo's value" );
    is_deeply( $app->get_bar, { qux => "top scope" }, "Testing top scope." );
    is_deeply(
        $app->get_baz,
        {
            foo  => 'baz scope',
            qux  => 'baz scope qux',
            test => 'world',
            quxx => [
                {
                    food  => { burger => 'baz scope', test => 'world' },
                    fries => 'baz scope qux',
                    test => 'world',
                },
                {
                    foo   => 'inner scope',
                    food  => { burger => 'inner scope', test => 'world' },
                    fries => 'inner scope qux',
                    test => 'world',
                },
            ],
        },
        "Testing big baz structure."
    );
    is_deeply(
        $app->get_blah,
        { blah => "self ref test", ego => "self ref test" },
        "Dynamic scoping handles self-refs right."
    );
    eval {$app->get_simple_circ};
    like( $@, qr/Circular reference in simple_circ/,
        "Checking circular dynamic variables." );
    eval {$app->get_circ};
    like( $@, qr/Circular reference in (?:prolog|circ|cows_are_good)/,
        "Checking circular dynamic variables." );
    eval {$app->get_bigcirc};
    like( $@, qr/Circular reference in thing/,
        "Checking circular dynamic variables." );
}
