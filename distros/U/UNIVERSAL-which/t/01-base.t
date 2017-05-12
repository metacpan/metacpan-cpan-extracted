use strict;
use warnings;
use UNIVERSAL::which;
use Test::More;
package Foo;
use Carp;
our $DEBUG = 0;
sub DESTROY {};
sub foo{
    my $self = shift;
    $self->{foo} = shift if @_;
    $self->{foo};
}
package Bar;
use base 'Foo';
sub new { bless {}, shift };
package main;
plan tests => 3;
my $u = Bar->new;
is($u->which('new'), 'Bar::new');
is($u->which('foo'), 'Foo::foo');
is($u->which('bar'), undef);

