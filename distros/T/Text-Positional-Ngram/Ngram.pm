#########################################################################
# PACKAGE: Text::Positional::Ngram
#
# Copyright (C), 2004-2007
# Bridget Thomson McInnes,       bthomson@d.umn.edu
#
# University of Minnesota, Duluth
#
# USAGE:
#           use Text::Positional::Ngram
#
# DESCRIPTION:
#
#      The Text::Positional::Ngram module determines contiguous and 
#      noncontiguous n-grams and their frequency from a given corpus.
#      See perldoc Text::Positional::Ngram
#
#########################################################################
package Text::Positional::Ngram;

use 5.008;
use strict;
use bytes;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Positional::Ngram ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.5';

#########################
#  File Name Variables  #
#########################
my $CORPUS_FILE   = "";
my $VOCAB_FILE    = "";
my $SNT_FILE      = "";
my $SNTNGRAM_FILE = "";
my $NGRAM_FILE    = "";
my $STOPLIST      = "";
my $TOKEN_FILE    = "";
my $NONTOKEN_FILE = "";

###########################
#  User defined Variables #
###########################
my $max_ngram_size = 2;      #default is 2
my $min_ngram_size = 2;      #default is 2
my $ngram_size     = 2;      #default is 2
my $frequency      = 0;      #default is 0
my $window_size    = 0;      #default is 0

#########################
#  Stop List Variables  #
#########################
my $stop_mode      = "AND";  #AND/OR default is AND
my $stop_regex = "";         #regex to store stop list
   
############################
#  Token Obtion Variables  #
############################
my $tokenizerRegex    = "";
my $nontokenizerRegex = "";

####################
#  Flag Variables  #
####################
my $stop_flag      = 0;   #default is false
my $marginals      = 0;   #default is false
my $remove         = 0;   #default is false;
my $new_line       = 0;   #default is false

#####################
#  Cache Variables  #
#####################
my $unigrams = "";
my %remove_hash = ();

#####################
#  Array Variables  #
#####################
my @vocab_array = ();
my @window_array = ();

#########################
#  Main Mask Variables  #
#########################
# VEC VARIABLES
my $corpus = "";   # corpus vec

# MISC VARIABLES
my $N = 0;           # the length of the corpus
my $bit = 32;        # the bit size for the vec array
my $ngram_count = 0; # the number of ngrams
my $win_bit = 1;     # the bit size for the windowing
my $timestamp = "";  # the time stamp for the files

###############
# new method  #
###############
my $location;
sub new
{
    # First argument is class
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{dir} = shift if (defined(@_ > 0));
    $self->{verbose} = @_ ? shift : 0;

    warn "Dir = ", $self->{dir}, "\n" if ($self->{verbose});
    warn "Verbose = ", $self->{verbose}, "\n" if ($self->{verbose});

    #  Initialize some variables at new
    $CORPUS_FILE    = "";    $VOCAB_FILE    = "";    
    $SNT_FILE       = "";    $SNTNGRAM_FILE = "";
    $NGRAM_FILE     = "";    $STOPLIST      = "";    
    $TOKEN_FILE     = "";    $NONTOKEN_FILE = "";

    $stop_flag      = 0;     $marginals     = 0;     
    $remove         = 0;     $new_line      = 0;   
    $ngram_size     = 2;     $frequency     = 0;     
    $window_size    = 0;

    $unigrams          = "";  %remove_hash    = ();  
    $nontokenizerRegex = "";  $tokenizerRegex = "";

    return $self;
}


