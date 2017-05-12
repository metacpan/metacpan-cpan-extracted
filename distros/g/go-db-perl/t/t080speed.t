#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(3);
use GO::AppHandle;
 
my $apph = get_readonly_apph;
my $term = $apph->get_term({search => "biological_process"});
print $term->acc."\n";
 
my $graph = $apph->get_node_graph($term->acc, 2, {terms=>{acc=>1, name=>1}});  
 
my @children = @{$graph->get_child_terms($term->acc)};
foreach my $child (@children){
    printf 
      "%s %s\n",
      $child->name,
      $child->acc,
    ;
}

stmt_ok;
my $rels = 
  $apph->get_relationships({parent=>$term});

stmt_check(scalar(@children) == scalar(@$rels));


$apph->disconnect;
stmt_ok;
