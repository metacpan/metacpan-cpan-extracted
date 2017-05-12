#!/usr/bin/perl -w

# huge-combine3.pl : Combines trigram files.

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

=head1 NAME

huge-combine3.pl - Combine two trigram files created by count.pl into single file 

=head1 SYNOPSIS

Combines two trigram files created by count.pl into a single trigram file.

=head1 USGAE

huge-combine3.pl [OPTIONS] COUNT1 COUNT2

=head1 INPUT

=head2 Required Arguments:

=head3 COUNT1 and COUNT2

combine-count.pl takes two trigram files created by count.pl as input.
If COUNT1 and COUNT2 are of unequal sizes, it is strongly recommended 
that COUNT1 should be the smaller file and COUNT2 should be the lager 
trigram file.

Each line in files COUNT1, COUNT2 should be formatted as -

word1<>word2<>n11 n1p np1

where word1<>word2 is a trigram, n11 is the joint frequency score of this
trigram, n1p is the number of trigrams in which word1 is the first word,
while np1 is the number of trigrams having word2 as the second word.

=head2 Optional Arguments:

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output displays all trigrams that appear either in COUNT1 (inclusive) or
in COUNT2 along with their updated scores. Scores are updated such that -

=over

=item 1: 

If a trigram appears in both COUNT1 and COUNT2, their n11 scores are added.

e.g. If COUNT1 contains a trigram 
	word1<>word2<>n11 n1p np1
and COUNT2 has a trigram
	word1<>word2<>m11 m1p mp1

Then, the new n11 score of trigram word1<>word2 is n11+m11

=item 2:

If the two trigrams belonging to COUNT1 and COUNT2 share a commom first word, 
their n1p scores are added.

e.g. If COUNT1 contains a trigram
	word1<>word2<>n11 n1p np1
and if COUNT2 contains a trigram
	word1<>word3<>m11 m1p mp1

Then, the n1p marginal score of word1 is updated to n1p+m1p

=item 3:

If the two trigrams belonging to COUNT1 and COUNT2 share a commom second word,
their np1 scores are added.

e.g. If COUNT1 contains a trigram
        word1<>word2<>n11 n1p np1
and if COUNT2 contains a trigram
        word3<>word2<>m11 m1p mp1

Then, the np1 marginal score of word2 is updated to np1+mp1

=back

=head1 AUTHOR

Amruta Purandare, Ted Pedersen.
University of Minnesota at Duluth.

=head1 COPYRIGHT

Copyright (c) 2004, 2009

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota, Duluth.
tpederse@umn.edu

Cyrus Shaoul, University of Alberta, Edmonton
cyrus.shaoul@ualberta.ca

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

