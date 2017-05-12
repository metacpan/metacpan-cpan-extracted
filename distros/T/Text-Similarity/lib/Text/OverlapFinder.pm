package Text::OverlapFinder;

use strict;
use warnings;

our @ISA = ();
our $VERSION = '0.05';

use constant MARKER => '###';

# manually patched with the following :
# https://rt.cpan.org/Public/Ticket/Attachment/999948/520850

##sub contains(\@@);
##sub containsReplace(\@@);

sub contains(\@$@);
sub containsReplace(\@$@);

## stemmer support not available as yet

my $stopregex = "";
my %stemmer;

# new (stoplist => $stoplist, stemmer => 1)
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless [], $class;
    
    my $stoplist;
    my $stemmer;
    while (scalar @_) {
	my $arg = shift;
	if ($arg =~ /stoplist/i) {
	    $stoplist = shift;
	    if (-z $stoplist) {
		die "'$stoplist' is not a stoplist file";
	    }
	}
	elsif ($arg =~ /stemmer/i) {
	    $stemmer = shift; 
	    unless (ref $stemmer) {
		die "'$stemmer' is not a reference to a stemmer object";
	    }
	}
	else {
	    die "Unknown argument '$arg'";
	}
    }

    # stemming
    # stoplist
    if (defined $stoplist) {
	$self->_loadStoplist ($stoplist);
    }

    if (defined $stemmer) {
	warn "Stemmer defined but ignored";
    }

    return $self;
}

sub DESTROY
{
    my $self = shift;
    delete $stemmer{$self};
}

sub doStop {0}

