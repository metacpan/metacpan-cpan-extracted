#!/usr/local/bin/perl -w

# THIS PROGRAM ORIGINALLY BELONGS TO THE SenseTools PACKAGE 
# (http://www.d.umn.edu/~tpederse/sensetools.html) DEVELOPED 
# BY SATANJEEV BANERJEE AND TED PEDERSEN. IT HAS BEEN 
# INCLUDED IN SenseClusters DISTRIBUTION AS A CONVENIENCE.

# BELOW IS THE DOCUMENTATION THAT IS COMPILED FROM THE README 
# FROM THE SenseTools PACKAGE

=head1 NAME

preprocess.pl - Split Senseval-2 data file into one file per lexical  
item (lexelt), and carry out various tokenization and formatting tasks

=head1 SYNOPSIS

preprocess.pl [OPTIONS] SOURCE

=head1 DESCRIPTION

Takes an xml file in SENSEVAL-2 lexical-sample format and splits it 
apart into as many files as there are lexical elements in the original 
file. Each lexical element usually corresponds with a word used in a 
particular part of speech. It also does other sundry preprocessing 
tasks with the data such as splitting it into training and test 
portions, tokenizing, and providing various formatting options. It can 
also create plain text versions of the xml files, which can be useful 
when needed as training data. 

=head1 INPUT

=head2 Required Arguments:

=head3 SOURCE

Senseval2 formatted input file.

=head2 Optional Arguments

=head4 --token FILE       

Reads tokens from FILE. The context of each instance
is broken up into tokens and each pair of consecutive tokens
are separated by white space. Non-white space characters
which do not belong to any token are put between angular
brackets. If this option is not used, the default token
definitions of count.pl are assumed.

=head4 --removeNotToken   

Removes strings that do not match token file. If not\n";    
specified, the non-matching strings are put within angular\n";
brackets, ie, <>

=head4 --nontoken FILE    

Removes all characters sequences that match Perl
regular expressions specified in FILE.	

=head4 --noxml

Does not output an xml file.

=head4 --xml FILE

Outputs the changed xml file to FILE. If this option nor
the option --noxml is provided, the file name is derived
by concatenating the word in the <lexelt> tag with \".xml\".
Note: if this option is used, separate lexelt items will
not be split into separate files.

=head4 --nocount          

Does not output a NSP-ready file.

=head4 --count FILE       

Outputs just the part between <context> </context> (after
modification) to FILE. FILE can then be used directly with
NSP. If this option nor the option --nocount is provided,
the file name is derived as in xml above, with a .count
extension.
Note: if this option is used, separate lexelt items will
not be split into separate files.

=head4 --useLexelt        

Includes a tag <lexelt=WORD/> within the <head></head>
tags, where WORD is the word in the immediately preceeding
<lexelt> tag.

=head4 --useSenseid       

Includes a tag <senseid=XXXXX/> within the <head></head>
tags, where XXXXX is the number in the immediately
preceeding <answer> tag.

=head4 --split N          

Shuffles the instances in SOURCE and then splits them into
two files, a training file and a test file, approximately
in the ratio N:(100-N).

=head4 --seed N           

Sets the seed for the random number generator used during
shuffling. If not used, no seeding is done (except for
that provided automatically by perl)

=head4 --putSentenceTags  

Puts separate lines within the <context> </context> region
within <s> </s> pairs of tags. If separate sentences are on
seperate lines, these tags effectively denote the start and
end of sentences.

=head4 --version          

Prints the version number.

=head4 --help             

Prints this help message.

=head4 --verbose          

Turns on verbose mode. Silent by default.

=head2 OUTPUT

1. The modified/processed Input SENSEVAL-2 (*.xml) file, if --noxml option is not specified.

2. The Ngram Statistics Package (NSP) ready (*.count) file, if --nocount is not specified.

3. The *-test and *-training files if the --split option is used.

=head1 An Example SENSEVAL-2 File

The following is an example SENSEVAL-2 file that we will refer to
later in as example.xml 

 <corpus lang='english'>
  <lexelt item="art.n">
    <instance id="art.40001">
      <answer instance="art.40001" senseid="art~1:06:00::"/>
      <answer instance="art.40001" senseid="fine_art%1:06:00::"/>
      <context>
        <head>Art</head> you can dance to from the creative group
        called Halo.
      </context>
    </instance>
    <instance id="art.40002">
      <answer instance="art.40002" senseid="art_gallery~1:06:00::"/>
      <context>
        There's always one to be heard somewhere during the summer in
        the piazza in front of the <head>art</head>gallery and town
        hall or in a park.
      </context>
    </instance>
    <instance id="art.40005" docsrc="bnc_ckv_938">
    <answer instance="art.40005" senseid="art~1:04:00::"/>
      <context>
        Paintings, drawings and sculpture from every period of
        <head>art</head> during the last 350 years will be on display.
      </context>
    </instance>
  </lexelt>
  <lexelt item="authority.n">
    <instance id="authority.40001">
      <answer instance="authority.40001" senseid="authority~1:14:00::"/>
      <context>
        Not only is it allowing certain health
        <head>authorities</head>to waste millions of pounds on
        computer systems that dont work, it also allowed the London
        ambulance service to put lives at risk with a system that had
        not been fully proven in practice.
      </context>
    </instance>
  </lexelt>
 </corpus>

Here we have two lexelts, "art.n" and "authority.n", where "n" denotes
that these are noun senses of the words. We have three instances of
art with instance id's art.40001, art.40002 and art.40007
respectively, and one instance of authority with instance id
authority.40001. The first instance has two answers, while the others
have one each. 

=head1 Detailed Description

=head2 Tokenization of Text

preprocess.pl accepts regular expressions from the user and
then "tokenizes" the text between the <context> </context> tags. This
is done to simplify the construction of regular expressions in program
nsp2regex.pl and to achieve optimum regular expression matching in
xml2arff.pl. Following is a description of the tokenization process.

