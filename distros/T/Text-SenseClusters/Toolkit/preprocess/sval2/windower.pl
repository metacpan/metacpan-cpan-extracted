#!/usr/local/bin/perl -w

=head1 NAME

windower.pl - Limit window of context around a target word specified in a Senseval-2 input file

=head1 SYNOPSIS

Suppose we have a very small Senseval-2 file (small-test.xml) with just 
2 instances. We would like to limit the surrounding context to 5 words 
to the left and 5 words to the right of the target word:

 windower.pl small.xml 5

Output => 

 <?xml version="1.0" encoding="iso-8859-1" ?>
 <corpus lang='english' tagged="NO">
 <lexelt item="begin.v">
 <instance id="begin.555">
 <answer instance="begin.555" senseid="begin%2:30:01::"/>
 <context>
 greats hardly knowns and unknowns <head>begin</head> a game three month season
 </context>
 </instance>
 <instance id="begin.557">
 <answer instance="begin.557" senseid="begin%2:30:01::"/>
 <context>
 late november it expects to <head>begin</head> construction by year end and
 </context>
 </instance>
 </lexelt>
 </corpus>

This is from the first two lines of the file begin.v-test.xml.  You can 
see the full contexts at /samples/Data.

Type C<windower.pl --help> for a quick summary of options

=head1 DESCRIPTION

Limits the contexts of given instances to W tokens around the target word.

=head1 USAGE

windower.pl [OPTIONS] SVAL2 W

=head1 INPUT

=head2 Required Arguments:

=head3 SVAL2

SVAL2 must be a tokenized and preprocessed instance file in the Senseval-2 
format.

=head3 W

Should be a positive integer number specifying the window size. windower
will display only the tokens that appear in the window of [-W, +W] centered 
around the target word.

=head2 Optional Arguments:

=head3 --plain 

Output will be displayed in plain text format showing context of each instance
on a single separate line. i.e. each i'th line on stdout will show the context 
of the i'th instance in the given SVAL2 file. By default, output is created in 
Senseval-2 format.

=head3 --token TOKENREGEX

TOKENREGEX should be a file containing Perl regular expressions that define
the tokenization scheme in SVAL2. windower recognizes only those character
sequences from SVAL2 that match the specified token regex/s, everything else
will be ignored. If --token is not specified, windower searches the default
token.regex file in the current directory.

=head3 --target TARGETREGEX

Specify a file containing Perl regular expressions that define the target 
word/s. Target words must be valid tokens recognizable by the specified 
tokenization scheme (via --token or token.regex)

Following are some of the examples of TARGET word regex files - 

=over 4 

=item 1. 

 /<head>[Ll]ines?<\/head>/

which specifies that the target word could be 

 line, Line, lines or Lines 

delimited in <head> and </head> tags.

=item 2.

Above regex can also be specified as multiple regexes in TARGET as -

 /<head>line<\/head>/

 /<head>lines<\/head>/

 /<head>Line<\/head>/

 /<head>Lines<\/head>/

with a single regex per line

=item 3.

Regex

 /<head>\w+<\/head>/

shows a more general regex for target words marked in <head> tags

=item 4.

Regex 

 /<head.*>\w+<\/head>/

Shows the regex for matching target words in the original Senseval-2 
data.

=item 5.

 /[Ll]ines?/

shows that any occurrence of words - Line, line, Lines, lines are target words 
(that are not delimited in any special tags).

=back

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

When --plain is not selected, OUTPUT is in Senseval-2 format that looks same 
as the input SVAL2 file except the context of each instance shows atmost W 
words around the target word.

When --plain is ON, OUTPUT shows each context on a single line i.e. context of i'th instance in the given SVAL2 file is shown on the i'th line on stdout.

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

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================


# command line options
use Getopt::Long;
GetOptions ("help","version","target=s","token=s","plain");
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

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

#check if the source file is specified
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the input SVAL2 file ...\n";
        exit 1;
}
#accept the input file name
$infile=$ARGV[0];

#check if exists
if(!-e $infile)
{
        print STDERR "ERROR($0):
        SVAL2 file <$infile> doesn't exist...\n";
        exit 1;
}
#open and get handle
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening input SVAL2 file <$infile>.\n";

# -------
# Window
# -------
#check if the window value is specified
if(!defined $ARGV[1])
{
        print STDERR "ERROR($0):
        Please specify the window size...\n";
        exit 1;
}
#accept the window size
$window=$ARGV[1];

# -------------------
# Target Word regex
# -------------------

#file containing regex/s for target word
if(defined $opt_target)
{
	$target_file=$opt_target;
	if(!(-e $target_file))
	{
        	print STDERR "ERROR($0):
        Target regex file <$target_file> doesn't exist.\n";
	        exit 1;
	}
}
else
{
	$target_file="target.regex";
	if(!-e $target_file)
	{
		print STDERR "ERROR($0):
	Please copy the target.regex file into the current directory or specify
	the target regex file via --target option.\n";
		exit 1;
	}
}

# ------------------------
# creating target regex
# ------------------------

open(REG,$target_file) || die "ERROR($0):
        Error(error code=$!) in opening the target regex file <$target_file>.\n";

