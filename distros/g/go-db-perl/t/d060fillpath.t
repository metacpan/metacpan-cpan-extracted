#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

# REQUIREMENTS
#
# check that the path table - population and querying - works
#
# also check gpc while we are here

n_tests(20);


use GO::Parser;
use Data::Dumper;
 # Get args

create_test_database("go_path");
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

stmt_note('loading function');
$parser->handler->optimize_by_dtype('go_ont');
$parser->parse ("./t/data/baby-function.dat");
$apph->add_root;
stmt_note('loading assocs');
$parser->set_type('go_assoc');
$parser->handler->optimize_by_dtype('go_assoc');
$parser->acc2name_h($apph->acc2name_h);
$parser->cache_errors;
$parser->parse("./t/data/mini-fb-assocs.fb");
my @errs = $parser->errlist;
print $_->sxpr foreach @errs;
stmt_note(scalar @errs);
stmt_check(@errs == 74);

my $pl1 = $apph->get_products({term=>3677, deep=>1});
stmt_note("total products: ".scalar(@$pl1));
my $pl = $apph->get_products({term=>3677, deep=>1});
stmt_note("n products 3677: ".scalar(@$pl));
stmt_check(@$pl == 526);

warn("test needs updated - check product types");
my @types = map {$_->type} @$pl;
print "TYPES: @types\n";
stmt_check((grep {$_ eq 'faketype'} @types) == 1);

# check negative annotations
$pl = $apph->get_products({term=>8233, deep=>1});
printf "P: %s\n", $_->symbol foreach @$pl;
my $al = $apph->get_associations({acc=>8233});
printf "A: %s %s %s\n", $_->is_not, $_->evidence_list->[0]->code, $_->gene_product->symbol foreach @$al;
stmt_check(@$al==1);
stmt_check(@$pl==1);
stmt_check((grep {$_->is_not} @$al) == 1);
# lets check we got stuff
stmt_note('filling path table');
$apph->fill_path_table;

my $dl = $apph->get_distances({acc=>3673}, {acc=>3677});
stmt_check($dl->[0] == 3);
$dl = $apph->get_distances({acc=>3677}, {acc=>3677});
stmt_check($dl->[0] == 0);

stmt_check($apph->has_path_table);

foreach (0,1) {
    my $pl = $apph->get_products({term=>3677, deep=>1});
    stmt_note("product / $_ = ".scalar(@$pl));
    stmt_check(scalar(@$pl) == 526);
    
    my $g = $apph->get_graph(3677, 2);
    $g->to_text_output;
    
    stmt_note($g->node_count);
    stmt_check($g->node_count == 37);
    $apph->has_path_table(0);
}
$apph->has_path_table(1);

my $t;
$apph->fill_count_table;
stmt_check($apph->has_count_table);
$t = $apph->get_term("DNA binding");
stmt_note($t->n_deep_products());
stmt_check($t->n_deep_products() == 526);
$apph->filters->{speciesdb} = ["SGD"];
$t = $apph->get_term("DNA binding");
stmt_check(!$t->n_deep_products || $t->n_deep_products == 0);
$apph->fill_count_table;
$t = $apph->get_term("DNA binding");
stmt_check($t->n_deep_products == 0);
delete $apph->filters->{speciesdb};
$t = $apph->get_term("DNA binding");
stmt_note("n_deep_products=".$t->n_deep_products);
#stmt_check($t->n_deep_products == 0);
stmt_check($t->n_deep_products == 526);

$apph->filters->{speciesdb} = ["FB"];
$apph->filters->{evcodes} = ["IDA"];
stmt_note("filling count table");
$apph->fill_count_table;
$t = $apph->get_term("DNA binding");
stmt_note("n_deep_products=".$t->n_deep_products);
stmt_check($t->n_deep_products == 45);

# load new data, with some trailing IDs
@errs = $parser->parse("./t/data/gene_association.GeneDB_Pfalciparum");
stmt_ok(1);