The text within the <context> </context> tags is considered as one
string, the "input" string. This algorithm takes this input string and
creates an "output" string where tokens are identified and separated
from each other by a SINGLE space. Regex's provided by the user are
checked against the input string to see if a sequence of characters
starting with the first character of the string match against any of
these regex's. As soon as a we find a regular expression that does
match, this checking is halted, the matched sequence of characters is
removed from the string and appended to an "output" string with
exactly one space to its left and right. If none of the regex's match
against the starting characters of the input string, the first
character is considered a "non-token". By default this non token is
placed in angular brackets (<>) and then put into the output string
with one space to its left and right. This process is continued until
the input string becomes empty. This process is restarted for the next
instance.

For example, assume we provide the following regular expressions to
preprocess.pl:

<head>\w+</head>
\w+

The first regular expression says that a sequence of characters
starting with "<head>", having an unbroken sequence of alphanumeric
characters and finally ending with a "</head>" is a valid token. Also,
an unbroken sequence of alphanum characters makes a token.

Then, assuming that the following text occurs within the <context>
</context> tags of an instance: 

No, he has no <head>authority</head> on this!

preprocess.pl would then convert this text to: 

 No <,> he has no <head>authority</head> on this <!> 

Observe that "No", "he", "has", "no", "<head>authority</head>", etc
are all the tokens, while "," and "!" arent tokens and so have been
put into angular brackets. Further observe that each token has exactly
one space to its left and right.

One can provide a file containing regular expressions to preprocess.pl
using the switch --token. In this file, each regular expression should
be on a line of its own and should be preceeded and succeeded with '/'
signs. Further these should be perl regular expressions.

Thus our regular expressions above would look like so: 

 /<head>\w+<\/head>/
 /\w+/

We shall call the file these regular expressions lie in
"token.txt". Then, we would run preprocess.pl on example.xml with this
token file like so:

 preprocess.pl example.xml --token token.txt

=head2 Various Issues of Tokenization wrt preprocess.pl

=head2 Default Regular Expressions:

Although
tokenization is best controlled via a user specified tokenization file
designated via the --token option, there is also a default definition
of tokens that is used in the absence of a tokenization file, which
consists of the following:

 /w+/
 /[\.,;:\?!]/ 

According to this definition, a token is either a single punctuation
mark from the specified class, or it is a string of alpha-numeric
characters. Note that this default definition is generally not a good
choice for XML data since it does not treat XML tags as tokens and
will result in them "breaking apart" during pre-processing. For
example, given this default definition, the string :

 <head>art</head>

will be represented by preprocess.pl as 

 <<> head <>> art <<> </> head <>>

which suggests that "<", ">", and "/" are non-tokens, while "art" and
"head" are. This is unlikely to provide useful information. 

These defaults correspond to those in NSP, which is geared towards
plain text. These are provided as a convenience, but in general we
recommend against relying upon them when processing XML data. 

=head2 Regular Expression /\S+/:

Assume that the only regular expression in our token file token.txt is
/\S+/. This regular expression says that any sequence of
non-white-space characters is a token. Now, if we run the program like
so:

preprocess.pl example.xml --token token.txt 

(where example.xml is the example xml file described in the previous section 
and token.txt is the file that contains the above regular
expressions /\S+/).

We would get all the four files, art.n.xml, art.n.count,
authority.n.xml and authority.n.count. From here on we shall show only
the "authority" files to save space; it is understood that the art
files are also created.

File authority.n.xml: 

 <corpus lang='english'>
 <lexelt item="authority.n">
 <instance id="authority.40001">
 <answer instance="authority.40001" senseid="authority~1:14:00::"/>
 <context>

 Not only is it allowing certain health <head>authorities</head>to waste millions of pounds on computer systems that dont work, it also allowed the London ambulance service to put lives at risk with a system that had not been fully proven in practice. 
 </context>
 </instance>
 </lexelt>
 </corpus>

File authority.n.count: 

Not only is it allowing certain health <head>authorities</head> 
to waste millions of pounds on computer systems that dont work, 
it also allowed the London ambulance service to put lives at 
risk with a system that had not been fully proven in practice. 

Note that every character is a part of some sequence of
non-white-space characters, and is therefore part of some token. Hence
no character is put into <> brackets. Also, each
non-white-space-character-sequence, that is each token, is placed in
the output with exactly one space character to its left and right. 


=head2 Regular Expression /\w+/: 

On the other hand if our token file token.txt were to contain the
following regex which treats every sequence of alpha numeric
characters as a token:

 /\w+/

... and we were to run the program like so: 

 preprocess.pl example.xml --token token.txt

... then our authority files would like like so: 

File authority.n.xml: 

 <corpus lang='english'>
 <lexelt item="authority.n">
 <instance id="authority.40001">
 <answer instance="authority.40001" senseid="authority~1:14:00::"/>
 <context>
  Not only is it allowing certain health <<> head <>> authorities 
 <</> head <>> to waste millions of pounds on computer systems that dont 
 work <,> it also allowed the London ambulance service to put lives at 
 risk with a system that had not been fully proven in practice <.> 
 </context>
 </instance>
 </lexelt>
 </corpus>

File authority.n.count: 

 Not only is it allowing certain health <<> head <>> authorities 
 <</> head <>> to waste millions of pounds on computer systems that 
 dont work <,> it also allowed the London ambulance service to put 
 lives at risk with a system that had not been fully proven in practice <.> 

Note again that since the '<' and '>' of the head tags are not
alpha-numeric characters they are considered as "non-token"
characters, and are put within the <> tags. Further note that if there
are more than one such non-token characters one after another, they
get put into one pair of diamond brackets '<' and '>'. As mentioned
before, the user should include regular expressions that
preserve the tags. Thus for the above example, a regular expression
like /<head>\w+<\/head>/ would work admirably.

=head2 Other Useful Regular Expressions in the Token File:

Besides the regular expressions <head>\w+</head> and \w+, we have
found the following regular expressions useful too.

 /[\.,;:\?!]/  - This states that a single occurrence of one of the
                 puncutation marks in the list is a token. This helps
                 us specify that a puncutation mark is indeed a token
                 and should not be ignored! Further, this allows us to
                 create features consisting of punctuation marks using
	         SenseClusters.

 /&([^;]+;)+/  - The XML format forces us to replace certain meta
                 symbols in the text by their standard formats. For
                 example, if the '<' symbol occurs in the text, it is
                 replaced with "&lt;". Similarly, '-' is replaced with
                 "&dash;". This regular expression recognizes these
                 constructs as tokens instead of breaking them up!

