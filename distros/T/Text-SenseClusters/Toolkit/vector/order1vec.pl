#!/usr/local/bin/perl -w

=head1 NAME

order1vec.pl - Convert Senseval-2 format contexts into first order feature vectors in Cluto format

=head1 SYNOPSIS

 order1vec.pl [OPTIONS] SVAL2 FEATURE_REGEX

Type C<order1vec.pl --help> for a quick summary of options

=head1 DESCRIPTION

Convert a context into a first order feature vector which shows how which features 
occured in the contexts. The possible features are identified via Perl regular 
expressions of the form created by L<nsp2regex.pl>. 

=head1 INPUT

=head2 Required Arguments:

=head3 SVAL2 

A tokenized, preprocessed and well formatted Senseval-2 instance file showing
instances whose context vectors are to be generated.

Context of each instance should be delimited within <context> and </context> 
tags. It is required that each XML tag in the Senseval-2 file appears on a 
separate line. Tokens should be space separated.

=head3 FEATURE_REGEX

A file containing Perl regular expressions for features as created by 
nsp2regex.pl.

Sample FEATURE_REGEX files -

=over

=item 1. 

 /\s(<[^>]*>)*time(<[^>]*>)*\s/ @name = time
 /\s(<[^>]*>)*task(<[^>]*>)*\s/ @name = task
 /\s(<[^>]*>)*believe(<[^>]*>)*\s/ @name = believe
 /\s(<[^>]*>)*life(<[^>]*>)*\s/ @name = life
 /\s(<[^>]*>)*control(<[^>]*>)*\s/ @name = control
 /\s(<[^>]*>)*words(<[^>]*>)*\s/ @name = words
 /\s(<[^>]*>)*define(<[^>]*>)*\s/ @name = define

Explanation :

=over 

=item 1. 

The above FEATURE_REGEX file shows total 7 unigram features, single feature on each line. 

=item 2. 

Feature names are shown by "@name = FEATURE_NAME" that follows the actual 
feature regex/s.

=item 3.

Tokens in the SVAL2 file should be separated by exactly one blank space. Any 
non-tokens if exist should be put inside the angular brackets e.g. <item>, <sat>

=back 

=item 2.

 /\s(<[^>]*>)*personal(<[^>]*>)*\s(<[^>]*>\s)*(<[^>]*>)*computer(<[^>]*>)*\s/ @name = personal<>computer
 /\s(<[^>]*>)*stock(<[^>]*>)*\s(<[^>]*>\s)*(<[^>]*>)*market(<[^>]*>)*\s/ @name = stock<>market
 /\s(<[^>]*>)*electronic(<[^>]*>)*\s(<[^>]*>\s)*(<[^>]*>)*systems(<[^>]*>)*\s/ @name = electronic<>systems
 /\s(<[^>]*>)*toll(<[^>]*>)*\s(<[^>]*>\s)*(<[^>]*>)*free(<[^>]*>)*\s/ @name = toll<>free

Shows a bigram feature file in which each feature includes two tokens 
separated by single space or any number of non-token sequences in <> brackets.

More explanation on feature regex creation is given in the perldoc
of the nsp2regex program.

NOTE: Null columns are discarded i.e. the features which do not occur in any 
of the contexts are dropped, and when --transpose option is specified (see 
below for details), contexts that do not contain any features are dropped as
well.

=back

=head2 Optional Arguments:

=head3 --binary

By default, order1vec creates frequency context vectors that show how many 
times each feature occurs in the context. --binary will instead create binary
context vectors where 1 indicates presence of feature and 0 indicates 
absence of feature in the context.

=head3 --dense

By default, context vectors will have sparse format. --dense will display
output context vectors in dense format.

=head3 --rlabel RLABELFILE 

Creates a RLABELFILE containing row labels for Cluto's --rlabelfile option.
Each line in the RLABELFILE shows an instance id of the instance whose context
vector is shown on the corresponding line on STDOUT.

Instance ids are extracted from the SVAL2 file by matching regex

                /instance id\s*=\s*"IID"/

where 'IID' is an instance id of the <context> that follows this <instance> tag.

NOTE: When the --transpose option is specified, the contents of the RLABELFILE 
and the CLABELFILE are swapped.

=head3 --rclass RCLASSFILE

Creates RCLASSFILE for Cluto's --rclassfile option. Each line in the 
RCLASSFILE shows true sense id of the instance whose context vector appears on
the corresponding line on STDOUT.

Sense ids are extracted from the SVAL2 file by matching regex 

                /sense\s*id\s*=\s*"SID"\/>/

where SID shows a true sense tag of the instance whose IID is recently
extracted by matching 

		/instance id\s*=\s*"IID"/

This option cannot be specified when the --transpose option is specified.

=head3 --clabel CLABELFILE

Creates a CLABELFILE containing column labels for Cluto's --clabelfile option.
Each line in the CLABELFILE shows a feature representing corresponding column 
of the output context vectors.

Features are extracted from the FEATURE_REGEX file by matching string 
"@name = FEATURE" where FEATURE shows the feature name. 

NOTE: When the --transpose option is specified, the contents of the RLABELFILE 
and the CLABELFILE are swapped.

=head3 --transpose

Creates feature vectors instead of the default context vectors. The output
is a Latent Semantic Analysis style feature-by-context matrix, instead of the
default context-by-feature matrix that is native to SenseClusters. As a
result, the contents of the RLABELFILE and CLABELFILE are swapped, i.e. the
list of features is output to the RLABELFILE and the list of contexts is
output to the CLABELFILE.

=head3 --testregex TEST_REGEX

