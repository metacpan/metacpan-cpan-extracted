#!/usr/local/bin/perl -w

=head1 NAME

clusterstopping.pl - Predict the optimal number of clusters in a data set

=head1 SYNOPSIS

 clusterstopping.pl [OPTIONS] INPUTFILE

=head1 DESCRIPTION

Predicts the optimal number of clusters for the given data. This script tries to find 
the optimal number of clusters for the given INPUTFILE.

=head1 INPUT

=head2 Required Arguments:

=head3 INPUTFILE

Matrix file containing either:

 * context vectors (in dense or sparse format)
 * similarity values between contexts	

=head2 Optional Arguments:

=head4 --prefix PRE

Specify a prefix to be used for the output filenames.

If prefix is not specified then prefix is created by concatenating
time stamp to the string "expr".

=head4 --measure MSR

Specify the cluster stopping measure to be used. 

(Further details about the measures given below under the Section "DETAILS ABOUT THE CLUSTER-STOPPING MEASURES")

The possible option values:
    pk1 - PK1 measure
    pk2 - PK2 measure
    pk3 - PK3 measure [Default]
    gap - Adapted Gap Statistic
    pk  - All the three PK measures
    all - All the four measures - PK1, PK2, PK3 and Gap

=head4 --space SP

Specify if the clustering should be performed in vector or similarity space.

The possible option values:
   vector [Default]
   similarity

=head4 --delta INT

NOTE: Delta value can only be a positive integer value.

Specify 0 to stop the iterating clustering process when two consecutive crfun values 
are exactly equal. This is the default setting when the crfun values are integer/whole numbers.

Specify non-zero positive integer to stop the iterating clustering process when the diffference 
between two consecutive crfun values is less than or equal to this value. However, note that the
integer value specified is internally shifted to capture the difference in the least significant 
digit of the crfun values when these crfun values are fractional.  For example: 

    For crfun = 1.23e-02 & delta = 1 will be transformed to 0.0001
    For crfun = 2.45e-01 & delta = 5 will be transformed to 0.005

The default delta value when the crfun values are fractional is 1.

However if the crfun values are integer/whole numbers (exponent >= 2) then the specified delta 
value is internally shifted only until the least significant digit in the scientific notation.
For example: 

    For crfun = 1.23e+04 & delta = 2 will be transformed to 200
    For crfun = 2.45e+02 & delta = 5 will be transformed to 5
    For crfun = 1.44e+03 & delta = 1 will be transformed to 10

=head4 --clmethod CL

Specifies the clustering method.

The possible option values:

   rb - Repeated Bisections [Default]
   rbr - Repeated Bisections for by k-way refinement
   direct - Direct k-way clustering
   agglo  - Agglomerative clustering
   bagglo - Partitional biased Agglomerative clustering [Only in vector space]

For large amount of data, 'rb', 'rbr' or 'direct' are recommended. 

=head4 --crfun CR

Selects the criteria function for Clustering. The meanings of these criteria
functions are explained in Cluto's manual.

The possible option values:

   i1      -  I1  Criterion function
   i2      -  I2  Criterion function [Default]
   h1      -  H1  Criterion function
   h2      -  H2  Criterion function
   e1      -  E1  Criterion function
	
=head4 --sim SIM

Specifies the similarity measure to be used

The possible option values:

   cos      -  Cosine [Default]
   corr     -  Correlation Coefficient
	
NOTE: This option can be used only in vector space.

=head4 --rowmodel RMOD

The option is used to specify the model to be used to scale every 
column of each row. (For further details please refer Cluto manual)

The possible option values:

   none  -  no scaling is performed [Default]
   maxtf -  post scaling the values are between 0.5 and 1.0
   sqrt  -  square-root of actual values
   log   -  log of actual values
	
=head4 --colmodel CMOD

The option is used to specify the model to be used to (globally) scale each 
column across all rows. (For further details please refer Cluto manual)

The possible option values:

   none  -  no scaling is performed [Default]
   idf   -  scaling according to inverse-document-frequency 

=head4 --threspk1 NUM

The threshold value that should be used by the PK1 measure to predict the
k value. 

Default = -0.7

=head4 --precision NUM 

Specifies the precision to be used.

Default: 4

=head3 Adapted Gap Statistic related options:

=head4 --B NUM    

The number of replicates/references to be generated.

Default: 1

=head4 --typeref TYP

Specifies whether to generate B replicates from a reference or to generate 
B references.

The possible option values:

      rep - replicates [Default]
      ref - references

=head4 --seed NUM

The seed to be used with the random number generator. 

Default: No seed is set.

=head4 --percentage NUM

Specifies the percentage confidence to be reported in the log file.
Since Statistics::Gap uses parametric bootstrap method for reference distribution
generation, it is critical to understand the interval around the sample mean that
could contain the population ("true") mean and with what certainty.

Default: 90

=head3 Other Options :

=head4 --help

Displays the quick summary of program options.

=head4 --version

Displays the version information.

=head4 --verbose

Displays to STDERR the current program status.

=head1 OUTPUT

=over

=item * prefix.pk(1|2|3)

Contains the crfun values, (PK1, PK2, PK3) values and the predicted k.

=item * prefix.gap

Contains the crfun values, delta values and the predicted k.

=item * prefix.gap.log

Contains a table of values for Gap(k), Obs(crfun(k)), Exp(crfun(k)), sd(k), s(k) and Confidence interval.
Also contains individual crfun values for each of the B replicates/references for every value of K.

=back

The following files (*.dat) files are created to facilitate
creation of plots if required.

=over

=item * prefix.cr.dat

Contains the crfun values.

=item * prefix.pk(1|2|3).dat
 
Contains the PK1, PK2, or PK3 values.

=item * prefix.exp.dat

 Contains the Exp(crfun(k)) values generated for Gap Statistics.

=item * prefix.gap.dat

 Contains the gap(k) values.

=back

=head1 DETAILS ABOUT THE CLUSTER-STOPPING MEASURES

Each of the four cluster-stopping measure PK1, PK2, PK3 and Gap try to predict
the optimal number of clusters for the provided data (represented in the form 
of vectors or similarity values).

Following is a description about each of the measures and how they select a k value.

=head2 Formulation for PK1:

           crfun[m] - mean(crfun[1...deltaM])
 PK1[m] = -----------------------------------
                std(crfun[1...deltaM])

 where m = 2,...deltaM
 deltaM is a m value beyond which the crfun value does not change much.

k selection strategy: If m is the first value for which the PK1 score is 
greater than the threshold value then m-1 value is selected as the k value 
when using one of the maximization criterion functions like I2, H2 etc. 
While using minimization criterion functions like E1, if m the first value 
for which the PK1 score is less than the threshold value then m-1 is 
selected as the k value.

=head2 Formulation for PK2:

            crfun[m]
 PK2[m] = ------------
           crfun[m-1]

 where m = 2,...deltaM