#######################################
#  Create the vocabulary and snt file #
#######################################
sub create_files
{
    my $self = shift;  my @files = @_;

    #  Open the corpus, vocab and snt files
    open(VOCAB , ">$VOCAB_FILE") || die "Could not open the vocabfile: $!\n";
    open(SNT,    ">$SNT_FILE")   || die "Could not open the sntfile : $!\n";
    
    #  Create the token and nontoken regular expression
    if($NONTOKEN_FILE ne "") { set_nontoken_regex(); } set_token_regex();
    
    ################################################
    #  Index always starts at 2 because 1 is       #
    #  considered a new line parameter if defined  #
    ################################################

    my $index = 2; my %vocab_hash = ();

    foreach (@files) {
        open(CORPUS, $_) || die "Could not find the corpus file: $_\n";
	while(<CORPUS>) {
	    chomp;
	    
	    s/$nontokenizerRegex//g;
	    
	    while( /$tokenizerRegex/g ) {
		my $token = $&;
		
		if (! exists $vocab_hash{$token} ) {
		    print SNT "$index "; 
		    print VOCAB "$index\n";  print VOCAB "$token\n";
		    $vocab_hash{$token} = $index++; 
		}
		else {
		    print SNT "$vocab_hash{$token} ";
		}
	    }
	    print SNT "1" if $new_line;
	    print SNT "\n";
	}
    }
}

######################
#  Remove the files  #
######################
sub remove_files
{
    my $self = shift;

    system("rm -rf $VOCAB_FILE");
    system("rm -rf $SNT_FILE");
    system("rm -rf $SNTNGRAM_FILE");
}

###########################
#  Remove the ngram file  #
###########################
sub remove_ngram_file
{
    system("rm -rf $NGRAM_FILE");
}


