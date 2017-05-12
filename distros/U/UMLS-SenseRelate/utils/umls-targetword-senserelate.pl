#!/usr/bin/perl 

=pod

=head1 NAME

umls-targetword-senserelate.pl - This program performs target word 
disambiguation and determines the correct sense of an ambiguous term 
using semantic similarity measures.

=head1 SYNOPSIS

This program assigns senses from the UMLS or a given sense 
file to ambiguous terms using semantic simlarity or relatedness
measures from the UMLS::Similarity package. 

=head1 USAGE

Usage: umls-targetword-senserelate.pl [OPTIONS] INPUTFILE

=head2 OUTPUT

The output files will be stored in the directory "log" or 
the directory defined by the --log option. 

=head2 Required Options

=head3 INPUTFILE 

Input file either in sval2 or plain format. Indicated by 
the --sval2 or --plain options respectively. The --plain 
option is the default.

=head2 General Options:

=head3 --plain

The input format is in plain text. This is the default format. 

In plain format each line of the text files contains a single 
context  where the ambiguous word is identified by:

<head item="target word" instance="id" sense="sense">word</head>.

For example: 

Paul was named <head item="art" instance="art.30002" sense="art">Art</head> magazine's top collector.

The sense information is optional. If you do not have the sense information 
either leave it blank such as:

Paul was named <head item="art" instance="art.30002" sense="">Art</head> magazine's top collector.

or do not include the sense tag such as:

Paul was named <head item="art" instance="art.30002">Art</head> magazine's top collector.

If the sense information is not there, then you can not use the --key FILE option

We also added a candidate tag so if would like to specifiy the possible senses 
for the target word in the instance, you can include a candidate attribute in 
which the candidate senses are seperated by a comma. For example: 

<head item="target word" instance="id" sense="sense" candidate="s1,s2">word</head>.

You must use the --candidate option to actually use the candidate information, 
otherwise it will be ignored.

=head3 --sval2

The format is in sval2 format

=head3 --mmxml

The format is in metamap xml (mmxml) format in which each target word 
thoughis identified by a <Target></Target> tag similar to that of the 
<Token></Token> tags. 

We have a conversion program in the coverters/ directory which will 
convert plain text into the what we refer to as mm-xml tagged text 
called: plain2mm-xml.pl 

=head3 --candidates

This option uses the candidate senses as identified by metamap for 
the target word. This option can only be used with the --mmxml option. 

=head3 --cuis

This option uses the CUIs tagged by metamap not the terms

=head3 --senses DIR|File

This is the directory that contains the candidate sense file for each 
target word you are going to disambiguate or just the file itself. 

The files for the target word contains the possible senses of the target 
word. 

This may be temporary but right now this is who I have it because often 
times the possible senses change depending on the version of the UMLS that 
you are using. I felt this allowed the most flexibility with it. 

The naming convention for this is a file called: <target word>.choices

The format for this file is:

    <tag>|<target word name>|semantic type|CUI

This format is based on the choice files in the NLM-WSD dataset which 
we use for our experiments. If you are using the NLM-WSD dataset you
can download these choice files from NLM's site. There are the 1999 
tagset and the 2007 tagset available.


=head3 --log DIR

Directory in which the output files will be stored. Default: log

=head3 --compound

Use the compounds in the input text. For the plain and sval2 format 
these are indicated by an underscore. For example:

    white_house
    blood_pressure

=head3 --key 

Stores the gold standard information in the <target word>.key file to be 
used in the evaluation programs. This file is stored in the log directory. 

=head3 --window NUMBER

The window in which to obtain the context surrounding the ambiguous term. 

Default: 2

=head3 --aggregator AGGREGATOR

The aggregator method to be used to combine the similarity scores. The 
available aggregators are: 
    1. max - the maximum similarity score
    2. avg - the average similarity score (default)
    3. orness - \frac{1}{(n-1)} Sum_{i=1}^{n} (n-i)w_{i} 
    4. andness - 1-orness
    5. disp
    6. closeness

=head3 --restrict 

This restricts the window to be contain the context whose terms maps 
to UMLS, not just any old term

=head3 --measure MEASURE

Use the MEASURE module to calculate the semantic similarity. The 
available measure are: 
    1. Leacock and Chodorow (1998) referred to as lch
    2. Wu and Palmer (1994) referred to as  wup
    3. The basic path measure referred to as path
    4. Rada, et. al. (1989) referred to as cdist
    5. Nguyan and Al-Mubaid (2006) referred to as nam
    6. Resnik (1996) referred to as res
    7. Lin (1988) referred to as lin
    8. Jiang and Conrath (1997) referred to as jcn
    9. The vector measure referred to as vector

=head3 --weight

Weight the scores based on the distance the content term is from the 
target word. This option can currently only be used with the --window 
option.

=head3 --stoplist FILE

A file containing a list of words to be excluded. This is used in the 
UMLS::SenseRelate::TargetWord module as well as the vector and lesk 
measures in the UMLS::Similarity package. The format required is one 
stopword per line, words are in regular expression format. 

For example:

  /\b[a-zA-Z]\b/
  /\b[aA]board\b/
  /\b[aA]bout\b/
  /\b[aA]bove\b/
  /\b[aA]cross\b/
  /\b[aA]fter\b/
  /\b[aA]gain\b/

The sample file, stoplist-nsp.regex, is under the samples directory. We 
might change this to require two different stoplists in the future; one 
for the senserelate program and the other for the relatedness measures.

=head3 --trace FILE

This stores the trace information in FILE for debugging purposes. 

=head3 --loadcache FILE

Preloads cache. The expected format is:

    score<>cui1<>cui2
    score<>cui3<>cui4
    ...

=head3 --getacache FILE

Outputs cache to FILE after run.

=head3 --version

Displays the version information.

=head3 --help

Displays the help information

=head2 UMLS-Interface General Options:

=head3 --config FILE

This is the configuration file. There are six configuration options 
that can be used depending on which measure you are using. The 
path, wup, lch, lin, jcn and res measures require the SAB and REL 
options to be set while the vector and lesk measures require the 
SABDEF and RELDEF options. 

The SAB and REL options are used to determine which sources and 
relations the path information is to be obtained from. The format 
of the configuration file is as follows:

 SAB :: <include|exclude> <source1, source2, ... sourceN>
 REL :: <include|exclude> <relation1, relation2, ... relationN>

For example, if we wanted to use the MSH vocabulary with only 
the RB/RN relations, the configuration file would be:

 SAB :: include MSH
 REL :: include RB, RN

or 

 SAB :: include MSH
 REL :: exclude PAR, CHD

The SABDEF and RELDEF options are used to determine the sources 
and relations the extended definition is to be obtained from. 
We call the definition used by the measure, the extended definition 
because this may include definitions from related concepts. 

The format of the configuration file is as follows:

 SABDEF :: <include|exclude> <source1, source2, ... sourceN>
 RELDEF :: <include|exclude> <relation1, relation2, ... relationN>