Creates a TEST_REGEX file containing only those regular expressions from the
input FEATURE_REGEX file that matched at least once in the input SVAL2 file.
This list can be different from the original list in FEATURE_REGEX when
different training data has been used to identify features or when a different
scope has been used for training and test data creation.

This option is required when the --transpose option is specified, in order to
ensure creation of a compatible TEST_REGEX file that corresponds to the
output of order1vec.pl in --transpose mode, so that both the output and the
TEST_REGEX can be directly passed as inputs to the order2vec.pl program.

=head3 --showkey

Displays the name of a system generated KEY file on the first line of STDOUT.
KEY file preserves the instance ids and sense tags of the instances in the 
given SVAL2 file. This information will be automatically used by some of the 
clustering and evaluation programs in SenseClusters that operate on purely 
numeric instance formats. The option should be selected if the user is planning 
to run SenseClusters' clustering code.

This option cannot be specified when the --transpose option is specified, as
no KEY file is generated in --transpose mode.

=head3 --target TARGETREGEX

Specifies a file containing Perl regex/s that define the target word. By 
default, target.regex file is assumed to exist in the current directory.

=head3 --extarget

This will exclude the target word from features if the target word (as
specified by the --target option or default target.regex file) appears
in the FEATURE_REGEX file. In other words, the feature dimensions
of the output context vectors will not include the target word even if
target word is listed in the FEATURE_REGEX file.

=head2 Other Options :

=head3 --help

Displays this message.

=head3 --version

Displays the version information.

=head1 OUTPUT

=head2 KEY file

When --transpose is not specified, order1vec automatically generates a KEY 
file that preserves the instance ids and sense tags of the SVAL2 instances. 

Each line in the KEY file shows an instance id and one or more sense tags 
of the instance represented by a context vector on the corresponding line 
on STDOUT. i.e. the ith line in the KEY file shows the instance and sense ids 
of the ith instance in the SVAL2 file or the ith vector displayed on stdout.

Sample KEY file looks like

 <instance id="line-n.w8_020:7099:"/> <sense id="phone"/>
 <instance id="line-n.w8_132:15431:"/> <sense id="phone"/>
 <instance id="line-n.w8_027:13762:"/> <sense id="phone"/>
 <instance id="line-n.w7_114:8965:"/> <sense id="text"/>
 <instance id="line-n.w7_065:1553:"/> <sense id="product"/>
 <instance id="line-n.w9_4:9437:"/> <sense id="product"/>

Or

 <instance id="line-n.w8_020:7099:"/> <sense id="NOTAG"/>
 <instance id="line-n.w7_111:238:"/> <sense id="NOTAG"/>
 <instance id="line-n.w7_011:12078:"/> <sense id="NOTAG"/>
 <instance id="line-n.w7_095:17576:"/> <sense id="NOTAG"/>
 <instance id="line-n.w7_080:10129:"/> <sense id="NOTAG"/>
 <instance id="line-n.w9_4:2358:"/> <sense id="NOTAG"/>

when the sense ids of instances are not available in the input SVAL2 file.

Or

 <instance id="hard-a.sjm-180_1:"/> <sense id="HARD1"/> <sense id="HARD2"/>
 <instance id="hard-a.br-l15:"/> <sense id="HARD1"/>
 <instance id="hard-a.sjm-242_12:"/> <sense id="HARD2"/>
 <instance id="hard-a.sjm-070_4:"/> <sense id="HARD1"/> <sense id="HARD3"/>
 <instance id="hard-a.sjm-168_4:"/> <sense id="HARD3"/>

when some instances have multiple sense tags. 

=head2 Context Vectors on STDOUT (when --transpose is NOT specified)

=head3 Sparse Format (SenseClusters Native Representation)

By default (unless --dense is specified), output vectors will be created in 
sparse format.

The first line on stdout will show 3 numbers separated by blanks as

N M NNZ

where

 N = Number of instances in SVAL2 file

 M = Number of features from the FEATURE_REGEX file that were found at least once in the SVAL2 file

 NNZ = Total number of non-zero entries in all sparse vectors

Each line thereafter shows a single sparse context vector on each line. In 
short, every ith line after the 1st line shows the context vector of the 
i'th instance in the given SVAL2 file.

Each sparse vector is a list of pairs of numbers separated by space such
that the first number in a pair is the index of a non-zero value in the
vector and the second number is a non-zero value itself corresponding to 
that index.

=head4 Sample Sparse Output

 12 18 31
 1 1 2 1
 1 1 2 2 3 2 4 1
 4 1
 5 1 6 2
 5 2 6 3 7 1 8 2 9 1
 9 1
 7 1
 8 1 10 1
 4 2 11 3 12 2 13 4 14 1
 15 1
 14 1 15 1
 3 1 8 1 16 4 17 4 18 4

Note that, 

=over

=item 1. 

First Line shows that there are total 12 sparse vectors, represented
using total 18 features, and total 31 non-zero values.

=item 2. 

Each vector (all lines except the 1st line) is a list of 'index value'
pairs separated by space. e.g. 1st vector (line 2) shows that features at 
indices 1 and 2 appear once in the 1st instance. 2nd vector (3rd line)
shows that features at indices 1 and 4 appear once while those at indices
2 and 3 appear twice each in the 2nd instance. 

Feature indices start from 1, to be consistent with Cluto's matrix format 
standard. 

=item 3. 

If --binary is set ON, all non-zero values will have value 1 showing
mere presence of feature in the context rather than the frequency counts.

=back

=head3 Dense Format (SenseClusters Native Representation)

When --dense option is selected, order1vec will create output in dense 
vector format. 

