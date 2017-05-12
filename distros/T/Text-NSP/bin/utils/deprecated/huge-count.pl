#!/usr/local/bin/perl -w

=head1 NAME

huge-count.pl - Divide huge text into pieces and run count.pl separately on each (and then combine)

=head1 SYNOPSIS

Runs count.pl efficiently on a huge data.

=head1 USGAE

huge-count.pl [OPTIONS] DESTINATION [SOURCE]+

=head1 INPUT

=head2 Required Arguments:

=head3 [SOURCE]+

Input to huge-count.pl should be a -

=over

=item 1. Single plain text file

Or

item 2. Single flat directory containing multiple plain text files

Or

=item 3. List of multiple plain text files

=back

=head3 DESTINATION

A complete path to a writable directory to which huge-count.pl can write all 
intermediate and final output files. If DESTINATION does not exist, 
a new directory is created, otherwise, the current directory is simply used
for writing the output files. 

NOTE: If DESTINATION already exists and if the names of some of the existing 
files in DESTINATION clash with the names of the output files created by 
huge-count, these files will be over-written w/o prompting user. 

=head2 Optional Arguments:

=head4 --split P

This option should be specified when SOURCE is a single plain file. huge-count
will divide the given SOURCE file into P (approximately) equal parts, 
will run count.pl separately on each part and will then recombine the bigram 
counts from all these intermediate result files into a single bigram output 
that shows bigram counts in SOURCE.

If SOURCE file contains M lines, each part created with --split P will 
contain approximately M/P lines. Value of P should be chosen such that
count.pl can be efficiently run on any part containing M/P lines from SOURCE.
As #words/line differ from files to files, it is recommended that P should
be large enough so that each part will contain at most million words in total.

=head4 --token TOKENFILE

Specify a file containing Perl regular expressions that define the tokenization
scheme for counting. This will be provided to count.pl's --token option.

--nontoken NOTOKENFILE

Specify a file containing Perl regular expressions of non-token sequences 
that are removed prior to tokenization. This will be provided to the 
count.pl's --nontoken option.

--stop STOPFILE

Specify a file of Perl regex/s containing the list of stop words to be 
omitted from the output BIGRAMS. Stop list can be used in two modes -

AND mode declared with '@stop.mode = AND' on the 1st line of the STOPFILE

or

OR mode declared using '@stop.mode = OR' on the 1st line of the STOPFILE.

In AND mode, bigrams whose both constituent words are stop words are removed
while, in OR mode, bigrams whose either or both constituent words are 
stopwords are removed from the output.

=head4 --window W

Tokens appearing within W positions from each other (with at most W-2 
intervening words) will form bigrams. Same as count.pl's --window option.

=head4 --remove L

Bigrams with counts less than L in the entire SOURCE data are removed from
the sample. The counts of the removed bigrams are not counted in any 
marginal totals. This has same effect as count.pl's --remove option.

=head4 --frequency F

Bigrams with counts less than F in the entire SOURCE are not displayed. 
The counts of the skipped bigrams ARE counted in the marginal totals. In other
words, --frequency in huge-count.pl has same effect as the count.pl's 
--frequency option.

=head4 --newLine

Switches ON the --newLine option in count.pl. This will prevent bigrams from 
spanning across the lines.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 PROGRAM LOGIC

=over 

=item * STEP 1

 # create output dir
 if(!-e DESTINATION) then 
 mkdir DESTINATION;

=item * STEP 2

=over 4

=item 1. If SOURCE is a single plain file -

Split SOURCE into P smaller files (as specified by --split P). 
These files are created in the DESTINATION directory and their names are 
formatted as SOURCE1, SOURCE2, ... SOURCEP.

Run count.pl on each of the P smaller files. The count outputs are also 
created in DESTINATION and their names are formatted as SOURCE1.bigrams,
SOURCE2.bigrams, .... SOURCEP.bigrams.

=item 2. SOURCE is a single flat directory containing multiple plain files -

count.pl is run on each file present in the SOURCE directory. All files in
SOURCE are treated as the data files. If SOURCE contains sub-directories,
these are simply skipped. Intermediate bigram outputs are written in
DESTINATION.

=item 3. SOURCE is a list of multiple plain files -

If #arg > 2, all arguments specified after the first argument are considered
as the SOURCE file names. count.pl is separately run on each of the SOURCE 
files specified by argv[1], argv[2], ... argv[n] (skipping argv[0] which 
should be DESTINATION). Intermediate results are created in DESTINATION.

Files specified in the list of SOURCE should be relatively small sized 
plain files with #words < 1,000,000.

=back

In summary, a large datafile can be provided to huge-count in the form of 

a. A single plain file (along with --split P)