############################
#  Creates the token file  #
#  CODE obtained from NSP  #
############################
sub set_token_regex
{
    my $self = shift; my @tokenRegex = (); $tokenizerRegex = "";
    
    if(-e $TOKEN_FILE) {
	open (TOKEN, $TOKEN_FILE) || die "Couldnt open $TOKEN_FILE\n";
	
	while(<TOKEN>)        {
	    chomp; s/^\s*//; s/\s*$//;
	    if (length($_) <= 0) { next; }
	    if (!(/^\//) || !(/\/$/))
	    {
		print STDERR "Ignoring regex with no delimiters: $_\n"; next;
	    }
	    s/^\///; s/\/$//;
	    push @tokenRegex, $_;
	}
	close TOKEN;
    }
    else  {
	push @tokenRegex, "\\w+"; push @tokenRegex, "[\.,;:\?!]";
    }
    
    # create the complete token regex
    
    foreach my $token (@tokenRegex)
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
	print STDERR "No token definitions to work with.\n";
	exit;
    }
}

##########################################
#  Set the non token regular expression  #
#         CODE Obtained from NSP         # 
##########################################
sub set_nontoken_regex
{
    $nontokenizerRegex = "";

    #check if the file exists
    if($NONTOKEN_FILE)
    {
	#open the non token file
	open(NOTOK, $NONTOKEN_FILE) || die "Couldn't open Nontoken file $NONTOKEN_FILE.\n";

	while(<NOTOK>) {
	    chomp;
	    s/^\s+//; s/\s+$//;
	    
	    #handling a blank lines
	    if(/^\s*$/) { next; }

	    if(!(/^\//)) {
		print STDERR "Nontoken regular expression $_ should start with '/'\n"; exit;
	    }
	    
	    if(!(/\/$/)) {
		print STDERR "Nontoken regular expression $_ should end with '/'\n"; exit;
	    }
	    
	    #removing the / s from the beginning and the end
	    s/^\///;
	    s/\/$//;
	    
	    #foorm a single regex
	    $nontokenizerRegex .="(".$_.")|";
	}
	
	# if no valid regexs are found in Nontoken file
	if(length($nontokenizerRegex)<=0) {
	    print STDERR "No valid Perl Regular Experssion found in Nontoken file $NONTOKEN_FILE.\n";
	    exit;
    	}
	
	chop $nontokenizerRegex;
    }  
    else {
	print STDERR "Nontoken file $NONTOKEN_FILE doesn't exist.\n";
	exit;
    }
} 

##############################
#  Create the stoplist hash  #
#   CODE obtained from NSP   #
##############################
sub create_stop_list
{
    my $self = shift;
    my $file = shift;
    
    $stop_regex = "";

    open(FILE, $file) || die "Could not open the Stoplist : $!\n";
    
    while(<FILE>) {
	chomp;	# accepting Perl Regexs from Stopfile
	s/^\s+//;
	s/\s+$//;
	
	#handling a blank lines
	if(/^\s*$/) { next; }
	
	#check if a valid Perl Regex
	if(!(/^\//)) {
	    print STDERR "Stop token regular expression <$_> should start with '/'\n";
	    exit;
	}
	if(!(/\/$/)) {
	    print STDERR "Stop token regular expression <$_> should end with '/'\n";
	    exit;
	}
	
	#remove the / s from beginning and end
	s/^\///;
	s/\/$//;
	
	#form a single big regex
	$stop_regex.="(".$_.")|";
    }
    
    if(length($stop_regex)<=0) {
	print STDERR "No valid Perl Regular Experssion found in Stop file.";
	exit;
    }
    
    chop $stop_regex;
    
    #  Reset the stop flag to true
    $stop_flag = 1;
    
    close FILE;
}

###############################
#  Load the vocabulary array  #
###############################
sub load_vocab_array
{
    open(VOCAB, $VOCAB_FILE) || die "Could not open the vocab file: $!\n";

    @vocab_array = ();
    while(<VOCAB>) {
	chomp;
	my $token = <VOCAB>; chomp $token;
	$vocab_array[$_] = $token;
    }

}

#################################
#  Set the windowing parameter  #
#################################
sub set_window_size
{
        my $self = shift;
        $window_size = shift;
}

##############################
#  Set the remove parameter  #
##############################
sub set_remove
{
        my $self = shift;
        $remove  = shift;
}

################################
#  Set the marginal parameter  #
################################
sub set_marginals
{
        $marginals = 1;
}

################################
#  Set the new_line parameter  #
################################
sub set_new_line
{
	$new_line = 1;
}

#######################
#  Set the frequency  #
#######################
sub set_frequency
{
        my $self = shift;
        $frequency = shift;
}

############################
#  Set minimum ngram size  #
############################
sub set_ngram_size
{
        my $self = shift;
        $ngram_size = shift;

	$min_ngram_size = $ngram_size;
	$max_ngram_size = $ngram_size;
}

#######################
#  Set the stop mode  #
#######################
sub set_stop_mode
{

    my $self = shift;
    $stop_mode = shift;
}

########################
#  Set the token file  #
########################
sub set_token_file
{
    my $self = shift;
    $TOKEN_FILE = shift;
}

###########################
#  Set the nontoken file  #
###########################
sub set_nontoken_file
{
    my $self = shift;
    $NONTOKEN_FILE = shift;
}

#############################
#  Set the ngram file name  #
#############################
sub set_destination_file
{
    my $self = shift;
    my $file = shift;

    $timestamp = time();  

    #  Set the file names of the internal files
    #  that will be used by the perl module.
    $VOCAB_FILE    = $file . ".vocab."    . $timestamp;
    $SNT_FILE      = $file . ".snt."      . $timestamp;
    $SNTNGRAM_FILE = $file . ".sntngram." . $timestamp;

    #  Set the ngram file
    $NGRAM_FILE    = $file;
}

#################################
#  Return the number of ngrams  #
#################################
sub get_ngram_count
{ 
    return $ngram_count;
}

###########################
#  Return the ngram file  #
###########################
sub get_ngram_file
{
    return $NGRAM_FILE;
}

##########################################################
#  METHOD THAT CALLS THE FUNCTIONS TO OBTAIN THE NGRAMS  #
##########################################################
sub get_ngrams
{

    #  Set the ngram count to zero
    $ngram_count = 0;

    #  Create the corpus array
    corpus_array();
       
    #  If the window size is 0; set it equal to the
    #  size of the ngram
    $window_size = $ngram_size if $window_size == 0;

    #  check to make certain marginals are not set with
    #  the window size greater than the ngram size
    $marginals = 0 if $window_size > $ngram_size;

    #  create the window
    create_window();
   
    #  print ngrams to the snt ngram file
    print_sntngrams();
  
    #  print the token ngram to the ngram file
    print_ngrams();
}

#############################
#  Create the corpus array  #
#############################
sub corpus_array
{
    #open SNTFILE
    open(SNT, $SNT_FILE) || die "Could not open the sntfile: $!\n";
    
    #  Initialize the variables
    my $offset = 0; $corpus = ""; $N = 0;

    while(<SNT>){
	chomp;
	my @t = split/\s+/;
	foreach (@t) { vec($corpus, $offset++, $bit)  = $_; $N++; vec($unigrams, $_, $bit)++; }
    }

    #decrement N by one to obtain the actual size of the corpus
    $N--;
}

#################################################
#  WINDOWING METHODS DESCRIBED BY GIL AND DIAS  #
#################################################
sub create_window
{
    my $doc = 0; @window_array = ();

    for my $i(0..$N) {

	for my $j(0..((2**$window_size)-1) ) {

	    #  determine the binary representation of one of the possible ngram combinations
	    my @bitarray = split//, unpack("B32", pack("N", $j));

	    #  ensure that it is not greater than the corpus size
	    if($i+$ngram_size > ($N+1) ) { next; }
	    
	    #  Reduce the bit array from 32 to the window size
	    my @bits = @bitarray[$#bitarray-$window_size+1 .. $#bitarray]; if($bits[0] != 1) { next; }
	    
	    #  Get the size of the possible ngram and if it to large or small -  next
	    my $size=0;  map{$size+=$_} @bits; if($size!=$ngram_size){ next; }

	    #  Looks like everything is correct so create the bit vec for the positional ngram
	    my $temp = ""; my $offset = 0; 

	    #  Set document number and the start position
	    vec($temp, $offset++, $bit) = $doc;    vec($temp, $offset++, $bit) = $i;
	    	 
	    #  Create the bit map
	    map{ vec($temp, $offset++, $win_bit) = $bits[$_] } 0..$#bits;  push @window_array, $temp;
	}
    }
} 

##############################################
#  Prints the positional ngrams for testing  #
##############################################
sub print_window
{
    print "$#window_array\n";
    foreach my $win (@window_array) {
	my $start = vec($win, 1, $bit);
	my $index = $start;
	my @ngram = ();
	for my $j(2..$window_size+1) {
	    if( vec($win, $j, $win_bit) == 1  ) {
		push @ngram, vec($corpus, $index, $bit);
	    }
	    $index++;
	}
	print "@ngram\n";
    }
}

#####################################
#  Print the sntngrams to the file  #
#####################################
sub print_sntngrams
{
    #  Open the SNTGRAM File #
    open(SNTNGRAM, ">$SNTNGRAM_FILE") ||
	die "Could not open the SNTNGRAM file : $!\n";
    
     #  Load the vocab hash if doesn;t exist
    if (!@vocab_array) { load_vocab_array(); }

    my @prev = (); my $freq = 0;
    foreach my $win (sort byvec @window_array) {

	my $index = vec($win, 1, $bit); my @ngram = (); my $zero_flag = 0;
	
	#  Get the ngram
	for (2..$window_size+1) {
	    push @ngram, vec($corpus, $index, $bit) if vec($win, $_, $win_bit) == 1;  $index++;
	}
	
	if($ngram[$#ngram] == 0) { next; }
	
	#  First time around need to initialize the @prev
	if($#prev == -1 )  { @prev = @ngram; $freq++;}  
	
	#  If @ngram and @prev are not equal print @prev and its freq.
	#  Reinitialize freq and @prev, increment the ngram count.
	elsif( (join " ", @ngram) ne (join " ", @prev) ) { 
	   
	    #  Check if the ngram is valid
	    my $return_value = valid( (join " ", @prev), $freq);
	    
	    #  If it is okay, print the ngram to the sntngram file
	    if($return_value == 1) { print SNTNGRAM "@prev $freq\n"; }

	    #  Initialize the freq and previous ngram
	    $freq = 1; @prev = @ngram; 
	    
	} else { $freq++; }
    }
    #  Print the last ngram to the sntngram file if it is valid
    my $return_value = valid( (join " ", @prev), $freq );
    if($return_value == 1) { print SNTNGRAM "@prev $freq\n"; }
}

#####################################################
#  Check to determine if the ngram is a valid ngram  #
######################################################
sub valid
{
    my @ngram = split/\s+/, shift;
    my $freq = shift;
    
    #  Initialize variables
    my $doStop = 0; my $line = 0; my @token_ngram = ();
    
    #  Get the token ngram 
    map { push @token_ngram, $vocab_array[$ngram[$_]] } 0..$#ngram;
	  
    #  If stoplist exists determine if the ngram is part of the stoplist
    if($stop_flag) {
	
	#  Set the doStop flag
	if($stop_mode=~/OR|or/) { $doStop = 0; } else { $doStop = 1; }
	
	for my $i(0..$#token_ngram) {
	    # if mode is OR, remove the current ngram if any word is a stop word
	    if($stop_mode=~/OR|or/) { if($token_ngram[$i]=~/$stop_regex/) { $doStop=1; last; } }
	    
	    # if mode is AND, accept the current ngram if any word is not a stop word 
	    else { if(!($token_ngram[$i]=~/$stop_regex/)) { $doStop=0; last; } }
	}
	#  If counting the marginals add the adjustment to the remove_hash
	if($doStop && $marginals) {
	    for (0..$#ngram) {
		if(exists $remove_hash{$_ . ":" . $ngram[$_]}) {
		    $remove_hash{$_ . ":" . $ngram[$_]} += $freq;
		}
		else { $remove_hash{$_ . ":" . $ngram[$_]} = $freq; }
	    }
	}
    }
    
    #  If new line determine if the new line exists in the  ngram
    if($new_line) { map { if($_ == 1) { $line++; } } @ngram; }

    #  If the ngram frequency is greater or equal to a specified frequency, a new 
    #  line flag is false and the ngram is not elimanted by the stop list then print 
    #  the ngram in its integer form  with its frequency to the snt ngram file
    if($doStop == 0 && $line == 0) { 
	if($remove <= $freq) {
	    $ngram_count+=$freq; 
	    if($frequency <= $freq) {  return 1; }
	}
	else {
	    for (0..$#ngram) {
		if(exists $remove_hash{$_ . ":" . $ngram[$_]}) {
		    $remove_hash{$_ . ":" . $ngram[$_]} += $freq;
		}
		else { $remove_hash{$_ . ":" . $ngram[$_]} = $freq; }
	    }
	}
    } 
    return 0;
}

#############################################
#  Print the positional ngrams to the file  #
#############################################
sub print_ngrams
{
    #open the SNTNGRAM file
    open(SNTNGRAM, $SNTNGRAM_FILE) || die "Could not open the sntngram file: $!\n";
    
    #open the ngram file
    open(NGRAM, ">$NGRAM_FILE") || die "Could not open the ngram file: $! \n";
    
    #  Load the vocab hash if doesn;t exist
    if (!@vocab_array) { load_vocab_array(); }

    #  Print the ngram count
    print NGRAM "$ngram_count\n";
    
    while(<SNTNGRAM>) {
	#  get the ngram and its frequency
	chomp; my @ngram = split/\s+/, $_;   my @marginalFreqs = ();
	
	my $freq = pop @ngram;

	if($marginals) { @marginalFreqs = Marginals(@ngram); }

	#  print the ngram
	for (0..$#ngram) { print NGRAM "$vocab_array[$ngram[$_]]<>"; }

    	# print the frequencies
	print NGRAM "$freq @marginalFreqs \n";
    }
}


#  Gets the marginal counts for each individual word in the ngram
sub Marginals
{
    my @marginalFreqs = ();
    
    for my $i(0..$#_) {
	push @marginalFreqs, vec($unigrams, $_[$i], $bit);
		
	if($i == 0) {
	    if($_[$i] == vec($corpus, $N, $bit)) { $marginalFreqs[$#marginalFreqs] -= 1; }
	}
	if($i == $#_) {
	    if($_[$i] == vec($corpus,  0, $bit)) { $marginalFreqs[$#marginalFreqs] -= 1; }
	}

	if($stop_flag || $remove > 0) {
	    if(exists $remove_hash{$i . ":" . $_[$i]}) {
		$marginalFreqs[$#marginalFreqs] -= $remove_hash{$i . ":" . $_[$i]};
	    }
	}
    }
    return @marginalFreqs;
}

#############################
#  Windowing sort function  #
#############################
sub byvec
{
    #  Get the ngrams of the two elements
    my @a_array = (); my @b_array = ();  my $z = 0; my $x = 0; my $counter = 0;
    my $a_index = vec($a, 1, $bit);    my $b_index = vec($b, 1, $bit);
    for my $i(2..$window_size+1) {
	if(vec($a, $i, $win_bit) == 1) { push @a_array, vec($corpus, $a_index, $bit); } $a_index++;
	if(vec($b, $i, $win_bit) == 1) { push @b_array, vec($corpus, $b_index, $bit); } $b_index++;
    }
    
    #  Find the first occurence of a non equal token in the ngrams, if exists.
    for $z(0..$#a_array) { if($a_array[$z]!=$b_array[$z]) { $x = $z; next; } }
    
    return ( $a_array[$x] > $b_array[$x] ? 1 : 
	     ($a_array[$x] < $b_array[$x] ? -1 : 0) );

}


1;

__END__

=head1 NAME

Text::Positional::Ngram 

=head1 SYNOPSIS

This document provides a general introduction to the Text::Positional::Ngram 
module.

=head1 DESCRIPTION

=head2 1. Introduction

The Text::Positional::Ngram module is a module that allows for the retrieval
of variable length ngrams. An ngram is defined as a sequence of 'n' tokens 
that occur within a window of at leaste 'n' tokens in the text. What 
constitutes as a 'token' can be defined by the user.

=head2 2. Ngrams

An ngram is a sequence of n tokens. The tokens in the ngrams are delimited
by the diamond symbol, "<>". Therefore "to<>be<>" is a bigram whose tokens 
consist of "to" and "be". Similarly, "or<>not<>to<>" is a trigram whose tokens
consist of "or", "not", and "to".

Given a piece of text, Ngrams are usually formed of contiguous tokens. For 
example, if we take the phrase:

    to     be     or     not     to     be

The bigrams for this phrase would be:

    to<>be<>     be<>or<>     or<>not<>

The trigrams for this phrase would be:

    to<>be<>or<>     be<>or<>not<>     
    or<>not<>to<>    not<>to<>be<>

=head2 3. Tokens  


We define a token as a contiguous sequence of characters that match one of a
set of regular expressions. These regular expressions may be user-provided,
or, if not provided, are assumed to be the following two regular expressions: 

 \w+        -> this matches a contiguous sequence of alpha-numeric characters

 [\.,;:\?!] -> this matches a single punctuation mark

For example, assume the following is a line of text:

"to be or not to be, that is the question!"

Then, using the above regular expressions, we get the following tokens:

    to           be           or          not       
    to           be           ,           that      
    is           the          question    !


If we assume that the user provides the following regular expression:

 [a-zA-Z]+  -> this matches a contiguous sequence of alphabetic characters

Then, we get the following tokens:

    to           be           or          not       
    to           be           that        is      
    the          question 
    

=head2 4. Usage

    use Text::Positional::Ngram;

=head3 Text::Positional::Ngram Requirements

   use Text::Positional::Ngram;

   #  create an instance of Text::Positional::Ngram
   my $text = Text::Positional::Ngram->new();

   #  create the files needed and specify which
   #  file you would like to get the ngrams from
   $text->create_files("my_file.txt");

   #  get the ngrams
   $text->get_ngrams();

=head3 Text::Positional::Ngram Functions

=item 1.  create_files(@FILE)

    Takes an array of files in which the ngrams are
    to be obtained from. This function will creates the 
    files that are required for the ngrams to be 
    created. These files are defined as the name of the
    first file entered in the FILE array and timestamped.

    1. vocabulary file : converts tokens to integers prefix: 
    2. snt file        : integer representation of corpus
    3. sntngram file   : integer representation of the ngrams
                         and their frequency counts
    4. ngram file      : ngrams and their frequencies


=item 2.  get_ngrams()

    Obtains ngrams of size two and their frequencies
    storing them in the given ngram file.

=item 3. create_stop_list(FILE)

    Removes n-grams containing at least one (in OR mode) 
    stop word or all stop words (in AND mode). The default 
    is OR mode. Each stop word should be a regular expression 
    in this FILE and should be on a line of its own. These 
    should be valid Perl regular expressions, which means that 
    any occurrence of the forward slash '/' within the regular 
    expression must be 'escaped'. 

=item 4. set_stop_mode(MODE)
    
    OR mode removes n-grams containing at least 
    one stop word and AND mode removes n-grams 
    that consists of entirely of stop words. 
    Default:  AND

=item 5.  set_token_file(FILE)

    Each regular expression in this FILE should be on a line
    of its own, and should be delimited by the forward slash 
    '/'. These should be valid Perl regular expressions, which 
    means that any occurrence of the forward slash '/' within 
    the regular expression must be 'escaped'. 
    
    NOTE: This function should be called before the 
    function that creates the main files ie before 
    create_files(FILE).
        
=item 6.  set_nontoken_file(FILE)
    
    The set_nontoken_file function can be used when there 
    are predictable sequences of characters that you know 
    should not be included as tokens.

    NOTE: This function should be called before the 
    function that creates the main files ie before 
    create_files(FILE).

=item 7.  set_remove()

    Ignores Ignores n-grams that occur less than N times. 
    Ignored n-grams are not counted and so do not affect 
    counts and frequencies.

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.
           
=item 8.  set_marginals()

    The marginal frequencies consist of the frequencies of 
    the individual tokens in their respective positions in
    the n-gram. 

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 9.  set_newline()

    Prevents n-grams from spanning across the new-line
    character
        
=item 10. set_frequency(N)

    Does not display n-grams that occur less than N times

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 11. set_min_ngram_size(N)
    
    Finds n-grams greater than or equal to size N.
    Default: 2

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 12. set_max_ngram_size(N)

    Finds n-grams less than or equal to size N
    Default: 2

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 13. set_ngram_size(N)
    
    Finds ngrams equal to size N
    Default : 2

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 14. set_destination_file(FILE)
    
    Prints the ngrams to FILE. 

    The hidden files that get erased when program is 
    completed are named: <FILE>.<ext>.

    If this is not set the files will be named
    default.<ext>
    
=item 15. get_ngram_count()
    
    Returns the number of n-grams.

=item 16. remove_files()

    Removes the snt, sntngram and the vocab file.
    
=item 17. set_window_size(N)

    Sets the size of the window in which positional 
    ngram can be found in.
=head1 AUTHOR

Bridget Thomson McInnes, bthomson@d.umn.edu

=head1 BUGS

Limitations of this package are:

=item 1.  Only a partial set of marginal counts are found in
this package. The frequency of the individual tokens in the 
n-gram are recorded. For example, given the trigram, w1 w2 w3,
the marginal counts that would be returned are: the number of 
times w1 occurs in position one of the ngram, the number of 
times that w2 occurs in the second position of an ngram, and
the number of times that w3 occurs in the third position of 
the ngram. 

=item 2. The size of the corpus that this package can retrieve
ngrams fromm is limited to approximatly 75 million tokens. Please
note that this number may vary dependng on what options are
used.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (C) 2004-2007, Bridget Thomson McInnes

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
02111-1307, USA.

Note: a copy of the GNU Free Documentation License is available 
on the web at L<http://www.gnu.org/copyleft/fdl.html> and is 
included in this distribution as FDL.txt. 

perl(1)
