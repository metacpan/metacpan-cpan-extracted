#!/usr/local/bin/perl 

=head1 NAME

svdpackout.pl - Reconstruct post-SVD form of matrix from singular values output by SVDPACKC

=head1 SYNOPSIS

 svdpackout.pl [OPTIONS] lav2 lao2

Type C<svdpackout.pl --help> for a quick summary of options

=head1 DESCRIPTION

Reconstructs a matrix from its singular values and singular vectors created
by SVDPACKC. The result of this is essentially a "smoothed" matrix equal 
in size to the original pre-SVDPACKC matrix, but where the  
non-significant dimensions have been removed. 

SVDPACKC decomposes the original input matrix into three matrices :

=over 

=item * U : M x k (rows by k)

=item * S : k x k (k singular values of input matrix stored in a diagonal matrix)

=item * VT : k x N (columns by k, obtained by transposing V : N x k)

=back

where k is the dimension value to which we have reduced the matrix 
(maxprs), M is the number of rows, and N is the number of columns. 

We will normally keep the first k singular values (since those are 
organized greatest to least in S, and represent the most significant 
dimensions in the data). We do this by keeping the first k rows of S 
and VT, and the first k columns of U. 

When we use --rowonly we reconstruct an M x k matrix by taking the 
product U * S. This matrix represents all of our original rows in a 
reduce column/dimension space which is then clustered by Cluto. 

If we don't use --rowonly we reconstruct the original M x N matrix, 
but only using k dimensions (which gives us a kind of smoothing 
effect). That is we take the product (M x k) * (k x k) * (k * N). 
Note that L<discriminate.pl> defaults to using --rowonly reconstration, 
at least in part in the interests of computational efficiently. 

=head1 INPUT

=head2 Required Arguments:

=head3 lav2 

Binary output file created by SVDPACKC las2

=head3 lao2

ASCII output file created by SVDPACK las2

=head2 Optional Arguments:

=head4 --rowonly 

Only the row vectors are reconstructed. By default, svdpackout  
reconstructs entire matrix. This may not be used with --output. 
This is the default setting for L<discriminate.pl>.

=head4 --output OUTPUT

Specifies the form of the output to be written by this program:

  reconstruct - re-constructs the full rank-k matrix, output to STDOUT 
  rowonly - same as --rowonly, output to STDOUT
  components - output the U, S, and VT matrices to U.txt, S.txt, VT.txt

=head4 --sqrt   

In --rowonly reconstruction, take sqrt of S (kxk). This was the 
default method in SenseClusters 1.00 and previous. Has no effect
when used with full reconstruction. Provided mainly for backwards
compatability. 

=head4 --negatives

Set negative values in reconstructed matrices that are between -1 and 0 
to 0 (except in component output). This option is provided mainly for 
backwards compatibility as this was the default behavior in 
SenseClusters 1.00 and previous.

=head4 --format FORM

Specifies numeric format for representing output matrix values. 
Following formats are supported with --format :

 iN - Output matrix will contain integer values each occupying N spaces

 fM.N - Output matrix will contain real values each occupying total M spaces of which last N digits show fractional part. M spaces for each entry include the decimal point and +/- sign if any.

Default format value is f16.10.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

svdpackout.pl displays a matrix reconstructed from the Singular Triplets
created by SVD. By default, entire matrix (product of left and right
singular vectors and singular values) is reconstructed. When --rowonly
is ON, or when --output rowonly is set, only the reduced row vectors
are built. When --output components is set, the three component
matrices, U, S, and V, are output separately.

=head1 SYSTEM REQUIREMENTS

=over

=item SVDPACKC - L<http://netlib.org/svdpack/> (also available in /External)

=item PDL - L<http://search.cpan.org/dist/PDL/>

=back

=head1 BUGS

In version 1.00 and before, we took the square root of the k x k matrix 
before recombining in --rowonly made. We have changed that to make it
an option (via --sqrt), since the motives for that are at this point
unclear. The following discussion originally formulated by Mahesh Joshi
motivates our change to a default method of not taking --sqrt.  

