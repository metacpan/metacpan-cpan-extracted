#!/usr/local/bin/perl -w

=head1 NAME

reduce-count.pl - Reduce size of feature space by removing words not in evaluation data

=head1 SYNOPSIS

reduce-count.pl [OPTIONS] BIGRAM UNIGRAM

The features found in training data are defined in a bigram file 'bigram':

 cat bigram

Output =>

 1491
 at<>least<>3 7 3
 co<>occurrences<>3 5 3
 be<>a<>3 13 25
 General<>Public<>3 3 3
 of<>test<>3 41 9
 file<>bigfile<>3 26 6
 given<>set<>3 7 5

The unigrams that occur in the evaluation data are defined in a file 'unigram' :

 cat unigram

Output => 

 at<>
 be<>
 test<>

Now remove any bigram that does not contain at least one of the words in the unigram 
file: 

 reduce-count.pl cout uni

Output => 

 1491
 at<>least<>3 7 3
 be<>a<>3 13 25
 of<>test<>3 41 9

Type C<reduce-count.pl> for a quick summary of options

=head1 DESCRIPTION

This program removes all bigrams from the given BIGRAM file that do not  
include at least one constituent word from the UNIGRAM file. Note that 
this can also be applied on a co-occurrence file. 

The intent of this in SenseClusters is to allow a user to significantly 
reduce the number of features in a BIGRAM file by including only those 
that contain at least one word from the test data. In this use case, a 
user would have a BIGRAM file of features found in training data, and 
would also have a UNIGRAM file from a set of test data. The intuition 
behind this is that we know that a bigram made up of words that do not 
occur in the test data will not be needed for creating representations of 
the test data for clustering. 

Note that this program DOES NOT adjust the any of the counts as found in 
the BIGRAM file. Thus, the intent of this program is to make it possible 
to reduce the number of features that must be searched through during 
feature matching, for example. However, it is not intended to adjust the 
sample size or counts of bigrams. The counts remain the same, so any 
conclusions drawn from statistic.pl, for example, are not affected by this 
program. 

=head1 INPUT

=head2 Required Arguments:

=head3 BIGRAM

Should be a bigram file created by NSP programs, count.pl, statistic.pl
or combig.pl. Each line containing a word pair (bigram or co-occurrences) 
should show either of the following forms:

	word1<>word2<>n11 n1p np1 	(if created by count or combig)

	word1<>word2<>rank score n11 n1p np1 (if created by statistic)

Any line that is not formatted like above is simply displayed as it is
assuming that its printed by the --extended option in NSP.

=head3 UNIGRAM

Should be a unigram output of NSP. Each line in the UNIGRAM file should show either of 
the following forms:

	word<>

	word<>n

where n is the frequency count of the word.

=head2 Optional Arguments:

=head3 --help

Displays the summary of command line options.

=head3 --version

Displays the version information.

=head1 OUTPUT

reduce-count.pl displays all lines in the given BIGRAM file except those that
are formatted as follows:

        word1<>word2<>n11 n1p np1

        word1<>word2<>rank score n11 n1p np1 

and neither word1 nor word2 are listed in the given UNIGRAM file.

=head1 SYSTEM REQUIREMENTS

=over
=item Ngram Statistics Package - L<http://search.cpan.org/dist/Test-NSP>
=back

=head1 BUGS

This program is very conservative in what it removes from a given set of input 
bigrams. Just because a unigram occurs in the test set of data does not mean that a 
bigram that contains it must occur. So reduce-count.pl very likely leaves in place 
some bigrams that do not occur in a given set of test data. However, it can be applied 
to bigrams, co-occurrence and target-co-occurrences equally well, since it is only 
looking for a unigram and not an exact match between bigrams (where order matters).

It must also be remembered that this program was originally intended for use with 
huge-count.pl, a program from the Ngram Statistics Package that calculates count 
information on very large corpora. So if you have 1,000,000 different bigrams,
then removing all of those that don't contain a given set of unigrams drawn from a 
much smaller sample of test data will make a very large difference. 

