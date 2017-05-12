#!/usr/local/bin/perl -w

=head1 NAME

bitsimat.pl - Build a similarity matrix from binary context vectors

=head1 SYNOPSIS

 bitsimat.pl [OPTIONS] VECTOR

The input file represents 5 vectors, each with 4 possible features. The
format of the input file is sparse, so if a feature has no value it is
not listed.

 cat input

Output =>

 5 4 12
 1 1 3 1 4 1
 2 1 3 1
 1 1 3 1 4 1
 2 1 3 1
 2 1 3 1

Compute the pairwise similarities between all 5 binary vectors and 
display them in a 5x5 matrix.

 bitsimat.pl input --format f4.2

Output =>

 5 25
 1 1.00 2 0.41 3 1.00 4 0.41 5 0.41
 1 0.41 2 1.00 3 0.41 4 1.00 5 1.00
 1 1.00 2 0.41 3 1.00 4 0.41 5 0.41
 1 0.41 2 1.00 3 0.41 4 1.00 5 1.00
 1 0.41 2 1.00 3 0.41 4 1.00 5 1.00

Type C<bitsimat.pl --help> for a quick summary of options

=head1 DESCRIPTION

Constructs a similarity matrix for the given binary context vectors. A 
similarity matrix shows the pairwise similarities between all the 
different vectors. Vectors are represented in an N x M matrix, where N 
is the number of vectors and M is the number of features. All NxN
combinations of vector pairs will be measured for similarity and stored 
in a matrix. 

=head1 INPUT

=head2 Required Arguments:

=head3 VECTOR

A binary vector file as created by vector constructor programs in Toolkit/vector. 

=head4 Sparse Format (default)

By default, VECTOR is assumed to be in sparse format.

For sparse vectors, the first line of the VECTOR file should show 3
numbers separated in spaces as -

 N M NNZ

where

 N = Number of vectors/rows 
 M = Number of dimensions/columns
 NNZ = Total number of non-zero values

Each line after this line should show a single sparse vector on each line.
A sparse vector is a list of pairs of numbers separated by space such
that the first number in a pair is the column index of a non-zero value in the
vector and the second number is the non-zero value itself corresponding to
that index. bitsimat treats all non-zero values as 1s in the bit vectors.

Column indices start with 1.

Sample Sparse Input

 9 12 19
 4 1 7 1
 1 1
 1 1 4 1 8 1 11 1
 1 1 7 1
 4 1
 5 1 10 1
 1 1
 5 1 8 1 12 1
 1 1 2 1 8 1

Explanation :

=over

=item 1. 

The first line shows that there are total 9 sparse vectors 
represented in 12 dimensions. Hence, bitsimat will consider next 9 lines
in the VECTOR file as 9 sparse vectors and will allow the column indices
only in the range [1-12]. Here, the total non-zero values are 19.

=item 2. 

Note that, each line shows a single sparse vector as a list of 
space separated 'index value' pairs. e.g. 2nd line shows that the 1st 
vector is non-zero (with value 1) at column indices 4 and 7. 3rd line shows
that the 2nd sparse vector is non-zero only at index 1. And so on ...

=back

=head4 Dense Format

If VECTOR uses dense format, switch --dense should be selected.

The 1st line in the dense VECTOR file should show -

N M

for N vectors represented using M columns.

Each line thereafter should show a single dense vector.
All dense vectors should have M space separated numbers that indicate the 
values at the corresponding columns in the vector.

All non-zero values are treated as 1s in the binary vectors.

Sample Dense Input

 9 12
 0 0 0 1 0 0 1 0 0 0 0 0
 1 0 0 0 0 0 0 0 0 0 0 0
 1 0 0 1 0 0 0 1 0 0 1 0
 1 0 0 0 0 0 1 0 0 0 0 0
 0 0 0 1 0 0 0 0 0 0 0 0
 0 0 0 0 1 0 0 0 0 1 0 0
 1 0 0 0 0 0 0 0 0 0 0 0
 0 0 0 0 1 0 0 1 0 0 0 1
 1 1 0 0 0 0 0 1 0 0 0 0

shows same vectors as shown in Sample Sparse Input in dense format.

