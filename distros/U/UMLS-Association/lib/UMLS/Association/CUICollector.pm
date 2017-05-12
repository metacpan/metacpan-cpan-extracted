package UMLS::Association::Collector;

use strict;
use warnings;
use DBI;
use feature qw(say);

#require Exporter;
use Exporter 'import';
our @EXPORT_OK = qw(build_utterance_graph get_bigrams_of);





my $VERBOSE = 1;
my $DEBUG = 0;


sub process_files {
    my @files = @_;
    
    my %bigrams;   # cui_1 => cui_2 => sum of cui_1 preceeding cui_2
    my %n1p;       # cui => sum of cui as cui_1
    my %np1;       # cui => sum of cui as cui_2
    my $npp;       # total sum of all bigram observations
        
    # Anonymous subroutine to update the bigram and marginal counts
    my $incrementor = sub {
        my($cui_1, $cui_2, $same_phrase) = @_;
        
        unless (exists $$same_phrase{$cui_1}{$cui_2}) { 
            $bigrams{$cui_1}{$cui_2}++;
            $n1p{$cui_1}++;
            $np1{$cui_2}++;
            $npp++;
        }
        
        $$same_phrase{$cui_1}{$cui_2} = 1;
    };
    
    for my $file (@files) {
        
        if( File::Type->mime_type($file) =~ /x-gzip/) {
            process_gz_file($file, $incrementor);
        }
        else {
            process_file($file, $incrementor);
        }
    }
    
   return (\%bigrams, \%n1p, \%np1, $npp); 
}
###############################################################################
sub process_file {
    my $file = shift;           # text/plain file to process
    my $incrementor = shift;    # ref to anon sub that updates bigram counts
    
    open(my $fh, '<', $file) or die "Cannot read $file: $!";    #fh = filehandle
    say "Parsing uncompressed file: $file" if $VERBOSE;
    
    until (eof $fh ){
        count_bigrams( read_utterance( $fh ), $incrementor );
    }
}

sub process_gz_file {

    my $file = shift;           # compressed .gz file to process
    my $incrementor = shift;    # ref to anon sub that updates bigram counts
        
    my $gz = gzopen("$file", "rb") or die "Cannot read gzip compressed $file\n";
    say "Parsing gzip compressed file: $file" if $VERBOSE; 
    
    # Count the bigrams in each utterance until the end of the file.         
    until ($gz->gzeof()) {
        count_bigrams( read_gz_utterance($gz), $incrementor );
    }
    
    $gz->gzclose();
}

###############################################################################
# take filehandle as lexical variable
# returns ref to array of phrases for single utterance
sub read_utterance {
    my $fh = shift;
   
    my @phrases_in_utterance;
   
   # The following loop will iterate over all the phrases for this utterance
    while (<$fh>) {
        
        # Finish when we reach the End Of Utterance (EOU) marker
        last if /^'EOU'/;
            
        # Skip all lines that aren't mappings for a phrase in the utterance
        next unless /^mappings/;
                
        my @mappings = @{ get_mappings($_) };

        push @phrases_in_utterance, \@mappings if @mappings;
    }
   
    return \@phrases_in_utterance;
}

###############################################################################
# takes the gzip "filehandle" object 
# returns ref to array of phrases for single utterance
sub read_gz_utterance {
    my $gz = shift;
   
    my @phrases;
   
   # The following loop will iterate over all the phrases for this utterance
    while ($gz->gzreadline($_)) {
        
        # Finish when we reach the End Of Utterance (EOU) marker
        last if /^'EOU'/;
            
        # Skip all lines that aren't mappings for a phrase in the utterance
        next unless /^mappings/;
                
        my @mappings = @{ get_mappings($_) };

        push @phrases, \@mappings if @mappings;
    }
   
    return \@phrases;
}