# loading trigrams from smaller file into memory
while(<SMALL>)
{
	if(/^\s*(\d+)\s*$/)
	{
		$total1=$1;
		next;
	}
#	if(/^\s*(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
# 3-gram version
	if(/^\s*(.*)<>(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		if(defined $n111{$1}{$2}{$3})
		{
			print STDERR "ERROR($0):
	Trigram <$1<>$2<>$3> is repeated in COUNT1 file <$small_file>.\n";
			exit;
		}
		$n111{$1}{$2}{$3}=$4;
		if(defined $n1pp{$1} && $n1pp{$1}!=$5)
		{
			print STDERR "ERROR($0):
	Word <$1> has two different n1pp scores in COUNT1 file <$small_file>.\n";
			exit;
		}
		$n1pp{$1}=$5;
		if(defined $np1p{$2} && $np1p{$2}!=$6)
                {
                        print STDERR "ERROR($0):
        Word <$2> has two different np1p scores in COUNT1 file <$small_file>.\n";
                        exit;
                }
		$np1p{$2}=$6;
		if(defined $npp1{$3} && $npp1{$3}!=$7)
                {
                        print STDERR "ERROR($0):
        Word <$2> has two different npp1 scores in COUNT1 file <$small_file>.\n";
                        exit;
                }
		$npp1{$3}=$7;
		if(defined $n11p{$1}{$2} && $n11p{$1}{$2}!=$8)
                {
                        print STDERR "ERROR($0):
        Word <$2> has two different n11p scores in COUNT1 file <$small_file>.\n";
                        exit;
                }
		$n11p{$1}{$2}=$8;
		if(defined $n1p1{$1}{$3} && $n1p1{$1}{$3}!=$9)
                {
                        print STDERR "ERROR($0):
        Word <$2> has two different n1p1 scores in COUNT1 file <$small_file>.\n";
                        exit;
                }
		$n1p1{$1}{$3}=$9;
		if(defined $np11{$2}{$3} && $np11{$2}{$3}!=$10)
                {
                        print STDERR "ERROR($0):
        Word <$2> has two different np11 scores in COUNT1 file <$small_file>.\n";
                        exit;
                }
		$np11{$2}{$3}=$10;
	}
}

# reading bigger file
while(<BIG>)
{
	# total trigrams
	if(/^\s*(\d+)\s*$/)
	{
		$total2=$1;
		$total=$total1+$total2;
		print "$total\n";
		next;
	}
#	if(/^\s*(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
	if(/^\s*(.*)<>(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		if(defined $n111{$1}{$2}{$3})
		{
			$n111{$1}{$2}{$3}+=$4;
			# mark the trigrams that appear in both files
			$update_n111{$1}{$2}{$3}=1;
			# get the updated n11 score
			$n111=$n111{$1}{$2}{$3};
		}
		else
		{
			# trigram appearing only in COUNT2
			$n111=$4;
		}
		if(defined $n1pp{$1}) 
		{
			# update marginals n1p only once
			if(!defined $update_n1pp{$1})
			{
				$n1pp{$1}+=$5;
				$update_n1pp{$1}=1;
			}
			# get the updated n1p score
			$n1pp=$n1pp{$1};
		}
		else
		{
			# marginal appearing only in COUNT2
			$n1pp=$5;
		}
		if(defined $np1p{$2}) 
		{
			# update marginals np1 only once
			if(!defined $update_np1p{$2})
			{
				$np1p{$2}+=$6;
				$update_np1p{$2}=1;
			}
			# get the updated np1 score
			$np1p=$np1p{$2};
		}
		else
		{
			$np1p=$6;
		}

		if(defined $npp1{$3}) 
		{
			# update marginals np1 only once
			if(!defined $update_npp1{$3})
			{
				$npp1{$3}+=$7;
				$update_npp1{$3}=1;
			}
			# get the updated np1 score
			$npp1=$npp1{$3};
		}
		else
		{
			$npp1=$7;
		}

		if(defined $n11p{$1}{$2}) 
		{
			# update marginals np1 only once
			if(!defined $update_n11p{$1}{$2})
			{
				$n11p{$1}{$2}+=$8;
				$update_n11p{$1}{$2}=1;
			}
			# get the updated np1 score
			$n11p=$n11p{$1}{$2};
		}
		else
		{
			$n11p=$8;
		}


		if(defined $n1p1{$1}{$3}) 
		{
			# update marginals np1 only once
			if(!defined $update_n1p1{$1}{$3})
			{
				$n1p1{$1}{$3}+=$9;
				$update_n1p1{$1}{$3}=1;
			}
			# get the updated np1 score
			$n1p1=$n1p1{$1}{$3};
		}
		else
		{
			$n1p1=$9;
		}



		if(defined $np11{$2}{$3}) 
		{
			# update marginals np1 only once
			if(!defined $update_np11{$2}{$3})
			{
				$np11{$2}{$3}+=$10;
				$update_np11{$2}{$3}=1;
			}
			# get the updated np1 score
			$np11=$np11{$2}{$3};
		}
		else
		{
			$np11=$10;
		}

		# printing trigrams from COUNT2
		print "$1<>$2<>$3<>$n111 $n1pp $np1p $npp1 $n11p $n1p1 $np11\n";
	}
}

# printing trigrams appearing only in COUNT1
foreach $word1 (sort keys %n111)
{
    foreach $word2 (sort keys %{$n111{$word1}})
    {
	foreach $word3 (sort keys %{$n111{$word1}{$word2}})
	{
	    # avoiding trigrams that appear in COUNT2
	    if(!defined $update_n111{$word1}{$word2}{$word3})
	    {
		print "$word1<>$word2<>$word3<>$n111{$word1}{$word2}{$word3} $n1pp{$word1} $np1p{$word2} $npp1{$word3} $n11p{$word1}{$word2} $n1p1{$word1}{$word3} $np11{$word2}{$word3}\n";
	    }
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
        print "Usage: huge-combine3.pl [OPTIONS] COUNT1 COUNT2";
        print "\nTYPE huge-combine3.pl --help for help\n";
}

#-----------------------------------------------------------------------------

#show help
sub showhelp()
{
        print "Usage:  huge-combine3.pl [OPTIONS] COUNT1 COUNT2

Combines two trigram files COUNT1 and COUNT2.

COUNT1 COUNT2
	Trigram files created by count.pl.

OPTIONS:
--help
        Displays this message.
--version
        Displays the version information.
Type 'perldoc huge-combine3.pl' to view detailed documentation of 
huge-combine3.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "huge-combine3.pl      -       Version 0.01\n";
        print "Combines the given two trigram files.\n";
        print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
        print "Date of Last Update:     03/03/2004\n";
}

#############################################################################

