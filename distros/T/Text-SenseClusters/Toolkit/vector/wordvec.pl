#!/usr/local/bin/perl -w

=head1 NAME

wordvec.pl - Construct word vectors from bigram or co-occurrence matrices

=head1 SYNOPSIS

 wordvec.pl [OPTIONS] WORD_PAIRS

=head1 DESCRIPTION

Constructs word vectors from the given WORD_PAIRS.

=head1 INPUT

=head2 Required Arguments:

=head4 WORD_PAIRS

WORD_PAIRS should be a bigram or co-occurrence pair file as created by 
programs count.pl, statistic.pl or combig.pl from the N-gram Statistics 
package. 

Various ways to create WORD_PAIRS are -

=over

=item 1. Run count.pl alone 

 (WORD_PAIRS show bigram frequency counts)

=item 2. Run count.pl followed by combig.pl

 (WORD_PAIRS show co-occurrence pair frequency counts)

=item 3. Run count.pl followed by statistic.pl

 (WORD_PAIRS show test of association scores of bigrams)

=item 4. Run count.pl followed by combig.pl followed by statistic.pl

 (WORD_PAIRS show test of association scores of co-occurrence pairs)

=back

Cases 1 and 2 will create WORD_PAIRS in format -

	word1<>word2<>n11 n1p np1 

where n11 shows the joint bigram or co-occurrence frequency count

Cases 3 and 4 will create WORD_PAIRS in format -

	word1<>word2<>rank score n11 n1p np1 

where 'score' shows the test of association score of a bigram/co-occurrence 
pair. 

=head2 Optional Arguments:

=head4 --wordorder WORDORD

Allows to retain or ignore the order of the words in the WORD_PAIRS.
The possible options for the value of --wordorder are -

=over 4

=item * nocare

Select --wordorder = nocare when WORD_PAIRS do not show any particular order 
of words. This is applicable only when WORD_PAIRS are created using combig.pl 
as suggested by cases 2 and 4 in the previous section. This tells wordvec 
that WORD_PAIRS show the joint co-occurrence scores of the word pairs.

With wordorder = nocare, wordvec won't allow word pairs in both orders, meaning,
if the pair word1<>word2 appears in the WORD_PAIRS file, pair word2<>word1 
won't be allowed. 

=item * follow [default]

Set --wordorder = follow if WORD_PAIRS are bigrams as created with cases 
1 and 3 shown in the previous section. 

For every word pair word1<>word2, word1 will be assigned a single feature index
and will represent a row in the output word matrix at that index while word2
will be assigned a single dimension index and will represent a column in the 
output word matrix at that index. Assumming that word1 is assigned a feature 
index i and represents ith row and word2 is assigned a dimension index j and
represents jth column, the matrix cell at [i][j] will show the frequency of 
the bigram word1<>word2.

=item * precede

WORD_PAIRS are bigrams same as in --wordorder = follow, however, for every word
pair word1<>word2, word1 is assigned a dimension index and represents a column 
(as against to representing a row/feature when --wordorder=follow) while word2
is assigned a feature index and represents a row (as against to representing 
a dimension/column in --wordorder=follow). Assumming that word1 is assigned a 
dimension index i and represents the ith column, while word2 is assigned a 
feature index j and represents the jth row, frequency score of bigram 
word1<>word2 is shown in the matrix cell at [j][i].

Thus, the output word matrix created by --wordorder = precede is a transpose of
that created by --wordorder = follow.

=back

=head4 --binary 

Creates binary word vectors that show mere presence (by 1) or absence (by 0) of
the feature-dimension pairs. By default, wordvec creates frequency vectors
that show the frequency scores of the word pairs as given in the WORD_PAIRS
file.

=head4 --dense

Creates dense word vectors. By default, output of wordvec will show 
sparse word vectors.

=head4 --feats FEATFILE

Specifies the name of the feature file that lists the words that represent the
rows of the output word association matrix. 

If the FEATFILE exists, words listed in this file define the rows of
the output word matrix. Thus, the FEATFILE specifies the feature words for 
which the word vectors are to be created. 

If the FEATFILE doesn't exist, it is created by wordvec and shows the 
words that represent the rows of the output word matrix. 

=head4 --dims DIMFILE 

DIMFILE is created by wordvec and reports the words that represent the 
columns/dimensions of the output word matrix.

=head4 --target TARGET_REGEX

