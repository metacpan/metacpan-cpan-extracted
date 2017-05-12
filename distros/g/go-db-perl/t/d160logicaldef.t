#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(6);


use GO::Parser;
use GO::SqlWrapper qw(:all);

create_test_database("go_mini");
# Get args

my $apph = getapph();
my $dbh = $apph->dbh;

stmt_ok;
my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
$parser->handler->optimize_by_dtype('go_ont');
stmt_ok;
use Data::Dumper;
unless ($ENV{NO_REBUILD_GO_TEST_DATABASE}) {
    $parser->parse ("./t/data/llm.obo");
}
$parser->show_messages;
stmt_ok;

$apph->refresh;

my $g = $apph->get_graph({name=>'larval locomotory behavior'});
my $t = $g->get_term_by_name('larval locomotory behavior');
my $rels = $g->get_parent_relationships($t);
stmt_note(scalar(@$rels));
foreach my $rel (@$rels) {
    printf "%s %s\n", $rel->as_str, $rel->complete || 0;
}
#my $ldef = $g->infer_logical_definitions;
my $ldef = $t->logical_definition;
stmt_note($ldef);
stmt_check($ldef);
print $g->to_text_output;
foreach my $t (@{$g->get_all_terms}) {
    my $ldef = $t->logical_definition;
    if ($ldef) {
        printf "%s\n  genus: %s\n  differentia: %s\n\n",
          $t->name,
            $ldef->genus_acc,
              join('; ',map {"@$_"} @{$ldef->differentia});
    }
}
$t = $g->get_term_by_name('larval locomotory behavior');
my $ldef = $t->logical_definition;
stmt_check($g->get_term($ldef->genus_acc)->name eq 'locomotory behavior');
stmt_check($ldef->differentia->[0]->[1] =~ /FBdv/);