k selection strategy: One standard deviation interval for the set of PK2[m]
values id calculated and the m value for which the PK2 score is outside this
interval but is still closest to the interval (from outside) is selected as
the k value.

=head2 Formulation for PK3:

                2 * crfun[m]
 PK3[m] = -------------------------
           crfun[m-1] + crfun[m+1]
 
 where m = 2,...deltaM

k selection strategy: Similar to that of PK2. One standard deviation of the 
PK3[m] scores is computed and the m value for which the PK3 score is outside 
this interval but is still closest to the interval (from outside) is selected 
as the k value.

=head2 Adapted Gap Statistic:

Adapted Gap tries to predict the optimal number of clusters by comparing the 
criterion function values that one gets for the observed/given data with the 
criterion function values that one gets for a random data. It uses hypothesis
testing in this process where the null hypothesis is that the optimal number 
of clusters for the given data is 1 and the aim is to refute this null 
hypothesis if the given data exhibits enough pattern. 

The plot of crfun values for given data is compared with the plot of crfun 
values for random or reference data. The m value corresponding to the first 
point of maximum difference between the two plots is chosen as the predicted 
k when using the maximization crfuns. While for the minimization crfuns, the 
m value corresponding to the first point of minimum difference between the
two plots is choosen as the predicted k value.

We provide two methods for the generation of reference data:

=over

=item 1. One can choose to generate a random dataset over the observed distribution by 
holding the row and the column marginals fixed and then generating B replicates 
from this random dataset using Monte Carlo sampling.
  
=item 2. Or to generate B random datasets over the observed distribution by holding 
the row and the column marginals fixed.

=back

Please refer to L<http://search.cpan.org/dist/Algorithm-RandomMatrixGeneration/> to
learn more about generating random dataset over the observed distribution by holding
the row and the column marginals fixed.

=head1 DETAILS ABOUT THE INPUT MATRIX FORMAT

The input matrix can be in either dense or sparse format. The cell values can 
be integer or real. Depending upon the value specified for the space parameter 
the header in the input file (first line) changes.

Example of input matrix in dense format when space=vector:

The first line specifies the dimensions - #rows #cols

From the second line the actual matrix follows.

 6 5
 1.3       2       0       0       3
 2.1       0       4       2.7     0
 1.3       2       0       0       3
 2.1       0       4       2.7     0
 1.3       2       0       0       3
 2.1       0       4       2.7     0

Example of input matrix in dense format when space=similarity:

The matrix, when in similarity space, is square and symmetric. 

The first line specifies the dimensions - #rows/#cols

From the second line the actual matrix follows.

 5
 1.0000   0.3179   0.5544   0.2541   0.4431   
 0.3179   1.0000   0.1386   0.4599   0.5413
 0.5544   0.1386   1.0000   0.5143   0.2186
 0.2541   0.4599   0.5143   1.0000   0.5148
 0.4431   0.5413   0.2186   0.5148   1.0000

Example of input matrix in sparse format when space=vector:

The first line specifies the dimensions & number of non-zero elements - #rows #cols #nonzeroElem

From the second line the matrix contents follow. Only non-zero elements are specified. Thus the
elements are specified as pairs of - #col elem. The row number is implied by the (line number-1).

 8 10 41
 1 3 4 2 8 2 10 1
 1 1 2 5 3 1 5 2 7 1 9 2
 1 3 4 2 8 2 10 1
 1 1 2 5 3 1 5 2 7 1 9 2
 1 3 4 2 8 2 10 1
 1 1 2 5 3 1 5 2 7 1 9 2
 2 4 3 1 4 2 5 5 7 1 9 1
 2 4 3 1 4 2 5 5 7 1 9 1

Example of input matrix in sparse format when space=similarity:

The first line specifies the dimensions & number of non-zero elements - #rows/#cols #nonzeroElem

The matrix format is same as explained above.

 5 15
 1 1.0000 3 0.5544 5 0.4431   
 2 1.0000 3 0.1386 4 0.4599 5 0.5413
 1 0.5544 2 0.1386 3 1.0000
 2 0.4599 4 1.0000
 1 0.4431 2 0.5413 5 1.0000

=head1 AUTHORS

 Anagha Kulkarni, Carnegie-Mellon University

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2006-2008, Anagha Kulkarni and Ted Pedersen

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

#use strict;
use POSIX qw(floor ceil);

### dependence on BigFloat only exists in RandomMatrix Generation
### use Math::BigFloat; 

use Algorithm::RandomMatrixGeneration;
use Getopt::Long;

# command line options
eval(GetOptions ("help","version","verbose","prefix=s","measure=s","space=s","delta=i","clmethod=s","crfun=s","sim=s","rowmodel=s","colmodel=s","threspk1=f","B=i","typeref=s","percentage=i","precision=i","seed=i")) or die("Please check the above mentioned option(s).\n");

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

#                       ====================================
#                          INITIALIZATION AND ERROR CHECKS
#                       ====================================

# ----------
# Input file
# ----------
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
                      Please specify the INPUTFILE file name...\n";
        exit 1;
}
$inpfile=$ARGV[0];

if(!-e $inpfile)
{
	print STDERR "ERROR($0):
                  Could not locate the INPUTFILE file $inpfile\n";
	exit 1;
}

# prefix
if(defined $opt_prefix)
{
	$prefix=$opt_prefix;
}
else
{
	$prefix="expr" . time();
}

# measure
if(defined $opt_measure && $opt_measure !~ /^(all|pk|pk1|pk2|pk3|gap)$/i)
{
	print STDERR "ERROR($0):
                  $opt_measure is not a valid option value for --measure\n";
	exit 1;	
}

if(defined $opt_measure)
{
	$measure = lc $opt_measure;
}
else #default
{
	$measure = "pk3";
}

# check for -ve delta value
if(defined $opt_delta && $opt_delta < 0)
{
	print STDERR "ERROR($0):
                      $opt_delta is not a valid option value for --delta.
		      The delta value should be a positive integer.\n";
	exit 1;	
}

# space
if(defined $opt_space && $opt_space !~ /^(vector|similarity)$/i)
{
	print STDERR "ERROR($0):
                  $opt_space is not a valid option value for --space\n";
	exit 1;	
}
if(defined $opt_space)
{
	$space = lc $opt_space;
}
else #default
{
	$space = "vector";
}

# delta
if(defined $opt_delta)
{
	$delta = $opt_delta;
}


# clmethod
if(defined $opt_clmethod && $opt_clmethod !~ /^(rb|rbr|direct|agglo|bagglo)$/i)
{
	print STDERR "ERROR($0):
                  $opt_clmethod is not a valid option value for --clmethod\n";
	exit 1;	
}
if(defined $opt_clmethod)
{
	$clmethod = lc $opt_clmethod;
}
else #default
{
	$clmethod = "rb";
}

if($space eq "similarity" && $clmethod eq "bagglo")
{
	print STDERR "ERROR($0):
                  Option value \"bagglo\" for --clmethod cannot be used in similarity space.\n";
	exit 1;		
}

