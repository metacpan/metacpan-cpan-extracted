#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

=head1 NAME

sort-trigrams.pl - Sort output from count.pl or statistic.pl in descending order based on frequency or association score

=head1 SYNOPSIS

Sorts a given trigram file in the descending order of the trigram scores.

=head1 USGAE

sort-trigrams.pl [OPTIONS] TRIGRAM

=head1 INPUT

=head2 Required Arguments:

=head3 TRIGRAM

Should be a trigram input file to be sorted. A TRIGRAM file created by 
count.pl or statistic.pl is already sorted in the descending order of the 
trigram scores. A TRIGRAM output of combig.pl or huge-combine.pl is 
however un-sorted and could be sorted using this program.

All lines in TRIGRAM file should be formatted as -

 word1<>word2<>word3<>n111 n1pp np1p npp1 n11p n1p1 np11

Or as -

 word1<>word2<>word3<>rank score n111 n1pp np1p npp1 n11p n1p1 np11

=head2 Optional Arguments:

=head4 --frequency F

Trigrams with counts/scores less than F will not be displayed. The ignored 
trigrams are however not removed from the sample and their counts are
still counted in the total trigrams and in the marginal word frequencies.
In other words, the behavior of this option is like count.pl's --frequency 
option.

=head4 --remove L

Trigrams with counts/scores less than L are completely removed from the sample.
Their counts do not affect any marginal totals. In other words, this option
has the same effect as count.pl's --remove option.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

sort-trigrams.pl shows given TRIGRAMs in the descending order of their counts/
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
	Error(code=$!) in opening TRIGRAM file <$bigfile>.\n";

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
	Line $line_num in TRIGRAM file <$bigfile> should be formatted as 
	the trigram output of NSP.\n";
			exit;
		}
		next;
	}
