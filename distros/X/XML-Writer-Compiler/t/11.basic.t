#!/usr/bin/perl -w
use strict;

use t::lib::T;
use t::lib::U;

my $compiler = XML::Writer::Compiler->new;

my $tree = XML::TreeBuilder->new( { 'NoExpand' => 0, 'ErrorContext' => 0 } );
$tree->parse_file('t/sample.xml');

my $pkg = 't::lib::My::Pkg';
my $class = $compiler->buildclass( $pkg, $tree, 0, '' );

Class::MOP::load_class($pkg);

my %data = (
    note => {
        to => { person => 'Satan' },
        from => [ [ via => 'postcard', russia => 'with love' ], 'moneypenny' ]
    }
);


my $xmlclass = $pkg->new(data => \%data);


my $xml = $xmlclass->xml->string->value;
my $exp =
'<note><to><person>Satan</person></to><from via="postcard" russia="with love">moneypenny</from><heading></heading><body></body></note>';

is_xml( $xml, $exp, 'test xml generation' );
done_testing;
