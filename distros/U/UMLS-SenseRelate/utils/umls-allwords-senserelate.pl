#!/usr/bin/perl 

=pod

=head1 NAME

umls-allwords-senserelate.pl - This program performs all-words word sense 
disambiguation and assigns senses from the UMLS to each ambiguous term in 
a runnning text using semantic similarity measures.

=head1 SYNOPSIS

umls-allwords-senserelate.pl - This program performs all-words word sense 
disambiguation and assigns senses from the UMLS to each ambiguous term in 
a runnning text using semantic similarity or relatedness measures from the 
UMLS::Similarity package.

=head1 USAGE

Usage: umls-allwords-senserelate.pl [OPTIONS] INPUTFILE

=head2 OUTPUT

The output files will be stored in the directory "log" or 
the directory defined by the --log option. 

=head2 Required Options

=head3 INPUTFILE 

Input file either in all-words xml format indicated by the --awxml 
option (which is also the default).

=head2 General Options:

=head3 --awxml

The input format is all-words xml, similar to what is found in the 
all-words disambiguating semeval task. This is the default format. 

In this format each line of the text files contains a single word
where the words to be disabugated are identified by:

  <head id="id">word</head>.

And the context is encapsulated in text tags <text id="id"> ... </text>

For example: 

  <text id="d000">
  That
  <head id="d000.s000.t001">is</head>
  what
  the
  <head id="d000.s000.t004">man</head>
  had
  <head id="d000.s000.t006">said</head>
  .
  Haney
  <head id="d000.s001.t001">peered</head>
  at
  his
  <head id="d000.s001.t005">drinking</head>
  <head id="d000.s001.t006">companion</head>
  doubtfully 
  .
  </text>

Please note that the following id format is required: 

  d[0-9]+ refers to the document id
  s[0-9]+ refers to the sentence number in the document
  t[0-9]+ refers to the term number in the sentence 

The padding of zeros is optional. 

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

To use this option, the input text must contain the key information in 
the following format:
  
   <head id="id" sense="sense">target word</head>

For example:

   <head id="d000.s001.t006" sense="C0000000">companion</head>

=head3 --candidates

The candidate information is embedded in the inputfile in the following 
format:

  <head id="id" candidates="sense1,sense2,sense3">target word</head>

For example:

  <head id="d001.s001.t001" candidates="C1280500,C2348382">effect</head>

=head3 --window NUMBER

The window in which to obtain the context surrounding the ambiguous term. 

Default: 2

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

A file containing a list of words to be excluded. This is used in 
the UMLS::SenseRelate::TargetWord module as well as the vector and 
lesk measures in the UMLS::Similarity package. The format required 
is one stopword per line, words are in regular expression format. 
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

If you do not want to use the default, this file is generated by the 
vector-input.pl program. An example of this file can be found in the 
samples/ directory and is called index.

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

  umls-allwords-senserelate.pl --measure lesk hand foot

2. --dictfile - which will just use the dictfile definitions

  umls-allwords-senserelate.pl --measure lesk --dictfile samples/dictfile hand foot

3. --dictfile + --config - which will use both the UMLS and dictfile 
definitions

  umls-allwords-senserelate.pl --measure lesk --dictfile samples/dictfile --config
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

Copyright (c) 2010-2012

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
use UMLS::SenseRelate::AllWords;
use Getopt::Long;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "measure=s", "config=s", "forcerun", "debug", "icpropagation=s", "realtime", "stoplist=s", "vectorstoplist=s", "leskstoplist=s", "vectormatrix=s", "vectorindex=s", "defraw", "dictfile=s", "t", "stem", "window=s", "key", "log=s", "candidates", "awxml", "compound", "trace=s", "undirected", "weight")) or die ("Please check the above mentioned option(s).\n");


#  set debug
my $debug = 0;
if(defined $opt_debug) { $debug = 1; }

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
my $precision    = "";
my $floatformat  = "";
my $measure      = "";
my $window       = "";
my $weight       = "";
my %instancehash = ();