The possible relations that can be included in RELDEF are:

  1. all of the possible relations in MRREL such as PAR, CHD, ...
  2. CUI which refers the concepts definition
  3. ST which refers to the concepts semantic types definition
  4. TERM which refers to the concepts associated terms


For example, if we wanted to use the definitions from MSH vocabulary 
and we only wanted the definition of the CUI and the definitions of the 
CUIs SIB relation, the configuration file would be:

 SABDEF :: include MSH
 RELDEF :: include CUI, SIB

Note: RELDEF takes any of MRREL relations and two special 'relations':

      1. CUI which refers to the CUIs definition

      2. TERM which refers to the terms associated with the CUI

If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

For more information about the configuration options (including the 
RELA and RELADEF options) please see the README.

=head3 --realtime

This option will not create a database of the path information
for all of concepts in the specified set of sources and relations 
in the config file but obtain the information for just the 
input concept

=head3 --forcerun

This option will bypass any command prompts such as asking 
if you would like to continue with the index creation. 

=head3 --loadcache FILE

FILE containing similarity scores of cui pairs in the following 
format: 

  score<>CUI1<>CUI2

=head3 --getcache FILE

Outputs the cache into FILE once the program has finished. 

=head2 UMLS-Interface Debug Options: 

=head3 --debug

Sets the UMLS-Interface debug flag on for testing

=head2 UMLS-Interface Database Options:

=head3 --username STRING

Username is required to access the umls database on mysql

=head3 --password STRING

Password is required to access the umls database on mysql

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head2 UMLS-Similarity IC Measure Options:

=head3 --icpropagation FILE

FILE containing the propagation counts of the CUIs. This file must be 
in the following format:

    CUI<>probability

where probability is the probability of the concept occurring. 

See create-icpropagation.pl for more information.

=head3 --intrinsic [seco|sanchez]

Uses intrinic information content of the CUIs defined by Sanchez and
Betet 2011 or Seco, et al 2004. 

=head2 UMLS-Similarity Vector Measure Options:

=head3 --vectormatrix FILE

This is the matrix file that contains the vector information to 
use with the vector measure. 

If you do not want to use the default, this file is generated by 
the vector-input.pl program. An example of this file can be found 
in the samples/ directory and is called matrix.

=head3 --vectorindex FILE

This is the index file that contains the vector information to 
use with the vector measure. 

If you do not want to use the default, this file is generated by 
the vector-input.pl program. An example of this file can be found 
in the samples/ directory and is called index.


=head3 --debugfile FILE

This prints the vector information to file, FILE, for debugging 
purposes.

=head2 UMLS-Similarity vector and lesk Options:

=head3 --vectorstoplist FILE

A file containing a list of words to be excluded from the vector 
measure calculation. This is the same format as the --stopword 
option.

head3 --leskstoplist FILE

A file containing a list of words to be excluded from the lesk
measure calculation. This is the same format as the --stopword 
option.

=head3 --dictfile FILE

This is a dictionary file for the vector or lesk measure. It contains 
the 'definitions' of a concept or term which would be used 
rather than the definitions from the UMLS. If you would like 
to use dictfile as a augmentation of the UMLS definitions, 
then use the --config option in conjunction with the --dictfile
option. 

The expect format for the --dictfile file is:

 CUI: <definition>
 CUI: <definition>
 TERM: <definition> 
 TERM: <definition>

There are three different option configurations that you have with the
--dictfile.

1. No --dictfile - which will use the UMLS definitions

  umls-targetword-senserelate.pl --measure lesk hand foot

2. --dictfile - which will just use the dictfile definitions

  umls-targetword-senserelate.pl --measure lesk --dictfile samples/dictfile hand foot

3. --dictfile + --config - which will use both the UMLS and dictfile 
definitions

  umls-targetword-senserelate.pl --measure lesk --dictfile samples/dictfile --config
  configuration hand foot

Keep in mind, when using this file with the --config option, if 
one of the CUIs or terms that you are obtaining the similarity 
for does not exist in the file the vector will be empty which 
will lead to strange similarity scores.

An example of this file can be found in the samples/ directory 
and is called dictfile.

=head3 --defraw

This is a flag for the vector measures. The definitions 
used are 'cleaned'. If the --defraw flag is set they will not be 
cleaned. 

=head3 --stem 

This is a flag for the vector and lesk method. If the --stem flag is 
set, definition words are stemmed using the Lingua::Stem::En module. 

=head3 --compoundfile FILE

This is a compound word file for the vector and lesk measures. 
It containsthe compound words which we want to consider them as 
one wordwhen we compare the relatedness. Each compound word is a 
line in the file and compound words are seperated by space. When 
using this option with vector, make sure the vectormatrix and 
vectorindex file are based on the corpus proprocessed by replacing 
the compound words in the Text-NSP package. An example is under 
/sample/compoundword.txt 

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

=item * UMLS::Similarity - http://search.cpan.org/dist/UMLS-Similarity

=back

=head1 CONTACT US
   
  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :
    
      umls-similarity@yahoogroups.com
     
  You can join this group by going to:
    
      http://tech.groups.yahoo.com/group/umls-similarity/
     
  You may also contact us directly if you prefer :
    
      Bridget T. McInnes: bthomson at umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2010,

 Bridget T. McInnes, University of Minnesota Twin Cities
 bthomson at umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu
 
 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002 at umn.edu

 Ying Liu, University of Minnesota Twin Cities
 liux0395 at umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

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


use UMLS::Interface;
use UMLS::SenseRelate::TargetWord;
use Getopt::Long;
use XML::Twig;
use File::Spec;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "measure=s", "config=s", "forcerun", "debug", "icpropagation=s", "intrinsic=s", "realtime", "stoplist=s", "vectorstoplist=s", "leskstoplist=s", "vectormatrix=s", "vectorindex=s", "defraw", "dictfile=s", "t", "stem", "window=s", "key", "log=s", "senses=s", "plain", "sval2", "mmxml", "candidates", "cuis", "compound", "compoundfile=s", "trace=s", "undirected", "st", "precision", "restrict", "loadcache=s", "getcache=s", "weight", "aggregator=s")) or die ("Please check the above mentioned option(s).\n");

my $debug = 0;

#  if help is defined, print out help
if( defined $opt_help ) {
    $opt_help = 1;
    &showHelp();
    exit;
} 

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}

# At least 1 terms should be given on the command line.
if(scalar(@ARGV) < 1) {
    print STDERR "The input file or directory must be given on the command line.\n";
    &minimalUsageNotes();
    exit;
}

my $source = shift;

#  initialize variables
my $stopregex     = undef;
my $precision     = "";
my $floatformat   = "";
my $measure       = "";
my $aggregator    = "";
my $window        = "";
my $weight        = "";
my %sensehash     = ();
my %candidatehash = ();
my %instancehash  = ();
my %keyhash       = ();

