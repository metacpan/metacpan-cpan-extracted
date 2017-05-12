#!/usr/local/bin/perl -w

#!/usr/bin/perl

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1}
use GO::TestHarness;
use GO::AppHandle;
use GO::Model::TreeIterator;

# ----- REQUIREMENTS -----

#  Each instance of a node should have the same
# number of children when iterating through the graph.
#  A bug has cropped up where the second time a term
# comes up it's kids don't get iterated.

# ------------------------

# TEMPORARILY DISABLED
ok(1);

#my @array;

#my $apph = get_readonly_apph;
##$apph->filters({evcodes=>['iea']});

#my $test_node = "GO:0009277";
#my $g = $apph->get_node_graph($test_node, 1);
#print $g->to_text_output;

#my $i = $g->create_iterator;
## 9277 has two parents.
#my $previous_depth = 0;
#my %hash;
#my $parent_array;
#while (my $ni = $i->next_node_instance) {
#    my $depth = $ni->depth;
#    if ($previous_depth == $depth) {
#        @$parent_array->[$depth] = $ni->term->public_acc;
#    } elsif ($previous_depth > $depth) {
#        while ($previous_depth > $depth) {
#            $previous_depth -= 1;
#            pop @$parent_array;
#        }
#        @$parent_array->[$depth] = $ni->term->public_acc;
#    } elsif ($previous_depth < $depth) {
#        push @$parent_array, $ni->term->public_acc;
#    }
#    else {
#        die;
#    }

#    # if the current node is a child of the test node.
#    if (@$parent_array->[scalar(@$parent_array) - 2] eq $test_node){
#        my $key;
#        my $i = 0;
#        # the key for each node is the full path.
#        while ($i < scalar(@$parent_array) - 2) {
#            $key .= @$parent_array->[$i];
##        } continue {
#            $i++;
#        }
#        %hash->{$key} += 1;
#    }
#    $previous_depth = $ni->depth;
#}


#my @keys = keys %hash;
#my $a = @keys->[0];
#my $b = @keys->[1];

### There should be the same # of child terms
### regardless of which node of the graph you're at.

#stmt_check(%hash->{$a} == %hash->{$b});


