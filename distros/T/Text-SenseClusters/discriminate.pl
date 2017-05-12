#!/usr/local/bin/perl -w

=head1 NAME

discriminate.pl Wrapper program to run SenseClusters in a single command

=head1 SYNOPSIS

Discriminates among the given text instances based on their contextual 
similarities.

=head1 USAGE

discriminate.pl [OPTIONS] TEST

=head1 INPUT

=head2 Required Arguments:

=head3 TEST

Senseval-2 formatted TEST instance file that contains the instances
to be clustered.

=head2 Optional Arguments:

=head3 DATA OPTIONS :

=head4 --training TRAIN

Training file in plain text format that can be used to select features.
If this is not specified, features are selected from the given TEST file.

=head4 --split N

Splits the given TEST file into two portions, N% for the use as the TRAIN 
data and (100-N)% as the TEST data. The value for N is a percentage and 
should be an integer between 1 to 99 (inclusive). The instances from the 
original TEST file are not picked or split in any particular order but are 
randomly split into the two portions of TRAIN and TEST data while maintaining
the ratio of N/(100-N).

Note: This option cannot be used when --training option is also used.

=head4 --token TOKEN

A file containing Perl regex/s that define the tokenization scheme in TRAIN
and TEST files. If --token is not specified, default token regex file 
token.regex is searched in the current directory.

=head4 --target TARGET

A file containing Perl regex/s for identifying the target word. A sample
target.regex file containing regex:

    /<head>\w+</head>/

is provided with this distribution. If --target is not specified, default 
target regex file target.regex is searched in the current directory. 
If this file doesn't exist, target.regex is automatically created by finding
all instances of <head> tags from the TEST data. If there are no instances
of <head> tags in TEST, the given data is assumed to be global and target
word is not searched in either TRAIN or TEST.

 Note: --target cannot be specified with headless input data
       i.e. test file without head/target word(s).

=head4 --prefix PRE

Specify a prefix to be used in all output file names. e.g. context vector
file will have name 'PRE.vectors', features file will have name 'PRE.features'
and so on ... By default, a random prefix is created using the time stamp.

=head4 --format f16.XX

The default format for floating point numbers is f16.06. This means that
there is room for 6 digits to the right of the decimal, and 9 to the
left. You may change XX to any value between 0 and 15, however, the
format must remain 16 spaces long due to formatting requirements of SVDPACKC.

=head4 --wordclust

Discriminates and clusters each word based upon its direct and indirect 
co-occurrence with other words (when used without the --lsa switch) or
clusters words or features based upon their occurrences in different contexts
(when used with the --lsa switch). 

 Note: 1. Separate (--training) TRAIN data should not be used with word 
          clustering.
       2. Starting with Version 0.93, word clustering is no longer 
          restricted to using only headless data. However, options 
          specific to headed data such as --scope_test and target 
          co-occurrence features (see below) cannot be used.

=head4 --lsa

Uses Latent Semantic Analysis (LSA) style representation for clustering
features or contexts. LSA representation is the transpose of
the context-by-feature matrix created using the native SenseClusters
order1 context representation.

This option can be used only in the following two combinations of 
the --context and the --wordclust options:

=over

=item 1.  --context o1 --wordclust --lsa


Performs feature clustering by grouping together features based on the
contexts that they occur in. Features can be unigrams, bigrams or 
co-occurrences. Feature vectors are the rows of the transposed
context-by-feature representation created by order1vec.pl.

=item 2.  --context o2 --lsa


Performs context clustering by creating context vectors by averaging the
feature vectors from the transposed context-by-feature representation of 
order1vec.pl.

=back

=head3 FEATURE OPTIONS :

=head4 --feature TYPE

Specify the feature type to be used for representing contexts. 
Possible options for feature type with first order context representation:

	bi	-   bigrams  [default]
	tco	-   target co-occurrences	
	co	-   co-occurrences
	uni	-   unigrams

Possible options for feature type with second order context representation:

	bi	-   bigrams  [default]
	co	-   co-occurrences
	tco	-   target co-occurrences

 Note: --tco (target co-occurrences) cannot be used with headless 
       data i.e. test/train file without head/target word(s).

=head4 --scope_train S1

Limits the scope of the training contexts to S1 words around (on both 
sides of) the TARGET word. Thus, it allows selection of local features.
If --scope_train is used, each training instance is expected to include
the target word as specified by the --target option or default target.regex.

 Note: --scope_train cannot be used with headless data i.e. train files
       without head/target word(s).

=head4 --scope_test S2

Limits the scope of the test contexts to S2 words around (on both sides of)
the TARGET word. Thus, it allows to match and use local features in the 
context vectors.

 Note: --scope_test cannot be used with headless data i.e. test files
       without head/target word(s).

=head4 --stop STOPFILE

A file of Perl regexes that define the stop list of words to be excluded from 
the features.

STOPFILE could be specified with two modes -

AND mode - declared by including '@stop.mode=AND' on the first line of the
STOPFILE.
         - ignores word pairs in which both words are stop words.

OR mode - declared by including '@stop.mode=OR' on the first line of the
STOPFILE.
        - ignores word pairs in which either word is a stop word.

Both modes exclude stop words from unigram features.

Default is OR mode.

=head4 --remove F

Removes features that occur less than F times in the training corpus.

=head4 --window W

Specifies the window size for bigram/co-occurrence features. Pairs of words 
that co-occur within the specified window from each other (window W allows at 
most W-2 intervening words) will form the bigram/co-occurrence features. 

Default window size is 2 which allows only consecutive word pairs.

Not applicable to unigram features.

=head4 --stat STAT

Bigrams and co-occurrences can be selected based on their statistical scores 
of association as specified by this option. If --vector = o2 and
--stat is used, word association matrix will use the scores computed by the 
specified statistical test instead of simple joint frequency counts of the
word pairs.

Available tests of association are :

	dice            -       Dice Coefficient
        ll              -       Log Likelihood Ratio
        odds            -       Odds Ratio
        phi             -       Phi Coefficient
        pmi             -       Point-Wise Mutual Information
        tmi             -       True Mutual Information
        x2              -       Chi-Squared Test
        tscore          -       T-Score
        leftFisher      -       Left Fisher's Test
        rightFisher     -       Right Fisher's Test

By default, features are selected and represented using their frequency 
counts.

=head4 --stat_rank N

Word pairs ranking below N when arranged in descending order of their test 
scores are ignored. 

--stat_rank has no effect unless --stat is specified.

=head4 --stat_score S

Selects word pairs with scores greater than S after performing the selected
test of association. Score could be any real number that will give reasonable 
number of features for the requested test. 

--stat_score has no effect unless --stat is specified.

=head3 VECTOR OPTIONS :

=head4 --context ORD

Specifies the context representation to be used. Set ORD to 'o1' to use 
1st order context vectors, and to 'o2' to select 2nd order context vectors.
Default context representation is o2.

=head4 --binary

Creates binary feature and context vectors. By default, feature vectors 
show the joint frequency scores of the associated word pairs while the
context vectors show the average of the feature vectors of words that occur 
in the context. With --binary turned ON, feature vectors show mere presence or 
absence of the particular word pair (co-occurrence/bigram) in TRAIN, 
while the context vectors will represent a binary 'OR' operation on the
corresponding vectors of contextual features.

=head3 SVD OPTIONS :

=head4 --svd

Reduces the feature space dimensions by performing Singular Value Decomposition
(SVD). By default, all feature dimensions are retained.

=head4 --k K

Reduces the dimensions of the feature space to K. Default K = 300

=head4 --rf RF

Specifies the scaling factor for reducing feature space dimensions such that
feature space with N dimensions is reduced down to N/RF. Default RF = 4.
RF should be an integer greater than 1.

If both --k and --rf are specified, dimensions are reduced to min(k,N/RF).

 Note: If the reduced dimensions ( min(k,N/RF) ) turn-out to be less than 
       or equal to 10 then svd is not performed.

=head4 --iter I

Specifies the number of iterations of SVD. Recommended value is 3 times 
the desired K.

=head3 CLUSTER-STOPPING OPTIONS:

=head4 --cluststop CS

Specifies the cluster stopping measure to be used to predict the number
the number of clusters.

   The possible option values:
   pk1 - Use PK1 measure [ PK1[m] = (crfun[m] - mean(crfun[1...deltaM]))/std(crfun[1...deltaM])) ]
   pk2 - Use PK2 measure [ PK2[m] = (crfun[m]/crfun[m-1]) ]
   pk3 - Use PK3 measure [ PK3[m] = ((2 * crfun[m])/(crfun[m-1] + crfun[m+1])) ]
   gap - Use Adapted Gap Statistic. 
   pk  - Use all the PK measures.
   all - Use all the four cluster stopping measures.

More about these measures can be found in the documentation of 
Toolkit/clusterstop/clusterstopping.pl

NOTE: Options --cluststop and --clusters (described under Clustering options) cannot be used together.

=head4 --delta INT

NOTE: Delta value can only be a positive integer value.

Specify 0 to stop the iterating clustering process when two consecutive crfun values 
are exactly equal. This is the default setting when the crfun values are integer/whole numbers.

Specify non-zero positive integer to stop the iterating clustering process when the difference 
between two consecutive crfun values is less than or equal to this value. However, note that the
integer value specified is internally shifted to capture the difference in the least significant 
digit of the crfun values when these crfun values are fractional.
 For example: 
    For crfun = 1.23e-02 & delta = 1 will be transformed to 0.0001
    For crfun = 2.45e-01 & delta = 5 will be transformed to 0.005
The default delta value when the crfun values are fractional is 1.

However if the crfun values are integer/whole numbers (exponent >= 2) then the specified delta 
value is internally shifted only until the least significant digit in the scientific notation.
 For example: 
    For crfun = 1.23e+04 & delta = 2 will be transformed to 200
    For crfun = 2.45e+02 & delta = 5 will be transformed to 5
    For crfun = 1.44e+03 & delta = 1 will be transformed to 10

=head4 --threspk1 NUM

Specifies the threshold value that should be used by the PK1 measure to predict the k value. 
Default = -0.7

NOTE: This option should be used only when --cluststop option is also used
with option value of "all" or "pk1".

=head3 CLUSTER-STOPPING: ADAPTED GAP STATISTIC OPTIONS:

=head4 --B NUM 

The number of replicates/references to be generated.
Default: 1

=head4 --typeref TYP 

Specifies whether to generate B replicates from a reference or to generate 
B references.

The possible option values:
      rep - replicates [Default]
      ref - references

=head4 --percentage NUM 

Specifies the percentage confidence to be reported in the log file.
Since Gap Statistic uses parametric bootstrap method for reference distribution
generation, it is critical to understand the interval around the sample mean that
could contain the population ("true") mean and with what certainty.
Default: 90

=head4 --seed NUM 

The seed to be used with the random number generator. 
Default: No seed is set.

=head3 CLUSTERING OPTIONS :

=head4 --clusters N

Specifies number of clusters to be created. Default is set to 2.

=head4 --space SPACE

Specifies whether clustering is to be performed in vector or similarity space.
Set the value of SPACE to 'vector' to perform clustering in vector space i.e.
to cluster the context vectors directly. To cluster in similarity space
by explicitly finding the pair-wise similarities among the contexts,
set SPACE to 'similarity'. 

By default, clustering is performed in vector space.

=head4 --clmethod CL

Specifies the clustering method.

Possible option values are :

	rb - Repeated Bisections [Default]
        rbr - Repeated Bisections for by k-way refinement
        direct - Direct k-way clustering
        agglo  - Agglomerative clustering
        graph  - Graph partitioning-based clustering
        bagglo - Partitional biased Agglomerative clustering

For large amount of data, 'rb', 'rbr' or 'direct' are recommended. 

=head4 --crfun CR

Selects the criteria function for Clustering. The meanings of these criteria
functions are explained in Cluto's manual.

The possible values are:

        i1      -  I1  Criterion function
        i2      -  I2  Criterion function [default for partitional]
        e1      -  E1  Criterion function
        g1      -  G1  Criterion function
        g1p     -  G1' Criterion function
        h1      -  H1  Criterion function
        h2      -  H2  Criterion function
        slink   -  Single link merging scheme
        wslink  -  Single link merging scheme weighted w.r.t. cluster sim
        clink   -  Complete link merging scheme
        wclink  -  Complete link merging scheme weighted w.r.t. cluster sim
        upgma   -  Group average merging scheme [default for agglomerative]

Note that for cluster stopping, i1, i2, e1, h1 and h2 criterion functions 
can only be used. If a crfun other than these is selected then cluster 
stopping uses the default crfun (i2) while the final clustering of contexts
is performed using the crfun specified.

=head4 --sim SIM

Specifies the similarity measure to be used for either vector or similarity
space clustering.

