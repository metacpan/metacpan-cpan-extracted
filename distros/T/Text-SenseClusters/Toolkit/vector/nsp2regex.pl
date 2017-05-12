#!/usr/local/bin/perl -w

# THIS PROGRAM ORIGINALLY BELONGS TO THE SenseTools PACKAGE 
# (http://www.d.umn.edu/~tpederse/sensetools.html) DEVELOPED 
# BY SATANJEEV BANERJEE AND DR. TED PEDERSEN. IT HAS BEEN 
# INCLUDED IN SenseClusters DISTRIBUTION FOR CONVENIENCE REASONS.

# BELOW IS THE DOCUMENTATION THAT IS COMPILED FROM THE READMES' 
# OF THE SenseTools PACKAGE

=head1 NAME

nsp2regex.pl - Convert Text-NSP output into regular expressions to be used for feature matching

=head1 SYNOPSIS

 nsp2regex.pl [OPTIONS] SOURCE [[, SOURCE] ...]

=head1 DESCRIPTION 

Takes n-word sequences and represents them as regular 
expressions. These can then be used to identify lexical 
features in a given data, and convert a lexical element 
files from text into feature vectors.  

=head1 INPUT

=head2 Required Arguments:

=head3 SOURCE

The SOURCE is a file containing the list of features. 
The features are required to be in specific format:

 the_feature_token<>

 Unigram feature: temperature<>
 Bigram feature: daily<>temperature<>
 
count.pl or statistic.pl (both part of the Ngram Statistics Package) 
created output can be directly used as the SOURCE file. 

=head2 Optional Arguments

=head3 --token FILE       

Uses tokens contained in FILE to create the separator
between tokens, when window size of SOURCE n-gram is
greater than the 'n' of the n-gram. Window sizes for
n-grams in SOURCE can be defined using the --extended
option in count.pl.

=head3 --version          

Prints the version number.

=head3 --help             

Prints this help message.

=head1 OUTPUT

Outputs the generated regular expressions to stdout.

=head1 Explanation of the created Regular Expressions

=head2 Default Regular Expression (without Skipping Intermediate Tokens): 

By default nsp2regex.pl creates regex's that match space
separated tokens. The regular expressions that nsp2regex.pl creates 
are based on the assumption that the text on
which these regex's are going to be used has tokens separated by a
single space. Further the regular expressions thus created ignore XML
tags and non-tokens, as described in the examples above.

For example, the following line in the input to nsp2regex.pl:

 a<>bigram<>

is converted to the following regex: 

 /\s(<[^>]*>)*a(<[^>]*>)*\s(<[^>]*>\s)*(<[^>]*>)*bigram(<[^>]*>)*\s/ @name = a<>bigram

In this output, everything from the first / to the last / constitutes
the regular expression. The portion "@name = a<>bigram" is used by
xml2arff.pl (from SenseTools package) for giving a name to the attribute 
corresponding to this regular expression. 

=head2 What This Regular Expression will Match: 

This regular expression defines a feature that will match the tokens
"a" and "bigram" under the following conditions: 

 i>   Tokens "a" and "bigram" have exactly one space to their left and
      right. For example, this regex will match the sentence " this is a
      bigram ". This regex will not match the sentence " i wanna bigram "
      nor the sentence " i have a bigrams ". It will not even match " I
      have a    bigram ". This is because nsp2regex.pl creates regular
      expressions that assume that there is exactly ONE space character
      between tokens!

 ii>  Tokens "a" and "bigram" are bounded by one or more xml tags or
      non-tokens, that is a sequence of characters that start with '<'
      and end with '>'. eg: this regex will match the sentence : " this
      is a <head>bigram</head> ". This regex will also match " this is
      a <head>bigram<senseid=20/></head> ". 

 iii> tokens "a" and "bigram" are separated by one or more space
      separated xml tags.  eg: this regex will match the sentence " this
      is a <,> bigram ". It will also match " this is a <,> bigram <!>
      " and " this is a <,> <head>bigram</head> ". 

 iv>  combinations of the above cases. 

=head2 Explanation of this Regular Expression:

Following is an explanation of the various parts of the regular
expression: 

 /\s(<[^>]*>)*a(<[^>]*>)*\s(<[^>]*>\s)*(<[^>]*>)*bigram(<[^>]*>)*\s/ @name = a<>bigram


 a> All the portion between the first '/' and the last '/' is the regular
    expression. 

 b> The regular expression starts with requiring a single space
    character, \s. This is consistent with the assumption that every
    token has exactly one space to its left and one to its right.

 c> The next chunk is (<[^>]*>)*a(<[^>]*>)*
    Note that the portion (<[^>]*>) represents exactly our definition
    of an XML tag, namely that it should start with a '<', have 0 or
    more characters, except the '>' character, and then end with the
    '>' character. The '*' outside the bracket denotes that we are
    willing to match 0 or more such tags. After that, we wish to match
    a single occurrence of the first token, 'a', again followed by 0 or
    more tags. Note that the tags are "stuck" to the token 'a', in that
    there is no space between the tag and the token 'a'. Of course if
    in the text there is a space between an XML tag and 'a', then the
    space would match the space in <b> above. 

 d> Having matched token 'a' with 0 or more tags "stuck" to its right
    and left, we now wish to match exactly a single space character
    through the \s. Again this corresponds to our assumption that
    tokens in the text are separated by exactly one space character!

 e> The next chunk (<[^>]*>\s)* is again our familiar XML tag. This
    time we wish to "skip" over 0 or more occurrences of any XML tag
    that lie between the first and the second token, ie between 'a' and
    'bigram'. Since these are not "stuck" to the next token 'bigram',
    they are space separated from each other and from 'bigram'. Hence,
    for every token we match, we also match a space character!

 f> The next chunk is (<[^>]*>)*bigram(<[^>]*>)* which is exactly like
    the chunk for 'a' in point <c> above. 

 g> Finally we wish to match a single space character \s.

 h> The portion after the last '/' @name = a<>bigram creates a "name"
    for this feature. This name is used by xml2arff (from SenseTools 
    package) while creating the vector output of the input XML file. 
    While this name is not necessary, it makes the vector output more 
    human-readable.

=head2 Regular Expression with Skipping of Intermediate Tokens: 

nsp2regex.pl can create regular expressions that ignore
one or more tokens that occur between the tokens to be
matched. This can be switched "ON" by having the
directive "@count.WindowSize=..." in the input file to
nsp2regex.pl. We need to provide nsp2regex.pl with the same token file
we provide preprocess.pl... say following is the token file: 

 /<head>\w+<\/head>/
 /\w+/

Let the input file to the nsp2regex.pl program be the following: 

 @count.WindowSize=3
 a<>bigram<>

then, the output regular expression from nsp2regex.pl is: 

 
/\s(<[^>]*>)*a(<[^>]*>)*\s(<[^>]*>\s)*((<[^>]*>)*((<head>\w+<\/head>)|(\w+))(<[^>]*>)*\s(<[^>]*>\s)*){0,1}(<[^>]*>)*bigram(<[^>]*>)*\s/ @name = a<>bigram<>1

=head2 What This Regular Expression will Match: 

This regular expression will match the tokens "a" and "bigram"
separated by 0 or 1 occurrences of the white space separated token
((<head>\w+<\/head>)|(\w+)). This is the token definitions obtained
from the token.txt file above! 

For example, this regular expression will match the following
sentences: 

 " this is a funny bigram "
 " this is a bigram "
 " this is a <head>nice</head> bigram "
 " this is a <,> bigram "
 " this is a <,> <head>nice</head> bigram "

This regular expression will not match:

 " this is a really big bigram ",
 " i wanna write bigram ".
 " this is a , bigram ",

=head2 Explanation of this Regular Expression:

Following is a description of various parts of the regular expression: 

 
/\s(<[^>]*>)*a(<[^>]*>)*\s(<[^>]*>\s)*((<[^>]*>)*((<head>\w+<\/head>)|(\w+))(<[^>]*>)*\s(<[^>]*>\s)*){0,1}(<[^>]*>)*bigram(<[^>]*>)*\s/ @name = a<>bigram<>1

On careful observation one will notice that the above regular
expression differs from the previous regular expression (section 6.1.2)
in only one portion. 

Specifically the portion \s(<[^>]*>)*a(<[^>]*>)*\s(<[^>]*>\s)* is the
same as above... this matches a space, followed by 'a'
with XML tags or non-token characters (within <> brackets) stuck to
its left and right, followed by a single space, followed by 0 or more
XML tags and non-token characters, with a space after every such tag.