# crfun
if(defined $opt_crfun && $opt_crfun !~ /^(i1|i2|h1|h2|e1)$/i)
{
	print STDERR "ERROR($0):
                  $opt_crfun is not a valid option value for --crfun\n";
	exit 1;	
}
#if(defined $opt_crfun && $opt_crfun eq "e1" && defined $opt_measure && ($opt_measure ne "all" || $opt_measure ne "gap"))
#{
#	print STDERR "ERROR($0):
#        --crfun e1 can be used only with --measure gap or --measure all\n";
#	exit 1;	
#}
if(defined $opt_crfun)
{
	$crfun = lc $opt_crfun;
	$crfun_name = uc $opt_crfun;
}
else #default
{
	$crfun = "i2";
	$crfun_name = "I2";
}

# sim
if(defined $opt_sim && $opt_sim !~ /^(cos|corr)$/i)
{
	print STDERR "ERROR($0):
                  $opt_sim is not a valid option value for --sim\n";
	exit 1;	
}
if(defined $opt_space && $opt_space eq "similarity" && defined $opt_sim)
{
    print STDERR "ERROR($0):
                  --sim option can be used only in vector space. \n";
    exit 1;
}
if(defined $opt_sim)
{
	$sim = lc $opt_sim;
}
elsif($space eq "vector") #default
{
	$sim = "cos";
}

# rowmodel
if(defined $opt_rowmodel && $opt_rowmodel !~/^(none|maxtf|sqrt|log)$/i)
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
if(defined $opt_rowmodel)
{
    $rowmodel = lc $opt_rowmodel;
}
elsif($space eq "vector") #default
{
    $rowmodel = "none";
}

# colmodel
if(defined $opt_colmodel && $opt_colmodel !~/^(none|idf)$/i)
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
if(defined $opt_colmodel)
{
    $colmodel = lc $opt_colmodel;
}
elsif($space eq "vector") #default
{
    $colmodel = "none";
}

# threspk1
if(($measure ne "all" && $measure ne "pk" && $measure ne "pk1") && defined $opt_threspk1)
{
    print STDERR "ERROR($0):
                  --threspk1 option can be used only when using --measure all or pk1 \n";
    exit 1;
}
if(defined $opt_threspk1)
{
	$thres_pk1 = $opt_threspk1;
}
elsif($measure eq "all" || $measure eq "pk" || $measure eq "pk1")
{
	$thres_pk1 = -0.7;
}

my $B = 1; #default
if(defined $opt_B)
{
	$B = $opt_B;
}

my $typeref = "rep"; #default
if(defined $opt_typeref && $opt_typeref !~ /^(rep|ref)$/i)
{
	print STDERR "ERROR($0):
	              Specified typeref value: $opt_typeref is not supported.\n";
	exit 1;
}
elsif(defined $opt_typeref)
{
	$typeref = $opt_typeref;
}

my $percentage = 90; #default
if(defined $opt_percentage)
{
	$percentage = $opt_percentage;
}

my $precision = 4; #default
if(defined $opt_precision)
{
	$precision = $opt_precision;
}

my $precision_str = '%.' . $precision . 'f';

my $seed;
if(defined $opt_seed)
{
	$seed = $opt_seed;
}

$cwd = `pwd`;
chomp($cwd);

#*********************************************************************

# for matrix dimensions
my $rcnt = 0;
my $ccnt = 0;

# read the input matrix file
open(INP,"<$inpfile") || die "Error opening input matrix file <$inpfile>\n";

my $line;
$line = <INP>;
chomp($line);

#remove leading white spaces
$line=~s/^\s+//;

