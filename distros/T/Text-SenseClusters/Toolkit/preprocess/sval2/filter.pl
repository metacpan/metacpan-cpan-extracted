#!/usr/local/bin/perl -w

=head1 NAME

filter.pl - Remove the instances of low frequency sense tags from a Senseval-2 data file 

=head1 SYNOPSIS

 filter.pl [OPTIONS] DATA FREQUENCY_OUTPUT

Determine the distribution of senses in the given Senseval-2 input file

 frequency.pl begin.v-test.xml > freq-output

 frequency.pl freq-output

Output =>

 <sense id="begin%2:30:00::" percent="64.31"/>
 <sense id="begin%2:30:01::" percent="14.51"/>
 <sense id="begin%2:42:04::" percent="21.18"/>
 Total Instances = 255
 Total Distinct Senses=3
 Distribution={64.31,21.18,14.51}
 % of Majority Sense = 64.31

Filter any sense that occurs in less than 1% of the instances (there are 
none in this data, so frequency output is unchanged)

 filter.pl begin.v-test.xml freq-output >fil-output

 frequency.pl fil-output

Output =>

 <sense id="begin%2:30:00::" percent="64.31"/>
 <sense id="begin%2:30:01::" percent="14.51"/>
 <sense id="begin%2:42:04::" percent="21.18"/>
 Total Instances = 255
 Total Distinct Senses=3
 Distribution={64.31,21.18,14.51}
 % of Majority Sense = 64.31

Keep only the top 2 ranked (most frequent) senses

 filter.pl --rank 2 begin.v-test.xml freq-output > fil-output

 frequency.pl fil-output

Output =>

 <sense id="begin%2:30:00::" percent="75.23"/>
 <sense id="begin%2:42:04::" percent="24.77"/>
 Total Instances = 218
 Total Distinct Senses=2
 Distribution={75.23,24.77}
 % of Majority Sense = 75.23

Keep all senses that occur in at least 20% of the instances in the 
original data

 filter.pl --p 20 begin.v-test.xml freq-output > fil-output

 frequency.pl fil-output

Output =>

 <sense id="begin%2:30:00::" percent="75.23"/>
 <sense id="begin%2:42:04::" percent="24.77"/>
 Total Instances = 218
 Total Distinct Senses=2
 Distribution={75.23,24.77}
 % of Majority Sense = 75.23

You can find L<begin.v-test.xml> in samples/Data

Type C<filter.pl --help> for a quick summary of available options.

=head1 DESCRIPTION

This program will remove low frequency sense tags from a Senseval-2 data 
set by specifying a percentage or rank threshhold. By default it  
removes any sense tag associated with less than 1% of the total 
instances. Output is to STDOUT, so the original input data file is 
unchanged.

=head1 INPUT

=head2 Required Arguments:

filter.pl requires two compulsory arguments - 

=head4 DATA 

Senseval-2 formatted data file that is to be filtered.

=head4 FREQUENCY_OUTPUT

This should be an output created by program frequency.pl of this 
package that shows percentage frequency of each sense tag appearing in given 
DATA. FREQUENCY_OUTPUT should be created by running frequency.pl on the same 
DATA file that is input to filter.

This should show tags

       <sense id="S" percent="P"/>

that specify percent of each sense tag S in the DATA file.

=head2 Optional Arguments:

=head3 Filter Options:

=head4 --percent P

With this option, user can specify the percentage cutoff for filtering. When
--percent is specified, filter.pl will remove all sense tags whose
frequency in FREQUENCY_OUTPUT is below P %. A DATA instance that has all sense
tags attached to it below P% is removed. In other words, only those DATA
instances are retained which have atleast one sense tag with frequency more
than or equal to P%.

=head4 --rank R

With this option, user can specify the rank cutoff for filtering. When 
--rank is specified, filter.pl will remove those sense tags that are ranked 
below R when senses are ordered according to their percentages. A DATA instance
that has all sense tags attached to it below the rank R will be removed. In 
other words, only those DATA instances are retained which have atleast one
sense tag above rank R.

filter.pl allows only one of the above filter conditions to be specified. 

If neither of the filter options is specified, it will set the default filter 
condition as P = 1 and will filter DATA by removing sense tags less then 1%.

=head4 --nomulti

Removes multiple sense tags attached to an instance such that each instance is
tagged with the most frequent sense tag among the tags attached to it.

=head3 Other Options :

--count COUNT