Deerwester et al. (S. Deerwester, S.T. Dumais, G.W. Furnas, T.K. 
Landauer, and R. Harshman. Indexing by latent semantic analysis. Journal 
of the American Society for Information Science, 41:391.407, 1990.), 
give a nice explanation of the reason of combing M x k and k x k to 
evaluate similarity between whatever was represented along the rows in 
the original matrix (contexts in order 1 and features in order 2).

They also mention the use of the combination Mxk and SquareRoot(kxk), 
but that is for evaluating correlation between a term and a document (as 
against between a term-term or document-document pair) and in such a 
case what is also needed is the combination of Nxk and SquareRoot(kxk) 
since in a heterogeneous pair (one term and one document) correlation 
analysis, one vector each is needed from these two different  
combinations. All this is mentioned in the "Technical Details" section 
of the Deerwester et al. paper.

But this does not seem to explain the use of the square root in the type 
of analysis we are doing - which is homogeneous, i.e. we are only 
analyzing term-term or context-context similarities.

In both --rowonly and full reconstruction, we smoothed negative values 
between 0 and -1 to 0. The motive for that is unclear, and so a option 
--negatives is provided to preserve negative values and override that 
behavior. 

We would now generally recommend that svdpackout.pl be run without 
--sqrt and --negatives. That is do not take the square roots of 
the S matrix when doing reconstruction and let negative values stand. 
This is the default behavior as of 1.01 and beyond. 

=head1 AUTHORS

 Amruta Purandare, University of Pittsburgh

 Richard Wicentowski, Swarthmore College
 richardw at cs.swarthmore.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2002-2008, Amruta Purandare, Richard Wicentowski, Ted Pedersen

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

# $0 contains the program name along with the 
# complete path. Extract just the program
# name and use in error messages
$0=~s/.*\/(.+)/$1/;

use PDL;
use PDL::NiceSlice;
use PDL::Primitive;

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version","format=s","output=s","rowonly","negatives","sqrt");

# show help option

if (defined $opt_help) {
  $opt_help=1;
  &showhelp();
  exit;
}

# show version information
if (defined $opt_version) {
  $opt_version=1;
  &showversion();
  exit;
}

#
# output options
#
# check to see if --output is set
# if it is, find out the setting and proceed
# and if it isn't, then check to see if --rowonly is set
# if it is, then set output variable to that
# if it isn't, the do a set output variable to full reconstruction
#

if (defined $opt_output) {
  if ((defined $opt_rowonly) && ($opt_output !~ /rowonly/)) {
    printf ("Incompatible options: --rowonly --output=%s\n", $opt_output);
    &showhelp();
    exit;
  }
  if (($opt_output ne "reconstruct") && 
      ($opt_output ne "rowonly") && 
      ($opt_output ne "components")) {
    printf ("Invalid output format: %s\n", $opt_output);
    &showhelp();
    exit;
  }
} elsif (defined $opt_rowonly) {
  $opt_output="rowonly";
  undef $opt_rowonly;
} else {
  $opt_output="reconstruct";
}

#
# formatting matrix values
#

if (defined $opt_format) {
  # integer format
  if ($opt_format=~/^i(\d+)$/) {
    $format="%$1d";
    $lower_format="-";
    while (length($lower_format)<($1-1)) {
      $lower_format.="9";
    }
    if ($lower_format eq "-") {
      $lower_format="0";
    }
    $upper_format="";
    while (length($upper_format)<($1-1)) {
      $upper_format.="9";
    }
  }
  # floating point format
  elsif ($opt_format=~/^f(\d+)\.(\d+)$/) {
    $format="%$1.$2f";
    $lower_format="-";
    while (length($lower_format)<($1-$2-2)) {
      $lower_format.="9";
    }
    $lower_format.=".";
    while (length($lower_format)<($1-1)) {
      $lower_format.="9";
    }

    $upper_format="";
    while (length($upper_format)<($1-$2-2)) {
      $upper_format.="9";
    }
    $upper_format.=".";
    while (length($upper_format)<($1-1)) {
      $upper_format.="9";
    }
  } else {
    print STDERR "ERROR($0):
	Wrong format value --format=$opt_format.\n";
    exit;
  }
}
# default
else {
  #	$format="%8.3f";
  $format="%16.10f";
  $lower_format="-999.9999999999";
  $upper_format="9999.9999999999";
}