my $format = 0; # determine the format of the input matrix - dense (0) / sparse (1)
if($space eq "vector")
{
	my @tmp = ();
	@tmp = split(/\s+/,$line);
	$rcnt = $tmp[0];
	$ccnt = $tmp[1];
	
	if($#tmp == 2)
	{
		$format = 1; #sparse
	}
}
else
{
	my @tmp = ();
	@tmp = split(/\s+/,$line);
	$rcnt = $tmp[0];
	$ccnt = $tmp[0];
	
	if($#tmp == 1)
	{
		$format = 1; #sparse
	}
}

my @rmar;
my @cmar;

if($measure eq "all" || $measure eq "gap")
{	
	# for row and column marginals
	@rmar = ((0) x $rcnt);
	@cmar = ((0) x $ccnt);

    # find the row and column marginals for the input matrix
	if($format) # for sparse input format
	{
		my $row = 0;

		while(<INP>)
		{
			# remove the newline at the end of the input line
			chomp;
			
			# for empty lines
			if(m/^\s*\s*\s*$/)
			{
				next;
			}

			# remove leading white spaces
			s/^\s+//;
				
			# separate individual values in a line
			my @tmp = ();
			@tmp = split(/\s+/);
			
			for(my $i=0; $i<$#tmp; $i=$i+2)
			{
				$rmar[$row] += $tmp[$i+1];
				my $tmp_col = $tmp[$i] - 1;
				$cmar[$tmp_col] += $tmp[$i+1];
			}
			
			$row++;
		}
	}
	else # for dense input format
	{
		my $row = 0;
		while(<INP>)
		{
			# remove the newline at the end of the input line
			chomp;
			
			# skip empty lines
			if(m/^\s*\s*\s*$/)
			{
				next;
			}
			
			# remove leading white spaces
			s/^\s+//;
			
			# separate individual values in a line
			my @tmp = ();
			@tmp = split(/\s+/);
			for(my $i=0; $i<=$#tmp; $i++)
			{
				$rmar[$row] += $tmp[$i];
				$cmar[$i] += $tmp[$i];
			}
			
			$row++;
		}
	}

    close INP;
}

if($measure eq "all")
{
    open(OP1,">$prefix.pk1") || die "Error opening <$prefix.pk1> for writing.\n";
    open(OP2,">$prefix.pk2") || die "Error opening <$prefix.pk2> for writing.\n";
    open(OP3,">$prefix.pk3") || die "Error opening <$prefix.pk3> for writing.\n";
    open(OP4,">$prefix.gap") || die "Error opening <$prefix.gap> for writing.\n";
}
elsif($measure eq "pk")
{
    open(OP1,">$prefix.pk1") || die "Error opening <$prefix.pk1> for writing.\n";
    open(OP2,">$prefix.pk2") || die "Error opening <$prefix.pk2> for writing.\n";
    open(OP3,">$prefix.pk3") || die "Error opening <$prefix.pk3> for writing.\n";
}
elsif($measure eq "pk1")
{
	open(OP1,">$prefix.pk1") || die "Error opening <$prefix.pk1> for writing.\n";
}
elsif($measure eq "pk2")
{
	open(OP2,">$prefix.pk2") || die "Error opening <$prefix.pk2> for writing.\n";
}
elsif($measure eq "pk3")
{
	open(OP3,">$prefix.pk3") || die "Error opening <$prefix.pk3> for writing.\n";
}
elsif($measure eq "gap")
{
	open(OP4,">$prefix.gap") || die "Error opening <$prefix.gap> for writing.\n";
}

# output file for crfun values (till deltaK)
open(FPCR,">$prefix.cr.dat") || die "Error opening <$prefix.h2.dat> for writing.\n";

# vector space
if($space eq "vector")
{
	# form the string of parameters for vcluster
	$cluster_string ="";

	$cluster_string .="--clmethod $clmethod ";

    $cluster_string .="--crfun $crfun ";

    $cluster_string .="--sim $sim ";

    $cluster_string .="--rowmodel $rowmodel ";

    $cluster_string .="--colmodel $colmodel ";
	
	$cluster_string .="--nooutput ";
}
else # similarity space
{
	# form the string of parameters for scluster
	$cluster_string ="";

	$cluster_string .="--clmethod $clmethod ";

    $cluster_string .="--crfun $crfun ";

	$cluster_string .="--nooutput ";
}

# initializations
$k = 0;
$last_k = 0;
$mean = 0;
$break_flag = 0;
$nan_flag = 0;

# keep clustering the input vectors into k clusters until deltaK is reached
do
{
    $k++;

	if($k > $rcnt)
	{
	    print STDERR "ERROR($0):
			$crfun values do not converge for the delta value of $delta 
			(internally: $thres). Try using larger delta value. \n";
	    exit 1;
	}    

    if($space eq "vector")
    {
		# cluster the vectors into k clusters 
		my $status = system("vcluster $cluster_string $inpfile $k > $cwd/$inpfile.$k");
		die "Error while running vcluster $cluster_string $inpfile $k\n" unless $status==0;
    }
    else # similarity space
    {
		my $status = system("scluster $cluster_string $inpfile $k > $cwd/$inpfile.$k");
		die "Error while running scluster $cluster_string $inpfile $k\n" unless $status==0;
    }
    
    # open cluto output file to be used to read the crfun values
    open(FP,"$cwd/$inpfile.$k") || die "Error opening file <$inpfile.$k>\n";
    
    # read the complete file in one command
    $temp = $/;
    $/ = undef;
    $str = <FP>;
    $/ = $temp;
    close FP;
    unlink "$inpfile.$k";
    
    # read the crfun value
    $str =~ /\-way clustering: \[.*=(.*?)\]/;
    
    my $tmp_crfun = $1;

    # check for "nan"
    if($tmp_crfun =~ /nan/)
    {
		$nan_flag = 1;
		$last_k = $k-1;
		$break_flag = 1;			
    }
    else
    {
		# array of crfun values for various k values
		$cr[$k] = $tmp_crfun;
		
		# print the crfun value to *.dat file 
		print FPCR "$k $cr[$k]\n";
		
		# decide the delta value 
		
		# If a delta value is specified by the user then transform this value and then use it. 
		# Else if crfun value is a integer/whole number then set the delta to 0 (exact match).
		# Else if crfun value is a fractional number then set the delta to 1.
		
		# if opt_delta not specified
		if(!defined $opt_delta)
		{
			$cr[$k] =~ /e(.+)/;
			$exponent = $1;
			
			# if crfun is a integer (exponent >= 2) then use exact match (delta = 0)
			if($exponent >= 2)
			{
				$delta = 0;
			}
			else # else (crfun fractional) delta = 1
			{
				$delta = 1;
			}
		}
		
		# The transformation shifts the given delta value to the least significant digit in
		# the precision of the given crfun value for fractional crfun values.
		# For example: For crfun = 1.23e-02 & delta = 1 will be transformed to 0.0001
		#	       For crfun = 2.45e-01 & delta = 5 will be transformed to 0.005
		# But for integer/whole crfun values (exponent >= 2) the transformation shifts
		# the delta value not to the real least significant digit but to the least significant 
		# digit in which any difference between two consecutive crfuns can be observed.
		# For example: For crfun = 1.23e+04 & delta = 2 will be transformed to 200
		#	       For crfun = 2.45e+02 & delta = 5 will be transformed to 5
		#	       For crfun = 1.44e+03 & delta = 1 will be transformed to 10
		# Finally if the delta value is 0 then the transformed delta value is 0 too.
		
		# Transformation: 1e+/-XX * 0.0D
		$cr[$k] =~ /(e.+)/;
		$trans_delta = "1.0" . $1;
		$temp = "0.0" . $delta;
		$trans_delta *= $temp;
		
		# for changing the delta value when the exponent of crfun values changes
		if(!$thres || $flag)
		{
			$thres = $trans_delta;
			$flag = 0;
			# if the delta values changes print to the o/p files
			if($measure eq "all")
			{
				print OP1 "Delta: $thres\n";
				print OP2 "Delta: $thres\n";
				print OP3 "Delta: $thres\n";
				print OP4 "Delta: $thres\n";
			}
			elsif($measure eq "pk")
			{
				print OP1 "Delta: $thres\n";
				print OP2 "Delta: $thres\n";
				print OP3 "Delta: $thres\n";
			}
			elsif($measure eq "pk1")
			{
				print OP1 "Delta: $thres\n";
			}
			elsif($measure eq "pk2")
			{
				print OP2 "Delta: $thres\n";
			}
			elsif($measure eq "pk3")
			{
				print OP3 "Delta: $thres\n";
			}
			elsif($measure eq "gap")
			{
				print OP4 "Delta: $thres\n";
			}
			
		}
		if($trans_delta != $thres)
		{
			$flag = 1;
		}
		
		if($measure eq "all")
		{
			print OP1 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
			print OP2 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
			print OP3 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
			print OP4 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
		}
		elsif($measure eq "pk")
		{
			print OP1 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
			print OP2 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
			print OP3 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
		}
		elsif($measure eq "pk1")
		{
			print OP1 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
		}
		elsif($measure eq "pk2")
		{
			print OP2 "$crfun_name"."[$k] = " . $cr[$k] . " \n";	
		}
		elsif($measure eq "pk3")
		{
			print OP3 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
		}
		elsif($measure eq "gap")
		{
			print OP4 "$crfun_name"."[$k] = " . $cr[$k] . " \n";
		}
		
		# accumulator for calculating the mean of crfun values
		$mean += $cr[$k];
		
		# check if new crfun value has improvement over the 
		# previous crfun value by at least the threshold value
		
		if($crfun eq "e1")
		{
			if($k > 1 && (($cr[$k-1] - $cr[$k]) <= $thres))
			{
				# if the new crfun value is almost comparable to the
				# previous crfun values which implies that separating
				# the instances into more clusters henceforth 
				# will yield more or less the same crfun value i.e.
				# will not give a significant improvement then stop.
				
				# This assumption significantly reduces the 
				# clustering requirement of this method.
				
				# remember the last k for further calculations
				$last_k = $k;
				$break_flag = 1;			
			}		
		}
		else
		{
			if($k > 1 && (($cr[$k] - $cr[$k-1]) <= $thres))
			{
				# if the new crfun value is almost comparable to the
				# previous crfun values which implies that separating
				# the instances into more clusters henceforth 
				# will yield more or less the same crfun value i.e.
				# will not give a significant improvement then stop.
				
				# This assumption significantly reduces the 
				# clustering requirement of this method.
				
				# remember the last k for further calculations
				$last_k = $k;
				$break_flag = 1;			
			}		
		}
    }	
}while(!$break_flag);

close FPCR;

# quit if NaN value generated for crfun
if($nan_flag)
{
    print STDERR "ERROR($0):
          $crfun is generating \"NaN\" values for this data. \n";
    exit 1;
}

# -------------Calculations for PK1-------------
if($measure eq "all" || $measure eq "pk" || $measure eq "pk1")
{
	# calculate mean_crfun
	if($last_k)
	{
		$mean = $mean/$last_k;
		$mean = sprintf($precision_str,$mean);
		print OP1 "Mean = $mean\n";
	}
	else
	{
	    print STDERR "ERROR($0):
                      Not enough $crfun values. $crfun values are converging very early for this data. 
Try using smaller delta value. \n";
	    exit 1;
	}

	# calculate std_deviation_crfun
	$stdev = 0;
	for($i = 1; $i <= $last_k; $i++)
	{
		$stdev = $stdev + ($cr[$i] - $mean)**2;
	}
	$stdev = $stdev/$last_k;
	$stdev = sqrt($stdev);
	$stdev = sprintf($precision_str,$stdev);
	print OP1 "Std Dev = $stdev\n";
	
	# calculate the confidence interval for 1 standard deviation. 
	$range1 = $mean-$stdev;
	$range1 = sprintf($precision_str,$range1);
	$range2 = $mean+$stdev;
	$range2 = sprintf($precision_str,$range2);
	print OP1 "Confidence Interval: $range1 to $range2\n";
	
	# print the output to a .dat file too for plots
	open(FP,">$prefix.pk1.dat") || die "Error opening $inpfile.dat for writing\n";
	
	# calculate PK1 values
	print OP1 "k  : PK1  \n";
	print OP1 "-----------\n";
	if($stdev != 0)
	{
		$flag = 0;
		for($i = 2; $i <= $last_k; $i++)
		{	
			if($stdev)
			{
				$pk1[$i] = ( $cr[$i] - $mean ) / $stdev;
				$pk1[$i] = sprintf($precision_str,$pk1[$i]);
			}
			else
			{
				print STDERR "ERROR($0):
                              The one standard deviation for the crfun values is 0. Quitting to avoid dividing by zero. \n";
				exit 1;
			}
			
			print OP1 "$i : $pk1[$i]\n";
			print FP "$i $pk1[$i]\n";
			
			if($crfun eq "e1")
			{
				if($pk1[$i] < $thres_pk1 && !$flag)
				{
					if($i > 2)
					{
						$pk1_K = $i-1;
						$pk1_K_value = $pk1[$i-1];
					}
					else
					{
						$pk1_K = 1;
						$pk1_K_value = 0;			
					}
					$flag = 1;
				}
			}
			else
			{
				if($pk1[$i] > $thres_pk1 && !$flag)
				{
					if($i > 2)
					{
						$pk1_K = $i-1;
						$pk1_K_value = $pk1[$i-1];
					}
					else
					{
						$pk1_K = 1;
						$pk1_K_value = 0;			
					}
					$flag = 1;
				}
			}
		}
	}
	else
	{
		for($i = 2; $i <= $last_k; $i++)
		{	
			print OP1 "$i : Infinity   \n";
		}
		
		$pk1_K = 1;
		$pk1_K_value = "Infinity";			
	}
	close FP;

	if(!$flag && !defined $pk1_K)
	{
		$pk1_K = 1;
		$pk1_K_value = 0;			
	}
}

# -------------Calculations for PK2-------------
# calculate 1st ratio = crfun(k+1)/crfun(k) 
if($measure eq "all" || $measure eq "pk" || $measure eq "pk2")
{
	$mean_ratio = 0;
	for($i = 1; $i < $last_k; $i++)
	{
	    if($crfun eq "e1")
	    {
		if($cr[$i+1])
		{
		    $ratio_1[$i] = $cr[$i] / $cr[$i+1];
		}
		else
		{
		    my $tmp = $i+1;
		    print STDERR "ERROR($0):
                          $crfun" . "[$tmp] = 0. Quitting to avoid dividing by zero. \n";
		    exit 1;
		}
	    }
	    else
	    {
		if($cr[$i])
		{
		    $ratio_1[$i] = $cr[$i+1] / $cr[$i];
		}
		else
		{
		    print STDERR "ERROR($0):
                          $crfun" . "[$i] = 0. Quitting to avoid dividing by zero. \n";
		    exit 1;
		}
	    }

	    $ratio_1[$i] = sprintf($precision_str,$ratio_1[$i]);
	    $mean_ratio += $ratio_1[$i];	
	}
	
	# calculate mean_pk2
	if($last_k>1)
	{
		$mean_ratio = $mean_ratio/($last_k-1);
		$mean_ratio = sprintf($precision_str,$mean_ratio);
		print OP2 "Mean = $mean_ratio\n";
	}
	else
	{
		print STDERR "ERROR($0):
                      Not enough $crfun values. Quitting to avoid dividing by zero. \n";
		exit 1;
	}
	
	# calculate std_deviation_pk2
	$stdev = 0;
	for($i = 1; $i < $last_k; $i++)
	{
		$stdev = $stdev + ($ratio_1[$i] - $mean_ratio)**2;
	}
	$stdev = $stdev/($last_k-1);
	$stdev = sqrt($stdev);
	$stdev = sprintf($precision_str,$stdev);
	print OP2 "Std Dev = $stdev\n";
	
	$range1 = $mean_ratio-$stdev;
	$range1 = sprintf($precision_str,$range1);
	$range2 = $mean_ratio+$stdev;
	$range2 = sprintf($precision_str,$range2);
	print OP2 "Confidence Interval: $range1 to $range2\n";
	
	# print the output to a .dat file too
	open(FP,">$prefix.pk2.dat") || die "Error opening <$inpfile.dat> for writing.\n";
	
	print OP2 "k  : PK2 value  : In/Out \n";
	print OP2 "------------------------\n";
	
	$pk2_K = 0;
	$pk2_K_value = 999999;
	for($i = 1; $i < $last_k; $i++)
	{
		if($ratio_1[$i] >= $range1 && $ratio_1[$i] <= $range2)
		{
			print OP2 $i+1 . " : $ratio_1[$i]  : 0 \n";
			print FP $i+1 . " $ratio_1[$i] $range1 $range2\n";
		}
		else
		{
			print OP2 $i+1 ." : $ratio_1[$i]  : 1 \n";
			print FP $i+1 . " $ratio_1[$i] $range1 $range2\n";

			# logic for predicting K value
			if($ratio_1[$i] >= 1)
			{
				if($ratio_1[$i] < $pk2_K_value)
				{
					$pk2_K = $i+1;
					$pk2_K_value = $ratio_1[$i];
				}				
			}
		}
	}
	close FP;
}

# -------------Calculations for PK3-------------
if($measure eq "all" || $measure eq "pk" || $measure eq "pk3")
{
	if($last_k <= 2)
	{
		print STDERR "ERROR($0):
                      Not enough $crfun values to compute pk3 measure.\n";
		exit 1;
	}
	
	# calculate dice = 2 * crfun(k)/(crfun(k-1) + crfun(k+1)) 
	$mean_ratio = 0;
	for($i = 2; $i < $last_k; $i++)
	{
		if(($cr[$i-1]+$cr[$i+1]) != 0)
		{
			$dice[$i] = (2 * $cr[$i]) / ($cr[$i-1] + $cr[$i+1]);
			$dice[$i] = sprintf($precision_str,$dice[$i]);
			$mean_ratio += $dice[$i];	
		}
		else
		{
		    my $tmp1 = $i+1;
		    my $tmp2 = $i-1;
		    print STDERR "ERROR($0):
                          Quitting to avoid dividing by zero. crfun[$tmp1] + crfun[$tmp2] ($cr[$i-1] + $cr[$i+1]) resulting to 0 \n";
			exit 1;
		}
	}
	
	# calculate mean_pk3
	if($last_k>2)
	{
		$mean_ratio = $mean_ratio/($last_k-2);
		$mean_ratio = sprintf($precision_str,$mean_ratio);
		print OP3 "Mean = $mean_ratio\n";
	}
	else
	{
		print STDERR "ERROR($0):
                      Not enough $crfun values. Quitting to avoid dividing by zero. \n";
		exit 1;
	}
	
	# calculate std_deviation_pk3
	$stdev = 0;
	for($i = 2; $i < $last_k; $i++)
	{
		$stdev = $stdev + ($dice[$i] - $mean_ratio)**2;
	}
	$stdev = $stdev/($last_k-2);
	$stdev = sqrt($stdev);
	$stdev = sprintf($precision_str,$stdev);
	print OP3 "Std Dev = $stdev\n";
	
	$range1 = $mean_ratio-$stdev;
	$range1 = sprintf($precision_str,$range1);
	$range2 = $mean_ratio+$stdev;
	$range2 = sprintf($precision_str,$range2);
	print OP3 "Confidence Interval: $range1 to $range2\n";
	
	# print the output to a .dat file too
	open(FP,">$prefix.pk3.dat") || die "Error opening <$inpfile.dat> for writing\n";
	
	print OP3 "k  :  PK3 Value : In/Out \n";
	print OP3 "------------------------\n";
	
	$pk3_K = 0;
	$pk3_K_value = 999999;
	for($i = 2; $i < $last_k; $i++)
	{
		if($dice[$i] >= $range1 && $dice[$i] <= $range2)
		{
			print OP3 "$i : $dice[$i]  : 0 \n";
			print FP "$i $dice[$i] $range1 $range2\n";
		}
		else
		{
			print OP3 "$i : $dice[$i]  : 1 \n";
			print FP "$i $dice[$i] $range1 $range2\n";
			
			# logic for predicting K value
			if($crfun eq "e1")
			{
				if($dice[$i] < 1)
				{
					if($dice[$i] < $pk3_K_value)
					{
						$pk3_K = $i;
						$pk3_K_value = $dice[$i];
					}				
				}
			}
			else
			{
				if($dice[$i] >= 1)
				{
					if($dice[$i] < $pk3_K_value)
					{
						$pk3_K = $i;
						$pk3_K_value = $dice[$i];
					}				
				}
			}
		}
	}
	close FP;
	
}

# -------------Calculations for Gap-------------

if($measure eq "all" || $measure eq "gap")
{
	#~~~~~ Step 1: Find the crfun value per k for the observed data ~~~~~~~~
	# This step already done. The crfun values in @cr 

	#~~~~~~~~~~~~~~~~~~~~ Step 2: Generation of Reference Model  ~~~~~~~~~~~~~~~~~~~~~~~~

	my @exp = ();		# holds the crfun values for various k for the reference data.

	if($typeref eq "rep") #replicates
	{		
		# Generate the Reference Distribution
		my @refmat = ();
		if(!$seed)
		{
			@refmat = generateMatrix(\@rmar, \@cmar, $precision);
		}
		else
		{
			@refmat = generateMatrix(\@rmar, \@cmar, $precision, $seed);
		}
	
		# Perform Monte Carlo Sampling B times from the generated distribution
		for(my $i = 1; $i <= $B; $i++)
		{
			my @replicate = ();
			
			for(my $j = 0; $j < $rcnt; $j++)
			{				
				my $rand = int(rand($rcnt));
				push @replicate, $refmat[$rand];
			}
			
			# compute total number of elements in @replicate
			my $totalElem = 0;
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $replicate[$j]->[$k])
					{
						$totalElem++;
					}
				}
			}

			# 1. Cluster the generated replicate
			# 2. Calculate the crfun value
			
			# Write the matrix to a temporary file
			my $filename = "$prefix.tmp.ref." . time() . $i;
			open(RO,">$filename") || die "Error opening temporary file <$filename> in write mode.\n";
			
			if($space eq "vector")
			{
				print RO $rcnt . "	 " . $ccnt  . "   " . $totalElem . "\n";
			}
			else
			{
				print RO $rcnt . "	 " . $totalElem . "\n";
			}
			
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $replicate[$j]->[$k])
					{
						my $tmp_col = $k+1;
						print RO "$tmp_col $replicate[$j]->[$k] ";
					}
				}
				print RO "\n";
			}
			
			close RO;
			
			for(my $k=1 ; $k<=$last_k ; $k++)
			{
				# cluster the replicate into 1..K clusters
				my $out_filename = "$prefix.tmp.ref.op." . $k . "." . time();
				
				if($space eq "vector")
				{
					my $status = system("vcluster $cluster_string $filename $k > $cwd/$out_filename");
					die "Error running vcluster $cluster_string $filename $k \n" unless $status==0;
				}
				else
				{
					my $status = system("scluster $cluster_string $filename $k > $cwd/$out_filename");
					die "Error running scluster $cluster_string $filename $k \n" unless $status==0;
				}
				
				# read the clustering output file
				open(CO,"<$cwd/$out_filename") || die "Error opening clustering output file <$out_filename>\n";
				
				# read the complete file in one command
				my $temp = $/;
				$/ = undef;
				my $str = <CO>;
				$/ = $temp;
				close FP;
				
				# read the crfun value
				$str =~ /\-way clustering: \[.*=(.*?)\]/;
				$exp[$i][$k] = $1;
				
				unlink "$out_filename","$filename.clustering.$k";
			}
		
			unlink "$filename", "$filename.tree";
		} # for $B
	}
	else # typeref = ref
	{
		# Generate B reference distributions
		for(my $i = 1; $i <= $B; $i++)
		{
			my @refmat = ();
		
			if(!$seed)
			{
				@refmat = generateMatrix(\@rmar, \@cmar, $precision);
			}
			else
			{
				@refmat = generateMatrix(\@rmar, \@cmar, $precision, $seed);
			}
			
			# compute total number of elements in @replicate
			my $totalElem = 0;
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $refmat[$j]->[$k])
					{
						$totalElem++;
					}
				}
			}
			
			# 1. Cluster the generated reference distributions
			# 2. Calculate the crfun
			
			# Write the matrix to a temporary file
			my $filename = "$prefix.tmp.ref." . time() . $i;
			open(RO,">$filename") || die "Error opening temporary file <$filename> in write mode.\n";
			
			# print the dimensions of the matrix to the file.		
			if($space eq "vector")
			{
			    print RO $rcnt . "	 " . $ccnt  . "   " . $totalElem . "\n";
			}
			else
			{
			    print RO $rcnt . "	 " . $totalElem . "\n";
			}
			
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $refmat[$j]->[$k])
					{
						my $tmp_col = $k+1;
						print RO "$tmp_col $refmat[$j]->[$k] ";
					}
				}
				print RO "\n";
			}
			
			close RO;
			
			for(my $k=1 ; $k<=$last_k ; $k++)
			{
				# cluster the generated reference into 1..K clusters
				my $out_filename = "$prefix.tmp.ref.op." . $k . "." . time();
				
				if($space eq "vector")
				{
					my $status = system("vcluster $cluster_string $filename $k > $cwd/$out_filename");
					die "Error running vcluster $cluster_string $filename $k \n" unless $status==0;
				}
				else
				{
					my $status = system("scluster $cluster_string $filename $k > $cwd/$out_filename");
					die "Error running scluster $cluster_string $filename $k \n" unless $status==0;
				}
				
				# read the clustering output file
				open(CO,"<$cwd/$out_filename") || die "Error opening clustering output file <$out_filename>\n";
				
				# read the complete file in one command
				my $temp = $/;
				$/ = undef;
				my $str = <CO>;
				$/ = $temp;
				close FP;
				
				# read the crfun value
				$str =~ /\-way clustering: \[.*=(.*?)\]/;
				my $tmp_crfun = $1;

				# check and quit if NaN value generated 
				if($tmp_crfun =~ /nan/)
				{
				    print STDERR "ERROR($0):
          $crfun is generating \"NaN\" values for the expected data. \n";
				    exit 1;
				}
				else
				{				    
				    $exp[$i][$k] = $1;
				}
				
				unlink "$out_filename","$filename.clustering.$k";

			} # for $last_k
			
			unlink "$filename", "$filename.tree";
		} # for $B
	} #else typeref = ref

	# For plots
	# Expected
	open(G3a,">$prefix.exp.dat") || die "Error creating file <$prefix.exp.dat>\n";
	
	my @sum = ();
	my @gap = ();
	
	# Calculate average over the B crfun(exp) values
	for(my $i = 1; $i <= $last_k; $i++)
	{
		for(my $j = 1; $j <= $B; $j++)
		{
			$sum[$i] += $exp[$j][$i];
		}
		
		$sum[$i] = sprintf($precision_str,$sum[$i]/$B) + 0;
		
		# Calculate Gap(k) = crfun(obs) - avg_crfun(exp)
		$gap[$i] = sprintf($precision_str, $cr[$i] - $sum[$i]) + 0;
		
		print G3a "$i $sum[$i]\n";
	}
	
	close G3a;
	
