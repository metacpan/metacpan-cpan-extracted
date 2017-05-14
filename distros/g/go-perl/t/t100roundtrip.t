#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 2;
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

# This test script tests the following requirements:/x
# GO::Model::Graph must implement the GO::Builder interface; ie
# it should be possible to pass in a graph to a parser and have it build
# up a graph object

# ------------------------


if (1) {
    my $f = './t/data/test-function.dat';
    my $of;
    $of = cvt($f, qw(go_ont prolog));
    cvt($f, qw(go_ont obo_xml));
    cvt($f, qw(go_ont rdf));
    #cvt($f, qw(go_ont godb_prestore));
    cvt($f, qw(go_ont pathlist));
    cvt($f, qw(go_ont summary));

    $of = cvt($f, qw(go_ont obo_text));
    cvt($of, qw(obo_text prolog));
    cvt($of, qw(obo_text rdf));
    cvt($of, qw(obo_text pathlist));
    cvt($of, qw(obo_text summary));

    $of = cvt($of, qw(obo_text obo_xml));
    $of = cvt($of, qw(obo_xml go_ont));
    ok(1);

    $f = './t/data/GO.defs';
    $of = cvt($f, qw(go_def obo_xml));    
    $of = cvt($of, qw(obo_xml go_def));    
    ok(2);
}


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
