#============================================================= -*-perl-*-
#
# t/parser.t
#
# Test the XML::Schema::Parser module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# TODO: want to try having the handlers messing around with 
# the stack, pushing new objects on, etc.
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: parser.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;

ntests(9);

my $DEBUG = 0;
#$XML::Schema::Parser::DEBUG = 1;
$XML::Schema::Scope::DEBUG = $DEBUG;

my @dir = grep(-d, qw( t/xml xml ));
my $dir = shift @dir || die "Cannot grok XML directory\n";
my $xperson = "$dir/person.xml";

my $schema = XML::Schema->new();
ok( $schema );

my $complex = $schema->complexType( name => 'personType', empty => 1 );
ok( $complex, $schema->error() );

ok( $schema->simpleType( name => 'idType', 
			 base => 'string',
			 maxLength => 6 ),
    $schema->error() 
);

my $ptype = $schema->complexType( name => 'personType', empty => 1 );
ok( $ptype, $schema->error()  );
ok( $ptype->attribute( name => 'id', type => 'idType' ) );

match( $ptype->attribute('id')->typename(), 'idType' );
match( $ptype->attribute('id')->type->name(), 'idType' );

my $name = $ptype->complexType( name => 'nameType', empty => 1 );
ok( $name, $ptype->error() );

my $string = $ptype->simpleType( base => 'string' );
ok( $string, $ptype->error() );

