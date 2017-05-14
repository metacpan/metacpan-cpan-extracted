#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 3;
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => NUMTESTS;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# goflat format files using !type: headers should be parsed
# types may be odd characters

# ------------------------


if (1) {
    my $f = './t/data/test2.ontology';
    my $parser = new GO::Parser;
    $parser->parse($f);
    my $obo = $parser->handler->stag;
    my @typedefs = $obo->get_typedef;
    my %th = map {$_->sget_id => 1} @typedefs;
    ok(scalar (@typedefs),5);
    my @terms = $obo->get_term;
    ok(scalar (@terms),7);
    print $_->sxpr foreach @terms;
    my @rels = $obo->find_relationship;
    my @bad = grep {!$th{$_->sget_type}} @rels;
    ok(!@bad);
}
