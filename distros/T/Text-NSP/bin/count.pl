#!/usr/local/bin/perl -w

=head1 NAME

count.pl - Count the frequency of Ngrams in text

=head1 SYNOPSIS

count.pl takes as input one or more text files and calculate the ngram  
frequency for the whole corpus.

=head1 DESCRIPTION

See perldoc README.pod

=head1 AUTHOR

Satanjeev Banerjee, bane0025@d.umn.edu

Ted Pedersen, tpederse@d.umn.edu

=head1 BUGS

=head1 SEE ALSO

 home page:    http://www.d.umn.edu/~tpederse/nsp.html

 mailing list: http://groups.yahoo.com/group/ngram/

=head1 COPYRIGHT

Copyright (C) 2000-2003, Ted Pedersen and Satanjeev Banerjee

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut

# count.pl version 0.57
#

###############################################################################
#
#                       -------         CHANGELOG       ---------
#
#version        date            programmer      List of changes     change-id
#
# 0.53          01/06/2003      Amruta      (1)	Added Perl Regex     ADP.53.1	
#						support for stop 
#						option 
#
#		01/06/2003	Amruta	    (2) Added AND & OR modes
#						for stop option      ADP.53.2	
#						making AND default	
#
#		01/07/2003	Amruta	    (3) Introduced 
#						--nontoken option    ADP.53.3	
#                   
# 0.57          06/30/2003      Ted         (1) show remove value    TDP.57.1
#                                               in extended output
#             
#               07/01/2003      Ted         (2) if destination file  TDP.57.2
#		                                found, check for 
#                                               source before proceeding
#
# 0.58		01/29/2010      Ying        (1) Introduced 
#						--tokenlist option   YDP.58.1
#
###############################################################################

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
GetOptions( "verbose", "recurse", "version", "help", "tokenlist", "histogram=s",
            "frequency=i", "ufrequency=i", "window=i", "stop=s", "newLine", "extended",
            "token=s", "ngram=i", "remove=i", "uremove=i", "set_freq_combo=s", "get_freq_combo=s","nontoken=s");

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

if (defined $opt_recurse) { $opt_recurse = 1; }

if (defined $opt_tokenlist) { $opt_tokenlist = 1; }

if ( defined $opt_frequency ) { $cutOff = $opt_frequency; }
else                          { $cutOff = 0; }

                         ## YL.58.1 START
if ( defined $opt_ufrequency ) { $ucutOff = $opt_ufrequency; }
else				{$ucutOff = 100000000;}

if ((defined $opt_frequency) and (defined $opt_ufrequency))
{
	if ($opt_frequency > $opt_ufrequency)
	{
		print "--frequency must be smaller than --ufrequency!\n";
		print STDERR "Type count.pl --help for help.\n";
		exit;
	}
}
                         ## TDP.57.1 START
if ( defined $opt_remove )    { $removeOff = $opt_remove }
else                          { $removeOff = 0; }
                         ## TDP.57.1 FINISH

if ( defined $opt_uremove )   { $uremoveOff = $opt_uremove }
else                          { $uremoveOff = 100000000;} 

if ((defined $opt_remove) and (defined $opt_uremove))
{
	if ($opt_remove > $opt_uremove)
	{
		print "--remove must be smaller than --uremove!\n";
		print STDERR "Type count.pl --help for help.\n";
		exit;
	}
}
if ( defined $opt_ngram )     { $ngram = $opt_ngram; }
else                          { $ngram = 2; }
                         ## YL.58.1 FINISH

if ($ngram <= 0) 
{
    print STDERR "Cannot have 'n' value of ngrams as less than 1\n";
    askHelp();
    exit();
}

if ( defined $opt_window ) { $windowSize = $opt_window; }
else 
{ 
    $windowSize = $ngram; 
    if (defined $opt_verbose)
    {
        print "Using default window size = $windowSize\n";
    }
}

if ($windowSize < $ngram || ($ngram == 1 && $windowSize != 1))
{
    print STDERR "Illegal value for window size. Should be >= size of ngram (1 if size of ngram is 1).\n";
    askHelp();
    exit();
}

# get hold of the frequency combinations that we need to keep track
# of, either from the file provided
if ((defined $opt_set_freq_combo) and (!defined $opt_tokenlist))
{
    readFreqCombo($opt_set_freq_combo);
}
# or, by default, everything possible
elsif ((!defined $opt_set_freq_combo) and (!defined $opt_tokenlist))
{
    getDefaultFreqCombos();
}

