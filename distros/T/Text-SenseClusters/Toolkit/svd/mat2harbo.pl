#!/usr/local/bin/perl -w

=head1 NAME

mat2harbo.pl - Convert matrix in Senseclusters sparse format to Harwell-Boeing (HB)  
format and set input parameters (lap2) for input to SVDPACKC. 

=head1 SYNOPSIS

 mat2harbo.pl [OPTIONS] MATRIX

The file input is a SenseClusters sparse matrix

 cat input

Output => 

 5 4 12
 1 1.5 3 2.5 4 1.0
 2 2.5 3 2.5
 1 1.5 3 2.5 4 1.0
 2 2.5 3 2.5
 2 2.5 3 2.5

Convert that to Harwell-Boeing form.

 mat2harbo.pl input --title "matrix format convestion" --id "sample" --numform 10f8.4

Output => 

 matrix format convestion                                                sample
 #
 rra                        5             4            12             0
           (10i8)          (10i8)            (10f8.4)            (10f8.4)
        1       3       6      11      13
        1       3       2       4       5       1       2       3       4       5
        1       3
   1.5000  1.5000  2.5000  2.5000  2.5000  2.5000  2.5000  2.5000  2.5000  2.5000
   1.0000  1.0000

The Harwell Boeing format stores data in 80 columns. The numform 10f8.4 says that 
there should be 10 numbers per line, each with 8 numeric values, where 4 digits are to 
the right of the decimal point. 

See L<http://math.nist.gov/MatrixMarket/formats.html#hb> for a detailed explanation of 
Harwell Boeing format. 

Type C<mat2harbo.pl --help> for a quick summary of options

=head1 DESCRIPTION

Converts a sparse matrix in SenseClusters format to Harwell-Boeing (HB) 
sparse format, which is the format required by SVDPACKC. This program also creates 
(optionally) the lap2 file which provides parameter settings for SVDPACKC.

=head1 INPUT

=head2 Required Arguments:

=head3 MATRIX

A sparse MATRIX in SenseClusters' format that is to be converted into 
Harwell Boeing format.

First line should show exactly 3 numbers separated by blanks as :

 #nrows #ncols #nnz

where 

 #nrows = Number of rows 
 #ncols = Number of columns 
 #nnz = Total number of non-zero values

in the MATRIX.

Each line thereafter should show a row of the MATRIX in sparse format.
A sparse row should be a space separated list of pairs of numbers 
where the first number shows the column index of a non-zero value 
and second number is the non-zero value itself that appears at that column 
index.

Column index counting starts from 1.

Sample MATRIX examples =>

=over 4

=item 1

 5 5 15
 2 9 4 9
 1 6 2 5 3 7 4 8 5 6
 1 4 2 5
 1 7 2 6 3 7
 1 9 2 8 3 9

Shows a 5 x 5 integer matrix containing total 15 non-zero elements.
Each ith line after the first line shows the non-zero elements in the ith
row. e.g. 2nd line (1st row) has 2 non-zero values (both 9) at column indices 
2 and 4. 6th line (5th row) has 3 non-zero values; 9 at index 1, 8 at index 2
and 9 at index 3.

=item 2 

 7 8 34
 1 0.160 2 -0.059 3 1.864 5 0.724 6 -0.472 7 -0.467
 2 -0.209 4 1.487 5 6.728 7 -3.085 8 1.396
 1 14.594 3 -2.858 4 -0.618 6 16.510 8 -2.314
 3 -0.384 5 -1.189 7 -0.155 8 0.006
 1 -0.128 3 0.020 4 -0.125 8 0.039
 2 0.062 3 0.058 4 0.016 5 0.057 7 0.407 8 0.015
 4 0.033 6 1.377 7 0.074 8 0.994

Shows a 7 x 8 real matrix =>

   7 8
   0.160 -0.059  1.864  0.000  0.724 -0.472 -0.467  0.000
   0.000 -0.209  0.000  1.487  6.728  0.000 -3.085  1.396
  14.594  0.000 -2.858 -0.618  0.000 16.510  0.000 -2.314
   0.000  0.000 -0.384  0.000 -1.189  0.000 -0.155  0.006
  -0.128  0.000  0.020 -0.125  0.000  0.000  0.000  0.039
   0.000  0.062  0.058  0.016  0.057  0.000  0.407  0.015
   0.000  0.000  0.000  0.033  0.000  1.377  0.074  0.994

