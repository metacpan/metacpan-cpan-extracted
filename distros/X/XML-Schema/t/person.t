#!/usr/bin/perl -w                                         # -*- perl -*-
#============================================================= -*-perl-*-
#
# t/person.t
#
# Test various XML::Schema modules by parsing an external XML
# file containing a simple person element.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: person.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Parser;
use XML::Schema::Particle;
use XML::Schema::Particle::Sequence;
use XML::Schema::Instance;
use XML::Schema::Handler::Complex;
use XML::Schema::Handler::Simple;

#ntests(8);

my $DEBUG = grep '-d', @ARGV;
$DEBUG = 3 if $DEBUG;
#$XML::Schema::DEBUG = $DEBUG;
#$XML::Schema::Parser::DEBUG = $DEBUG;
#$XML::Schema::Instance::DEBUG = $DEBUG;
#$XML::Schema::Element::DEBUG = $DEBUG;
#$XML::Schema::Scope::DEBUG = $DEBUG;
$XML::Schema::Handler::Complex::DEBUG = $DEBUG;
$XML::Schema::Handler::Simple::DEBUG = $DEBUG;
$XML::Schema::Particle::DEBUG = $DEBUG;
$XML::Schema::Particle::Sequence::DEBUG = $DEBUG;

my @dir  = grep(-d, qw( t/xml xml  ));
my $dir  = shift @dir || die "Cannot grok XML directory\n";
my $file = "$dir/person.xml";

my $schema = XML::Schema->new();
ok( $schema );

my $person = $schema->complexType( name => 'personType' );
ok( $person, $schema->error() );
my $name = $person->element( name => 'name', type => 'string' );
ok( $name, $person->error() );
my $id = $person->attribute( name => 'id', type => 'string' );
ok( $id, $person->error() );
my $emailt = $person->simpleType( name => 'emailType', base => 'string' );
ok( $emailt, $person->error() );
my $email = $person->element( name => 'email', type => $emailt );
ok( $email, $person->error() );

$emailt->schedule_instance(sub {
    my ($node, $infoset) = @_;
    $infoset->{ result } = "  Email: $infoset->{ result }";
});

#$person->schedule_end_element(sub {
#    my ($node, $infoset) = @_;
#    print "got here: ", $emailt->_inspect($infoset->{ content }), "\n";
##    $infoset->{ result } = "$infoset->{ result }";
#    return 1;
#});


ok( $person->content(
    sequence => [{
	element => $name,
	min => 1,
	max => 1,
    },{
	element => $email,
	min => 0, 
	max => 3,
    }],
    max => 5,
), $person->error() );

ok( $schema->element( name => 'person', type => 'personType' ),
    $schema->error() );

my $parser = $schema->parser();
ok( $parser, $schema->error() );

my $result = $parser->parsefile($file);
assert( $result, $parser->error() );

#print join("\n", @{ $result->{ content } });
#print "OUT: @{$result->{ content }}\n";
#print "result: ", $parser->_dump_ref($result), "\n";
#print "attributes: ", $parser->_dump_ref($result->{ attributes }), "\n";
#print "content: ", $parser->_inspect($result->{ content }), "\n";

