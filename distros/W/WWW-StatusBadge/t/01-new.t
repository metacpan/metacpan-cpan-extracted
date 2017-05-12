#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Scalar::Util ();

require 't/common.pl';

my $object = common_object();

# BEGIN: 1 check object class
is( ref $object, common_class(), 'object class' );

# BEGIN: 2 new from object
isnt(
    Scalar::Util::refaddr( $object ),
    Scalar::Util::refaddr( $object->new( common_args() ) ),
    'new from object'
);

# BEGIN: 3 new as function
{
    no strict 'refs';
    my $function = join '::', common_class(), 'new';
    is(
        ref $function->( undef, common_args() ),
        common_class(),
        'new as function'
    );
}
