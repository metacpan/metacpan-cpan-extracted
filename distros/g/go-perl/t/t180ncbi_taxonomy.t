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

# ----- REQUIREMENTS -----

# ncbi_taxonomy roundtrips
# this test involves class properties

# ------------------------

if (1) {
    my $f = './t/data/sample.ncbi_taxonomy';
    my $f2 = cvt($f,'ncbi_taxonomy','obo');

    # some taxon terms contain {} - test that escaping of these works
    open(F,$f2) || die;
    my $matched;
    while (<F>) {
        # ID 21 has a fake {...} entry
        if (/\\\{test\\\}/) {
            $matched=1;
            last;
        }
    }
    ok($matched);
    
    my $parser = new GO::Parser;
    $parser->parse($f2);
    my $obo = $parser->handler->stag;
    ok($obo->get('header/synonymtypedef'));
    ok($obo->get('term/synonym/@/synonym_type'));
    my @terms = $obo->get_term;
    my ($t) = grep {$_->sget_id eq 'NCBITaxon:21'} @terms;
    # some taxon terms contain {} - test that escaping of these works
    print $t->get_name,"\n";
    ok($t->get_name eq 'Phenylobacterium immobile {test}');
}

exit 0;

sub cvt {
    my $f = shift;
    my ($from, $to) = @_;
    print "$f from:$from to:$to\n";

    my $parser = new GO::Parser ({format=>$from,
				  handler=>$to});
    my $outf = "$f.$to";
    unlink $outf if -f $outf;
    $parser->handler->file($outf);
    $parser->parse($f);
    return $outf;
}