#  check and set the options
&checkOptions       ();
&setOptions         ();

#  load the UMLS::Interface, UMLS::Similarity Measure and the 
#  UMLS::SenseRelate package - order matters here!
my $umls        = &load_UMLS_Interface();
my $meas        = &load_UMLS_Similarity();
my $senserelate = &load_UMLS_SenseRelate();

#  get the instances
&setInput($source);

#  set the key
if(defined $opt_key) { 
   &setKey();
}

&assignSenses();

print STDERR "The results will be found in the $log directory\n";

#########################################################################################
##  SUB FUNCTIONS
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
	&load_XML_Input($inputfile); 
    }
}

#  assign senses to the instances in instancehash using 
#  the UMLS::SenseRelate::TargetWord  module
sub assignSenses {

    if($debug) { print STDERR "In assignSenses\n"; }
    
    foreach my $id (sort keys %instancehash) { 
	
	if($debug) { print STDERR "  Assigning senses to instance $id\n"; }

	#  get the context
	my @context = @{$instancehash{$id}}; 

	#  assign the senses to the terms
	my $assignments = $senserelate->assignSenses(\@context);

	#  open the log files
	open(ANSWERS, ">$log/$id.answers") || die "Could not open $log/$id.answers\n"; 
       	foreach my $element (@{$assignments}) { 
	    print ANSWERS "$element\n";
	}
	close ANSWERS;
    }
}