#~~~~~~~~~~~~~~~~~~~~ Step 3: Calculation of Standard Deviation  ~~~~~~~~~~~~~~~~~~~~~~~~
	
	my @sd = ();
	my @s = ();
	my $lower = 0;
	my $upper = 0;
	
# For plot
	open(G4,">$prefix.gap.dat") || die "Error creating file <$prefix.gap.dat>\n";
	
# Calculate standard deviation sd for crfun(exp)
	for(my $i = 1; $i <= $last_k; $i++)
	{
		for(my $j = 1; $j <= $B; $j++)
		{
			$sd[$i] += ($exp[$j][$i] - $sum[$i])**2;
		}
		
		$sd[$i] = sprintf($precision_str,sqrt($sd[$i]/$B)) + 0;
		
		# Calculate the modified standard deviation to account for 
		# simulation error.
		$s[$i] = $sd[$i] * sqrt(1 + 1/$B);
		$s[$i] = sprintf($precision_str,$s[$i]) + 0;
		
		$lower = $gap[$i] - $s[$i];
		$upper = $gap[$i] + $s[$i];
		print G4 "$i $gap[$i] $lower $upper\n";
	}
	
	close G4;
	
	$gap_K = 1;

	# Find the optimal #of k
	# for e1 
	if($crfun eq "e1")
	{		
		for(my $i = 2; $i < $last_k; $i++)
		{
			if($gap[$i] <= ($gap[$i+1] + $s[$i+1]))
			{
				$gap_K = $i;
#				print "$gap_K\n";
				last;
			}
		}
	} # e1 - end
	elsif($crfun eq "i2" || $crfun eq "i1") # for i2
	{
		for(my $i = 1; $i < $last_k; $i++)
		{
			if($gap[$i] >= $gap[$i+1] - $s[$i+1])
			{
				$gap_K = $i;
#				print "$gap_K\n";
				last;
			}
		}
	} # i2 - end
	elsif($crfun eq "h2" || $crfun eq "h1") # for h2
	{
		for(my $i = 2; $i < $last_k; $i++)
		{
			if($gap[$i] < 0)
			{
				next;
			}
			
			if($gap[$i] >= $gap[$i+1] - $s[$i+1])
			{
				$gap_K = $i;
#				print "$gap_K\n";
				last;
			}
		}
	} # h2 - end

	# Printing to the log file.
	open(LO,">$prefix.gap.log") || die "Error opening the Log file <$prefix.gap.log> in write mode.\n";    
	
	# Print the confidence intervals
	my $alpha = 0;
	my $low_conf_int = 0;
	my $upp_conf_int = 0;
	my @tmp = ();
	
	printf LO "%3s  %10s  %10s  %10s  %10s  %10s  %30s\n", "K", "Gap(k)", "Obs($crfun(k))", "Exp($crfun(k))", "sd(k)", "s(k)", "$percentage% Confidence Intervals";   
	printf LO "-" x 95 ."\n";
	for(my $i = 1; $i <= $last_k; $i++)
	{
		# Calculate a from 100(1-2a) = %
		$alpha = (1 - $percentage/100)/2;
		
		for(my $j = 1; $j <= $B; $j++)
		{
			$tmp[$j-1] = $exp[$j][$i];
		}
		# sort in the numeric ascending order 
		@tmp = sort {$a <=> $b} (@tmp);    
		
		# Calculate lower bound
		$low_conf_int = ($tmp[floor($B*$alpha)-1] + $tmp[ceil($B*$alpha)-1])/2;
		
		# Calculate upper bound
		$upp_conf_int = ($tmp[floor($B*(1-$alpha))-1] + $tmp[ceil($B*(1-$alpha))-1])/2;
		
		printf LO "%3d  %10.4f  %10.4f  %10.4f  %10.4f  %10.4f  %30s\n", $i, $gap[$i], $cr[$i], $sum[$i], $sd[$i], $s[$i], "$low_conf_int - $upp_conf_int";
	    }

	print LO "\nIndividual Exp($crfun(k)) values:\n";
	for(my $i = 1; $i <= $last_k; $i++)
	{
	    print LO "K=$i\n";
	    printf LO "%3s  %10s\n", "B", "crfun"; 
	    printf LO "-" x 15 . "\n"; 
	    for(my $j = 1; $j <= $B; $j++)
	    {
		$tmp[$j-1] = $exp[$j][$i];
		printf LO "%3s  %10s\n", "$j", "$exp[$j][$i]"; 
	    }
	    print LO "\n";
	}
	
	close LO;
}

