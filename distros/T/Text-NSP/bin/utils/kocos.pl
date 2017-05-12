#!/usr/local/bin/perl -w

=head1 NAME

kocos.pl - Find the Kth order co-occurrences of a word

=head1 SYNOPSIS

This program finds the Kth order co-occurrences of a given word. 

=head1 DESCRIPTION

=head2 1. What are Kth order co-occurrences?

Co-occurrences are the words which occur together in the same context. All 
words which co-occur with a given target word are called its co-occurrences. 
The concept of 2nd order co-occurrences is explained in the paper Automatic 
word Sense Discrimination [Schutze98]. According to this paper, the words 
which co-occur with the co-occurring words of a target word are called as the 
2nd order co-occurrences of that word. 

So with each increasing order of co-occurrences, we introduce an extra level 
of indirection and find words co-occurring with the previous order 
co-occurrences.  

We generalize the concept of 2nd order co-occurrences from [Schutze98] to find
the Kth order co-occurrences of a word. These are the words that co-occur 
with the (K-1)th order co-occurrences of a given target word.

We have also found [Niwa&Nitta94] to be related to kocos. While we do not 
exactly reimplement the co-occurrence vectors they propose, we feel that 
kocos is at least similar in spirit.

=head2 2. Usage

Usage: kocos.pl [OPTIONS] BIGRAM

=head2 3. Input 

=head3 3.1 BIGRAM

Specify the BIGRAM file name on the command line after the program name and 
options (if any) as shown in the usage note. 

BIGRAM should be a bigram output(normal or extended) created by NSP programs - 
count.pl, statistic.pl or combig.pl. When count.pl and statistic.pl are run for 
creating bigrams (--ngram set to 2 or not specified), the programs list the 
bigrams of all words which co-occur together(in certain window). So we can
say that if a bigram 'word1<>word2<>' is listed in the output of count.pl
or statistic.pl program, it means that the words word1 and word2 are the 
co-occurrences of each other.

In general you may want to consider the use of stop lists (--stop option  
in count.pl) to remove very common words such as "the" and "for", and 
also eliminate low frequency bigrams (--remove option in count.pl). The  
stop list is particularly  important as high frequency words such as "the" 
or "for" will co-occur with many different words, and greatly expand the  
search needed to find kth order co-occurrences. 

If you want to run kocos.pl on a source file not created by either count 
or statistic program of this package, just make sure that each line of BIGRAM 
file will list two words WORD1 and WORD2 as 
WORD1<>WORD2<> 
The program minimally requires that there are exactly two words and they are 
separated by delimiter '<>' with an extra delimiter '<>' after the second
word. So you may convert any non NSP input to this format where two words 
occurring in the same context are '<>' separated and provide it to kocos.  

Controlling scope of the context

You may like to call two words as co-occurrences of each other if they occur 
within a specific distance from each other. We encourage in this case that you 
use --window w option of NSP program count.pl while creating a BIGRAM file. This 
will create bigrams of all words which co-occur within a distance w from each 
other. Thus --window w sets the maximum distance allowed between two words to 
call them co-occurrences of each other. 

Note that if the --window option is not used while creating BIGRAM input
for kocos, only those words which come immediately next to each other will
be considered as the co-occurrences (default window size being 2 for bigrams).
 
=head2 4. Options

=head3 4.1 --literal WORD

With this option, the target WORD whose kth order co-occurrences are to be
found can be directly specified on the command line.

e.g.
        kocos.pl --literal line test.input
will find the 1st order co-occurrences (by default) of the word 'line' using 
Bigrams listed in file test.input.

	kocos.pl --literal , --order 3 test.input 
will find 3rd order co-occurrences of ',' from file test.input. 

=head3 4.2 --regex REGEXFILE

With this option, target word can be specified using Perl regular expression/s.
The regex/s should be written in a file and multiple regex/s should either 
appear on separate lines or should be Perl 'OR' (|) separated. 
 
