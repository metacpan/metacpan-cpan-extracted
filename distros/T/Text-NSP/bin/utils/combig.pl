#!/usr/local/bin/perl -w

=head1 NAME

combig.pl - Combine frequency counts to determine co-occurrence

=head1 SYNOPSIS

Combines (sums) the frequency counts of bigrams made up of the same pair   
of words in either possible order.  It will   count the number of time two  
words occur together in a bigram  regardless of which one comes first. 

=head1 DESCRIPTION 

=head2 USAGE

 combig.pl [OPTIONS] BIGRAM

=head3 INPUT PARAMETERS

=over 4

=item * BIGRAM

Specify a file of bigram counts created by NSP programs count.pl. 
The entries in BIGRAM will be formatted as follows:

	word1<>word2<>n11 n1p np1  

Here, word1 is followed by word2 n11 times. word1 occurs as the 1st word in 
total n1p bigrams and word2 occurs as the 2nd word in np1 bigrams. 

=item * OPTIONS


 --help

Displays this message.

 --version

Displays the version information.

=back

=head3 OUTPUT

combig.pl produces a count of the number of times two words make up a   
bigram in either order, whereas count.pl produces counts for a single 
fixed ordering. In other words, combig.pl combines the counts of bigrams 
that are composed of the same words but in reverse order. While the 
BIGRAM shows pairs of words forming bigrams, output of combig will show
the pairs of words that are co-occurrences or that co-occur irrespective
of their order.

e.g. if bigrams 

	word1<>word2<>n11 n1p np1 
and 
	word2<>word1<>m11 m1p mp1 

are found in BIGRAM file, then combig.pl treats these as a single unordered bigram 

	word1<>word2<>n11+m11 n1p+mp1 np1+m1p

where the new bigram will show a combined contingency table in which the order of words doesn't matter. 
		
			word2		~word2
	___________________________________________________________
	 word1	|	n11+m11		n12+m21     | n1p+mp1 
	        |                                   |
	~word1	|	n21+m12		n22+m22-n   | n2p+mp2-n
		___________________________________________________
                        np1+m1p         np2+m2p-n   |  n
here the entry 

=over 4 

=item * (word1,word2)=n11+m11 

shows the number of bigrams having both word1 and word2 in either order 

i.e. word1<>word2 + word2<>word1

=item * (word1,~word2)=n12+m21

shows the number of bigrams having word1 but not word2 at either position

i.e. word1<>~word2 + ~word2<>word1

=item * (~word1,word2)=n21+m12

shows the number of bigrams having word2 but not word1 at either position

i.e. ~word1<>word2 + word2<>~word1

=item * (~word1,~word2)=n22+m22

shows the number of bigrams not having word1 nor word2 at either position

i.e. ~word1<>~word2 + ~word2<>~word1 - n 

where n=total number of bigrams
	
The mathematical proof of how the cell counts in the above contingency table are
counted is explained in section Proof. 

=back

When a bigram appears in only one order i.e. 

word1<>word2<>n11 n1p np1 

appears but 

word2<>word1<>m11 m1p mp1 

does not, then the combined bigram will be same as the original bigram  
that appears. Or in other words, 
	
word1<>word2<>n11 n1p np1

is displayed as it is.

=head2 PROOF OF CORRECTNESS

A bigram word1<>word2<>n11 n1p np1 represents a contingency table 

		  word2		~word2
		--------------------------------------
	word1	n11	|	n12	|	n1p	
			|		|
	~word1	n21	|	n22	|	n2p
		--------------------------------------
		np1	|	np2	|	n

while a bigram word2<>word1<>m11 m1p mp1 represents a contingency table

		  word1		~word1
		--------------------------------------	
	word2	m11	|	m12	|	m1p
			|		|
	~word2	m21	|	m22	|	m2p
		--------------------------------------
		mp1	|	mp2	|	n
		
Here, 

 n11+n12+n21+n22 = n 

Also, 

 m11+m12+m21+m22 = n 

combig.pl combines bigram counts into a single order independant word pair 

 word1<>word2<>n11+m11 n12+m21 n21+m12 

And the corresponding contingency table will be shown as 

			word2		~word2	
		-----------------------------------------
	word1	n11+m11	  |	n12+m21	  |	n1p+mp1
			  |		  |
	~word1	n21+m12	  |	n22+m22-n |	n2p+mp2	
		-----------------------------------------
		np1+m1p	  |	np2+m2p	  |	n 
			

The first cell (n11+m11) shows the #bigrams having word1 and word2 
(irrespective of their positions) i.e. word1<>word2 or word2<>word1 
which is n11+m11.

The second cell (n12+m21) shows the #bigrams having word1 but not 
word2 at any position i.e. word1<>~word2 or ~word2<>word1 which is 
n12+m21.


The third cell (n21+m12) shows the #bigrams having word2 but not word1 
at any position i.e. ~word1<>word2 or word2<>~word1 which is n21+m12. 

The fourth cell (m22+n22-n) shows the #bigrams not having word1 nor
word2 at any position which

 = n - (n11+m11) - (n12+m21) - (n21+m12)

 = n - (n11+n12+n21) - (m11+m12+m21)

 = n - (n-n22) - (n-m22)

 = n22 + m22 - n 


Alternative proof - 

 n22 = m11 + m12 + m21 + X  	(a)

 m22 = n11 + n12 + n21 + X 	(b)

where X = #bigrams not having either word1 or word2. 