When --space = vector (or default), possible values of SIM are :

        cos      -  Cosine [default]
        corr     -  Correlation Coefficient
        dist     -  Euclidean distance
        jacc     -  Extended Jaccard Coefficient

When --space = similarity and --binary is ON, possible values of SIM are -

        cos     - Cosine [default]
        mat     - Match
        jac     - Jaccard
        ovr     - Overlap
        dic     - Dice

Otherwise, only cosine measure is available and is default.

The following table summarizes availability of similarity measures
for 2 clustering approaches - vector(vcl) and similarity(scl) and
on 2 different types of context vectors - binary Vs frequency

        vcl+bin         vcl+freq        scl+bin         scl+freq
 cos     Y               Y               Y               Y
 mat     N               N               Y               N
 jacc    Y               Y               Y               N
 dice    N               N               Y               N
 ovr     N               N               Y               N
 dist    Y               Y               N               N
 corr    Y               Y               N               N

The reasons are purely implementation issues and in future, we plan to support
more consistent measures across these combinations.

=head4 --rowmodel RMOD

The option is used to specify the model to be used to scale every 
column of each row. (For further details please refer Cluto manual)

The possible values for RMOD -
        none  -  no scaling is performed (default setting)
        maxtf -  post scaling the values are between 0.5 and 1.0
        sqrt  -  square-root of actual values
        log   -  log of actual values

=head4 --colmodel CMOD

The option is used to specify the model to be used to (globally) scale each 
column across all rows. (For further details please refer Cluto manual)

The possible values for CMOD -
        none  -  no scaling is performed (default setting)
        idf   -  scaling according to inverse-document-frequency 

=head3 LABELING OPTIONS :

Note: Labeling options cannot be used with word-clustering (--wordclust).

=head4 --label_stop LABEL_STOPFILE

A file of Perl regexes that define the stop list of words to be 
excluded from the features.

LABEL_STOPFILE could be specified with two modes -

AND mode - declared by including '@stop.mode=AND' on the first line of the
LABEL_STOPFILE
         - ignores word pairs in which both words are stop words.

OR mode - declared by including '@stop.mode=OR' on the first line of the
LABEL_STOPFILE
        - ignores word pairs in which either word is a stop word.

Default is OR.

=head4 --label_ngram LABEL_NGRAM

Specifies the value of n in 'n-gram' for the feature selection. 
The supported values for n are 2, 3 and 4.

Default value is 2 i.e. bigram.

=head4 --label_remove LABEL_N

Removes ngrams that occur less than LABEL_N times.

=head4 --label_window LABEL_W

Specifies the window size for bigrams. Pairs of words that co-occur 
within the specified window from each other (window LABEL_W allows at most
LABEL_W-2 intervening words) will form the bigram features. 
Default window size is 2 which allows only consecutive word pairs.

=head4 --label_stat LABEL_STAT

Specifies the statistical scores of association.

Available tests of association are :

		dice            -       Dice Coefficient
        ll              -       Log Likelihood Ratio
        odds            -       Odds Ratio
        phi             -       Phi Coefficient
        pmi             -       Point-Wise Mutual Information
        tmi             -       True Mutual Information
        x2              -       Chi-Squared Test
        tscore          -       T-Score
        leftFisher      -       Left Fisher's Test
        rightFisher     -       Right Fisher's Test

=head4 --label_rank LABEL_R

Word pairs ranking below LABEL_R when arranged in descending order of 
their test scores are ignored. 

=head3 Other Options :

=head4 --eval

Evaluates clustering performance by computing precision and recall for maximally
accurate assignment of sense tags to clusters. Maximal Assignment is when
clusters are given sense labels such that maximum number of instances will be
attached with their true sense tags.

TEST instances tagged with multiple senses are automatically attached with the 
single sense-tag that is the most frequent among the attached tags.

Note: This option can be used only if the answer tags are provided in the TEST file.

=head4 --rank_filter R

Allows to remove low frequency senses during evaluation. This will
remove the senses that rank below R when senses in TEST are arranged
in the descending order of their frequencies. In other words, it
selects top R most frequent senses. An instance will be removed if
it has all sense tags below rank R.

=head4 --percent_filter P

Allows to remove low frequency senses based on their percentage
frequencies. This will remove senses whose frequency is below P%
in the TEST data.

If rank or percent filters are specified, they are applied after removing
the multiple sense tags.

=head4 --help

Displays the quick summary of program options.

=head4 --version

Displays the version information.

=head4 --verbose

Displays to STDERR the current program status.

=head4 --showargs

Displays to STDOUT values of compulsory and required parameters.
[NOT SUPPORTED IN THIS VERSION]

=head1 OUTPUT

discriminate.pl creates several output files. The discrimination of contexts 
performed by discriminate.pl, (i.e., a cluster assigned to each context) is given
by the file $PREFIX.clusters if the number of clusters was set manually, otherwise
by the file $PREFIX.clusters.$CLUSTSTOP where the $CLUSTSTOP specifies the cluster
stopping measure that was used to predict the number of clusters.

In addition, discriminate.pl also creates following files:

NOTE: If a cluster stopping measure was used then it is indicated in the names of
several output files by appending the cluster stopping measure name with the
file name. Represented below as filename[.$CLUSTSTOP]

=over

=item * $PREFIX.clusters_context[.$CLUSTSTOP] - File containing all the input instances grouped by the cluster-id assigned to them.

=item * $PREFIX[.$CLUSTSTOP].cluster.CLUSTERID - All the identified clusters and their instances are separated into different files. The filenames end with the cluster-id. e.g.: File containing instances of cluster 0 will be named as $PREFIX.cluster.0

=item * $PREFIX.report[.$CLUSTSTOP] - Confusion table if --eval is ON

=item * $PREFIX.cluster_labels[.$CLUSTSTOP] - List of labels (word-pairs) assigned to each cluster.

=item * $PREFIX[.$CLUSTSTOP].dendogram.ps - Dendograms + some information.

=item * $PREFIX.features - Features file

=item * $PREFIX.regex - File containing regular expressions for identifying
the features listed in $PREFIX.features file.

=item * $PREFIX.testregex - File containing only those regular expressions from 
the $PREFIX.regex file above, which match at least once in the test contexts, 
only created in second order context clustering mode (SC native as well as LSA)
and LSA feature clustering mode

=item * $PREFIX.wordvec - Word Vectors if --context = o2

=item * $PREFIX.vectors - Context Vectors

=item * $PREFIX.rlabel - Row Labels of $PREFIX.vectors

=item * $PREFIX.clabel - Column Labels of $PREFIX.vectors

=item * $PREFIX.rclass - Class Ids of $PREFIX.vectors if --eval is ON

=item * $PREFIX.cluster_solution[.$CLUSTSTOP] - Cluster ids of $PREFIX.vectors

=item * $PREFIX.cluster_output[.$CLUSTSTOP] - Clustering program output

=back

=head3 Cluster Stopping related output files:

=over

=item * $PREFIX.pk1 - crfun[k] values, delta values, PK1[k] values and predicted k value

=item * $PREFIX.pk2 - crfun[k] values, delta values, PK2[k] values and predicted k value

=item * $PREFIX.pk3 - crfun[k] values, delta values, PK3[k] values and predicted k value

=item * $PREFIX.gap - crfun[k] values, delta values and predicted k value

=item * $PREFIX.gap.log - Gap(k), Obs(crfun(k)), Exp(crfun(k)) values etc.

=back

=head3 The following files are created to facilitate creation of plots, if needed:

=over

=item * $PREFIX.cr.dat - value-pairs :- k-value crfun-value

=item * $PREFIX.pk1.dat - value-pairs :- k-value PK1[k] value

=item * $PREFIX.pk2.dat - value-pairs :- k-value PK2[k] value

=item * $PREFIX.pk3.dat - value-pairs :- k-value PK3[k] value

=item * $PREFIX.gap.dat - value-pairs :- k-value Gap[k] value

=item * $PREFIX.exp.dat - value-pairs :- k-value Exp(crfun[k]) value

=back

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Amruta Purandare, University of Pittsburgh

 Anagha Kulkarni, Carnegie-Mellon University

 Mahesh Joshi, Carnegie-Mellon Unversity

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

#                               THE CODE STARTS HERE

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

use Math::SparseMatrix;

# use the following perl module for command line options parsing
# Do not allow abbreviations of options i.e. options have to be spelled out completely.
use Getopt::Long qw(:config no_auto_abbrev);

# command line options
# catch, abort and print the message for unknown options specified
eval(GetOptions ("help","version","training=s","token=s","target=s","stop=s","feature=s","remove=i","window=i","scope_train=i","scope_test=i","stat=s","stat_rank=i","stat_score=f","context=s","binary","svd","k=i","rf=i","iter=i","clusters=i","space=s","clmethod=s","crfun=s","sim=s","eval","verbose","showargs","prefix=s","format=s","rank_filter=i","percent_filter=f","label_ngram=n","label_window=i","label_stop=s","label_remove=i","label_stat=s","label_rank=i","wordclust","split=i","rowmodel=s","colmodel=s","cluststop=s","threspk1=f","delta=i","B=i","typeref=s","percentage=i","seed=i", "lsa")) or die("Please check the above mentioned option(s).\n");

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
        exit 1;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

# Note on ERROR message conventions - error and warning messages from
# discriminate.pl should go to STDERR, and should be intended 1 tab.
# Error messages from Toolkit programs should be indented 2 tabs. 
# TDP August, 2006

# ----------
# Testfile
# ----------
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
	Please specify the TEST file name...\n";
        exit 1;
}
$testfile=$ARGV[0];
if(!-e $testfile)
{
        print STDERR "ERROR($0):
	Could not locate the TEST file <$testfile>\n";
        exit 1;
}

# ---------------
# Tokenfile
# ---------------

if(defined $opt_token)
{
	$token=$opt_token;
}
else
{
	$token="token.regex";
}

if(!-e $token)
{
	print STDERR "ERROR($0):
	Could not locate the TOKEN file <$token>\n";
	exit 1;
}
elsif(-z $token)
{
	print STDERR "ERROR($0):
	TOKEN file <$token> is empty.\n";
	exit 1;
}

# ---------------
# Targetfile
# ---------------

my $target = "";

if(defined $opt_target)
{
    $target=$opt_target;
	if(!-e $target)
	{
        print STDERR "ERROR($0):
	Could not locate the TARGET file <$target>\n";
        exit 1;
	}
}
else
{
    $target="target.regex";
	# this will automatically create the target.regex file
	# in the current dir.
	if(!-e $target)
	{
		$status=system("maketarget.pl -head $testfile");
		die "Error while running maketarget.pl on <$testfile>\n" unless $status==0;
	}
}

# --------------
#  Prefix
# --------------

if(defined $opt_prefix)
{
	$prefix=$opt_prefix;
}
else
{
	$prefix="expr" . time();
}

# --------------
#  Format
# --------------

if(defined $opt_format)
{
    if ($opt_format !~/^(f16.\d\d)/)
	{
	    print STDERR "ERROR($0):
	--format must be of the form f16.XX, where 0 <= XX < 16, 
	not $opt_format\n";
        exit 1;
	}
    else
	{
		$format=$opt_format;     ## format is defined, has valid form
		$format =~ /^f16.(\d\d)/;
		$prec = $1;  # precision
	}
}
else
{
    $format = "f16.06";          ## format is not defined, use default
	$prec = 6;
}

# --------------
# SVD options
# --------------

if(!defined $opt_k)
{
    $opt_k=300;
}
if(!defined $opt_rf)
{
    $opt_rf=10;
}

# default feature
if(!defined $opt_feature)
{
    $opt_feature = "bi";
}

# initialize the variable for default number of clusters
$default_clusters = 2;

# --------------
#  Error checks
# --------------

if(defined $opt_space)
{
        if($opt_space !~/^(vector|simil)/)
        {
			print STDERR "ERROR($0):
	--space should be either 'vector' or 'similarity'.\n";
			exit 1;
        }
}

if($opt_feature !~/^(bi(gram)?|co(occur|c)?|uni(gram)?|tco(occur|c)?)/)
{
	print STDERR "ERROR($0):
	Specified Feature type --$opt_feature is not supported.\n";
	exit 1;
}

if($opt_feature=~/^uni(gram)?/ && !defined $opt_lsa && (!defined $opt_context || $opt_context =~ /o2|order2/))
{
	print STDERR "ERROR($0):
	--feature cannot be $opt_feature when --context is o2, 
	unless --lsa is also specified\n";
	exit 1;
}

if(defined $opt_split && ($opt_split >=100 || $opt_split <= 0))
{
	print STDERR "ERROR($0):
	The N value for the --split option should be between 1 to 99\n";
	exit 1;
}


# Option validations for Word Clustering and headless input data.

