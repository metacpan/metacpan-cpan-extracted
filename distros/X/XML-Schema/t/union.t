#============================================================= -*-perl-*-
#
# t/union.t
#
# Test the union type.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: union.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Type::Builtin;
use XML::Schema::Type::Union;

ntests(13);

my $DEBUG = 0;
$XML::Schema::Type::Union::DEBUG = $DEBUG;
$XML::Schema::Type::Simple::DEBUG = $DEBUG;

my ($pkg, $union, $item);

my $float = XML::Schema::Type::float->new();
my $time  = XML::Schema::Type::time->new();
my $int   = XML::Schema::Type::int->new();

$pkg = 'XML::Schema::Type::Union';

ok( ! $pkg->new() );
match( $pkg->error(), "$pkg: memberTypes not specified" );

$union = $pkg->new( memberTypes => [ $int, $time, $float ] );
ok( $union );

match( $union->variety(), 'union' );

$item = $union->instance('');
ok( ! $item );

$item = $union->instance('23');
ok( $item );
#print '{ ', $union->_dump_hash($item->{ value }), " }\n";

$item = $union->instance('23:45:56');
ok( $item );
#print '{ ', $union->_dump_hash($item->{ value }), " }\n";

$item = $union->instance('23.45');
ok( $item );
#print '{ ', $union->_dump_hash($item->{ value }), " }\n";

$item = $union->instance('123.34.45');
ok( !$item );
match( $union->error(), 
       'invalid union: int: value is not a decimal, '
     . 'time: value is not a valid date, float: value is not a valid float' );

$union->constrain( pattern => '12:\d{2}:\d{2}' );

$item = $union->instance('23.45');

ok( ! $item );
match( $union->error(), 'string mismatch (required pattern: 12:\d{2}:\d{2})' );

$item = $union->instance('12:36:45');
ok( $item );


