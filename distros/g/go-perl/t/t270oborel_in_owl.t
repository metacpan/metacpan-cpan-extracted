#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 4;
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => NUMTESTS;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    for (1..NUMTESTS) {
        skip("XML::Parser::PerlSAX not installed",1);
    }
    exit 0;
}
eval {
    require "XML/Writer.pm";
};
if ($@) {
    for (1..NUMTESTS) {
        skip("XML::Writer not installed",1);
    }
    exit 0;
}

# ----- REQUIREMENTS -----

# ------------------------


my $f = './t/data/go-with-local-id-mapping.obo';
my $parser = new GO::Parser ({format=>'obo'
                             });
#                              handler=>'xml'});
$parser->xslt("oboxml_to_owl"); 

$parser->parse($f);
my $owl =  $parser->handler->stag;


# explicitly listed relation, declared to be in relationship
my $part_of = $owl->get('owl:TransitiveProperty');
print $part_of->sxpr;
ok($part_of);

print $part_of->sget('@/rdf:about'). "\n";
ok($part_of->sget('@/rdf:about') eq 'http://purl.org/obo/owl/OBO_REL#part_of');

my ($foo) = $owl->qmatch('owl:ObjectProperty','@/rdf:about','http://purl.org/obo/owl/obo#foo');
print $foo->sxpr;
ok($foo->sget('@/rdf:about') eq 'http://purl.org/obo/owl/obo#foo');

my ($bar) = $owl->where('owl:AnnotationProperty',sub {shift->sget('@/rdf:about') eq 'http://purl.org/obo/owl/obo#bar'});
print $bar->sxpr;
ok($bar->sget('@/rdf:about') eq 'http://purl.org/obo/owl/obo#bar');