# Find the type (headed/headless) of the Test and Train data 
# and then handle the following cases:
# Case 1: train headless / test headed 
# Case 2: train headless / test headless
# Case 3: train headed / test headed  
# Case 4: train headed / test headless 

my $TestType = 0; # By default headed
my $TrainType = 0; # By default headed

# check the Test data for <head> tag
open (INP,$testfile) || die "Error($0):
    Error(code=$!) in opening <$testfile> file.\n";

# read the complete file in single instruction instead of reading line by line.
my $temp_delimiter = $/;
$/ = undef;

my $inp_str = <INP>;

$/ = $temp_delimiter;
close INP;
	
# If the --eval option specified Then check if answer tags present 
if(defined $opt_eval)
{
	if($inp_str !~ m/<answer/)
	{
		print STDERR "ERROR($0):
	The --eval option cannot be used with unlabeled data.
	In other words, the experiment cannot be evaluated if 
	the input Senseval2 file does not contain the answer tags.\n";
		exit 1;		
	}
}

if($inp_str !~ m/<head>.+<\/head>/i)
{
    $TestType = 1; # headless
}

# when separate training data specified
if(defined $opt_training)
{
    # training data cannot be provided word clustering.
    if(defined $opt_wordclust)
    {
		if (defined $opt_lsa) 
		{
			print STDERR "ERROR($0):
	--training option cannot be used with feature-clustering.\n";
		} 
		else 
		{
	    print STDERR "ERROR($0):
	--training option cannot be used with word-clustering.\n";
	}
	exit 1;
    }

    # check if the training file exists
    if(!-e $opt_training)
    {
        print STDERR "ERROR($0):
	Could not locate the TRAIN file <$opt_training>\n";
        exit 1;
    }

    # check if the training file is a text file.
    if(!-T $opt_training)
    {
	print STDERR "ERROR($0):
	Training file has to be a plain text file. 
	The provided file is not a text file. \n";
	exit 1;		
    }
    
    open (INP,$opt_training) || die "Error($0):
        Error(code=$!) in opening <$opt_training> file.\n";
    
    # read the complete file in single instruction instead of reading line by line.
    my $temp_delimiter = $/;
    $/ = undef;
    
    my $inp_str = <INP>;

    $/ = $temp_delimiter;
    close INP;

	# check if the training file is senseval2 formatted file - if yes quit.
	if($inp_str =~ m/<corpus/i && $inp_str =~ m/<lexelt/i && $inp_str =~ m/<instance/i && $inp_str =~ m/<context/i)
	{
		print STDERR "ERROR($0):
	Training file has to be a plain text file. 
	The provided file is a Senseval2 formatted file. \n";
		exit 1;		
	}

	# check if the training file is html formatted file - if yes quit.
	if($inp_str =~ m/<html/i)
	{
		print STDERR "ERROR($0):
	Training file has to be a plain text file. 
	The provided file is a html formatted file. \n";
		exit 1;		
	}

	# check if the training file is xml formatted file - if yes quit.
	if($inp_str =~ m/<\?xml/i)
	{
		print STDERR "ERROR($0):
	Training file has to be a plain text file. 
	The provided file is an xml formatted file. \n";
		exit 1;		
	}

	# checks the Train data for <head> tag    
    if($inp_str !~ m/<head>.+<\/head>/i)
    {
        $TrainType = 1;
    }
}
else # Test data to be used as Train data thus $TrainType = $TestType
{
	$TrainType = $TestType;
}

# scope cannot be used with headless training data 
if (defined $opt_scope_train && $TrainType == 1) {
  print STDERR "ERROR($0):
	--scope_train option cannot be used 
	when the Train data is headless.\n";
  exit 1;
}

# scope cannot be used with headless test data, or when word clustering
# is requested
if (defined $opt_scope_test && ($TestType == 1 || defined $opt_wordclust)) {
  print STDERR "ERROR($0):
	--scope_test option cannot be used when the Test data 
	is headless or when word clustering is requested.\n";
  exit 1;
}

# word-clustering is treated as headless type of clustering thus 
# 1. check for target co-occurrence
# 2. target option
if(defined $opt_wordclust)
{
	# we do no allow tco as the feature type, headed data is allowed but
  # <head>...</head> is simply a normal token in this case
	if(defined $opt_feature && $opt_feature eq "tco")
	{
		print STDERR "ERROR($0):
	target co-occurrences (tco) cannot be used as the feature 
	type with word-clustering.\n";
		exit 1;
	}

	# headless case which cannot allow target file option
	if(defined $opt_target)
	{
		print STDERR "ERROR($0):
	--target option cannot be used with word-clustering.\n";
		exit 1;
	}
}

# --lsa cannot be used in o1 context representation, unless word clustering is specified
if (defined $opt_lsa) {
  if($opt_context =~ /o1|order1/ && !defined $opt_wordclust) {
    print STDERR "ERROR($0):
	--lsa option cannot be used with --context o2 
	without specifying the --wordclust option\n";
    exit 1;
  }
  if((!defined $opt_context || $opt_context =~ /o2|order2/) && defined $opt_wordclust) {
    print STDERR "ERROR($0):
	--lsa option can be used either with \"--context o2\" 
	(the default) or with \"--context o1 --wordclust\" options, 
	but not with \"--context o2 --wordclust\".\n";
    exit 1;
  }
}

# Case 1: train headless / test headed 
if($TrainType == 1 && $TestType == 0)
{
	# headed case which cannot allow tco as the feature type
	if(defined $opt_feature && $opt_feature eq "tco")
	{
		print STDERR "ERROR($0):
	target co-occurrences (tco) cannot be used as the feature 
	type when the Test/Train data is headless.\n";
		exit 1;
	}
}

# Case 2: train headless / test headless And 
# Case 4: train headed / test headless 
if(($TrainType == 1 && $TestType == 1) || ($TrainType == 0 && $TestType == 1))
{
	# headless case which cannot allow target file option
	if(defined $opt_target)
	{
		print STDERR "ERROR($0):
	--target option cannot be used with headless clustering.\n";
		exit 1;
	}

	# headless case which cannot allow tco as the feature type
	if(defined $opt_feature && $opt_feature eq "tco")
	{
		print STDERR "ERROR($0):
	target co-occurrences (tco) cannot be used as the feature type 
	when the Test/Train data is headless.\n";
		exit 1;
	}
}

# Case 3: train headed / test headed  
# No Special error checks required

# Check if Test and Train specified by user and --split option is also used
if(defined $opt_training && defined $opt_split)
{
	print STDERR "ERROR($0):
	Cannot use --split option to split the input data 
	into Test and Train portions if separate Training data 
	(--training) is alredy specified.\n";
	exit 1;
}

# if space is vector and clmethod is graph then only can 
# jacc and dist similarity measures be used.
if((!defined $opt_space || $opt_space eq "vector") && (!defined $opt_clmethod || $opt_clmethod ne "graph") && defined $opt_sim && ($opt_sim eq "dist" || $opt_sim eq "jacc"))
{
    print STDERR "ERROR($0):
	Similarity Measures (--sim) Euclidean distance and Jaccard can 
	only be used if Clustering Method(--clmethod graph) is Graph
	and Clustering Space (--space vector) is Vector.\n";
    exit 1;
}
if(defined $opt_space && $opt_space eq "similarity" && !defined $opt_binary && defined $opt_sim && $opt_sim ne "cos")
{
    print STDERR "ERROR($0):
	Only Cosine Similarity Measure (--sim cos) is a valid option 
	if Clustering space is similarity (--space similarity)
	and --binary option is not ON.\n";
    exit 1;
}
if(defined $opt_space && $opt_space eq "similarity" && defined $opt_clmethod && $opt_clmethod eq "bagglo")
{
    print STDERR "ERROR($0):
	Partitional biased Agglomerative clustering (--clmethod bagglo) 
	available only for vector space.\n";
    exit 1;
}
if(defined $opt_clmethod && $opt_clmethod ne "agglo" && defined $opt_crfun && ($opt_crfun eq "slink" || $opt_crfun eq "wslink" || $opt_crfun eq "clink" || $opt_crfun eq "wclink" || $opt_crfun eq "upgma"))
{
    print STDERR "ERROR($0):
	$opt_crfun Criterion Function (--crfun $opt_crfun) valid only if 
	Clustering Method is agglomerative (--clmethod agglo). \n";
    exit 1;
}
# Error Checks for the rowmodel and colmodel options of Cluto
if(defined $opt_rowmodel && $opt_rowmodel !~/^(none|maxtf|sqrt|log)$/)
{
	print STDERR "ERROR($0):
	Specified rowmodel value: $opt_rowmodel is not supported.\n";
	exit 1;
}
if(defined $opt_space && $opt_space eq "similarity" && defined $opt_rowmodel)
{
    print STDERR "ERROR($0):
	--rowmodel option can be used only in vector space. \n";
    exit 1;
}
if(defined $opt_colmodel && $opt_colmodel !~/^(none|idf)$/)
{
	print STDERR "ERROR($0):
	Specified colmodel value: $opt_colmodel is not supported.\n";
	exit 1;
}
if(defined $opt_space && $opt_space eq "similarity" && defined $opt_colmodel)
{
    print STDERR "ERROR($0):
	--colmodel option can be used only in vector space. \n";
    exit 1;
}

# cluster stopping related initializations and error checks
# if neither #clusters nor cluster-stopping measure specified
if(!defined $opt_clusters && !defined $opt_cluststop)
{
	$opt_clusters = $default_clusters;
}

if(defined $opt_clusters && defined $opt_cluststop)
{
    print STDERR "ERROR($0):
	--clusters and --cluststop options cannot be used together. \n";
    exit 1;
}

if(defined $opt_cluststop && $opt_cluststop !~ /^(all|pk|pk1|pk2|pk3|gap)$/i)
{
    print STDERR "ERROR($0):
	$opt_cluststop not a valid option value for --cluststop. \n";
    exit 1;
}

if(!defined $opt_cluststop && defined $opt_threspk1)
{
    print STDERR "ERROR($0):
	--threspk1 option can be used only when using --cluststop option. \n";
    exit 1;
}

if(!defined $opt_cluststop && defined $opt_delta)
{
    print STDERR "ERROR($0):
	--delta option can be used only when using --cluststop option. \n";
    exit 1;
}

if(defined $opt_typeref && $opt_typeref !~ /^(rep|ref)$/i)
{
    print STDERR "ERROR($0):
	$opt_typeref not a valid option value for --typeref. \n";
    exit 1;
}

if(defined $opt_percentage && ($opt_percentage < 0 || $opt_percentage > 100))
{
    print STDERR "ERROR($0):
	The value for --percentage must be in the range [0,100] (inclusive).\n";
    exit 1;
}

##############################################################################

#			-------------------------
#			       Preprocessing
#			-------------------------

if(defined $opt_verbose)
{
	print STDERR "Preprocessing the input data ...\n";
}

# if TEST contains actual sense tags,
# filter TEST to remove multiple 
# senses / instance
if(defined $opt_eval)
{
	# removing multiple senses of TEST instances

	$test_report="$prefix.test_report";
	$status=system("frequency.pl $testfile > $test_report");
	die "Error while running frequency.pl on <$testfile>\n" unless $status==0;

	$status=system("filter.pl --percent 0 --nomulti $testfile $test_report > $testfile.nomulti");
	die "Error while running filter.pl on <$testfile>\n" unless $status==0;

	# applying filters now
	if(defined $opt_rank_filter || defined $opt_percent_filter)
	{
		if(defined $opt_verbose)
		{
			print STDERR "Removing Low Frequency Senses from TEST ...\n";
		}
		if(defined $opt_rank_filter)
		{
			$filter_string="--rank $opt_rank_filter ";
		}
		else
		{
			$filter_string="--percent $opt_percent_filter ";
		}
		$status=system("filter.pl $filter_string $testfile.nomulti $test_report > $testfile.filtered");
		die "Error while running filter.pl on <$testfile.nomulti>\n" unless $status==0;
		$testfile="$testfile.filtered";
	}
	else
	{
        	$testfile="$testfile.nomulti";
	}
}

if(defined $opt_training)
{
	$train_plain=$opt_training;

	$tmp_testfile = "$testfile.pro";

	$status = system("preprocess.pl --token $token --removeNotToken --xml $tmp_testfile --nocount $testfile");
	die "Error in running preprocess.pl on <$testfile>\n" unless $status==0;
	$testfile = $tmp_testfile;
}
else
{
	if(defined $opt_split)
	{
		# convert test in sval2 to plain, process the test file and also split the data
		$train_plain="$prefix.train_plain";
		$tmp_testfile = "$testfile.pro";
		
		$status = system("preprocess.pl --token $token --removeNotToken --xml $tmp_testfile --count $train_plain --split $opt_split $testfile");
		die "Error in running preprocess.pl on <$testfile>\n" unless $status==0;

		# delete the unnecessary file that get created by preprocessor.pl when used with the split option
		unlink "$tmp_testfile-training","$train_plain-test";

		# use the appropriate test and train file henceforth
		$testfile = "$tmp_testfile-test";
		$train_plain = "$train_plain-training";

		$train_sval2=$testfile;
	}
	else
	{
		# convert test in sval2 to plain and also clean the test file
		$train_plain="$prefix.train_plain";
		$tmp_testfile = "$testfile.pro";
		
		$status = system("preprocess.pl --token $token --removeNotToken --xml $tmp_testfile --count $train_plain $testfile");
		die "Error in running preprocess.pl on <$testfile>\n" unless $status==0;
		
		# use the clean test file henceforth
		$testfile = $tmp_testfile;
		
		$train_sval2=$testfile;
	}
}

