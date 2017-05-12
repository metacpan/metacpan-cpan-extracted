package Text::CommonParts;

use strict;
use vars qw($VERSION @EXPORT_OK);
use base qw(Exporter);

$VERSION   = 0.5;
@EXPORT_OK = qw(common_parts shortest_common_parts);

=head1 NAME

Text::CommonParts - return the common starting parts of phrases

=head1 SYNOPSIS

    use Text::CommonParts qw(common_parts);

    # returns "sheep"
    common_parts("sheep shearing", "sheep dipping", "sheep rustling");
 
    # returns "sheep", "sheep shearing"
    common_parts("sheep shearing", "sheep dipping", "sheep rustling", "sheep shearing shears");

    # returns "sheep"
    shortest_common_parts("sheep shearing", "sheep dipping", "sheep rustling");
 
    # returns "sheep"
    shortest_common_parts("sheep shearing", "sheep dipping", "sheep rustling", "sheep shearing shears");
 



=head1 METHODS

=head2 common_parts <phrases>

Takes a list of phrases and returns the longest common parts.

If a phrase shares no common parts with any other phrases then it will be returned whole.

Given a set of phrases which have a common prt and a subset of phrases that have a 
longer common part then both parts will be returned. e.g given

    "something good", "something bad", "something in the woodshed", "something in my eye"

will return

    "something", "something in"

=cut

sub common_parts { 
    return _common_parts(1,@_);

}

=head2 shortest_common_parts <phrases>

Same as common_parts but will not return subsets. e.g given

    "something good", "something bad", "something in the woodshed", "something in my eye"

will just return

    "something"



=cut



sub shortest_common_parts {
    return _common_parts(0,@_);
}

sub _common_parts {
    my $longest = shift;
    my @keys    = sort _slength @_;
    @keys       = reverse @keys if !$longest;


    # this fetches a list of all candidate parts
    my %candidates = _get_candidates($longest, @keys);

    my %seen;
    my %results;

    my @cand_keys = sort _slength keys %candidates;
    @cand_keys    = reverse @cand_keys if !$longest;


    # note which phrases we've seen already    
    foreach my $cand (@cand_keys) {
        my @phrases = @{$candidates{$cand}};
        foreach my $match (@phrases) {
                next if $seen{$match}++;
                push @{$results{$cand}}, $match;
        }
    }


    # clean up the results hash
    my %tmp;
    foreach my $result (keys %results) {
        my @phrases = @{$results{$result}};
        # we're golden if it's got more than two phrase attached 
        # Butif there's only one phrase since it will be 
        # the n-1th ngram of the phrases when we want the whole phrase
        # (we'll deal with that later)
        if (@phrases>1) {
                $tmp{$result}++;
                next;
        } 
        # claim we've never seen it
        delete $seen{$_} for @phrases;

    }
    %results = %tmp;
    %tmp     = ();

    # now get anything that hasn't been matches already
    # i.e get singletons
    foreach my $key (@keys) {
        next if $seen{$key};
        $results{$key}++;
    }

    return keys %results;
}

sub _get_candidates {
        my @keys    = @_;

        my %cands;
        for my $key (@keys) {
            my @so_far;
            # split each phrase up into parts
            foreach my $part (split ' ', $key) {
                push @so_far, $part;
                # make the sub part
                my $match = join(" ",@so_far);
                # we don't wnat whole matches yet 
                # since they'll always be the longest match
                # we'll add whole phrases that share no common parts 
                # in later
                next if $match eq $key && !exists $cands{$match};
                # keep it for later
                push @{$cands{$match}}, $key;
            }
        }
        return %cands;
}

# sort by length, longest first
sub _slength ($$) {
        return length($_[1]) <=> length($_[0]);
}





=head1 AUTHOR

Simon Wistow <simon@thegestalt.org

=head1 COPYRIGHT

Copyright 2006, Simon Wistow

Distributed under the same terms as Perl itself

=cut

1;
