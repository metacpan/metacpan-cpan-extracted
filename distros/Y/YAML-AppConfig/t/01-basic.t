use strict;
use warnings;
use Test::More tests => 21;
do "t/lib/helpers.pl";

BEGIN { use_ok('YAML::AppConfig') }

# TEST: Object creation from a file.
{
    my $app = YAML::AppConfig->new( file => "t/data/basic.yaml" );
    ok( $app, "Instantiated object from file." );
    isa_ok( $app, "YAML::AppConfig", "Asserting isa YAML::AppConfig" );
    my $c = 1;
    for my $var (qw(foo bar)) {
        is( $app->get($var), $c, "Retrieving value for $var." );
        my $method = "get_$var";
        ok( $app->can($method), "Checking that \$app can get_$var." );
        is( $app->$method($var), $c, "Retrieving $var with $method." );
        $c++;
    }

    $app->set("bar", 99);
    is($app->get("bar"), 99, "Setting bar, type set().");
    $app->set_bar(101);
    is( $app->get("bar"), 101, "Setting bar, type set_bar()." );
}

# TEST: Object creation from string.
{
    my $app = YAML::AppConfig->new( string => slurp("t/data/basic.yaml") );
    ok( $app, "Instantiated object from string." );
    isa_ok( $app, "YAML::AppConfig", "Asserting isa YAML::AppConfig" );
    my $c = 1;
    for my $var (qw(foo bar)) {
        is( $app->get($var), $c, "Retrieving value for $var." );
        my $method = "get_$var";
        ok( $app->can($method), "Checking that \$app can get_$var." );
        is( $app->$method($var), $c, "Retrieving $var with $method." );
        $c++;
    }

    $app->set("bar", 99);
    is($app->get("bar"), 99, "Setting bar, type set().");
    $app->set_bar(101);
    is( $app->get("bar"), 101, "Setting bar, type set_bar()." );
}