Filters the corresponding COUNT file created by preprocess.pl 
along with the DATA file. COUNT file is filtered such that it stays consistent 
with the new filtered DATA file and contains only those instances left after 
filtering, in the same order as they appear in the output.

Filtered COUNT is written to file COUNT.filtered and every ith line in
COUNT.filtered shows the instance data within <context> and </context> tags 
for the ith instance in the output of filter.

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output is a sense filtered Senseval-2 file that shows only those DATA instances 
which have at least one sense tag left after filtering.

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Amruta Purandare, University of Pittsburgh

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

#############################################################################
#
#       PROGRAM NAME-  filter.pl (A Component of SenseClusters Package)
#	Filters given data by removing low % sense tags and instances using 
#	these tags.
#
#############################################################################
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
GetOptions ("help","version","percent=f","rank=i","count=s","nomulti");
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
if($#ARGV<1)
{
        &showminimal();
        exit;
}

# --percent P will remove all sense tags 
# occurring less than P% of the times
if(defined $opt_percent)
{
	$percent=$opt_percent;
}

# --rank R will remove senses below rank R 
if(defined $opt_rank)
{
	$rank=$opt_rank;
}

# rank and percent can't be both used
if(defined $percent && defined $rank)
{
	print STDERR "ERROR($0):
	Program allows only one of the filter conditions. 
	Use either --rank or --percent options.\n";
	exit;
}

# if both the filter conditions are not specified
# program will set value of percent cutoff to 1
# and will remove all sense tags appearing less than 
# 1% in the given data
if(!defined $percent && !defined $rank)
{
	$percent=1; 
}

# filters count file created by preprocess.pl 
# for a given input file
if(defined $opt_count)
{
	$count_file=$opt_count;	
}

##############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#argv[0] should be the file to be filtered
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify a Senseval-2 formatted data file to be filtered.\n";
        exit;
}
#accept the file name
$infile=$ARGV[0];
#check if exists
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Source file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening <$infile> file.\n";

# argv[1] should be the output of frequency.pl
# that shows % frequency of each sense tag in the source  
if(!defined $ARGV[1])
{
        print STDERR "ERROR($0):
        Please specify the sense distribution file containing output of 
	frequency.pl for the given Source <$infile>.\n";
        exit;
}
#accept the file name
$freq_file=$ARGV[1];
#check if exists
if(!-e $freq_file)
{
        print STDERR "ERROR($0):
        Sense distribution file <$freq_file> doesn't exist.\n";
        exit;
}
open(FREQ,$freq_file) || die "Error($0):
        Error(code=$!) in opening <$freq_file> file.\n";

# --------------------------
# if count file is provided
# --------------------------
if(defined $count_file)
{
	if(!-e $count_file)
	{
        	print STDERR "ERROR($0):
        Count file <$count_file> doesn't exist.\n";
	        exit;
	}
	open(COUNT,$count_file) || die "Error($0):
        Error(code=$!) in opening <$count_file> file.\n";

	#-----------------------------
	# Creating out file for count
	#-----------------------------
	$count_outfile=$count_file.".filtered";
	$ans="N";
        if(-e $count_outfile)
        {
                print STDERR "Warning($0):
        Count filtered file <$count_outfile> already exists, overwrite (y/n)? ";
                $ans=<STDIN>;
        }
        if(!-e $count_outfile || $ans=~/Y|y/)
        {
                open(COUNT_OUT,">$count_outfile") || die "Error($0):
        Error(code=$!) in opening count filtered file <$count_outfile>.\n";
        }
        else
        {
                undef $count_file;
        }
}

##############################################################################

#			===========================
#			BUILD SENSE FREQUENCY TABLE
#			===========================

