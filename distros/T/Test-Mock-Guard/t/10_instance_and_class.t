use strict;
use warnings;

use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;
sub new { bless {} => shift }
sub foo { "foo" }

package main;

my $obj = Some::Class->new;

is $obj->foo, 'foo';
is Some::Class::foo, 'foo';

{
    my $guard = mock_guard($obj, { foo => sub { "bar" } } );
    is $obj->foo, 'bar';
    is Some::Class::foo($obj), 'bar';
    is Some::Class::foo, 'foo';
};

is $obj->foo, 'foo';
is +Some::Class::foo, 'foo';

done_testing;