b. A directory containing several plain files

c. Multiple plain files directly specified as command line arguments

In all these cases, count.pl is separately run on SOURCE files or parts of
SOURCE file and intermediate results are written in DESTINATION dir.

=back

=head2 STEP 3

Intermediate count results created in STEP 2 are recombined in a pair-wise
fashion such that for P separate count output files, C1, C2, C3 ... , CP,

C1 and C2 are first recombined and result is written to huge-count.output

Counts from each of the C3, C4, ... CP are then combined (added) to 
huge-count.output and each time while recombining, always the smaller of the
two files is loaded.

=head2 STEP 4

After all files are recombined, the resultant huge-count.output is then sorted
in the descending order of the bigram counts. If --remove is specified, 
bigrams with counts less than the specified value of --remove, in the final 
huge-count.output file are removed from the sample and their counts are 
deleted from the marginal totals. If --frequency is selected, bigrams with
scores less than the specified value are simply skipped from output.

=head1 OUTPUT

After huge-count finishes successfully, DESTINATION will contain -

=over

=item * Intermediate bigram count files (*.bigrams) created for each of the 
given SOURCE files or split parts of the SOURCE file.

=item * Final bigram count file (huge-count.output) showing bigram counts in
the entire SOURCE.

=back

=head1 BUGS

huge-count.pl doesn't consider bigrams at file boundaries. In other words,
the result of count.pl and huge-count.pl on the same data file will
differ if --newLine is not used, in that, huge-count.pl runs count.pl
on multiple files separately and thus looses the track of the bigrams 
on file boundaries. With --window not specified, there will be loss 
of one bigram at each file boundary while its W bigrams with --window W. 

Functionality of huge-count is same as count only if --newLine is used and 
all files start and end on sentence boundaries. In other words, there 
should not be any sentence breaks at the start or end of any file given to
huge-count.

=head1 AUTHOR

Amruta Purandare, Ted Pedersen.
University of Minnesota at Duluth.

=head1 COPYRIGHT

Copyright (c) 2004,

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota, Duluth.
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
GetOptions ("help","version","token=s","nontoken=s","remove=i","window=i","stop=s","split=i","frequency=i","newLine");
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
        exit;
}

if(defined $opt_frequency && defined $opt_remove)
{
	print STDERR "ERROR($0):
	Options --remove and --frequency can't be both used together.\n";
	exit;
}

#############################################################################

#			========================
#			      CODE SECTION
#			========================

#accept the destination dir name
$destdir=$ARGV[0];
if(-e $destdir)
{
	if(!-d $destdir)
	{
		print STDERR "ERROR($0):
	$destdir is not a directory.\n";
		exit;
	}
}
else
{
	system("mkdir $destdir");
}

# ----------
#  Counting 
# ----------

