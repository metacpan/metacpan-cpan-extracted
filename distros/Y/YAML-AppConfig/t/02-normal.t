use strict;
use warnings;
use Test::More tests => 106;
do "t/lib/helpers.pl";

BEGIN { use_ok('YAML::AppConfig') }

# TEST: Object creation from a file, string, and object.
{
    test_object_creation( string => slurp("t/data/normal.yaml") );
    my $app = test_object_creation( file => "t/data/normal.yaml" );
    test_object_creation( object => $app );
}

sub test_object_creation {
    my $app = YAML::AppConfig->new( @_ );
    ok( $app, "Checking object creation." );

    # Test obvious accessors are there.
    for my $method (qw(food man good is i_like and)) {
        ok( $app->can("get_$method"), "Testing $method getter" );
        ok( $app->can("set_$method"), "Testing $method setter" );
    }

    # Test we didn't get some strays.
    for my $not_method (qw(yummy like or)) {
        ok( !$app->can("get_$not_method"), "Testing !$not_method getter" );
        ok( !$app->can("set_$not_method"), "Testing !$not_method getter" );
    }

    # Test our wild things
    ok( !$app->can('get_somtin!^^^wild'),
        "Checking we can't do get_somtin!^^^wild" );
    ok( !$app->can('set_somtin!^^^wild'),
        "Checking we can't do set_somtin!^^^wild" );
    is( $app->get('somtin!^^^wild'), 'cows', "Retrieving somtin!^^^wild" );
    ok( !$app->can('get_12_foo'), "Checking we can't do get_12_foo" );
    ok( !$app->can('set_12_foo'), "Checking we can't do set_12_foo" );
    is( $app->get('12_foo'), 'blah', "Retrieving 12_foo" );

    # Test the values
    is( $app->get_food,  'oh',   "food test" );
    is( $app->get_man,  'yeah', "man test" );
    is( $app->get_good, 'it',   "good test" );
    is( $app->get_is,   'good', "is test" );
    is_deeply( $app->get_i_like, [ 'tofu', 'spatetee', 'ice cream' ],
        "i_like test" );
    is_deeply(
        $app->get_and,
        {
            yummy => 'stuff', like => 'popcorn',
            'or' => [qw(candy fruit bars)]
        },
        "and test"
    );

    return $app;
}

# TEST: Two objects don't clober each others methods.
{
    my $bar = "get_bar";

    my $app1 = YAML::AppConfig->new( string => "---\nfoo: 1\nbar: 2\n" );
    ok( $app1, "Checking object creation." );
    ok( $app1->can("get_foo"), "Checking that \$app1 has get_foo method." );
    ok( $app1->can("get_bar"), "Checking that \$app1 has get_bar method." );
    is( $app1->$bar, 2, "Checking bar1 is ok." );

    my $app2 = YAML::AppConfig->new( string => "---\nqux: 3\nbar: 5\n" );
    ok( $app2, "Checking object creation." );
    ok( $app2->can("get_qux"), "Checking that \$app2 has get_qux method." );
    ok( $app2->can("get_bar"), "Checking that \$app2 has get_bar method." );
    is( $app2->$bar, 5, "Checking bar2 is ok." );

    # Make sure we didn't clober each other.
    is( $app1->$bar, 2, "Checking that value of bar1 in app1 is the same." );
    is( $app2->$bar, 5, "Checking that value of bar2 in app1 is the same." );
}

# TEST: Make sure we don't get warnings on undef. values
{
    my $app = YAML::AppConfig->new( string => "---\nnovalue:\n" );
    ok($app, "Object created");
    local $SIG{__WARN__} = sub { die };
    eval { $app->get_novalue };
    ok( !$@, "Getting a setting with no value does not produce warnings." );
}
