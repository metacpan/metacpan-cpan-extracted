#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1 }   
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(1);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();
my $graph = $apph->get_node_graph(-acc=>5575,
                                  -depth=>1,
                                  -template=>{traverse_up=>0});

#  The idea here is simply that the iterator should 
# return each set of siblings in alphabetical order.
#  This isn't really a great test of that, but I'm not
# sure how you test it easily.

my $nit = $graph->create_iterator;


# currently, it's returning the first child of 5575 as membrane,
# which is not first in alphabetical order.
my @children =();
while (my $curr_node = $nit->next_node_instance) {
    if ($curr_node->term->acc ne "GO:0005575") {
        push(@children, $curr_node->term->name);
    }
}

stmt_note("children = @children");

my $uhoh = 0;
for (my $i=1; $i<@children; $i++) {
    $uhoh = 1 if (lc($children[$i-1]) gt lc($children[$i]));
}
stmt_check(!$uhoh);

$apph->disconnect;