$line_num=0;
while(<FREQ>)
{
	$line_num++;
        # trimming extra spaces
        chomp;
        s/\s+$//g;
        s/^\s+//g;
        s/\s+/ /g;
	# handling blank lines
        if(/^\s*$/)
        {
                next;
        }
	# get the % of each sense tag
	if(/<sense id=\"([^\"]+)\" percent=\"(\d*\.?[\d]+)\"\/>/)
	{
		if(defined $freq_hash{$1})
		{
			print STDERR "ERROR($0):
	Sense Tag <$1> is repeated in the sense distribution file <$freq_file>.\n";
			exit;
		}
		$freq_hash{$1}=$2;
		if(defined $rank)
		{
			push @freq_array,$2;
		}
		# store the removed sense to update the KEY file later
		if(defined $opt_key && defined $percent && $freq_hash{$1}<$percent)
		{
			push @removed,$1;
		}
	}
}

if(!%freq_hash)
{
	print STDERR "ERROR($0):	
	No valid <sense id=\"S\" percent=\"P\"\/> entry found in the sense 
	distribution file <$freq_file>.\n";
	exit;
}
##############################################################################

#				================
#				FIND SENSE RANKS
#				================

# --rank R removes all senses whose ranks are below R 
# ranking senses according to their percentages
if(defined $rank)
{
	undef $old;
	$myrank=1;
	# sorting sense frequencies in descending order
	@sorted=sort {$b <=> $a} @freq_array;
	foreach $freq (@sorted)
	{
		# senses with this freq are already assigned ranks
		# so go ahead
		if(defined $old && $freq == $old)
                {
                      next;
                }
		# increment rank only at % rise
                if(defined $old && $freq<$old)
                {
                      $myrank++;
                }
                $old=$freq;
		# assign ranks to senses
		foreach $sense (sort keys %freq_hash)
		{
			if($freq==$freq_hash{$sense})
			{
				# each sense will get only one rank
				if(!defined $rank_hash{$sense})
				{
					$rank_hash{$sense}=$myrank;
					# store the removed sense to update 
					# the KEY file later 
					if(defined $opt_key && $myrank>$rank)
					{
						push @removed,$sense;
					}
				}
			}
		}
	}
}

##############################################################################

#				===============
#				SENSE FILTERING
#				===============

# if --nomulti is defined remove multiple sense tags for an instance 
# keeping only the most frequent tag
if(defined $opt_nomulti)
{
	#---------------------
	#creating a TEMP file
	#---------------------
	#use the system_defined date for unique name for tempfile

	$tempfile="temp".time().".filter";
	open(TEMP1,">$tempfile")||die"ERROR($0):
	Internal System Error(code=$!).\n";
	while(<IN>)
	{
		# removing all but the most frequent tag
		if(/sense\s*id=\"([^\"]+)\"/)
		{
			if((defined $freq_hash{$1}) && (!defined $current_max || $freq_hash{$1}>$current_max))
			{
				$current_max=$freq_hash{$1};
				$max_sense=$_;
			}
		}
		elsif(/<context>/)
		{
			if(defined $max_sense)
			{
				print TEMP1 $max_sense;
				undef $max_sense;
				undef $current_max;
			}
			print TEMP1 $_;
		}
		else
		{
			print TEMP1 $_;
		}
	}
	close TEMP1;
	close IN;
	open(IN,$tempfile) || die "\nERROR($0):
	Error in opening temporary file $tempfile.\n";
}

#---------------------
#creating a TEMP file
#---------------------
#we hold data temporarily in tempfile till the program terminates
#without an error. In case of error, the tempfile would be
#retained and will hold partial output of the program.

#use the system_defined date for unique name for tempfile

$tempfile1="temp1".time().".filter";
open(TEMP,">$tempfile1") || die"ERROR($0):
Internal System Error(code=$!).\n";

#this is to keep track of which data instances are to be written
#from corresponding count file
$line_num=1;

#			----------------------------
#			Actual Filtering Starts Here
#			----------------------------

# write flag indicates if the current instance is to be 
# written or not 

# initially write is set to allow standard XML tags before the actual
# instance data starts
$write=1;
# counts lines between the tags <context> and </context>
$count_lines=0;
$line_no=0;
while(<IN>)
{
	$line_no++;
	# we count data lines only within <context> & </context> tags
	# to remember line nos to be written into filtered count output
	if(/<\/context>/)
        {
                $count_lines=0;
        }
	if(/instance id=\"([^\"]+)\"/)
	{
		# hold temporarily as we don't know percent/rank used  
		# by this instance yet
		if(defined $temp_buf)
		{
			$temp_buf.=$_;
		}
		else
		{
			$temp_buf=$_;
		}
		# write will be set only when program encounters
		# atleast 1 sense tag used by this instance that
		# passes the filter condition 
		undef $write;
	}
	elsif(/<\/instance>/)
	{
		undef $temp_buf;
		if(defined $write && $write==1)
		{
			print TEMP $_;
		}
		# to allow any data between </instance> and <instance>
		# or closing tags after last </instance>
		$write=1;
	}
	# extract the sense id and check the filter conditions
	elsif(/sense\s*id=\"([^\"]+)\"/)
	{
		$sense=$1;
		#check percent/rank and set write flag appropriately
		if(defined $percent) 
		{
			if(defined $freq_hash{$sense})
			{
				if($freq_hash{$sense}>=$percent)
				{
					# write this instance
					$write=1;
					# hold this answer tag till all answer 
					# tags are processed
					$temp_buf.=$_;
				}
			}
		}
		elsif(defined $rank) 
		{
			if(defined $rank_hash{$sense})
                        {
				if($rank_hash{$sense}<=$rank)
				{
		                        $write=1;
					# hold this answer tag till all answer 
					# tags are processed
	                        	$temp_buf.=$_;
				}
			}
		}
	}
	elsif(defined $write && $write==1)
	{
		if(defined $temp_buf)
		{
			print TEMP $temp_buf;
			undef $temp_buf;
		}
		print TEMP $_;
		# data on line numbers in @lines_for_count array will be 
		# written from the corresponding count file 
		if($count_lines==1)
		{
			# push current line number as data from .count
			# file at this position needs to be written to
			# filtered count
			push @lines_for_count,$line_num;
		}
	}
	# count lines when <context> tag is seen
	if($count_lines==1)
	{
		$line_num++;
	}
	# start counting number of data lines when <context> comes 
	if(/<context>/)
	{
		$count_lines=1;
	}
}

#now display to STDOUT
close TEMP;
open(TEMP,$tempfile1) || die "ERROR($0):
        Internal System Error(code=$!).\n";
@file_stuff=<TEMP>;
print @file_stuff;
#remove the tempfile1
unlink "$tempfile1";

if(defined $opt_nomulti)
{
	unlink "$tempfile";
}
##############################################################################

#			==============================
#			FILTERING DATA FROM COUNT FILE
#			==============================

# @lines_for_count is already sorted as it contains line numbers
# from xml file as they are read 
if(defined $count_file)
{
	$line_num=0;
	$next_line=shift @lines_for_count;
	while(<COUNT>)
	{
		$line_num++;
		# write this line
		if($line_num==$next_line)
		{
			print COUNT_OUT $_;
			# get the next line number 
			if($#lines_for_count>=0)
			{
				$next_line=shift @lines_for_count;
			}
			else
			{
				last;
			}
		}
	}
	# catching inconsistency between given count and Data file 
	# all line nos in lines_for_count array must occur in count file
	if($#lines_for_count>=0)
	{
		print STDERR "ERROR($0):
	Data File <$infile> and Count file <$count_file> are inconsistent.\n";
		exit;
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
        print "Usage: filter.pl [OPTIONS] DATA FREQUENCY_OUTPUT";
        print "\nTYPE filter.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage: filter.pl [OPTIONS] DATA FREQUENCY_OUTPUT 

Filters DATA by removing low percent sense tags using FREQUENCY_OUTPUT (output 
of program frequency.pl showing percentage frequency of each sense in DATA). 
A DATA instance is removed if all sense tags attached to it are removed by 
applying a filter.  

DATA
	Specify a Senseval-2 formatted DATA file to be filtered. 

FREQUENCY_OUTPUT
	A file containing the output of frequency.pl by running it on the same 
	DATA file. FREQUENCY_OUTPUT should show tags  
		<sense id=\"S\" percent=\"P\"\/>
	that specifies percent of sense tag S in the DATA file.

OPTIONS:
--percent P
	Removes all senses whose frequency is below P%. Data instances having 
	all attached senses below P% are removed. 

--rank R
	Removes all senses ranking below R when arranged in descending order 
	of their frequencies.

Default Filter 
	If neither --percent P nor --rank R are specified, default filter will
	be percent P = 1 and will remove senses below 1%.

--count COUNTFILE
	This will filter data instances from the corresponding COUNTFILE 
	created by preprocess.pl program. This is to
	keep the COUNTFILE consistent with the DATA file after filtering.

--nomulti
	Removes all but the most frequent sense tag attached to a multi-tagged
	instance.

--help
        Displays this message.

--version
        Displays the version information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
#        print "filter.pl      -       Version 0.11";
	print '$Id: filter.pl,v 1.13 2013/06/22 20:31:12 tpederse Exp $';
        print "\nRemove low frequency sense tags from a Senseval-2 file\n";
#        print "\nCopyright (c) 2002-2005, Amruta Purandare, Ted Pedersen.\n";
#        print "Date of Last Update:     05/07/2003\n";
}

#############################################################################