=head2 Order of Regular Expressions Is Important: 

Recall that at every point of the "input string", the matching
mechanism marches down the regular expressions in the order they are
provided in the input regular expression file, and stops at the FIRST
regular expression that matches. Thus the order of the regular
expression makes a difference. For example, say our regular expression
file has the following regular expressions in this order: 

 /he/
 /hear/
 /\w+/

and our input text is "hear me"

Then our output text is " he ar me "

On the other hand, if we reverse the first two regular expressions

 /hear/
 /he/
 /\w+/

we get as output " hear me "

Thus as expected, the order of the regular expressions define how the
output will look. 

=head2 Redundant Regular Expressions:

Consider the following regular expressions: 

 /\S+/
 /\w+/

As should be obvious, every token that matches the second regular
expression matches the first one too. We say that the first regular
expression "subsumes" the second one, and the second regular
expression is redundant. This is because the matching mechanism will
always stop at the first regular expression, and never get an
opportunity to exercise the second one. Note of course that this does
not adversely affect anything.

=head2 Ignoring Non-Tokens using --removeNotToken:

Recall that characters in the input string that do not match any regular  
expression as defined in token are put into angular (<>) brackets.   You  
may, if you wish, remove these "non tokens", that is not have them appear  
in the output xml and count files, by using the switch --removeNotToken. 

Thus, for the following text: 

No, he has no <head>authority</head> on me!

and with regular expressions 

 <head>\w+</head>
 \w+

and if we were to run the program with the switch --removeNotToken,
preprocess.pl would convert the text into: 

 No he has no <head>authority</head> on me 

=head2 Ignoring Non-Tokens using --nontoken:

The --nontoken option allows a user to specify a list of regular
expressions. Any strings in the input file that match this list
are removed from the file prior to tokenization. 

It's important to note the order in which tokenization occurs.
First, those strings that match the regexes defined in nontoken
are removed. Then the strings that match the regexes defined in
token are matched. Those tokens that do not match the token
regexes are then removed. Thus, the "order" of precedence during
tokenization is:

 -nontoken
 -token
 -removeNotToken

=head2 XML output: 

By default, for each lexical element "word" in the training or test
file (in the lexical sample of SENSEVAL-2), preprocess.pl creates a
file of the name "word".xml. For example for the file example.xml,
preprocess.pl will create files art.n.xml and authority.n.xml if it
is run as follows: 

 preprocess.pl example.xml --token token.txt 

File art.n.xml: 

 <corpus lang='english'>
 <lexelt item="art.n">
 <instance id="art.40001">
 <answer instance="art.40001" senseid="art~1:06:00::"/>
 <answer instance="art.40001" senseid="fine_art%1:06:00::"/>
 <context>
  <head>Art</head> you can dance to from the creative group called Halo <.> 
 </context>
 </instance>
 <instance id="art.40002">
 <answer instance="art.40002" senseid="art_gallery~1:06:00::"/>
 <context>
  There <'> s always one to be heard somewhere during the summer in the piazza in front of the <head>art</head> gallery and town hall or in a park <.> 
 </context>
 </instance>
 <instance id="art.40005" docsrc="bnc_ckv_938">
 <answer instance="art.40005" senseid="art~1:04:00::"/>
 <context>
  Paintings <,> drawings and sculpture from every period of <head>art</head> during the last 350 years will be on display <.> 
 </context>
 </instance>
 </lexelt>
 </corpus>

File authority.n.xml: 

 <corpus lang='english'>
 <lexelt item="authority.n">
 <instance id="authority.40001">
 <answer instance="authority.40001" senseid="authority~1:14:00::"/>
 <context>
  Not only is it allowing certain health <head>authorities</head> to waste millions of pounds on computer systems that dont work <,> it also allowed the London ambulance service to put lives at risk with a system that had not been fully proven in practice <.> 
 </context>
 </instance>
 </lexelt>
 </corpus>

Observe of course that the text within the <context> </context> region
has been tokenized as described previously according to the regular
expressions in file token.txt.

This default behavior can be stopped either by using the switch --xml
FILE, by which only one FILE is created, or by using the switch
--noxml, by which no xml file is created.

=head2 Count output: 

Besides creating xml output, this program also creates output that can
be used directly with the program count.pl (from the Ngram Statistics
Package). After tokenizing the region within the <context>
</context> tags of each instance, the program puts together ONLY these
pieces of text to create "count.pl ready" output. This is because
count.pl assumes that all tokens in the input file needs to be
"counted" and generally we are only interested in the "contextual"
material provided in each instance, and not the tags that occur
outside the <context> </context> region of text.

By default, for each lexical element "word", this program creates a
file of the name word.count. For example, for the file example.xml, we
would get the files art.n.count and authority.n.count.

File art.n.count: 

 <head>Art</head> you can dance to from the creative group called Halo <.> 
 There <'> s always one to be heard somewhere during the summer in the piazza in front of the <head>art</head> gallery and town hall or in a park <.> 
 Paintings <,> drawings and sculpture from every period of <head>art</head> during the last 350 years will be on display <.> 

File authority.n.count: 

 Not only is it allowing certain health <head>authorities</head> to waste millions of pounds on computer systems that dont work <,> it also allowed the London ambulance service to put lives at risk with a system that had not been fully proven in practice <.> 

This default behavior can be stopped either by using the switch
--count FILE, by which only one FILE is created, or by using the
switch --nocount, by which no count file is created.

Note that the --xml/--noxml switches and the --count/--nocount
switches are independant of each other. Thus, although providing --xml
FILE or --noxml switchs produces a single xml FILE or no xml file at
all, you will still get all the count files, unless you also give the
--count FILE or --nocount switches. Similarly, providing the --count
FILE or --nocount switches does not affect the production of the xml
files.


=head2 Information Insertion

=head3 Inserting lexelt and senseId Information:

The lexelt information and the senseId information are outside the
<context> </context> region. This program gives you the
capability to bring these pieces of information inside the context.

Switch --useLexelt puts the tag <lexelt=WORD/> within the
<head></head> tags, where WORD is the word in the immediately
preceding <lexelt> tag.