VECTOR file could also optionally show the KEY file name on the first line.
If the VECTOR file starts with the <keyfile> name on the 1st line, the above
information should begin from the 2nd line onwards.

=head2 Optional Arguments:

=head4 --dense

This switch should be selected if the given VECTORs are in dense format. 
This will also create the output similarity matrix in the dense format. By
default, sparse format is assumed for both input vectors and output
similarity matrix.

=head4 --measure SIM

Specify the similarity measure to be used to construct the similarity matrix.

Possible option values for --sim are  

	match			Match Coefficient
	dice			Dice Coefficient
	overlap			Overlap Coefficient
	jaccard			Jaccard Coefficient
	cosine			Cosine Coefficient

The following table shows how the similarity values are computed by each 
of these measures. 

	match		  	|intersection(X,Y)|
	dice			2*|intersection(X,Y)|/(|X|+|Y|)
	overlap			|intersection(X,Y)|/(min(|X|,|Y|))
	jaccard			|intersection(X,Y)|/|union(X,Y)|
	cosine			|intersection(X,Y)|/sqrt(|X|*|Y|)

where X and Y represent any two binary vectors
|X| shows the norm or number of bits set in vector X

=head4 --format FORM

Specifies numeric format for representing output similarity values.

Possible values of FORM are

 iN   -> integer format allocating total N bytes/digits for each entry

 fN.M -> floating point format allocating total N bytes/digits for each entry of which last M digits show the fractional part.

For matching coefficient, default is i8 and for other measures, default is
f16.10.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

If the input VECTORs are in sparse format (default), output is also created
in sparse format, while, if the input vectors are in dense format, output
is also in dense format.

=head2 Sparse Output (Default)

The 1st line in the sparse output shows 2 space separated numbers -

 N NNZ1

where

 N = Number of vectors (same as the N in the VECTOR file)
 NNZ1 = Number of non-zero entries in the output similarity matrix

Each line after this will show the corresponding row of the 
similarity matrix in sparse format. Specifically, each i'th line after the 
above line shows the list of 'j SIM' pairs separated by space such that 
SIM is the non-zero similarity value between the i'th and j'th vectors in the 
given VECTOR file.

Note that, only those pairs are listed in which the SIM value is non-zero.

Sample Sparse Output

 9 43
 1 1.000 3 0.354 4 0.500 5 0.707
 2 1.000 3 0.500 4 0.707 7 1.000 9 0.577
 1 0.354 2 0.500 3 1.000 4 0.354 5 0.500 7 0.500 8 0.289 9 0.577
 1 0.500 2 0.707 3 0.354 4 1.000 7 0.707 9 0.408
 1 0.707 3 0.500 5 1.000
 6 1.000 8 0.408
 2 1.000 3 0.500 4 0.707 7 1.000 9 0.577
 3 0.289 6 0.408 8 1.000 9 0.333
 2 0.577 3 0.577 4 0.408 7 0.577 8 0.333 9 1.000

Shows the actual full similarity matrix -

 9
 1.000 0.000 0.354 0.500 0.707 0.000 0.000 0.000 0.000
 0.000 1.000 0.500 0.707 0.000 0.000 1.000 0.000 0.577
 0.354 0.500 1.000 0.354 0.500 0.000 0.500 0.289 0.577
 0.500 0.707 0.354 1.000 0.000 0.000 0.707 0.000 0.408
 0.707 0.000 0.500 0.000 1.000 0.000 0.000 0.000 0.000
 0.000 0.000 0.000 0.000 0.000 1.000 0.000 0.408 0.000
 0.000 1.000 0.500 0.707 0.000 0.000 1.000 0.000 0.577
 0.000 0.000 0.289 0.000 0.000 0.408 0.000 1.000 0.333
 0.000 0.577 0.577 0.408 0.000 0.000 0.577 0.333 1.000

Both these matrices show the pairwise cosine similarities among the same 9 
vectors shown in the Sample Sparse and Dense Input sections.

=head2 Dense Output

If --dense is selected, output is created in dense format and shows all 
similarity values including 0s.

Dense output shows the number of vectors (N) on the first line. Each i'th line 
after this shows N space separated numbers such that a number at column 
index j shows the pairwise similarity among the i'th and j'th vectors.

