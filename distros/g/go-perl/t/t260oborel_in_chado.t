#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 6;
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

# explicitly listed relation, declared to be in relationship
my $part_of = $relh{'part_of'};
print $part_of->xml;
ok($part_of);
my $cv_id = $part_of->sget('cv_id');
print($cv_h{$cv_id},"\n");
ok($cv_h{$cv_id} eq 'relationship');
ok($part_of->sget('dbxref_id/dbxref/db_id') eq 'OBO_REL');

ok($relh{foo});
ok($relh{foo}->sget('dbxref_id/dbxref/db_id')  eq '_default_idspace');
ok($relh{bar});