# show minimal usage message if no arguments
if ($#ARGV<1) {
  &showminimal();
  exit;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

# accept lav2 file name
$lav2=$ARGV[0];
if (!-e $lav2) {
  print STDERR "ERROR($0):
        lav2 file <$lav2> doesn't exist...\n";
  exit;
}
open(LAV2,$lav2) || die "Error($0):
        Error(code=$!) in opening lav2 file <$lav2>.\n";

#accept lao2 file name
$lao2=$ARGV[1];
if (!-e $lao2) {
  print STDERR "ERROR($0):
        lao2 file <$lao2> doesn't exist...\n";
  exit;
}
open(LAO2,$lao2) || die "Error($0):
        Error(code=$!) in opening lao2 file <$lao2>.\n";

##############################################################################

#			========================
#			      CODE SECTION
#			========================

# -------------------
# Reading file lao2 
# -------------------
while (<LAO2>) {
  # e-pairs = K, reduction factor specified by the user
  if (/MAX. NO. OF EIGENPAIRS\s*=\s*(\d+)/) {
    $k=$1;
  }
  # rows
  if (/NO\. OF TERMS\s*\(ROWS\)\s*=\s*(\d+)/) {
    $rows=$1;
    next;
  }
  # cols
  if (/NO\. OF DOCUMENTS\s*\(COLS\)\s*=\s*(\d+)/) {
    $cols=$1;
    next;
  }
  # nsig
  if (/NSIG\s*=\s*(\d+)/) {
    $nsig=$1;
    next;
  }
  # after this the S-values follow
  if (/COMPUTED S-VALUES/) {
    last;
  }
}

# check: valid values of rows, cols, k, nsig 
# are obtained from lao2
if (!defined $rows) {
  print STDERR "ERROR($0):
	#ROWS not found in lao2 file <$lao2>.\n";
    exit;
}
if (!defined $cols) {
  print STDERR "ERROR($0):
        #COLS not found in lao2 file <$lao2>.\n";
    exit;
}
if (!defined $nsig) {
  print STDERR "ERROR($0):
        NSIG value not found in lao2 file <$lao2>.\n";
  exit;
}
if (!defined $k) {
  print STDERR "ERROR($0):
        NO. OF EIGENPAIRS not found in lao2 file <$lao2>.\n";
  exit;
}

# one line is blank in lao2 after "COMPUTED S-VALUES..." line
<LAO2>;

$d=zeroes($nsig);
# reading singular values

# singular values are reverse ordered in lao2 
# such that the most significant/highest value 
# occurs last 
for ($i=$nsig-1 ; $i>=0 ; $i--) {
  $line=<LAO2>;
  if (!defined $line) {
    print STDERR "ERROR($0):
	lao2 file <$lao2> doesn't have $nsig S-values.\n";
    exit;
  }
  $line=~s/^\s+//;
  # line containing S-value contains 
  # ellipses, index of S-value, S-value, RES NORMS
  ($ellipses,$ind,$sval,@rest)=split(/\s+/,$line);
  # we only need the S-value
  undef $ellipses;
  undef $ind;
  undef @rest;
  set($d,$i,$sval);
}

# taking minimum of #nsig and k
$k=($k<$nsig) ? $k : $nsig;

# --------------------
# Reading file lav2
# --------------------

# binary file needs to specify
# binmode
binmode LAV2;

# lav2 contains some header information
# before the actual S-vectors

# the header length is length(pack(2l+d))
$longsize=length(pack("l",()));
$doubsize=length(pack("d",()));

# right S-vectors start after header
$vstart=(2*$longsize) + $doubsize;

# left S-vectors start after right S-vectors
$ustart=$vstart+($cols*$nsig*$doubsize);

# printing rows cols on first line 
if ($opt_output eq "reconstruct") {
  print "$rows $cols\n";
} elsif ($opt_output eq "rowonly") {
  print "$rows $k\n";
} elsif ($opt_output eq "components") {
  
}

#
# output components U, S, VT to files
# --negatives has no effect here
# --sqrt does not either (sqrt was only ever taken on --rowonly)
#

if ($opt_output eq "components") {
  print STDERR "Writing to U.txt, S.txt and VT.txt\n";

  open (U, ">U.txt") or die "$!: U.txt\n";
  print U "$rows $k\n";
  for ($i=0;$i<$rows;$i++) {
    for ($m=$nsig-1;$m>=$nsig-$k;$m--) {
      $index=$ustart+((($m*$rows)+$i)*$doubsize);
      seek(LAV2,$index,0);
      read(LAV2,$value,$doubsize);
      if (!defined $value) {
	print STDERR "ERROR($0):
	lav2 file <$lav2> doesn't have sufficient S-vectors.\n";
	exit;
      }
      #unpacking
      $value=unpack("d",$value);
      printf U ($format, $value);
    }
    print U "\n";
  }
  close(U);

  open (S, ">S.txt") or die "$!: S.txt\n";
  print S "$k $k\n";
  for ($i=0 ; $i<$k ; $i++) {
    for ($j=0; $j<$i ; $j++) { printf S ($format, 0); }
    printf S ($format, $d->at($i));
    for ($j=$i+1; $j<$k ; $j++) { printf S ($format, 0); }
    print S "\n";
  }
  close(S);

  open (VT, ">VT.txt") or die "$!: VT.txt\n";
  print VT "$k $cols\n";
  for ($j=0;$j<$cols;$j++) {
    for ($m=$nsig-1;$m>=$nsig-$k;$m--) {
      $index=$vstart+((($m*$cols)+$j)*$doubsize);
      seek(LAV2,$index,0);
      read(LAV2,$value,$doubsize);
      if (!defined $value) {
	print STDERR "ERROR($0):
        lav2 file <$lav2> doesn't have sufficient S-vectors.\n";
	exit;
      }
      # unpacking
      $value = unpack("d", $value);
      printf VT ($format, $value);
    }
    print VT "\n";
  }
  close(VT);

  exit;
} 

#
# reconstruct full matrix, U*S*VT, with only k dimensions,
# (M x k) * (k x k) * (k x N) => M x N (smoothed)
#

elsif ($opt_output eq "reconstruct") {
  $u=zeroes($k);
  $v=zeroes($k);
  for ($i=0;$i<$rows;$i++) {
    $u->inplace->zeroes;
    for ($m=$nsig-1;$m>=$nsig-$k;$m--) {
      $index=$ustart+((($m*$rows)+$i)*$doubsize);
      seek(LAV2,$index,0);
      read(LAV2,$value,$doubsize);
      if (!defined $value) {
	print STDERR "ERROR($0):
	lav2 file <$lav2> doesn't have sufficient S-vectors.\n";
	exit;
      }
      #unpacking
      $value=unpack("d",$value);
      set($u,$nsig-1-$m,$value);
    }
    for ($j=0;$j<$cols;$j++) {
      $v->inplace->zeroes;
      for ($m=$nsig-1;$m>=$nsig-$k;$m--) {
	$index=$vstart+((($m*$cols)+$j)*$doubsize);
	seek(LAV2,$index,0);
	read(LAV2,$value,$doubsize);
	if (!defined $value) {
	  print STDERR "ERROR($0):
        lav2 file <$lav2> doesn't have sufficient S-vectors.\n";
	  exit;
	}
        # unpacking
	$value = unpack("d", $value);
	set($v,$nsig-1-$m,$value);
      }
      $recon=$u * $d(0:$k-1) x transpose $v;
      $number=sprintf($format,$recon->sclr);

      # if --negatives is on, then values between -1 and 0 are set to 0
      	
      if ((defined $opt_negatives) && ($number=~/\-(0.)?0+/)) { $number=0; }

      if ($number<$lower_format) {
	print STDERR "ERROR($0):
        Floating point underflow.
        Value <$number> can't be represented with format $format.\n";
	exit 1;
      }
      if ($number>$upper_format) {
	print STDERR "ERROR($0):
        Floating point overflow.
        Value <$number> can't be represented with format $format.\n";
	exit 1;
      }
      printf($format,$number);
    }
    print "\n";
  }
}

#
# recontruct only row vectors 
#

elsif ($opt_output eq "rowonly") {

  for ($i=0;$i<$rows;$i++) {	
    for ($j=$nsig-1;$j>=$nsig-$k;$j--) {

      # computing index of each value from beginning of file

      $index = $ustart+((($j*$rows)+$i)*$doubsize);
      seek(LAV2,$index,0);
      read(LAV2,$value,$doubsize);
      if (!defined $value) {
	print STDERR "ERROR($0):
        lav2 file <$lav2> doesn't have sufficient left S-vectors.\n";
	exit;
      }
      # unpacking

      $value = unpack("d", $value);

	# if the sqrt option is turned on, then take the
	# square root of the kxk matrix when building the
	# --row-only reconstruction

	# see discussion in bugs about this issue

      if (defined $opt_sqrt) { 

	      $recon = $value * sqrt at($d,$nsig-1-$j);
     	 } 
      else {
	      $recon = $value * at($d,$nsig-1-$j);
	}

      $number=sprintf($format,$recon);

      # if --negatives is on, then values between -1 and 0 are set to 0

      if ((defined $opt_negatives) && ($number=~/\-(0.)?0+/)) { $number=0; }

      if ($number<$lower_format) {
	print STDERR "ERROR($0):
        Floating point underflow.
        Value <$number> can't be represented with format $format.\n";
	exit 1;
      }
      if ($number>$upper_format) {
	print STDERR "ERROR($0):
        Floating point overflow.
        Value <$number> can't be represented with format $format.\n";
	exit 1;
      }
      printf($format,$number);
    }
    print "\n";
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
    print "Usage: svdpackout.pl [OPTIONS] LAV2 LAO2";
    print "\nTYPE svdpackout.pl --help for help\n";
  }

#-----------------------------------------------------------------------------
#show help
sub showhelp()
  {
    print "Usage:  svdpackout.pl [OPTIONS] LAV2 LAO2 

Reconstructs a rank-k matrix from output files LAV2 and LAO2 created by las2 
program of SVDPack.

LAV2
	Binary output file created by las2
	
LAO2
	ASCII output file created by las2

OPTIONS:

--rowonly 
	Reconstructs only row vectors, output to STDOUT. May not be 
	used with --output 

--output OUTPUT
        reconstruct - reconstructs the rank-k matrix, output to STDOUT
	rowonly - same as --rowonly, output to STDOUT 
        components - output U, S, VT matrices to U.txt, S.txt, VT.txt

--sqrt   
	In --rowonly reconstruction, take square root of S (k x k). 
	This was the default in SenseClusters 1.02 and previous. 
	
--negatives
        Sets all negative values in reconstructed matrix to 0 (except 
	in component output). This was the default in SenseClusters 
	1.00 and previous.

--format FORM
	Specifies the format for displaying output matrix. Default is f16.10.

--help
        Displays this message.
--version
        Displays the version information.

Type 'perldoc svdpackout.pl' to view detailed documentation of svdpackout.\n";
  }

#------------------------------------------------------------------------------
#version information
sub showversion()
  {
#        print "svdpackout.pl      -       Version 0.04\n";
        print '$Id';
        print "\nReconstruct a rank-k matrix from output of SVDPACKC\n";
#        print "Copyright (c) 2002-2005, Amruta Purandare & Ted Pedersen.\n";
#        print "Date of Last Update:     06/02/2004\n";
}

#############################################################################