Sample Dense Output

 9
 1.000 0.000 0.354 0.500 0.707 0.000 0.000 0.000 0.000
 0.000 1.000 0.500 0.707 0.000 0.000 1.000 0.000 0.577
 0.354 0.500 1.000 0.354 0.500 0.000 0.500 0.289 0.577
 0.500 0.707 0.354 1.000 0.000 0.000 0.707 0.000 0.408
 0.707 0.000 0.500 0.000 1.000 0.000 0.000 0.000 0.000
 0.000 0.000 0.000 0.000 0.000 1.000 0.000 0.408 0.000
 0.000 1.000 0.500 0.707 0.000 0.000 1.000 0.000 0.577
 0.000 0.000 0.289 0.000 0.000 0.408 0.000 1.000 0.333
 0.000 0.577 0.577 0.408 0.000 0.000 0.577 0.333 1.000

Shows the pairwise similarities among the 9 vectors shown in the Sample
Dense Input section.

Note that the similarity matrix will always be square and symmetric.

If the first line of the input VECTOR file shows the <keyfile> tag, 
bitsimat.pl will display the same <keyfile> tag on the first line of 
output.

=head1 SYSTEM REQUIREMENTS

bitsimat is dependent on the following CPAN modules :

=over

=item Bit::Vector - L<http://search.cpan.org/dist/Bit-Vector/>

=item Set::Scalar - L<http://search.cpan.org/dist/Set-Scalar/>

=back


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

use Bit::Vector;
use Set::Scalar;

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
GetOptions ("help","version","measure=s","format=s","dense");
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

if(!defined $opt_measure)
{
        $opt_measure="cosine";
}
if($opt_measure !~ /(mat(ch)?)|(cos(ine)?)|(jac(card)?)|(dice)|(over(lap)?)/)
{
        print STDERR "ERROR($0):
        Wrong value of --measure=$opt_measure\n";
        exit;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the Vector file name...\n";
        exit;
}
#accept the input file name
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Vector file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening <$infile> file.\n";