We provide this option to allow user to specify various morphological
variants of the target word e.g. line, lines, Line,Lines etc.

e.g.
(1) let test.regex contains a regular expression for target word which is -
 /^[Ll]ines?$/

To use this for finding kocos, run kocos.pl with command

        kocos.pl --regex test.regex --order K test.input

(2) To find say 2nd order co-occurrences of any general target word which occurs in
Data in <head> tags like Senseval Format,
we use a regular expression
 /^<head.*>\w+</head>$/
in our regex file say test.regex
and run kocos.pl using command

        kocos.pl --regex test.regex --order 2 eng-lex-sample.training.xml

(3) To find 3rd order co-occurrences of any word that contains period '.'
run kocos.pl using 
	     
	kocos.pl --literal . --order 3 test.input 

Or write a regex /\./ in file say test.regex and run kocos using 

	kocos.pl --regex test.regex --order 3 test.input 

(4) To find 2nd order co-occurrences of all words that are numbers, 
write a regex like /^\d+$/ to a regexfile say test.regex and run kocos 
using, 
       
        kocos.pl --regex test.regex --order 2 test.input     

Note: writing a regex /\d+/ will also match words like line20.1.cord, or 
art%10.fine456 that include numbers. 

Regex/s that should exactly match as target words should be delimited by 
^ and $ as in /^[Ll]ines?$/. Specifying something like /[Ll]ines?/ will
match with 'incline'. 

Note - The program kocos.pl requires that the target word is specified using
either of the options --literal or --regex

=head3 4.3 --order K

If the value of K is specified using the command line option --order K,
kocos.pl will find the Kth order co-occurrences of the target word. K can
take any integer value greater than 0. If the value of K is not specified,
the program will set K to 1 and will simply find the co-occurrences of the
target (the word co-occurrence generally means first order co-occurrences).  

=head3 4.4 --trace TRACEFILE

To see a detailed report of how each Kth order co-occurrence is reached as a 
sequence of K words, specify the name of a TRACEFILE on the command line 
using --trace TRACEFILE option. 

TRACEFILE will show the chains of K+1 words where the first word is the TARGET 
word and every ith word in the chain is a (i-1)th order co-occurrence of target 
which co-occurs with (i-1)th word in the chain. So a chain of K+1 words, 

 TARGET->COC1->COC2->COC3....->COCK-1->COCK 

shows that COC1 is a first order co-occurrence of the TARGET. 

 COC2 is a second order co-occurrence such that COC2 co-occurs with 
 COC1 which in turn co-occurs with the TARGET. 
 COC3 is a third order co-occurrence such that COC3 co-occurs with
 COC2 which in turn co-occurs with COC1 which co-occurs with TARGET. 

and so on......  

=head3 4.6 --help

This option will display the help message.

=head3 4.7 --version

This option will display version information of the program.

=head2 5. Output 

The program will display a list of Kth order co-occurrences to standard 
output  such that each co-occurrence occurs on a separate line and is 
followed by '<>' (just to be compatible with other programs in NSP).  

Note that the output of kocos.pl could be directly used by the program   
nsp2regex of the SenseTools Package (by Satanjeev Banerjee and Ted  
Pedersen) to convert Senseval data instances into feature vectors in ARFF  
format where our Kth order co-occurrences are used as features. 

For more information on SenseTools you can refer to its README:
http://www.d.umn.edu/~tpederse/sensetools.html

                                IMPORTANT NOTE

If there are some kth order co-occurrences which are also the ith order
co-occurrences (0<i<k) of the target word, program kocos.pl will not
display them as the Kth order co-occurrences. kocos.pl displays only those 
words as Kth order co-occurrences whose minimum distance from target word
is K in the co-occurrence graph.
[Co-occurrence graph shows a network of words where a word is connected to 
all words it co-occurs with.]


