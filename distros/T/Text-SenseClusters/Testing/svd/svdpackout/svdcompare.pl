#!/usr/local/bin/perl -w

=head1 NAME

svdcompare.pl - Provide a "fuzzy" diff command for comparing svd output 
to our key 

=head1 SYNOPSIS

Simulates 'diff' system command on numeric matrices allowing some precision 
errors within a given tolerance. This is necessary since the results 
from SVDPACKC can vary somewhat depending on the underlying 
architecture. 

As of 1.09 the tolerance has been hard coded at 10000, meaning that we 
are simply checking to see that output is generated. The differences 
among different architectures seem to cause rather large differences
in results. This is not necessarily a problem, since if you run all 
your experiments on the same system, the SVD values will be consistent 
within that architecture. We would not recommend mixing SVDPACKC output 
from various systems for this reason. 

=head1 USGAE

C<svdcompare.pl MATRIX1 MATRIX2 TOLERANCE>

=head1 INPUT

=head2 MATRIX1 MATRIX2

Should be the matrix files to be compared, formatted like SenseClusters'
standard matrix/vector format. 

=head2 TOLERANCE

Should be a numeric value (integer or float) specifying the tolerance limit. 
Matrix cells at the same locations ([i][j]) in MATRIX1 and MATRIX2 that 
differ by more than the given TOLERANCE will be treated as different. 

=head1 OUTPUT

Output will be blank if no pair of matrix cells appearing at the same 
location in MATRIX1 and MATRIX2 has an absolute difference more than a 
given TOLERANCE.

Following conditions will lead to non-blank output -

1. If the number of rows in the two matrices are different.

2. If ROWi in MATRIX1 has different number of columns than ROWi in MATRIX2.

3. If abs(MATRIX1[i][j]-MATRIX2[i][j]) > TOLERANCE

where abs() shows the absolute function.

Output if displayed will show 

< LI1 

> LI2 

where LI1 is an Ith line in MATRIX1 and LI2 is an Ith line in MATRIX2,
for all lines I where the matrices differ as per the above conditions.

=head1 AUTHORS

 Amruta Purandare, University of Pittsburgh

 Ted Pedersen,  University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2003-2008 Amruta Purandare and Ted Pedersen

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

$file1=$ARGV[0];
$file2=$ARGV[1];
$tolerance=$ARGV[2];

# set this value very high for now, just want to make sure the
# installed program is getting some output - architectural 
# differences seem to cause variation in results. 

$tolerance = 10000;

open(IN1,$file1) || die "Error in opening file <$file1>.\n";
open(IN2,$file2) || die "Error in opening file <$file2>.\n";

while($line1=<IN1>)
{
	$line2=<IN2>;
	if(!defined $line2)
	{
		print STDERR "< $line1";
		print STDERR "> \n";
		next;
	}
        $line1=~s/^\s*//;
        $line1=~s/\s*$//;
	$line2=~s/^\s*//;
        $line2=~s/\s*$//;
	
	@row1=split(/\s+/,$line1);
	@row2=split(/\s+/,$line2);
	if($#row1 != $#row2)
	{
		print STDERR "< $line1";
                print STDERR "> $line2";
		next;
	}
	foreach $i (0..$#row1)
	{
		if($row2[$i]>$row1[$i]+$tolerance || $row2[$i]<$row1[$i]-$tolerance)
		{
			print STDERR "< $line1";
	                print STDERR "> $line2";
			last;
		}
	}
}
while($line2=<IN2>)
{
	print STDERR "< \n";
	print STDERR "> $line2";
}
