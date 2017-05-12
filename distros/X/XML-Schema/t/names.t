#!/usr/bin/perl -w                                         # -*- perl -*-
#============================================================= -*-perl-*-
#
# t/name.t
#
# Test various XML::Schema modules by parsing an external XML
# file containing a simple element.
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
# $Id: names.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Parser;
use XML::Schema::Particle;
use XML::Schema::Instance;
use XML::Schema::Handler::Complex;

ntests(8);

my $DEBUG = grep '-d', @ARGV;
$DEBUG = 3 if $DEBUG;
$XML::Schema::DEBUG = $DEBUG;
$XML::Schema::Parser::DEBUG = $DEBUG;
$XML::Schema::Instance::DEBUG = $DEBUG;
$XML::Schema::Element::DEBUG = $DEBUG;
$XML::Schema::Scope::DEBUG = $DEBUG;
$XML::Schema::Handler::Complex::DEBUG = $DEBUG;
$XML::Schema::Particle::DEBUG = $DEBUG;

my @dir  = grep(-d, qw( t/xml xml  ));
my $dir  = shift @dir || die "Cannot grok XML directory\n";
my $file = "$dir/names.xml";

my $schema = XML::Schema->new();
ok( $schema );

my $namet = $schema->simpleType( name => 'nameType', type => 'string' );
ok( $namet, $schema->error() );

my $names = $schema->complexType( name => 'namesType' );
my $name  = $names->element( name => 'name', type => 'nameType' );
ok( $name, $names->error() );

ok( $names->content( element => $name,
		     min     => 0,	
		     max     => 10  ) );
ok( $names, $schema->error() );

ok( $schema->element( name => 'names', type => $names ),
    $schema->error() );

$namet->schedule_instance(sub { 
    my ($self, $infoset) = @_;
    $infoset->{ result } = "dude: $infoset->{ result }";
});


my $parser = $schema->parser();
ok( $parser, $schema->error() );

my $result = $parser->parsefile($file);
ok( $result, $parser->error() );

#print "result: $result\n";
#print "result: ", $parser->_dump_ref($result), "\n";
#print "attributes: ", $parser->_dump_ref($result->{ attributes }), "\n";
#print "content: ", $parser->_dump_list($result->{ content }), "\n";

print join("\n", @{ $result->{ content } });
