package Text::Tradition::Parser::Util;

use strict;
use warnings;
use Algorithm::Diff;
use Exporter 'import';
use vars qw/ @EXPORT_OK /;
@EXPORT_OK = qw/ add_hash_entry check_for_repeated cmp_str collate_variants is_monotonic /;

=head1 NAME

Text::Tradition::Parser::Util

=head1 DESCRIPTION

A collection of utilities used by multiple Text::Tradition parsers.  
Probably not of external interest.

=head1 METHODS

=head2 B<collate_variants>( $collation, @reading_ranges )

Given a set of readings in the form 
( lemma_start, lemma_end, rdg1_start, rdg1_end, ... )
walks through each to identify those readings that are identical.  The
collation is a Text::Tradition::Collation object; the elements of
@readings are Text::Tradition::Collation::Reading objects that appear
on the collation graph.

=cut

sub collate_variants {
    my( $collation, @reading_sets ) = @_;
    
    # Make sure the reading sets are unique, but retain their ordering.
    my %unique_sets;
    my @sets;
    foreach( @reading_sets ) {
    	push( @sets, $_ ) unless $unique_sets{$_};
    	$unique_sets{$_} = $_;
    }

    # Two different ways to do this, depending on whether we want
    # transposed reading nodes to be merged into one (producing a
    # nonlinear, bidirectional graph) or not (producing a relatively
    # linear, unidirectional graph.)
    return $collation->linear ? _collate_linearly( $collation, @sets )
        : _collate_nonlinearly( $collation, @sets );
}

sub _collate_linearly {
    my( $collation, $lemma_set, @variant_sets ) = @_;

    my @unique;
    my $substitutions = {};
    push( @unique, @$lemma_set );
    while( @variant_sets ) {
        my $variant_set = shift @variant_sets;
        # Use diff to do this job
        my $diff = Algorithm::Diff->new( \@unique, $variant_set, 
                                         {'keyGen' => \&_collation_hash} );
        my @new_unique;
        my %merged;
        while( $diff->Next ) {
            if( $diff->Same ) {
                # merge the nodes
                my @l = $diff->Items( 1 );
                my @v = $diff->Items( 2 );
                foreach my $i ( 0 .. $#l ) {
                    if( !$merged{$l[$i]->id} ) {
                        next if $v[$i] eq $l[$i];
#                         print STDERR sprintf( "Merging %s into %s\n", 
#                                              $v[$i]->id,
#                                              $l[$i]->id );
                        $collation->merge_readings( $l[$i], $v[$i] );
                        $merged{$l[$i]->id} = 1;
                        $substitutions->{$v[$i]->id} = $l[$i];
                    } else {
                        print STDERR "Would have double merged " . $l[$i]->id . "\n";
                    }
                }
                # splice the lemma nodes into the variant set
                my( $offset ) = $diff->Get( 'min2' );
                splice( @$variant_set, $offset, scalar( @l ), @l );
                push( @new_unique, @l );
            } else {
                # Keep the old unique readings
                push( @new_unique, $diff->Items( 1 ) ) if $diff->Items( 1 );
                # Add the new readings to the 'unique' list
                push( @new_unique, $diff->Items( 2 ) ) if $diff->Items( 2 );
            }
        }
        @unique = @new_unique;
    }
    return $substitutions;
}

sub _collate_nonlinearly {
    my( $collation, $lemma_set, @variant_sets ) = @_;
    
    my @unique;
    my $substitutions = {};
    push( @unique, @$lemma_set );
    while( @variant_sets ) {
        my $variant_set = shift @variant_sets;
        # Simply match the first reading that carries the same word, so
        # long as that reading has not yet been used to match another
        # word in this variant. That way lies loopy madness.
        my @distinct;
        my %merged;
        foreach my $idx ( 0 .. $#{$variant_set} ) {
            my $vw = $variant_set->[$idx];
            my @same = grep { cmp_str( $_ ) eq $vw->text } @unique;
            my $matched;
            if( @same ) {
                foreach my $i ( 0 .. $#same ) {
                    unless( $merged{$same[$i]->id} ) {
                        #print STDERR sprintf( "Merging %s into %s\n", 
                        #                     $vw->id,
                        #                     $same[$i]->id );
                        $collation->merge_readings( $same[$i], $vw );
                        $merged{$same[$i]->id} = 1;
                        $matched = $i;
                        $variant_set->[$idx] = $same[$i];
                        $substitutions->{$vw->id} = $same[$i];
                    }
                }
            }
            unless( @same && defined($matched) ) {
                push( @distinct, $vw );
            }
        }
        push( @unique, @distinct );
    }
    return $substitutions;
}

sub _collation_hash {
    my $node = shift;
    return cmp_str( $node );
}

=head2 B<cmp_str>

Don't use this. Really.

=cut

sub cmp_str {
    my( $reading ) = @_;
    my $word = $reading->text();
    return $word unless $reading->collation->tradition->name =~ /158/;
    $word = lc( $word );
    $word =~ s/\W//g;
    $word =~ s/v/u/g;
    $word =~ s/j/i/g;
    $word =~ s/cha/ca/g;
    $word =~ s/quatuor/quattuor/g;
    $word =~ s/ioannes/iohannes/g;
    return $word;
}

=head2 B<check_for_repeated>( @readings )

Given an array of items, returns any items that appear in the array more
than once.

=cut

sub check_for_repeated {
    my @seq = @_;
    my %unique;
    my @repeated;
    foreach ( @seq ) {
        if( exists $unique{$_->id} ) {
            push( @repeated, $_->id );
        } else {
            $unique{$_->id} = 1;
        }
    }
    return @repeated;
}

=head2 B<add_hash_entry>( $hash, $key, $entry )

Very simple utility for adding $entry to the list at $hash->{$key}.

=cut

sub add_hash_entry {
    my( $hash, $key, $entry ) = @_;
    if( exists $hash->{$key} ) {
        push( @{$hash->{$key}}, $entry );
    } else {
        $hash->{$key} = [ $entry ];
    }
}

1;

=head1 BUGS / TODO

=over

=item * Get rid of abomination that is cmp_str.

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