=back

=head2 Optional Arguments:

=head4 --title TITLE

Allows user to specify the Title of the MATRIX which is displayed at Line1
(1-72) of the output HB matrix.
If --title is not specified, mat2harbo uses the MATRIX file name as 
the default title. 

=head4 --id ID

Programs processing the HB formatted matrix can identify the matrix by the ID 
specified at Line1 (73-80). Default ID is "harbomat". This identifier is limited to 8 
characters. 

=head4 --cpform CPFORM

Specifies the Column Pointer Format. The column pointer should have the format
of type MiN which indicates that each line in Block1 contains M integer
pointers each occupying N character spaces. Default format is 10i8. 

Note: M x N must be 80. 

=head4 --rpform RPFORM

Specifies the Row Pointer Format for row pointers in Block2. This has same 
MiN type of format as --cpform.

=head4 --numform NUMFORM

Specifies the Numeric Format to represent the matrix values in Block3.

mat2harbo allows 2 numeric formats :

=over
=item 1. MiN type, which has same interpretation as --cpform and --rpform.

=item 2. MfD.F - which means that there are total M real numbers on each line of block3, each occupying total D digit/character space, of which last F digits show fractional portion. 
=back

Thus, Matrix values could be Integer or Real, selected by specifying a 
particular format. 

Default NUMFORM is (5f16.10) which uses 16 digits for each MATRIX value of which
last 10 digits stand for the fractional part and each line contains 5 such 
real numbers.

=head3 Parameter Setting Options :

The options listed in this section create the parameter file (lap2) for las2.c
automatically.

=head4 --param 

Creates the parameter file lap2 that can be directly used while running las2.

=head4 --k K

Sets the value of maxprs option in LAP2 file to K i.e. 
requests K singular triplets from las2. Value of K should not exceed the 
number of columns of MATRIX.
Default K = 300

=head4 --rf RF

Reduces the dimensions of the column space of the MATRIX by scaling factor RF
i.e. if the MATRIX has N columns, maxprs is set to N/RF where RF > = 1

In other words, N/RF singular triplets are requested from las2.
Default RF = 10 that reduces the column space to 10% or preserves 10% of the 
original dimensions.

If both --k and --rf are specified, maxprs = min(K,N/RF)
Thus, default maxprs = min(300,N/10)

=head4 --iter I

