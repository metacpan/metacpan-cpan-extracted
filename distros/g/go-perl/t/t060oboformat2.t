#!/usr/local/bin/perl -w

use lib '.';

use constant NUMTESTS => 12*3;
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

# ----- REQUIREMENTS -----

# make sure synonums etc are parsed
# ------------------------

my $f = shift @ARGV || "./t/data/go-truncated.obo";
check_file($f);
$f = cvt($f, 'obo_text', 'obo_xml');
check_file($f);
$f = cvt($f, 'obo_xml', 'obo_text');
check_file($f);

exit 0;


sub check_file {
    my $f = shift;

    my $parser = new GO::Parser ({ # format=>'obo_text',
                                  handler=>'obj'});
    $parser->handler->add_root;
    ok(1);
    print "Parsing: $f\n";
    $parser->parse ($f);
    ok(1);
    my $graph = $parser->handler->g;
    my $terms = $graph->find_roots;
    foreach my $term (@$terms) {
        printf "ROOT: %s\n", $term->name;
    }
    $terms = $graph->get_all_nodes;
    my $t = 0;
    my $t2 = 0;
    my $n_obs = 0;
    my $n_syns = 0;
    my $n_exact_syns = 0;
    my $n_alt_ids = 0;
    my $n_xrefs = 0;
    my $n_def_xrefs = 0;
    my $n_defs = 0;
    my $n_comments = 0;
    printf "TERMS: %d\n", scalar(@$terms);
    #ok(@$terms == 97);
    foreach my $term (@$terms) {
        my $syns = $term->synonym_list || [];
        if (@$syns) {
            printf "SYNS:%s\n", join('|',@$syns);
            $n_syns += @$syns;
        }
        my $exact_syns = $term->synonyms_by_type('exact') || [];
        if (@$exact_syns) {
            printf "EXACT SYNS:%s\n", join('|',@$exact_syns);
            $n_exact_syns += @$exact_syns;
        }
        $n_alt_ids += @{$term->alt_id_list};
        my $xrefs = $term->dbxref_list || [];
        if (@$xrefs) {
            printf "XREFS:%s\n", join('|',map {$_->as_str} @$xrefs);
            $n_xrefs += @$xrefs;
        }
        my $comment = $term->comment;
        if ($comment) {
            printf "COMMENT:%s\n", $comment;
            $n_comments++;
        }
        my $def = $term->definition;
        if ($def) {
            my $xrefs = $term->definition_dbxref_list;
            printf "DEFXREFS:%s\n", join('|', map {$_->as_str} @$xrefs);
            $n_def_xrefs += @$xrefs;
            $n_defs++;
        }
        $n_obs ++ if $term->is_obsolete;
        my $rels = $graph->get_relationships($term->acc);
        $t2 += @$rels;
        $t+= @{$graph->get_parent_relationships($term->acc)};
            foreach my $rel (@$rels) {
        	printf "EDGE|%s|%s|%s\n",
        	  $rel->subject_acc,
        	    $rel->object_acc,
        	      $rel->type;
            }
    }
    printf "total defs:%s\n", $n_defs;
    printf "total def xrefs:%s\n", $n_def_xrefs;
    printf "total xrefs:%s\n", $n_xrefs;
    printf "total comments:%s\n", $n_comments;
    printf "total syns:%s\n", $n_syns;
    printf "total EXACT syns:%s\n", $n_exact_syns;
    printf "total obs:%s\n", $n_obs;
    printf "total parent rels:%s\n", $t;
    printf "total (both ways):%s\n", $t2;
    ok($n_defs,  27);
    ok($n_xrefs,  2);
    ok($n_def_xrefs,  42);
    ok($n_comments,  2);
    ok($n_syns,  12);
    ok($n_exact_syns,  1);
    ok($n_obs,  1);
    ok($n_alt_ids,  1);
    ok($t, 37);
    ok($t2, 64);              # trailing rels counted only once
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