First line on STDOUT will show exactly two numbers separated by space. 
The first number indicates the number of vectors and the second number 
indicates the number of features (dimensions of the context vectors).

Each line thereafter shows a single context vector such that ith line after 
the 1st line shows the context vector of the ith instance in the SVAL2 file.

=head4 Sample Dense Output

 12 18
 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 1 2 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0
 0 0 0 0 2 3 1 2 1 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0
 0 0 0 2 0 0 0 0 0 0 3 2 4 1 0 0 0 0
 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0
 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0
 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 4 4 4

shows same context vectors as shown in Sample Sparse Format but in dense 
format.

Note that 

=over

=item 1. All vectors have same length and is same as the number of features 
(here 18) from the given FEATURE_REGEX file that matched at least once in
the SVAL2 file.

=item 2. When --binary is ON, value at column j in a vector will be 1 
for every feature j that is found at least once in the context. 

=item 3. When --binary is not used, value at column j in a vector shows the 
number of times the jth feature is found in the context. 

=item 4. A 0 at column j of any vector shows that the jth feature in the 
FEATURE_REGEX file doesn't appear in that context.

=back

When --showkey is selected, output will be exactly same as described above
except the first line will show the KEY file name that is required by
the SenseClusters' programs. 

e.g. 

 <keyfile name="KEY"/>
 12 18 31
 1 1 2 1
 1 1 2 2 3 2 4 1
 4 1
 5 1 6 2
 5 2 6 3 7 1 8 2 9 1
 9 1
 7 1
 8 1 10 1
 4 2 11 3 12 2 13 4 14 1
 15 1
 14 1 15 1
 3 1 8 1 16 4 17 4 18 4

Shows same vectors as shown in Sample Sparse Output when --showkey is ON.
Value of KEY shown in the <keyfile> tag will be the system generated KEY 
file name.

=head2 Features Vectors on STDOUT (when --transpose IS specified)

Note that --testregex TEST_REGEX is a required option when --transpose is
specified.

=head3 Sparse Format (Latent Semantic Analysis Representation)

By default (unless --dense is specified), output vectors will be created in 
sparse format.

The first line on stdout will show 3 numbers separated by blanks as

 N M NNZ

where

 N = Number of features from the FEATURE_REGEX file that were found at least once in the SVAL2 file

 M = Number of instances in SVAL2 file, for which at least one feature was identified

 NNZ = Total number of non-zero entries in all sparse vectors

Each line thereafter shows a single sparse feature vector on each line. In 
short, every ith line after the 1st line shows the feature vector of the 
i'th feature in the created TEST_REGEX file.

Each sparse vector is a list of pairs of numbers separated by space such
that the first number in a pair is the index of a non-zero value in the
vector and the second number is a non-zero value itself corresponding to 
that index.

=head4 Sample Sparse Output (Transpose of the Context Vectors output above)

 18 12 31
 1 1 2 1
 1 1 2 2
 2 2 12 1
 2 1 3 1 9 2
 4 1 5 2
 4 2 5 3
 5 1 7 1
 5 2 8 1 12 1
 5 1 6 1
 8 1
 9 3
 9 2
 9 4
 9 1 11 1
 10 1 11 1
 12 4
 12 4
 12 4

Note that, 

=over

=item 1. 

First Line shows that there are total 18 sparse feature vectors, represented
using total 12 contexts, and total 31 non-zero values.

=item 2. 

Each vector (all lines except the 1st line) is a list of 'index value'
pairs separated by space. e.g. 1st vector (line 2) shows that contexts at 
indices 1 and 2 contain the 1st feature once each. 3rd vector (4th line)
shows that context at index 2 contains the 3rd feature 2 times and the context
at index 12 contains the 3rd feature once.

Context indices start from 1, to be consistent with Cluto's matrix format 
standard. 

=item 3. 

If --binary is set ON, all non-zero values will have value 1 showing
mere presence of feature in the context rather than the frequency counts.

=back

=head3 Dense Format (Latent Semantic Analysis Representation)

When --dense option is selected, order1vec will create output in dense 
vector format. 

First line on STDOUT will show exactly two numbers separated by space. 
The first number indicates the number of vectors and the second number 
indicates the number of contexts (dimensions of the feature vectors).

Each line thereafter shows a single feature vector such that ith line after 
the 1st line shows the context vector of the ith instance in the SVAL2 file.

=head4 Sample Dense Output (Transpose of the dense output of Context Vectors
above)

 18 12
 1 1 0 0 0 0 0 0 0 0 0 0 
 1 2 0 0 0 0 0 0 0 0 0 0 
 0 2 0 0 0 0 0 0 0 0 0 1 
 0 1 1 0 0 0 0 0 2 0 0 0 
 0 0 0 1 2 0 0 0 0 0 0 0 
 0 0 0 2 3 0 0 0 0 0 0 0 
 0 0 0 0 1 0 1 0 0 0 0 0 
 0 0 0 0 2 0 0 1 0 0 0 1 
 0 0 0 0 1 1 0 0 0 0 0 0 
 0 0 0 0 0 0 0 1 0 0 0 0 
 0 0 0 0 0 0 0 0 3 0 0 0 
 0 0 0 0 0 0 0 0 2 0 0 0 
 0 0 0 0 0 0 0 0 4 0 0 0 
 0 0 0 0 0 0 0 0 1 0 1 0 
 0 0 0 0 0 0 0 0 0 1 1 0 
 0 0 0 0 0 0 0 0 0 0 0 4 
 0 0 0 0 0 0 0 0 0 0 0 4 
 0 0 0 0 0 0 0 0 0 0 0 4

shows same context vectors as shown in Sample Sparse Format but in dense 
format.

Note that 

=over

