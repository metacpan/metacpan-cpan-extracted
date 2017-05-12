use Test::More tests => 13;

BEGIN {
use_ok( 'Versionify::Dispatch' );
}

diag('Setting up and using a single dispatcher');

my $RETURN_VAL_1 = 'Hello world';
my $RETURN_VAL_2 = 'hi';
my $RETURN_VAL_3 = 3.14159;

sub func {
    return $RETURN_VAL_1;
}

my $func_ref = sub {
    return $RETURN_VAL_2;
};

is(func(), $RETURN_VAL_1, 'Sample subroutine works');
is($func_ref->(), $RETURN_VAL_2, 'Sample subref works');

my $dispatcher = Versionify::Dispatch->new(function => {
    1.11 => \&func,
    1.5 => $func_ref,
});

is($dispatcher->get_function()->(), $RETURN_VAL_1, 'Dispatcher returns the highest version function by default');
$dispatcher->set_default_version(1.5);
is($dispatcher->get_function()->(), $RETURN_VAL_2, 'Dispatcher uses the default version (if set) when no version is provided');
is($dispatcher->get_function(1.11)->(), $RETURN_VAL_1, 'Dispatcher ignores the default version when a version number is provided');
is($dispatcher->get_function(1.6)->(), $RETURN_VAL_2, 'Dispatcher returns the highest version function less than the provided one if not an exact match');

$dispatcher->set_function({1.1 => \&func});
is($dispatcher->get_function(1.6)->(), $RETURN_VAL_1, 'set_function has completely replaced the previously stored lookups');

$dispatcher->register(
    1.16 => sub {return $RETURN_VAL_3},
    1.23 => $func_ref,
);
is($dispatcher->get_function(1.16)->(), $RETURN_VAL_3, 'Dispatcher registers new function and uses them correctly');
$dispatcher->set_default_version(1.25);
is($dispatcher->get_function()->(), $RETURN_VAL_2, 'Dispatcher registers new function and uses them correctly (with fallback from default)');
is($dispatcher->get_function(1.5)->(), $RETURN_VAL_1, 'Newly registered functions do not interfere with previously registered functions');

$dispatcher->set_function({});
eval {$dispatcher->get_function()};
like($@, qr/^No valid functions stored/, 'set_function removes the old registered functions');

my $new_dispatcher = Versionify::Dispatch->new();
$new_dispatcher->register(
    1.0 => $func_ref,
);
is($new_dispatcher->get_function()->(), $RETURN_VAL_2, 'Dispatcher registers new function and uses them correctly when no functions had been set before first register() call');