Specifies a file containing Perl regex/s that define the target word. By
default, target.regex file is assumed to exist in the current directory.
This is only required if --extarget is selected.

=head4 --extarget

This will ignore WORD_PAIRS in which either of the constituent words is a 
target word. Target word can be defined by specifying a target regex file
via --target option or by copying target.regex file to current directory.

=head4 --format FORM

Specifies numeric format for representing each word vector entry.

Possible values of FORM are

 iN   -> integer format allocating total N bytes/digits for each entry

 fN.M -> floating point format allocating total N bytes/digits for each entry of which last M digits show fractional part. 

When --binary is ON, default format is i2 and otherwise default is f16.10.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Consider the following illustration -

Sample WORD_PAIRS input =>

 stir<>soup<>5 21 64
 soup<>plate<>8 70 14
 hot<>soup<>12 173 64
 hot<>plate<>9 173 29
 salt<>pepper<>42 124 121
 taste<>salt<>18 83 84
 add<>salt<>12 157 84
 stir<>lemon<>2 21 53
 lemon<>juice<>2 10 2
 add<>lemon<>3 157 53
 lemon<>pepper<>3 67 120
 stir<>juice<>2 21 27

=over

=item 1. --wordorder = follow or default

Given WORD_PAIRS are treated as bigrams and the order of the words is 
retained such that the 1st word in the bigrams becomes a feature and 
is assigned a unique row index while the 2nd word becomes a dimension and 
is assigned a single column index in the output word matrix.

case (1) Feature file provided via --feats FEATFILE doesn't exist

Feature file is automatically created by wordvec and lists all the word types 
that appear as the 1st words in the given bigrams. i.e. - 

 stir<>
 soup<>
 hot<>
 salt<>
 taste<>
 add<>
 lemon<>

The dimension file created with --dims option will list all the word types 
that appear as the 2nd words in the given bigrams. i.e. -

 soup<>
 plate<>
 pepper<>
 salt<>
 lemon<>
 juice<>

Thus, the bigrams listed in the given WORD_PAIRS file can be viewed in a 
matrix form as -

	  soup<>  plate<>  pepper<>  salt<>  lemon<>  juice<>
 stir<>   5	  0	   0	     0	     2	      2
 soup<>	  0	  8	   0	     0	     0	      0
 hot<>	 12	  9	   0	     0	     0	      0
 salt<>	  0	  0	  42	     0	     0	      0
 taste<>  0	  0	   0	    18       0	      0
 add<>	  0	  0	   0	    12	     3        0
 lemon<>  0	  0	   3	     0	     0	      2

whose rows represent the feature words and columns represent the dimension
words.

=over

=item a. --dense not used

By default, the output word matrix is created in sparse format in which 
the first line shows 

 #rows #cols #nnz 

i.e. number of rows, number of columns and total number of non-zero entries
separated by space.

Each line thereafter shows a sparse word vector of the feature shown on
the corresponding line in the feature file.

A sparse word vector lists pairs of numbers separated by space such that the 
first number in a pair indicates the column index of a non-zero value 
and the second number is the value itself that appears at that index.

Thus, the output of wordvec for the above example, created with --wordorder = 
follow or un-specified will be =>

 7 6 12
 1  5 5  2 6  2
 2  8
 1 12 2  9
 3 42
 4 18
 4 12 5  3
 3  3 6  2

where the 1st line "7 6 12" shows that there are total 7 word vectors 
represented using 6 dimensions with 12 non-zero entries.

Each row thereafter indicates a word vector in sparse format. e.g. 2nd line
shows the word vector of feature stir<>. This vector has total 3 non-zero 
values 5, 2, 2 that occur at indices 1, 5, 6 resp. 

Column index counting starts from 1 to be consistent with Cluto's matrix format.

=item b. --dense used 

When --dense is used, output will show the word matrix in dense format as 

  7 6
  5  0  0  0  2  2
  0  8  0  0  0  0
 12  9  0  0  0  0
  0  0 42  0  0  0
  0  0  0 18  0  0
  0  0  0 12  3  0
  0  0  3  0  0  2

where the first line shows that there are 7 word vectors represented using 6 
dimensions.

=item c. --binary used

When --binary is used, all non-zero bigram scores will be set to 1.

Thus, when --dense is used, output will show 

  7 6
  1  0  0  0  1  1
  0  1  0  0  0  0
  1  1  0  0  0  0
  0  0  1  0  0  0
  0  0  0  1  0  0
  0  0  0  1  1  0
  0  0  1  0  0  1

