#!/usr/bin/perl -w                                         # -*- perl -*-
#============================================================= -*-perl-*-
#
# t/id.t
#
# Test ID and IDREF simple types.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: id.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema;
use XML::Schema::Attribute::Group;
use XML::Schema::Handler::Complex;

#ntests(5);

my $DEBUG = grep(/-d/, @ARGV);
$XML::Schema::Attribute::Group::DEBUG = $DEBUG;
#$XML::Schema::Instance::DEBUG = $DEBUG;

#$XML::Schema::Handler::Complex::DEBUG = $DEBUG;
#$XML::Schema::Type::Complex::DEBUG = $DEBUG;

my $schema  = XML::Schema->new();
my $ename   = $schema->element( name => 'name', type => 'string' ); 
ok( $ename, $schema->error() );

my $tperson = $schema->complexType( name        => 'personType',
				    attributes  => {
					id      => 'ID',
			    		brother => {
					      type => 'IDREF',
					      use  => 'optional',
					  }
				      },
				    element => $ename);
ok( $tperson, $schema->error() );

my $person = $schema->element( name => 'person', type => $tperson);
ok( $person, $schema->error() );

my $tpeople = $schema->complexType( name    => 'peopleType',
				    element => $person,
				    min     => 1,
				    max     => 10 );

my $people = $schema->element( name => 'people', type => $tpeople )
    || die $schema->error();

my $XML =<<EOF;
<people>
<person id="abw"><name>Andy</name></person>
<person id="cmb" brother="abw"><name>Craig</name></person>
</people>
EOF

my $parser = $schema->parser();
ok( $parser, $schema->error() );

my $result = $parser->parse($XML);
ok( $result, $parser->error() );

my $bro  = $result->{ content }->[1]->{ attributes }->{ brother };
assert( ref $bro eq 'HASH', "bro don't do no hash thang" );
my $name = $bro->{ content }->[0];

match( $name, 'Andy' );