=head2 6. Usage examples 

(a)	Using default value of order 
To find the (1st order) co-occurrences of a word 'line' from the BIGRAM file 
test.input, run kocos.pl using the following command. 
 	kocos.pl --literal line test.input 

(b)	Using option order 
To find the 2nd order co-occurrences of a word 'line' from the BIGRAM file
test.input, run kocos.pl using the following command.
	kocos.pl --literal line --order 2 test.input 

(c)	Using the trace option
To see how the 4th order co-occurrences of a word 'line' is reached as a 
sequence of words which form a co-occurrence chain, run kocos.pl using the
following command.
	kocos.pl --literal line --order 4 --trace test.trace test.input 

(d) 	Using a Regex to specify the target word
To find Kth order co-occurrences of a target word 'line' which is specified as 
a Perl regular expression say /^[Ll]ines?$/ in a file test.regex, 
run kocos.pl using 
	kocos.pl --regex test.regex --order K test.input

(e) 	Using a generic Regex for Data like Senseval-2,
To find 2nd order co-occurrences of a target word that occurs in <head> tags
in the data file eng-lex-sample.training.xml, use a regular expression like
/<head>\w+</head>/ from a file say test.regex, and run kocos.pl using
	kocos.pl --regex test.regex --order 2 test.input

=head2 7. General Recommendations

(a) Create a BIGRAM file using programs count.pl, statistic.pl or combig.pl
    of NSP Package. 
(b) Use --window W option of program count.pl to specify the scope of the 
    context. Any word that occurs within a distance W from a target word will be
    treated as its co-occurrence.
(c) Use either --literal or --regex option to specify the target word. We
    recommend use of regex support to detect forms of target word other than
    its base form.

=head2 8. Examples of Kth order co-occurrences

In all the following examples, we assume that the input comes from the file 
test.input and word 'line' is a target word. 

 test.input => 			
 ----------------
 print<>in<>	|
 print<>line<>	|
 text<>the<>	|
 text<>line<>	|
 file<>the<>	|
 file<>in<>	|
 line<>file	|
 ----------------

(Note that test.input doesn't look like a valid count/statistic output because 
kocos.pl will minimally require two words WORD1 and WORD2 separated by '<>' 
with an extra '<>' after WORD2 as described in Section 3.1 of this README) 

(a)	The 1st order co-occurrences of word 'line' can be found by 	
	running kocos.pl with either of the following commands -

	kocos.pl --literal line test.input 
		OR
	kocos.pl --order 1 --literal line test.input 

This will display the co-occurrences of 'line' to standard output as shown
below in the box. 

 --------	
 text<>	|
 file<>	|
 print<>|
 --------

This is because the program finds the bigrams 

 print<>line<>
 text<>line<>
 line<>file<> 

where word 'line' co-occurs with the words print, text and file which become 
the 1st order co-occurrences. 

(b)     The 2nd order co-occurrences of word 'line' can be found by 
	running kocos.pl with the following command -
        kocos.pl --literal line --order 2 test.input 

This will display the 2nd order co-occurrences of 'line' to standard output 
as shown below in the box.

 --------
 the<> 	|
 in<> 	|
 --------

This is because the program finds the words print, text and file as the 
first order co-occurrences (as explained in case a) and finds bigrams 

 print<>in<>
 text<>the<>
 file<>the<>
 file<>in

where 'the' and 'in' co-occur with the words print, text, file.  

(c)     To see how the 2nd order co-occurrences of word 'line' are reached 
	run the program using the following command -
        kocos.pl --order 2 --trace test.trace test.input line

This will display the 2nd order co-occurrences of 'line' to standard output
as shown below in the box.

 --------
 the<>   |
 in<>    |
 --------

and a detailed report of co-occurrence chains in test.trace file as shown 
in the box below. 

 test.trace =>
 
 ----------------
 line->text->the|
 line->file->the|
 line->file->in	|
 line->print->in|
 ----------------