Otherwise, binary sparse vectors will look like -

 7 6 12
 1  1 5  1 6  1
 2  1
 1  1 2  1
 3  1
 4  1
 4  1 5  1
 3  1 6  1

=back

case (2) Feature file provided via the '--feats FEATFILE' option exists 
and lists the features for which the vectors are to be created. 

Suppose the FEATFILE contains -

 taste<>
 hot<>
 lemon<>
 salt<>

Then, for each bigram word1<>word2, if word1 is one of the above words listed
in the FEATFILE, a unique row index say i is assigned to word1 and a unique
column index say j is assigned to word2. The matrix entry at [i][j] then
indicates the score of the bigram word1<>word2. Thus, for the above example,
the word matrix can be viewed as -

        soup  plate  pepper  salt  juice
 taste     0      0       0    18      0
 hot      12      9       0     0      0
 lemon     0      0       3     0      2
 salt      0      0      42     0      0

The dimension file created with --dims option will show the words that
represent the columns -

 soup<>
 plate<>
 pepper<>
 salt<>
 juice<>

The output of wordvec created with --dense option will look as -

 4 5
 0      0       0    18      0
 12     9       0     0      0
 0      0       3     0      2
 0      0      42     0      0

where, the first line shows that there are 4 features and 5 dimensions.
Each line thereafter shows the word vector of the corresponding feature word.

The following shows the sparse representation of the same matrix when --dense
is not used -

 4 5 6
 4 18
 1 12 2 9
 3 3 5 2
 3 42

where the first line indicates that there are total 4 features, 5 dimensions
and total 6 non-zero entries in the output matrix. Each row after that shows
the 'index value' pair for each non-zero entry at that row, where column
indices start with 1s.

=item 2. --wordorder = precede

Order of words in bigram pairs is retained such that 2nd word becomes a feature
and represents a row while the 1st word becomes a dimension and represents a 
column of the output word matrix. The word matrix thus shows the transpose 
of the bigram matrix created by --wordorder = follow and the cell values 
show how frequently a dimension word precedes a feature word.

The feature file created with --feats option shows the word types that 
appear as the 2nd words in the given bigrams. i.e.

 soup<>
 plate<>
 pepper<>
 salt<>
 lemon<>
 juice<>

while the dimension file created with dims option shows the word types that 
appear as the 1st words in the bigrams. i.e. 

 stir<>
 soup<>
 hot<>
 salt<>
 taste<>
 add<>
 lemon<>

Thus, the word matrix can be seen as 

	 stir<>  soup<>  hot<>  salt<>  taste<>  add<>  lemon<>
 soup<>   5       0       12     0  	0	 0	0
 plate<>  0       8        9	 0	0	 0 	0
 pepper<> 0       0        0    42      0        0      3
 salt<>   0       0        0     0     18       12 	0
 lemon<>  2       0        0     0      0        3	0
 juice<>  2       0	   0     0      0        0      2

When --dense is selected, word vectors displayed on stdout will look as -

  6 7
  5  0 12  0  0  0  0
  0  8  9  0  0  0  0
  0  0  0 42  0  0  3
  0  0  0  0 18 12  0
  2  0  0  0  0  3  0
  2  0  0  0  0  0  2

while by default, output will be sparse as shown by -

 6 7 12
 1  5 3 12
 2  8 3  9
 4 42 7  3
 5 18 6 12
 1  2 6  3
 1  2 7  2

If the feature file is provided, vectors are created for the given feature
words only and dimensions show the words that precede them.

=item 3. --wordorder = nocare

When wordorder is nocare, given WORD_PAIRS are treated as co-occurrence pairs
and the order of words is ignored. 

case (1) Feature file provided via '--feats FEATFILE' option doesnt exist.

In this case, feature and dimension files will be same and will show all 
unique word types encountered in the WORD_PAIRS file irrespective of the 
positions of the words. Each word type in WORD_PAIRS is assigned a unique index 
and represents the row and column of the output word matrix at that index. 
Thus, the output word co-occurrence matrix is square and symmetric.

Feature and dimension files for above example will show =>

 stir<>
 soup<>
 plate<>
 hot<>
 salt<>
 pepper<>
 taste<>
 add<>
 lemon<>
 juice<>

