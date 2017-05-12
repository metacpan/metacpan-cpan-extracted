#!/usr/local/bin/perl -w

=head1 NAME

split-data.pl - Divide a text file in N approximately equal parts

=head1 SYNOPSIS

Splits a given data file into N parts such that each part has approximately 
same number of lines.

=head1 USAGE

split-data.pl [Options] DATA

Type 'split-data.pl --help' for a quick summary of the Options.

=head1 INPUT

=head2 Required Arguments:

=head3 DATA

DATA should be a file in plain text format such that each line in the DATA 
file shows a single training example.

=head2 Optional Arguments:

=head4 --parts N

Splits the DATA file into N equal parts. If the DATA file has M lines, 
each part except the last part will have int(M/N) lines while the 
last part will have all the remaining lines, M - (N-1 * (int(M/N))).

Default N is 10.

=head3 Other Options :

=head4 --help

Displays the quick summary of options.

=head4 --version

Displays the version information.

=head1  OUTPUT

split-data.pl creates exactly N files in the current directory. If the name
of the DATA file is say DATA-file, then the N files will have names as 
DATA-file1, DATA-file2, DATA-file3,... DATA-fileN. e.g. If the DATA filename 
is ANC, then the N files created by split-data.pl will have names like 
ANC1, ANC2, ..., ANCN. 

A DATA file containing total M lines is split into N parts such that 
each part/file contains approximately M/N lines.

Thus, if N = 1, the output file will be exactly same as the given DATA file.
If N = M where N = value of --parts and M = #lines in DATA then,
each part will have a single line.

=head1 AUTHOR

Amruta Purandare, Ted Pedersen.
University of Minnesota, Duluth.

=head1 COPYRIGHT

Copyright (c) 2004,

Amruta Purandare, University of Minnesota,
Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota,
Duluth.
tpederse@umn.edu

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

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version","parts=i");

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

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
# show minimal usage message if required arguments not specified
if($#ARGV<0)
{
        &showminimal();
        exit;
}


###############################################################################

#			============================
#			    Initialisation Section
#			============================

if(!defined $ARGV[0])
{
	print STDERR "ERROR($0):
	Required argument DATA file is not specified.\n";
	exit;
}

$datafile=$ARGV[0];

if(! -e $datafile)
{
    print STDERR "ERROR($0):
        DATA file <$datafile> does not exist.\n";
    exit;
}

open(IN,$datafile) || die "Error (code=$!) in opening DATA file <$datafile>.\n";

if(!defined $opt_parts)
{
        $opt_parts=10;
}

##############################################################################

#			==========================
#			       CODE SECTION
#			==========================

# find total number of lines in data file

$total=0;
while(<IN>)
{
	$total++;
}

seek(IN,0,0);

# parts > total

if($opt_parts > $total)
{
	print STDERR "ERROR($0):
	Can not divide DATA file <$datafile> with $total lines into $opt_parts parts.\n";
	exit;
}

$part=1;
$lines=0;

$partfile=$datafile . $part;
if(-e $partfile)
{
        print STDERR "Warning($0):
        Output file <$partfile> already exists, overwrite ?\n";
        $ans=<STDIN>;
}
if(!-e $partfile || $ans=~/[yY]([eE][sS])?/)
{
        open(PART, ">$partfile") || die "Error(code=$!) in opening output file <$partfile>.\n";
}
else
{
	exit;
}

while(<IN>)
{
	$dataline=$_;
	if($lines < int($total/$opt_parts) || $part==$opt_parts)
	{
		print PART $dataline;
		$lines++;
	}
	else
	{
		$part++;
		$lines=0;
		$partfile=$datafile . $part;
                if(-e $partfile)
                {
                        print STDERR "Warning($0):
        Output file <$partfile> already exists, overwrite ?\n";
                        $ans=<STDIN>;
                }
                if(!-e $partfile || $ans=~/[yY]([eE][sS])?/)
                {
                        open(PART, ">$partfile") || die "Error(code=$!) in opening output file <$partfile>.\n";
                }
                else
                {
                        exit;
                }
                print PART $dataline;
                $lines++;
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
	print "Usage: split-data.pl [Options] DATA\n";
	print "Type 'split-data.pl --help' for summary of the Options.\n";
	print "Type 'perldoc split-data.pl' for detailed description of split-data.pl\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage: split-data.pl [Options] DATA";
	print "
Splits a given DATA file into N parts, each containing approximately same 
number of lines.

Required parameters:

DATA
	A data file in plain text format containing a single training instance
	on each line.

Optional Parameters:

--parts N
	Splits the DATA file into N parts. Default is 10.
--help
        Displays this message.
--version
        Displays the version information.

Documentation :
---------------
See perldoc page of split-data.pl for detailed documentation.\n";

}
#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "split-data.pl      -       Version 0.01";
        print "
Splits a given DATA file into N parts.\n"; 
        print "Copyright (C) 2004, Amruta Purandare, Ted Pedersen.\n";
        print "Date of Last Update:     2/22/2004\n";
}

#############################################################################

