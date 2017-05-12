#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/collector.t'

#  This scripts tests all of the functions in Collector.pm 

use Test::More;
use Test::Deep;
use lib '../lib';

use UMLS::Association::Collector qw(build_utterance_graph get_bigrams_of);

use Data::Dumper;

# Can we find our Collector module?
require_ok( UMLS::Association::Collector);

# Can we load the Graph CPAN module?
require_ok( Graph::Directed );


# Construct an utterance and its graph for testing.
my @utterance = 
        ( [ 'C0000011 C0000012 C0000013', 
            'C0000014 C0000013', 
            'C0000015'
          ],
          
          [ 'C0000021 C0000022', 
            'C0000023'
          ], 
          
          [ 'C0000031 C0000032 C0000033', 
            'C0000034'
          ], 
            
          [ 'C0000013 C0000040' ]    # repeated CUI  
            
        );

my $utterance_graph = build_utterance_graph(\@utterance);

# Did build_utterance_graph() actually build a graph?
isa_ok( $utterance_graph, 'Graph::Directed',
        'return value of build_utterance_graph' );

# C0000011 should lead to just C0000012
@C0000011 = $utterance_graph->edges_from('C0000011');
ok( scalar @C0000011 == 1,   'C0000011 has only one child'   );
ok( 'C0000012' ~~ @C0000011, 'C0000011 -> C0000012'          );

# C0000015 should lead to C0000021 and C0000023 
@C0000015 = $utterance_graph->edges_from('C0000015');
ok( scalar @C0000015 == 2,   'C0000015 has two children'   );
ok( 'C0000021' ~~ @C0000015, 'C0000015 -> C0000021'        );
ok( 'C0000023' ~~ @C0000015, 'C0000015 -> C0000023'        );

# C0000013 is a repeated CUI. Should have both sets of parents and children
@C0000013_parents = $utterance_graph->edges_to('C0000013');
ok( scalar @C0000013_parents == 4,   'C0000013 has four parents' );
@C0000013_children = $utterance_graph->edges_from('C0000013');
ok( scalar @C0000013_children == 3,   'C0000013 has three children' );

# Print the graph for debugging help
print '='x10 . "\n";
print $utterance_graph . "\n";
print '='x10 . "\n";

# Now lets try to find bigrams for a specific CUI
@C0000012_bigrams = get_bigrams_of($utterance_graph, 'C0000012', 1);
@should_be = qw[ C0000013 ];
cmp_set(    \@C0000012_bigrams, 
            \@should_be, 
            "C0000012 has correct single bigram for window=1");

@C0000012_bigrams = get_bigrams_of($utterance_graph, 'C0000012', 2);
@should_be = qw[ C0000013 C0000021 C0000023 ];
cmp_set(    \@C0000012_bigrams, 
            \@should_be, 
            "C0000012 has correct three bigrams for window=2");

@C0000012_bigrams = get_bigrams_of($utterance_graph, 'C0000012', 3);
@should_be = qw[ C0000013 C0000021 C0000023 C0000022 C0000031];
cmp_set(    \@C0000012_bigrams, 
            \@should_be, 
            "C0000012 has correct five bigrams for window=3");











print "\nCompleted tests: ";
done_testing();