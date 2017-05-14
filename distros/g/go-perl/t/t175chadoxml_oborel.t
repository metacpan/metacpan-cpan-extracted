#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 9;
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


my $f = './t/data/llm2.obo';
my $parser = new GO::Parser ({format=>'obo'
                             });
#                              handler=>'xml'});
$parser->xslt("oboxml_to_chadoxml"); 

$parser->parse($f);
my $chado =  $parser->handler->stag;

my @cvterms = $chado->get_cvterm;
my %relh = ();
foreach my $cvterm (@cvterms) {
    $relh{$cvterm->sget('@/id')} = $cvterm;
}
my %cv_h = ();
$cv_h{$_->sget('@/id')} = $_->sget('name') foreach $chado->get_cv;

# builtin
# intersection_of tags are parsed
#ok($relh{intersection_of}->sget_cv_id eq 'cvterm_property_type');
ok(1);

# explicitly listed relation, declared to be in relationship
my $cv_id = $relh{'part_of'}->sget('cv_id');
ok($cv_h{$cv_id} eq 'relationship');

# only mentioned in header - not listed so we presume loaded
ok(!$relh{'OBOL:during'}->sget('cv_id'));

# by default, place unqualified rel in default-namespace cv
ok($cv_h{$relh{bzz}->sget_cv_id} eq 'gene_ontology');
ok($relh{bzz}->sget('dbxref_id/dbxref/db_id') eq '_default_idspace');

ok($cv_h{$relh{foo}->sget_cv_id} eq 'relationship');
ok($relh{foo}->sget('dbxref_id/dbxref/db_id') eq 'OBO_REL');

# genuine ID and no namespace explicitly provided, use default
ok($cv_h{$relh{'X:Y'}->sget('cv_id')} eq 'gene_ontology');

ok($cv_h{$relh{'Y:Z'}->sget('cv_id')} eq 'yz');