if ((defined $opt_get_freq_combo) and (!defined $opt_tokenlist))
{
    open (FREQ_COMBO_OUT, ">$opt_get_freq_combo") || die ("Couldnt open $opt_get_freq_combo");
    
    for ($i = 0; $i < $combIndex; $i++)
    {
	for ($j = 1; $j <= $freqComb[$i][0]; $j++)
	{
	    print FREQ_COMBO_OUT "$freqComb[$i][$j] ";
	}
	print FREQ_COMBO_OUT "\n";
    }

    close (FREQ_COMBO_OUT); 
}

# at the end of those two functions we should have with us the @freqComb
# array!

# check if tokens file has been supplied. if so, try to open it and extract
# the regex's.
if ( defined $opt_token )
{
    open (TOKEN, $opt_token) || die "Couldnt open $opt_token\n";
    
    while(<TOKEN>)
    {
        chomp; s/^\s*//; s/\s*$//;
        if (length($_) <= 0) { next; }
        if (!(/^\//) || !(/\/$/))
        {
            print STDERR "Ignoring regex with no delimiters: $_\n";
            next;
        }
        s/^\///; s/\/$//;
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
    print STDERR "No token definitions to work with.\n";
    askHelp();
    exit;
}

# ---------------
# ADP.53.3 start
# ---------------
# Introducing new --nontoken option to remove any sequence of characters 
# that matches the regular expression specified by the --nontoken option.
# With this, we also allow user to specify what is not a valid token.
# Providing this option is important because the user can specify some 
# special character sequences which include tokens but need to be entirely 
# removed 

#if the non-token file is specified
if(defined $opt_nontoken)
{

  #check if the file exists
  if(-e $opt_nontoken)
     {

     #open the non token file
     open(NOTOK,"$opt_nontoken") || die "Couldn't open Nontoken file $opt_nontoken.\n";

     while(<NOTOK>) {

	chomp;
	s/^\s+//;
       	s/\s+$//;
        
        #handling a blank lines
       	if(/^\s*$/) {
             next;
       	}

        if(!(/^\//)) {
            print STDERR "Nontoken regular expression $_ should start with '/'\n";
            exit;
       	}
        
        if(!(/\/$/)) {
            print STDERR "Nontoken regular expression $_ should end with '/'\n";
            exit;
       	}
        
        #removing the / s from the beginning and the end
	s/^\///;
        s/\/$//;
        
        #form a single regex
	$nontoken_regex.="(".$_.")|";

        }  ## end of while 

	# if no valid regexs are found in Nontoken file
	if(length($nontoken_regex)<=0) {
          print STDERR "No valid Perl Regular Experssion found in Nontoken file $opt_nontoken.\n";
	  exit;
    	}

	chop $nontoken_regex;

      }  ## end of if not-token exists 

     else {
         print STDERR "Nontoken file $opt_nontoken doesn't exist.\n";
         exit;
     }
} ## end of if non-token option defined 

# Added --nontoken option functionality
# -------------
# ADP.53.3 end
# -------------

# having stripped the commandline of all the options etc, we should now be
# left only with the source/destination files

#  we moved this here in order to create the stop regex so that it can 
#  be used with the --tokenlist option - 16 Feb 2010 Bridget
my $stop_regex = "";
my $stop_mode = "AND";
if(defined $opt_stop) {

    # we have already checked that the stop list exists. open it and create
    # the stop hash
    #  we moved this in order to account for the --tokenlist option

    open ( STP, $opt_stop ) ||
        die ("Couldn't open the stoplist file $opt_stop\n");

    # --------------
    # ADP.53.1 start 
    # --------------
    # Perl Regex support for stop option
    # this will accept the stop tokens from the 
    # stop file as Perl regular experssions 
    # delimited by slashes /regex/ 
    # each regex should appear on a separate line 
    
    # commented code belongs to old version 0.51 
    # my %stopHash = (); version 0.51 code 
    
    while ( <STP> ) 
    { 
         chomp; 
    # 	 version 0.51 code
    #    s/^\s+//;
    #    s/\s+$//;
    #    if ( /^\/(.*)\/$/ ) 
    #    { 
    #        $stopHash{$1} = 1;
    #    }
    #}
	# ---------------
	# ADP.53.2 start
	# ---------------
	# Adding support for AND and OR Stop modes 
	# AND Mode will remove those ngrams which 
	# consist of all stop words 
	# OR Mode will remove those ngrams which 
	# consist of at least one stop word
	# Default Mode will be AND Mode

        if(/\@stop.mode\s*=\s*(\w+)\s*$/) {
		$stop_mode=$1;
		if(!($stop_mode=~/^(AND|and|OR|or)$/)) {
			print STDERR "Requested Stop Mode $1 is not supported.\n";
			exit;
		}
		next;
	} 
	# --------------
        # ADP.53.2 end
        # --------------

	# accepting Perl Regexs from Stopfile
	s/^\s+//;
	s/\s+$//;

	#handling a blank lines
	if(/^\s*$/)
	{
		next;
	}
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
	print STDERR "No valid Perl Regular Experssion found in Stop file $opt_stop";
	exit;
    }
    chop $stop_regex;

    # Added Perl Regex Support for Stop option
    # ------------
    # ADP.53.1 end 
    # ------------

    # --------------
    # ADP.53.2 start
    # --------------
    # making AND a default stop mode
    if(!defined $stop_mode) {
	$stop_mode="AND";
    }
    # ------------
    # ADP.53.2 end
    # ------------
    close STP;
}

# so, first get hold of the destination file!
$destination = shift;

# check to see if a destination has been supplied at all...
if ( !($destination ) )
{
    print STDERR "No output file (DESTINATION) supplied.\n"; 
    askHelp();
    exit;
}

# TDP.57.2 start (moved this) check for destination file and source file
# before proceeding

# whats left in the command line are paths. go thru them and salvage all
# text files to be processed. the following function does just that, putting
# all useful files in @sourceFiles :o)

&getSourceFiles(@ARGV);

# if not even one file found, complain and quit!
if ($#sourceFiles == -1)
{
    print STDERR "No input (SOURCE) file supplied!\n";
    askHelp();
    exit;
}
# TDP.57.2 finish (moved this)

# check to see if destination exists, and if so, if we should overwrite...
if ( -e $destination )
{
    print "Output file $destination already exists! Overwrite (Y/N)? ";
    $reply = <STDIN>;
    chomp $reply;
    $reply = uc $reply;
    exit 0 if ($reply ne "Y");
}

# having ascertained that we may open the destination file for output, lets 
# do so...

open ( DST, ">$destination" ) || die "Couldn't open output file $destination";

# TDP.57.2 old location of check for source files

# output the files found, if verbose set!
if ( defined $opt_verbose )
{
    print "\nFound the following $index file(s) to source from: \n";
    for  ( $i = 0; $i < $index; $i ++ ) { print "$sourceFiles[$i]\n"; }
    print "\n";
}

# get all the permutations for this ngram/windowSize combination. this tells
# us which words to pick from a window to form the various ngrams
@permutations = ();
getPermutations($windowSize-1, $ngram-1, 0);

# ngramTotal will contain the total number of ngrams found!
$ngramTotal = 0;

# now get the source files one by one from @sourceFiles, and process them in
# a loop!
foreach $source (@sourceFiles)
{
    # we already know that the file exists... that is checked by
    # &getSourceFiles, so no need to check it again! just open and
    # proceed.
    open( SRC, "$source" ) || die "Cant open SOURCE file $source, quitting";
    
    # having successfully opened the source file start reading it...
    if ( defined $opt_verbose ) { print "Accessing file $source.\n"; }    
    
    # start off the window index which will tell us where in the window array
    # we are right now. this is a global variable to be used by processToken
    # to figure out what to do with a new token. 
    $windex = 0; # the NEXT place in the window array to write to!
    
    # read in the file, tokenize and process the token thus found

    while (<SRC>)
    {
        # if we dont want ngrams to span across the new line, then every
        # time we process a new line, we need to refresh the window
        if ( defined $opt_newLine )
        {
            $opt_newLine = 1;
            $windex = 0;
        }

	# ---------------
	# ADP.53.3 start 
	# ---------------
	# Removing sequences of characters which are declared as non-tokens
	# These are detected and removed before checking for tokens because 
	# those sequences which include valid tokens in them should be removed 
	# since the whole sequence is declared as a non-token

	if(defined $nontoken_regex) {
		s/$nontoken_regex//g;
	}

	# Removed non-tokens from the input stream
	# -------------
        # ADP.53.3 end
        # -------------
 
        # now for this line, tokenize the line and send the token for
        # processing. 

        while ( /$tokenizerRegex/g ) {
            $token = $&;
            processToken($token);
        }
    }
}

# that is the tokenizing and token-processing done!
# now to put in the stop list, if its been provided

if ( defined $opt_stop ) {
    
    # having got the file, go thru the ngrams, removing the offending ngrams
    foreach (keys %ngramFreq) {

        @tempArray = split /<>/;
	# --------------
        # ADP.53.2 start
        # --------------
        # Adding AND/OR Modes for Stopping Ngrams containing atleast 
	# one or all stop words
        # commented code from here belongs to version 0.51

        #my $doStop = 1;
	my $doStop;

	#by default OR should get value 0 so that when any word matches 
	#a stop token, we can remove the ngram 
	if($stop_mode=~/OR|or/) {
		$doStop = 0;
	}

	#by default AND should get value 1 so that when any word doesn't
	#match a stop token, we can accept the ngram 

	else	{
		$doStop = 1;
	}

        for ($i = 0; $i <= $#tempArray; $i++ ) {
	    # verion 0.51 code
            #if (!(defined ($stopHash{$tempArray[$i]})))
	    #{
            #    $doStop = 0;
            #    last;
            #}

	    # if mode is OR, remove the current ngram if
            # any word is a stop word	
	    if($stop_mode=~/OR|or/) {
		if($tempArray[$i]=~/$stop_regex/)
                {
			$doStop=1;
                        last;
                }
            }
	    # if mode is AND, accept the current ngram if
            # any word is not a stop word 
            else {
		if(!($tempArray[$i]=~/$stop_regex/)) {
			$doStop=0;
			last;
		}
	    }
	    # Added support for AND and OR Stop modes
	    # -------------
	    # ADP.53.2 end
	    # -------------
        }
        if ($doStop)
        {
            # remove this ngram and adjust all frequencies appropriately
            removeNgram($_);
        }
    }
}

# now to remove n-grams if the --remove or --uremove option has been taken.
if ( defined $opt_remove )
{
	if ( defined $opt_uremove)
	{
		foreach  (keys %ngramFreq)
		{
        		removeNgram($_) if (($ngramFreq{$_} < $opt_remove) || ($ngramFreq{$_} > $opt_uremove));
		}	
	}
	else
	{
		foreach  (keys %ngramFreq)
		{
        		removeNgram($_) if ($ngramFreq{$_} < $opt_remove);
		}
	}
}
else
{
	if ( defined $opt_uremove)
	{
		foreach  (keys %ngramFreq)
		{
        		removeNgram($_) if ($ngramFreq{$_} > $opt_uremove);
		}
	}
}

# end of processing all the files. now to write out the information.
if ( defined $opt_verbose ) { print "Writing to $destination.\n"; }

if ( defined $opt_extended )
{
    $opt_extended *= 1;

    # print out the ngram size
    print DST "\@count.Ngram=$ngram\n";

    # print out the window size used
    print DST "\@count.WindowSize=$windowSize\n";

    # print out the frequency cut off used
    print DST "\@count.FrequencyCut=$cutOff\n";


                                  ## TDP.57.1 START
    # print out the remove cut off used   
    print DST "\@count.RemoveCut=$removeOff\n";
                                  ## TDP.57.1 FINISH

                                  ## YL.58.1 START
    # print out the frequency cut off used
    print DST "\@count.uFrequencyCut=$ucutOff\n";

    # print out the remove cut off used   
    print DST "\@count.uRemoveCut=$uremoveOff\n";


    ##########################################################################
    #                                                                        #
    # The following idea suggested by Otso Virtanen, ojtvirta@cs.helsinki.fi #
    #                                                                        #
    ########################################################################## 

    # print out the path/file name of the first file as input
    my $source;
    print DST "\@count.InputFilePath=";
    foreach $source (@sourceFiles) 
    {
	print DST "$source ";
    }
    print DST "\n";
}

# finally print out the total ngrams
if (!defined $opt_tokenlist)
{
    print DST "$ngramTotal\n";
}

foreach (sort { $ngramFreq{$b} <=> $ngramFreq{$a} } keys %ngramFreq)
{
    # check if this is below the cut-off frequency to be displayed
    # as set by switch --frequency. if so, quit the loop
    last if ($ngramFreq{$_} < $cutOff);

    # check if this is above the ucut-off frequency to be displayed
    # as set by switch --ufrequency. if so, quit the loop
    next if ($ngramFreq{$_} > $ucutOff);

    # get the components of this ngram
    my @words = split /<>/;

    # if a line starts with a single @, its a command (extended output).
    # if it starts with two consequtive @'s, then its a single 'literal' @.

    if ( $_ =~ /^@/ ) { print DST "@"; } 
    print DST "$_"; # ngram 

    # now print the frequency combo's requested
    my $j;
    for ($j = 0; $j < $combIndex; $j++)
    {
        my $tempString = "";
        my $k;
        for ($k = 1; $k <= $freqComb[$j][0]; $k++)
        {
            $tempString .= "$words[$freqComb[$j][$k]]<>";
        }
        $tempString .= $j;
        print DST "$frequencies{$tempString} ";
    }
    print DST "\n";
}

# having done it all, close all open files...
close SRC;
close DST;

# create histogram if necessary
if (defined $opt_histogram) { createHistogram(); }

# ... and thats it! :o)

#-----------------------------------------------------------------------------
#                       User Defined Function Definitions
#-----------------------------------------------------------------------------

# function to process tokens
sub processToken
{
    my $token = shift;

    if ($ngram > 1)
    {
        # first put the word into the window array!
        $window[$windex] = $token;
	
        # until we have enough to make our first ngram, just keep going!
        if ( $windex < $ngram-1 )
        {
            $windex++;
            return;
        }
	
        # otherwise, create the ngrams! our method here will be to create all
        # possible ngrams that END with the token that's just come in. thus we
        # shall avoid the pitfall of creating the same ngram twice (a possibility
        # when windowSize > ngram).

        # we already have the permutations array. get em!
	
        my $permutationsIndex = 0;
        while ($permutationsIndex <= $#permutations)
        {
            my $ngramString = "";
            my $okFlag = 1;
            for ($i = 0; $i < $ngram-1; $i++)
            {
                if ( $permutations[$permutationsIndex] < $windex )
                {
                    $ngramString .= $window[$permutations[$permutationsIndex]] . "<>";
                }
                else { $okFlag = 0; }
                $permutationsIndex++;
            }
	       
            if (!$okFlag) { next; }

            $ngramString .= "$window[$windex]<>";

            # that is our ngram then!
            # increment the ngramTotal

	    if (defined $opt_tokenlist) 
            {    
		if(defined $opt_stop) {
		    #  This is the stopregex copied from below in order to 
		    #  incorporate this functionality into the --tokenlist 
		    #  option - 16 Feb 2010 Bridget
		    
		    # by default AND should get value 1 so that when any word 
		    # doesn't match a stop token, we can accept the ngram 
		    my $doStop = 1;
		    #  otherwise set it to the or
		    if($stop_mode=~/OR|or/) {
			$doStop = 0;
		    }
		    
		    my @tempArray = split/<>/, $ngramString;
		    
		    for ($i = 0; $i <= $#tempArray; $i++ ) {
			
			if($stop_mode=~/OR|or/) { 
			    if($tempArray[$i]=~/$stop_regex/) {
				$doStop=1;
				last;
			    }
			}
			else {
			    if(!($tempArray[$i]=~/$stop_regex/)) {
				$doStop=0;
				last;
			    }
			}
		    }
		    
		    
		    if (! ($doStop) ) {
			print DST "$ngramString\n";
		    }
		}
		else {
		    print DST "$ngramString\n";
		}
            }    
            else 
            {    

                $ngramTotal++;

                # and the ngram freq hash. our output ngrams are going to
                # be sorted on this hash. we shall not show this frequency
                # tho... if this has to be shown, the corresponding combo
                # has to be in the loop below!
                $ngramFreq{$ngramString}++;
            
                # now increment the various frequencies according to the
                # @freqCombo array...
                my @words = split /<>/, $ngramString;
                my $j;
                for ($j = 0; $j < $combIndex; $j++)
                {
                     my $tempString = "";
                     my $k;
                     for ($k = 1; $k <= $freqComb[$j][0]; $k++)
                     {
                         $tempString .= "$words[$freqComb[$j][$k]]<>";
                     }
                     $tempString .= $j;
                     $frequencies{$tempString}++;
                }
	    }
        }

        # having dealt with all the new ngrams in this window,
        # increment the windex, if less than the size, or shift out
        # the first element of the array to make place for the next
        # word thats coming in!
	
        if ( $windex < $windowSize - 1 )    { $windex++; }
        else                                { shift @window; }
    }
    else # this is the case when ngram = 1
    {
        my $ngramString = $token . "<>";
        $ngramFreq{$ngramString}++;
	my $tempString = $token . "<>0";
	$frequencies{$tempString}++;
        $ngramTotal++;
    }
}

# function to remove an ngram and adjust the various frequency counts
# appropriately
sub removeNgram
{
    my $ngramString = shift;

    # first reduce the ngram total by the frequency of this ngram
    $ngramTotal -= $ngramFreq{$ngramString};

    # now get hold of the component words
    my @words = split /<>/, $ngramString;

    # and reduce each combination frequency by the freq of this ngram
    my $j;
    for ($j = 0; $j < $combIndex; $j++)
    {
        my $tempString = "";
        my $k;
        for ($k = 1; $k <= $freqComb[$j][0]; $k++)
        {
            $tempString .= "$words[$freqComb[$j][$k]]<>";
        }
        $tempString .= $j;
        $frequencies{$tempString} -= $ngramFreq{$ngramString};
        if ($frequencies{$tempString} <= 0)
        {
            delete $frequencies{$tempString};
        }
    }

    # finally remove this ngram!
    delete $ngramFreq{$ngramString};

    # and we are done!
}

# function to create a histogram given the ngramFreq hash of frequencies
sub createHistogram
{
    # check if output histogram file already exists
    if (-e $opt_histogram)
    {
        print "File $opt_histogram exists! Overwrite (Y/N)? ";
        $reply = <STDIN>;
        chomp $reply;
        $reply = uc $reply;
        return if ($reply ne "Y");
    }

    # having ascertained that we may open the histogram file for output, lets
    # do so...
    open ( HST, ">$opt_histogram" ) || die "Couldn't open $opt_histogram";

    # now to construct the histogram hash...
    my %histogram = ();
    $histogram{$ngramFreq{$_}}++ foreach (keys %ngramFreq);

    # having done that, lets print out to the histogram file...
    print HST "Total ngrams = $ngramTotal\n";

    printf HST "Number of n-grams that occurred %3d time(s) = %5d (%.2f percent)\n", $_, $histogram{$_}, ($histogram{$_}*$_*100)/$ngramTotal
        foreach (sort {$a<=>$b} keys %histogram);

    close HST;
}

# Function &getSourceFiles: function to take the command tail and
# return an array of text files to be used to count! while going thru the
# command line do the following processing:
#
# 1> if the string is a text file and can be opened, add it to the array.
# 2> if the string is a directory name, find all text files in that directory,
#    and append to array.
# 3> if the -r (recursive) option is set, go into all subdirectories of that
#    directory too, to do the above!

sub getSourceFiles
{
    # get the next commandline string...
    my $nextString = shift;
    $index = 0;
    
    while ( $nextString )
    {
        if ( !( -e $nextString ) )
        {
            # file doesn't exist... ignore!
	    
            if ( defined $opt_verbose ) { print "File $nextString does not exist!\n"; }
            $nextString = shift;
            next;
        }
	
    	if ( !( -r $nextString ) )
    	{
            # file can't be read... ignore!
            if ( defined $opt_verbose ) { print "File $nextString cant be read!\n"; }
            $nextString = shift;
            next;
    	}
    	
        if ( -d $nextString )
        {
            # this is a directory, go and search this directory for text files
            &directorySearch( $nextString );
            $nextString = shift;
            next;
        }
	
        if ( !( -T $nextString ) )
        {
            # file is not a text file... ignore!
            if ( defined $opt_verbose ) { print "$nextString is not a text file!\n"; }   
            $nextString = shift; 		
            next;
        }
	
        $sourceFiles[$index] = $nextString; 
        $index++;
        $nextString = shift;
    }
}

# function to (possibly recursively) search inside the given directory for
# text files
sub directorySearch
{
    my $directory = $_[0];
    
    opendir DIR, $directory || "Couldnt open directory $directory!\n";
    my @files = grep !/^\./, readdir DIR;
    @files = map "$directory/$_", @files;
    closedir DIR;
    
    my $file = "";
    
    foreach $file (@files)
    {
        if ( ( -d $file ) && ( defined $opt_recurse ) ) { &directorySearch($file); }
        if ( ( -T $file ) )
        {
            $sourceFiles[$index] = $file; 
            $index++;
        }
    }
}

# function that takes two numbers and creates a (global) array of
# numbers thusly: given the nos 5, 3 it creates the following array: 
# 0 1 2 0 1 3 0 1 4 0 2 3 0 2 4 0 3 4 1 2 3 1 2 4 1 3 4 2 3 4 
# to be used to create all possible n grams within a given window 
# to generate above list, call function thusly: getPermutations(5,3,0). 
# 0 is mandatory to get the recursion started. 
# generated list will be in global array called permutation[]

sub getPermutations
{
    my $totalLength = shift;
    my $lengthReqd = shift;
    my $level = shift;
    my $i; 

    if ($level == $lengthReqd)
    {
        for ($i = 0; $i < $lengthReqd; $i++ )
        {
            push @permutations, $tempArray[$i];
        }
        return;
    }

    my $start = ($level == 0) ? 0 : $tempArray[$level-1] + 1;
    my $stop = $totalLength - $lengthReqd + $level;

    for ($i = $start; $i <= $stop; $i++)
    {
        $tempArray[$level] = $i;
        getPermutations($totalLength, $lengthReqd, $level+1);
    }
}

# function to create the default frequency combinations to be computed
# and output
sub getDefaultFreqCombos
{
    my $i;

    # first create the first index of the comb, that is the
    # combination that includes all the characters in the window

    $combIndex = 0;
    $freqComb[0][0] = $ngram;
    for ($i = 0; $i < $ngram; $i++)
    {
        $freqComb[0][$i+1] = $i;
    }
    $combIndex++;

    # now create the rest, starting with size 1
    for ($i = 1; $i < $ngram; $i++)
    {
        createCombination(0, $i);
    }
}

# function to read in the user requested frequency combinations
sub readFreqCombo
{
    my $sourceFile = shift;

    # open the source file
    open (FREQ_SRC, $sourceFile) || die ("Couldnt open $sourceFile\n");

    # read in the freq combo's one by one into the @freqComb array
    $combIndex = 0;
    while (<FREQ_SRC>)
    {
        s/^\s*//;
        s/\s*$//;
        my @tempArray = split(/\s+/);

        # first how many words make up this combination
        $freqComb[$combIndex][0] = $#tempArray+1;

        # next the indices of the words. note that these indices
        # shouldnt exceed $ngram-1... we'll check for that here.
        my $i;
        for ($i = 1; $i <= $freqComb[$combIndex][0]; $i++)
        {
            $freqComb[$combIndex][$i] = $tempArray[$i-1];

            # check!
            if ($freqComb[$combIndex][$i] >= $ngram)
            {
                printf STDERR ("Illegal index value at row %d column %d in file %s\n", $combIndex+1, $i, $sourceFile);
                exit;
            }
        }
        $combIndex++;
    }
}

sub createCombination
{
    my $level = shift;
    my $size = shift;

    if ($level == $size)
    {
        $freqComb[$combIndex][0] = $size;

        my $i;
        for ($i = 1; $i <= $size; $i++)
        {
            $freqComb[$combIndex][$i] = $tempCombArray[$i-1];
        }
        $combIndex++;
    }
    else
    {
        my $i;
        my $loopStart = (!$level)?0:$tempCombArray[$level-1]+1;

        for ($i = $loopStart; $i < $ngram; $i++)
        {
            $tempCombArray[$level] = $i;
            createCombination($level+1, $size);
        }
    }
}

# function to output a minimal usage note when the user has not provided any
# commandline options
sub minimalUsageNotes
{
    print STDERR "Usage: count.pl [OPTIONS] DESTINATION SOURCE [[, SOURCE] ...]\n";
    askHelp();
}

# function to output help messages for this program
sub showHelp
{
    print "Usage: count.pl [OPTIONS] DESTINATION SOURCE [[, SOURCE] ...]\n\n";
	  
    print "Counts up the frequency of all n-grams occurring in SOURCE.\n";
    print "Sends to DESTINATION the list of n-grams found, along with the\n";
    print "frequencies of combinations of the n tokens that the n-gram is\n";
    print "composed of. If SOURCE is a directory, all text files in it are\n";
    print "counted.\n\n";
	  
    print "OPTIONS:\n\n";
	  
    print "  --ngram N          Creates n-grams of N tokens each. N = 2 by\n";
    print "                     default.\n\n";
	  
    print "  --window N         Sets window size to N. Defaults to n-gram\n";
    print "                     size above.\n\n";
	  
    print "  --token FILE       Uses regular expressions in FILE to create\n";
    print "                     tokens. By default two regular expressions\n";
    print "                     are provided (see README).\n\n";
	  
    print "  --nontoken FILE    Removes all characters sequences that match\n";
    print "                     Perl regular expressions specified in FILE.\n\n";
 
    print "  --set_freq_combo FILE \n";
    print "                     Uses the frequency combinations in FILE to\n";
    print "                     decide which combinations of tokens to\n";
    print "                     count in a given n-gram. By default, all\n";
    print "                     combinations are counted.\n\n";
	  
    print "  --get_freq_combo FILE \n";
    print "                     Prints out the frequency combinations used\n";
    print "                     to FILE. If frequency combinations have been\n";
    print "                     provided through --set_freq_combo switch above\n";
    print "                     these are output; otherwise the default\n";
    print "                     combinations being used are output.\n\n";
	  
    print "  --stop FILE        Removes n-grams containing at least one (in\n"; 
    print "                     OR mode) or all stop words (in AND mode).\n"; 
    print "                     Stop words should be declared as Perl Regular\n"; 
    print "                     expressions in FILE.\n\n"; 
	  
    print "  --frequency N      Does not display n-grams that occur less\n";
    print "                     than N times.\n\n";
	  
    print "  --ufrequency N     Does not display n-grams that occur more\n";
    print "                     than N times. Default value is 100,000,000\n\n";
	  
    print "  --remove N         Ignores n-grams that occur less than N\n";
    print "                     times. Ignored n-grams are not counted and\n";
    print "                     so do not affect counts and frequencies.\n\n";
	  
    print "  --uremove N        Ignores n-grams that occur more than N\n";
    print "                     times. Ignored n-grams are not counted and\n";
    print "                     so do not affect counts and frequencies.\n";
    print "                     Default value is 100,000,000.\n\n";
	  
    print "  --newLine          Prevents n-grams from spanning across the\n";
    print "                     new-line character.\n\n";
	  
    print "  --tokenlist        Prints out all n-grams to the output file.\n\n";
	  
    print "  --histogram FILE   Outputs histogram to FILE. Tabulates how\n";
    print "                     many times n-grams of a given frequency\n";
    print "                     have occurred.\n\n";
	  
    print "  --recurse          If SOURCE is a directory, uses all files\n";
    print "                     in SOURCE as well as all subdirectories of\n";
    print "                     SOURCE recursively as input.\n\n";
	  
    print "  --extended         Outputs values of the above switches, if\n";
    print "                     default values are not used.\n\n";
	  
    print "  --verbose          Outputs to stderr information about\n";
    print "                     current program status.\n\n";
	  
    print "  --version          Prints the version number.\n\n";
	  
    print "  --help             Prints this help message.\n\n";
}


# function to output the version number
sub showVersion
{
    print STDERR "count.pl      -        version 0.58\n";
    print STDERR "Copyright (C) 2000-2010, Ted Pedersen & Satanjeev Banerjee & Ying Liu\n";
    print STDERR "Date of Last Update 01/29/10\n";

}

# function to output "ask for help" message when the user's goofed up!
sub askHelp
{
    print STDERR "Type count.pl --help for help.\n";
}

sub showFreqCombArray
{
    my ($i, $j);

    for ($i = 0; $i < $combIndex; $i++)
    {
        print STDERR "$freqComb[$i][0]: ";
        for ($j = 1; $j <= $freqComb[$i][0]; $j++)
        {
            print STDERR "$freqComb[$i][$j] ";
        }
        print STDERR "\n";
    }
}