where  
the first line shows that the word 'line' co-occurred with 'text' which
co-occurred with 'the'. Hence 'the' became a 2nd order co-occurrence. 
Similarly, 'line' co-occurred with 'file' which in turn co-occurred with 
'the' and 'in' which are therefore the 2nd order co-occurrences of 'line'.

=head2 11. References

[Niwa&Nitta94] Y. Niwa and Y. Nitta. Co-occurrence vectors from corpora 
vs. distance vectors from dictionaries. COLING-1994.

[Schutze98] H. Schutze. Automatic word sense discrimination. Computational
Linguistics,24(1):97-123,1998.

=head1 AUTHORS

 Amruta Purandare, pura0010@umn.edu
 Ted Pedersen, tpederse@umn.edu

 Last updated on 12/05/2003 by TDP 

This work has been partially supported by a National Science Foundation
Faculty Early CAREER Development award (#0092784).

=head1 BUGS

=head1 SEE ALSO

http://www.d.umn.edu/~tpederse/nsp.html

=head1 COPYRIGHT

Copyright (C) 2002-2003, Amruta Purandare and Ted Pedersen

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

#				Changelogs

# Date		Version		By		Changes			Code

# 03/30/2003	0.03		Amruta		Regex support for     ADP.03.1
#						specifying target
#						word
#
# 07/02/2003	0.05		Amruta		Redesigned algorithm  ADP.05	
#						to improve performance
#
###############################################################################

#                               THE CODE STARTS HERE

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# show minimal usage message if no arguments
if($#ARGV<0)
{
        &showminimal();
        exit;
}

# command line options
use Getopt::Long;
GetOptions ("help","version","order=i","trace=s","literal=s","regex=s");
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
# if the order is specified 
if(defined $opt_order)
{
	$order=$opt_order;
}
# otherwise set default to 1
else
{
	$order=1;
}

# trace report will show how 
# a Kth order co-occurrence is
# reached via a chain of 
# lower order co-occurrences
if(defined $opt_trace)
{
	$trace=$opt_trace;
}

# ----------------
# ADP.03.1 start
# ----------------
# this part has been added during NSP version 0.55 release

# target word is specified via --literal
if(defined $opt_literal)
{
        $target=$opt_literal;
}
# target specified as Perl regex/s in a file
if(defined $opt_regex)
{
        $regex_file=$opt_regex;
        if(!(-e $regex_file))
        {
                print STDERR "ERROR($0):
        Regex file <$regex_file> doesn't exist.\n";
                exit;
        }
        open(REG,$regex_file) || die "ERROR($0):
        Error(error code=$!) in opening Regex File <$regex_file>.\n";
        undef $target;
	while(<REG>)
        {
                chomp;
                s/^\s+//g;
                s/\s$//g;
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
                        exit;
                }
                if(/\/$/)
                {
                        s/\/$//;
                }
                else
                {
                        print STDERR "ERROR($0):
        Regular Expression <$_> should end with '/'\n";
                        exit;
                }
                $target.="(".$_.")|";
        }
	if(defined $target)
	{
		chop $target;
	}
	else
	{
		print "ERROR($0):
	No valid Perl regex found in Regex file <$regex_file>.\n";
		exit;
	}
}
# --------------
# ADP.03.1 end
# --------------

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#$0 contains the program name along with
#a complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the SOURCE file name...\n";
        exit;
}
#accept the input file name
$infile=$ARGV[0];
#check if exists
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Source file <$infile> doesn't exist...\n";
        exit;
}
#open if exists
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening <$infile> file.\n";

#check if the target word exists
if(!defined $target)
{
        print STDERR "ERROR($0):
        Please specify the target word using one of the --literal or --regex 
	options.\n";
        exit;
}