=item 1. All vectors have same length and is same as the number of contexts 
(here 12) from the given SVAL2 file that contained at least one feature
from the TEST_REGEX file.

=item 2. When --binary is ON, value at column j in a vector will be 1 
for every context j that contains the feature at least once. 

=item 3. When --binary is not used, value at column j in a vector shows the 
number of times the feature is found in the jth context. 

=item 4. A 0 at column j of any vector shows that the feature
doesn't appear in the jth context.

=back

=head1 SYSTEM REQUIREMENTS

=over 
=item PDL - L<http://search.cpan.org/dist/PDL/>

=item Math::SparseVector - L<http://search.cpan.org/dist/Math-SparseVector/>
=back

=head1 BUGS

This program behaves unpredictably if the input file is not in
Senseval2 format. No error message is given, and it will produce
numeric output, but of course it has no real meaning. A check
should be added to make sure the input file is in Senseval2 format.

=head1 AUTHOR

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Amruta Purandare, University of Pittsburgh

 Anagha Kulkarni, Carnegie-Mellon University

 Mahesh Joshi, Carnegie-Mellon University

=head1 COPYRIGHT

Copyright (c) 2002-2008, Ted Pedersen, Amruta Purandare, Anagha Kulkarni, Mahesh Joshi

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

#			 ==============================	
#                             THE CODE STARTS HERE
#			 ==============================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

# PDL is used for dense vectors
use PDL;
use PDL::NiceSlice;
use PDL::Primitive;

# Math::SparseVector is used for sparse vectors
use Math::SparseVector;

# Math::SparseMatrix for sparse matrix transpose
# functionality
use Math::SparseMatrix;

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version","showkey","rlabel=s","rclass=s","clabel=s","binary","target=s","extarget","dense", "transpose", "testregex=s");
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
        exit 1;
}

if (!defined $opt_transpose) {
	$opt_transpose = 0;
}

if ($opt_transpose != 0 && !defined $opt_testregex) {
	print STDERR "ERROR($0):
	--transpose cannot be specified without specifying --testregex 
	TEST_REGEX.\n";
	exit 1;
}

if ($opt_transpose != 0 && defined $opt_rclass) {
	print STDERR "ERROR($0):
		--rclass cannot be specified when using --transpose option.\n";
	exit 1;
}

if ($opt_transpose != 0 && defined $opt_showkey) {
	print STDERR "ERROR($0):
		--showkey cannot be specified when using --transpose option.\n";
	exit 1;
}

#############################################################################

#                       ================================
#                           INITIALIZATION AND INPUT
#                       ================================

# -------------
# SVAL2 file
# -------------
if(!defined $ARGV[0])
{
	print STDERR "ERROR($0):
		Please specify the SVAL2 file.\n";
	exit 1;
}
#accept the SVAL2 file name
$infile=$ARGV[0];
if(!-e $infile)
{
	print STDERR "ERROR($0):
		SVAL2 file <$infile> doesn't exist...\n";
	exit 1;
}

open(IN,$infile) || die "Error($0):
		Error(code=$!) in opening the SVAL2 file <$infile>\n";

# -------------------
# Feature regex file
# -------------------
if(!defined $ARGV[1])
{
	print STDERR "ERROR($0):
		Please specify the Feature Regex file.\n";
	exit 1;
}
#accept the feature file name
$featfile=$ARGV[1];
if(!-e $featfile)
{
	print STDERR "ERROR($0):
		Feature Regex file <$featfile> doesn't exist...\n";
	exit 1;
}
open(FEAT,$featfile) || die "Error($0):
		Error(code=$!) in opening Feature Regex file <$featfile>\n";

# -------------------
# Target Word regex
# -------------------

if(defined $opt_extarget)
{
	#file containing regex/s for target word
	if(defined $opt_target)
	{
		$target_file=$opt_target;
		if(!(-e $target_file))
		{
			print STDERR "ERROR($0):
		Target regex file <$target_file> doesn't exist.\n";
			exit 1;
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
			exit 1;
		}
	}

	# ------------------------
	# creating target regex
	# ------------------------

	open(REG,$target_file) || die "ERROR($0):
		Error(error code=$!) in opening the target regex file <$target_file>\n";

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
        	        exit 1;
        	}
	        if(/\/$/)
        	{
	                s/\/$//;
        	}
	        else
        	{
	                print STDERR "ERROR($0):
        Regular Expression <$_> should end with '/'\n";
        	        exit 1;
        	}
	        $target.="(".$_.")|";
	}

	if(!defined $target)
	{
	        print STDERR "ERROR($0):
        No valid Perl regular expression found in the target regex file
        <$target_file>\n";
        	exit 1;
	}
	else
	{
        	chop $target;
	}	
}

##############################################################################

#			=======================
#			  Read Feature Regex/s
#			=======================

