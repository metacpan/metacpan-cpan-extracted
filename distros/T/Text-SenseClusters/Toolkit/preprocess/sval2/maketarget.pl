#!/usr/local/bin/perl -w

=head1 NAME

maketarget.pl - Create target.regex file for a given Senseval-2 data 
file that shows all the forms of the target word

=head1 SYNOPSIS

 maketarget.pl -head begin.v-test.xml

This creates a file called target.regex with the following contents: 

 /<head>\s*(began)|(begin)|(beginning)|(begins)|(begun)\s*</head>/

 maketarget.pl begin.v-test.xml

This creates a file called target.regex with the following contents: 

 /(\bbegan\b)|(\bbegin\b)|(\bbeginning\b)|(\bbegins\b)|(\bbegun\b)/
 
These are regular expressions that show all the forms of "begin" that 
appear in the given Senseval-2 data file with and without a surrounding 
head tag.

You can find begin.v-test.xml at samples/Data

Type C<maketarget.pl> for a quick list of options

=head1 DESCRIPTION

This program creates a Perl regex for the TARGET word by detecting its 
various forms from the given SVAL2 file.

This program will create a regular expression file called target.regex 
that can be used to match target words via the --target option in many 
SenseClusters programs. The target.regex file can be of two forms:

 /<head>\s*(target1|target2)\s*</head>/

or 

 /(\btarget1\b)|(\btarget2\b)/

The first form is appropriate when the corpus already has the target word 
marked with head tags, while the second should be used when the corpus is 
plain unannotated text. The second form is the default, while the first is 
available with the --head option. Note that in the first form the <head> 
tag acts as a delimiter on word boundaries, while in the second form the 
\b character class is used for that purpose. 

=head1 INPUT

=head2 Required Arguments:

=head3 SVAL2

Should be a file in Senseval-2 format from which various possible forms of the
TARGET word are to be detected. 

=head2 Optional Arguments:

=head3 --head

Create target word regex in the form: <head>\s*(target1|target2)\s*</head>

=head3 --help

Displays the summary of command line options.

=head3 --version

Displays the version information.

=head1 OUTPUT

maketarget.pl automatically creates the file with name 'target.regex' that
shows the Perl regex for the TARGET word. The regex is a OR of various 
forms of the word detected placed within a single regex, optionally 
surrounded by <head> and </head> tags.

For example: Contents of a sample <target.regex> file:

 /(\bLine\b)|(\bLines\b)|(\bline\b)|(\blined\b)|(\blines\b)/ (default)

 /<head>\s*(Line)|(Lines)|(line)|(lined)|(lines)\s*</head>/ (with --head)

=head1 BUGS

This program does not recognize target words of the form:

 <head> Bill Clinton </head>

It is restricted to target words that are a single string, such as

 <head> Bill_Clinton </head>

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Amruta Purandare, University of Pittsburgh

 Anagha Kulkarni, Carnegie-Mellon University

=head1 COPYRIGHT

Copyright (c) 2002-2008, Ted Pedersen, Amurta Purandare, Anagha Kulkarni

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

# command line options
use Getopt::Long;
GetOptions ("head","help","version");

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

# use head tags if --head is given

if(defined $opt_head)
{
        $opt_head=1;
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

#accept the SVAL2 file name
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Source file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening source file <$infile>.\n";

##############################################################################

while(<IN>)
{

	# modified by tdp on august 5, 2006 to handle \s* that
	# may appear inside the head tags

	# first match the head tags, and then find what is inside
	# them. Match those to a regex that defines a single 
	# string that is (optionally) preceded and/or followed
	# by spaces. If that matches, then we have a legal head tag.
	
        if(/<head>(.*)<\/head>/)
        {
		$match = $1;
                if( $match =~ /\s*(\w+)\s*/)
                {
                        $target_form{$1}=1;
                }
                else
                {
                        print STDERR "ERROR($0):
	Target word <$match> doesn't look like a valid word.\n";
                        exit 1;
                }
        }
}

if(%target_form)
{
        $targetfile="target.regex";
        if(-e $targetfile)
        {
                print STDERR "Warning($0):
        Target File <$targetfile> already exists, overwrite (y/n)? ";
                $ans=<STDIN>;
                if($ans !~ /^y|Y/)
                {
                        exit;
                }
        }
        open(TARGET,">$targetfile") || die "Error($0):
        Error(code=$!) in opening file <$targetfile>.\n";

	# modified by TDP August 1, 2006 to use head option
	# if using head tag, word boundaries delimited by <head>
	# if not, then should use \b to avoid substring matches

        if ($opt_head) {

		# Modified by AKK July 30, 2006.
		# Added the surrounding head tags to the regex of 
		# target forms.
	
		# tdp modified $target assignments to single quotes
		# to avoid interpolation of regex, which seemed to
		# be causing problem with passed through \s errors

	        $target= '/<head>\s*';
        	foreach $form (sort keys %target_form)
	        {
        	        $target.="($form)|";
	        }
	        chop $target;
	        $target.= '\s*</head>/';
	        print TARGET $target;
		print TARGET "\n";
	}
        else {
	        $target="/";
        	foreach $form (sort keys %target_form)
	        {
        	        $target.="(\\b$form\\b)|";
	        }
	        chop $target;
	        $target.="/";
	        print TARGET $target;
		print TARGET "\n";
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
        print "Usage: maketarget.pl [OPTIONS] SVAL2";
        print "\nTYPE maketarget.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  maketarget.pl [OPTIONS] SVAL2

Creates a Perl regex for the TARGET word by detecting its various 
forms from the given SVAL2 file.

SVAL2
	File in Senseval-2 format from which different forms of the target
	word are to be searched.

OPTIONS:
--head
        Create target word regex as follows: <head>\\s*target\\s*</head>
--help
        Displays this message.
--version
        Displays the version information.
Type 'perldoc maketarget.pl' to view detailed documentation of maketarget.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print '$Id: maketarget.pl,v 1.18 2013/06/22 20:28:29 tpederse Exp $';
##        print "\nCopyright (c) 2002-2006, Ted Pedersen, Amruta Purandare, & Anagha Kulkarni\n";
##        print "maketarget.pl      -       Version 0.01\n";
        print "\nCreate a Perl regex for a target word in a Senseval-2 file\n";
#        print "Date of Last Update:     07/30/2006\n";
}

#############################################################################