# print the predicted K values
if($measure eq "all" || $measure eq "pk" || $measure eq "pk1")
{
    print "$pk1_K\n";
    print OP1 "PK1 predicted k = $pk1_K (PK1[$pk1_K] = $pk1_K_value)\n";
    close OP1;
}
if($measure eq "all" || $measure eq "pk" || $measure eq "pk2")
{
    if(!$pk2_K)
    {
	print "1\n";
	print OP2 "PK2 predicted k = 1 (PK2[1] = 0)\n";
    }
    else
    {
	print "$pk2_K\n";
	print OP2 "PK2 predicted k = $pk2_K (PK2[$pk2_K] = $pk2_K_value)\n";
    }
    close OP2;    
}
if($measure eq "all" || $measure eq "pk" || $measure eq "pk3")
{
    if(!$pk3_K)
    {
	print "1\n";
	print OP3 "PK3 predicted k = 1 (PK3[1] = 0)\n";
    }
    else
    {
	print "$pk3_K\n";
	print OP3 "PK3 predicted k = $pk3_K (PK3[$pk3_K] = $pk3_K_value)\n";
    }
    close OP3;
}
if($measure eq "all" || $measure eq "gap")
{
    print "$gap_K\n"; 
    print OP4 "Adapted Gap Statistic predicted k = $gap_K\n"; 
    close OP4;
}