###############################################################################
sub get_mappings {
    my $mapping_string = shift;    # the line for which /^mappings/ is true
    
    # Break mappings into each possible mapping of phrase into CUIs
    my @maps = split /map\(/, $mapping_string;

    # Collect the CUIs in each possible mapping (assumes format 'C1234567')
    # as a set of strings
    my @mappings;           
    for my $map (@maps) {
        
       my $CUI_string = join " ", ( $map =~ m/C\d{7}/g );
       
       say $CUI_string if $CUI_string and $DEBUG;
       
       push @mappings, $CUI_string if $CUI_string; 
    }

    return \@mappings;
}

###############################################################################
sub count_bigrams {
    my( $phrases_ref,   # reference to list of mappings for single utterance 
        $incrementor    # anonymous subroutine to update counting hashes
        ) = @_;
        
    my @phrases = @$phrases_ref;
    
    # Iterate through n-1 phrases in utterance
    for (my $i = 0; $i < $#phrases; $i++) {
                
        my @phrase_1 = @{ $phrases[$i]      };  # Mappings for current phrase
        my @phrase_2 = @{ $phrases[$i + 1]  };  # Mappings for the next phrase

        my %prior;  # Tracks bigrams within same phrase to avoid double counting
        
        # Loop through each of the mappings of the current phrase
        foreach my $map_str_p1 ( @phrase_1 ) {
            my @cuis = split ' ', $map_str_p1;
            
            # Count bigrams up to the k-1th CUI
            for (my $k = 0; $k < $#cuis; $k++) {
                my $cui_1 = $cuis[$k];
                my $cui_2 = $cuis[$k+1];
                
                $incrementor->($cui_1, $cui_2, \%prior);
            }
         
            # Count the kth CUI with the first of each of the next phrases maps
            foreach my $map_str_p2 ( @phrase_2 ) {
                (my $first_of_next_phrase) = $map_str_p2 =~ /(C\d{7})/;
                
                $incrementor->($cuis[-1], $first_of_next_phrase, \%prior);
            }
        }
    }
}

###############################################################################
sub build_utterance_graph {
    my $phrases_ref = shift;
    my @phrases = @$phrases_ref;
    
    # Create utterance graph, u. Counted vertices enabled so same CUI can exist
    # 2+ in graph with different descendants
    my $u = Graph::Directed->new();
    
    my $cui_index = 0;  # Uniquely identifies each CUI in the graph.
                        # Needed to correctly find descendants for repeated
                        # CUIs. 
                        # Suffixed to each CUI before adding to graph.
                        # So, for 42nd CUI in the graph, C0123456 
                        # 'C0123456' -> 'C0123456_42'
    
    # Create a phrase graph for each phrase, then add it to the utterance graph
    my @phrase_graphs;
    for my $phrase_ref (@phrases) {
        
        # Initialize empty phrase graph
        my $p = Graph::Directed->new();
        
        # Iterate over mappings for this phrase to contruct the phrase graph
        for my $cui_string (@{ $phrase_ref }) {
            
            my @cuis = split / /, $cui_string;
            
            # tag each cui with an index ID
            @cuis = map { join ':', $_, $cui_index++ } @cuis;
            
            # Add cuis for each mapping to the phrase graph
            $p->add_vertex( $_ ) for (@cuis);
            for (my $i = 0; $i < $#cuis; $i++) {
                $p->add_edge($cuis[$i], $cuis[$i+1]);
            }
        }
        
        # Store the phrase graph
        push @phrase_graphs, $p;
    }
    $u->add_edges($_->edges) for @phrase_graphs;

    # "Stitch" phrase graphs together in utterance graph by connecting
    # all CUIs in phraseA without descendants to all CUIs in phraseB without
    # parents. $pg_i is ith phrase graph in list.
    for (my $i = 0; $i < $#phrase_graphs; $i++) {
        
        # Find leaves (no children) in phraseA and roots(no parents) in phraseB 
        my @leaves = grep { 
                $phrase_graphs[$i]->edges_from($_) == 0; 
                } $phrase_graphs[$i]->vertices;
        my @roots  = grep { 
                $phrase_graphs[$i+1]->edges_to($_) == 0;
                } $phrase_graphs[$i+1]->vertices;

        # Connect the leaves of phraseA to the roots of phrase B
        for my $leaf (@leaves) {
            for my $root (@roots) {
                $u->add_edge($leaf, $root);
            }
        }
    }
    
    
    return $u;
}

###############################################################################

# get_bigrams( $utterance_graph_ref, $window_size )
# returns list of bigram pairs as a reference to an array of tuples
sub get_all_bigrams {
    my($u, $window) = @_;
    
    my @bigrams;
    
    
    
    return \@bigrams;
}

###############################################################################
sub get_bigrams_of {
    my($u, $cui, $window) = @_;
  
    my %bigrams;     # use hash as a set of unique values
    
    # Closure to recursively traverse the utterance graph for bigrams
    my $get_tokens_at_level;        # need to declare separately for recursion
    $get_tokens_at_level = sub {
        my ($token, $level) = @_;
        
        print $token . "\n";
        
        # Remove the index tag from the CUI's vertex label
        $token =~ s/:\d+$//;
        
        print $token . "\n";
        
        # Add the token to the list of bigrams for the CUI
        $bigrams{$token} = 1;
        
        # Stop if at the end of the window
        return if $level == 0;
       
        # Otherwise, get the next batch of succesor tokens
        $get_tokens_at_level->($_, $level-1) for ($u->successors($token));
    };

    # Get all the bigrams within window for the target CUI. 
    $get_tokens_at_level->($cui, $window);
    
    # Remove the target CUI from its own bigram list. 
    # TODO: tweak the recusive function to remove the need for this line
    delete $bigrams{$cui};
    
    # Return a list of CUIs which form bigram pairs for the target CUI
    return keys %bigrams;
}

###############################################################################

1; # End of Module