#check if order is valid
if($order<1)
{
	print STDERR "ERROR($0):
	Order should be greater than or equal to 1.\n"; 
	exit;
}
#check if --trace is used
if(defined $trace)
{
	$ans="n";
	#check if the TRACE_FILE already exists
	if(-e $trace)
	{
		print STDERR "WARNING($0):
	Trace file <$trace> already exists, overwrite(y/n)? ";
		$ans=<STDIN>;
	}
	if(!-e $trace || $ans=~/Y|y/)
	{
		#open the TRACE_FILE
		open(TRACE,">$trace") || die "Error($0):
        Error(code=$!) in opening Trace file <$trace>.\n";
	}
	else
	{
		undef $trace;
	}
}
##############################################################################

#			=============================
#			 Reading and Storing Bigrams
#			=============================

$line_num=0;
#creating a coc_store data structure for storing all bigram strings from SOURCE
#so that co-occurrences can be found looking at this data structure
while($line=<IN>)
{
	$line_num++;
        chomp $line;
	# handling blank lines
        if($line=~/^\s*$/)
        {
                next;
        }
	#store the bigram strings 
	if($line=~/<>/)
	{
		#checking if the SOURCE is a valid NSP output for Bigrams
		$check_bigram=$line;
		$cnt=0;
		#count how many times <> occurs
		while($check_bigram=~/<>/)
		{
			$cnt++;
			$check_bigram=$';
		}
		#should be 2 for bigrams
		if($cnt!=2)
		{
			print STDERR "ERROR($0):
	SOURCE file <$infile> is not a valid Bigram output of NSP at line 
	<$line_num>.\n";
			exit;
		}
		# store bigram in coc_store
		push @coc_store,$line;
	}
}

############################################################################

#		===========================================
#		 Ranking words according to their distance 
#			     From the target word 
#		===========================================