while the word matrix can be seen as 

       stir<>  soup<>  plate<>  hot<>  salt<>  pepper<>  taste<>  add<> lemon<> juice<>
 stir<>   0     5       0        0      0       0         0        0      2       2
 soup<>   5     0       8       12      0       0         0        0      0       0
 plate<>  0     8       0        9      0       0         0        0      0       0
 hot<>    0    12       9        0      0       0         0        0      0       0
 salt<>	  0    0        0        0      0      42        18       12      0       0
 pepper<> 0    0        0        0     42       0         0        0      3       0
 taste<>  0    0        0        0     18       0         0        0      0       0
 add<>    0    0        0        0     12       0         0        0      3       0
 lemon<>  2    0        0        0      0       3         0        3      0       2
 juice<>  2    0        0        0      0       0         0        0      2       0

Output word matrix shown on stdout will look as =>

 10 10 24
 2  5 9  2 10  2
 1  5 3  8 4 12
 2  8 4  9
 2 12 3  9
 6 42 7 18 8 12
 5 42 9  3
 5 18
 5 12 9  3
 1  2 6  3 8  3 10  2
 1  2 9  2

Or as 

  10 10
  0  5  0  0  0  0  0  0  2  2
  5  0  8 12  0  0  0  0  0  0
  0  8  0  9  0  0  0  0  0  0
  0 12  9  0  0  0  0  0  0  0
  0  0  0  0  0 42 18 12  0  0
  0  0  0  0 42  0  0  0  3  0
  0  0  0  0 18  0  0  0  0  0
  0  0  0  0 12  0  0  0  3  0
  2  0  0  0  0  3  0  3  0  2
  2  0  0  0  0  0  0  0  2  0

when --dense is ON.

case (2) Feature file provided via '--feats FEATFILE' exists and lists
the feature words for which the vectors are to be created.

In this case, the feature and dimension files won't be same, neither the
output matrix will be square and symmetric, unless the FEATFILE is exactly
same like the one automatically created by wordvec as in case (1) above. 
For each bigram word1<>word2 that is encountered in the WORD_PAIRS file, 
we check if word1 is listed in the given FEATFILE. If so, word2 is assigned a 
unique dimension index say j and the score of the bigram word1<>word2 is
assigned to the matrix entry at [i][j], if word1 occurs at the ith position in 
the given FEATFILE. 
Then, we check if word2 is listed in the given FEATFILE and if it is and 
appears at the kth position in the FEATFILE, we assign a unique dimension 
(column) index say l to word1 and set the matrix entry at [k][l] to the 
co-occurrence score of the pair word1<>word2.

For example, if the FEATFILE contains -

 soup<>
 hot<>
 salt<>
 lemon<>
 pepper<>

then, the word matrix with --wordorder = nocare can be viewed as -

	   stir  plate  soup  hot  pepper  salt  taste  add  juice  lemon
   soup<>    5       8     0   12       0     0      0    0      0      0
   hot<>     0       9    12    0       0     0      0    0      0      0
   salt<>    0       0     0    0      42     0     18   12      0      0
   lemon<>   2       0     0    0       3     0      0    3      2      0
   pepper<>  0       0     0    0       0    42      0    0      0      3

Output will display only the word matrix as 

   5 10
   5   8   0  12   0   0   0   0   0   0
   0   9  12   0   0   0   0   0   0   0
   0   0   0   0  42   0  18  12   0   0
   2   0   0   0   3   0   0   3   2   0
   0   0   0   0   0  42   0   0   0   3

with --dense ON 

and 

 5 10 14
 1 5 2 8 4 12
 2 9 3 12
 5 42 7 18 8 12
 1 2 5 3 8 3 9 2
 6 42 10 3

without --dense

The dimension file created with --dims will show -

 stir<>
 plate<>
 soup<>
 hot<>
 pepper<>
 salt<>
 taste<>
 add<>
 juice<>
 lemon<>

=back

=head1 SYSTEM REQUIREMENTS

=over
=item Ngram Statistics Package - L<http://search.cpan.org/dist/Text-NSP> 
=back

=head1 AUTHORS

Amruta Purandare, University of Pittsburgh.

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

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version","wordorder=s","binary","dense","dims=s","feats=s","format=s","target=s","extarget");
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