Further note that the portion (<[^>]*>)*bigram(<[^>]*>)*\s is again
the same as before... they match 'bigram' with XML tags and non-token
character tags stuck to its left and right, followed by a single
space.

Thus the only "new" portion in this regex is 

 ((<[^>]*>)*((<head>\w+<\/head>)|(\w+))(<[^>]*>)*\s(<[^>]*>\s)*){0,1}

We call this the "separator" portion of the regex; this is the portion
that allows for the "ignoring" of up to one token between the tokens
'a' and 'bigram'. This token can be either a <head>\w+</head> or a
\w+. 

 a> Observe that the entire section is within a pair of round brackets,
    followed by a {0,1}. This says that this portion is allowed to
    occur 0 or 1 times. This is consistent with the window size of
    3... besides 'a' and 'bigram', we allow at most one other token to
    come into the window. If our window size were to be 10 say, this
    would be {0,8}.

 b> The first part inside this bracketed portion is 
    (<[^>]*>)*((<head>\w+<\/head>)|(\w+))(<[^>]*>)*. This says that we
    are willing to match either a <head>\w+</head> or a \w+. Further
    whatever we match can be preceeded or followed by an XML tag or a
    non-token character ensconced with the angular brackets <>. 

 c> Having matched either of the two options, we wish to match a single
    space, \s, followed by one or more XML tags or non-tokens, in
    keeping with our desire to skip these tags!

 e> And, as mentioned in <a> above, we would like to do this matching
    at most once, that is there will be at most one such token between
    'a' and 'bigram'. 

 f> The name of the feature has also changed to @name = a<>bigram<>1
    implying that we are allowing at most one token to come in between
    our two main tokens!

=head2 A Fine Point about nsp2regex.pl:

