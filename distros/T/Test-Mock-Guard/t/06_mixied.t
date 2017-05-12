use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class::One;

sub new { bless {} => shift }
sub foo { "foo" }

package Some::Class::Two;

sub new { bless {} => shift }
sub hoge { "hoge" }

package main;

my $one1 = Some::Class::One->new;
my $one2 = Some::Class::One->new;
my $two  = Some::Class::Two->new;

{
    my $guard = mock_guard(
        $one1, {
            foo => 'bar',
        },
        'Some::Class::Two' => {
            hoge => 'fuga',
        },
    );

    is $one1->foo, 'bar', 'foo at one1';
    is $one2->foo, 'foo', 'foo at one2';
    is (Some::Class::Two->hoge, 'fuga', 'hoge at Some::Class::Two');
    is $two->hoge, 'fuga', 'hoge at two';
}

is $one1->foo, 'foo', 'foo at one1 restored';
is $one2->foo, 'foo', 'foo at one2 no changed';
is $two->hoge, 'hoge', 'hoge at two restored';

done_testing;