# format for printing output
if(defined $opt_format)
{
        # integer
        if($opt_format=~/^i(\d+)$/)
        {
                $format="%$1d";
		# as no sim. measure takes -ve value
		# no need to check for underflow
		$upper_format="";
                while(length($upper_format)<($1-1))
                {
                        $upper_format.="9";
                }
        }
        # float
        elsif($opt_format=~/^f(\d+)\.(\d+)$/)
        {
                $format="%$1\.$2f";
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
# default 
else
{
	# i8 for match
	if($opt_measure=~/mat/)
	{
		$format="%8d";
		$upper_format="9999999";
	}
	# f16.10 for other measures
	else
	{
	        $format="%16.10f";
		$upper_format="9999.9999999999";
	}
}


##############################################################################

#			  ==========================
#			   	 CODE SECTION
#			  ==========================

if(defined $opt_dense)
{
	$line_num=0;
	while(<IN>)
	{
		$line_num++;
	        # trimming extra spaces
        	chomp;
	        s/\s*$//g;
        	s/^\s*//g;
	        s/\s+/ /g;
		# line 1 should show either KEY file or rows cols
		if($line_num==1)
		{
			$line=$_;
			if(/keyfile/)
			{
				# when input starts with <keyfile> tag
				# output displays same on the 1st line
				print "$_\n";
				$line=<IN>;
				$line_num++;
			}
			if($line=~/^\s*(\d+)\s+(\d+)\s*$/)
			{
				$rows=$1;
				$cols=$2;
				print "$rows\n";
			}
			else
			{
				print STDERR "ERROR($0):
	Line $line_num in Vector file <$infile> should show the number of rows
	and columns.\n";
				exit;
			}
			next;
		}
		# each vector should have exactly specified number of elements
		@row_ele=split(/\s+/);
		if(scalar(@row_ele) != $cols)
		{
			print STDERR "ERROR($0):
        Line $line_num in Vector file <$infile> should show $cols number of
        elements.\n";
        	        exit;
		}
		# loading a bit vector
		$vector=Bit::Vector->new($cols);
		foreach $ind (0..$#row_ele)
		{
			if($row_ele[$ind] != 0)
			{
				$vector->Bit_On($ind);
			}
		}
		push @vectors,$vector;
	}

	# number of vectors should be same as the number specified earlier at 
	# line 1 or 2
	if(scalar(@vectors) != $rows)
	{
		print STDERR "ERROR($0):
	Vector file <$infile> doesn't contain $rows number of vectors.\n";
		exit;
	}

	# computing similarity measure between each pair of vectors
	foreach $i (0..$rows-1)
	{
		foreach $j (0..$rows-1)
		{
			if($i != $j)
			{
				$inter=Bit::Vector->new($cols);
				$inter->And($vectors[$i],$vectors[$j]);
				$inter_size=$inter->Norm();
				if($opt_measure =~ /^mat(ch)?$/)
				{
					$sim=$inter_size;
				}
				elsif($opt_measure =~ /^dice$/)
				{
					$sim=(2*$inter_size)/($vectors[$i]->Norm()+$vectors[$j]->Norm());
				}
				elsif($opt_measure =~ /^jac(card)?$/)
				{
					$union=Bit::Vector->new($cols);
					$union->Union($vectors[$i],$vectors[$j]);
					if($union->Norm()!=0)
					{
						$sim=($inter_size)/($union->Norm());
					}
					else
					{
						$sim=0;
					}
				}
				elsif($opt_measure =~ /^over(lap)?$/)
				{
					$size1=$vectors[$i]->Norm();
					$size2=$vectors[$j]->Norm();
					$min=($size1 < $size2) ? $size1 : $size2;
					$sim=($inter_size)/$min;
				}
				elsif($opt_measure =~ /^cos(ine)?$/)
				{
					$size1=$vectors[$i]->Norm();
	                	        $size2=$vectors[$j]->Norm();
					$denom=sqrt($size1*$size2);
					if($denom != 0)
					{
						$sim=($inter_size)/$denom;
					}
					else
					{
						$sim=0;
					}
				}
			}
			else
			{
				if($vectors[$i]->Norm())
				{
					$sim=1;
				}
				else
				{
					$sim=0;
				}
			}
			$value=sprintf $format, $sim;
			if($value>$upper_format)
			{
				print STDERR "ERROR($0):
        Floating point overflow.
        Value <$value> can't be represented with format $format.\n";
	                        exit 1;
			}
			print $value;
		}
		print "\n";
	}
}
else
{
	$line_num=1;
	$line=<IN>;
	if($line=~/keyfile/)
	{
		print "$line";
		$line=<IN>;
		$line_num++;
	}
	if($line=~/^\s*(\d+)\s+(\d+)\s+(\d+)\s*$/)
	{
		$rows=$1;
		$cols=$2;
		$nnz1=$3;
	}
	else
	{
		print STDERR "ERROR($0):
	Line$line_num in Vector file <$infile> should show #rows #cols #nnz.\n";
		exit;
	}
	$nnz=0;
	while(<IN>)
	{
		$line_num++;
		chomp;
		s/^\s*//;
		s/\s*$//;
		s/\s+/ /;
		$set=Set::Scalar->new;
		@pairs=split;
		for($i=0;$i<$#pairs;$i=$i+2)
		{
			$index=$pairs[$i];
			if($index>$cols)
			{
				print STDERR "ERROR($0):
	Index <$index> at line <$line_num> in VECTOR file <$infile> 
	exceeds #cols = <$cols> specified in the header line.\n";
				exit;
			}
			$value=$pairs[$i+1];
			if($value==0)
			{
				print STDERR "ERROR($0):
	0 value found in sparse vector at line <$line_num> in VECTOR file
	<$infile>.\n";
				exit;
			}
			# add index to set
			$set->insert($index);
			$nnz++;
		}
		push @vectors,$set;
	}
	close IN;
	if(scalar(@vectors) != $rows)
	{
		print STDERR "ERROR($0):
	#rows = $rows specified in the header line of the VECTOR file <$infile>
	does not match the actual #rows = " . scalar(@vectors) . " found in the file.\n";
		exit;
	}
	if($nnz != $nnz1)
	{
		print STDERR "ERROR($0):
	#nnz = $nnz1 specified in the header line of the VECTOR file <$infile>
	does not match the actual #nnz = $nnz found in the file.\n";
		exit;
	}

	# writing output to a TEMP file
	$tempfile="tempfile" . time() . ".tmp";
	if(-e $tempfile)
	{
		print STDERR "ERROR($0):
	Temporary file <$tempfile> should not already exist.\n";
		exit;
	}
	open(TEMP,">$tempfile") || die "Error($0):
        Error(code=$!) in opening tempfile <$tempfile>.\n";

	$nnz=0;
	foreach $i (0..$#vectors)
	{
		foreach $j (0..$#vectors)
		{
			undef $simcount;
			if($i==$j && (!$vectors[$i]->is_null))
			{
				$simcount=1;
			}
			else
			{
				$s=$vectors[$i];
				$t=$vectors[$j];
				# checking for null vectors
                        	if((!$s->is_null) || (!$t->is_null))
                        	{
	                                $inter_st=$s->intersection($t);
        	                        # match coefficient
					if($opt_measure =~ /mat/)
                        	        {
						# match = |(s,t)|
                                        	$simcount=$inter_st->size;
	                                }
					# dice
                	                elsif($opt_measure =~ /dic/)
                        	        {
                                	        $sum_st=$s->size+$t->size;
                                        	# dice = 2* |(s,t)|/(|s|+|t|)
	                                        $simcount=(2*$inter_st->size)/$sum_st;
        	                        }
					# jaccard
                        	        elsif($opt_measure =~ /jac/)
                                	{
	                                        $union_st=$s->union($t);
        	                                # jaccard = |(s,t)|/(|sUt|)
                	                        $simcount=($inter_st->size)/($union_st->size);
                        	        }
					# overlap
	                                elsif($opt_measure =~ /ove?r/)
        	                        {
                	                         # overlap = |(s,t)|/min(|s|,|t|)
                        	                 $min_st=($s->size<$t->size) ? $s->size:$t->size;
                                	         if($min_st!=0)
                                        	 {
	                                               $simcount=($inter_st->size)/$min_st;
        	                                 }
                	                }
					# cosine
		                        elsif($opt_measure =~ /cos/)
                 	                {
                        	                if((!$s->is_null) && (!$t->is_null))
                                        	{
                                                	$denom=sqrt(($s->size)*($t->size));
	                                                # cosine = |(s,t)|/sqrt(|s|*|t|)
        	                                        $simcount=($inter_st->size)/$denom;
                	                        }
                        	        }
				}
			}
			if(defined $simcount && $simcount != 0)
			{
				$value=sprintf $format, $simcount;
				print TEMP "" . ($j+1) ." $value ";
				$nnz++;
			}
		}
		print TEMP "\n";
	}
	
	close TEMP;
        open(TEMP,$tempfile) || die "Error($0):
        Error(code=$!) in opening tempfile <$tempfile>.\n";
	
	# printing to stdout
	print "$rows $nnz\n";
	while(<TEMP>)
	{
		print;
	}
	close TEMP;
	unlink "$tempfile";
}

undef $opt_dense;

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: bitsimat.pl [OPTIONS] VECTOR";
        print "\nTYPE bitsimat.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  bitsimat.pl [OPTIONS] VECTOR 

Constructs a similarity matrix for given binary context vectors.

VECTOR
	A file containing binary context vectors.

OPTIONS:

--dense 
	Should be selected if the given VECTORs are in dense format. By default,
	sparse format is assumed.

--measure SIM
	Specify a measure of similarity to be used for creating similarity
	matrix. Possible option values for --measure are 

	match		Match Coefficient
	dice		Dice Coefficient
	overlap		Overlap Coefficient
	jaccard		Jaccard Coefficient
	cosine		Cosine Coefficient

--format FORM
	Specifies numeric format for representing output similarity values.
	Default format for match coefficient is i8. For other measures,
	default is f16.10.

--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc bitsimat.pl' to view detailed documentation of bitsimat.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
#        print "bitsimat.pl      -       Version 0.04\n";
	print '$Id';
        print "\nConstructs a similarity matrix from binary context vectors\n";
#        print "Copyright (c) 2002-2005, Amruta Purandare, Ted Pedersen.\n";
#        print "Date of Last Update:     06/01/2004\n";
}

#############################################################################

