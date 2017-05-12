#!/usr/local/bin/perl -w

=head1 NAME

huge-combine.pl - Combine two bigram files created by count.pl into single file 

=head1 SYNOPSIS

Combines two bigram files created by count.pl into a single bigram file.

=head1 USGAE

huge-combine.pl [OPTIONS] COUNT1 COUNT2

=head1 INPUT

=head2 Required Arguments:

=head3 COUNT1 and COUNT2

combine-count.pl takes two bigram files created by count.pl as input.
If COUNT1 and COUNT2 are of unequal sizes, it is strongly recommended 
that COUNT1 should be the smaller file and COUNT2 should be the lager 
bigram file.

Each line in files COUNT1, COUNT2 should be formatted as -

word1<>word2<>n11 n1p np1

where word1<>word2 is a bigram, n11 is the joint frequency score of this
bigram, n1p is the number of bigrams in which word1 is the first word,
while np1 is the number of bigrams having word2 as the second word.

=head2 Optional Arguments:

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output displays all bigrams that appear either in COUNT1 (inclusive) or
in COUNT2 along with their updated scores. Scores are updated such that -

=over

=item 1: 

If a bigram appears in both COUNT1 and COUNT2, their n11 scores are added.

e.g. If COUNT1 contains a bigram 
	word1<>word2<>n11 n1p np1
and COUNT2 has a bigram
	word1<>word2<>m11 m1p mp1

Then, the new n11 score of bigram word1<>word2 is n11+m11

=item 2:

If the two bigrams belonging to COUNT1 and COUNT2 share a commom first word, 
their n1p scores are added.

e.g. If COUNT1 contains a bigram
	word1<>word2<>n11 n1p np1
and if COUNT2 contains a bigram
	word1<>word3<>m11 m1p mp1

Then, the n1p marginal score of word1 is updated to n1p+m1p

=item 3:

If the two bigrams belonging to COUNT1 and COUNT2 share a commom second word,
their np1 scores are added.

e.g. If COUNT1 contains a bigram
        word1<>word2<>n11 n1p np1
and if COUNT2 contains a bigram
        word3<>word2<>m11 m1p mp1

Then, the np1 marginal score of word2 is updated to np1+mp1

=back

=head1 AUTHOR

Amruta Purandare, Ted Pedersen.
University of Minnesota at Duluth.

=head1 COPYRIGHT

Copyright (c) 2004,

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota, Duluth.
tpederse@umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut

###############################################################################

#			===============================
#                               CODE STARTS HERE
#			===============================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version");
# show help option
if(defined $opt_help)
{
        $opt_help=1;
        &showhelp();
        exit;
}

# show version information
if(defined $opt_version)
{
        $opt_version=1;
        &showversion();
        exit;
}

# show minimal usage message if fewer arguments
if($#ARGV<1)
{
        &showminimal();
        exit;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

$small_file=$ARGV[0];
$big_file=$ARGV[1];

if(!-e $small_file)
{
	print STDERR "ERROR($0):
	COUNT1 file <$small_file> doesn't exist.\n";
	exit;
}

if(!-e $big_file)
{
        print STDERR "ERROR($0):
        COUNT2 file <$big_file> doesn't exist.\n";
        exit;
}

open(SMALL,$small_file) || die "ERROR($0):
	Error(code=$!) in opening COUNT1 file <$small_file>.\n";
open(BIG,$big_file) || die "ERROR($0):
	Error(code=$!) in opening COUNT2 file <$big_file>.\n";

#############################################################################

#                       ====================
#                    	    CODE SECTION
#                       ====================

# loading bigrams from smaller file into memory
while(<SMALL>)
{
	if(/^\s*(\d+)\s*$/)
	{
		$total1=$1;
		next;
	}
	if(/^\s*(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		if(defined $n11{$1}{$2})
		{
			print STDERR "ERROR($0):
	Bigram <$1<>$2> is repeated in COUNT1 file <$small_file>.\n";
			exit;
		}
		$n11{$1}{$2}=$3;
		if(defined $n1p{$1} && $n1p{$1}!=$4)
		{
			print STDERR "ERROR($0):
	Word <$1> has two different n1p scores in COUNT1 file <$small_file>.\n";
			exit;
		}
		$n1p{$1}=$4;
		if(defined $np1{$2} && $np1{$2}!=$5)
                {
                        print STDERR "ERROR($0):
        Word <$2> has two different np1 scores in COUNT1 file <$small_file>.\n";
                        exit;
                }
		$np1{$2}=$5;
	}
}

# reading bigger file
while(<BIG>)
{
	# total bigrams
	if(/^\s*(\d+)\s*$/)
	{
		$total2=$1;
		$total=$total1+$total2;
		print "$total\n";
		next;
	}
	if(/^\s*(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		if(defined $n11{$1}{$2})
		{
			$n11{$1}{$2}+=$3;
			# mark the bigrams that appear in both files
			$update_n11{$1}{$2}=1;
			# get the updated n11 score
			$n11=$n11{$1}{$2};
		}
		else
		{
			# bigram appearing only in COUNT2
			$n11=$3;
		}
		if(defined $n1p{$1}) 
		{
			# update marginals n1p only once
			if(!defined $update_n1p{$1})
			{
				$n1p{$1}+=$4;
				$update_n1p{$1}=1;
			}
			# get the updated n1p score
			$n1p=$n1p{$1};
		}
		else
		{
			# marginal appearing only in COUNT2
			$n1p=$4;
		}
		if(defined $np1{$2}) 
		{
			# update marginals np1 only once
			if(!defined $update_np1{$2})
			{
				$np1{$2}+=$5;
				$update_np1{$2}=1;
			}
			# get the updated np1 score
			$np1=$np1{$2};
		}
		else
		{
			$np1=$5;
		}
		# printing birgrams from COUNT2
		print "$1<>$2<>$n11 $n1p $np1\n";
	}
}

# printing bigrams appearing only in COUNT1
foreach $word1 (sort keys %n11)
{
	foreach $word2 (sort keys %{$n11{$word1}})
	{
		# avoiding bigrams that appear in COUNT2
		if(!defined $update_n11{$word1}{$word2})
		{
			print "$word1<>$word2<>$n11{$word1}{$word2} $n1p{$word1} $np1{$word2}\n";
		}
	}
}

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: huge-combine.pl [OPTIONS] COUNT1 COUNT2";
        print "\nTYPE huge-combine.pl --help for help\n";
}

#-----------------------------------------------------------------------------

#show help
sub showhelp()
{
        print "Usage:  huge-combine.pl [OPTIONS] COUNT1 COUNT2

Combines two bigram files COUNT1 and COUNT2.

COUNT1 COUNT2
	Bigram files created by count.pl.

OPTIONS:
--help
        Displays this message.
--version
        Displays the version information.
Type 'perldoc huge-combine.pl' to view detailed documentation of 
huge-combine.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "huge-combine.pl      -       Version 0.01\n";
        print "Combines the given two bigram files.\n";
        print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
        print "Date of Last Update:     03/03/2004\n";
}

#############################################################################

