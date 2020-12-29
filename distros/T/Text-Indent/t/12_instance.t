use strict;
use warnings;

use Test::More;
plan tests => 9;

my $class = 'Text::Indent';
use_ok($class);

my %default_parameters = (
    Spaces => 1,
    Level  => 0,
);

my %original_indent = (
    obj        => undef,
    parameters => undef,
);

INSTANCE_DOESNT_EXIST: {
    note("if instance doesn't exist");

    $original_indent{parameters}{Spaces} = $default_parameters{Spaces} + 1;
    $original_indent{parameters}{Level}  = $default_parameters{Level} + 1;

    # construct a new instance.
    $original_indent{obj} = $class->instance($original_indent{parameters});

    isa_ok($original_indent{obj}, $class);

    subtest 'instance args are passed to the constructor' => sub {
        plan tests => 2;
        is($original_indent{obj}->spaces, $original_indent{parameters}{Spaces}, "'spaces' is set to the new instance value");
        is($original_indent{obj}->level, $original_indent{parameters}{Level}, "'level' is set to the new instance value");
    };
}

INSTANCE_DOES_EXIST: {
    note('if instance does exist');

    my %parameters = (
        Spaces => $default_parameters{Spaces} + 2,
        Level  => $default_parameters{Level} + 2,
    );

    # use the existing instance, passed args will be lost.
    my $indent = $class->instance(%parameters);

    isa_ok($indent, $class);

    subtest 'instance args are not passed to the constructor' => sub {
        plan tests => 2;
        is($indent->spaces, $original_indent{parameters}{Spaces}, "'spaces' is set to the original instance value");
        is($indent->level, $original_indent{parameters}{Level}, "'level' is set to the original instance value");
    };

    is_deeply($indent, $original_indent{obj}, 'instance is the original instance');
}

INSTANCE_PARAMETER_IS_OFF: {
    note('if instance parameter is off');

    # construct a new instance with Instance parameter set to false.
    # the new object with Instance false will not become the new singleton.
    my $new_indent = $class->new(
        %default_parameters,
        Instance => 0,
    );

    my %parameters = (
        Spaces => $default_parameters{Spaces} + 3,
        Level  => $default_parameters{Level} + 3,
    );

    # use the existing (original) instance, passed args will be lost.
    my $indent = $class->instance(%parameters);

    isa_ok($indent, $class);

    subtest 'instance args are not passed to the constructor' => sub {
        plan tests => 2;
        is($indent->spaces, $original_indent{parameters}{Spaces}, "'spaces' is set to the original instance value");
        is($indent->level, $original_indent{parameters}{Level}, "'level' is set to the original instance value");
    };

    is_deeply($indent, $original_indent{obj}, 'instance is the original instance');
}