# start with target word which
# is at 0th level (rank)
$rank{$target}=0;
$word=$target;
while($rank{$word}<$order)
{
	# rank my co-occurrences 
	&rank_cocs($word,$rank{$word});
	# no more words in queue
	if($#words < 0)
	{
		if($rank{$word}<$order)
		{
			print "No co-occurrences at $order th level.\n";
		}
		last;
	}
	else
	{
		# get the first word from queue
	        $word=shift @words;
	}
}

#############################################################################

#			==============================
#			     Printing Trace Report 
#			==============================

# print trace report
if(defined $trace)
{
	# trace each kth order co-occurrence back
	foreach $word (@kocs)
	{
		# get all parents until the 
		# target word is reached
		@chain=();
		push @chain,$word;
		if(defined $regex_file)
		{
			while($word !~ /$target/)
			{
				push @chain,$parent{$word};
				$word=$parent{$word};
			}
		}
		else
		{
			while($word ne $target)
			{
				push @chain,$parent{$word};
                                $word=$parent{$word};
			}
		}
		# print reverse chain
		@reversed=reverse @chain;
		print TRACE join("->",@reversed);
		print TRACE "\n";
	}
}
###########################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------

# ranks and queues the co-occurrences of a given word
sub rank_cocs
{
	my $word=$_[0];	
	# co-occurrences of given word 
	# will be at rank(word)+1
	my $level=$_[1]+1;
	#string from the coc_store
	my $coc_string="";
	# check bigrams and rank words 
	# co-occurring with the given
	# word
	foreach $coc_string (@coc_store)
	{
		@parts=split(/<>/,$coc_string);
		$word1=$parts[0];
		$word2=$parts[1];
		# current word is the target word
		# specified via regex option
		undef $got_coc;
		if($level==1 && defined $regex_file)
		{
			# if exactly one of the words matches
			# the target, extract the other 
			if($word1=~/$word/ && !defined $rank{$word2} && $word2!~/$target/)
			{
				$got_coc=$word2;
				$parent=$word1;
			}
			elsif($word2=~/$word/ && !defined $rank{$word1} && $word1!~/$target/)
			{
				$got_coc=$word1;
				$parent=$word2;
			}
		}
		elsif(defined $regex_file)
		{
			# if one of the words matches the 
			# given word and other doesn't match
			# the target word
			if($word1 eq $word && !defined $rank{$word2} && $word2!~/$target/)
                        {
				$got_coc=$word2;
				$parent=$word1;
			}
                        elsif($word2 eq $word && !defined $rank{$word1} && $word1!~/$target/)
                        {
				$got_coc=$word1;
				$parent=$word2;
			}
		}
		else
		{
			# one of the words matches the 
			# given word
			if($word1 eq $word && !defined $rank{$word2})
			{
				$got_coc=$word2;
				$parent=$word1;
			}
			elsif($word2 eq $word && !defined $rank{$word1})
			{
				$got_coc=$word1;
				$parent=$word2;
			}
		}
		if(defined $got_coc)
                {
			# rank the obtained coc
			$rank{$got_coc}=$level;
			# queue the coc
			push @words,$got_coc;
			# print if level is K
			if($level==$order)
			{
				print "$got_coc<>\n";
			}
			# store link to parent for tracing
			if(defined $trace)
			{
				$parent{$got_coc}=$parent;
			        if($level==$order)
				{
					push @kocs,$got_coc;
				}
			}
		}
	}
}

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: kocos.pl [OPTIONS] BIGRAM";
        print "\nTYPE kocos.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  kocos.pl [OPTIONS] BIGRAM 
Displays the kth order Co-occurrences of a given target word.
Target word should be specified via --literal or --regex option.

BIGRAM
	A list of bigrams formatted like the output (extended or normal) 
	of NSP programs count.pl or statistic.pl.

OPTIONS:
--literal LITERAL 
	Specify the target word directly on command line as a literal.

--regex REGEXFILE
	Specify a file containing Perl regular expression/s that define 
	the target word.

--order K 
	Specify the value of K (K>0) to find the kth order co-occurrences. 
	A Kth order co-occurrence is a word that co-occurs with a (K-1)th 
	order co-occurrence of the target word. 
 
	By default, the value of K is set to 1 which simply lists the 
	words that co-occur with a given target word. When K is 2, all words 
	that co-occur with the words that co-occur with the target word are 
	shown, and so on for higher orders.
 
--trace TRACEFILE
	Specify the name of a TRACEFILE to see a detailed trace report 
	showing  the chains of co-occurrences. A chain shows how a Kth 
	order co-occurrence is reached as a sequence of K lower order 
	co-occurrences. 
		e.g. WORD->First->Second->Third..->Kth 
	shows that 'First' is a first order co-occurrence of WORD,  	
	'Second' is a second order co-occurrence of WORD which co-occurs 
	with 'First'. 'Third' is a third order co-occurrence of WORD which  
	co-occurs with 'Second' and so on until K is reached. 
--help
        To display this message.

--version
        To display the version information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
        print "kocos.pl       -        version 0.05\n";
        print "Copyright (C) 2002-2003, Amruta Purandare & Ted Pedersen\n";
        print "Date of Last Update: 07/01/2003\n";
}

#############################################################################


=head1 AUTHORS

 Amruta Purandare, University of Minnesota, Duluth,  pura0010@d.umn.edu
 Ted Pedersen, University of Minnesota, Duluth,  tpederse@umn.edu

=head1 BUGS

=head1 SEE ALSO

http://www.d.umn.edu/~tpederse/nsp.html

=head1 COPYRIGHT

Copyright (C) 2002-2003, Amruta Purandare & Ted Pedersen

This program is free software; you can redistribute it and/or modify it  
under the terms of the GNU General Public License as published by the Free  
Software Foundation; either version 2 of the License, or (at your option)  
any later version.

This program is distributed in the hope that it will be useful, but  
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License 
for more details.

You should have received a copy of the GNU General Public License along  
with this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut

