#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 4;

use lib 't';
use tlib;


eval q{
    package My::Class;

    # import some function
    use Scalar::Util 'looks_like_number';

    # collect the names of all previously created functions
    use namespace::functions;

    # our function uses imported function
    sub is_num {
        my ($self, $val) = @_;
        return looks_like_number("$val");
    }

    # delete all previously collected functions
    no namespace::functions;

    # our package doesn't provide imported function anymore!
};
is($@, '', 'My::Class is ok');

ok( My::Class->is_num(123), 'My::Class->is_num(123) is ok' );
ok( !My::Class->is_num("abc"), 'My::Class->is_num("abc") is ok' );
is_deeply( list_subroutines("My::Class"), [ qw( is_num ) ], 'namespace is ok' );