############################################
# Localizing the Context Scope in Training
############################################

if(defined $opt_scope_train)
{
	if(defined $opt_verbose)
	{
		print STDERR "Localizing the Context Scope in TRAIN ...\n";
	}

	if(!defined $train_sval2)
	{
		# converting training data to sval2 format
		$train_sval2="$prefix.train_sval2";
		$status=system("text2sval.pl $train_plain > $train_sval2");
		die "Could not run text2sval.pl on <$train_plain>\n" unless $status==0;
	}
	# running windower
	$train_context="$prefix.train_context";
    if(defined $opt_target)
    {
        $status=system("windower.pl --plain --target $target --token $token $train_sval2 $opt_scope_train > $train_context");
        die "Error while running windower.pl on <$train_sval2>\n" unless $status ==0;
    }
    else
    {
        $status=system("windower.pl --plain --token $token $train_sval2 $opt_scope_train > $train_context");
        die "Error while running windower.pl on <$train_sval2>\n" unless $status ==0;
    }
	$train=$train_context;
}
else
{
	$train=$train_plain;
}

######################
# Selecting Features
######################

if($opt_feature =~ /^uni(gram)?/)
{
	if(defined $opt_verbose)
	{
		print STDERR "Computing Unigram Counts ...\n";
	}
	$unigrams="$prefix.unigrams";
	$count_string="";

	if(defined $opt_remove)
        {
                $count_string="--remove $opt_remove ";
        }

	if(defined $opt_stop)
        {
                $count_string.="--stop $opt_stop ";
        }

        $status=system("count.pl --ngram 1 --newLine --token $token $count_string $unigrams $train");
        die "Error while running count.pl with --ngram 1 on <$train>\n" unless $status==0;

}
else
{
	###########################
	# Computing Bigram Counts
	###########################

	if(defined $opt_verbose)
	{
		print STDERR "Computing Bigram Counts ...\n";
	}

	$bigrams="$prefix.bigrams";
	$count_string="";

	if(defined $opt_remove)
	{
		$count_string="--remove $opt_remove ";
	}
	if(defined $opt_window)
	{
		$count_string.="--window $opt_window ";
	}
	if(defined $opt_stop)
	{
		$count_string.="--stop $opt_stop ";
	}

	$status=system("count.pl --extended --newLine --token $token $count_string $bigrams $train");
	die "Error while running count.pl on <$train>\n" unless $status==0;

	###################
	# Combining Counts
	###################

	if($opt_feature =~/^(co(occur|c)?|tco(occur|c)?)/)
	{
	    if(defined $opt_verbose)
	    {
		print STDERR "Combining Bigrams into Co-occurrence pairs ...\n";
	    }
	 
	    # check the number of bigram features present
		open (INP,"<$bigrams") || die "Error($0):
            Error(code=$!) in opening <$bigrams> file\n";		
	    
	    my $feat_cnt = 0;
	    while(<INP>)
	    {
		# skip the header
		if(/^@/)
		{
		    next;
		}

		# capture the count
		if(/^(\d+)/)
		{
		    $feat_cnt = $1;
		    last;
		}
	    }
	    
	    if(!$feat_cnt)
	    {
		if($opt_feature =~/^tco(occur|c)?/)		
		{
		    print STDERR "ERROR($0):
	0 FEATURES found in the <$bigrams> file.
	This will lead to 0 co-occurrence features and 0 target 
	co-occurrence features. Therefore aborting the experiment.\n";
		}
		else
		{
		    print STDERR "ERROR($0):
	0 FEATURES found in the <$bigrams> file.
	This will lead to 0 co-occurrence features. Therefore aborting 
	the experiment.\n";
		}

		exit 1;		
	    }

	    $pairs="$prefix.cocs";
	    $status=system("combig.pl $bigrams > $pairs");
	    die "Error while running combig.pl on <$bigrams>\n" unless $status==0;
	    
	    if($opt_feature =~ /^tco(occur|c)?/) # target co-occurrences
	    {
		if(defined $opt_verbose)
		{
		    print STDERR "Finding Target Co-occurrences ...\n";
		}
		
		# select the target co-occurrences from the *.cocs file
		$target_pairs = "$prefix.target_cocs";
		
		open (INP,"<$pairs") || die "Error($0):
            Error(code=$!) in opening <$pairs> file\n";
		
		open (OUT,">$target_pairs") || die "Error($0):
            Error(code=$!) in opening <$target_pairs> file.\n";
		
		# select the word pairs with target word and write to a temp file
		# keep the count of number of such target word-pairs selected
		
		# extract the total number of features from the cocs file
		# usually the first number in the file.
		$total_feat = 0;
		do
		{
		    $sent = <INP>;
		    if($sent =~ m/^\s*(\d+)\s*$/)
		    {
			$total_feat = $1;
		    }
		} until($total_feat != 0);
		# write the total number of features on the first line of the output file
		print OUT "$total_feat\n";
		
		while(<INP>)
		{
		    # find and write out the target co-occurrences to the output file
		    if(m/<head>.+<\/head>/i)
		    {
			print OUT;
		    }
		}
		close INP;
		close OUT;
		
		$pairs=$target_pairs;
	    }
	    
	}
	else
	{
	    $pairs=$bigrams;
	}

	######################
	# Running Statistic
	######################

	if(defined $opt_stat)
	{
		if(defined $opt_verbose)
		{
			print STDERR "Performing Statistics on Word Pairs ...\n";
		}

		$statistic="$prefix.statistic";

		$stat_string="";
		if(defined $opt_stat_rank)
		{
			$stat_string.="--rank $opt_stat_rank ";
		}
		if(defined $opt_stat_score)
		{
			$stat_string.="--score $opt_stat_score ";
		}

        # included statistic.pl's --precision option if format option specified
		$stat_string .= " --precision $prec ";

		$stat_string.="$opt_stat ";

		$status=system("statistic.pl $stat_string $statistic $pairs");
		die "Error while running statistic.pl on <$pairs>\n" unless $status ==0;

		$scores=$statistic;
	}
	else
	{
		$scores=$pairs;
	}
}

#############################
# Creating Context Vectors
#############################

$vectors="$prefix.vectors";

# -------------------------
# defining context scope
# -------------------------

if(defined $opt_scope_test)
{
    if(defined $opt_verbose)
    {
	print STDERR "Localizing the Context Scope in TEST ...\n";
    }
    
    $test_context="$prefix.test_context";
    if(defined $opt_target)
    {
        $status=system("windower.pl --token $token --target $target $testfile $opt_scope_test > $test_context");
        die "Error while running windower.pl on <$testfile>\n" unless $status==0;
    }
    else
    {
        $status=system("windower.pl --token $token $testfile $opt_scope_test > $test_context");
        die "Error while running windower.pl on <$testfile>\n" unless $status==0;
    }
}
else
{
       $test_context=$testfile;
}

$rlabel="$prefix.rlabel";
if(defined $opt_eval)
{
       $rclass="$prefix.rclass";
       $rclass_string="--rclass $rclass";
}
else
{
        $rclass_string="";
}
$clabel="$prefix.clabel";

# turned ON if svd defined and actually applied
my $svd_flag = 0;