#  check and set the options
&checkOptions       ();
&setOptions         ();

#  load the UMLS::Interface, UMLS::Similarity Measure and the 
#  UMLS::SenseRelate package - order matters here!
my $umls        = &load_UMLS_Interface();
my $meas        = &load_UMLS_Similarity();
my $senserelate = &load_UMLS_SenseRelate();

#  get the senses
if(defined $opt_senses) {
   &setSenses();
}

#  get the instances
&setInput($source);

#  set the key
if(defined $opt_key) { 
   &setKey();
}

#  assign senses
&assignSenses();

#  get the cache if requested
if(defined $opt_getcache) { 
    $senserelate->dumpCache($opt_getcache);
}

print STDERR "The results will be found in the $log directory\n";

#########################################################################################
##  SUB FUnCTIONS
#########################################################################################

#  gets the input data and loads the instances in to the instance hash
sub setInput() {

    #  get the input
    my $input = shift;

    my @inputfiles = ();
    if(-d $input) {
	opendir(DIR, $input) || die "Could not open the input ($input) directory\n";
	my @files= grep { $_ ne '.' and $_ ne '..' } readdir DIR;
	foreach my $f (@files) { push @inputfiles, "$input/$f"; }
    }
    else {
	push @inputfiles, $input;
    }

    #  load the input into the instance hash
    foreach my $inputfile (@inputfiles) { 

	if(defined $opt_sval2)    { &load_Sval2_Input($inputfile);   }
	elsif(defined $opt_mmxml) { &load_MetaMap_Input($inputfile); }
	else                      { &load_Plain_Input($inputfile);   }
    }
}

#  assign senses to the instances in instancehash using 
#  the UMLS::SenseRelate::TargetWord  module
sub assignSenses {

    if($debug) { print "In assignSenses\n"; }
    
    foreach my $tw (sort keys %instancehash) { 
	
	if($tw=~/^\s*$/) { next; }

	if($debug) { print STDERR "  Assigning sense for $tw\n"; }

	#  open the log files
	open(ANSWERS, ">$log/$tw.answers") || die "Could not open $log/$tw.answers\n"; 

	#  get the possible senses for the target words
	my @senses = (); 
	
	#  if defined --senese similar to what we do with the NLM-WSD datset
	#  where the target word has predefined set of senses
	if(defined $opt_senses) { 
	    foreach my $sense (sort keys %{$sensehash{$tw}}) { 
		push @senses, $sense; 
	    }
	}
	
	
	#  loop through the instances and assign each of them a sense
	my $tp = 0; my $tn = 0;
	foreach my $id (sort keys %{$instancehash{$tw}}) {
	
	    my $instance = $instancehash{$tw}{$id};
	    
	    my $hashref = undef;
	    
	    #  if the --senses option was defined pass the senses given 
	    #  for the specified target word
	    if(defined $opt_senses) {
		($hashref) = $senserelate->assignSense($tw, $instance, \@senses);
	    }
	    #  if the --candidates option was defined pass the senses given 
	    #  for the instance containing the target word
	    elsif(defined $opt_candidates) { 
		my @candidates = ();
		foreach my $sense (sort keys %{$candidatehash{$tw}{$id}}) { 
		    push @candidates, $sense; 
		}
	       
		($hashref) = $senserelate->assignSense($tw, $instance, \@candidates);
	    }
	    #  no option was defined so the candidates are coming from the UMLS
	    else { 
		($hashref) = $senserelate->assignSense($tw, $instance, undef);
	    }

	    if(defined $hashref) {
		
		foreach my $sense (sort keys %{$hashref}) { 
		    my $score = sprintf $floatformat, ${$hashref}{$sense};
		    print ANSWERS "$tw $id $tw%$sense\n";
		}

	    }
	    else {
		print STDERR "ERROR: A sense was not assigned to instance to $tw for $id\n";
		exit;
	    }
	}
	close ANSWERS;
    }
}

