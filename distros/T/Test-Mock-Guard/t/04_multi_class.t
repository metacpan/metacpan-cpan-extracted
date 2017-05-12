use strict;
use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class::One;

sub new { bless {} => shift }
sub foo { "foo" }
sub bar { 1 }

package Some::Class::Two;

sub new { bless {} => shift }
sub hoge { "hoge" }
sub fuga { 2 }

package main;

{
    my $guard = mock_guard(
        'Some::Class::One', {
            foo => sub { "bar" },
            bar => 10,
        },
        'Some::Class::Two', {
            hoge => sub { "fuga" },
            fuga => 20,
        },
    );

    my $one = Some::Class::One->new;
    is $one->foo, 'bar', 'foo';
    is $one->bar, 10, 'bar';

    my $two = Some::Class::Two->new;
    is $two->hoge, 'fuga', 'hoge';
    is $two->fuga, 20, 'fuga';
}

my $one = Some::Class::One->new;
is $one->foo, 'foo', 'foo';
is $one->bar, 1, 'bar';

my $two = Some::Class::Two->new;
is $two->hoge, 'hoge', 'hoge';
is $two->fuga, 2, 'fuga';

done_testing;