Switch --useSenseid puts the tag <senseid=XXXXX/> within the
<head></head> tags, where XXXXX is the number in the immediately
preceding <answer> tag.

For example, running the program like so:

 preprocess.pl example.xml --useLexelt --useSenseid --token token.txt

produces this for authority.n.xml:

 <corpus lang='english'>
 <lexelt item="authority.n">
 <instance id="authority.40001">
 <answer instance="authority.40001" senseid="authority~1:14:00::"/>
 <context>
 Not only is it allowing certain health <head> authorities <lexelt=authority.n/><senseid=authority~1:14:00::/></head> to waste millions of pounds on computer systems that dont work , it also allowed the London ambulance service to put lives at risk with a system that had not been fully proven in practice . 
 </context>
 </instance>
 </lexelt>
 </corpus>

Note that the extra information is put inside the <head> </head>
region. Hence the user has to provide a token file that will preserve
these <head> </head> tags. For instance, as shown in the previous
section, if one were to rely on the default regex's, these tags would
not be preserved (the '<' and '>' would be considered non-token
symbols) and the lexelt and senseid information would not be included
within the tags.

So for example, the following regular expression file is adequate: 

 <head>\w+</head>
 \w+

=head3 Inserting Sentence-Boundary Tags

The english lexical sample data available from SENSEVAL-2 is such that
each sentence within the <context> </context> tags is on a line of its
own. This human-detected sentence boundary information is usually lost
in preprocess.pl, but can be preserved using the switch
--putSentenceTags. This puts each line within <s> and </s>
tags. Assuming that each sentence was originally on a line of its own,
then <s> marks the start of a sentence and </s> marks its end. Note
that no sentence boundary detection is done: if the end of line
character (\n) does not match the end of a sentence, then the <s> </s>
tags will not be indicative of a sentence boundary either.

For example, assume the following is our source xml file, source.xml:

 <corpus lang='english'>
 <lexelt item="word">
 <instance id="word.1">
 <answer instance="word.1" senseid="1"/>
 <context>
 This is the first line
 This is the second line
 This is the last line for <head>word</head>
 </context>
 </instance>
 </lexelt>
 </corpus>

Further assume our token file is this: 

 /<head>\w+</head>/
 /<s>/
 /<\/s>/
 /\w+/

Running preprocess.pl like so: 

 preprocess.pl --token token.txt source.xml 

Produces the following word.xml file:

 <corpus lang='english'>
 <lexelt item="word">
 <instance id="word.1">
 <answer instance="word.1" senseid="1"/>
 <context>
  This is the first line This is the second line This is the last line for <head>word</head> 
 </context>
 </instance>
 </lexelt>
 </corpus>

and the following word.count file:

 This is the first line This is the second line This is the last line for <head>word</head> 

However, running preprocess.pl like so:

 preprocess.pl --token token.txt --putSentenceTags source.xml

Produces the following word.xml file: 

 <corpus lang='english'>
 <lexelt item="word">
 <instance id="word.1">
 <answer instance="word.1" senseid="1"/>
 <context>
  <s> This is the first line </s> <s> This is the second line </s> <s> This is the last line for <head>word</head> </s> 
 </context>
 </instance>
 </lexelt>
 </corpus>

and the following word.count file:

 <s> This is the first line </s> <s> This is the second line </s> <s> This is the last line for <head>word</head> </s> 

Note that the <s> and </s> tags are placed into the data BEFORE the
tokenization process. Hence a token regular expression that preserves
these tags is required! The token file shown above is adequate for
this.

=head2 Splitting Input Lexical Files

Besides splitting the lexical elements into separate files,
preprocess.pl also allows you to split the instances of a single
lexical element into separate "training" and "test" files. 

If one has a corpus of sense-tagged text, it is
often desirable to divide that sense tagged text into training and
test portions in order to develop or tune  a methodology. This is the
intention of the --split option.   

The --split option of preprocess.pl allows you to specify an integer
N... the instances of each lexical element in the input XML SOURCE
file are split into two files approximately in the ratio N:(100-N).

If an output XML file "foo" is specified through the switch --xml then
two files, foo-training.xml and foo-test.xml are created.

If an output count file "foo" is specified through the switch --count
then two files, foo-training.count and foo-test.count are created.

Creation of Xml and count output files can be suppressed by using the
--noxml and --nocount switches respectively. 

If neither --noxml nor --xml switches are used, then files of the type
word-training.xml, word-test.xml are created.

If neither --nocount nor --count switches are used, then files of the
type word-training.count, word-test.count are created.

The instances are shuffled before being put into training and test
files. Perl automatically seeds the randomizing process... but you can
specify your own seed using the switch --seed.

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

# preprocess.pl version 0.3
#
# Program to take a Senseval training data file and convert it into the format
# required by xml2arff and, optionally, by NSP
#
#
###############################################################################
#
#                       -------         CHANGELOG       ---------
#
# version        date           programmer      List of changes    change-id
#
# 0.3            01/18/2003      Amruta          Introduced
#                                               --nontoken option    ADP.3.1
# 0.3            05/10/2003      Ted             split loop fix      TDP.3.1
#
###############################################################################
#
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
GetOptions("version", "help", "verbose", "useLexelt", "useSenseid", "count=s", 
	   "xml=s", "noxml", "nocount", "split=i", "token=s", "seed=i", "removeNotToken",
	   "putSentenceTags","nontoken=s");

# if help has been requested, print out help!
if ( defined $opt_help )
{
    $opt_help = $opt_help;
    &showHelp();
    exit;
}

# if version has been requested, show version!
if ( defined $opt_version )
{
    $opt_version = $opt_version;
    &showVersion();
    exit;
}

$opt_removeNotToken = 1 if ( defined $opt_removeNotToken);

# seed if defined
if ( defined $opt_seed)
{
    srand($opt_seed);
}

# create count-style tokenizer regex from -token file, if supplied, or by using 
# the defaults that count uses.

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

# ---------------
# ADP.3.1 start
# ---------------
# Introducing --nontoken option to specify what is not a valid token.
# The designated file contains regular expressions that define strings
# that should not be considered tokens. Any string that matches these
# will be removed. Note that nontoken take precedence over token.

