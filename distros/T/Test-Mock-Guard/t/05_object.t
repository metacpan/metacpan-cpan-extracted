use strict;
use warnings;

use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;
sub new { bless {} => shift }
sub foo { "foo" }
sub bar { 1 }

package main;

my $obj1 = Some::Class->new;
my $obj2 = Some::Class->new;
{
        my $guard1 = mock_guard($obj1, { foo => sub { "bar" }, bar => 10 } );
        is $obj1->foo, "bar";
        is $obj1->bar, 10;

        my $guard2 = mock_guard($obj2, { foo => sub { "baz" }, bar => 20 } );
        is $obj2->foo, "baz";
        is $obj2->bar, 20;

        is $obj1->foo, "bar";
        is $obj1->bar, 10;

        my $another = Some::Class->new;
        is $another->foo, "foo";
        is $another->bar, 1;
}

is $obj1->foo, "foo";
is $obj1->bar, 1;

is $obj2->foo, "foo";
is $obj2->bar, 1;

my $outofscope = Some::Class->new;
is $outofscope->foo, "foo";
is $outofscope->bar, 1;

done_testing;