# default context representation is order2
if(!defined $opt_context || $opt_context =~/o2|order2/)
{
	
	# do not rename any feature file to .features file yet, since
	# wordvec.pl produces a new .features file
	# just decide for now which is the features file
	if ($opt_feature =~ /^uni(gram)?/) {
		$featuresfile = $unigrams;                
	} else {
		$featuresfile = $scores;
	}
	# check if atleast 10 feature present in the features file.
	open(FEAT,$featuresfile) || die "Error($0):
    Error(code=$!) while opening the feature file <$featuresfile>\n";

	# read the complete file in single instruction instead of reading line by line.
	my $temp_delimiter = $/;
	$/ = undef;
	
	my $inp_str = <FEAT>;
	
	$/ = $temp_delimiter;
	close FEAT;
	
	my $feat_cnt = 0;
	while($inp_str =~ m/<>.*\n/g && $feat_cnt < 10)
	{
		$feat_cnt++;
	}

	if($feat_cnt < 10)
	{
		print STDERR "ERROR($0):
	Only $feat_cnt FEATURES found in the <$scores> file. 
	At least 10 FEATURES required to proceed with context 
	representation.\n";
		exit 1;
	}

	if (defined $opt_lsa) {
		# we will get feature vectors from a feature-by-context matrix
		# the extension is maintained to be .wordvec to be
		# consistent with the web interface interpretation as of now
		$featvec="$prefix.wordvec";
		$features = "$prefix.features";
		# move the appropriate feature output file as the .features file
		if ($opt_feature =~ /^uni(gram)?/) {
			$status = system("mv $unigrams $features");
			die "Error while moving <$unigrams> file to <$features>\n" unless $status==0;
		} else {
			$status = system("mv $scores $features");
			die "Error while moving <$scores> file to <$features>\n" unless $status==0;
		}

		# -----------------------
		# finding feature regexs
		# -----------------------

		if(defined $opt_verbose)
		{
			print STDERR "Finding Feature Regex/s ...\n";
		}

		$feature_regex="$prefix.regex";
		$status=system("nsp2regex.pl $features > $feature_regex");
		die "Error while running nsp2regex.pl on <$features>\n" unless $status==0;

		if(defined $opt_verbose)
		{
			print STDERR "Building First Order Vectors for LSA...\n";
		}

		# we are doing context clustering in lsa fashion
		# binary requested
		if(defined $opt_binary)
		{
			$binary="--binary";
		}
		else
		{
			$binary="";
		}

		$o1_presvd="$prefix.o1_presvd";
		# do not generate the .rclass file and the .rlabel / .clabel files
		# generate the .testregex file which corresponds to the features
		# identified in the test data, this needs to be passed to
		# order2vec.pl later
		# Also specify --transpose option, for getting a feature-by-context
		# representation
		$testregex = "$prefix.testregex";

		$status=system("order1vec.pl --transpose --testregex $testregex $binary $test_context $feature_regex > $o1_presvd");
		die "Error while running order1vec.pl on <$test_context>\n" unless $status==0;

		# the keyfile produced by order1vec.pl should be removed, since later 
		# order2vec.pl will create another one
		unlink <keyfile*.key>;
	
	 	# set input file for svd
		$svdinput = $o1_presvd;
		# set an output file name for svd
		$postsvdvectors = $featvec;
		  
	} else {
		# we are doing either context clustering or word clustering in SC fashion

		if(defined $opt_verbose)
		{
			print STDERR "Building Word Vectors ...\n";
		}

		$wordvec="$prefix.wordvec";
		# creating word vectors from scores file
		$wordvec_presvd="$prefix.wordvec_presvd";
		$features = "$prefix.features";
		$dims="$prefix.dims";

		$wordvec_string="--feats $features --dims $dims ";
		if($opt_feature=~/^co(occur|c)?|tco(occur|c)?/)
		{
			$wordvec_string.="--wordorder nocare ";
		}
		else
		{
			$wordvec_string.="--wordorder follow ";
		}
		if(defined $opt_binary)
		{
			$wordvec_string.="--binary ";
		}
		$status=system("wordvec.pl --format $format $wordvec_string $scores > $wordvec_presvd");
		die "ERROR($0): Error while running wordvec.pl\n" unless $status==0;

	 	# set input file for svd
		$svdinput = $wordvec_presvd;
		# set an output file name for svd
		$postsvdvectors = $wordvec;
	}

	# SVD
	if(defined $opt_svd)
	{
		# Check if performing svd will reduce the number of features i.e. number of columns
		# less than or equal to 10, if so do not perform svd

		open(INSVD,$svdinput) || die "Error($0):
		Error(code=$!) in opening Matrix file <$svdinput>\n";

		# line1 in Matrix file should either show the
		# <keyfile> tag or #rows #cols #nnz
		$line1=<INSVD>;

		if($line1=~/keyfile/)
		{
		    $line1=<IN>;
		}

		if($line1=~/^\s*(\d+)\s+(\d+)\s+(\d+)\s*$/)
		{
		    $rows=$1;
		    $cols=$2;
		    $nnz1=$3;
		}
		else
		{
		    print STDERR "ERROR($0):
	Line $line1 in Matrix file <$svdinput> should show #rows #cols #nnz\n";
		    exit 1;
		}
		
		close INSVD;

		$flag_svd = 0;
		$maxprs=$opt_k > ($cols/$opt_rf) ? int($cols/$opt_rf) : $opt_k;
		if($maxprs >= 10)
		{    
		    if(defined $opt_verbose)
		    {
			print STDERR "Performing SVD ...\n";
		    }
		    $svd_flag = 1;
		    # calling svd(input,output)
		    svd($svdinput, $postsvdvectors);
		    $flag_svd = 1;
		}
		else
		{
		    print STDERR "WARNING($0):
	SVD could not be performed on SVDINPUT <$svdinput> 
	because svd with reduction factor = $opt_k and scaling 
	factor = $opt_rf would reduce the resultant number of 
	features to = $maxprs, computed via (min($opt_k, $cols/$opt_rf)). 
	The minimum number of features required for representing 
	the contexts is 10\n";

		    $status=system("mv $svdinput $postsvdvectors");
		    die "Error while creating <$postsvdvectors> file.\n" unless $status==0;
		}
	}
	else
	{
		$status=system("mv $svdinput $postsvdvectors");
		die "Error while creating <$postsvdvectors> file.\n" unless $status==0;
	}

# If word clustering (synonym finding) do not create context vectors but
# instead pass the word vectors to the clustering stage.

	if(defined $opt_wordclust)
	{
		$status=system("mv $wordvec $vectors");
		die "Error while creating <$vectors> file.\n" unless $status==0;

		$status=system("mv $features $rlabel");
		die "Error while creating <$rlabel> file.\n" unless $status==0;
    		
		$status=system("mv $dims $clabel");
		die "Error while creating <$clabel>\n" unless $status==0;
	}
	else
	{	
		# --------------------------
		# Creating Context Vectors
		# --------------------------

		if (!defined $opt_lsa) {
			# only in native SC order2 context clustering mode, generate
			# a regex file from the output of wordvec.pl. we don't do
			# this immediately after calling wordvec.pl above as that
			# will be unnecessarily created in SC word clustering mode
			
			# generate a .testregex file from the $features file created by
			# wordvec.pl
			$testregex = "$prefix.testregex";
			$status=system("nsp2regex.pl $features > $testregex");
			die "Error while running nsp2regex.pl on <$features>\n" unless $status==0;
		}

		if(defined $opt_verbose)
		{
		    print STDERR "Building 2nd Order Context Vectors ...\n";
		}
		$context_string="--rlabel $rlabel ";
		if(defined $opt_svd && $flag_svd == 1)
		{
		    $context_string.="--dense ";
		}
		if(defined $opt_binary)
		{
		    $context_string.="--binary ";
		}
		$status=system("order2vec.pl --format $format $context_string $rclass_string $test_context $postsvdvectors $testregex > $vectors");
		die "Error while running order2vec.pl on <$test_context>\n" unless $status==0;
	}
}
# requested context type is order1
else
{
	$features="$prefix.features";
	if($opt_feature=~/^uni(gram)?/)
	{
		$status=system("mv $unigrams $features");
        	die "Error while creating Unigram Feature file <$features>\n" unless $status==0;
	}
	else
	{
		$status=system("mv $scores $features");
		die "Error while creating Bigram Feature file <$features>\n" unless $status==0;
	}
#	else # target co-occurrences
#	{
#		if(defined $opt_verbose)
#        {
#            print STDERR "Finding Target Co-occurrences ...\n";
#        }
#		# run kocos to find co-occurrences from scores file
#		$status=system("kocos.pl --order 1 --regex $target $scores > $features");
#		die "Error while running kocos.pl on $scores.\n" unless $status==0;
#	}

# check if atleast 10 feature present in the features file.
	open(FEAT,$features) || die "Error($0):
    Error(code=$!) while opening the feature file <$features>\n";

	# read the complete file in single instruction instead of reading line by line.
	my $temp_delimiter = $/;
	$/ = undef;
	
	my $inp_str = <FEAT>;
	
	$/ = $temp_delimiter;
	close FEAT;
	
	my $feat_cnt = 0;
	while($inp_str =~ m/<>.*\n/g && $feat_cnt < 10)
	{
		$feat_cnt++;
	}

	if($feat_cnt < 10)
	{
		print STDERR "ERROR($0):
	Only $feat_cnt FEATURES found in the <$scores> file. 
	At least 10 FEATURES required to proceed with context 
	representation.\n";
		exit 1;
	}

	# -----------------------
	# finding feature regexs
	# -----------------------

	if(defined $opt_verbose)
	{
		print STDERR "Finding Feature Regex/s ...\n";
	}

	$feature_regex="$prefix.regex";
	$status=system("nsp2regex.pl $features > $feature_regex");
	die "Error while running nsp2regex.pl on <$features>\n" unless $status==0;

	# -------------------------
	# creating context vectors
	# -------------------------

	if(defined $opt_verbose)
	{
		print STDERR "Building 1st Order Context Vectors ...\n";
	}

	# binary requested
	if(defined $opt_binary)
	{
		$binary="--binary";
	}
	else
	{
		$binary="";
	}

	$o1_presvd="$prefix.o1_presvd";

	if (defined $opt_lsa) {
		# do not create .rclass file and .clabel file in word / feature
		# clustering
		# create the .rlabel file and specify --transpose option to get
		# feature-by-context output
		# MJ - 06/30/2006
		# we also need to specify --testregex option with --transpose, 
		# although we don't use it in LSA feature clustering.
		$testregex = "$prefix.testregex";
		$status=system("order1vec.pl --transpose --testregex $testregex --rlabel $rlabel $binary $test_context $feature_regex > $o1_presvd");
	} else {
		# print STDERR "order1vec.pl $binary --rlabel $rlabel $rclass_string --clabel $clabel $test_context $feature_regex > $o1_presvd\n";
		$status=system("order1vec.pl $binary --rlabel $rlabel $rclass_string --clabel $clabel $test_context $feature_regex > $o1_presvd");
	}
	die "ERROR ($0):
		Error (code=$!) while running order1vec.pl on <$test_context>\n" unless $status==0;

	$svdinput = $o1_presvd;

	# SVD
	if(defined $opt_svd)
	{
        # Check if performing svd will reduce the number of features i.e. number of columns
        # less than or equal to 10, if so do not perform svd
        open(INSVD,$svdinput) || die "Error($0):
        Error(code=$!) in opening Matrix file <$svdinput>\n";

        # line1 in Matrix file should either show the
        # <keyfile> tag or #rows #cols #nnz
        $line1=<INSVD>;

        if($line1=~/keyfile/)
        {
            $line1=<IN>;
        }

        if($line1=~/^\s*(\d+)\s+(\d+)\s+(\d+)\s*$/)
        {
            $rows=$1;
            $cols=$2;
            $nnz1=$3;
        }
        else
        {
            print STDERR "ERROR($0):
	Line $line1 in Matrix file <$svdinput> should show #rows #cols #nnz\n";
            exit 1;
        }
        
        close INSVD;

        $maxprs=$opt_k > ($cols/$opt_rf) ? int($cols/$opt_rf) : $opt_k;
        if($maxprs >= 10)
        {    
            if(defined $opt_verbose)
            {
                print STDERR "Performing SVD ...\n";
            }
            $svd_flag = 1;
            # calling svd function
            svd($svdinput,$vectors);
        }
        else
        {
            print STDERR "WARNING($0):
	SVD could not be performed on SVDINPUT <$svdinput> 
	because svd with reduction factor = $opt_k and scaling 
	factor = $opt_rf would reduce the resultant number of 
	features to = $maxprs, computed via (min($opt_k, $cols/$opt_rf)). 
	The minimum number of features required for representing 
	the contexts is 10\n";

            $status=system("mv $svdinput $vectors");
            die "Error while creating file <$vectors>\n" unless $status==0;
        }
    }
	else
	{
		$status=system("mv $svdinput $vectors");
		die "Error while creating file <$vectors>\n" unless $status==0;
	}
}

##############
# Clustering
##############

# cluster stopping param string
$cluststop_str = "";

# params common to both vcluster and scluster
$cluster_str ="--rlabelfile $rlabel ";
if(defined $opt_clmethod)
{
	$cluster_str .="--clmethod $opt_clmethod ";

	if($opt_clmethod =~ /^(rb|rbr|direct|agglo|bagglo)$/i)
	{
		$cluststop_str .="--clmethod $opt_clmethod "; 
	}
	else
	{
		$cluststop_str .="--clmethod rb "; 
	}
}
if(defined $opt_crfun)
{
	$cluster_str .="--crfun $opt_crfun ";

	if($opt_crfun =~ /^(i1|i2|h1|h2|e1)$/i)
	{
		$cluststop_str .="--crfun $opt_crfun ";
	}
	else
	{
		$cluststop_str .="--crfun i2 ";
	}
}