exit 0;

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: clusterstopping.pl [OPTIONS] INPUTFILE";
        print "\nTYPE clusterstopping.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()

{
	print "Usage: clusterstopping.pl [OPTIONS] INPUTFILE

INPUTFILE

Matrix file containing either:
 * context vectors (in dense or sparse format)
 * similarity values between contexts	

Optional Arguments:

--prefix PRE

Specify a prefix to be used for the output filenames.

If prefix is not specified then prefix is created by concatenating
time stamp to the string \"expr\".

--measure MSR

Specify the cluster stopping measure to be used. 

(Further details about the measures given below under the Section 
\"DETAILS ABOUT THE CLUSTER-STOPPING MEASURES\")

The possible option values:
    pk1 - PK1 measure
    pk2 - PK2 measure
    pk3 - PK3 measure [Default]
    gap - Adapted Gap Statistic
    pk  - All the three PK measures
    all - All the four measures - PK1, PK2, PK3 and Gap

--space SP

Specify if the clustering should be performed in vector or similarity space.

The possible option values:
   vector [Default]
   similarity

--delta INT

NOTE: Delta value can only be a positive integer value.

Specify 0 to stop the iterating clustering process when two 
consecutive crfun values are exactly equal. This is the 
default setting when the crfun values are integer/whole numbers.

Specify non-zero positive integer to stop the iterating 
clustering process when the diffference between two consecutive 
crfun values is less than or equal to this value. However, note 
that the integer value specified is internally shifted to capture 
the difference in the least significant digit of the crfun values 
when these crfun values are fractional.
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

--clmethod CL

Specifies the clustering method.

The possible option values:
   rb - Repeated Bisections [Default]
   rbr - Repeated Bisections for by k-way refinement
   direct - Direct k-way clustering
   agglo  - Agglomerative clustering
   bagglo - Partitional biased Agglomerative clustering [Only in vector space]

For large amount of data, 'rb', 'rbr' or 'direct' are recommended. 

--crfun CR

Selects the criteria function for Clustering. The meanings of these criteria
functions are explained in Cluto's manual.

The possible option values:
   i1      -  I1  Criterion function
   i2      -  I2  Criterion function [Default]
   h1      -  H1  Criterion function
   h2      -  H2  Criterion function
   e1      -  E1  Criterion function
	
--sim SIM

Specifies the similarity measure to be used

The possible option values:
   cos      -  Cosine [Default]
   corr     -  Correlation Coefficient
	
NOTE: This option can be used only in vector space.

--rowmodel RMOD

The option is used to specify the model to be used to scale every 
column of each row. (For further details please refer Cluto manual)

The possible option values:
   none  -  no scaling is performed [Default]
   maxtf -  post scaling the values are between 0.5 and 1.0
   sqrt  -  square-root of actual values
   log   -  log of actual values
	
--colmodel CMOD

The option is used to specify the model to be used to (globally) scale each 
column across all rows. (For further details please refer Cluto manual)

The possible option values:
   none  -  no scaling is performed [Default]
   idf   -  scaling according to inverse-document-frequency 

--threspk1 NUM

The threshold value that should be used by the PK1 measure to predict the
k value. 

Default = -0.7

--precision NUM 

Specifies the precision to be used.

Default: 4

Adapted Gap Statistic related options:

--B NUM    

The number of replicates/references to be generated.

Default: 1

--typeref TYP

Specifies whether to generate B replicates from a reference or to generate 
B references.

The possible option values:
      rep - replicates [Default]
      ref - references

--seed NUM

The seed to be used with the random number generator. 
Default: No seed is set.

--percentage NUM

Specifies the percentage confidence to be reported in the log file.
Since Statistics::Gap uses parametric bootstrap method for reference 
distribution generation, it is critical to understand the interval 
around the sample mean that could contain the population (\"true\") 
mean and with what certainty.

Default: 90

Other Options :

--help

Displays the quick summary of program options.

--version

Displays the version information.

--verbose

Displays to STDERR the current program status.

\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: clusterstopping.pl,v 1.33 2008/03/30 04:51:10 tpederse Exp $';
	print "\nPredict the optimal number of clusters\n";
#        print "clusterstopping.pl      -       Version 0.04\n";
#        print "Cluster Stopping program.\n";
#        print "Copyright (c) 2006-2008, Ted Pedersen, Anagha Kulkarni.\n";
#        print "Date of Last Update:     07/29/2006\n";
}

#############################################################################
