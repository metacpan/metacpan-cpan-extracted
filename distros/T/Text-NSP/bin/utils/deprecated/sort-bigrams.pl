#!/usr/local/bin/perl -w

=head1 NAME

sort-bigrams.pl - Sort output from count.pl or statistic.pl in descending order based on frequency or association score

=head1 SYNOPSIS

Sorts a given bigram file in the descending order of the bigram scores.

=head1 USGAE

sort-bigrams.pl [OPTIONS] BIGRAM

=head1 INPUT

=head2 Required Arguments:

=head3 BIGRAM

Should be a bigram input file to be sorted. A BIGRAM file created by 
count.pl or statistic.pl is already sorted in the descending order of the 
bigram scores. A BIGRAM output of combig.pl or huge-combine.pl is 
however un-sorted and could be sorted using this program.

All lines in BIGRAM file should be formatted as -

 word1<>word2<>n11 n1p np1

Or as -

 word1<>word2<>rank score n11 n1p np1

=head2 Optional Arguments:

=head4 --frequency F

Bigrams with counts/scores less than F will not be displayed. The ignored 
bigrams are however not removed from the sample and their counts are
still counted in the total bigrams and in the marginal word frequencies.
In other words, the behavior of this option is like count.pl's --frequency 
option.

=head4 --remove L

Bigrams with counts/scores less than L are completely removed from the sample.
Their counts do not affect any marginal totals. In other words, this option
has the same effect as count.pl's --remove option.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

sort-bigrams.pl shows given BIGRAMs in the descending order of their counts/
scores.

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

#                               THE CODE STARTS HERE

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
GetOptions ("help","version","remove=f","frequency=f");
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

# show minimal usage message if no arguments
if($#ARGV<0)
{
        &showminimal();
        exit;
}

if(defined $opt_remove && defined $opt_frequency)
{
	print STDERR "ERROR($0):
	--remove and --frequency can't be both used simultaneously.\n";
	exit;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

$bigfile=$ARGV[0];
open(BIG,$bigfile) || die "ERROR($0):
	Error(code=$!) in opening BIGRAM file <$bigfile>.\n";

$line_num=0;
while(<BIG>)
{
	$line_num++;
	# first line
	if(/^(\d+)\s*$/)
	{
		if($line_num==1)
		{
			$total=$1;
		}
		else
		{
			print STDERR "ERROR($0):
	Line $line_num in BIGRAM file <$bigfile> should be formatted as 
	the bigram output of NSP.\n";
			exit;
		}
		next;
	}
	if(/^(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		$word1=$1;
		$word2=$2;
		$n11=$3;
		$n1p=$4;
		$np1=$5;
		$score=$n11;
		$big_string=$_;
	}
	elsif(/(.*)<>(.*)<>\d+\s+(-?\d+\.?\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		$word1=$1;
		$word2=$2;
		$score=$3;
		$n11=$4;
		$n1p=$5;
		$np1=$6;
		$big_string=$_;
	}
	else
	{
		print STDERR "ERROR($0):
	Line $line_num in BIGRAM file <$bigfile> should be formatted as the
	Bigram output of NSP.\n";
		exit;
	}
	if(defined $opt_frequency && $score < $opt_frequency)
	{
		next;
	}
	if(defined $opt_remove && $score < $opt_remove)
	{
		$total-=$n11;
		$sub_n1p{$word1}+=$n11;
		$sub_np1{$word2}+=$n11;
		next;
	}
	if(!defined $bigrams{$score})
	{
		$bigrams{$score}="";
	}
	if($big_string=~/<\|\|>/)
	{
		print STDERR "ERROR($0):
	Detected internal separator string <||> at line $line_num in BIGRAM
	file <$bigfile>.\n";
		exit 1;
	}
	$bigrams{$score}.=$big_string."<||>";
}

print "$total\n";
foreach $score (sort {$b <=> $a} keys %bigrams)
{
	# remove last <||>
	if($bigrams{$score}=~/<\|\|>$/) { $bigrams{$score}=~s/<\|\|>$//; }

	# get all bigrams with this score
	@big_strings=split(/<\|\|>/,$bigrams{$score});
	foreach $bigram (@big_strings)
	{
		# subtract the removed bigram counts if 
		# this bigram shares words with the removed ones
		if(defined $opt_remove)
		{
			if($bigram=~/^(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
			{
				$word1=$1;
				$word2=$2;
				$n11=$3;
				$n1p=$4;
				$np1=$5;
				if(defined $sub_n1p{$word1})
				{
					$n1p-=$sub_n1p{$word1};
				}
				if(defined $sub_np1{$word2})
				{
					$np1-=$sub_np1{$word2};
				}
				print "$word1<>$word2<>$n11 $n1p $np1\n";
			}
			elsif($bigram=~/(.*)<>(.*)<>(\d+)\s+(-?\d+\.?\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
			{
				$word1=$1;
				$word2=$2;
				$rank=$3;
				$score=$4;
				$n11=$5;
				$n1p=$6;
				$np1=$7;
				if(defined $sub_n1p{$word1})
                                {
                                        $n1p-=$sub_n1p{$word1};
                                }
                                if(defined $sub_np1{$word2})
                                {
                                        $np1-=$sub_np1{$word2};
                                }
                                print "$word1<>$word2<>$rank $score $n11 $n1p $np1\n";
			}
			else
			{
				print STDERR "ERROR($0):
	Hmmm, Weird problem ! Can't really say why this happened but 
	looks like a bug in the program.\n";
				exit;
			}
		}
		else
		{
			print $bigram;
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
        print "Usage: sort-bigrams.pl [OPTIONS] BIGRAM";
        print "\nTYPE sort-bigrams.pl --help for help\n";
}

#-----------------------------------------------------------------------------

#show help
sub showhelp()
{
        print "Usage:  sort-bigrams.pl [OPTIONS] BIGRAM

Sorts a given BIGRAM file in the descending order of the bigram scores.

BIGRAM
	Should be a bigram count/score file that is to be sorted.

OPTIONS:
--frequency F
	Bigrams with counts/scores less than F will not be displayed.
--remove L
	Bigrams with counts/scores less than L are removed from the sample.
--help
        Displays this message.
--version
        Displays the version information.
Type 'perldoc sort-bigrams.pl' to view detailed documentation of this program.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "sort-bigrams.pl      -       Version 0.03";
        print "
Sorts a given bigram file in the descending order of the bigram scores.\n";
        print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
        print "Date of Last Update:     06/14/2004\n";
}

#############################################################################

