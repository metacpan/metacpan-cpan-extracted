#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw(no_plan);
use_ok('XML::Validator::Schema') or exit;

use XML::SAX::ParserFactory;
$XML::SAX::ParserPackage = 'XML::SAX::ExpatXS';

# test requires XML::SAX::ExpatXS and XML::Filter::ExceptionLocator
eval { require XML::SAX::ExpatXS };
my $has_expatxs = $@ ? 0 : 1;
eval { require XML::Filter::ExceptionLocator };
my $has_el = $@ ? 0 : 1;

SKIP: {
    skip 'These tests require XML::SAX::ExpatXS', 1 unless $has_expatxs;
    skip 'These tests require XML::Filter::ExceptionLocator', 1 unless $has_el;
    
    my $v = XML::Validator::Schema->new(file => 't/test.xsd');
    ok($v);
    my $p = XML::SAX::ParserFactory->parser(Handler => $v);
    ok($p);
    
    # parse a file with an error on line 6
    eval { $p->parse_uri('t/bad.xml') };
    isa_ok($@, 'XML::SAX::Exception');
    is($@->{LineNumber}, 6);
    ok($@->{ColumnNumber} >= 11);
    like($@, qr/\[Ln: 6/);

    # now a bad XSD
    eval { $v = XML::Validator::Schema->new(file => 't/bad.xsd') };
    isa_ok($@, 'XML::SAX::Exception');
    is($@->{LineNumber}, 4);
    ok($@->{ColumnNumber} >= 6);
    like($@, qr/\[Ln: 4/);
};