if(defined $opt_nontoken)
{
        #check if the file exists
        if(-e $opt_nontoken)
        {
               #open the non token file
                open(NOTOK,"$opt_nontoken") || die "Couldn't open Nontoken file $opt_nontoken.\n";
                while(<NOTOK>)
                {
                        chomp;
                        s/^\s+//;
                        s/\s+$//;
                        #handling a blank lines
                        if(/^\s*$/)
                        {
                                next;
                        }

                        if(!(/^\//))
                        {
                                print STDERR "Nontoken regular expression $_ should start with '/'\n";
                                exit;
                        }
                        if(!(/\/$/))
                        {
                                print STDERR "Nontoken regular expression $_ should end with '/'\n";
                                exit;
                        }
                        #removing the / s from the beginning and the end
                        s/^\///;
                        s/\/$//;
                        #form a single regex
                        $non_token_regex.="(".$_.")|";
                }
               # if no valid regexs are found in Nontoken file
                if(length($non_token_regex)<=0)
                {
                        print STDERR "No valid Perl Regular Experssion found in Nontoken file $opt_nontoken.\n";
                        exit;
                }
                chop $non_token_regex;
        }
        else
        {
                print STDERR "Nontoken file $opt_nontoken doesn't exist.\n";
                exit;
        }
}
# End of --nontoken option functionality
# -------------
# ADP.3.1 end
# -------------

# if count file has been specified, try to open it for writing!
if ( defined $opt_count )
{
    # if split not defined, open normally...
    if ( !defined $opt_split )
    {
	if ( -e $opt_count )
	{
	    print "File $opt_count exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ($reply ne "Y");
	}
	open ( COUNT, ">$opt_count" ) || die "Couldnt open $opt_count\n";
    }
    # else open two separate file: training and test!
    else
    {
	my $training = $opt_count . "-training";
	if ( -e $training )
	{
	    print "File $training exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ( $reply ne "Y" );
	}
	open ( COUNT_TRAIN, ">$training" ) || die "Couldnt open $training\n";
	
	my $test = $opt_count . "-test";
	if ( -e $test )
	{
	    print "File $test exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ( $reply ne "Y" );
	}
	open ( COUNT_TEST, ">$test" ) || die "Couldnt open $test\n";
    }
}

# if xml file has been specified, try to open it for writing!
if ( defined $opt_xml )
{
    if ( !defined $opt_split )
    {
	if ( -e $opt_xml )
	{
	    print "File $opt_xml exists! Overwrite (Y/N)? "; 
	    $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ($reply ne "Y");
	}
	open ( XML, ">$opt_xml" ) || die "Couldnt open $opt_xml\n";
    }
    # else open two separate file: training and test!
    else
    {
	my $training = $opt_xml . "-training";
	if ( -e $training )
	{
	    print "File $training exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ( $reply ne "Y" );
	}
	open ( XML_TRAIN, ">$training" ) || die "Couldnt open $training\n";
	
	my $test = $opt_xml . "-test";
	if ( -e $test )
	{
	    print "File $test exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ( $reply ne "Y" );
	}
	open ( XML_TEST, ">$test" ) || die "Couldnt open $test\n";
    }
}

if ( defined $opt_noxml && defined $opt_nocount )
{
    print "Cannot simultaneously specify both -noxml and -nocount.\n";
    askHelp();
    exit;
}

# now starts the real fun!
# first get the header that precedes <corpus.. 

# get the file name 
$sourceXMLFile = shift;

if (!defined $sourceXMLFile)
{
    print "Source file not provided.\n";
    askHelp();
    exit;
}

open(SRC, $sourceXMLFile) || die("Couldnt open file $sourceXMLFile");

@header = ();
$gotHeader = 0;

$lineFromSource = <SRC>;

while ($lineFromSource && ($gotHeader == 0))

{

    # since this line could have multiple tags, we will split the line
    # such that each line has at most one tag. note, in the split
    # function below, the brackets return the tags we are splitting
    # on, besides the stuff within the tags

## TDP 3.1 START
## Statement (S1) causes split loop error on linux, but not Solaris!
## 
## the regex is based on the following definition of a tag - any string  
## that starts with a <, ends with a > and includes any characters except
## >. Thus, <<<> is considered a tag. The string <<>> is split into
## <<> and >. The motivation for this is to make sure that each line
## only has one tag. Curiously enough, the regex does not seem to
## be the problem. The split loop error does not occur on linux when
## the input to the split statement is in $_. This doesn't make sense
## to me, but I have hacked things such that split reads from $_.
##
##    @separatedLines = split/(<[^>]*>)/, $lineFromSource; (S1)
##

     $_ = $lineFromSource;          ## TDP.3.1

    @separatedLines = split/(<[^>]+>)/;

    while (defined ($thisLine = shift @separatedLines))
    {
	chomp $thisLine;
	if ($thisLine eq "") { next; }  

	if ( defined $opt_xml ) 
	{ 
	    if ( defined $opt_split ) 
	    {
		print XML_TRAIN "$thisLine\n";
		print XML_TEST "$thisLine\n";
	    }
	    else { print XML "$thisLine\n"; }
	}
	if ( $thisLine =~ /<corpus / ) 
	{ 
	    $gotHeader = 1; 
	    $corpus = "$thisLine\n";
	    last; 
	}
	push @header, "$thisLine\n";
    }

    $lineFromSource = <SRC> if (!$gotHeader);
}

if (!defined $corpus) 
{ 
    print "Could not find <corpus> in input file!\n"; 
    exit;
}

# now to get the lexical elts till the end of the file
while (defined ($lineFromSource = <SRC>) || defined ($separatedLines[0]))
{

    $_ = $lineFromSource;                       ## TDP.3.1

##     push @separatedLines, split/(<[^>]*>)/, $lineFromSource;  ## TDP.3.1

    push @separatedLines, split/(<[^>]*>)/     ## TDP.3.1
       	               if (defined $lineFromSource);

    my $foundLexelt = 0;
    
    while ( defined ($thisLine = shift @separatedLines))
    {
	if ($thisLine =~ /^<lexelt / )
	{
	    $foundLexelt = 1;
	    last; 
	}
    }
    
    next if ($foundLexelt == 0);
    
    # right, so we've got <lexelt>. 
    # first get the lexelt word
   
    $thisLine =~ /<lexelt item="([^\"]*)">/;
    $lexeltWord = $1;

    # if xml option has not been taken, create the xml filename using the lexelt word
    if ( !(defined $opt_xml) && !(defined $opt_noxml) ) 
    {
	if ( !defined $opt_split )
	{
	    my $filename = $lexeltWord . ".xml";
	    
	    if ( $filename eq $sourceXMLFile )
	    {
		print "Default output XML filename $filename clashes with source XML filename.\n";
		print "Create output in file ${filename}1? (Y = Yes / N = abort) ";
		$reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ($reply ne "Y");
		$filename .= "1";
	    }
	    if ( -e $filename ) 
	    {
		print "File $filename exists! Overwrite (Y/N)? ";
		$reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ($reply ne "Y");
	    }
	    
	    open XML, ">$filename" || die "Couldnt open file $filename\n";
	    
	    print XML @header;
	    print XML $corpus;
	}
	else
	{
	    my $training = $lexeltWord . "-training.xml";
	    
	    if ( -e $training )
	    {
		print "File $training exists! Overwrite (Y/N)? ";
		my $reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ( $reply ne "Y" );
	    }
	    
	    open XML_TRAIN, ">$training" || die "Couldnt open file $training\n";
	    
	    print XML_TRAIN @header;
	    print XML_TRAIN $corpus;
	    
	    my $test = $lexeltWord . "-test.xml";
	    
	    if ( -e $test )
	    {
		print "File $test exists! Overwrite (Y/N)? ";
		my $reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ( $reply ne "Y" );
	    }
	    
	    open XML_TEST, ">$test" || die "Couldnt open file $test\n";
	    
	    print XML_TEST @header;
	    print XML_TEST $corpus;
	}
    }

    # print out the lexelt tag
    if ( !defined ($opt_noxml) ) 
    { 
	if ( defined $opt_split )
	{
	    print XML_TRAIN "$thisLine\n";
	    print XML_TEST "$thisLine\n";
	}
	else { print XML "$thisLine\n"; }
    }

    # also create the count file, if not already opened
    if ( !( defined $opt_count ) && !(defined $opt_nocount) ) 
    {
	if ( !defined $opt_split ) 
	{
	    my $filename = $lexeltWord . ".count";
	    
	    if ( $filename eq $sourceXMLFile )
	    {
		print "Default output count filename $filename clashes with source XML filename.\n";
		print "Create output in file ${filename}1? (Y = Yes / N = abort) ";
		$reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ($reply ne "Y");
		$filename .= "1";
	    }
	    if ( -e $filename ) 
	    {
		print "File $filename exists! Overwrite (Y/N)? ";
		$reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ($reply ne "Y");
	    }
	    
	    open COUNT, ">$filename" || die "Couldnt open file $filename\n";
	}
	else
	{
	    my $training = $lexeltWord . "-training.count";

	    if ( -e $training ) 
	    {
		print "File $training exists! Overwrite (Y/N)? ";
		my $reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ( $reply ne "Y" );
	    }

	    open COUNT_TRAIN, ">$training" || die "Couldnt open file $training\n";
	
	    my $test = $lexeltWord . "-test.count";
	    
	    if ( -e $test )
	    {
		print "File $test exists! Overwrite (Y/N)? ";
		my $reply = <STDIN>;
		chomp $reply;
		$reply = uc $reply;
		exit 0 if ( $reply ne "Y" );
	    }

	    open COUNT_TEST, ">$test" || die "Couldnt open file $test\n";
	}
    }

    # now do the following until we get to </lexelt>
# removed by tdp oct 3, 2015 due to perl deprecation of defined @array
#    if ( defined @instanceArrayXml ) { undef @instanceArrayXml; }
#    if ( defined @instanceArrayCount ) { undef @instanceArrayCount; }

    $instanceStringXml = "";
    $instanceStringCount = "";
    
    $foundLexelt = 0;
    $insideContext = 0;

    while ( !$foundLexelt )
    {
	while (!(defined ($separatedLines[0])))
	{
	    my $lineFromSource = <SRC>;
	    if ( !defined $lineFromSource ) 
	    { 
		print STDERR "ERROR!! Premature end to source file!\n";
		exit;
	    }

	    $_ = $lineFromSource;                       ## TDP.3.1
	    @separatedLines = split/(<[^>]*>)/;         ## TDP.3.1

##	    @separatedLines = split/(<[^>]*>)/, $lineFromSource; TDP.3.1

	}
	
	while (defined ($thisLine = shift @separatedLines))
	{
	    # chomp $thisLine;

	    # if outside the context... 
	    if (!$insideContext)
	    {
		# then it better be a tag!
		chomp $thisLine;

		if ( $thisLine !~ /<[^>]*>/ ) { next; }    

		if ( !defined $opt_noxml )
		{
		    if ( defined $opt_split ) 
		    { 
			if ( !( $thisLine =~ /<\/instance>/) ) 
			{
			    $instanceStringXml .= $thisLine . "\n"; 
			}
		    }
		    else { print XML "$thisLine\n"; }
		}
		
		# if its an answer tag, put the senseid into the array!
		if ( $thisLine =~ /<answer instance=\"[^\"]*\" senseid=\"([^\"]*)\"/ )
		{
		    my $senseid = $1;
		    push @answers, $senseid;
		}
		
		if ( $thisLine =~ /<context/ ) 
		{ 
		    $contextLine = "";
		    $insideContext = 1; 
		}

		# check if this is the lexelt!
		if ( $thisLine =~ /<\/lexelt>/ )
		{
		    $foundLexelt = 1;
		    last;
		}

	    }
	    else
	    {
		if ( $thisLine !~ /<\/context/ ) 
		{
		    $contextLine .= $thisLine;
		    next; 
		}

		# right so we are at the END of the context now.
		$insideContext = 0;
		
		# remove all new lines from $line
		# $contextLine =~ s/\s+/ /g;
	
		# create tag according to if -uselexelt has been chosen
		$newTag = "";
		if ( defined $opt_useLexelt ) 
		{
		    $opt_useLexelt *= 1;
		    $newTag = "<lexelt=$lexeltWord/>";
		}
		
		# create tag according to if -useSenseid has been chosen
		if ( defined $opt_useSenseid )
		{
		    $opt_useSenseid *= 1;
		    foreach $answer (@answers)
		    {
			$newTag .= "<senseid=$answer/>";
		    }
		    undef @answers;
		}
	
		# note that at this point, new line characters have
		# not been removed. if --putSentenceTags is forced, put
		# in the sentence tags, and then put everything on one
		# line.

		if (defined $opt_putSentenceTags)
		{
		    $opt_putSentenceTags = 1;

		    $contextLine = $contextLine;
		    $contextLine =~ s/^\s+//;
		    $contextLine =~ s/\s+$//;
		    $contextLine =~ s/\n+/\n/g;
		    $contextLine =~ s/\n+/ <\/s> <s> /g;
		    $contextLine = "<s> " . $contextLine . " </s>";
		}

		# now fix the line so that everything count cant see goes into tags
		$temp = $contextLine;

		# ------------------------------
		# ADP.3.1 adding nontoken option
		# ------------------------------
		if(defined $non_token_regex)
		{
			$temp=~s/$non_token_regex/ /g;
			$temp=~s/\s+/ /g;
		}
		$contextLine = "";
		while ( $temp =~ /($tokenizerRegex)/ )
		{
		    if (!(defined $opt_removeNotToken) && !( $` eq "" ))
		    {
			my $notToken = $`;
			$notToken =~ s/^\s+//;
			$notToken =~ s/\s+$//;
			$contextLine .= " <" . $notToken . ">" if ($notToken ne "");
		    }

		    my $currentToken = $1;
		    $temp = $';
		    
		    $contextLine .= " $currentToken";
		}
	
		$temp =~ s/^\s*//;
		$temp =~ s/\s*$//;
		if (!(defined $opt_removeNotToken) && !( $temp eq "" ) && !($temp =~ /^\s+$/))
		{
		    $contextLine .= " <" . $temp . ">";
		}
	
		# put a space in the end so that every token has at least one space on each side
		$contextLine .= " ";

		# write out the context to the count file, if defined
		if ( !(defined $opt_nocount) )
		{
		    if ( !defined $opt_split )
		    {
			$temp = $contextLine;
			while ( $temp =~ /<\/head>/ )
			{
			    print COUNT $`;
			    print COUNT $newTag;
			    print COUNT $&;
			    $temp = $';
			}
			print COUNT "$temp\n";
		    }
		    else
		    {
			$temp = $contextLine;
			while ( $temp =~ /<\/head>/ )
			{
			    $instanceStringCount .= $`;
			    $instanceStringCount .= $newTag;
			    $instanceStringCount .= $&;
			    $temp = $';
			}
			$instanceStringCount .= $temp . "\n";
			push @instanceArrayCount, $instanceStringCount;
			$instanceStringCount = "";
		    }
		}
		
		# now write out to the xml file
		if ( !( defined $opt_noxml ) )
		{
		    if ( !defined $opt_split )
		    {
			$temp = $contextLine;
			while ( $temp =~ /<\/head>/ )
			{
			    print XML $`;
			    print XML $newTag;
			    print XML $&;
			    $temp = $';
			}
			
			print XML "$temp\n";
			
			# finally write out the /context tag 
			print XML "</context>\n";
		    }
		    else
		    {
			$temp = $contextLine;
			while ( $temp =~ /<\/head>/ )
			{
			    $instanceStringXml .= $`;
			    $instanceStringXml .= $newTag;
			    $instanceStringXml .= $&;
			    $temp = $';
			}
			$instanceStringXml .= $temp . "\n</context>\n</instance>\n";
			push @instanceArrayXml, $instanceStringXml;
			$instanceStringXml = "";
		    }
		}
	    }
	}
    }

    # if split defined, do the shuffling, and then writing out to the files!
    if ( defined $opt_split )
    {
	if ((!defined $opt_noxml) && (!defined $opt_nocount))
	{
	    $splitPoint = sprintf("%d", $opt_split / 100 * $#instanceArrayXml);

	    for ( $i = 0; $i < $splitPoint; $i++ )
	    {
		my $index = int rand ($#instanceArrayXml+1);
		while ( $instanceArrayXml[$index] eq "" )
		{
		    $index = int rand ($#instanceArrayXml+1);
		}
		print XML_TRAIN $instanceArrayXml[$index];
		print COUNT_TRAIN $instanceArrayCount[$index]; 
		$instanceArrayXml[$index] = "";
	    }
	    print XML_TRAIN "</lexelt>\n";
	
	    for ( $i = $splitPoint; $i <= $#instanceArrayXml; $i++ )
	    {
		my $index = int rand ($#instanceArrayXml+1);
		while ( $instanceArrayXml[$index] eq "" )
		{
		    $index = int rand ($#instanceArrayXml+1);
		}
		print XML_TEST $instanceArrayXml[$index]; 
		print COUNT_TEST $instanceArrayCount[$index]; 
		$instanceArrayXml[$index] = "";
	    }
	    print XML_TEST "</lexelt>\n"; 
	}

	elsif (defined $opt_noxml)
	{

	    $splitPoint = sprintf("%d", $opt_split / 100 * $#instanceArrayCount);

	    for ( $i = 0; $i < $splitPoint; $i++ )
	    {
		my $index = int rand ($#instanceArrayCount+1);
		while ( $instanceArrayCount[$index] eq "" )
		{
		    $index = int rand ($#instanceArrayCount+1);
		}
		print COUNT_TRAIN $instanceArrayCount[$index]; 
		$instanceArrayCount[$index] = "";
	    }
	
	    for ( $i = $splitPoint; $i <= $#instanceArrayCount; $i++ )
	    {
		my $index = int rand ($#instanceArrayCount+1);
		while ( $instanceArrayCount[$index] eq "" )
		{
		    $index = int rand ($#instanceArrayCount+1);
		}
		print COUNT_TEST $instanceArrayCount[$index]; 
		$instanceArrayCount[$index] = "";
	    }
	}

	else # defined $opt_nocount
	{
	    $splitPoint = sprintf("%d", $opt_split / 100 * $#instanceArrayXml);

	    for ( $i = 0; $i < $splitPoint; $i++ )
	    {
		my $index = int rand ($#instanceArrayXml+1);
		while ( $instanceArrayXml[$index] eq "" )
		{
		    $index = int rand ($#instanceArrayXml+1);
		}
		print XML_TRAIN $instanceArrayXml[$index];
		$instanceArrayXml[$index] = "";
	    }
	    print XML_TRAIN "</lexelt>\n";
	
	    for ( $i = $splitPoint; $i <= $#instanceArrayXml; $i++ )
	    {
		my $index = int rand ($#instanceArrayXml+1);
		while ( $instanceArrayXml[$index] eq "" )
		{
		    $index = int rand ($#instanceArrayXml+1);
		}
		print XML_TEST $instanceArrayXml[$index]; 
		$instanceArrayXml[$index] = "";
	    }
	    print XML_TEST "</lexelt>\n"; 
	}
    }
	    
    # that is the end of the <lexelt>. if opt_xml not defined,
    # close the corpus and close the file. 

    if ( !( defined $opt_xml) && !(defined $opt_noxml) )
    {
	if ( defined $opt_split )
	{
	    print XML_TRAIN "</corpus>\n";
	    close XML_TRAIN;
	    print XML_TEST "</corpus>\n";
	    close XML_TEST;
	}
	else
	{
	    print XML "</corpus>\n";
	    close XML;
	}
    }
    if ( !(defined $opt_count) && !(defined $opt_nocount) )
    {
	if ( defined $opt_split )
	{
	    close COUNT_TRAIN;
	    close COUNT_TEST;
	}
	else { close COUNT; }
    }
}

if ( defined $opt_xml )
{
    if ( defined $opt_split )
    {
	print XML_TRAIN "</corpus>\n";
	close XML_TRAIN;
	print XML_TEST "</corpus>\n";
	close XML_TEST;
    }
    else
    {
	print XML "</corpus>\n";
	close XML;
    }
}
if ( defined $opt_count )
{
    if ( defined $opt_split )
    {
	close COUNT_TRAIN;
	close COUNT_TEST;
    }
    else { close COUNT; }
}

# thats it!

# function to output a minimal usage note when the user has not provided any
# commandline options
sub minimalUsageNotes
{
    print "Usage: preprocess.pl [OPTIONS] SOURCE\n";
    askHelp();
}

# function to output help messages for this program
sub showHelp
{
    print "Usage: preprocess.pl [OPTIONS] SOURCE\n\n";

    print "Preprocesses Senseval lexical samples files. Outputs modified xml file(s) and\n";
    print "also a NSP-ready file (see options below). By default separates different\n";
    print "lexical elements into separate .xml and .count files.\n\n";

    print "OPTIONS:\n\n";

    print "  --token FILE       Reads tokens from FILE. The context of each instance\n";
    print "                     is broken up into tokens and each pair of consecutive tokens\n";
    print "                     are separated by white space. Non-white space characters\n";
    print "                     which do not belong to any token are put between angular\n";
    print "                     brackets. If this option is not used, the default token\n";
    print "                     definitions of count.pl are assumed.\n\n";

    print "  --removeNotToken   Removes strings that do not match token file. If not\n";    
    print "                     specified, the non-matching strings are put within angular\n";
    print "                     brackets, ie, <>\n\n";


    print "  --nontoken FILE    Removes all characters sequences that match Perl\n";
    print "                     regular expressions specified in FILE.\n\n";	

    print "  --noxml            Does not output an xml file.\n\n";

    print "  --xml FILE         Outputs the changed xml file to FILE. If this option nor\n";
    print "                     the option --noxml is provided, the file name is derived\n";
    print "                     by concatenating the word in the <lexelt> tag with \".xml\".\n";
    print "                     Note: if this option is used, separate lexelt items will\n";
    print "                     not be split into separate files.\n\n";

    print "  --nocount          Does not output a NSP-ready file.\n\n";

    print "  --count FILE       Outputs just the part between <context> </context> (after\n";
    print "                     modification) to FILE. FILE can then be used directly with\n";
    print "                     NSP. If this option nor the option --nocount is provided,\n";
    print "                     the file name is derived as in xml above, with a .count\n";
    print "                     extension.\n";
    print "                     Note: if this option is used, separate lexelt items will\n";
    print "                     not be split into separate files.\n\n";

    print "  --useLexelt        Includes a tag <lexelt=WORD/> within the <head></head>\n";
    print "                     tags, where WORD is the word in the immediately preceeding\n";
    print "                     <lexelt> tag.\n\n";

    print "  --useSenseid       Includes a tag <senseid=XXXXX/> within the <head></head>\n";
    print "                     tags, where XXXXX is the number in the immediately\n";
    print "                     preceeding <answer> tag.\n\n";

    print "  --split N          Shuffles the instances in SOURCE and then splits them into\n";
    print "                     two files, a training file and a test file, approximately\n";
    print "                     in the ratio N:(100-N).\n\n";

    print "  --seed N           Sets the seed for the random number generator used during\n";
    print "                     shuffling. If not used, no seeding is done (except for\n";
    print "                     that provided automatically by perl)\n\n";

    print "  --putSentenceTags  Puts separate lines within the <context> </context> region\n";
    print "                     within <s> </s> pairs of tags. If separate sentences are on\n";
    print "                     seperate lines, these tags effectively denote the start and\n";
    print "                     end of sentences.\n\n";

    print "  --version          Prints the version number.\n\n";

    print "  --help             Prints this help message.\n\n";

    print "  --verbose          Turns on verbose mode. Silent by default.\n\n";
}

# function to output the version number
sub showVersion
{
#    print STDERR "preprocess.pl  -  Version 0.3\n";
    print  '$Id: preprocess.pl,v 1.9 2015/10/03 14:05:57 tpederse Exp $';     
    print  "\nFormat and clean a Senseval-2 data file\n";
#    print STDERR "Copyright (C) 2001-2003, Ted Pedersen & Satanjeev Banerjee\n";
#    print STDERR "Date of Last Update: May 10, 2003 by TDP\n";
}

# function to output "ask for help" message when the user's goofed up!
sub askHelp 
{
    print STDERR "Type preprocess.pl --help for help.\n";
}
