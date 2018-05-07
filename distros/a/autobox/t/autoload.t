#!/usr/bin/env perl

# confirm method autoloading works

use strict;
use warnings;

use Test::Fatal qw(exception);
use Test::More tests => 6;

our $AUTOLOAD;

my $scalar = 42;
my $array = [];
my $hash = {};
my $error = q{^Can't (call|locate object) method "%s"};

sub error {
    my $message = sprintf($error, shift);
    qr{$message};
}

sub AUTOLOAD {
    return [ @_, $AUTOLOAD ];
}

# confirm autoloaded methods work if autobox is enabled
{
    use autobox {
        SCALAR => __PACKAGE__,
        ARRAY  => __PACKAGE__,
        HASH   => __PACKAGE__,
    };

    is_deeply $scalar->foo, [ $scalar, 'main::foo' ];
    is_deeply $array->bar,  [ $array,  'main::bar' ];
    is_deeply $hash->baz,   [ $hash,   'main::baz' ];
}

# confirm they don't work if autobox is not enabled
{
    like exception { $scalar->foo }, error('foo');
    like exception { $array->bar }, error('bar');
    like exception { $hash->baz }, error('baz');
}