# cluster in vector space
if(!defined $opt_space || $opt_space =~/^vector$/)
{
	if(defined $opt_verbose)
	{
		print STDERR "Clustering in Vector Space ...\n";
	}
  
	# build the string of params for vcluster
	$vclus_str = $cluster_str;

	if(defined $opt_sim)
	{
		$vclus_str .= "--sim $opt_sim ";

		if($opt_sim =~ /^(cos|corr)$/i)
		{
			$cluststop_str .= "--sim $opt_sim ";
		}
		else
		{
			$cluststop_str .= "--sim cos ";
		}

		if($opt_sim =~ /^co/)
		{
			$vclus_str .="--showfeatures ";
		}
	}

	$clabel_str = "";
	if (-f $clabel) {
		$clabel_str = "--clabel $clabel";
	}
	$vclus_str .="--nfeatures 10 $clabel_str ";

	# row scaling option
	if(defined $opt_rowmodel)
	{
		$vclus_str .= "--rowmodel $opt_rowmodel ";
		$cluststop_str .= "--rowmodel $opt_rowmodel ";
	}
	else
	{
		$vclus_str .= "--rowmodel none ";
		$cluststop_str .= "--rowmodel none ";
	}

	# column scaling option
	if(defined $opt_colmodel)
	{
		$vclus_str .= "--colmodel $opt_colmodel ";
		$cluststop_str .= "--colmodel $opt_colmodel ";
	}
	else
	{
		$vclus_str .= "--colmodel none ";
		$cluststop_str .= "--colmodel none ";
	}

	# cluster stopping
	if(defined $opt_cluststop)
	{
		$cluststop = $opt_cluststop;

		if(defined $opt_verbose)
		{
			print STDERR "Finding Number of Clusters with Cluster Stopping...\n";
		}

		if(defined $opt_threspk1)
		{
			$cluststop_str .= "--threspk1 $opt_threspk1 ";
		}
		
		if(defined $opt_delta)
		{
			$cluststop_str .= "--delta $opt_delta ";
		}
		if(defined $opt_B)
		{
			$cluststop_str .= "--B $opt_B ";
		}
		if(defined $opt_typeref)
		{
			$cluststop_str .= "--typeref $opt_typeref ";
		}
		if(defined $opt_percentage)
		{
			$cluststop_str .= "--percentage $opt_percentage ";
		}
		if(defined $opt_seed)
		{
			$cluststop_str .= "--seed $opt_seed ";
		}

		$cluststop_str .= "--space vector --measure $opt_cluststop --precision $prec ";
		
		$status = system("clusterstopping.pl --prefix $prefix $cluststop_str $vectors >& $prefix.predictions");
		# error handling for clusterstopping.pl
		if ($status != 0) 
		{
		    my $tmp = uc $opt_cluststop;

			# if predictions file not created fall-back to using the default #clusters
			if(!-e "$prefix.predictions")
			{
				print STDERR "WARNING($0):
	Could not locate the PREDICTIONS <$prefix.predictions> 
	file which indicates that the cluster-stopping measure 
	$tmp failed to predict the optimal number of clusters 
	for the VECTORS <$vectors> file. 
	Proceeding with the default number of clusters of $default_clusters\n\n";

				# default number of clusters
				$opt_clusters = $default_clusters;
			}
			else
			{
				# if predictions file exists then print out the error message present in the file 
				# and fall-back to using the default #clusters
				open (TFP,"$prefix.predictions");
				$errstr = "";
				while(<TFP>)
				{
					$errstr .= $_;
				}
				print STDERR "WARNING($0):
		$errstr
	The cluster-stopping measure $tmp failed to predict the
	optimal number of clusters for <$vectors>
	Proceeding with the default number of clusters of $default_clusters\n\n";
				
				# default #clusters
				$opt_clusters = $default_clusters;
			}

			# undefine cluster-stopping option to indicate that the #clusters being used is not 
			# predicted by the measures but is set manually to the default value.
			$opt_cluststop = undef;

			# proceed with the default #clusters
			$num_k = 0;
			$predict[$num_k] = $opt_clusters;
			
			$cluster_solution ="$prefix.cluster_solution";
			$cluster_output ="$prefix.cluster_output";		
			$vclus_str .="--clustfile $cluster_solution ";
			
			# running vcluster
		    	# use the -showtree option only if the #clusters is greater than 1
		    	if($opt_clusters > 1)
			{
			    my $tmp_fig_str =  "--showtree --plotclusters $prefix.dendogram.ps --plotformat ps ";
			    system("vcluster $vclus_str $rclass_string $tmp_fig_str $vectors $opt_clusters > $cluster_output");			
			}
		    	else
			{
			    system("vcluster $vclus_str $rclass_string $vectors $opt_clusters > $cluster_output");			
			}
		}
		else # If clusterstopping.pl ran successfully.
		{
			open (TFP,"$prefix.predictions") || die "Error($0):
        Error(code=$!) in opening <$prefix.predictions> file.\n";
			
			$num_k = 0;
			while(<TFP>)
			{
				chomp;
				$predict[$num_k++] = $_;
			}
			$num_k--;
			close TFP;
			
			$i = 0;
			while($i <= $num_k)
			{
				$opt_clusters = $predict[$i];
				
				if($cluststop ne "all" && $cluststop ne "pk")
				{
					$cluster_solution ="$prefix.cluster_solution.$cluststop";
					$cluster_output ="$prefix.cluster_output.$cluststop";
					$dendo_file = "$prefix.$cluststop.dendogram.ps";
				}
				else
				{
					if($i == 0)
					{
						$cluster_solution ="$prefix.cluster_solution.pk1";
						$cluster_output ="$prefix.cluster_output.pk1";
						$dendo_file = "$prefix.pk1.dendogram.ps";
					}
					elsif($i == 1)
					{
						$cluster_solution ="$prefix.cluster_solution.pk2";
						$cluster_output ="$prefix.cluster_output.pk2";
						$dendo_file = "$prefix.pk2.dendogram.ps";
					}
					elsif($i == 2)
					{
						$cluster_solution ="$prefix.cluster_solution.pk3";
						$cluster_output ="$prefix.cluster_output.pk3";
						$dendo_file = "$prefix.pk3.dendogram.ps";
					}
					elsif($i == 3)
					{
						$cluster_solution ="$prefix.cluster_solution.gap";
						$cluster_output ="$prefix.cluster_output.gap";
						$dendo_file = "$prefix.gap.dendogram.ps";
					}
				}
				
				$update_str ="--clustfile $cluster_solution ";
				
				# running vcluster
				# use the -showtree option only if the #clusters is greater than 1
				if($opt_clusters > 1)
				{			
				    my $tmp_fig_str =  "--showtree --plotclusters $dendo_file --plotformat ps ";
				    system("vcluster $vclus_str $update_str $rclass_string $tmp_fig_str $vectors $opt_clusters > $cluster_output");
				}
				else
				{
				    system("vcluster $vclus_str $update_str $rclass_string $vectors $opt_clusters > $cluster_output");
				}

				$i++;
			}
		}
	}
	else # if not using cluster stopping measures
	{
		$num_k = 0;
		$predict[$num_k] = $opt_clusters;

		$cluster_solution ="$prefix.cluster_solution";
		$cluster_output ="$prefix.cluster_output";		
		$vclus_str .="--clustfile $cluster_solution ";

		# running vcluster
		# use the -showtree option only if the #clusters is greater than 1
		if($opt_clusters > 1)
		{	    
		    my $tmp_fig_str =  "--showtree --plotclusters $prefix.dendogram.ps --plotformat ps ";	    
		    system("vcluster $vclus_str $rclass_string $tmp_fig_str $vectors $opt_clusters > $cluster_output");
		}
		else
		{
		    system("vcluster $vclus_str $rclass_string $vectors $opt_clusters > $cluster_output");
		}
	}
}
else # cluster in similarity space
{
	if(defined $opt_verbose)
	{
		print STDERR "Building Similarity Matrix ...\n";
	}

	# creating similarity matrix
	$simat="$prefix.simat";
	
    my $simat_string = " ";

	if(defined $opt_svd && $svd_flag == 1)
	{
		$simat_string ="--dense ";
	}

	if(defined $opt_binary)
	{
		if(defined $opt_sim)
		{
			$simat_string .="--measure $opt_sim ";
		}
		$sim_program ="bitsimat.pl";
	}
	else
	{
		$sim_program ="simat.pl";
	}

	$status=system("$sim_program --format $format $simat_string $vectors > $simat");
	die "Error while running $sim_program\n" unless $status==0;

	if(defined $opt_verbose)
	{
		print STDERR "Clustering in Similarity Space ...\n";
	}

	# build the string of params for scluster
	$sclus_str = $cluster_str;

	# cluster stopping
	if(defined $opt_cluststop)
	{
		$cluststop = $opt_cluststop;

		if(defined $opt_verbose)
		{
			print STDERR "Finding Number of Clusters with Cluster Stopping...\n";
		}

		if(defined $opt_threspk1)
		{
			$cluststop_str .= "--threspk1 $opt_threspk1 ";
		}
		
		if(defined $opt_delta)
		{
			$cluststop_str .= "--delta $opt_delta ";
		}
		if(defined $opt_B)
		{
			$cluststop_str .= "--B $opt_B ";
		}
		if(defined $opt_typeref)
		{
			$cluststop_str .= "--typeref $opt_typeref ";
		}
		if(defined $opt_percentage)
		{
			$cluststop_str .= "--percentage $opt_percentage ";
		}
		if(defined $opt_seed)
		{
			$cluststop_str .= "--seed $opt_seed ";
		}
		
		$cluststop_str .= "--space similarity --measure $opt_cluststop --precision $prec ";
		
		$status = system("clusterstopping.pl --prefix $prefix $cluststop_str $simat >& $prefix.predictions");
		# error handling for clusterstopping.pl
		# If clusterstopping.pl returned an error code
		if ($status != 0) 
		{
		    my $tmp = uc $opt_cluststop;

			# if predictions file not created fall-back to using the default #clusters
			if(!-e "$prefix.predictions")
			{
				print STDERR "WARNING($0):
	Could not locate the PREDICTIONS <$prefix.predictions> 
	file which indicates that the cluster-stopping measure 
	$tmp failed to predict the optimal number of clusters 
	for the VECTORS <$vectors> file. 
	Proceeding with the default number of clusters of $default_clusters\n\n";

				# default #clusters
				$opt_clusters = $default_clusters;
			}
			else
			{
				# if predictions file exists then print out the error message present in the file 
				# and fall-back to using the default #clusters
				open (TFP,"$prefix.predictions");
				$errstr = "";
				while(<TFP>)
				{
					$errstr .= $_;
				}
				print STDERR "WARNING($0): 
		$errstr
	The cluster-stopping measure $tmp failed to predict the
	optimal number of clusters for the given data.
	Proceeding with the default number of clusters of $default_clusters\n\n";
				
				# default #clusters
				$opt_clusters = $default_clusters;
			}

			# undefine cluster-stopping option to indicate that the #clusters being used is not 
			# predicted by the measures but is set manually to the default value.
			$opt_cluststop = undef;

			# proceed with the default #clusters
			$num_k = 0;
			$predict[$num_k] = $opt_clusters;
			
			$cluster_solution ="$prefix.cluster_solution";
			$cluster_output ="$prefix.cluster_output";		
			
			$sclus_str .="--clustfile $cluster_solution ";
			
			# running scluster
		    	# use the -showtree option only if the #clusters is greater than 1
		        if($opt_clusters > 1)
			{	    
			    my $tmp_fig_str =  "--showtree --plotsclusters $prefix.dendogram.ps --plotformat ps ";	    
			    system("scluster $sclus_str $rclass_string $tmp_fig_str $simat $opt_clusters > $cluster_output");
			}
		        else
		        {
			    system("scluster $sclus_str $rclass_string $simat $opt_clusters > $cluster_output");
		        }
		    }
		else # If clusterstopping.pl ran successfully.
		{
			open (TFP,"$prefix.predictions") || die "Error($0):
                       Error(code=$!) in opening <$prefix.predictions> file.\n";
			
			$num_k = 0;
			while(<TFP>)
			{
				chomp;
				$predict[$num_k++] = $_;
			}
			$num_k--;
			close TFP;
			
			$i = 0;
			while($i <= $num_k)
			{
				$opt_clusters = $predict[$i];
				
				if($cluststop ne "all" && $cluststop ne "pk")
				{
					$cluster_solution ="$prefix.cluster_solution.$cluststop";
					$cluster_output ="$prefix.cluster_output.$cluststop";
					$dendo_file = "$prefix.$cluststop.dendogram.ps";
				}
				else
				{
					if($i == 0)
					{
						$cluster_solution ="$prefix.cluster_solution.pk1";
						$cluster_output ="$prefix.cluster_output.pk1";
						$dendo_file = "$prefix.pk1.dendogram.ps";
					}
					elsif($i == 1)
					{
						$cluster_solution ="$prefix.cluster_solution.pk2";
						$cluster_output ="$prefix.cluster_output.pk2";
						$dendo_file = "$prefix.pk2.dendogram.ps";
					}
					elsif($i == 2)
					{
						$cluster_solution ="$prefix.cluster_solution.pk3";
						$cluster_output ="$prefix.cluster_output.pk3";
						$dendo_file = "$prefix.pk3.dendogram.ps";
					}
					elsif($i == 3)
					{
						$cluster_solution ="$prefix.cluster_solution.gap";
						$cluster_output ="$prefix.cluster_output.gap";
						$dendo_file = "$prefix.gap.dendogram.ps";
					}
				}
				
				$update_str ="--clustfile $cluster_solution ";
				
				# running scluster
				# use the -showtree option only if the #clusters is greater than 1
				if($opt_clusters > 1)
				{	  
				    my $tmp_fig_str =  "--showtree --plotsclusters $dendo_file --plotformat ps ";	    
				    system("scluster $sclus_str $update_str $rclass_string $tmp_fig_str $simat $opt_clusters > $cluster_output");
				}
				else
				{				    
				    system("scluster $sclus_str $update_str $rclass_string $simat $opt_clusters > $cluster_output");
				}
				$i++;
			}
		}
	}
	else # if not using cluster stopping measures
	{
		$num_k = 0;
		$predict[$num_k] = $opt_clusters;

		$cluster_solution ="$prefix.cluster_solution";
		$cluster_output ="$prefix.cluster_output";		

		$sclus_str .="--clustfile $cluster_solution ";

		# running scluster
		# use the -showtree option only if the #clusters is greater than 1
		if($opt_clusters > 1)
		{	  
		    my $tmp_fig_str =  "--showtree --plotsclusters $prefix.dendogram.ps --plotformat ps ";	    
		    system("scluster $sclus_str $rclass_string $tmp_fig_str $simat $opt_clusters > $cluster_output");
		}
		else
		{
		    system("scluster $sclus_str $rclass_string $simat $opt_clusters > $cluster_output");
		}
	}
}

#*********************

# formatting clustering solution, show instances in each cluster
$i = 0;
while($i <= $num_k)
{
	if(defined $opt_cluststop)
	{
		if($cluststop ne "all" && $cluststop ne "pk")
		{
			$clusters="$prefix.clusters.$cluststop";
			$cluster_solution = "$prefix.cluster_solution.$cluststop";
			$clusters_context = "$prefix.clusters_context.$cluststop";
		}
		else
		{
			if($i == 0)
			{
				$clusters="$prefix.clusters.pk1";
				$cluster_solution = "$prefix.cluster_solution.pk1";
				$clusters_context = "$prefix.clusters_context.pk1";
			}
			elsif($i == 1)
			{
				$clusters="$prefix.clusters.pk2";
				$cluster_solution = "$prefix.cluster_solution.pk2";
				$clusters_context = "$prefix.clusters_context.pk2";
			}
			elsif($i == 2)
			{
				$clusters="$prefix.clusters.pk3";
				$cluster_solution = "$prefix.cluster_solution.pk3";
				$clusters_context = "$prefix.clusters_context.pk3";
			}
			elsif($i == 3)
			{
				$clusters="$prefix.clusters.gap";
				$cluster_solution = "$prefix.cluster_solution.gap";
				$clusters_context = "$prefix.clusters_context.gap";
			}
		}
	}
	else # No. of Clusters: Set Manually
	{
		$clusters="$prefix.clusters";
		$cluster_solution = "$prefix.cluster_solution";
		$clusters_context = "$prefix.clusters_context";
	}

	if(defined $opt_wordclust)
	{
		$status=system("format_clusters.pl $cluster_solution $rlabel > $clusters");
		die "Error while formatting clusters.\n" unless $status==0;
	}
	else
	{
		$status=system("format_clusters.pl $cluster_solution $rlabel --senseval2 $testfile > $clusters");
		die "Error while formatting clusters.\n" unless $status==0;

		# execute the format_clusters.pl with --context option and use this file to label the clusters.
		$status=system("format_clusters.pl $cluster_solution $rlabel --context $testfile > $clusters_context");
		die "Error while running format_clusters.pl $cluster_solution $rlabel --context $testfile > $clusters_context\n" unless $status==0;
	}

	$i++;
}