It seems like it should be possible to be more aggressive and find, for example, the 
intersection of the bigrams found in training and test data, and reset the features to 
that. 

It also seems like it might be useful to reduce the number of unigram features in the 
same way.

This might be replaceable with a simple program that finds the intersection of 
features observed in training data and those that actually exist in the test data. 

=head1 AUTHORS

Amruta Purandare, University of Pittsburgh

Ted Pedersen, University of Minnesota, Duluth
tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2002-2008, Amruta Purandare and Ted Pedersen

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

#accept the BIGRAM file name
$bigfile=$ARGV[0];
if(!-e $bigfile)
{
        print STDERR "ERROR($0):
        BIGRAM file <$bigfile> doesn't exist...\n";
        exit;
}
open(BIG,$bigfile) || die "Error($0):
        Error(code=$!) in opening BIGRAM file <$bigfile>.\n";

#accept the UNIGRAM file name
$unifile=$ARGV[1];
if(!-e $unifile)
{
        print STDERR "ERROR($0):
        UNIGRAM file <$unifile> doesn't exist...\n";
        exit;
}
open(UNI,$unifile) || die "Error($0):
        Error(code=$!) in opening UNIGRAM file <$unifile>.\n";

##############################################################################

# read the UNIGRAM file and store the list of unigrams
# we assume that the UNIGRAM file is small and loadable

$line_num=0;
while(<UNI>)
{
	$line_num++;
	# checking if valid unigram file
	if($line_num==1 && /^\d+\s*$/)
	{
		next;
	}
	$uni_string=$_;
	$diamonds=0;
	while(/<>/)
	{
		$_=$';
		$diamonds++;
	}
	if($diamonds != 1)
	{
		print STDERR "ERROR($0):
	UNIGRAM file $unifile is not a valid UNIGRAM output of NSP at line
	$line_num.\n";
		exit 1;
	}
	if($uni_string=~/^(.*)<>\d*\s*$/)
	{
		$unigram{$1}=1;
	}
}

# reading the BIGRAM file and printing bigrams that have
# at least one of the words present in the UNIGRAM

$line_num=0;
while(<BIG>)
{
	if(/<>/)
	{
		if(/^(.*)<>(.*)<>\d+\s+\d+\s+\d+\s*$/ || /^(.*)<>(.*)<>\d+\s+-?\d*\.?\d+\s+\d+\s+\d+\s+\d+\s*$/)
		{
			if(!defined $unigram{$1} && !defined $unigram{$2})
			{
				next;
			}
		}
		else
		{
			print STDERR "ERROR($0):
	BIGRAM file $bigfile is not a valid bigram output of NSP at line $line_num.\n";
			exit 1;
		}
	}
	print;
}

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: reduce-count.pl [OPTIONS] BIGRAM UNIGRAM";
        print "\nTYPE reduce-count.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  reduce-count.pl [OPTIONS] BIGRAM UNIGRAM

Reduces the number of entries in the given BIGRAM file by removing those 
bigrams where both words do not appear in the UNIGRAM file. 

BIGRAM
	Bigram output of NSP showing the bigram counts or statistical 
        scores. This can also be a file of co-occurrences from combig.pl

UNIGRAM
	Unigram output of NSP showing the unigrams with their optional 
        frequency counts.

OPTIONS:

--help
        Displays this message.
--version
        Displays the version information.
Type 'perldoc reduce-count.pl' to view the detailed documentation of 
reduce-count.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print '$Id: reduce-count.pl,v 1.13 2008/03/30 04:19:01 tpederse Exp $';
	print "\nRemove features that don't occur in evaluation data\n";
##        print "\nCopyright (c) 2002-2006, Ted Pedersen & Amruta Purandare\n";
###        print "Date of Last Update:     05/25/2004\n";
}

#############################################################################