#	if(/^(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
	if(/^\s*(.*)<>(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		$word1=$1;
		$word2=$2;
		$word3=$3;
		$n111=$4;
		$n1pp=$5;
		$np1p=$6;
		$npp1=$7;
		$n11p=$8;
		$n1p1=$9;
		$np11=$10;
		$score=$n111;
		$big_string=$_;
	}
	elsif(/\s*(.*)<>(.*)<>(.*)<>\d+\s+(-?\d+\.?\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		$word1=$1;
		$word2=$2;
		$word3=$3;
		$score=$4;
		$n111=$5;
		$n1pp=$6;
		$np1p=$7;
		$npp1=$8;
		$n11p=$9;
		$n1p1=$10;
		$np11=$11;
		$big_string=$_;
	}
	else
	{
		print STDERR "ERROR($0):
	Line $line_num in TRIGRAM file <$bigfile> should be formatted as the
	Trigram output of NSP.\n";
		exit;
	}
	if(defined $opt_frequency && $score < $opt_frequency)
	{
		next;
	}
	if(defined $opt_remove && $score < $opt_remove)
	{
		$total-=$n111;
		$sub_n1pp{$word1}+=$n111;
		$sub_np1p{$word2}+=$n111;
		$sub_npp1{$word3}+=$n111;
		$sub_n11p{$word1}{$word2}+=$n111;
		$sub_n1p1{$word1}{$word3}+=$n111;
		$sub_np11{$word2}{$word3}+=$n111;
		next;
	}
	if(!defined $trigrams{$score})
	{
		$trigrams{$score}="";
	}
	if($big_string=~/<\|\|>/)
	{
		print STDERR "ERROR($0):
	Detected internal separator string <||> at line $line_num in TRIGRAM
	file <$bigfile>.\n";
		exit 1;
	}
	$trigrams{$score}.=$big_string."<||>";
}

print "$total\n";
foreach $score (sort {$b <=> $a} keys %trigrams)
{
	# remove last <||>
	if($trigrams{$score}=~/<\|\|>$/) { $trigrams{$score}=~s/<\|\|>$//; }

	# get all trigrams with this score
	@big_strings=split(/<\|\|>/,$trigrams{$score});
	foreach $trigram (@big_strings)
	{
		# subtract the removed trigram counts if 
		# this trigram shares words with the removed ones
		if(defined $opt_remove)
		{
#			if($trigram=~/^(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
			if($trigram=~/^\s*(.*)<>(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
			{
				$word1=$1;
				$word2=$2;
				$word3=$3;
				$n111=$4;
				$n111=$4;
				$n1pp=$5;
				$np1p=$6;
				$npp1=$7;
				$n11p=$8;
				$n1p1=$9;
				$np11=$10;
				if(defined $sub_n1pp{$word1})
				{
					$n1pp-=$sub_n1pp{$word1};
				}
				if(defined $sub_np1p{$word2})
				{
					$np1p-=$sub_np1p{$word2};
				}
				if(defined $sub_npp1{$word3})
				{
					$npp1-=$sub_npp1{$word3};
				}
				if(defined $sub_n11p{$word1}{$word2})
				{
					$n11p-=$sub_n11p{$word1}{$word2};
				}
				if(defined $sub_n1p1{$word1}{$word3})
				{
					$n1p1-=$sub_n1p1{$word1}{$word3};
				}
				if(defined $sub_np11{$word2}{$word3})
				{
					$np11-=$sub_np11{$word2}{$word3};
				}

				print "$word1<>$word2<>$word3<>$n111 $n1pp $np1p $npp1 $n11p $n1p1 $np11\n";
			}
#			elsif($trigram=~/(.*)<>(.*)<>(\d+)\s+(-?\d+\.?\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
			elsif($trigram=~/\s*(.*)<>(.*)<>(.*)<>(\d+)\s+(-?\d+\.?\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/)
			{
				$word1=$1;
				$word2=$2;
				$word3=$3;
				$rank=$4;
				$score=$5;
				$n111=$6;
				$n1pp=$7;
				$np1p=$8;
				$npp1=$9;
				$n11p=$10;
				$n1p1=$11;
				$np11=$12;

				if(defined $sub_n1pp{$word1})
				{
					$n1pp-=$sub_n1pp{$word1};
				}
				if(defined $sub_np1p{$word2})
				{
					$np1p-=$sub_np1p{$word2};
				}
				if(defined $sub_npp1{$word3})
				{
					$npp1-=$sub_npp1{$word3};
				}
				if(defined $sub_n11p{$word1}{$word2})
				{
					$n11p-=$sub_n11p{$word1}{$word2};
				}
				if(defined $sub_n1p1{$word1}{$word3})
				{
					$n1p1-=$sub_n1p1{$word1}{$word3};
				}
				if(defined $sub_np11{$word2}{$word3})
				{
					$np11-=$sub_np11{$word2}{$word3};
				}

				print "$word1<>$word2<>$word3<>$rank $score $n111 $n1pp $np1p $npp1 $n11p $n1p1 $np11\n";
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
			print $trigram;
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
        print "Usage: sort-trigrams.pl [OPTIONS] TRIGRAM";
        print "\nTYPE sort-trigrams.pl --help for help\n";
}

#-----------------------------------------------------------------------------

#show help
sub showhelp()
{
        print "Usage:  sort-trigrams.pl [OPTIONS] TRIGRAM

Sorts a given TRIGRAM file in the descending order of the trigram scores.

TRIGRAM
	Should be a trigram count/score file that is to be sorted.

OPTIONS:
--frequency F
	Trigrams with counts/scores less than F will not be displayed.
--remove L
	Trigrams with counts/scores less than L are removed from the sample.
--help
        Displays this message.
--version
        Displays the version information.
Type 'perldoc sort-trigrams.pl' to view detailed documentation of this program.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "sort-trigrams.pl      -       Version 0.01";
        print "
Sorts a given trigram file in the descending order of the trigram scores.\n";
        print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
	print "Modified to support trigrams by Cyrus Shaoul.\n";
        print "Date of Last Update:     09/15/2009\n";
}

#############################################################################

