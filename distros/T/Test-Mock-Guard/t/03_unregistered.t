use strict;
use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;

sub new { bless {} => shift }
sub foo { "foo" }
sub bar { 1; }

package main;

{
    my $guard = mock_guard('Some::Class', {
        foo => sub { "bar" },
        bar => 10,
        baz => 20,
    });
    my $obj = Some::Class->new;
    is $obj->foo, 'bar', 'foo';
    is $obj->bar, 10, 'bar';
    is $obj->baz, 20, 'baz';
}

my $obj = Some::Class->new;
is $obj->foo, "foo";
is $obj->bar, 1;
eval { $obj->baz };
like $@, qr/Can't locate .*baz/, 'method unregistered';

done_testing;