if(!defined $opt_wordclust)
{

	# create the parameter string for clusterlabeling.pl
	if(defined $opt_verbose)
	{
		print STDERR "Creating Cluster Labels ...\n";
	}

    $cluslabel_str = " --token $token ";
    
    if(defined $opt_label_window)
    {
        $cluslabel_str .= " --window $opt_label_window "; 
    }
    
    if(defined $opt_label_ngram)
    {    
    	if($opt_label_ngram < 2 || $opt_label_ngram > 4)
		{
        	print STDERR "\n ERROR($0):
        		Labeling mechanism only support bigrams, trigrams and 4-grams for feature selection..\n";
        	exit 1;
		}

        $cluslabel_str .= " --ngram $opt_label_ngram "; 
    }
        
    if(defined $opt_label_stop)
    {
        $cluslabel_str .= " --stop $opt_label_stop "; 
    }
    
    if(defined $opt_label_remove)
    {
        $cluslabel_str .= " --remove $opt_label_remove "; 
    }
    
    if(defined $opt_label_stat)
    {
        $cluslabel_str .= " --stat $opt_label_stat "; 
    }
    
    if(defined $opt_label_rank)
    {
        $cluslabel_str .= " --rank $opt_label_rank "; 
    }

	$i = 0;
	while($i <= $num_k)
	{
		if(defined $opt_cluststop)
		{
			if($cluststop ne "all" && $cluststop ne "pk")
			{
				$clusters_context = "$prefix.clusters_context.$cluststop";
				$cluster_labels = "$prefix.cluster_labels.$cluststop";
				$param_str = $cluslabel_str . "--prefix $prefix.$cluststop ";
			}
			else
			{
				if($i == 0)
				{
					$clusters_context = "$prefix.clusters_context.pk1";
					$cluster_labels = "$prefix.cluster_labels.pk1";
					$param_str = $cluslabel_str . "--prefix $prefix.pk1 ";
				}
				elsif($i == 1)
				{
					$clusters_context = "$prefix.clusters_context.pk2";
					$cluster_labels = "$prefix.cluster_labels.pk2";
					$param_str = $cluslabel_str . "--prefix $prefix.pk2 ";
				}
				elsif($i == 2)
				{
					$clusters_context = "$prefix.clusters_context.pk3";
					$cluster_labels = "$prefix.cluster_labels.pk3";
					$param_str = $cluslabel_str . "--prefix $prefix.pk3 ";
				}
				elsif($i == 3)
				{
					$clusters_context = "$prefix.clusters_context.gap";
					$cluster_labels = "$prefix.cluster_labels.gap";
					$param_str = $cluslabel_str . "--prefix $prefix.gap ";
				}
			}
		}
		else # No. of Clusters: Set Manually
		{
			$clusters_context = "$prefix.clusters_context";
			$cluster_labels = "$prefix.cluster_labels";
			$param_str = $cluslabel_str . "--prefix $prefix ";
		}

		# execute the cluster labeling program
		$status=system("clusterlabeling.pl $param_str $clusters_context > $cluster_labels");
		die "Error while running clusterlabeling.pl $param_str $clusters_context > $cluster_labels\n" unless $status==0;

		$i++;
	}
}

################
# Evaluation
################

if(defined $opt_eval)
{
	if(defined $opt_verbose)
	{
		print STDERR "Evaluating ...\n";
	}

	$i = 0;
	while($i <= $num_k)
	{
		if(defined $opt_cluststop)
		{
			if($cluststop ne "all" && $cluststop ne "pk")
			{
				$prelabel="$prefix.prelabel.$cluststop";
				$label="$prefix.label.$cluststop";
				$report="$prefix.report.$cluststop";
				$cluster_solution ="$prefix.cluster_solution.$cluststop";
			}
			else
			{
				if($i == 0)
				{
					$prelabel="$prefix.prelabel.pk1";
					$label="$prefix.label.pk1";
					$report="$prefix.report.pk1";
					$cluster_solution ="$prefix.cluster_solution.pk1";
				}
				elsif($i == 1)
				{
					$prelabel="$prefix.prelabel.pk2";
					$label="$prefix.label.pk2";
					$report="$prefix.report.pk2";
					$cluster_solution ="$prefix.cluster_solution.pk2";
				}
				elsif($i == 2)
				{
					$prelabel="$prefix.prelabel.pk3";
					$label="$prefix.label.pk3";
					$report="$prefix.report.pk3";
					$cluster_solution ="$prefix.cluster_solution.pk3";
				}
				elsif($i == 3)
				{
					$prelabel="$prefix.prelabel.gap";
					$label="$prefix.label.gap";
					$report="$prefix.report.gap";
					$cluster_solution ="$prefix.cluster_solution.gap";
				}
			}
		}
		else # No. of Clusters: Set Manually
		{
			$prelabel="$prefix.prelabel";
			$label="$prefix.label";
			$report="$prefix.report";
			$cluster_solution ="$prefix.cluster_solution";
		}

		$status=system("cluto2label.pl $cluster_solution keyfile*.key > $prelabel");
		die "Error while running cluto2label.pl\n" unless $status==0;

		$status=system("label.pl $prelabel > $label");
		die "Error while running label.pl\n" unless $status==0;

		$status=system("report.pl $label $prelabel > $report");
		die "Error while running report.pl\n" unless $status==0;

		$i++;
	}

	$status=system("mv keyfile*.key $prefix.key");
	die "Error while creating the KEY file.\n" unless $status==0;
}

##################
# Printing Output
##################

if(defined $opt_cluststop)
{
	if($opt_cluststop eq "all")
	{
		$predict_measure[0] = "PK1 measure";
		$predict_measure[1] = "PK2 measure";		
		$predict_measure[2] = "PK3 measure";
		$predict_measure[3] = "Adapted Gap Statistic";
	}
	elsif($opt_cluststop eq "pk")
	{
		$predict_measure[0] = "PK1 measure";
		$predict_measure[1] = "PK2 measure";		
		$predict_measure[2] = "PK3 measure";
	}
	else
	{
		$predict_measure[0] = uc $opt_cluststop;
		$predict_measure[0] .= " measure";	
	}
}
else
{
	$predict_measure[0] = "Set manually";
}

$i = 0;
while($i <= $num_k)
{	
	print "\n=================================================================\n";		
	print "Output when #clusters = $predict[$i] ($predict_measure[$i])\n";
	print "=================================================================\n";	

	if(defined $opt_cluststop)
	{
		if($cluststop ne "all" && $cluststop ne "pk")
		{
			$cluster_output ="$prefix.cluster_output.$cluststop";
			$status=system("cat $cluster_output");
			die "Error while displaying the cluster results.\n" unless $status==0;
			
			if(defined $opt_eval)
			{
				$report = "$prefix.report.$cluststop";
				$status=system("cat $report");
				die "Error while displaying the report file.\n" unless $status==0;
			}
			
			$clusters="$prefix.clusters.$cluststop";
			print "\nClusters of given contexts can be found in file: <$clusters>\n\n";
		}
		else
		{
			if($i == 0)
			{
				$cluster_output ="$prefix.cluster_output.pk1";
				$status=system("cat $cluster_output");
				die "Error while displaying the cluster results.\n" unless $status==0;
				
				if(defined $opt_eval)
				{
					$report = "$prefix.report.pk1";
					$status=system("cat $report");
					die "Error while displaying the report file.\n" unless $status==0;
				}
				
				$clusters="$prefix.clusters.pk1";
				print "\nClusters of given contexts can be found in file: $clusters\n\n";
			}
			elsif($i == 1)
			{
				$cluster_output ="$prefix.cluster_output.pk2";
				$status=system("cat $cluster_output");
				die "Error while displaying the cluster results.\n" unless $status==0;
				
				if(defined $opt_eval)
				{
					$report = "$prefix.report.pk2";
					$status=system("cat $report");
					die "Error while displaying the report file.\n" unless $status==0;
				}
				
				$clusters="$prefix.clusters.pk2";
				print "\nClusters of given contexts can be found in file: $clusters\n\n";
			}
			elsif($i == 2)
			{
				$cluster_output ="$prefix.cluster_output.pk3";
				$status=system("cat $cluster_output");
				die "Error while displaying the cluster results.\n" unless $status==0;
				
				if(defined $opt_eval)
				{
					$report = "$prefix.report.pk3";
					$status=system("cat $report");
					die "Error while displaying the report file.\n" unless $status==0;
				}
				
				$clusters="$prefix.clusters.pk3";
				print "\nClusters of given contexts can be found in file: $clusters\n\n";
			}
			elsif($i == 3)
			{
				$cluster_output ="$prefix.cluster_output.gap";
				$status=system("cat $cluster_output");
				die "Error while displaying the cluster results.\n" unless $status==0;
				
				if(defined $opt_eval)
				{
					$report = "$prefix.report.gap";
					$status=system("cat $report");
					die "Error while displaying the report file.\n" unless $status==0;
				}
				
				$clusters="$prefix.clusters.gap";
				print "\nClusters of given contexts can be found in file: $clusters\n\n";
			}
		}
	}
	else # No. of Clusters: Set Manually
	{
		$cluster_output ="$prefix.cluster_output";
		$status=system("cat $cluster_output");
		die "Error while displaying the cluster results.\n" unless $status==0;
		
		if(defined $opt_eval)
		{
			$report = "$prefix.report";
			$status=system("cat $report");
			die "Error while displaying the report file.\n" unless $status==0;
		}
		
		$clusters="$prefix.clusters";	
		print "\nClusters of given contexts can be found in file: $clusters\n\n";
	}

	$i++;
}

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

sub svd
{
	($svdin,$svdout)=@_;
	# converting input to harwell-boeing format
	$svd_string="";
        if(defined $opt_k)
        {
                $svd_string="--k $opt_k ";
        }
        if(defined $opt_rf)
        {
                $svd_string.="--rf $opt_rf ";
        }
        if(defined $opt_iter)
        {
                $svd_string.="--iter $opt_iter ";
        }

	    $numform = "5$format";            ## numform is 5f16.XX

        $status=system("mat2harbo.pl --numform $numform --param $svd_string $svdin > matrix");
        die "Error while running mat2harbo.pl on <$svdin>\n" unless $status==0;

        system("las2");

        $harbomat="$prefix.harbomat";
        $status=system("mv matrix $harbomat");

        die "Error in creating <$harbomat>\n" unless $status==0;

        # reconstruction
        $status=system("svdpackout.pl --rowonly --format $format lav2 lao2 > $svdout");
        die "Error while running svdpackout.pl\n" unless $status==0;
}

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: discriminate.pl [OPTIONS] TEST";
        print "\nTYPE discriminate.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  discriminate.pl [OPTIONS] TEST 

Wrapper program for SenseClusters' Toolkit. Discriminates among the 
given text instances based on their contextual similarities.

TEST
	Senseval-2 formatted TEST instance file containing the instances
	to be clustered.

OPTIONS:

--training TRAIN
	Specify the training file in plain text format. Instances from this 
	file are used for selecting features. If --training is not specified, 
	features are selected from the same TEST file.

--split N
	Splits the given TEST file into two portions, N% for the use as the 
	TRAIN data and (100-N)% as the TEST data. The value for N is a 
	percentage and should be an integer between 1 to 99 (inclusive). 
	The instances from the original TEST file are not picked or split 
	in any particular order but are randomly split into the two portions 
	of TRAIN and TEST data while maintaining the ratio of N/(100-N).

	Note: This option cannot be used when --training option is also used. 

--token TOKEN
	Specify a file containing Perl regex/s that define the tokenization
	scheme in TRAIN and TEST files. By default, token.regex is searched
	in the current directory.

--target TARGET
	Specify a file containing Perl regex/s that identify the target word/s
	whose senses are to be discriminated. 

	If --target is not specified, target.regex file is searched in the 
	current directory. If this file doesn't exist, target.regex is 
	automatically created by searching the <head> tags in the TEST data.
	If no <head> tags are found in TEST, TEST is assumed to be global.

	Note: --target cannot be specified with headless input data
		i.e. test file without head/target word(s).

--prefix PRE
	Specify the prefix to be used for output filenames. 

