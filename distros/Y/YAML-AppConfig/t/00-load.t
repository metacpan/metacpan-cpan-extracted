use strict;
use warnings;
use Test::More tests => 28;
do "t/lib/helpers.pl";
use lib 't/lib';

BEGIN { use_ok('YAML::AppConfig') }

my $SKIP_NUM = 0;
test_load("YAML");
test_load("YAML::Syck");
ok($SKIP_NUM < 2, "Asserting at least one YAML parser was tested");

sub test_load {
    my $class = shift;
SKIP: {
    delete $INC{'YAML/Syck.pm'};
    delete $INC{'YAML.pm'};
    eval "require $class; 0;";
    if ($@) {
        $SKIP_NUM++;
        skip "$class did not load, this might be ok.", 13 
    } else {
        ok(1, "Testing $class");
    }

# TEST: Object creation
{
    my $app = YAML::AppConfig->new();
    ok($app, "Instantiated object");
    is($app->{yaml_class}, $class, "Testing class is right.");
    isa_ok( $app, "YAML::AppConfig", "Asserting isa YAML::AppConfig" );
    ok( $app->can('new'), "\$app has new() method." );
}

# TEST: Loading a different YAML class, string.
{
    my $test_class = 'MatthewTestClass';
    my $app = YAML::AppConfig->new(string => "cows", yaml_class => $test_class);
    ok($app, "Instantiated object");
    is($app->{yaml_class}, $test_class, "Testing class is right.");
    isa_ok( $app, "YAML::AppConfig", "Asserting isa YAML::AppConfig." );
    is($app->get_string, "cows", "Testing alternate YAML class (stirng).");
}

# TEST: Loading a different YAML class, file.
{
    my $test_class = 'MatthewTestClass';
    my $app = YAML::AppConfig->new(file => "dogs", yaml_class => $test_class);
    ok($app, "Instantiated object");
    is($app->{yaml_class}, $test_class, "Testing class is right.");
    isa_ok( $app, "YAML::AppConfig", "Asserting isa YAML::AppConfig." );
    is($app->get_file, "dogs", "Testing alternate YAML class (file).");
}

} # end SKIP
} # end SUB