# show minimal usage message if less arguments
if($#ARGV<0)
{
        &showminimal();
        exit;
}

# default wordorder is follow
# word vectors show bigram scores feature<>dimension
if(!defined $opt_wordorder)
{
	$opt_wordorder="follow";
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

if($opt_wordorder !~ /(precede)|(follow)|(nocare)/)
{
        print STDERR "ERROR($0):
        --wordorder must be precede/follow/nocare.\n";
        exit;
}

# ----------------
# WORD_PAIRS file
# ----------------
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
	Please specify the WORD_PAIRS file ...\n";
        exit;
}

$pairsfile=$ARGV[0];
if(!-e $pairsfile)
{
        print STDERR "ERROR($0):
        WORD_PAIRS file <$pairsfile> doesn't exist...\n";
        exit;
}
open(PAIRS,$pairsfile) || die "Error($0):
        Error(code=$!) in opening <$pairsfile> file.\n";

# format for printing output
if(defined $opt_format)
{
	# integer
	if($opt_format=~/^i(\d+)$/)
	{
		$format_string="%$1d";
		$lower_format="-";
		while(length($lower_format)<($1-1))
		{
			$lower_format.="9";
		}
		if($lower_format eq "-")
		{
			$lower_format="0";
		}
		$upper_format="";
		while(length($upper_format)<($1-1))
		{
			$upper_format.="9";
		}
	}
	# float
	elsif($opt_format=~/^f(\d+)\.(\d+)$/)
	{
		$format_string="%$1\.$2f";
		$lower_format="-";
		while(length($lower_format)<($1-$2-2))
		{
			$lower_format.="9";
		}
		$lower_format.=".";
		while(length($lower_format)<($1-1))
		{
			$lower_format.="9";
		}
		
		$upper_format="";
		while(length($upper_format)<($1-$2-2))
        {
            $upper_format.="9";
        }
        $upper_format.=".";
        while(length($upper_format)<($1-1))
        {
            $upper_format.="9";
        }

	}
	else
	{
		print STDERR "ERROR($0):
	Wrong format value --format=$opt_format.\n";
		exit;
	}
}
# default is f16.10 for non-binary
# and i2 for binary
else
{
	if(defined $opt_binary)
	{
		$format_string="%2d";
		$lower_format="0";
		$upper_format="1";
	}
	else
	{
		$format_string="%16.10f";
		$lower_format="-999.9999999999";
		$upper_format="9999.9999999999";
	}
}

# -------------------
# Target Word regex
# -------------------

#file containing regex/s that define the target word
if(defined $opt_extarget)
{
	if(defined $opt_target)
	{
        	$target_file=$opt_target;
	        if(!(-e $target_file))
        	{
                	print STDERR "ERROR($0):
        Target regex file <$target_file> doesn't exist.\n";
	                exit;
        	}
	}
	else
	{
        	$target_file="target.regex";
	        if(!-e $target_file)
        	{
                	print STDERR "ERROR($0):
        Please copy the target.regex file into the current directory or specify
        the target regex file via --target option.\n";
	                exit;
        	}
	}

	# ------------------------
	# creating target regex
	# ------------------------

	open(REG,$target_file) || die "ERROR($0):
        Error(error code=$!) in opening the target regex file <$target_file>.\n";

	while(<REG>)
	{
        	chomp;
	        s/^\s+//g;
        	s/\s+$//g;
	        if(/^\s*$/)
        	{
                	next;
	        }
        	if(/^\//)
	        {
        	        s/^\///;
        	}
	        else
        	{
                	print STDERR "ERROR($0):
	Regular Expression <$_> should start with '/'\n";
        	        exit;
	        }
        	if(/\/$/)
	        {
        	        s/\/$//;
	        }
        	else
	        {
        	        print STDERR "ERROR($0):
	        Regular Expression <$_> should end with '/'\n";
        	        exit;
	        }
	        $target.="(".$_.")|";
	}	

	if(!defined $target)
	{
	        print STDERR "ERROR($0):
        No valid Perl regular expression found in the target regex file
        <$target_file>.\n";
        	exit;
	}
	else
	{
	        chop $target;
	}
}

if(defined $opt_feats)
{
	$featfile=$opt_feats;
	if(-e $featfile)
	{
		open(FEAT,$featfile) || die "Error($0):
        Error(code=$!) in opening Feature file <$featfile>.\n";
		$line_num=0;
		while(<FEAT>)
		{
		        $line_num++;
		        # trimming extra spaces
		        chomp;
		        # handling non-unigram lines
		        if(/^[\s\d]*$/ || ($_=~/^@/ && $_!~/<>/))
		        {
	                	next;
        		}

		        # --------------------------------
		        # Checking for valid unigram file
		        # --------------------------------
			$check_unigram=$_;
		        $cnt=0;
		        #count how many times <> occurs
		        while($check_unigram=~/<>/)
		        {
		                $cnt++;
		                $check_unigram=$';
		        }
		        #should be 1 for unigrams
		        if($cnt!=1)
		        {
		                print STDERR "ERROR($0):
        Given Feature file <$featfile> is not a valid Unigram output of NSP
        at line <$line_num>.\n";
                		exit;
		        }
			# storing feature words
		        if(/^(.*)<>\d*\s*$/)
		        {
				push @features,$1;
	                        $feature_index{$1}=scalar(@features);
        		}
		        else
		        {
		                print STDERR "ERROR($0):
        Given Feature file <$featfile> is not a valid Unigram output of NSP
        at line <$line_num>.\n";
                		exit;
		        }
		}
	}
}


##############################################################################

#			=====================================
#			    Construct a Co-occurrence Table
#				from the Bigram file
#			=====================================

# read each entry in bigram file
$line_num=0;
while(<PAIRS>)
{
	$line_num++;
        # trimming extra spaces
        chomp;
	# handling non-bigram lines
        if(/^[\s\d]*$/ || ($_=~/^@/ && $_!~/<>/))
        {
                next;
        }

	# ------------------------------
	# Checking for Valid bigram file
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
        Given WORD_PAIRS file <$pairsfile> is not a valid Bigram output of NSP
	at line <$line_num>.\n";
                exit;
        }

	# --------------------------------------------------
	# Extracting words and their Co-occurrence scores 
	# --------------------------------------------------

	# output created by count.pl or combig.pl
	if(/^(.*)<>(.*)<>(\d+)\s+\d+\s+\d+\s*$/)
	{
		$word1=$1;
		$word2=$2;
		$score=$3;
	}
	# output created by statistic.pl
	elsif(/^(.*)<>(.*)<>\d+\s+(\-?\d*\.?\d+)\s+\d+\s+\d+\s+\d+\s*$/)
    {
		$word1=$1;
        $word2=$2;
        $score=$3;
    }
	else
    {
        print STDERR "ERROR($0):
        Given WORD_PAIRS file <$pairsfile> is not a valid Bigram output of NSP
	at line <$line_num>.\n";
        exit;
    }
	
	# ignore pair if either of the features is a target word
	if(defined $opt_extarget && ($word1=~/^$target$/ || $word2=~/^$target$/))
	{
		next;
	}

    # added by AKK 21st Feb 2005
    # skip the word-pairs with 0 score
    # and the word-pairs whose score become 0 after formatting
    $value=sprintf $format_string,$score;
    
    # for binary representation
    if(defined $opt_binary && $value != 0)
    {
       $value = 1;
    }

    if($value<$lower_format)
    {
        print STDERR "ERROR($0):
	Floating point underflow.
	Value <$value> can't be represented with format $format_string.\n";
        exit 1;
    }
    if($value>$upper_format)
    {
        print STDERR "ERROR($0):
	Floating point overflow.
	Value <$value> can't be represented with format $format_string.\n";
        exit 1;
    }
    if($value==0)
    {
        next;
    }
    # end by AKK

	# wordorder = nocare when order of words in WORD_PAIRS file
	# doesn't matter
	# every word type is a feature as well as dimension
	if($opt_wordorder =~ /nocare/)
	{
		if(defined $featfile && -e $featfile)
		{
			if(defined $feature_index{$word1})
			{
				if(!defined $dimension_index{$word2})
				{
					push @dimensions, $word2;
					$dimension_index{$word2}=scalar(@dimensions);
				}
				$index1=$feature_index{$word1};
				$index2=$dimension_index{$word2};
				
				if(defined $coctable{$index1}{$index2})
				{
					print STDERR "ERROR($0):
        Pair \"$word1<>$word2\" is repeated in the WORD_PAIRS file <$pairsfile>.\n";
	                                exit;
				}
				if(defined $opt_binary)
				{
					$coctable{$index1}{$index2}=1;
				}
				else
				{
					$coctable{$index1}{$index2}=$score;
				}
				$nnz++;
			}
			if(($word1 ne $word2) && defined $feature_index{$word2})
            {
                if(!defined $dimension_index{$word1})
                {
                    push @dimensions, $word1;
                    $dimension_index{$word1}=scalar(@dimensions);
                }
                $index1=$feature_index{$word2};
                $index2=$dimension_index{$word1};
                
                if(defined $coctable{$index1}{$index2})
                {
                    print STDERR "ERROR($0):
        Pair \"$word1<>$word2\" is repeated in the WORD_PAIRS file <$pairsfile>.\n";
                    exit;
                }
				if(defined $opt_binary)
				{
					$coctable{$index1}{$index2}=1;
				}
				else
				{
					$coctable{$index1}{$index2}=$score;
				}
				$nnz++;
            }
		}
		else
		{
			# assigning numeric index to each feature/dimension
			if(!defined $index{$word1})
            {
                push @features,$word1;
                push @dimensions,$word1;
                $index{$word1}=scalar(@features);
            }
            if(!defined $index{$word2})
            {
                push @features,$word2;
                push @dimensions,$word2;
                $index{$word2}=scalar(@features);
            }
            
			$index1=$index{$word1};
			$index2=$index{$word2};
	
			# pair already seen
			if(defined $coctable{$index1}{$index2} || defined $coctable{$index2}{$index1})
			{
				print STDERR "ERROR($0):
	Pair \"$word1<>$word2\" is repeated in the WORD_PAIRS file <$pairsfile>.\n";
				exit;
			}
			if(!defined $opt_binary)
			{
				$coctable{$index1}{$index2}=$score;
				$coctable{$index2}{$index1}=$score;
			}
			else
			{
				$coctable{$index1}{$index2}=1;
                $coctable{$index2}{$index1}=1;
			}
			if($word1 ne $word2)
			{
				$nnz+=2;
			}
			else
			{
				$nnz++;
			}
		}
	}
	# wordorder = precede
	elsif($opt_wordorder =~ /precede/)
	{
		if(defined $featfile && -e $featfile && !defined $feature_index{$word2})
		{
			next;
		}
		# with wordorder = precede,
        # word2 is a feature and
        # word1 is a dimension
        if(!defined $feature_index{$word2})
        {
            push @features,$word2;
            $feature_index{$word2}=scalar(@features);
        }
        if(!defined $dimension_index{$word1})
        {
            push @dimensions,$word1;
            $dimension_index{$word1}=scalar(@dimensions);
        }
        
		$index1=$feature_index{$word2};
		$index2=$dimension_index{$word1};

		if(defined $coctable{$index1}{$index2})
		{
			print STDERR "ERROR($0):
        Pair \"$word1<>$word2\" is repeated in WORD_PAIRS file <$pairsfile>.\n";
                        exit;
		}
		if(!defined $opt_binary)
		{
			$coctable{$index1}{$index2}=$score;
		}
		else
		{
			$coctable{$index1}{$index2}=1;
		}
		$nnz++;
	}
	# wordorder = follow
	elsif($opt_wordorder =~ /follow/)
	{
		if(defined $featfile && -e $featfile && !defined $feature_index{$word1})
		{
			next;
		}
		# with wordorder = follow
        # word1 is a feature and
        # word2 is a dimension
        if(!defined $feature_index{$word1})
        {
            push @features,$word1;
            $feature_index{$word1}=scalar(@features);
                }
        if(!defined $dimension_index{$word2})
        {
            push @dimensions,$word2;
            $dimension_index{$word2}=scalar(@dimensions);
        }

		$index1=$feature_index{$word1};
		$index2=$dimension_index{$word2};
		
		if(defined $coctable{$index1}{$index2})
        {
            print STDERR "ERROR($0):
        Pair \"$word1<>$word2\" is repeated in WORD_PAIRS file <$pairsfile>.\n";
            exit;
        }
		if(!defined $opt_binary)
		{
			$coctable{$index1}{$index2}=$score;
		}
		else
		{
			$coctable{$index1}{$index2}=1;
		}
		$nnz++;
	}
}

##############################################################################

#			=========================
#			  Printing Word Vectors
#			=========================

print scalar(@features) . " " . scalar(@dimensions);

if(!defined $opt_dense)
{
	print " $nnz";
}
print "\n";

# for each feature
foreach $row (1..scalar(@features))
{
	if(defined $opt_dense)
	{
	  # for each dimension
	  foreach $col (1..scalar(@dimensions))
	  {
	    # checking if feature-dimension co-occur
	    # according to the bigram file
	    if(defined $coctable{$row}{$col})
	    {
            $value=sprintf $format_string,$coctable{$row}{$col};
            if($value<$lower_format)
            {
                print STDERR "ERROR($0):
	Floating point underflow.
	Value <$value> can't be represented with format $format_string.\n";
                exit 1;
            }
            if($value>$upper_format)
            {
                print STDERR "ERROR($0):
	Floating point overflow.
	Value <$value> can't be represented with format $format_string.\n";
                exit 1;
            }
	    }
	    else
	    {
            $value=sprintf($format_string,0);
	    }
	    print $value;
      }
    }
	# print sparse word vectors
  else
  {
      @sparse_cols=keys %{$coctable{$row}};
      @sorted_sparse_cols=sort {$a <=> $b} @sparse_cols;
      foreach $sparse_col (@sorted_sparse_cols)
      {
          # added by AKK on 21st Feb 2005
          # filter out the 0 valued scores
          #$val = $coctable{$row}{$sparse_col};
          $val=sprintf $format_string,$coctable{$row}{$sparse_col};
#          if($val != 0)
#          {
#              print "$sparse_col $coctable{$row}{$sparse_col} ";
              print "$sparse_col $val ";
#          }
      }
  }

  print "\n";
}

undef $opt_extarget;
##############################################################################

#			=====================================
#			  Reporting Features and Dimensions
#			=====================================

# -------------
# Feature file
# -------------
if(defined $featfile && !-e $featfile)
{
        open(FEAT,">$featfile") || die "ERROR($0):
        Error(code=$!) in opening Feature file <$featfile>.\n";
	foreach (@features)
	{
	    print FEAT "$_<>\n";
	}
}

# ----------------
#  Dimension file
# ----------------
if(defined $opt_dims)
{
        $dimfile=$opt_dims;
        if(-e $dimfile)
        {
                print STDERR "Warning($0):
        Dimension file <$dimfile> already exists, overwrite (y/n)? ";
                $ans=<STDIN>;
        }
        if(!-e $dimfile || $ans=~/Y|y/)
        {
                open(DIM,">$dimfile") || die "ERROR($0):
        Error(code=$!) in opening Dimension file <$dimfile>.\n";
		foreach (@dimensions)
		{
		    print DIM "$_<>\n";
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
        print "Usage: wordvec.pl [OPTIONS] WORD_PAIRS";
        print "\nTYPE wordvec.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  wordvec.pl [OPTIONS] WORD_PAIRS

Converts the given NSP output into a word-by-word association matrix.

WORD_PAIRS
	Should be a bigram/co-occurrence score file as created by programs
	count.pl, combig.pl or statistics.pl from the NSP.

OPTIONS:

--wordorder WORDORD
	Specifies whether wordvec should retain or ignore the order of words 
	in the WORD_PAIRS file.

	The possible values of WORDORD are - 

	nocare	-	order of words in WORD_PAIRs is ignored. 
			WORD_PAIRS are co-occurrence pairs created using 
			combig.pl program from NSP

	follow	-	WORD_PAIRS are bigrams and word vectors show how 
			frequently a dimension word (2nd word) follows a
			feature word (1st word) [Default]

	precede	-	WORD_PAIRS are bigrams and word vectors show how
			frequently a dimension word (1st word) precedes a
			feature word (2nd word)

--binary 
	Creates binary word vectors.

--dense
	Creates dense word vectors. By default, output word vectors are sparse.

--feats FEATFILE
	If the FEATFILE exists, features are extracted from this file, 
	otherwise, automatically extracted features are written into the 
	FEATFILE.

--dims DIMFILE
	Writes extracted dimensions to DIMFILE.

--target TARGET_REGEX
        Specifies a file containing Perl regex/s that define the target word.
        By default, target.regex is assumed to exist in current directory.
	--target is ignored unless --extarget is used.

--extarget
	Ignores WORD_PAIRS in which either of the constituent words is a target
	word as specified via --target option or default target.regex file.

--format FORM
	Specifies the numeric format for output representation. Default format 
	for binary word vectors is i2 and for non-binary frequency vectors
	default format is f16.10.
 
--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc wordvec.pl' to view detailed documentation of wordvec.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: wordvec.pl,v 1.24 2008/03/30 04:40:58 tpederse Exp $';
	print "\nCreate word vectors from Text-NSP output\n";
#        print "wordvec.pl      -       Version 0.4\n";
#        print "Builds word vectors.\n";
#        print "Copyright (c) 2002-2005, Amruta Purandare, Anagha Kulkarni & Ted Pedersen.\n";
#        print "Date of Last Update:     03/04/2005\n";
}

#############################################################################