--format f16.XX
	The default format for floating point numbers is f16.06. This means 
	that there is room for 6 digits to the left of the decimal,
	and 9 to the right. You may change XX to any value between 0
	and 15, however, the format must remain 16 spaces long due to
	formatting requirements of SVDPACKC. 

--wordclust

	Discriminates and clusters each word based upon its direct and indirect
	co-occurrence with other words (when used without the --lsa switch) or
	clusters words or features based upon their occurrences in different 
	contexts (when used with the --lsa switch). 

 	Note: 1. Separate (--training) TRAIN data should not be used with word 
		 clustering.
	      2. Starting with Version 0.93, word clustering is no longer 
                 restricted to using only headless data. However, options 
                 specific to headed data such as --scope_test and target 
                 co-occurrence features (see below) cannot be used.

--lsa

	Uses Latent Semantic Analysis (LSA) style representation for clustering
	features or contexts. LSA representation is the transpose of
	the context-by-feature matrix created using the native SenseClusters
	order1 context representation.

	This option can be used only in the following two combinations of 
	the --context and the --wordclust options:

	1. --context o1 --wordclust --lsa

	Performs feature clustering by grouping together features based on the
	contexts that they occur in. Features can be unigrams, bigrams or 
	co-occurrences. Feature vectors are the rows of the transposed
	context-by-feature representation created by order1vec.pl.

	2. --context o2 --lsa

	Performs context clustering by creating context vectors by averaging the
	feature vectors from the transposed context-by-feature representation of 
	order1vec.pl.

Feature Options :

--feature TYPE
	Specify the feature type to be used for representing contexts. 
	Possible options for feature type with first order context 
	representation:

	bi	- 	bigrams  [default]
	tco	-	target co-occurrences	
	co	-	co-occurrences
	uni	- 	unigrams

	Possible options for feature type with second order context 
	representation:

	bi	- 	bigrams  [default]
	co	-	co-occurrences
	tco	-	target co-occurrences

	Note: --tco (target co-occurrences) cannot be used with headless
          data i.e. test/train file without head/target word(s).

--scope_train S1
	Context in TRAIN instances is limited to include only S1 words on the 
	left and right of the TARGET word. Use --scope_train only if every 
	training instance contains the TARGET word.

	Note: --scope_train cannot be used with headless data i.e. train file
          without head/target word(s).

--scope_test S2
	Context in TEST instances is limited to include only S2 words on the
	left and right of the TARGET word. Use --scope_test only if every
	test instance contains the TARGET word.

	Note: --scope_test cannot be used with headless data i.e. test file
          without head/target word(s).

--remove F
	Features occurring less than F number of times are removed from the
        feature set.

--window W
	Sets the window size for bigram and co-occurrence features. Words
	occurring within W positions from each other (i.e. at most W-2 
	intervening words) form bigrams/co-occurrences.

--stop STOPFILE
	Specify a file of Perl regex/s that define a stop list of words to be
	excluded from the features.

--stat Stat
	Performs the specified statistical test of association on bigrams/
	co-occurrences. The test scores can be used to filter insignificant 
	pairs or in the feature vector representations.

        The possible values of STAT are -

                dice            -       Dice Coefficient
                ll              -       Log Likelihood Ratio
                odds            -       Odds Ratio
                phi             -       Phi Coefficient
                pmi             -       Point-Wise Mutual Information
                tmi             -       True Mutual Information
                x2              -       Chi-Squared Test
                tscore          -       T-Score
                leftFisher      -       Left Fisher's Test
                rightFisher     -       Right Fisher's Test

--stat_rank R

	Word pairs ranking below R when arranged in descending order of 
	their test scores are ignored. 

	--stat_rank will be ignored unless --stat option is specified.

--stat_score S
	Specify the score cutoff value to select pairs with test scores 
	greater than S. 

	--stat_score will be ignored unless option --stat is specified.

Vector Options :

--context ORD
	Specify the context representation to be used to represent the TEST 
	instances. Set ORD to 'o1' to use 1st order context vectors and to
	'o2' to use 2nd order context vectors. Default context representation 
	is o2.

--binary
	Creates binary feature and context vectors. By default, the frequency
	scores are retained by these vectors.

SVD Options :

--svd
	Performs Singular Value Decomposition to reduce the feature space
        dimensions.

--k K
	Reduces dimensions of the feature space to K. Default is 300.

--rf RF
	Specifies the reduction factor such that feature space with N
        dimensions is reduced down to N/RF (RF >= 1). Default RF=10.

--iter I
	Specifies the number of SVD iterations. Recommended value is (3 x K)

Cluster-Stopping Options:

--cluststop CS
	Specify the cluster stopping measure to be used to predict the number
	the number of clusters.

	The possible option values:

    	pk1 - Use PK1 measure 
	[PK1[m] = (crfun[m] - mean(crfun[1...deltaM]))/std(crfun[1...deltaM]))]
	pk2 - Use PK2 measure 
	[PK2[m] = (crfun[m]/crfun[m-1])]
    	pk3 - Use PK3 measure 
	[PK3[m] = ((2 * crfun[m])/(crfun[m-1] + crfun[m+1]))]
    	gap - Use Adapted Gap Statistic. 
    	pk  - Use all the PK measures.
    	all - Use all the four cluster stopping measures.
	
	More about these measures can be found in the documentation of 
	Toolkit/clusterstop/clusterstopping.pl

	NOTE: Options --clusters and --cluststop cannot be used together.

--delta INT
	NOTE: Delta value can only be a positive integer value.

	Specify 0 to stop the iterating clustering process when two consecutive 
	crfun values are exactly equal. This is the default setting when the 
	crfun values are integer/whole numbers.

	Specify non-zero positive integer to stop the iterating clustering 
	process when the difference between two consecutive crfun values 
	is less than or equal to this value. However, note that the integer 
	value specified is internally shifted to capture the difference in 
	the least significant digit of the crfun values when these crfun 
	values are fractional.
	 For example: 
	    For crfun = 1.23e-02 & delta = 1 will be transformed to 0.0001
	    For crfun = 2.45e-01 & delta = 5 will be transformed to 0.005
	The default delta value when the crfun values are fractional is 1.

	However if the crfun values are integer/whole numbers (exponent >= 2) 
	then the specified delta value is internally shifted only until the 
	least significant digit in the scientific notation.
	 For example: 
	    For crfun = 1.23e+04 & delta = 2 will be transformed to 200
	    For crfun = 2.45e+02 & delta = 5 will be transformed to 5
	    For crfun = 1.44e+03 & delta = 1 will be transformed to 10

--threspk1 NUM
	The threshold value that should be used by the PK1 measure to predict 
	the k value. 
	Default = -0.7

	NOTE: This option should be used only when --cluststop option is also 
	used with option value of \"all\" or \"pk1\".

Cluster-Stopping: Adapted Gap Statistic Options:

--B NUM
	The number of replicates/references to be generated.
    	Default: 1

--typeref TYP
    	Specifies whether to generate B replicates from a reference or to 
	generate B references.

    	The possible option values:
      	rep - replicates [Default]
      	ref - references

--percentage NUM
    	Specifies the percentage confidence to be reported in the log file.
    	Since Gap Statistic uses parametric bootstrap method for reference 
	distribution generation, it is critical to understand the interval 
	around the sample mean that could contain the population (\"true\") 
	mean and with what certainty.
    	Default: 90

--seed NUM
    	The seed to be used with the random number generator. 
    	Default: No seed is set.

Clustering Options :

--clusters C
	Specify the number of clusters to be created. Default is 2.

--space SPACE
	Specifies whether clustering is to be performed in vector or similarity
        space. Set SPACE to 'vector' to cluster context vectors directly in
        vector space OR to 'similarity' to compose a similarity matrix and
        cluster instances in similarity space. Default SPACE is vector.

--clmethod CL
	Specifies the clustering method.

        Possible option values are :
                rb - Repeated Bisections [Default]
                rbr - Repeated Bisections for by k-way refinement
                direct - Direct k-way clustering
                agglo  - Agglomerative clustering
                graph  - Graph partitioning-based clustering
                bagglo - Partitional biased Agglomerative clustering

--crfun CR
	Selects the criteria function for Clustering. The meanings of these
        criteria functions is explained in Cluto's manual.

        The possible values are :
        i1      -  I1  Criterion function
        i2      -  I2  Criterion function [default for partitional]
        e1      -  E1  Criterion function
        g1      -  G1  Criterion function
        g1p     -  G1' Criterion function
        h1      -  H1  Criterion function
        h2      -  H2  Criterion function
        slink   -  Single link merging scheme
        wslink  -  Single link merging scheme weighted w.r.t. cluster sim
        clink   -  Complete link merging scheme
        wclink  -  Complete link merging scheme weighted w.r.t. cluster sim
        upgma   -  Group average merging scheme [default for agglomerative]

    	Note that for cluster stopping, i1, i2, e1, h1 and h2 criterion 
	functions can only be used. If a crfun other than these is selected 
    	then cluster stopping uses the default crfun (i2) while the final 
    	clustering of contexts is performed using the crfun specified.

--sim SIM
	Specifies the similarity measure to be used during clustering.
        When --space is vector, possible option values of SIM are :

                cos      -  Cosine Coefficient [default]
                corr     -  Correlation Coefficient
                dist     -  Euclidean distance
                jacc     -  Extended Jaccard Coeeficient

        When --space is similarity and --binary is ON,
        possible values of SIM are :

                cos     -  Cosine Coefficient [default]
                mat     -  Match Coefficient
                jac     -  Jaccard Coefficient
                ovr     -  Overlap Coefficient
                dic     -  Dice Coefficient

        Otherwise, only cosine coefficient is available and is default.

--rowmodel RMOD
	The option is used to specify the model to be used to scale every 
	column of each row. (For further details please refer Cluto manual)

	The possible values for RMOD -
		none  -  no scaling is performed (default setting)
		maxtf -  post scaling the values are between 0.5 and 1.0
		sqrt  -  square-root of actual values
		log   -  log of actual values

--colmodel CMOD
	The option is used to specify the model to be used to (globally) 
	scale each column across all rows. (For further details please refer 
	Cluto manual)

	The possible values for CMOD -
		none  -  no scaling is performed (default setting)
		idf   -  scaling according to inverse-document-frequency 

Labeling Options :

	Note: Labeling options cannot be used with word-clustering 
	(--wordclust).

--label_stop LABEL_STOPFILE
	A file of Perl regexes that define the stop list of words to be 
	excluded from the labels.

--label_ngram LABEL_NGRAM
	Specifies the value of n in 'n-gram' for the feature selection. 
	The supported values for n are 2, 3 and 4.
	
	Default value is 2.

--label_remove LABEL_N
	Removes ngrams that occur less than LABEL_N times.

--label_window LABEL_W
	Specifies the window size for bigrams. Pairs of words that co-occur 
	within the specified window from each other (window LABEL_W allows at 
	most LABEL_W-2 intervening words) will form the bigram features. 
	Default window size is 2 which allows only consecutive word pairs.

--label_stat LABEL_STAT
	Specifies the statistical scores of association.

	Available tests of association are :

                dice            -       Dice Coefficient
                ll              -       Log Likelihood Ratio
                odds            -       Odds Ratio
                phi             -       Phi Coefficient
                pmi             -       Point-Wise Mutual Information
                tmi             -       True Mutual Information
                x2              -       Chi-Squared Test
                tscore          -       T-Score
                leftFisher      -       Left Fisher's Test
                rightFisher     -       Right Fisher's Test

--label_rank LABEL_R
	Features ranking below LABEL_R when arranged in descending order of 
	their test scores are ignored. 

Other Options :

--eval
	Evaluates clustering performace by comparing results against correct
	answer keys.

	Note: This option can be used only if the answer tags are provided 
	in the TEST file.

--rank_filter R
	Allows to remove low frequency senses during evaluation. This will
	remove the senses that rank below R when senses in TEST are arranged
	in the descending order of their frequencies. In other words, it 
	selects top R most frequent senses. An instance will be removed if 
	it has all sense tags below rank R.

--percent_filter P
	Allows to remove low frequency senses based on their percentage
	frequencies. This will remove senses whose frequency is below P%
	in the TEST data.

--showargs
	Displays to STDOUT values of compulsory and optional arguments.
	[NOT SUPPORTED IN THIS VERSION]

--verbose
	Displays to STDERR the current program status.

--help
	Displays this message.

--version
	Displays the version information.

Type 'perldoc discriminate.pl' for more detailed information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print '$Id: discriminate.pl,v 1.108 2013/06/26 01:09:24 jhaxx030 Exp $';
        print "\nDriver to Run SenseClusters\n";
##        print "\nCopyright (c) 2002-2006, Ted Pedersen, Amruta Purandare, Anagha Kulkarni, & Mahesh Joshi\n";
##        print "Date of Last Update:     07/30/2006\n";
}

#############################################################################