as both n22 and m22 have some terms in common which show the 
bigrams not having either word1 or word2. But,

 m11+m12+m21 = n - m22 

Substituting this in eqn (a)

 n22 = n - m22 + X 

Or 

 X = n22 + m22 - n 

Or add (a) and (b) to get 

 n22+m22 = (n11+m11) + (n12+m21) + (n21+m12) + 2X 

rearranging terms, 

 n22+m22 = (n11+n12+n21) + (m11+m12+m21) + 2X

but 

 n11+n12+n21 = n - n22 and 

 m11+m12+m21 = n - m22 

Hence, 

 n22+m22 = (n-n22) + (n-m22) + 2X

 2(n22+m22-n) = 2X

Or 

 (n22+m22-n) = X

which is the fourth cell count. 


=head2 Viewing Bigrams as Graphs

In bigrams, the order of words is important. Bigram word1<>word2 shows that 
word2 follows word1. Bigrams can be viewed as a directed graph where a bigram 
word1<>word2 will represent a directed edge e from initial vertex word1 to 
terminal vertex word2(word1->word2).

In this case, 

n11, which is the number of times bigram word1<>word2 occurs, becomes 
the weight of the directed edge word1->word2. 

n1p, which is the number of bigrams having word1 at 1st position, becomes
the out degree of vertex word1

and 

np1, which is the number of bigrams having word2 at 2nd position, becomes
the in degree of vertex word2

combig.pl creates a new list of word pairs from these bigrams such that the 
order of words can be ignored. Viewed another way, it converts the directed 
graph of given bigrams to an undirected graph showing new word pairs.

A pair say 

	word1<>word2<>n11 n1p np1 

shown in the output of combig can be viewed as an undirected edge joining 
word1 and word2 having weight n11. If we count the degree of vertex word1 it 
will be n1p and degree of vertex word2 will be np1. 

=head1 AUTHORS

 Amruta Purandare, pura0010@d.umn.edu
 Ted Pedersen, tpederse@d.umn.edu

 Last update 03/22/04 by ADP

This work has been partially supported by a National Science Foundation
Faculty Early CAREER Development award (#0092784).

=head1 BUGS

=head1 SEE ALSO

http://www.d.umn.edu/~tpederse/nsp.html

=head1 COPYRIGHT

Copyright (c) 2004, Amruta Purandare and Ted Pedersen

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

# show minimal usage message if no arguments
if($#ARGV<0)
{
        &showminimal();
        exit;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the Bigram file ...\n";
        exit;
}
#accept the input file name
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Bigram file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening Bigram file <$infile>.\n";

##############################################################################

$line_num=0;
while(<IN>)
{
	$line_num++;
	# shows total number of bigrams
	if(/^\s*\d+\s*$/)
	{
		$total_big=$_;
	}
        # trimming extra spaces
        chomp;
        s/\s+$//g;
        s/^\s+//g;
        s/\s+/ /g;
	# handling non-bigram lines
        if(/^[\s\d]*$/ || /^\@/)
        {
                next;
        }

        # ------------------------------
        # Checking for Valid bigram line
        # ------------------------------
        $check_bigram=$_;
        $cnt=0;
        #count how many times <> occurs
        while($check_bigram=~/<>/)
        {
                $cnt++;
                $check_bigram=$';
        }
        #should be 2 for bigrams
        if($cnt!=2)
        {
                print STDERR "ERROR($0):
	Line <$line_num> in Bigram file <$infile> is not formatted like the
        bigram output of count.pl in NSP.\n";
                exit;
        }

	# extracting word pairs forming this bigram
	if(/^(.*)<>(.*)<>(\d+)\s+(\d+)\s+(\d+)\s*$/)
        {
		if(defined $n11{$1}{$2})
		{
			print STDERR "ERROR($0):
	Bigram \"$1<>$2\" is repeated in Bigram file <$infile>.\n";
			exit;
		}
		# if the reverse bigram is already seen 
		if(defined $n11{$2}{$1})
		{
			# new n11=n11{w2}{w1}+n11{w1}{w2}
			$n11{$2}{$1}+=$3;
		}
		# make a new bigram entry 
		else
		{
			$n11{$1}{$2}=$3;
		}
		# marg stores total #pairs
		# in which a word occurs
		$marg{$1}+=$3;
		$marg{$2}+=$3;
        }
        else
        {
                print STDERR "ERROR($0):
	Line <$line_num> in Bigram file <$infile> is not formatted like the 
	bigram output of count.pl in NSP.\n";
                exit;
        }
}

if(defined $total_big)
{
	print $total_big;
}
else
{
	print STDERR "ERROR($0):
	Bigram file <$infile> should show the total number of bigrams.\n";
	exit;
}

foreach $w1 (keys %n11)
{
	foreach $w2 (keys %{$n11{$w1}})
	{
		print "$w1<>$w2<>$n11{$w1}{$w2} $marg{$w1} $marg{$w2}\n";
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
        print "Usage: combig.pl [OPTIONS] BIGRAM";
        print "\nTYPE combig.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  combig.pl [OPTIONS] BIGRAM 

Combines bigrams that are composed of same pair of words but in reverse orders. 

BIGRAM 
	Should be an output created by count.pl program of NSP package.

OPTIONS:
--help
        Displays this message.
--version
        Displays the version information.

Type 'perldoc combig.pl' to view detailed documentation of combig.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "combig.pl      -         Version 0.02\n";
        print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
        print "Date of Last Update:     03/22/2004\n";
}

#############################################################################

