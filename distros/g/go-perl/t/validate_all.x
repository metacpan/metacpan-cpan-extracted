#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 1;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
use GO::ObjCache;
use Data::Stag;

# ----- REQUIREMENTS -----

# ------------------------

# you may need to set your classpath to msv.jar
# sun multi schema validator

my @bad = ();
foreach my $file ((glob "$ENV{GODATA_ROOT}/ontology/*.{ontology,defs,obo}"),
                  "$ENV{GODATA_ROOT}/external2go/ec2go",
                  (glob "$ENV{GODATA_ROOT}/gene-associations/gene_associaton.fb*")
                 ) {

    parse_and_validate($file, 'obo_xml', "tmp.obo-xml");
    parse_and_validate("tmp.obo-xml", 'godb_prestore', 'tmp.godb_prestore.xml');
}
ok (!@bad);

sub parse_and_validate {
    my $file = shift;
    my $htype = shift;
    my $outfile = shift;

    my $parser = new GO::Parser ({handler=>$htype});
    print STDERR "PARSING:$file => $outfile [$htype]\n";
    if ($parser->handler->can("is_transform") &&
        $parser->handler->is_transform) {
        my $inner_handler = $parser->handler;
        my $w = Data::Stag->getformathandler('xml');
        $w->file($outfile);
        my $handler =
          Data::Stag->chainhandlers([$parser->handler->CONSUMES],
                                    $inner_handler,
                                    $w);
        $parser->handler($handler);
    }
    else {
        $parser->handler->file($outfile);
    }
    $parser->parse($file);
    my $dtd = $parser->parser->dtd;
    if ($htype eq 'godb_prestore') {
        $dtd = 'godb_prestore-events.dtd';
    }
    $dtd || die "no dtd for $parser";
    print STDERR "VALIDATING:$outfile with $dtd\n";
    my $err = system("java -jar ~/msv/msv.jar $ENV{GO_ROOT}/xml/dtd/$dtd $outfile >& tmp.err");
    if ($err) {
        system("cat tmp.err");
        print STDERR "PROBLEM VALIDATING $file VIA $dtd\n";
        push(@bad, $file);
    }
    else {
        print STDERR "Validates OK!\n";
    }
    
}