# originally adapted from a function in string_compare.pm 
# (distributed with earlier versions of WordNet::Similarity)
# now WordNet::Similarity uses Text::Similarity and no longer
# includes string_compare.pm
sub getOverlaps
{
    my $self = shift;
    my $string0 = shift;
    my $string1 = shift;

    my %overlapsHash = ();

    $string0 =~ s/^\s+//;
    $string0 =~ s/\s+$//;
    $string1 =~ s/^\s+//;
    $string1 =~ s/\s+$//;


	if ($stopregex ne "")
	{
    	$string0 = $self->_removeStopWords ($string0);
    	$string1 = $self->_removeStopWords ($string1);
	}

    # if stemming on, stem the two strings
    my $stemmingReqd = 0;
    if ($stemmingReqd)
    {
	my $stemmer = bless [];
        $string0 = $stemmer->stemString($string0, 1); # 1 turns on caching
        $string1 = $stemmer->stemString($string1, 1);
    }

    my @words0 = split /\s+/, $string0;
    my @words1 = split /\s+/, $string1;

    my %first;
    foreach my $offset (0 .. $#words1) {
       push @{$first{$words1[$offset]}}, $offset;
    }

    my $wc0 = scalar @words0;
    my $wc1 = scalar @words1;

    # for each word in string0, find out how long an overlap can start from it.
    my @overlapsLengths = ();
    my $matchStartIndex = 0;
    my $currIndex = -1;

    while ($currIndex < $#words0)
    {
        # forward the current index to look at the next word
        $currIndex++;

        # if this works, carry on!
#        if (contains (@words1, @words0[$matchStartIndex..$currIndex])) {
	 if (contains (@words1, $first{$words0[$matchStartIndex]},@words0[$matchStartIndex..$currIndex])) {
	    next
	}
	else {
	    # XXX shouldn't this be $currIndex - $matchStartIndex + 1 ?
	    $overlapsLengths[$matchStartIndex] = $currIndex - $matchStartIndex;
	    $currIndex-- if ($overlapsLengths[$matchStartIndex] > 0);
	    $matchStartIndex++;
	}
    }

    for (my $i = $matchStartIndex; $i <= $currIndex; $i++)
    {
        $overlapsLengths[$i] = $currIndex - $i + 1;
    }

    my ($longestOverlap) = sort {$b <=> $a} @overlapsLengths;

    while (defined($longestOverlap) && ($longestOverlap > 0))
    {
        for (my $i = 0; $i <= $#overlapsLengths; $i++)
        {
            next if ($overlapsLengths[$i] < $longestOverlap);

            # form the string
            my $stringEnd = $i + $longestOverlap - 1;

            # check if still there in $string1. replace in string1 with a mark

            if (1 #!doStop($temp)
##		&& containsReplace (@words1, @words0[$i..$stringEnd]))
	        && exists $first{$words0[$i]}
		&& containsReplace (@words1, $first{$words0[$i]}, @words0[$i..$stringEnd]))
            {
                # so its still there. we have an overlap!
		my $temp = join (" ", @words0[$i..$stringEnd]);
                $overlapsHash{$temp}++;

                # adjust overlap lengths forward
                for (my $j = $i; $j < $i + $longestOverlap; $j++)
                {
                    $overlapsLengths[$j] = 0;
                }

                # adjust overlap lengths backward
                for (my $j = $i-1; $j >= 0; $j--)
                {
                    last if ($overlapsLengths[$j] <= $i - $j);
                    $overlapsLengths[$j] = $i - $j;
                }
            }
            else
	    {
                # ah its not there any more in string1! see if
                # anything smaller than the full string works
                my $k = $longestOverlap - 1;
                while ($k > 0)
                {
                    # form the string
                    my $stringEnd = $i + $k - 1;
##		    last if contains (@words1, @words0[$i..$stringEnd]);
		     last if contains (@words1, $first{$words0[$i]}, @words0[$i..$stringEnd]);

                    $k--;
                }

                $overlapsLengths[$i] = $k;
            }
        }
        ($longestOverlap) = sort {$b <=> $a} @overlapsLengths;
    }

    return (\%overlapsHash, $wc0, $wc1);
}

# returns true if the first array contains the list, otherwise returns false
# See also containsReplace()
# e.g., contains (@Array, LIST);
##sub contains (\@@)
sub contains (\@$@)
{
    my $array2_ref = shift;

    my $positions = shift;
    return 0 if (not defined $positions);

    my @array1 = @_;

    return 0 if $#{$array2_ref} < $#array1;

##    for my $j (0..($#{$array2_ref} - $#array1)) {
    for my $j (@$positions) {
        next if ($j > $#{$array2_ref} - $#array1);

	next if $array2_ref->[$j] eq MARKER;

	if ($array1[0] eq $array2_ref->[$j]) {
	    my $match = 1;
	    for my $i (1..$#array1) {
		if ($array2_ref->[$j + $i] eq MARKER
		    or $array1[$i] ne $array2_ref->[$j + $i]) {
		    $match = 0;
		    last;
		}
	    }
	    if ($match) {
		return 1;
	    }
	}
    }
    
    return 0;
}

# same functionality as contains(), but replaces each word in the match
# with the constant MARKER
##sub containsReplace (\@@)
sub containsReplace (\@$@)

{
    my $array2_ref = shift;

    my $positions = shift;
    return 0 if (not defined $positions);

    my @array1 = @_;

    return 0 if $#{$array2_ref} < $#array1;

  #  for my $j (0..($#{$array2_ref} - $#array1)) {

	for my $j (@$positions) {
        next if ($j > $#{$array2_ref} - $#array1);

	next if $array2_ref->[$j] eq MARKER;

	if ($array1[0] eq $array2_ref->[$j]) {
	    my $match = 1;
	    for my $i (1..$#array1) {
		if ($array2_ref->[$j + $i] eq MARKER
		    or $array1[$i] ne $array2_ref->[$j + $i]) {
		    $match = 0;
		    last;
		}
	    }
	    
	    # match found, remove match and return true
	    if ($match) {
		for my $k ($j..($j+$#array1)) {
		    $array2_ref->[$k] = MARKER;
		}
		return 1;
	    }
	}
    }
   
    # no match found
    return 0;
}

sub _removeStopWords
{
    my $self = shift;
    my $str = shift;
    my @words = split /\s+/, $str;
    my @newwords;
    foreach my $word (@words) {
		if(!($word =~ /$stopregex/))
        {
			push (@newwords, $word); 
        }
    }
    return join (' ', @newwords);
}

sub _loadStoplist
{
    my $self = shift;
    my $list = shift;
    open FH, '<', $list or die "Cannot open stoplist file '$list': $!";
  
	$stopregex = "(";
    while (<FH>) {
		chomp;
		if ($_ ne "")
		{	
			$_=~s/\///g;
			if ($_=~m/\\b/)
			{
				$stopregex .= "$_|";
			}
			else
			{
				my $word = "\\b"."$_"."\\b";
				$stopregex .= "$word|";
			}
		}
    }
	chop $stopregex; $stopregex .= ")";
    close FH;
}


1;

__END__

=head1 NAME

Text::OverlapFinder - Find Overlapping Words in Strings

=head1 SYNOPSIS

    # this will list out the overlaps found in two strings
    # note that the overlaps are found among space separated
    # tokens, there are no partial word matches
    # ('cat' will not match 'at' or 'cats', for example)

    use Text::OverlapFinder;
    my $finder = Text::OverlapFinder->new;
    defined $finder or die "Construction of Text::OverlapFinder failed";

    my $string1 = 'aaa bbb ccc ddd eee';
    my $string2 = 'aa bbb ccc dd ee aaa';

    # overlaps is a hash of references to the overlaps found
    # len1 and len2 are the lengths of the strings in terms of words

    my ($overlaps, $len1, $len2) = $finder->getOverlaps ($string1, $string2); 
    foreach my $overlap (keys %$overlaps) {
        print "$overlap occurred $overlaps->{$overlap} times.\n";
    }
    print "length of string 1 = $len1 length of string 2 = $len2\n";

=head1 DESCRIPTION

This module finds word overlaps in strings. It finds the longest 
possible overlap, and keeps track of how many time each overlap occurs.

There is a mechanism available for a user to provide a stemming module, 
but no stemmer is provided by this package as yet. 

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Siddharth Patwardhan, University of Utah
 sidd at cs.utah.edu

 Satanjeev Banerjee, Carnegie-Mellon University
 banerjee at cs.cmu.edu

 Jason Michelizzi 

 Ying Liu, University of Minnesota, Twin Cities
 liux0395 at umn.edu

Last modified by:
$Id: OverlapFinder.pm,v 1.4 2015/10/08 13:06:27 tpederse Exp $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Jason Michelizzi, Ted Pedersen, Siddharth 
Patwardhan, Satanjeev Banerjee and Ying Liu

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