#  loads the instances in plain format in to the instance hash
sub load_XML_Input {

    my $inputfile = shift;
    
    if($debug) { print STDERR "In loadPlainInput for $inputfile\n"; }
    
    #  open the input file
    open(INPUT, $inputfile) || die "Could not open input file: $inputfile\n";
    
    #  get the instance and instance information
    my $id = ""; my @ontext = (); my $flag = 0;
    while(<INPUT>) { 
	chomp;
	
	if($_=~/^\s*$/)        { next; }
	if($_=~/<\?xml/)       { next; }
	if($_=~/<\!DOCTYPE/)   { next; }
	if($_=~/<corpus lang/) { next; }
	if($_=~/<\/corpus>/)   { next; }
	
	if($_=~/<MMOs>/) { 
	    print STDERR "\nERROR. This file looks like it is in mm-xml format rather than aw-xml format.\n";
	    print STDERR "Please check the format of your input file.\n\n";
	    &minimalUsageNotes();
	    exit;
	}

	#  get the id
	if($_=~/<text id=\"(.*?)\"/) { $id = $1; next; }

	#  store the context
	if($_=~/<\/text>/) { 
	    $instancehash{$id} = [@context];
	    $id = ""; @context = (); 
	    next;
	}

	#  if candidate option is set make certain
	#  that each instance has a candidate tag
	if(defined $opt_candidates) { 
	    if($_=~/<head id=/) { 
		if(! ($_=~/candidates=\"(.*?)\"/)) { 
		    print STDERR "\nERROR. This instance does not contain the candidate senses.\n";
		    print STDERR "Instance: $_\n";
		    print STDERR "Please check the format of your input file.\n\n";
		    &minimalUsageNotes();
		    exit;
		}                  
	    }
	}            
	
	#  so what is left over is the terms - check to make 
	#  certain the format is correct if tagged
	if($_=~/\<head/) { 
	    $flag = 1;
	    $_=~/<head id=\"(d[0-9]+)\.(s[0-9]+)\.(t[0-9]+)\"/;
	    my $d = $1; my $s = $2; my $t = $3;
	    if($d eq "" || $s eq "" || $t eq "") { 
		
		    print STDERR "\nERROR. This instance does not look to be in the correct format.\n";
		    print STDERR "Instance: $_\n";
		    print STDERR "Please check the format of your input file.\n\n";
		    &minimalUsageNotes();
		    exit;
	    }
	}
	
	#  add the terms to the context
	push @context, $_; 
    }

    if($flag == 0) { 
	print STDERR "\nERROR. This file looks like it is in plain format rather than aw-xml format.\n";
	print STDERR "Please check the format of your input file.\n\n";
	&minimalUsageNotes();
	exit;
    }
}

sub setKey {

    if(! (defined $opt_key)) { next; }

    if($debug) { print STDERR "In setKey\n"; }

    foreach my $id (sort keys %instancehash) { 
	
	if($debug) { print STDERR "  Setting key for instance $id\n"; }

	foreach my $id (sort keys %instancehash) { 
	    
	    #  open the key file
	    open(KEY, ">$log/$id.key") || 
		die "Could not open key ($log/$id.key) file\n";
	
	    #  get the context
	    my @context = @{$instancehash{$id}}; 
	    
	    #  loop through the context and print the key
	    foreach $element (@context) {
		if($element=~/<head/) { 
		    $element=~/<head id=\"(.*?)\"/;
		    my $tid    = $1;
		    $element=~/>(.*?)</;
		    my $tw    = $1;
		    if($element=~/sense=\"(.*?)\"/) { 
			my $sense = $1;
			print KEY "$id $tid $tw\%$sense\n";
		    }
		    else {
			print STDERR "\nERROR. This instance does not contain sense information\n";
			print STDERR "Instance: $element\n";
			print STDERR "Please check the format of your input file\n\n";
			&minimalUsageNotes();
			exit;
		    }

		    
		    
		} 
	    } close KEY;
	}
    }
}

#  load the Umls-Allwords-Senserelate package
sub load_UMLS_SenseRelate {

    if($debug) { print STDERR "In load_UMLS_SenseRelate\n"; }
        
    my %option_hash = ();
    
    $option_hash{"window"}   = $window;

    if(defined $opt_compound)  { $option_hash{"compound"}   = $opt_compound;  }
    if(defined $opt_stoplist)  { $option_hash{"stoplist"}   = $opt_stoplist;  }
    if(defined $opt_trace)     { $option_hash{"trace"}      = $opt_trace;     }
    if(defined $opt_candidates){ $option_hash{"candidates"} = $opt_candidates;}
    if(defined $opt_weight)    { $option_hash{"weight"}     = $opt_weight;    }

    $option_hash{"measure"} = $measure;

    my $handler = UMLS::SenseRelate::AllWords->new($umls, $meas, \%option_hash); 
    die "Unable to create UMLS::Interface object.\n" if(!$handler);
    
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
    #  load the module implementing the Resnik (1995) measure
    if($measure eq "res") {
	use UMLS::Similarity::res;
	$meas = UMLS::Similarity::res->new($umls);
    }
    #  load the module implementing the Jiang and Conrath 
    #  (1997) measure
    if($measure eq "jcn") {
	use UMLS::Similarity::jcn;
	$meas = UMLS::Similarity::jcn->new($umls);
    }
    #  load the module implementing the Lin (1998) measure
    if($measure eq "lin") {
	use UMLS::Similarity::lin;
	$meas = UMLS::Similarity::lin->new($umls);
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
	
	if(defined $opt_config)      { $leskoptions{"config"}    = $opt_config;       }
	if(defined $opt_leskstoplist){ $leskoptions{"stoplist"}  = $opt_leskstoplist; }
	if(defined $opt_stem)        { $leskoptions{"stem"}      = $opt_stem;         }
	if(defined $opt_debugfile)   { $leskoptions{"debugfile"} = $opt_debugfile;    }
	if(defined $opt_defraw)      { $leskoptions{"defraw"}    = $opt_defraw;       }
	if(defined $opt_dictfile)    { $leskoptions{"dictfile"}  = $opt_dictfile;     }
	
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
    if(defined $opt_icpropagation) {
	$option_hash{"icpropagation"} = $opt_icpropagation;
    }
    if(defined $opt_icfrequency) { 
	$option_hash{"icfrequency"} = $opt_icfrequency;
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
    if(defined $opt_measure) {
	if($opt_measure=~/\b(path|wup|lch|cdist|nam|vector|res|lin|random|jcn|lesk)\b/) {
	    #  good to go
	}
	else {
	    print STDERR "The measure ($opt_measure) is not defined for\n";
	    print STDERR "the Umls-Senserelate package at this time.\n\n";
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
    
    #  the icpropagation and icfrequency options can only be used 
    #  with specific measures
    if(defined $opt_icpropagation || defined $opt_icfrequency) { 
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

#  set user input and default options
sub setOptions {


    if($debug) { print STDERR "In setOptions\n"; }

    #  intialize the output variables
    my $set     = "";
    my $default = "";
        
    #  get the time stamp
    my $timestamp = &time_stamp();
    
    #  umls-allwords-senserelate.pl options
    if(defined $opt_awxml)  { $set .= "  --awxml\n";     }
    else                    { $default .= "  --awxml\n"; }

    if(defined $opt_weight) { $set .= "  --weight\n"; }
    if(defined $opt_key)    { $set .= "  --key\n"; }


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
    
    if(defined $opt_stoplist) { $set .= "  --stoplist $opt_stoplist\n"; }
    
    if(defined $opt_candidates) { $set .= "  --candidates\n"; }

    if(defined $opt_window)   { 
	$window = $opt_window;
	$set .= "  --window $opt_window\n";     
    }
    else { 
	$window = 2;
	$default .= "  --window 2\n";           
    }

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
    if(defined $opt_smooth) {
	$set .= "  --smooth\n";
    }
    if(defined $opt_vectormatrix) { 
	$set .= "  --vectormatrix $opt_vectormatrix\n";
    }
    if(defined $opt_vectorindex) { 
	$set .= "  --vectorindex $opt_vectorindex\n";
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

    #  print settings
    print STDERR "Default Settings:\n";
    print STDERR "$default\n";
    print STDERR "User Settings:\n";
    print STDERR "$set\n";
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
    
    print "Usage: umls-allwords-senserelate.pl [OPTIONS] INPUTFILE\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility \n";
  
    print "Usage: umls-allwords-senserelate.pl [OPTIONS] INPUTFILE\n\n";
    
    print "\n\nGeneral Options:\n\n";

    print "--awxml                  The input format is all-words xml (DEFAULT).\n\n";

    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         semantic similarity. (DEFAULT: path)\n\n";

    print "--window N               The context used to disambiguate the target word.\n";
    print "                         Default: 2\n\n";

    print "--weight                 Weight the context based on distance from the target\n";
    print "                         word.\n\n";

    print "--stoplist FILE          A file containing a list of words to be excluded\n\n";

    print "--key                    Stores the  key file information in $log.key for\n";
    print "                         the purposes of evaluation\n\n";

    print "--candidates             Sense information is embedded in the inputfile\n\n";

    print "--log STR                Directory containing the output files\n";
    print "                         Default: log \n\n";

    print "--compound               Input text contains compounds denoted by an under-\n";
    print "                         score in plain or sval tex.\n\n"; 

    print "--trace FILE             This stores the trace information in FILE for debugging.\n\n";

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

    print "\n\nVector Options:\n\n";

    print "--vectormatrix FILE        The matrix file containing the vector\n";
    print "                         information for the vector measure.\n\n";

    print "--vectorindex FILE         The index file containing the vector\n";
    print "                         information for the vector measure.\n\n";
    

    print "\n\nVector and Lesk Measure Options:\n\n";
    
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
    print '$Id: umls-allwords-senserelate.pl,v 1.12 2012/04/13 22:09:37 btmcinnes Exp $';
    print "\nCopyright (c) 2011, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-allwords-senserelate.pl --help for help.\n";
}
    