Fine Point 1: Certain characters, like '.', '*', '?' etc have special
meaning when used within a regular expression. If these characters
occur in the tokens that the regular expression is being built from,
they are "escaped" (by prepending them with a slash '\'). Following is
a list of characters that are so escaped: '\', '/', '|', '(', ')',
'[', ']', '{', '}', '^', '$', '*', '+', '?' and '.'

=head1 AUTHORS

 Satanjeev Banerjee, Carnegie-Mellon University

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2001-2008, Satanjeev Banerjee and Ted Pedersen

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

# nsp2regex.pl version 0.3
# Program to create regex's from output of count.pl or statistic.pl
#
##############################################################################
#                                 ChangeLog
# 
# May 10, 2003 TDP renamed bsp2regex as nsp2regex 
#
##############################################################################

#-----------------------------------------------------------------------------
#                              Start of program
#-----------------------------------------------------------------------------

# we have to use commandline options, so use the necessary package!
use Getopt::Long;

# first check if no commandline options have been provided... in which case
# print out the usage notes!
if ( $#ARGV == -1 )
{
    &minimalUsageNotes();
    exit;
}

# now get the options!
GetOptions("version", "help", "token=s", "sort" );

# if help has been requested, print out help!
if ( defined $opt_help )
{
    $opt_help = 1;
    &showHelp();
    exit;
}

# if version has been requested, show version!
if ( defined $opt_version )
{
    $opt_version = 1;
    &showVersion();
    exit;
}

# get the separator token!
if ( defined $opt_token )
{
    if ( !( -e $opt_token))
    {
	print "Cant find token definition file $opt_token.\n";
	askHelp();
	exit;
    }
    
    open TOKEN, $opt_token || die "Couldnt open $opt_token\n";
    
    while(<TOKEN>)
    {
	chomp;
	s/^\s*//g;
	s/\s*$//g;
	if (length($_) <= 0) { next; }
	if (!(/^\//) || !(/\/$/))
	{
	    print STDERR "Ignoring regex with no delimiters: $_\n";
	    next;
	}
	s/^\///;
	s/\/$//;
	push @tokenRegex, $_;
    }
    close TOKEN;
}
else 
{
    push @tokenRegex, "\\w+";
    push @tokenRegex, "[\.,;:\?!]";
}

# create the complete token regex
$tokenizerRegex = "";

foreach $token (@tokenRegex)
{
    if ( length($tokenizerRegex) > 0 ) 
    {
	$tokenizerRegex .= "|";
    }
    $tokenizerRegex .= "(";
    $tokenizerRegex .= $token;
    $tokenizerRegex .= ")";
}

# if you dont have any tokens to work with, abort
if ( $#tokenRegex < 0 ) 
{
    print "No token definitions to work with.\n";
    askHelp();
    exit;
}

$tokenizerRegex = "((<[^>]*>)*(" . $tokenizerRegex . ")(<[^>]*>)*\\s(<[^>]*>\\s)*)";

# now the meaty part!

while ( <> ) 
{
    chomp;
    
    if ( /^@/ && !(/^@@/) )
    {
	
	if ( $_ =~ /^@[^\.]*.WindowSize/ ) 
	{ 
	    s/^[^=]*=//;
	    $declaredWindowSize = $_;
	}
	next;
    }
    
    if ( /^@@/ ) { s/^@@/@/; }
    if (!(/<>/)) { next; }

    @words = split(/<>/);
    if ( $_ !~ /<>$/ ) { pop @words; }

    # if no words, then quit 
    if (!(@words)) { next; }

    # create the name using the <> 
    $name = join ("<>", @words);

    if (defined $declaredWindowSize) 
    {
	$windowSize = $declaredWindowSize - $#words - 1;
    }
    else 
    {
	$windowSize = 0;
    }

    # stick the window size in if windowSize > 0
    if ( $windowSize ) { $name .= "<>" . $windowSize; }
    
    # escape all the words 
    for ($i = 0; $i <= $#words; $i++)
    {
	$words[$i] = escape($words[$i]);
    }

    # wrap all the words in tags
    for ($i = 0; $i <= $#words; $i++)
    {
	$words[$i] = "(<[^>]*>)*" . $words[$i] . "(<[^>]*>)*";  
    }

    # create the separator
    $separator = "\\s(<[^>]*>\\s)*";  
    if ( $windowSize >= 1 )
    { 
	$separator .= $tokenizerRegex . "\{0,$windowSize\}";
    }

    $regex = join($separator, @words);
    $regex = "/\\s" . $regex . "\\s/";

    print "$regex \@name = $name\n";
}

# function to escape a punctuation mark, if necessary
sub escape
{
    my $param = shift;
    $param =~ s/([\\\/\|\(\)\[\]\{\}\^\$\*\+\?\.])/\\$1/g;
    return $param;
}

# function to output a minimal usage note when the user has not provided any
# commandline options
sub minimalUsageNotes
{
    print "Usage: nsp2regex.pl [OPTIONS] SOURCE [[, SOURCE] ...]\n";
    askHelp();
}

# function to output help messages for this program 
sub showHelp 
{
    print "Usage: nsp2regex.pl [OPTIONS] SOURCE [[, SOURCE] ...]\n\n";

    print "Converts n-grams in SOURCE to regular expressions. SOURCE must be the output of\n";
    print "count.pl or statistic.pl (both part of the Ngram Statistics Package).\n";
    print "Regular expressions are output to stdout.\n\n";

    print "OPTIONS:\n\n";

    print "  --version          Prints the version number.\n\n";

    print "  --help             Prints this help message.\n\n";

    print "  --token FILE       Uses tokens contained in FILE to create the separator\n";
    print "                     between tokens, when window size of SOURCE n-gram is\n";
    print "                     greater than the 'n' of the n-gram. Window sizes for\n";
    print "                     n-grams in SOURCE can be defined using the --extended\n";
    print "                     option in count.pl.\n\n";
}

# function to output the version number
sub showVersion
{
#    print "nsp2regex.pl  -  Version 0.3\n";
#    print "A component of the SenseTools Version 0.3\n";
#    print "Copyright (C) 2001-2002, Ted Pedersen & Satanjeev Banerjee\n";
#    print "Date of Last Update: May 10, 2003\n";
     print '$Id: nsp2regex.pl,v 1.5 2008/03/30 04:40:58 tpederse Exp $';
     print "\nConvert Text-NSP output to regular expressions for use in feature matching\n";
}

# function to output "ask for help" message when the user's goofed up!
sub askHelp
{
    print STDERR "Type nsp2regex.pl --help for help.\n";
}