Specifies the number of iterations for las2.
I, if specified, should not exceed the number of columns in the MATRIX
and I should be at least as high as maxprs.
Default I = min((3 * maxprs),#cols) where maxprs = min(K,N/RF).

=head3 Help on setting parameters in file las2.h

The header file las2.h in SVDPACKC specifies values of various constants
for las2. This section provides some guidelines on setting these constants
for using SenseClusters. Please note that the version of SVDPACKC found in /External 
has been modified with the settings as described below.

=over

=item * NMAX

Specifies the maximum possible number of columns in the matrix given to las2.
las2.h initially has a value of NMAX = 3000, which allows a maximum of 
3000 columns. However, we have found this default is too small for many 
of our experiments, so we recommend setting NMAX much higher. We  
routinely use a value of 30,000, and will assume that the user has 
reset NMAX in las2.h to this value in the rest of this discussion.

In general, this value should be higher than NCOLS shown by the 3rd column
on the 3rd line in the output of mat2harbo.pl.

=item * NZMAX

Specifies the maximum possible number of non-zero values in the matrix.
Initially the settings in las2.h have NZMAX = 100000. However, 
again we have found this to be too small. If the user sets NMAX to 30,000, 
and if we assume a 30,000 x 30,000 matrix is approximately 1%   dense,  
NZMAX could be set to 9,000,000 (30,000 x 30,000 / 100). This is the value 
we routinely use, and we will assume that the user has reset NZMAX to this 
value in the rest of this discussion. 

The user can check the exact NZMAX for their matrix on line 3 column 4 of  
the output matrix displayed by mat2harbo.pl and then set NZMAX to  
something higher than that.

=item * LMTNW

This specifies the maximum total memory to be allocated by las2. The  
initial setting of LMTNW in las2.h is 600000, however, we find that this 
is often too small. In general, the size of LMTNW is determined by the  
values you set NMAX and NZMAX to. LMTNW should be at least as large as :

 LMTNW = (6*NMAX + 4*NMAX + 1 + NZMAX*NZMAX) 

mat2harbo.p assumes that NMAX has been reset to 30,000 and that NZMAX is  
set to 9,000,000.  Thus, 

 LMTNW = ((6 * 30,000) + (4 * 30,000) + 1 + (30,000 * 30,000))

This leads to the new value for LMTNW of 900,300,001, which is equivalent 
to a maximum working memory size of 1 GB. We have found this size to be  
more than adquate to do SVD on a 25,000 x 25,000 matrix.

math2arbo.pl will show an advisory message indicating the minimum size 
that LMNTW should be set for, and will issue a warning message if the  
actual size needed for the user matrix exceeds 900,300,001 (approx 1 GB).

Memory is dynamically allocated by las2 depending upon the size of the input
matrix, irrespective of the value of LMTNW. In short, LMTNW specifies the
upper limit on memory consumption and the actual consumption depends on the
size of the matrix. Hence, LMTNW doesn't specify the total memory that las2
will *always* consume rather its an upper limit that could be consumed if
necessary.

=back

In case if las2 fails due to insufficient values of these parameters 
as indicated by the las2.h file, an error message will be shown in output 
file lao2 suggesting that the matrix is too large or something ... User is
adviced to check 3rd line of the matrix in Harwell-Boeing format (as produced 
by this program) that is given to las2. Check if NCOLS shown at column 3 of 
line 3 in the HB matrix exceeds NMAX. If so, increase NMAX to something higher
than NCOLS. If not, check if NNZ shown by column 4 on line 3 of the HB matrix 
exceeds NZMAX in las2.h, if so, increase NZMAX. If not, increase the LMTNW
to something higher than (6*NMAX + 4*NMAX + 1 + NMAX*NMAX), or simply
increase it without too much computations until las2 succeeds :-)

The other problem that a user might notice is that sometimes las2 runs 
for a very long time like more than few days. In such case, user is advised
to restart las2 by reducing the values of parameters 'maxprs' and 'iter' in 
parameter file lap2. Specifically, the 2nd parameter in lap2 is iter and 
the 3rd one is maxprs. Remember that, iter has to be >= maxprs.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

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
use POSIX 'ceil';

GetOptions ("help","version","title=s","id=s","cpform=s","rpform=s","numform=s","param","k=i","iter=i","rf=i");
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

if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the Matrix file ...\n";
        exit;
}
#accept the input file name
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Matrix file <$infile> doesn't exist...\n";
        exit;
}

open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening Matrix file <$infile>.\n";

# ---------------
# Reading infile
# ---------------

$line=1;

# line1 in Matrix file should either show the
# <keyfile> tag or #rows #cols #nnz
$line1=<IN>;
if($line1=~/keyfile/)
{
        $line1=<IN>;
        $line++;
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
        Line $line in Matrix file <$infile> should show #rows #cols #nnz.\n";
        exit;
}

# default parameters
if(defined $opt_param)
{
        if(!defined $opt_k)
        {
                $opt_k=300;
        }
        if(!defined $opt_rf)
        {
                $opt_rf=10;
        }
        elsif($opt_rf<1)
        {
                print STDERR "ERROR($0):
        --rf = $opt_rf should be greater than 1.\n";
                exit;
        }
	
	my $tmp_ratio = ceil($cols/$opt_rf);
        $maxprs=$opt_k > $tmp_ratio ? $tmp_ratio : $opt_k;

	if(!defined $opt_iter || $opt_iter < $maxprs || $opt_iter > $cols)
        {
                $opt_iter=(3*$maxprs) > $cols ? $cols : (3*$maxprs);
        }
        $iter=$opt_iter;
}

