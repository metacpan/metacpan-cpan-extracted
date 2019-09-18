#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use X::Tiny::Base;

sub put_error_in_array {
    my ($array_ar) = @_;

    my $err = X::Tiny::Base->new('no leaks');

    push @$array_ar, $err;
}

my $array_obj = bless [], 'Thing';

put_error_in_array($array_obj);

my $array_obj_str = "$array_obj";

undef $array_obj;

is_deeply( \@Thing::DESTROYED, [$array_obj_str], 'DESTROY called' );

done_testing();

#----------------------------------------------------------------------

package Thing;

our @DESTROYED;

sub DESTROY {
    my $self = shift;

    push @DESTROYED, "$self";
}

1;
