#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval 'use Test::WWW::Mechanize';
    plan( skip_all => 'Test::WWW::Mechanize required for testing connection' )
      if $@;
}

use XML::Parser::EasyTree;
use Test::WWW::Mechanize;
use XML::Parser;

$XML::Parser::EasyTree::Noempty = 1;

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech, 'Test::WWW::Mechanize' );
can_ok( 'Test::WWW::Mechanize', qw(get_ok content) );

$mech->get_ok( 'https://webservices.netsuite.com/wsdl/v2013_1_0/netsuite.wsdl',
    'Accessing NetSuite WSDL v2013_1' );

my $p = new XML::Parser( Style => 'EasyTree' );
isa_ok( $p, 'XML::Parser' );
can_ok( 'XML::Parser', qw(parse) );

my $wsdl = $p->parse( $mech->content );
for my $node ( @{ $wsdl->[0]->{content}->[0]->{content}->[0]->{content} } ) {
    my $namespace = $node->{attrib}->{namespace};
    $mech->get_ok(
        $node->{attrib}->{schemaLocation},
        'Accessing Namespace ' . $namespace
    );
}

done_testing();
