#!/usr/bin/env perl

use warnings;
use strict;

use File::Spec;

use lib 'lib', 't';
use TestTools;
use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 22;

our $xmlfile = XML::Compile->findSchemaFile('2001-XMLSchema.xsd');

ok(-r $xmlfile,  'find demo file');

my $parser = XML::LibXML->new;
my $doc    = $parser->parse_file($xmlfile);
ok(defined $doc, 'parsing schema');
isa_ok($doc, 'XML::LibXML::Document');

my $defs  = XML::Compile::Schema->new($doc);
ok(defined $defs);

my $namespaces  = $defs->namespaces;
isa_ok($namespaces, 'XML::Compile::Schema::NameSpaces');

my @ns      = $namespaces->list;
cmp_ok(scalar(@ns), '==', 1, 'one target namespace');
my $ns = shift @ns;
is($ns, $SchemaNS);

my @schemas = $namespaces->namespace($ns);
ok(scalar(@schemas), 'found ns');

@schemas
   or die "no schemas, so no use to continue";

cmp_ok(scalar(@schemas), '==', 1, "one schema");
my $schema = $schemas[0];

my $list = '';
open OUT, '>', \$list or die $!;
$_->printIndex(\*OUT) for @schemas;
close OUT;
#warn $list;

my @types   = split /\n/, $list;
is(shift(@types), "namespace: $SchemaNS");
is(shift(@types), "   source: XML::LibXML::Document");
cmp_ok(scalar(@types), '==', 150);

my $random = (sort @types)[42];
is($random, '    derivationControl');

cmp_ok(scalar($schema->simpleTypes),     '==', 55);
cmp_ok(scalar($schema->complexTypes),    '==', 35);
cmp_ok(scalar($schema->groups),          '==', 12);
cmp_ok(scalar($schema->attributeGroups), '==',  2);
cmp_ok(scalar($schema->elements),        '==', 41);
cmp_ok(scalar($schema->attributes),      '==',  0);
#cmp_ok(scalar($schema->notations),      '==',  2);

my $testtype = '{http://www.w3.org/2001/XMLSchema}derivationControl';
my $lookup = $schema->find(simpleType => $testtype);
ok(defined $lookup, 'found simpleType');
is(ref $lookup, 'HASH');
ok(!$schema->find(complexType => $testtype));
