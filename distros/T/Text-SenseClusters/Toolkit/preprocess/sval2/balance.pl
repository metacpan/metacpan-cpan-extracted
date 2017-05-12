#!/usr/local/bin/perl -w

=head1 NAME

balance.pl - Create a balanced Senseval-2 data file that has the same 
number of instances for each possible sense. 

=head1 SYNOPSIS

 balance.pl [OPTIONS] DATA N > Balanced-DATA

This is the original distribution of senses in a Senseval-2 data file:

 frequency.pl begin-v.test.xml

Output => 

 <sense id="begin%2:30:00::" percent="64.31"/>
 <sense id="begin%2:30:01::" percent="14.51"/>
 <sense id="begin%2:42:04::" percent="21.18"/>
 Total Instances = 255
 Total Distinct Senses=3
 Distribution={64.31,21.18,14.51}
 % of Majority Sense = 64.31

Here they are balanced with 20 instances per sense.

 balance.pl begin.v-test.xml 20 > bal-output

 frequency.pl bal-output

Output => 

 <sense id="begin%2:30:00::" percent="33.33"/>
 <sense id="begin%2:30:01::" percent="33.33"/>
 <sense id="begin%2:42:04::" percent="33.33"/>
 Total Instances = 60
 Total Distinct Senses=3
 Distribution={33.33,33.33,33.33}
 % of Majority Sense = 33.33

Here they are balanced with 50 instances per sense. Please note that any 
sense with less than 50 instances is removed from the data.

 balance.pl begin.v-test.xml 50 > bal-output

 frequency.pl bal-output

Output => 

 <sense id="begin%2:30:00::" percent="50.00"/>
 <sense id="begin%2:42:04::" percent="50.00"/>
 Total Instances = 100
 Total Distinct Senses=2
 Distribution={50.00,50.00}
 % of Majority Sense = 50.00

You can find begin-v.test.xml in samples/Data
 
Type C<balance.pl --help> for a quick summary of options

=head1 DESCRIPTION

This program will choose exactly the same number of instances for each 
sense found in a given Senseval-2 file. Unless a value is specified, it 
will choose the number of instances present in the least frequent sense. 
Output is to STDOUT, so the original input data is unchanged. 

=head1 INPUT

=head2 Required Arguments:

=head4 DATA

balance.pl accepts a Senseval-2 data file. 

=head4 N 

Specifies the number of instances to be selected from each sense. 

=head2 Optional Arguments:

--count COUNT

Balances the COUNT file created by SenseTool's L<preprocess.pl> along 
with the DATA file. COUNT file is balanced such that it stays consistent 
with the new balanced DATA file and contains only those instances left 
after balancing, in the same order as they appear in the output. 

Balanced COUNT is written to file COUNT.balanced and every ith line in 
COUNT.balanced is instance data within <context> and </context> tags for the 
ith instance in the output of balance.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output is a sense balanced Senseval-2 file and is displayed to stdout. Output 
will show exactly N instances of each sense that has at least N 
instances. All senses in the output Senseval-2 will have equal number of 
instances meaning the senses will be equally distributed.

=head1 BUGS

The output of balance.pl will have un-balanced distribution of senses 
when some of the instances have multiple sense tags in the given DATA 
file.

=head1 AUTHORS

 Ted Pedersen,  University of Minnesota, Duluth
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

###############################################################################

#                               ====================
#                               THE CODE STARTS HERE
#                               ====================

###############################################################################

#                          ==============================
#                          COMMAND LINE OPTIONS AND USAGE
#                          ==============================

#command line options
use Getopt::Long;
GetOptions ("help","version","count=s");

#show help message
if(defined $opt_help)
{
	$opt_help=1;
	&showhelp();
	exit;
}

#show version information
if(defined $opt_version)
{
	$opt_version=1;
	&showversion();
	exit;
}

