#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 13;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    for (1..13) {
        skip("XML::Parser::PerlSAX not installed",1);
    }
    exit 0;
}

# ----- REQUIREMENTS -----

# checks godb_prestore mapping

# ------------------------

my $f =
  shift @ARGV || "./t/data/gene_association.goa_test";
my $parser = new GO::Parser ({format=>'go_assoc'});
$parser->cache_errors;
$parser->xslt('oboxml_to_godb_prestore');
ok(1);
$parser->parse ($f);
ok(1);
print "We expect some parse errors; here they are:\n";
my @errs = $parser->errlist;
print $_->sxpr foreach @errs;
ok(scalar @errs, 9); # we expect errors - different taxa same gene product

# check the resulting XML to go into DB
#
# note that we expect half the assocs to be filtered because of
# the two different taxa
my $stag = $parser->handler->stag;
print $stag->xml;
my @prods = $stag->find_gene_product;
ok(@prods == 1);
my $prod = shift @prods;
ok($prod->get_symbol eq 'SLYA_YERPE');
ok($prod->get_full_name eq 'Transcriptional regulator slyA');
ok($stag->get('gene_product/dbxref/xref_key'), 'Q9AM39');
ok($stag->get('gene_product/type/term/name'), 'protein');
ok($stag->get('gene_product/species/ncbi_taxa_id'), 632);
my @source_dbs = $stag->get('gene_product/association/source_db/db/name');
ok(scalar(@source_dbs), 5);
ok(scalar (grep {$_ eq 'UniProt'} @source_dbs), 5);
ok(scalar (grep {$_ eq '20040915'} $stag->get('gene_product/association/assocdate')), 5);
ok(scalar (grep {$_ eq 'IEA'} $stag->get('gene_product/association/evidence/code')), 9);