$line_num=0;
while(<FEAT>)
{
	$line_num++;
	chomp;
	s/^\s*//;
	s/\s*$//;

	if(/(.*)\s*\@name\s*=\s*(.*)/)
	{
		$feature_regex=$1;
		$feature=$2;

		# removing leading and lagging blank spaces
		$feature_regex=~s/^\s*//;
		$feature_regex=~s/\s*$//;
		$feature=~s/^\s*//;
		$feature=~s/\s*$//;

		# removing the starting and ending slashes //
		if($feature_regex=~/^\//) { $feature_regex=~s/^\///; }
        	else
	        {
        	        print STDERR "ERROR($0):
        Feature regex <$feature_regex> 
	at line <$line_num> in Feature Regex file <$featfile> should start 
	with '/'\n";
                	exit 1;
	        }
        	if($feature_regex=~/\/$/) { $feature_regex=~s/\/$//; }
        	else
	        {
			print STDERR "ERROR($0):
        Feature regex <$feature_regex>
        at line <$line_num> in Feature Regex file <$featfile> should end
        with '/'\n";
                        exit 1;
	        }
		# target word is a feature only when --extarget is not 
		# selected or feature regex doesn't match with target 
		# regex
		if(!defined $opt_extarget || $feature !~ /^$target$/)
		{
			push @features,$feature_regex;
			# we require the @name part of the nsp2regex output if column labels
			# or test regexes are requested
			if(defined $opt_clabel || defined $opt_testregex)
			{
				push @clabels, $feature;
			}
		}
	}
	else
	{
		print STDERR "ERROR($0):
	Line <$line_num> in Feature Regex file <$featfile> has an unexpected 
	format.\n";
		exit 1;
	}
}

#output vector will have 
#columns = #features 
$cols=scalar(@features);
##############################################################################

#		=================================================
#			    CREATING CONTEXT VECTORS 
#		=================================================

# context vectors are temporarily written into a 
# TEMP file 

# if the program finishes successfully, this TEMP file
# is printed to STDOUT and is deleted 

# otherwise TEMP file is retained and stores the partial
# program output

$tempfile="tempfile" . time() . ".order1vec";
if(-e $tempfile)
{
	print STDERR "ERROR($0):
	Temporary file <$tempfile> should not already exist.\n";
	exit 1;
}

open(TEMP,">$tempfile") || die "ERROR($0):
	Error(code=$!) in opening internal temporary file <$tempfile>\n";

# reading the SVAL2 file
$line_num=0;

if(defined $opt_dense)
{
	# use PDL
	$context_vector=zeroes($cols);
	# PDL matrices are column major. Initially create a matrix
	# with number of columns equal to number of features and
	# number of rows = 1, filled with zeroes
	$orig_matrix = zeroes($cols, 1);
}
else
{
	# use Math::SparseVector module
	$context_vector=Math::SparseVector->new;
	$nnz=0;
}

$context_count = 0;

while(<IN>)
{
	$line_num++;

	if(/instance id\s*=\s*\"([^"]+)\"/)
	{
		$instance=$1;
		if(defined $instance_ids{$instance})
		{
			print STDERR "ERROR($0):
	Instance Id <$instance> is repeated in the SVAL2 file <$infile>\n";
			exit 1;
		}
		push @instances,$instance;
		$instance_ids{$instance}=1;
	}
	if(/<\/instance>/)
	{
		undef $instance;
	}
	if(/sense\s*id\s*=\s*\"([^"]+)\"/)
	{
		# no <instance> open
        if(!defined $instance)
        {
            print STDERR "ERROR($0):
        Missing <instance> tag before the <sense> tag at line <$line_num>
        in SVAL2 file <$infile>\n";
            exit 1;
        }

		$sense=$1;
		if(defined $key_table{$instance}{$sense})
		{
			print STDERR "ERROR($0):
	<instance-id, sense-tag> pair <$instance, $sense> is repeated in the
	SVAL2 file <$infile>\n";
			exit 1;
		}
		$key_table{$instance}{$sense}=1;
	}

	if(/<\/context>/)
	{

		undef $data_start;
                
		# add dense vector to orig_matrix
		if(defined $opt_dense)
		{
			# initially resize the original matrix to new number of contexts
			# (actual increment in count is done later, since we use the current
			# value of $context_count for indexing the orig_matrix)
			$orig_matrix->reshape($cols, $context_count + 1);
			# get the vector for the current context
			$rowvec = $orig_matrix->slice(":,($context_count)");
			# update the vector for the context in the the orig_matrix
			$rowvec .= $context_vector;
		}
		# printing context vector to TEMP file
		# sparse vector
		else
		{
			foreach $key ($context_vector->keys)
			{
				print TEMP "$key " . $context_vector->get($key) . " ";
				$nnz++;
			}
			print TEMP "\n";
		}
	
		# increment the number of contexts
		$context_count++;
	}

	# contextual data
	if(defined $data_start)
	{
		# nsp2regex features have format 
		# /\sFEATURE\s/ which requires a space
		# on each side of the token
		s/^(\S)/ $1/;
		s/(\S)$/$1 /;
		# ---------------------------------------------------
		#  the logic of matching feature regex/s is borrowed
		#  from the xml2arff.pl program from the SenseTools
		#  package by Satanjeev Banerjee and Ted Pedersen
		# ---------------------------------------------------
		foreach $index (0..$#features)
		{
			$feature_regex=$features[$index];
			if(defined $opt_binary)
			{
				# match or not
				if(/$feature_regex/)
				{
					if(defined $opt_dense)
					{
					   $context_vector->set($index,1);
					}
					else
					{
					   $context_vector->set($index+1,1);
					}
				}
			}
			else
			{
				# number of matches
				while(/$feature_regex/g)
				{
					if(defined $opt_dense)
					{
						$context_vector($index)++;
					}
					else
					{
						$context_vector->incr($index+1);
					}
				}
			}
		}
	}

	# beginning of the context
	if(/<context>/)
	{
		# no <instance> open
		if(!defined $instance)
		{
			print STDERR "ERROR($0):
		Missing <instance> tag before the <context> tag at line <$line_num>
		in SVAL2 file <$infile>\n";
			exit 1;
		}
        
		# no sense tag for this instance
		if(!defined $key_table{$instance})
		{
			$sense="NOTAG";
			$key_table{$instance}{$sense}=1;
		}
		$data_start=1;
		if(defined $opt_dense)
		{
            $context_vector->inplace->zeroes;
		}
		else
		{
			$context_vector->free;
		}
	}
}

# if we are in dense mode, then TEMP file is
# created here
if(defined $opt_dense) {
	if ($opt_transpose != 0) {
		# create feature-by-context dense TEMP file
		$transpose_matrix = transpose($orig_matrix);
		for ($i = 0; $i < $cols; $i++) {
			for ($j = 0; $j < $context_count; $j++) {
				print TEMP $transpose_matrix->at($j,$i) . " ";
			}
			print TEMP "\n";
		}
	} else {
		# create context-by-feature dense TEMP file
		for ($i = 0; $i < $context_count; $i++) {
			for ($j = 0; $j < $cols; $j++) {
				print TEMP $orig_matrix->at($j,$i) . " ";
			}
			print TEMP "\n";
		}
	}
}

close TEMP;

undef $opt_extarget;

# added by AKK on 02/28/2005
# work-around for eliminating the columns (i.e. the features) which
# dont have any non-zero row entry i.e. the features that do not occur
# in any of the contexts.

my $mod_tempfile = "mod_tempfile" . time() . ".order1vec";
my @col = ();

if(!defined $opt_dense)
{
	open(TEMP,$tempfile) || die "ERROR($0):
		Error(code=$!) in opening internal temporary file <$tempfile>\n";

	# go through each row of the file till either of the following occurs:
	# 1. we encounter atleast one entry for each column i.e. for each feature
	# 2. we reach end of the file

	my $flag = 0;

	for($i=1;$i<=$cols;$i++)
	{
			$col[$i] = 0;
	}

	while(<TEMP>)
	{
			@elem = split(/\s+/);
			
			# mark the column for which an entry was found 
			for($i=0;$i<=$#elem;$i=$i+2)
			{
					$col[$elem[$i]] = 1;
			}

			# check if an entry found for each column
			$flag = 0;
			for($i=1;$i<=$cols;$i++)
			{
					if($col[$i] == 0)
					{
							$flag = 1;
							last;
					}
			}

			# if an entry found for each column
			# then exit the while loop.
			# this situation suggests that we dont have any  
			# no entry column in this input data.
			if($flag == 0)
			{
					last;
			}
	}
	close TEMP;

	# ON(1) state of flag variable suggests that the input matrix
	# has one or more columns with no non-zero entries.
	# Thus we need to remove these columns and adjust the column
	# indices for all the columns following the removed column.
	my %hash_col = ();

	if($flag == 1)
	{
			# create the new column indices
			$cnt = 1;
			for($i=1;$i<=$#col;$i++)
			{
					# for the remaining columns 
					# adjust the column indices
					if($col[$i] == 1)
					{
							$hash_col{$i} = $cnt;
							$cnt++;
					}
					# when column dropped decrease
					# total # of cols
					else
					{
							$cols--;
					}
			}

			# write the modified TEMP file to another temp file with the changed column indices.
			open(TEMP,$tempfile) || die "ERROR($0):
					 Error(code=$!) in opening internal temporary file <$tempfile>\n";

			open(MOD,">$mod_tempfile") || die "ERROR($0):
					 Error(code=$!) in opening internal temporary file <$mod_tempfile>\n";

			while(<TEMP>)
			{
					@elem = split(/\s+/);
			
					# print the column index and the cell value pairs for the context
					for($i=0;$i<=$#elem;$i=$i+2)
					{
							print MOD $hash_col{$elem[$i]} . " " . $elem[$i+1] . " ";
					}
					print MOD "\n";        
			}    

			close TEMP;
			close MOD;
	}
}

# end by AKK on 02/28/2005

# for sparse mode, if --transpose is specified, we need to use
# Math::SpaarseMatrix for the transpose functionality

if (!defined $opt_dense && $opt_transpose != 0) {
	# first prepare a temporary file for transpose function input.
	# we need to eliminate any empty contexts from the original
	# output of order1 represenataion
	$transpose_in = "transpose_in" . time() . "order1vec";
	# process the temporary file created above, to eliminate empty
	# contexts, and create an input file for transposing
	if(-e $mod_tempfile)
	{
			open(TEMP,$mod_tempfile) || die "ERROR($0):
		Error(code=$!) in opening internal temporary file <$tempfile>\n";
	}
	else
	{
			open(TEMP,$tempfile) || die "ERROR($0):
		Error(code=$!) in opening internal temporary file <$tempfile>\n";
	}
	open(TRANS_IN, "> $transpose_in") or die "ERROR($0): 
		Error(code=$!) while creating temporary input file <$transpose_in>
		for transposing.\n";

	# $linetowrite contains the content of output except
	# blank lines representing empty contexts
	$linetowrite = "";
	$rows = @instances;
	# in this process, instances might reduce, so we should create a
	# new array of only the remaining instances. initially, just create
	# an array containing all 1's indicating that no instances are dropped
	for ($i = 0; $i < @instances; $i++) {
		$nonempty_instances[$i] = 1;
	}
	# use index to determine which instances to ignore
	$index = 0;
	while ($line = <TEMP>) {
		chomp $line;
		if ($line ne "") {
			$linetowrite .= "$line\n";
		} else {
			# do no print the empty line and reduce the row count
			$rows--;
			# put a 0 in the nonempty_instances array, indicating that the
			# instance at this index in the @instances array is empty
			$nonempty_instances[$index] = 0;
		}
		$index++;
	}
	# write the reduced number of contexts back, without empty lines
	print TRANS_IN "$rows $cols $nnz\n";
	print TRANS_IN $linetowrite;

	close TEMP;
	close TRANS_IN;
 
	$transpose_sparsematrix = Math::SparseMatrix->createTransposeFromFile(
		$transpose_in);
	# create the transpose output
	$transpose_out = "transpose_out" . time() . "order1vec";
	$transpose_sparsematrix->writeToFile($transpose_out);
}


###########################################################################

#			=========================
#			     OUTPUT SECTION
#			=========================

# ===================== 
#  Creating KEY file
# =====================

# DO NOT GENERATE A KEY FILE IN --transpose MODE

# KEY file is automatically created by the program
# and preserves the instance ids and sense tags of the
# SVAL-2 instances 

if ($opt_transpose == 0) {
	$keyfile="keyfile" . time() . ".key";
	if(-e $keyfile)
	{
		print STDERR "ERROR($0):
		System generated KEY file <$keyfile> should not already exist.\n";
		exit 1;
	}

	open(KEY,">$keyfile") || die "ERROR($0):
		Error(code=$!) in opening system generated KEY file <$keyfile>\n";

	foreach $instance (@instances)
	{
		print KEY "<instance id=\"$instance\"\/> ";
		foreach $sense (sort keys %{$key_table{$instance}})
		{
			print KEY "<sense id=\"$sense\"\/> ";
		}
		print KEY "\n";
	}

	close KEY;
}

# ========================= 
#  Printing output vectors
# =========================

# printing KEY name when --showkey is ON
if(defined $opt_showkey)
{
	print "<keyfile name=\"$keyfile\"\/>\n";
	undef $opt_showkey;
}

# first line for sparse vectors shows 
# N M NNZ
# while the first line in dense vectors shows
# N M

# where N = number of vectors = Number of instances in SVAL2
# M = number of dimensions = Number of features in FEATURE
# NNZ = total number of non-zero entries in sparse vectors

# Additionally, we also need to consider if the the --transpose was on,
# in which case N and M are swapped. But this file is already created
# in the Math::SparseMatrix transpose code called above. So in that case
# we simply open that file and print it at STDOUT

if (!defined $opt_dense && $opt_transpose != 0) {
	# transpose and sparse
	open (TRANS_OUT, "< $transpose_out") or die "ERROR($0):
		Error (code=$!) while opening internal file <$transpose_out>\n";
	while (<TRANS_OUT>)	{
		print;
	}
	close TRANS_OUT;
} else {

	if ($opt_transpose != 0) {
		# transpose and dense (since transpose and sparse would have
		# been the "if" condition above)
		print "$cols " . scalar(@instances);
	} else {
		# non-transpose and (sparse/dense)
		print scalar(@instances) . " $cols";
	}

	if(!defined $opt_dense)
	{
		print " $nnz";
	}
	print "\n";

	# this is followed by the actual context vectors
	if(-e $mod_tempfile)
	{
			open(TEMP,$mod_tempfile) || die "ERROR($0):
		Error(code=$!) in opening internal temporary file <$tempfile>\n";
	}
	else
	{
			open(TEMP,$tempfile) || die "ERROR($0):
		Error(code=$!) in opening internal temporary file <$tempfile>\n";
	}

	while(<TEMP>)
	{
		print;
	}
	close TEMP;
}

# deleting TEMP as the program is successfully finished
unlink $tempfile;
if(-e $mod_tempfile)
{
	unlink $mod_tempfile;
}
if (defined $transpose_in && -e $transpose_in)
{
	unlink $transpose_in;
}
if (defined $transpose_out && -e $transpose_out)
{
	unlink $transpose_out;
}

undef $opt_binary;

# ==========================
#   Creating Cluto files
# ==========================

# REMEMBER: if --transpose is specified, then row and column labels get 
# interchanged

# writing rlabel file
if(defined $opt_rlabel)
{
	$rlabel=$opt_rlabel;
	if(-e $rlabel)
	{
		print STDERR "Warning($0):
		Row label file <$rlabel> already exists, overwrite (y/n)? ";
		$ans=<STDIN>;
	}
	if(!-e $rlabel || $ans=~/Y|y/)
	{
		open(RLAB,">$rlabel") || die "Error($0):
		Error(code=$!) in opening the Row Label file <$rlabel>\n";
		if ($opt_transpose == 0) {
			# printing rlabels
			foreach $instance (@instances)
			{
				print RLAB "$instance\n";
			}
		} else {
			# printing column labels as row labels during transpose
			if (!defined $opt_dense) {
				# in sparse mode, we need to check for dropping
				# column labels for empty columns
				for ($index=1; $index <= @clabels; $index++)
				{
					if ($col[$index] > 0) {
						print RLAB $clabels[$index-1] . "\n";
					}
				}
			} else {
				# in dense mode, output all column labels 
				for ($index=1; $index <= @clabels; $index++)
				{
					print RLAB $clabels[$index-1] . "\n";
				}
			}
		}
		close RLAB;
	}
}

# writing rclass file 
if(defined $opt_rclass)
{
	$rclass=$opt_rclass;
	if(-e $rclass)
	{
		print STDERR "Warning($0):
		Class label file <$rclass> already exists, overwrite (y/n)? ";
		$ans=<STDIN>;
	}
	if(!-e $rclass || $ans=~/Y|y/)
	{
		open(RCL,">$rclass") || die "Error($0):
		Error(code=$!) in opening the Class Label file <$rclass>\n";
		# printing rclasses
		foreach $instance (@instances)
		{
			@senses=sort keys %{$key_table{$instance}};
			if(scalar(@senses) > 1)
			{
				print STDERR "ERROR($0):
		Instance <$instance> can not have multiple senses in RCLASSFILE.\n";
				exit 1;
			}
			print RCL "$senses[0]\n";
		}
		close RCL;
	}
}

# writing clabel file
if(defined $opt_clabel)
{
	$clabel=$opt_clabel;
	if(-e $clabel)
	{
		print STDERR "Warning($0):
		Column label file <$clabel> already exists, overwrite (y/n)? ";
		$ans=<STDIN>;
	}
	if(!-e $clabel || $ans=~/Y|y/)
	{
		open(CLAB,">$clabel") || die "Error($0):
		Error(code=$!) in opening the Column Label file <$clabel>\n";
		if ($opt_transpose == 0) {
			# printing column labels
			if (!defined $opt_dense) {
				# in sparse mode, we need to check for dropping
				# column labels for empty columns
				for ($index=1; $index <= @clabels; $index++)
				{
					if ($col[$index] > 0) {
						print CLAB $clabels[$index-1] . "\n";
					}
				}
			} else {
				# in dense mode, output all column labels 
				for ($index=1; $index <= @clabels; $index++)
				{
					print CLAB $clabels[$index-1] . "\n";
				}
			}
		} else {
			# printing rlabels as column labels during transpose
			# check for empty contexts, and skip them in the output
			if (!defined $opt_dense) {
				# number of instances might reduce in sparse representation
				# in --transpose option
				for ($i = 0; $i < @instances; $i++)
				{
					if ($nonempty_instances[$i] == 1) {
						print CLAB "$instances[$i]\n";
					}
				}
			} else {
				for ($i = 0; $i < @instances; $i++)
				{
					print CLAB "$instances[$i]\n";
				}
			}
		}
		close CLAB;
	}
}

# writing testregex file
if(defined $opt_testregex)
{
	$testregex=$opt_testregex;
	if(-e $testregex)
	{
		print STDERR "Warning($0):
		Test Regex file <$testregex> already exists, overwrite (y/n)? ";
		$ans=<STDIN>;
	}
	if(!-e $testregex || $ans=~/Y|y/)
	{
		open(TESTREGEX,">$testregex") || die "Error($0):
		Error(code=$!) in opening the Test Regex file <$testregex>\n";
		# printing regexes 
		if (!defined $opt_dense) {
			# in sparse mode, we need to check for dropping
			# regexes for empty columns
			for ($index=1; $index <= @features; $index++)
			{
				if ($col[$index] > 0) {
					print TESTREGEX "/$features[$index-1]/" . " \@name=$clabels[$index-1]\n";
				}
			}
		} else {
			# in dense mode, output all column labels 
			for ($index=1; $index <= @features; $index++)
			{
				print TESTREGEX "/$features[$index-1]/" . " \@name=$clabels[$index-1]\n";
			}
		}
		close TESTREGEX;
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
	print "Usage: order1vec.pl [OPTIONS] SVAL2 FEATURE_REGEX";
	print "\nTYPE order1vec.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  order1vec.pl [OPTIONS] SVAL2 FEATURE_REGEX

Displays the first order context vectors of the instances in the given SVAL2 
file.

SVAL2 
	A tokenized, preprocessed and well formatted Senseval-2 instance file.

FEATURE_REGEX
	
	A file containing Perl regular expressions for features as created 
        by nsp2regex.pl.

OPTIONS:

--binary
	Displays binary context vectors that show mere presence or absence of 
	features in the contexts. By default, frequency vectors are displayed.

--dense 
	Displays dense context vectors. By default, context vectors will have
	sparse format.

--rlabel RLABELFILE
	Writes row labels (instance ids) to the RLABELFILE which can be given 
	to vcluster's --rlabelfile option.
	
--rclass RCLASSFILE
	Writes sense ids to the RCLASSFILE which can be given to vcluster's 
	--rclassfile option.

	This option cannot be specified when --transpose is specified.

--clabel CLABELFILE
	Writes column labels (features) to the CLABELFILE which can be given 
	to vcluster's --clabelfile option.

--transpose
	Creates feature vectors instead of the default context vectors. The 
	output is a Latent Semantic Analysis style feature-by-context matrix, 
	instead of the default context-by-feature matrix that is native to 
	SenseClusters. As a result, the contents of the RLABELFILE and 
	CLABELFILE are swapped, i.e. the list of features is output to the 
	RLABELFILE and the list of contexts is output to the CLABELFILE.

--testregex TEST_REGEX

	Creates a TEST_REGEX file containing only those regular expressions 
	from the input FEATURE_REGEX file that matched at least once in the 
	input SVAL2 file. This list can be different from the original list 
	in FEATURE_REGEX when different training data has been used to 
	identify features or when a different scope has been used for 
	training and test data creation.

	This option is required when the --transpose option is specified.

--showkey
	Displays the system generated KEY file name on the first line.

	This option cannot be specified when --transpose is specified.

--target TARGET_REGEX
	Specify a file containing Perl regex/s that define the target word
	in SVAL2. By default, target.regex is assumed to exist in current
	directory.

--extarget
	Excludes the target word from features if the target word as
	specified by --target or default target.regex, is listed in the
	FEATURE_REGEX file.

Other Options:

--help
	Displays this message.

--version
	Displays the version information.

Type 'perldoc order1vec.pl' to view detailed documentation of order1vec.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: order1vec.pl,v 1.48 2008/03/30 04:40:58 tpederse Exp $';
	print "\nConvert Senseval-2 contexts into first order feature vectors\n";

#        print "\nCopyright (c) 2002-2006, Ted Pedersen, Amruta Purandare, Anagha Kulkarni, & Mahesh Joshi\n";
#        print "order1vec.pl      -       Version 0.08\n";
#        print "Displays the first order context vectors.\n";
#        print "Date of Last Update:     03/04/2005\n";
}

#############################################################################