while(<REG>)
{
        chomp;
        s/^\s+//g;
        s/\s+$//g;
        if(/^\s*$/)
        {
                next;
        }
        if(/^\//)
        {
                s/^\///;
        }
        else
        {
                print STDERR "ERROR($0):
        Regular Expression <$_> should start with '/'\n";
                exit 1;
        }
        if(/\/$/)
        {
                s/\/$//;
        }
	else
        {
                print STDERR "ERROR($0):
        Regular Expression <$_> should end with '/'\n";
                exit 1;
        }
	$target.="(".$_.")|";
}

if(!defined $target)
{
	print STDERR "ERROR($0):
	No valid Perl regular expression found in the target regex file 
	<$target_file>.\n";
	exit 1;
}
else
{
	chop $target;
}

# -----------------------
# creating token regex
# -----------------------
if(defined $opt_token)
{
	$token_file=$opt_token;
	if(!(-e $token_file))
	{
        	print STDERR "ERROR($0):
        Token regex file <$token_file> doesn't exist.\n";
	        exit 1;
	}
}
else
{
	$token_file="token.regex";
	if(!(-e $token_file))
	{
        	print STDERR "ERROR($0):
        Please copy the file token.regex into the current directory
	or specify the token regex file via --token option.\n";
	        exit 1;
	}
}

open(TOK,$token_file) || die "ERROR($0):
	Error(error code=$!) in opening token regex file <$token_file>.\n";
while(<TOK>)
{
        chomp;
        s/^\s+//g;
        s/\s+$//g;
        if(/^\s*$/)
        {
                next;
        }
        if(/^\//)
        {
                s/^\///;
        }
        else
        {
                print STDERR "ERROR($0):
        Regular Expression <$_> should start with '/'\n";
                exit 1;
        }
        if(/\/$/)
        {
                s/\/$//;
        }
        else
        {
                print STDERR "ERROR($0):
        Regular Expression <$_> should end with '/'\n";
                exit 1;
        }
        $token_regex.="(".$_.")|";
}

if(!defined $token_regex)
{
        print STDERR "ERROR($0):
        No valid Perl regular expression found in token regex file
        <$token_file>.\n";
        exit 1;
}
else
{
        chop $token_regex;
}

##############################################################################

#			=========================
#			       CODE SECTION
#			=========================

$tempfile="tempfile" . time() . ".windower";
if(-e $tempfile)
{
	print STDERR "ERROR($0):
	Temporary file <$tempfile> already exists.\n";
	exit 1;
}
open(TEMP,">$tempfile") || die "ERROR($0):
	Error(code=$!) in opening temporary internal file <$tempfile>.\n";

$line_num=0;
while(<IN>)
{
	$line_num++;
	# instance start
	if(/instance id\s*=\s*\"([^"]+)\"/)
	{
		$instance=$1;
	}
	# instance ends
	if(/<\/instance>/)
	{
		undef $instance;
	}
	# end of context
	if(/<\/context>/)
	{
		undef $data_start;
		if(!defined $got_target)
		{
			print STDERR "ERROR($0):
	No matching target word found in the context of instance <$instance>
	in SVAL2 file <$infile>.\n";
			exit 1;
		}
		
		# actual windowing now !
		foreach $index (0..$#text_line)
	        {
        	        #check if the target word
                	if($text_line[$index] =~ /$target/)
	                {
        	                #find the lower and upper bounds for window
                	        $lower=($index-$window)<0 ? 0 : $index-$window;
        	                $upper=($index+$window)>$#text_line ? $#text_line : $index+$window;
				# display the window words
	                        foreach $windex ($lower..$upper)
        	                {
                                       	print TEMP "$text_line[$windex] ";
	                        }
        	        }
	        }
        	print TEMP "\n";
	}
	# context data
	if(defined $data_start)
	{
		# tokenize
		while(/$token_regex/)
		{
			$token=$&;
			$_=$';
			# check if target 
			if($token =~ /$target/)
                	{
				# error on multiple targets
                        	if(defined $got_target)
	                        {
        	                        print STDERR "ERROR($0):
        Multiple target words matched in the context of instance <$instance> 
	in SVAL2 file <$infile>.\n";
                	                exit 1;
                        	}
	                        $got_target=1;
        	        }
			push @text_line,$token;
		}
	}
	if(!defined $data_start && !defined $opt_plain)
        {
                print TEMP $_;
        }
	# context start
	if(/<context>/)
	{
		$data_start=1;
		if(!defined $instance)
		{
			print STDERR "ERROR($0):
	No instance id found for the context at line <$line_num> in SVAL2 file
	<$infile>.\n";
			exit 1;
		}
		undef $got_target;
		undef @text_line;
	}
}

# -----------------------
#  printing to stdout
# -----------------------

close TEMP;
open(TEMP,$tempfile) || die "ERROR($0):
	Error(code=$!) in opening temporary internal file <$tempfile>.\n";
while(<TEMP>)
{
	print;
}
close TEMP;
unlink "$tempfile";

undef $opt_plain;

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: windower.pl SVAL2 W";
        print "\nTYPE windower.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  windower.pl SVAL2 W

Context of each instance in the given SVAL2 file is limited to W tokens around
the target word. Input and output are both in Senseval-2 format.

SVAL2 
	A tokenized and preprocessed input instance file in Senseval-2 format.

W 
	Window size. Limits the contexts to W tokens on left and right of the 
	target word.

OPTIONS:

--plain 
	Output will be in plain text format showing context of each instance
	on a single line. By default, output is in Senseval-2 format.

--target TARGETREGEX
	A file containing Perl regex/s that define the target word/s.
	By default, file target.regex is searched in the current directory.
	
--token TOKENREGEX
	A file containing Perl regex/s that define valid tokens in the SVAL2 
	file. By default, file token.regex is searched in the current directory.

--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc windower.pl' to view detailed documentation of windower.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
#        print "windower.pl      -       Version 0.07\n";
	print '$Id: windower.pl,v 1.13 2008/03/29 20:52:30 tpederse Exp $';
        print "\nLimit contexts in a Senseval-2 file to N tokens around the target word\n";
#        print "Copyright (c) 2002-2005, Amruta Purandare & Ted Pedersen.\n";
#        print "Date of Last Update:     27/07/2006\n";
}

#############################################################################