#show minimal usage note
if($#ARGV<1)
{
        &minimal();
        exit;
}

#if --count file is provided
if(defined $opt_count)
{
	$countfile=$opt_count;
}
##############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

#getting the source file name 
if(!defined $ARGV[0])
{
	print STDERR "ERROR($0):
	Please specify Senseval-2 formatted Data file to be balanced.\n";
	exit;
}
$infile=$ARGV[0];
if(!(-e $infile))
{
	print STDERR "ERROR($0):
	Source file $infile doesn't exist.\n";
	exit;
}
open(IN,$infile) || die "ERROR($0):
	Error(code=$!) in opening file $infile.\n";

#getting no of instances to be selected from each sense
if(!defined $ARGV[1])
{
	print STDERR "ERROR($0):
	Please specify the Number of instances to be selected from each sense.\n";
	exit;
}
$number=$ARGV[1];

# --------------------------
# if count file is provided
# --------------------------
if(defined $countfile)
{
        if(!-e $countfile)
        {
                print STDERR "ERROR($0):
        Count file <$countfile> doesn't exist.\n";
                exit;
        }
        open(COUNT,$countfile) || die "Error($0):
        Error(code=$!) in opening <$countfile> file.\n";

        #-----------------------------
        # Creating out file for count
        #-----------------------------
        $count_outfile=$countfile.".balanced";
        $ans="N";
        if(-e $count_outfile)
        {
                print STDERR "Warning($0):
        Balanced file <$count_outfile> for count file <$countfile> already exists, 
	overwrite (y/n)? ";
                $ans=<STDIN>;
        }
        if(!-e $count_outfile || $ans=~/Y|y/)
        {
                open(COUNT_OUT,">$count_outfile") || die "Error($0):
        Error(code=$!) in opening balanced count file <$count_outfile>.\n";
        }
        else
        {
                undef $countfile;
        }
}
##############################################################################

#			====================
#			  Actual Balancing
#			====================

# if sense tagged, get senses from data file
while(<IN>)
{
	push @text,$_;
	if(/instance id=\"([^\"]+)\"/)
	{
		$instance=$1;
	}
	if(/sense\s*id=\"([^\"]+)\"/)
	{
		# storing instances per sense
		push @{$instances{$1}},$instance;
	}
}

# selecting N instances of each sense
foreach $sense (keys %instances)
{
	# shuffle and select only the instances of that sense which have
	# number of instances > specified number N 
	if($#{$instances{$sense}} >= ($number-1))
	{
		#selecting randomly by shuffling and selecting top N
		shuffle(\@{$instances{$sense}});
		foreach (0..$number-1)
		{
			# selected will contain all the instances that are 
			# to be displayed
			$select_it=shift @{$instances{$sense}};
			$selected{$select_it}=1;
		}
	}
}

# now display only the selected instances from the text
$write=1;
$line_num=0;
$count_flag=0;
foreach (@text)
{
	if(/<\/context>/)
	{
		$count_flag=0;
	}
	if($count_flag==1)
        {
                $line_num++;
        }
	if(/instance id=\"([^\"]+)\"/)
	{
		if(!defined $selected{$1})
		{
			$write=0;
		}
	}
	if($write==1)
	{
		print;
		if(defined $opt_count && $count_flag==1)
		{
			push @count_lines,$line_num;
		}
	}
	if(/<\/instance>/)
	{
		$write=1;
	}
	if(/<context>/)
	{
		$count_flag=1;
	}
}

###############################################################################

# ---------------------
# balancing count file
# ---------------------

# @count_lines contains line numbers of lines to be written from count file
if(defined $countfile)
{
	$line_num=0;
        $next_line=shift @count_lines;
        while(<COUNT>)
        {
                $line_num++;
                # write this line
                if(defined $next_line && $line_num==$next_line)
                {
                        print COUNT_OUT $_;
                        # get the next line number
                        if($#count_lines>=0)
                        {
                                $next_line=shift @count_lines;
                        }
                        else
                        {
                                last;
                        }
                }
        }
	# catching inconsistency between given count and Data file
        # all line nos in count_lines array must occur in count file
        if($#count_lines>=0)
        {
                print STDERR "ERROR($0):
        Data File <$infile> and Count file <$countfile> are inconsistent.\n";
                exit;
        }
}
##############################################################################

#-------------------
#shuffle subroutine
#-------------------
#this code is taken from the book Perl Cookbook Chapter 4 that describes
#randomizing array(Page 121-122)

#Reference : Perl Cookbook, Tom Christiansen & Nathan Torkington, O'Reilly
#            publication, 1998, Chapter 4, section 4.17, Randomizing an Array

sub shuffle
{
        my $array = shift;
        my $i;
        for ($i = @$array; --$i; )
        {
                 my $j = int rand ($i+1);
                 next if $i == $j;
                 @$array[$i,$j] = @$array[$j,$i];
        }
}

#show minimal usage message
sub minimal()
{
	print "Usage: balance.pl [OPTIONS] DATA N";
	print "\nTYPE balance.pl --help for help\n";
}
#show help
sub showhelp()
{
	print "Usage: 
	balance.pl [OPTIONS] DATA N 
Balances sense distribution in a given Senseval-2 formatted DATA file by 
randomly selecting exactly N instances of each sense tag. 

DATA
	Specify a Senseval-2 file to be balanced for sense tags. 
 
N	
	Specify the number of instances to be selected from sense found in 
	the SOURCE file.";
	print "\nOPTIONS:";
	print "
--count COUNT_FILE
	Specify the COUNT_FILE created by preprocess.pl program that shows 
	instance data within <context> tags corresponding to each instance
	in a given DATA file. COUNT_FILE will also be balanced along with 
	the DATA file and updated COUNT_FILE will be written into 
	COUNT_FILE.balanced. 

--help		
	Displays this message.";
	print "
--version	
	Displays the version information.\n";
}
#version information
sub showversion()
{
	print '$Id: balance.pl,v 1.12 2008/03/31 16:19:57 tpederse Exp $';
#	print "balance.pl	-	Version 0.11\n";
	print "\nBalance sense distribution in a Senseval-2 file\n";
#	print "Copyright (c) 2002-2005, Amruta Purandare, Ted Pedersen.\n";
# 	print "Date Of Last Update:     05/23/2003\n";
}