# output format options
if(defined $opt_cpform)
{
        if($opt_cpform =~ /^(\d+)i(\d+)$/)
	{
		if(($1 * $2) !=80)
		{
			print STDERR "ERROR($0):
	(#pointers/line ($1)) * (#digits/pointer ($2)) != 80 
	in --cpform = $opt_cpform.\n";
			exit;
		}
	}
	else
        {
                print STDERR "ERROR($0):
        Invalid column pointer format --cpform=$opt_cpform.\n";
                exit;
        }
}
if(defined $opt_rpform)
{
        if($opt_rpform =~ /^(\d+)i(\d+)$/)
	{
		if($1 * $2 !=80)
		{
			print STDERR "ERROR($0):
	(#pointers/line ($1)) * (#digits/pointer ($2)) !=80 
	in --rpform = $opt_rpform.\n";
			exit;
		}
	}
	else
        {
                print STDERR "ERROR($0):
        Invalid row pointer format --rpform=$opt_rpform.\n";
                exit;
        }
}
if(defined $opt_numform)
{
	if($opt_numform =~ /^(\d+)i(\d+)$/)
	{
		if($1 * $2 != 80)
		{
			print STDERR "ERROR($0):
	(#integers/line ($1)) * (#digits/integer ($2)) != 80 
	in --numform = $opt_numform.\n";
			exit;
		}
	}
	elsif($opt_numform =~ /^(\d+)f(\d+)\.\d+$/)
	{
		if($1 * $2 != 80)
		{
			print STDERR "ERROR($0):
	(#reals/line ($1)) * (#digits/real ($2)) != 80
	in --numform = $opt_numform.\n";
			exit;
		}
	}
	else
        {
                print STDERR "ERROR($0):
        Invalid number format --numform=$opt_numform.\n";
                exit;
        }
}

# reading the sparse matrix
# in row order
$row=0;
while(<IN>)
{
	$line++;
	$row++;
	chomp;
	s/^\s*//;
	s/\s*$//;
	if(/^\s*$/)
	{
		next;
	}
	@pairs=split(/\s+/);
	for($i=0; $i<$#pairs; $i=$i+2)
	{
		$index=$pairs[$i];
		if($index > $cols)
		{
			print STDERR "ERROR($0):
	Index <$index> at line <$line> in Matrix file <$infile> exceeds the 
	total number of columns <$cols> specified on line 1.\n";
			exit;
		}
		$value=$pairs[$i+1];
		if($value==0)
		{
			print STDERR "ERROR($0):
	Given Matrix <$infile> is not sparse. Caught 0 value at line $line.\n";
			exit;
		}
		# storing in column-wise order
		$sparse_matrix{$index}{$row}=$value;
		$nnz++;
	}
}

close IN;
if($row != $rows)
{
	print STDERR "ERROR($0):
	1st line in Matrix file <$infile> shows #vectors = #rows = $rows 
	while the actual #vectors found in this file = $row.\n";
	exit;
}

if($nnz != $nnz1)
{
	print STDERR "ERROR($0):
	1st line in Matrix file <$infile> shows #nnz = $nnz1 while the 
	actual #nnz found in the file = $nnz.\n";
	exit;
}

foreach $col (1..$cols)
{
	if(!defined $sparse_matrix{$col})
	{
		print STDERR "ERROR($0):
	Null column at $col.\n";
		exit;
	}
}

##############################################################################

#			==========================
#			      PROGRAM SECTION
#			==========================

=head1 Harwell Boeing Format

=head2 Header Section

=over 

=item * Line1 (Title[72], Id[8])

=item * Line2 Skipped (as SVDPack ignores this line)

=item * Line3 (Type[3], 11x, Nrows[14], Ncols[14], NNZ[14], Nrhs[14])

where Type[3] is a 3 Character Field in which

=over 

=item 1. char[1] = 

r for Real matrix, 

c for Complex matrix, 

p for Pattern matrix

=item 2. char[2] =

u for Unsymmetric matrix, 

h for Hermitian matrix (Aij=Aji* where Aji* is a complex conjugate of Aij), 

z for Skew Symmetrix matrix

r for Rectangular matrix

=item 3. char[3]=

a for Assembled matrix

f for Unassembled Finite Elements

=back

Nrows = Number of Rows

Ncols = Number of Columns

NNZ = Number of Non-Zero Elements

Nrhs = Number of Right-Hand Sides (not used in SenseClusters)

=item * Line4 

(Pointer_Format[16], Row_index_Format[16], Numeric_Value_Format[20],
RHS_Format[20])

Pointers and Row Indices could have MiN type of format which specifies
that there are M intergers on each line and each represented with N digits. 
(M x N must be = 80 as this format only supports column width of maximum 80
characters)

Numeric Values can have either MiN format with same interpretation of 
M and N as above or MfD.F format which specifies that there are M real 
numbers on each line, each occupying total D digit space of each last F digits 
show the fractional part. 

Note: D is that total space used to represent a number that includes the 
decimal point and +/- sign if any. 

=back 

The above 4 Lines form the Header of the HB sparse matrix. 

=head2 Data Section 

This section contains 3 blocks which contain the non-zero values in the matrix
along with their row and column index information. 

 *************************************************************************
             NON-ZERO ENTRIES ARE STORED IN COLUMN ORDER !!!
 *************************************************************************

We consider data section of 3 blocks:

=head3 BLOCK1 POINTERS

The first block is an array whose entries show the indices (in block3) of the
leading non-zero value of every column.

e.g. If a given matrix is 

 4 6
 2 3 0 0 0 1
 0 2 0 1 2 0
 0 0 2 4 1 0 
 1 1 0 0 5 0

Then the first block will contain the pointers 

[1 3 6 7 9 12 13]

This shows that 

The first column begins at the 1st non-zero entry (2)
The second column begins at the 3rd non-zero entry (3) [in COLUMN ORDER] 
The third column begins at the 6th non-zero entry (2)
The forth column begins at the 7th non-zero entry (1)
and so on ... 

 *************************************************************************
	NULL columns (having no non-zero elements) are not allowed. 
 *************************************************************************

Note: The column pointers start at 1.

The last entry in @pointers contains an extra pointer pointing to one location 
after the last entry. So the last index in @pointers will always be #nnz + 1 
(where #nnz = total no. of non-zero entries) 

=head3 BLOCK2 ROW_INDICES

This block stores the row indices of the non-zero matrix entries in column 
order. 

For above matrix, this block will look like 

[1 4 1 2 4 3 2 3 2 3 4 1]

which shows that 

The 1st non-zero entry is at 1st row.
The 2nd non-zero entry is at 4th row.
The 3rd non-zero entry is at 1st row
and so on ....

Note: Row indices start from 1.

=head3 BLOCK3 VALUES

This block contains the actual non-zero values from the matrix in 
column order.

Thus, the block3 for the above shown matrix will look like 

[2 1 3 2 1 2 1 4 2 1 5 1]


General Observations:

=over 4

=item 1. The length(block2)=length(block3) and each is equal to the number 
of non-zero entries in the matrix. 

=item 2. The length(block1) = #columns of matrix + 1 as each column will have
an entry in block1 that shows the position of the leading non-zero element 
in it and there are no NULL columns allowed.

+1 because there is an extra pointer pointing to the location after the last 
non-zero entry. 

=item 3. The column pointers in block1 are also the pointers to block3 entries
where the leading(first) non-zero entry of each column is located.

=back

=head2 Sample Output 

matrix.dat                                                 harbomat

#

 rra                  4             6            11             0

    (10i8)          (10i8)            (8f10.3)            (8f10.3)

       1       3       5       6       7      10      12
       2       3       2       3       4       1       1       2       
       3       3       4
     1.000     1.000     2.000     4.000     1.000     2.000     1.000     
     2.000     2.000     3.000     1.000

Shows the HB format for a 4 x 6 matrix :

 4 6
 0 0 0 2 1 0
 1 2 0 0 2 0
 1 4 0 0 2 3
 0 0 1 0 0 1

=cut

############################################################################

#			=============================
#			     CONVERSION SECTION
#			=============================

# creating temporary files to store sparse data blocks
$blk1="blk1". time(). ".mat2harbo";
$blk2="blk2". time(). ".mat2harbo";
$blk3="blk3". time(). ".mat2harbo";
# opening temp files in w
open(BLK1,">$blk1") || die "Error($0):
        Error(code=$!) in opening <$blk1> file.\n";
open(BLK2,">$blk2") || die "Error($0):
        Error(code=$!) in opening <$blk2> file.\n";
open(BLK3,">$blk3") || die "Error($0):
        Error(code=$!) in opening <$blk3> file.\n";

# reading the MATRIX in column order
# and making entries for each nnz in block files
$nnz=0;

@column_indices=keys %sparse_matrix;
@sorted_columns=sort {$a <=> $b} @column_indices;
foreach $col (@sorted_columns)
{
	@row_indices=keys %{$sparse_matrix{$col}};
	@sorted_rows=sort {$a <=> $b} @row_indices;
	$newcol=1;
	foreach $row (@sorted_rows)
	{
		$nnz++;
		if($newcol)
		{
			print BLK1 "$nnz\n";
			$newcol=0;
		}
		print BLK2 "$row\n";
		print BLK3 $sparse_matrix{$col}{$row} . "\n";
	}
}

print BLK1 ($nnz+1);

##############################################################################

#                       =========================
#			    PRINTING SECTION 
#			=========================

# printing Line1 (Title[72], Id[8])

# if the title is specified by the user
if(defined $opt_title)
{
	print pack("A72",$opt_title);
}
# use matrix file name as the default title
else
{
	print pack("A72",$infile);
}

# if the Id(also called as the KEY by SVDPack) 
# is specified by the user 
if(defined $opt_id)
{
	$id=$opt_id;
}
# use default id = "harbomat"
else
{
	$id="harbomat";
}
print pack("A8",$id);

# done with Line1
print "\n";

# Skipping Line2 by putting # as this line is 
# ignored by SVDPack. But should have at least 
# single character

print "#\n";

# printing Line3 (Type[3], 11x, Nrows[14], Ncols[14], NNZ[14], Nrhs[14])

# setting type characters 
$c1="r"; # we deal with Real matrices only

$c2="r"; # always assume rectangular 

$c3="a"; # always assembled matrices
$type=$c1.$c2.$c3;

printf("%3s%11s%14s%14s%14s%14s",$type," ",$rows,$cols,$nnz,0);
print "\n";

# done with Line3

# printing formats

# if column pointer format is specified
if(defined $opt_cpform)
{
	$ptrform=$opt_cpform;
	# check : valid format
	if($ptrform =~ /^(\d+)i(\d+)$/)
	{
		$ptrs_online=$1;
		$digits_per_ptr=$2;
		$ptr_string="%".$digits_per_ptr."d";

		$upper_cpform="";
                while(length($upper_cpform)<($digits_per_ptr-1))
                {
                        $upper_cpform.="9";
                }
	}
	else
	{
		print STDERR "ERROR($0):
	Invalid column pointer format $ptrform.\n";
		exit;
	}
	$ptrform="(".$opt_cpform.")";
}
# use default (10i8)
else
{
	$ptrform="(10i8)";
	$ptr_string="%8d";
	$ptrs_online=10;
	$upper_cpform="9999999";
}

# if row pointer format is specified
if(defined $opt_rpform)
{
        $rowform=$opt_rpform;
        # check : valid format
        if($rowform =~ /^(\d+)i(\d+)$/)
        {
                $rowinds_online=$1;
                $digits_per_rowind=$2;
                $row_string="%".$digits_per_rowind."d";

		$upper_rpform="";
                while(length($upper_rpform)<($digits_per_rowind-1))
                {
                        $upper_rpform.="9";
                }
        }
        else
        {
                print STDERR "ERROR($0):
        Invalid row pointer format $rowform.\n";
                exit;
        }
	$rowform="(".$opt_rpform.")";
}
# use default (10i8)
else
{
        $rowform="(10i8)";
	$row_string="%8d";
	$rowinds_online=10;
	$upper_rpform="9999999";
}

# if numeric value format is specified
if(defined $opt_numform)
{
        $numform=$opt_numform;
	# check : valid format
	# integer ?
        if($numform =~ /^(\d+)i(\d+)$/)
        {
                $nums_online=$1;
                $digits_per_num=$2;
                $num_string="%".$digits_per_num."d";

		$lower_numform="-";
                while(length($lower_numform)<($digits_per_num-1))
                {
                        $lower_numform.="9";
                }
                if($lower_numform eq "-")
                {
                        $lower_numform="0";
                }
                $upper_numform="";
                while(length($upper_numform)<($digits_per_num-1))
                {
                        $upper_numform.="9";
                }
        }
	# real ?
	elsif($numform=~/^(\d+)f(\d+)\.(\d+)$/)
	{
		$nums_online=$1;
                $digits_per_num=$2;
		$fract=$3;
                $num_string="%".$digits_per_num. "." .$fract."f";

		$lower_numform="-";
                while(length($lower_numform)<($digits_per_num-$fract-2))
                {
                        $lower_numform.="9";
                }
                $lower_numform.=".";
                while(length($lower_numform)<($digits_per_num-1))
                {
                        $lower_numform.="9";
                }

                $upper_numform="";
                while(length($upper_numform)<($digits_per_num-$fract-2))
                {
                        $upper_numform.="9";
                }
                $upper_numform.=".";
                while(length($upper_numform)<($digits_per_num-1))
                {
                        $upper_numform.="9";
                }
	}
	# invalid
        else
        {
                print STDERR "ERROR($0):
        Invalid number format $numform.\n";
                exit;
        }
	$numform="(".$opt_numform.")";
}
# use default (5f16.10)
else
{
        $numform="(5f16.10)";
	$num_string="%16.10f";
	$nums_online=5;

	$lower_numform="-999.9999999999";
        $upper_numform="9999.9999999999";
}

# we don't use rhs

# printing formats
printf("%16s%16s%20s%20s",$ptrform,$rowform,$numform,$numform);

# done with Line 4
print "\n";

# done with Header section !

# now data blocks ... 

# print from temp files

# block1 : column pointers

open(BLK1,$blk1) || die "Error($0):
        Error(code=$!) in opening <$blk1> file.\n";

# each line of BLK1 contains a single column pointer
$ptr=0;
while(<BLK1>)
{
	$ptr++;
	$value=$_;

	# check if valid pointer index
	if($value !~ /^\d+$/)
	{
		print STDERR "ERROR($0):
	Wrong pointer value<$value> at line $ptr in file<$blk1>.\n";
		exit;
	}
	if($ptr!=1 && ($ptr-1) % $ptrs_online == 0)
        {
                print "\n";
        }
	$formatted_cp=sprintf($ptr_string,$value);

	if($formatted_cp>$upper_cpform)
	{
		print STDERR "ERROR($0):
        Floating point overflow.
        Column pointer <$formatted_cp> can't be represented with format $ptr_string.\n";
                exit 1;
	}
	print "$formatted_cp";
}

print "\n";

# block2 : row indices 

open(BLK2,$blk2) || die "Error($0):
        Error(code=$!) in opening <$blk2> file.\n";

# each row of BLK2 contains a single row pointer 

$ptr=0;
while(<BLK2>)
{
	$ptr++;
	$value=$_;

	# check if valid pointer index 
	if($value !~ /^\d+$/)
        {
               print STDERR "ERROR($0):
        Wrong row pointer value <$value> at line $ptr in file<$blk2>.\n";
               exit;
        }

	if($ptr!=1 && ($ptr-1) % $rowinds_online == 0)
        {
                print "\n";
        }
	$formatted_rp=sprintf($row_string,$value);
	if($formatted_rp>$upper_rpform)
        {
                print STDERR "ERROR($0):
        Floating point overflow.
        Row pointer <$formatted_rp> can't be represented with format $row_string.\n";
                exit 1;
        }
	print "$formatted_rp";
}

print "\n";

# block3 : non-zero matrix values

open(BLK3,$blk3) || die "Error($0):
        Error(code=$!) in opening <$blk3> file.\n";

# BLK3 stores a single non-zero value per line

$ptr=0;
while(<BLK3>)
{
	$ptr++;
	s/^\s+//;
	s/\s+$//;
	$value=$_;

	# check if valid number
	if($value !~ /^-?\d+\.?\d*$/)
        {
                print STDERR "ERROR($0):
        Wrong non-zero value<$value> at line $ptr in file<$blk3>.\n";
                exit;
        }

	if($ptr!=1 && ($ptr-1) % $nums_online == 0)
        {
                print "\n";
        }
	$formatted_value=sprintf($num_string,$value);

	if($formatted_value<$lower_numform)
        {
                print STDERR "ERROR($0):
        Floating point underflow.
        Value <$formatted_value> can't be represented with format $num_string.\n";
                exit 1;
        }
	if($formatted_value>$upper_numform)
	{
                print STDERR "ERROR($0):
        Floating point overflow.
        Value <$formatted_value> can't be represented with format $num_string.\n";
                exit 1;
	}
	print "$formatted_value";
}

print "\n";

# printing complete !

unlink "$blk1";
unlink "$blk2";
unlink "$blk3";

##############################################################################

#			==============================
#			 Creating Parameter file lap2
#			==============================

# Now, create the paramters

if(defined $opt_param)
{
	if(-e "lap2")
	{
        	print STDERR "Warning($0):
        Parameter file <lap2> already exists, overwrite (y/n)? ";
        	$ans=<STDIN>;
	        if($ans !~ /(y|Y)(es)?/)
        	{
                	undef $opt_param;
        	}
	}

	if(defined $opt_param)	{
		open(PAR,">lap2") || die "Error($0):
				          Error(code=$!) in opening parameter file <lap2>.\n";	

# the need for these warnings is somewhat less now, given that
# we are providing a las2.h file set with fairly large values

#		# the minimum required amt of memory, based on the data we have...
#		$lmtnw_minimum = (6*$cols)+(4*$iter)+1+($iter**2);

#		print STDERR "NOTE($0):
#    		The size of your default work area (LMTNW) in las2.h should be 
#     		greater than $lmtnw_minimum (cols=$cols, iter=$iter).\n";
		
		# the actual value in las2.h for LMTNW is:
		### 900,300,001 

##		if ($lmtnw_minimum >= 900,300,001) { 
##			print STDERR "Warning($0):
##	        	The value of LMTNW in las2.h/SVDPACKC is too small! 
##	        	Please change LMTNW to a value greater than $lmtnw_minimum.\n"; 
##	    	}

			# left and right threshold for e-values
			$endl="-1.0e-30";
			$endr="1.0e-30";
			# allowed tolerance
			$kappa="1.0e-6";
			print PAR "'$id' $iter $maxprs $endl $endr TRUE $kappa 0\n";
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
        print "Usage: mat2harbo.pl [OPTIONS] MATRIX";
        print "\nTYPE mat2harbo.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  mat2harbo.pl [OPTIONS] MATRIX

Converts a given matrix in SenseClusters' sparse format to Harwell-Boeing 
sparse matrix format.

MATRIX
	Matrix in SenseClusters' sparse matrix format that is to be converted
	into Harwell-Boeing sparse matrix format.

OPTIONS:

--title TITLE
	Specify the TITLE to be used for the MATRIX at Line1 of Harwell-Boeing 
	format. Default TITLE uses the MATRIX file name.

--id ID
	Specify the ID to be used to identify the MATRIX at Line1 of Harwell-
	Boeing format. Default ID is 'harbomat'.

--cpform CPFORM
	Specify the Column Pointer FORMat. Default is 10i8. 

--rpform RPFORM
	Specify the Row Pointer FORMat. Default is 10i8.

--numform NUMFORM
	Specify the NUMber FORMat to represent the non-zero MATRIX values.
	Default is 5f16.10.

Parameter Options :

These options help to automatically create the parameter file lap2 used by
the las2.c program in SVDPack.

--param 
	Creates the parameter file lap2 that can be directly used while 
	running las2.

--k K 
	Sets the value of maxprs parameter in lap2 file to K. 
	Default K=300

--rf RF
	Reduces the column space of a given MATRIX by scaling factor RF 
	such that maxprs = #columns(MATRIX) / RF , where RF >=1
	Default RF = 10

	Both --k and --rf allow user to control the maxprs value in lap2 file 
	which specifies the number of singular triplets to be returned by las2.

	If both --k and --rf are specified, maxprs = min(K,#columns(MATRIX)/RF)

--iter ITER
	Specifies number of iterations (or lanmax) in LAP2.
	Default ITER = min((3 * maxprs), #columns(MATRIX))

	ITER should be < = #columns(MATRIX)
	and
	ITER should be > = (maxprs = min(K,#columns(MATRIX)/RF))

--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc mat2harbo.pl' to view detailed documentation of mat2harbo.\n";

}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: mat2harbo.pl,v 1.35 2008/03/31 21:31:13 tpederse Exp $';
##      print "mat2harbo.pl      -       Version 0.4";
	print "\nConvert a matrix in SenseClusters sparse format to Harwell-Boeing sparse format\n";
##        print "\nCopyright (c) 2002-2006, Amruta Purandare & Ted Pedersen\n";
##      print "Date of Last Update:     11/06/2004\n";
}

#############################################################################

=head1 AUTHORS

Amruta Purandare, University of Pittsburgh

Ted Pedersen, University of Minnesota, Duluth
tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2003-2008, Amruta Purandare and Ted Pedersen

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