#  loads the instances in sval2 format in to the instance hash
sub load_Sval2_Input {

    my $inputfile = shift;

    if($debug) { print STDERR "In load_Sval2_Input for $inputfile\n"; }
    
    #  open the input file
    open(INPUT, $inputfile) || die "Could not open input file: $inputfile\n";
        
    #  get the instance and instance information
    my $tw = ""; my $id = ""; my $sense = ""; my $instance = ""; my $formatcheck = 1;
    while(<INPUT>) { 
	chomp;

	#  check format
	if($_=~/<corpus lang/) { $formatcheck = 0; }
	if($_=~/<token word/)  { $formatcheck = 2; }
 
	#  get the target word
	if($_=~/lexelt item=\"(.*?)\">/) { $tw = $1; }

	# get the instance id
	if($_=~/<instance id=\"(.*?)\"/) { $id = $1; }
	
	#  get the sense
	if($_=~/senseid=\"(.*?)\"\/>/) { $sense = $1; }
	
	#  set the context flag on
	if($_=~/<context>/)   { $contextflag = 1; }
	
	#  get the context if the flag is set
	if($contextflag == 1) { $instance .= $_; }

	#  set the context flag off
	if($_=~/<\/context>/) { $contextflag = 0; }
	
	#  load the information in the instance hash
	if($_=~/<\/instance>/) {
	   	    
	    #  check we obtained all of the required infromation 
	    if($tw eq "") { 
		print STDERR "\nERROR: The item information is missing.\n";
		print STDERR "$_\n\n";
		&minimalUsageNotes();
		exit;
	    }
	    if($id eq "") { 
		print STDERR "\nERROR: The instance id information is missing from instance.\n";
		print STDERR "$_\n\n";
		&minimalUsageNotes();
		exit;
	    }

	    #  remove the <context> <title> and <local> tags	    
	    $instance=~s/<context>//g; $instance=~s/<\/context>//g;
	    $instance=~s/<local>//g;   $instance=~s/<\/local>//g;
	    $instance=~s/<title>//g;   $instance=~s/<\/title>//g;

	    #  set the header information
	    my $header = " <head item=\"$tw\" instance=\"$id\">$tw<\/head> ";

	    #  replace the current head information with the new
	    $instance=~s/<head>(.*?)<\/head>/$header/;

	    #  get rid of possible white spaces that were introduced
	    $instance=~s/\s+/ /g;  $instance=~s/^\s*//g; $instance=~s/\s*$//g;
	    
	    #  store the instance
	    $instancehash{$tw}{$id} = $instance;
	
	    #  if the --key option is defined print out the key information
	    if(defined $opt_key) { 
		if($sense eq "")  { 
		    print STDERR "\nERROR There is no sense information for instance $id.\n";
		    print STDERR "The --key FILE option can only be used when the sense\n";
		    print STDERR "information is embedded in the sval2 format.\n\n";
		    &minimalUsageNotes();
		    exit;
		}
		$keyhash{$tw}{$id} = "$tw%$sense";
	    }
	    
	    #  reset the variables
	    $id = ""; $instance = ""; $sense = ""; 
	}
    }
    
    #  double check if the format was correct
    if($formatcheck > 0) { 
	print STDERR "\nERROR: This does not look like sval2 format. \n";
	print STDERR "Please check the format of your input file.\n\n";
	&minimalUsageNotes();
	exit;
    }

}

#  loads the instances in metamap format in the instance hash
sub load_MetaMap_Input {

    my $inputfile = shift;
    
    if($debug) { print STDERR "In load_MetaMap_Input for $inputfile\n"; }
    
    #  open the input file
    open(INPUT, $inputfile) || die "Could not open input file: $inputfile\n";
        
    my @abstracts = (); my $abstract = "";
    while(<INPUT>) { 

	if($_=~/\<?xml version/) { 
	    if($abstract ne "") { push @abstracts, $abstract; }
	    $abstract = "";
	}
	if($_=~/<instance id>/) { 
	    print STDERR "\nERROR. This file looks like it is in sval2 format.\n";
	    print STDERR "Please check the format of your input file.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
	if($_=~/<head item=>/) { 
	    print STDERR "\nERROR. This file looks like it is in plain format.\n";
	    print STDERR "Please check the format of your input file.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
	
	$abstract .= $_;
    }
    
    foreach my $abstract (@abstracts) { 

	#  initialize the instance variables
	my $id    = ""; my $flag    = 0; my @tokens  = (); my %candidates = ();
	my $tw    = ""; my $tflag   = 0; my @cuis    = (); 
	my $item  = ""; my $mflag   = 1;
	my $sense = "";                   
 	
	#  split on the new line character
	my @lines = split/\n/, $abstract;
	
	foreach my $i (0..$#lines) { 
	    
	    my $line = $lines[$i];
	

	    #  get the tokens
	    if($line=~/<InputMatch>(.*?)<\/InputMatch>/) { 
		
		#  get the tokens
		my $token = $1;
		
		#  remove the puncutation
		$token=~s/[\.\,\(\)\%\-\:\/\=\+\;]//g;
		
		#  remove multiple spaces
		$token=~s/\s+/ /g; $token=~s/^\s+//g; $token=~s/\s+$//g;

		#  if defined compound underscore the mwe's
		if(defined $opt_compound) { $token=~s/ /_/g; }

		#  add token if it is just spaces
		if(! ($token=~/^\s*$/) ) { push @tokens, $token; }

		#  set the flags
		$flag = 0;
	    }
	    
	    #  check if target word
	    if($line=~/Target instance=\"(.*?)\" item=\"(.*?)\" sense=\"(.*?)\">/) { 
		
		#  get the attributes
		$id=$1;
		$tw=$2;
		$sense=$3;

		#  set the flag 
		$tflag = 1;
		$flag  = 0;
	    
		#  remove the target word
		my $target = pop @tokens;
		
		#  set the target word with its attributes
		$item = "<head ";
		$item .= "item=\"$tw\" ";
		$item .= "instance=\"$id\" ";
		$item .= "sense=\"$sense\"";
		$item .= ">$target<\/head>";

		#  add the updated target word
		push @tokens, $item;
		push @cuis, $item;
		
		#  if the key is defined add sense to the key hash
		if(defined $opt_key) { 
		    $keyhash{$tw}{$id} = "$tw%$sense";
		}
	    }
	    
	    #  check if in mapping
	    if($line=~/<Mappings Count=\"(.*?)\"/) { 
		$flag = $1; $mflag = 1; 
	    }

	    #  set the tflag off when mappings are finished regardless 	    
	    if($line=~/<\/Mappings>/) { 
		$flag  = 0; $tflag = 0; $mflag = 0; 
	    }

	    #  get the cuis of the mapping                       
	    if($line=~/<CandidateCUI>(.*?)<\/CandidateCUI>/) {
		my $cui = $1; 
		
		#  check if it is the target word
		if( ($tflag == 1) ) { 
		    #  get the cui and store it in the candidates
		    if(defined $opt_candidates) { 
			$candidates{$cui}++; 
		    }
		}
		
		#  if in mapping that is not the target word, get the cui
		 if( (defined $opt_cuis) && ($flag > 0)  && ($tflag == 0) ) { 

		     #  get the cui and the match
		     $lines[$i+1]=~/<CandidateMatched>(.*?)<\/CandidateMatched>/;
		     my $match = lc($1);

		     #  if stoplist is defined check to make certain that it is not
		     #  a stopword and then add it to the list if all is good
		     my $keep = 1;
		     if(defined $opt_stoplist) { if(! ($match=~/$stopregex/)) { $keep = 1; } }

		     if($keep == 1) { 
			 if($mflag == 1) { push @cuis, $cui; }
			 else { 
			     my $c = pop @cuis;
			     $c .= "/$cui";
			     push @cuis, $c;
			 }
		     }
		     $mflag++;
		 }
	    }
	}
	
	#  store the candidates in the candidate hash if defined
	if(defined $opt_candidates) { 
	    my @senses = ();
	    foreach my $cui (sort keys %candidates) { 
		$candidatehash{$tw}{$id}{$cui}++;
	    }
	}
	
	#  store instance in the hash
	if(defined $opt_cuis) { 
	    $instancehash{$tw}{$id} = join " ", @cuis;
	}
	else { 
	    $instancehash{$tw}{$id} = join " ", @tokens;
	}
    }
    
}

#  loads the instances in plain format in to the instance hash
sub load_Plain_Input {

    my $inputfile = shift;

    if($debug) { print STDERR "In loadPlainInput for $inputfile\n"; }
    
    #  open the input file
    open(INPUT, $inputfile) || die "Could not open input file: $inputfile\n";
        
    #  get the instance and instance information
    my $tw = ""; my $id = ""; my $sense = ""; 
    while(<INPUT>) { 
	chomp;
	
	if($_=~/<corpus lang/) { 
	    print STDERR "\nERROR. This does not look like plain format.\n";
	    print STDERR "Please check the format of your input file.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
	    
	my $before = "";	my $tw        = "";	
	my $id     = "";        my $sense     = "";	
	my $after  = "";        my $candidate = "";
	
	
	if($_=~/^(.*?)<head item=\"(.*?)\" instance=\"(.*?)\" sense=\"(.*?)\" candidates=\"(.*?)\">(.*?)<\/head>(.*?)$/) { 
	    $before    = $1;	    $tw     = $2;
	    $id        = $3;	    $sense  = $4;
	    $candidate = $5;        $after  = $7;
	    if( (defined $opt_candidates) && ($candidate=~/^\s*$/) ) { 
		print STDERR "\nERROR: The candidate information is missing from instance.\n";
		print STDERR "$_\n\n";
		&minimalUsageNotes();
		exit;
	    }

	}
	elsif($_=~/^(.*?)<head item=\"(.*?)\" instance=\"(.*?)\" sense=\"(.*?)\">(.*?)<\/head>(.*?)$/) { 
	    $before = $1;	    $tw     = $2;
	    $id     = $3;	    $sense  = $4;
	    $after  = $6;

	    if( (defined $opt_candidates) ) { 
		print STDERR "\nERROR: The candidate information is missing from instance.\n";
		print STDERR "$_\n\n";
		&minimalUsageNotes();
		exit;
	    }

	}
	elsif($_=~/^(.*?)<head item=\"(.*?)\" instance=\"(.*?)\">(.*?)<\/head>(.*?)$/) { 
	    $before = $1;	    $tw     = $2;
	    $id     = $3;	    $after  = $5;
	}
	else { 
	    print STDERR "\nERROR: The instance does not have any header information\n";
	    print STDERR "$_\n\n";
	    &minimalUsageNotes();
	    exit;
	}

	#  check all of the required information is there
	if($tw eq "") { 
	    print STDERR "\nERROR: The item information is missing from instance.\n";
	    print STDERR "$_\n\n";
	    &minimalUsageNotes();
	    exit;
	}
	if($id eq "") { 
	    print STDERR "\nERROR: The instance information is missing from instance.\n";
	    print STDERR "$_\n\n";
	    &minimalUsageNotes();
	    exit;
	}

	#  check that the candidate information is there
	if( (defined $opt_candidates) && ($candidate=~/^\s*$/) ) { 
	    print STDERR "\nERROR: The candidate information is missing from instance.\n";
	    print STDERR "$_\n\n";
	    &minimalUsageNotes();
	    exit;
	}

	#  reset the instance with out the sense or candidate information if it is there
	my $instance = $before . " <head item=\"$tw\" instance=\"$id\">$tw<\/head> " . $after;

	#  remove non essential white space
	$instance=~s/\s+/ /g;	$instance=~s/^\s*//g;	$instance=~s/\s*$//g;
	
	#  store the insance
	$instancehash{$tw}{$id} = $instance;
	
	
	

	#  store the candidate infromtion 
	if(defined $opt_candidates) { 
	    my @array = split/\,/, $candidate;
	    foreach my $cui (@array) { $candidatehash{$tw}{$id}{$cui}++; }
	}

	#  if the --key option is defined print out the key information
	if(defined $opt_key) { 
	    if($sense eq "")  { 
		print STDERR "\nERROR There is no sense information for instance $id.\n";
		print STDERR "The --key FILE option can only be used when the sense\n";
		print STDERR "information is embedded in the plain text format.\n\n";
		&minimalUsageNotes();
		exit;
	    }
	    $keyhash{$tw}{$id} = "$tw%$sense";
	}
    }
}

    #  open the key file if defined and print out the key information
sub setKey {

    if(! (defined $opt_key)) { next; }

    if($debug) { print STDERR "In setKey\n"; }

    foreach my $tw (sort keys %keyhash) { 
	open(KEY, ">$log/$tw.key") || 
	    die "Could not open key ($log/$tw.key) file\n";
	foreach my $id (sort keys %{$keyhash{$tw}}) { 
	    print KEY "$tw $id $keyhash{$tw}{$id}\n";
	}
	close KEY;
    }
}

#  get the sense information from the choice files if the --sense option is defined
sub setSenses {
    
    if(! (defined $opt_senses)) { return; }
    
    if($debug) { print STDERR "In setSenses\n"; } 
     
    my %files = ();
    if(-d $opt_senses) {
	opendir(DIR, $opt_senses) || die "Could not open $opt_senses directory\n";
	my @dirs = grep { $_ ne '.' and $_ ne '..' and $_ ne "CVS" and 
			  $_ ne "raw_summary" and $_ ne "index.shtml"} 
	readdir DIR;
	foreach my $file (@dirs) { 
	    $file=~/(.*?)\.choices/;	    
	    my $tw = $1;
	    $files{$tw} = "$opt_senses/$file";
	}
    }
    else { 
	my @array = split/\//, $opt_senses;
	my $file  = $array[$#array];
	$array[$#array]=~/(.*?)\.choices/;	
	my $tw = $1; 
	$files{$tw} = $opt_senses;
    }
    
    foreach my $tw (sort keys %files) { 
	open(FILE, $files{$tw}) || die "Could not open $file\n";
	while(<FILE>) {
	    chomp;
	    my($tag, $concept, $semantics, $cui) = split/\|/;
	    $sensehash{$tw}{$cui}++;
	}
	close FILE;
    }
}

#  load the UMLS-SenseRelate package
sub load_UMLS_SenseRelate {

    if($debug) { print STDERR "In load_UMLS_SenseRelate\n"; }
        
    my %option_hash = ();
    
    $option_hash{"window"}   = $window;

    if(defined $opt_compound)   { $option_hash{"compound"}   = $opt_compound;  }
    if(defined $opt_stoplist)   { $option_hash{"stoplist"}   = $opt_stoplist;  }
    if(defined $opt_trace)      { $option_hash{"trace"}      = $opt_trace;     }
    if(defined $opt_precision)  { $option_hash{"precision"}  = $opt_precision; }
    if(defined $opt_restrict)   { $option_hash{"restrict"}   = $opt_restrict;  }
    if(defined $opt_cuis)       { $option_hash{"cuis"}       = $opt_cuis;      }
    if(defined $opt_loadcache)  { $option_hash{"loadcache"}  = $opt_loadcache; }
    if(defined $opt_weight)     { $option_hash{"weight"}     = $opt_weight;    }
    if(defined $opt_aggregator) { $option_hash{"aggregator"} = $opt_aggregator;}    

    $option_hash{"measure"} = $measure;
    
    my $handler = UMLS::SenseRelate::TargetWord->new($umls, $meas, \%option_hash); 
    die "Unable to create UMLS::SenserRelateTargetWord object.\n" if(!$handler);
    
    return $handler;
}

#  load the appropriate measure in the UMLS-Similarity package
sub load_UMLS_Similarity {
   
    if($debug) { print STDERR "In load_UMLS_Similarity\n"; } 

    my $meas;

    #  load the module implementing the Leacock and 
    #  Chodorow (1998) measure
    if($measure eq "lch") {
	use UMLS::Similarity::lch;	
	$meas = UMLS::Similarity::lch->new($umls);
    }
    #  loading the module implementing the Wu and 
    #  Palmer (1994) measure
    if($measure eq "wup") {
	use UMLS::Similarity::wup;	
	$meas = UMLS::Similarity::wup->new($umls);
    }    
    #  loading the module implementing the simple edge counting 
    #  measure of semantic relatedness.
    if($measure eq "path") {
	use UMLS::Similarity::path;
	$meas = UMLS::Similarity::path->new($umls);
    }
    #  load the module implementing the Rada, et. al.
    #  (1989) called the Conceptual Distance measure
    if($measure eq "cdist") {
	use UMLS::Similarity::cdist;
	$meas = UMLS::Similarity::cdist->new($umls);
    }
    #  load the module implementing the Nguyen and 
    #  Al-Mubaid (2006) measure
    if($measure eq "nam") {
	use UMLS::Similarity::nam;
	$meas = UMLS::Similarity::nam->new($umls);
    }

    my %ic_hash = ();
    if(defined $opt_icpropagation) {
	$ic_hash{"icpropagation"} = $opt_icpropagation;
    }
    if(defined $opt_icfrequency) { 
	$ic_hash{"icfrequency"} = $opt_icfrequency;
    }
    if(defined $opt_intrinsic) { 
	$ic_hash{"intrinsic"} = $opt_intrinsic; 
    }


    #  load the module implementing the Resnik (1995) measure
    if($measure eq "res") {

	if(defined $opt_st) { 
	    $ic_hash{"st"} = 1;
	}
	use UMLS::Similarity::res;
	$meas = UMLS::Similarity::res->new($umls, \%ic_hash);
    }
    #  load the module implementing the Jiang and Conrath 
    #  (1997) measure
    if($measure eq "jcn") {
	use UMLS::Similarity::jcn;
	$meas = UMLS::Similarity::jcn->new($umls, \%ic_hash);
    }
    #  load the module implementing the Lin (1998) measure
    if($measure eq "lin") {
	use UMLS::Similarity::lin;
	$meas = UMLS::Similarity::lin->new($umls, \%ic_hash );
    }
    #  load the module implementing the random measure
    if($measure eq "random") {
	use UMLS::Similarity::random;
	$meas = UMLS::Similarity::random->new($umls);
    }
    
    #  load the module implementing the lesk measure
    
    if($measure eq "lesk") {
	use UMLS::Similarity::lesk;
	my %leskoptions = ();
	
	if(defined $opt_config)      { $leskoptions{"config"}       = $opt_config;       }
	if(defined $opt_leskstoplist){ $leskoptions{"stoplist"}     = $opt_leskstoplist; }
	if(defined $opt_stem)        { $leskoptions{"stem"}         = $opt_stem;         }
	if(defined $opt_debugfile)   { $leskoptions{"debugfile"}    = $opt_debugfile;    }
	if(defined $opt_defraw)      { $leskoptions{"defraw"}       = $opt_defraw;       }
	if(defined $opt_dictfile)    { $leskoptions{"dictfile"}     = $opt_dictfile;     }
	if(defined $opt_compoundfile){ $leskoptions{"compoundfile"} = $opt_compoundfile; }
	
        $meas = UMLS::Similarity::lesk->new($umls,\%leskoptions);  
    }
    
    
    if($measure eq "vector") {
	require "UMLS/Similarity/vector.pm";
	
	my %vectoroptions = ();
	
	if(defined $opt_dictfile)      { $vectoroptions{"dictfile"}    = $opt_dictfile;       }
	if(defined $opt_config)        { $vectoroptions{"config"}      = $opt_config;         }
	if(defined $opt_vectorindex)   { $vectoroptions{"vectorindex"}  = $opt_vectorindex;   }
	if(defined $opt_debugfile)     { $vectoroptions{"debugfile"}    = $opt_debugfile;     } 
	if(defined $opt_vectormatrix)  { $vectoroptions{"vectormatrix"} = $opt_vectormatrix;  }
	if(defined $opt_defraw)        { $vectoroptions{"defraw"}       = $opt_defraw;        }
	if(defined $opt_vectorstoplist){ $vectoroptions{"stoplist"}     = $opt_vectorstoplist;}
	if(defined $opt_stem)          { $vectoroptions{"stem"}         = $opt_stem;          }
	if(defined $opt_compoundfile)  { $vectoroptions{"compoundfile"} = $opt_compoundfile;   }
	
	$meas = UMLS::Similarity::vector->new($umls,\%vectoroptions);
    }
    
    die "Unable to create measure object.\n" if(!$meas);
    
    return $meas;
}

#  load the UMLS Interface Package
sub load_UMLS_Interface {
 
    if($debug) { print STDERR "In load_UMLS_Interface\n"; }

    if(defined $opt_t) { 
	$option_hash{"t"} = 1;
    }
    if(defined $opt_config) {
	$option_hash{"config"} = $opt_config;
    }
    if(defined $opt_debug) {
	$option_hash{"debug"} = $opt_debug;
    }
    if(defined $opt_forcerun) {
	$option_hash{"forcerun"} = $opt_forcerun;
    }
    if(defined $opt_realtime) {
	$option_hash{"realtime"} = $opt_realtime;
    }
    if(defined $opt_undirected) { 
	$options_hash{"realtime"} = $opt_undirected;
    }
    if(defined $opt_smooth) { 
	$option_hash{"smooth"} = $opt_smooth;
    }
    if(defined $opt_username and defined $opt_password) {
	$option_hash{"driver"}   = "mysql";
	$option_hash{"database"} = $database;
	$option_hash{"username"} = $opt_username;
	$option_hash{"password"} = $opt_password;
	$option_hash{"hostname"} = $hostname;
	$option_hash{"socket"}   = $socket;
    }
    
    my $umls = UMLS::Interface->new(\%option_hash); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
    
    return $umls;
}

#  checks the user input options
sub checkOptions {

    if($debug) { print STDERR "In checkOptions\n"; }

    if( (defined $opt_weight) && (! (defined $opt_window)) ) { 
	print STDERR "The --weight option can only be used with the --window option.\n";
	    &minimalUsageNotes();
	    exit;
    }

    if((defined $opt_candidates) && (defined $opt_sval2)) { 
	print STDERR "The --candidates option is not available for the sval2 format.\n";
	&minimalUsageNotes();
	exit;
    }

    if((defined $opt_cuis) && (! (defined $opt_mmxml) )) { 
	print STDERR "The --cuis option is only available for the mmxml format.\n";
	&minimalUsageNotes();
	exit;
    }

    if(defined $opt_measure) {
	if($opt_measure=~/\b(path|wup|lch|cdist|nam|vector|res|lin|random|jcn|lesk)\b/) {
	    #  good to go
	}
	else {
	    print STDERR "The measure ($opt_measure) is not defined for\n";
	    print STDERR "the UMLS-SenseRelate package at this time.\n\n";
	    &minimalUsageNotes();
	    exit;
	}   
    }
    
     if(defined $opt_stem) { 
	if(! ($opt_measure=~/vector|lesk/) ) {
	    print STDERR "The --stem option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_dictfile) { 
	if(! ($opt_measure=~/vector|lesk/) ) {
	    print STDERR "The --dictfile option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_debugfile) { 
	if(! ($opt_measure=~/(vector|lesk)/) ) {
	    print STDERR "The --debugfile option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    
    
    if(defined $opt_vectormatrix and defined $opt_vectorindex) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --vectormatrix and --vectorindex options are only\n";
	    print STDERR "available when using the vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    
    
    if(defined $opt_vectormatrix) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --vectormatrix option is only available\n";
	    print STDERR "when using the vector measure. \n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_compoundfile) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --compoundfile option is only available\n";
	    print STDERR "when using the vector measure. \n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_vectorindex) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --vectorindex option is only available\n";
	    print STDERR "when using the vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    
    
    #  the --smooth option can only be used with the icfrequency options
    if(defined $opt_smooth) {
	if(!defined $opt_icfrequency) {
	    print STDERR "The --smooth option can only be used with the\n";
	    print STDERR "--icfrequency option.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }

    if(defined $opt_icpropagation and defined $opt_intrinsic) {
        print STDERR "You can not specify both the --icpropagation and\n";
        print STDERR "--intrinsic options at the same time.\n\n";
        &minimalUsageNotes();
        exit;
    }

    if(defined $opt_icfrequency and defined $opt_intrinsic) {
        print STDERR "You can not specify both the --icfrequency and\n";
        print STDERR "--intrinsic options at the same time.\n\n";
        &minimalUsageNotes();
	exit;
    }

    #  the icpropagation and icfrequency options can only be used 
    #  with specific measures
    if(defined $opt_icpropagation || defined $opt_icfrequency || defined $opt_intrinsic) { 
	if( !($opt_measure=~/(res|lin|jcn)/) ) {
	    print STDERR "The --icpropagation or --icfrequency options\n";
            print STDERR "may only be specified when using the res, lin\n";
	    print STDERR "or jcn measures.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    


    if(defined $opt_icpropagation and defined $opt_icfrequency) { 
	print STDERR "You can specify both the --icpropagation and\n";
	print STDERR "--icfrequency options at the same time.\n\n";
	&minimalUsageNotes();
	exit;
    }    
    
    if(defined $opt_precision) {
	if ($opt_precision !~ /^\d+$/) {
	    print STDERR "Value for switch --precision should be integer >= 0\n";
	    &minimalUsageNotes();
	    exit;
	}
    }
}

#  method sets the stoplist
#  input : $stoplist <- file containing stoplist
#  output: $regex    <- string containing regex
sub setStopList {

    if($debug) { print STDERR "In setStopList\n"; }    

    open(STOP, $opt_stoplist) || die "Could not open $opt_stoplist\n";
    $stopregex = "(";
    while(<STOP>) { 
	chomp;
	$_=~s/^\///g;
	$_=~s/\/$//g;
	$stopregex .= "$_|";
    }
    chop $stopregex;
    $stopregex .= ")";
}

#  set user input and default options
sub setOptions {

    if($debug) { print STDERR "In setOptions\n"; }

    my $set     = "";
    my $default = "";

    #  get the time stamp
    my $timestamp = &time_stamp();

    #  umls-targetword-senserelate.pl options
    if(defined $opt_sval2)    { $set .= "  --sval2\n";     }
    elsif(defined $opt_plain) { $set .= "  --plain\n";     }
    else                      { $default .= "  --plain\n"; }

    if(defined $opt_weight) { $set .= "  --weight\n"; }
    if(defined $opt_key)    { $set .= "  --key\n";    }
    if(defined $opt_cuis)   { $set .= "  --cuis\n";   }

    if(defined $opt_loadcache) { $set .= "  --loadcache $opt_loadcache\n"; }
    if(defined $opt_setcache)  { $set .= "  --setcache $opt_setcache\n"; }

    $log = "log.$timestamp";
    if(defined $opt_log) { 
	$set .= "  --log $opt_log\n"; 
	$log  = $opt_log;
    }
    else { $default .= "  --log $log\n"; }

    if(-e $log) { 
	print STDERR "The log directory ($log) already exists!";
	print STDERR "Overwrite (Y/N)? ";
	$reply = <STDIN>;
	chomp $reply;
	$reply = uc $reply;
	exit 0 if ($reply ne "Y");
    } else { system "mkdir $log"; }
    
    $precision = 4;
    if(defined $opt_precision) {
	$precision = $opt_precision;
	$set       .= "  --precision $precision\n";
    }
    else {
	$precision = 4;
	$default  .= "  --precision $precision\n";
    }
    $floatformat = join '', '%', '.', $precision, 'f';
    
    #  UMLS::SenseRelate Options
    if(defined $opt_senses)     { $set .= "  --senses $opt_senses\n";     }    
    if(defined $opt_candidates) { $set .= "  --candidates\n";             }

    if(defined $opt_stoplist)   { 
	$set .= "  --stoplist $opt_stoplist\n"; 
	&setStopList();
    }

    if(defined $opt_window)   { 
	$window = $opt_window;
	$set .= "  --window $opt_window\n";     
    }
    else { 
	$window = 2;
	$default .= "  --window 2\n";           
    }

    if(defined $opt_restrict) { $set .= "  --restrict\n"; }

    if(defined $opt_compound) { $set .= "  --compound\n"; }
    
    if(defined $opt_trace) { 
	if(-e $opt_trace) { 
	    print STDERR "The trace file ($opt_trace) already exists!";
	    print STDERR "Overwrite (Y/N)? ";
	    $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ($reply ne "Y");
	} 
	
	$set .= "  --trace $opt_trace\n"; 
    }

    if(defined $opt_aggregator) {
	$aggregator = $opt_aggregator;
	$set    .= "  --aggregator $aggregator\n";
    }
    else {
	$aggregator  = "avg";
	$set     .= "  --aggregator $aggregator\n";
    }

    #  UMLS::Interface options
    if(defined $opt_config) { 
	$config = $opt_config;
	$set .= "  --config $config\n";
    }

    if(defined $opt_realtime) {	$set .= "  --realtime\n"; }    
    if(defined $opt_debug)    {	$set .= "  --debug\n";    }
    
    #  set the UMLS::Interface Database Options
    if(defined $opt_username) {
	if(defined $opt_username) { $set     .= "  --username $opt_username\n"; }
	if(defined $opt_password) { $set     .= "  --password XXXXXXX\n";       }
	if(defined $opt_database) {
	    $database = $opt_database;
	    $set     .= "  --database $database\n";
	}
	else {
	    $database = "umls";
	    $set    .= "  --database $database\n";
	}

	if(defined $opt_hostname) {
	    $hostname = $opt_hostname;
	    $set     .= "  --hostname $hostname\n";
	}
	else {
	    $hostname = "localhost";
	    $set     .= "  --hostname $hostname\n";
	}
	
	if(defined $opt_socket) {
	    $socket = $opt_socket;
	    $set   .= "  --socket $socket\n";
	}
	else {
	    $socket   = "/tmp/mysql.sock\n";
	    $set     .= "  --socket $socket\n";
	}
    }
    
    #  UMLS::Similarity options
    if(defined $opt_measure) {
	$measure = $opt_measure;
	$set    .= "  --measure $measure\n";
    }
    else {
	$measure  = "path";
	$set     .= "  --measure $measure\n";
    }

    if(defined $opt_undirected) { 
	$set .= "  --undirected\n";
    }

    if(defined $opt_icpropagation) {
	$set .= "  --icpropagation $opt_icpropagation\n";
    }
    if(defined $opt_icfrequency) {
	$set .= "  --icfrequency $opt_icfrequency\n";
    }
    if(defined $opt_intrinsic) {
	$set .= "  --intrinsic $opt_intrinsic\n";
    }
    if(defined $opt_smooth) {
	$set .= "  --smooth\n";
    }
    if(defined $opt_vectormatrix) { 
	$set .= "  --vectormatrix $opt_vectormatrix\n";
    }
    if(defined $opt_vectorindex) { 
	$set .= "  --vectorindex $opt_vectorindex\n";
    }
    if(defined $opt_compoundfile) { 
	$set .= "  --compoundfile $opt_compoundfile\n";
    }

    if(defined $opt_debugfile) { 
	$set .= "  --debugfile $opt_debugfile\n";
    }    
    if(defined $opt_dictfile) {
	$set .= "  --dictfile $opt_dictfile\n";
    }
    if(defined $opt_defraw) { 
	$set .= "  --defraw\n";
    }
    if(defined $opt_vectorstoplist) {
	$set .= "  --vectorstoplist $opt_vectorstoplist\n";
    }
    if(defined $opt_leskstoplist) {
	$set .= "  --leskstoplist $opt_leskstoplist\n";
    }
    if(defined $opt_stem) { 
	$set .= "  --stem\n";
    }

    if(defined $opt_st) { 
	$set .= "  --st\n";
    }

    #  print settings
    if($default ne "") { 
	print STDERR "Default Options:\n";
	print STDERR "$default\n";
    }
    if($set ne "") { 
	print STDERR "UserOptions: \n";
	print STDERR "$set\n";
    }
}

##############################################################################
#  function to create a timestamp
##############################################################################
sub time_stamp {
    my ($stamp);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    $year += 1900;
    $mon++;
    $d = sprintf("%4d%2.2d%2.2d",$year,$mon,$mday);
    $t = sprintf("%2.2d%2.2d%2.2d",$hour,$min,$sec);
    
    $stamp = $d . $t;

    return($stamp);
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: umls-targetword-senserelate.pl [OPTIONS] INPUTFILE\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility \n";
  
    print "Usage: umls-targetword-senserelate.pl [OPTIONS] INPUTFILE\n\n";
    
    print "\n\nGeneral Options:\n\n";

    print "--plain                  INPUTFILE is in plain format. Default\n\n";
    
    print "--sval2                  INPUTFILE is in sval2 format.\n\n";
    
    print "--mmxml                  INPUTFILE is in mmxml format.\n\n";

    print "--candidates             Uses the candidate senses as identified\n";
    print "                         by metamap for the target word. \n\n";

    print "--cuis                   Use the CUIs tagged by metamap not the terms\n\n";

    print "--senses FILE|DIR        File or directory containing the sense files\n\n";
    
    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         semantic similarity. (DEFAULT: path)\n\n";

    print "--aggregator AGGREGATOR  The aggregator method to be used to combine\n";
    print "                         the similarity scores (DEFAULT: avg)\n\n";
 
    print "--restrict               This restricts the window to be contain the \n";
    print "                         context whose terms maps to a UMLS concept\n\n";

    print "--window N               The context used to disambiguate the target word.\n";
    print "                         Default: 2\n\n";

    print "--weight                 Weight the context based on distance from the target\n";
    print "                         word.\n\n";

    print "--stoplist FILE          A file containing a list of words to be excluded\n\n";

    print "--key                    Stores the  key file information in $log.key for\n";
    print "                         the purposes of evaluation\n\n";

    print "--log STR                Directory containing the output files\n";
    print "                         Default: log \n\n";

    print "--compound               Input text contains compounds denoted by an under-\n";
    print "                         score in plain or sval tex.\n\n"; 

    print "--loadcache FILE         Preloads cache.\n\n";

    print "--getcache FILE          Dumps cache to file.\n\n";

    print "--trace FILE             This stores the trace information in FILE for debugging.\n\n";

    print "--loadcache FILE         FILE containing similarity scores of cui pairs.\n\n";
    
    print "--getcache FILE         Outputs the cache into FILE \n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "\n\nUMLS Interface Options\n\n";

    print "--config FILE            Configuration file\n\n";        
    
    print "--realtime               This option finds the path and propagation\n";
    print "                         information for relevant measures in realtime\n";
    print "                         rather than building an index\n\n";

    print "--forcerun               This option will bypass any command \n";
    print "                         prompts such as asking if you would \n";
    print "                         like to continue with the index \n";
    print "                         creation. \n\n";
    
    print "\n\nDatabase Options: \n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "\n\nIC Measure Options:\n\n";

    print "--icpropagation FILE     File containing the information content\n";
    print "                         of the CUIs.\n\n";

    print "--intrinsic [seco|sanchez] Use the intrinsic IC defined either by\n";
    print "                           Seco et al 2004 or Sanchez et al 2011\n\n";

    print "\n\nVector Options:\n\n";

    print "--vectormatrix FILE      The matrix file containing the vector\n";
    print "                         information for the vector measure.\n\n";

    print "--vectorindex FILE       The index file containing the vector\n";
    print "                         information for the vector measure.\n\n";
        
    print "\n\nVector and Lesk Measure Options:\n\n";
    
    print "--compoundfile FILE      This is a compound word file for the vector and lesk\n";
    print "                         measures. It contains the compound word lists.\n";
    print "                         For the compounds words in the definitions \n";
    print "                         are treated as a single unit.\n\n";

    print "--dictfile FILE          This is a dictionary file for the vector and lesk\n";
    print "                         measure. It contains the 'definitions' of a concept\n";
    print "                         which would be used rather than the definitions from\n";
    print "                         the UMLS\n\n";

    print "--stem                   This is a flag for the vector and lesk method. \n";
    print "                         If the --stem flag is set, words are stemmed. \n\n";

    print "--defraw                 This is a flag for the vector or lesk measure. The \n";
    print "                         definitions used are 'cleaned'. If the --defraw\n";
    print "                         flag is set they will not be cleaned. \n\n";
    
    print "--vectorstoplist FILE    File containing the stoplist for the vector measure.\n\n";
    
    print "--leskstoplist FILE      File containing the stoplist for the lesk measure.\n\n";

    print "\n\nDebug Options:\n\n";

    print "--debug                  Sets the UMLS-Interface debug flag on\n";
    print "                         for testing purposes\n\n";

}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-targetword-senserelate.pl,v 1.23 2013/07/24 09:25:58 btmcinnes Exp $';
    print "\nCopyright (c) 2010-2012, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-targetword-senserelate.pl --help for help.\n";
}

