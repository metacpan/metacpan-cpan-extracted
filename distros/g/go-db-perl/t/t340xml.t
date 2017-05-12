#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use FileHandle;

n_tests(4);
eval {
    require "XML/Writer.pm";
};
if ($@) {
    print "XML::Writer not installed - skipping tests\n";
    for (1..4) {
        stmt_ok();
    }
    exit 0;
}

my $apph = get_readonly_apph();
stmt_ok;

# lets check we got stuff

my $t = $apph->get_term({name=>'endoplasmic reticulum'});
my $g = $apph->get_node_graph($t->acc, 2);
my $out = FileHandle->new(">t/out.tmp.xml");
print $g->to_xml($out);
stmt_note;
$out->close;
my $t1 = `grep go:is_a t/out.tmp.xml`;
my $t2 = `grep go:part_of t/out.tmp.xml`;
stmt_check($t1);
stmt_check($t2);
stmt_ok;

