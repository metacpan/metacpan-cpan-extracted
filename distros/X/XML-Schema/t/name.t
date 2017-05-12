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
# $Id: name.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Parser;
use XML::Schema::Instance;

#ntests(9);

my $DEBUG = 0;
$XML::Schema::DEBUG = $DEBUG;
$XML::Schema::Parser::DEBUG = $DEBUG;
$XML::Schema::Instance::DEBUG = $DEBUG;
$XML::Schema::Element::DEBUG = $DEBUG;
$XML::Schema::Scope::DEBUG = $DEBUG;

my @dir  = grep(-d, qw( t/xml xml  ));
my $dir  = shift @dir || die "Cannot grok XML directory\n";
my $file = "$dir/name.xml";

my $schema = XML::Schema->new();
ok( $schema );

ok( $schema->element( name => 'name', type => 'string' ),
    $schema->error() );

my $parser = $schema->parser();
ok( $parser, $schema->error() );

my $result = $parser->parsefile($file);
assert( $result, $parser->error() );

print "result: $result\n";