# source = dir
if($#ARGV==1 && -d $ARGV[1])
{
	$sourcedir=$ARGV[1];
	opendir(DIR,$sourcedir) || die "ERROR($0):
	Error (code=$!) in opening Source Directory <$sourcedir>.\n";
	while(defined ($file=readdir DIR))
	{
		next if $file =~ /^\.\.?$/;
		if(-f "$sourcedir/$file")
		{
			&runcount("$sourcedir/$file",$destdir);
		}
	}
}
# source is a single file
elsif($#ARGV==1 && -f $ARGV[1])
{
	$source=$ARGV[1];
	if(defined $opt_split)
	{
		system("cp $source $destdir");
		if(defined $opt_token)
		{
			system("cp $opt_token $destdir");
		}
		if(defined $opt_nontoken)
		{
			system("cp $opt_nontoken $destdir");
		}
		if(defined $opt_stop)
		{
			system("cp $opt_stop $destdir");
		}
		chdir $destdir;
		$chdir=1;
		system("split-data.pl --parts $opt_split $source");
		system("/bin/rm -r -f $source");
		opendir(DIR,".") || die "ERROR($0):
        Error (code=$!) in opening Destination Directory <$destdir>.\n";
		while(defined ($file=readdir DIR))
		{
			if($file=~/$source/ && $file!~/\.bigrams/)
			{
				&runcount($file,".");
			}
		}
		close DIR;
	}
	else
	{
		print STDERR "Warning($0):
	You can run count.pl directly on the single source file if don't
	want to split the source.\n";
		exit;
	}
}
# source contains multiple files
elsif($#ARGV > 1)
{
	foreach $i (1..$#ARGV)
	{
		if(-f $ARGV[$i])
		{
			&runcount($ARGV[$i],$destdir);
		}
		else
		{
			print STDERR "ERROR($0):
	ARGV[$i]=$ARGV[$i] should be a plain file.\n";
			exit;
		}
	}
}
# unexpected input
else
{
	&showminimal();
	exit;
}

# --------------------
# Recombining counts
# --------------------

if(!defined $chdir)
{
	chdir $destdir;
}

# current dir is now destdir
opendir(DIR,".") || die "ERROR($0):
        Error (code=$!) in opening Destination Directory <$destdir>.\n";

$output="huge-count.output";
$tempfile="tempfile" . time(). ".tmp";

if(-e $output)
{
	system("/bin/rm -r -f $output");
}

while(defined ($file=readdir DIR))
{
	if($file=~/\.bigrams$/)
	{
		if(!-e $output)
		{
			system("cp $file $output");
		}
		else
		{
			system("huge-combine.pl $file $output > $tempfile");
			system("mv $tempfile $output");
		}
	}
}

close DIR;

# ---------------------
# Sorting and Removing
# ---------------------

if(defined $opt_remove)
{
	system("sort-bigrams.pl --remove $opt_remove $output > $tempfile");
}
else
{
	if(defined $opt_frequency)
	{
		system("sort-bigrams.pl --frequency $opt_frequency $output > $tempfile");
	}
	else
	{
		system("sort-bigrams.pl $output > $tempfile");
	}
}
system("mv $tempfile $output");

print STDERR "Check the output in $destdir/$output.\n";
exit;

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

sub runcount()
{
    my $file=shift;
    my $destdir=shift;
    my $justfile=$file;
    $justfile=~s/.*\/(.+)/$1/;
    # --window used
    if(defined $opt_window)
    {
	# --token used
	if(defined $opt_token)
	{
	    # --nontoken used
	    if(defined $opt_nontoken)
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --token $opt_token --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --token $opt_token --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --token $opt_token --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --token $opt_token --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	    # nontoken not used
	    else
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --token $opt_token --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --token $opt_token --stop $opt_stop $destdir/$justfile.bigrams $file")
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --token $opt_token $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --token $opt_token $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	}
	# --token not used
	else
	{
	    # --nontoken used
	    if(defined $opt_nontoken)
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	    # nontoken not used
	    else
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --window $opt_window $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --window $opt_window $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	}
    }
    # --window not used
    else
    {
	# --token used
	if(defined $opt_token)
	{
	    # --nontoken used
	    if(defined $opt_nontoken)
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --token $opt_token --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --token $opt_token --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --token $opt_token --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --token $opt_token --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	    # nontoken not used
	    else
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --token $opt_token --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --token $opt_token --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --token $opt_token $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --token $opt_token $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	}
	# --token not used
	else
	{
	    # --nontoken used
	    if(defined $opt_nontoken)
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --nontoken $opt_nontoken --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --nontoken $opt_nontoken $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	    # nontoken not used
	    else
	    {
		# --stop used
		if(defined $opt_stop)
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl --stop $opt_stop $destdir/$justfile.bigrams $file");
		    }
		}
		# --stop not used
		else
		{
		    if(defined $opt_newLine)
		    {
			system("count.pl --newLine $destdir/$justfile.bigrams $file");
		    }
		    else
		    {
			system("count.pl $destdir/$justfile.bigrams $file");
		    }
		}
	    }
	}
    }
}


#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: huge-count.pl [OPTIONS] DESTINATION [SOURCE]+";
        print "\nTYPE huge-count.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  huge-count.pl [OPTIONS] DESTINATION [SOURCE]+

Efficiently runs count.pl on a huge data.

SOURCE
	Could be a -

		1. single plain file
		2. single flat directory containing multiple plain files
		3. list of plain files

DESTINATION 
	Should be a directory where output is written. 

OPTIONS:

--split P
	If SOURCE is a single plain file, --split has to be specified to 
	split the source file into P parts and to run count.pl separately 
	on each part. 

--token TOKENFILE
	Specify a file containing Perl regular expressions that define the
	tokenization scheme for counting.

--nontoken NOTOKENFILE
	Specify a file containing Perl regular expressions of non-token
	sequences that are removed prior to tokenization.

--stop STOPFILE
	Specify a file containing Perl regular expressions of stop words
	that are to be removed from the output bigrams.

--window W
	Specify the window size for counting.

--remove L
	Bigrams with counts less than L will be removed from the sample.

--frequency F
	Bigrams with counts less than F will not be displayed.

--newLine
	Prevents bigrams from spanning across the new-line characters.

--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc huge-count.pl' to view detailed documentation of huge-count.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "huge-count.pl      -       Version 0.03\n";
        print "Efficiently runs count.pl on a huge data.\n";
        print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
        print "Date of Last Update:     03/30/2004\n";
}

#############################################################################

