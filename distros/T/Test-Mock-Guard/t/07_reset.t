use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class::One;

sub new { bless {} => shift }
sub foo { "foo" }

package Some::Class::Two;

sub new { bless {} => shift }
sub bar { "bar" }

package main;

my $obj = Some::Class::One->new;
my $obj2 = Some::Class::Two->new;

{
    note 'basic';
    my $guard1 = mock_guard('Some::Class::One' => { foo => 'bar' });
    is $obj->foo, 'bar', 'foo at guard1';
    $guard1->reset('Some::Class::One' => [qw/foo/]);
    is $obj->foo, 'foo', 'foo restored';
}

is $obj->foo, 'foo', 'foo';

{
    note 'repeat';
    my $guard1 = mock_guard('Some::Class::One' => { foo => 'bar' });
    is $obj->foo, 'bar', 'foo at guard1';
    $guard1->reset('Some::Class::One' => [qw/foo/]);
    is $obj->foo, 'foo', 'foo restored';
    $guard1->reset('Some::Class::One' => [qw/foo/]);
    is $obj->foo, 'foo', 'foo restored';
}

is $obj->foo, 'foo', 'foo';

{
    note 'reoverride';
    my $guard1 = mock_guard('Some::Class::One' => { foo => 'bar' });
    is $obj->foo, 'bar', 'foo at guard1';
    my $guard2 = mock_guard('Some::Class::One' => { foo => 'baz' });
    is $obj->foo, 'baz', 'foo at guard2';
    $guard1->reset('Some::Class::One' => [qw/foo/]);
    is $obj->foo, 'baz', 'foo restored but alived guard2';
    $guard2->reset('Some::Class::One' => [qw/foo/]);
    is $obj->foo, 'foo', 'foo restored';
}

is $obj->foo, 'foo', 'foo';

{
    note 'dual';
    my $guard1 = mock_guard(
        'Some::Class::One' => { foo => 'bar' },
        'Some::Class::Two' => { bar => 'baz' },
    );
    is $obj->foo, 'bar', 'foo at guard1';
    is $obj2->bar, 'baz', 'bar at guard1';

    $guard1->reset(
        'Some::Class::One' => [qw/foo/],
        'Some::Class::Two' => [qw/bar/],
    );

    is $obj->foo, 'foo', 'foo restored';
    is $obj2->bar, 'bar', 'bar restored';
}

is $obj->foo, 'foo', 'foo';
is $obj2->bar, 'bar', 'bar';

{
    note 'mixed';
    my $guard1 = mock_guard(
        'Some::Class::One' => { foo => 'bar' },
        $obj2, { bar => 'baz' },
    );
    is $obj->foo, 'bar', 'foo at guard1';
    is $obj2->bar, 'baz', 'bar at guard1';

    $guard1->reset(
        'Some::Class::One' => [qw/foo/],
        $obj2, [qw/bar/],
    );

    is $obj->foo, 'foo', 'foo restored';
    is $obj2->bar, 'bar', 'bar restored';
}

is $obj->foo, 'foo', 'foo';
is $obj2->bar, 'bar', 'bar';

done_testing;
