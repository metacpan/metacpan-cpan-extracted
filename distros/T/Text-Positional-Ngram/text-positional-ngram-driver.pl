#!/usr/bin/perl

=head1 NAME

text-positional-ngram-driver.pl

=head1 SYNOPSIS

text-positional-ngram-driver.pl takes as input one or more text files 
and calculates the ngram  frequency for the whole corpus.

=head1 DESCRIPTION

See README

=head1 AUTHOR

Bridget Thomson McInnes, bthomson@d.umn.edu

Ted Pedersen, tpederse@d.umn.edu

=head1 BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (C) 2004-2007, Bridget T. McInnes

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

#-----------------------------------------------------------------------------
#                              Start of program
#-----------------------------------------------------------------------------

#  Set the Text::Positional::Ngram;
use Ngram;

# we have to use commandline options, so use the necessary package!
use Getopt::Long;

#  Create the accessor
$text = Text::Positional::Ngram->new();

# first check if no commandline options have been provided... in which case
# print out the usage notes!
if ( $#ARGV == -1 )
{
    &minimalUsageNotes();
    exit;
}

# now get the options!
GetOptions( "version",   "help",    "frequency=i", "stop=s",   "stopmode=s", 
	    "newLine",   "token=s", "nontoken=s",  "ngram=i",  "remove=i", 
	    "marginals", "window=s");

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

#  check the windowing option
if ( defined $opt_window )    { $text->set_window_size($opt_window);     } 

#  check the frequency option
if ( defined $opt_frequency ) { $text->set_frequency($opt_frequency);    }
else                          { $text->set_frequency(0);                 }

#  check the remove option
if ( defined $opt_remove )    { $text->set_remove($opt_remove);          }
else                          { $text->set_remove(0);                    }
                         
#  check to see if the marginals are wanted
if ( defined $opt_marginals ) { $text->set_marginals(1);                 }

#  check to see if the token option has been defined
if ( defined $opt_token )     { $text->set_token_file($opt_token);       }

#  check to see if the nontoken option has been defined
if ( defined $opt_nontoken )  { $text->set_nontoken_file($opt_nontoken); }

#  check to see if the stop option has been defined
if ( defined $opt_stop )      { $text->create_stop_list($opt_stop);      }

#  check to see if the newline option has been defined
if ( defined $opt_newline )   { $text->set_new_line();                   }

#  check to see if the stop  mode has been defined
if ( defined $opt_stopmode ) { 

    if( lc($opt_stopmode) ne "or" && lc($opt_stopmode) ne "and" ) {
	print STDERR "Stop mode must be either: AND or OR.\n";
	askHelp();
	exit;
    }
    $text->set_stop_mode($opt_stopmode);    
}  
else { $text->set_stop_mode(OR); }

#  check the ngram option
if ( defined $opt_ngram )     { 
   
    if($opt_ngram <= 0) {
	print STDERR "Cannot have 'n' value of ngrams as less than 1\n";
	askHelp();
	exit();
    }
    
    $text->set_ngram_size($opt_ngram); 
}
else { $text->set_ngram_size(2); }

# having stripped the commandline of all the options etc, we should now be
# left only with the source/destination files

# retrieve the destination file 
$destination = shift; 

# check to see if a destination has been supplied at all...
if ( !($destination ) )
{
    print STDERR "No output file (DESTINATION) supplied.\n"; 
    askHelp();
    exit;
}   

# check to see if destination exists, and if so, if we should overwrite...
if ( -e $destination )
{
    print "Output file $destination already exists! Overwrite (Y/N)? ";
    $reply = <STDIN>;
    chomp $reply;
    $reply = uc $reply;
    exit 0 if ($reply ne "Y");
}

#  set the destination file
$text->set_destination_file($destination);

#  get the source files
@files = ();
foreach $element (@ARGV) {
    if(-d $element) {
	my @temp = (); 
	opendir(THISDIR, $element) || die "Can not open the $dirpath";
	push(@temp, grep {$_ ne '.' and $_ ne '..' } readdir THISDIR); 
	closedir THISDIR;
	foreach (@temp) { push @files, $element . $_; }
    }
    else { push @files, $element; }
}

#  create the files necessary to run the module
$text->create_files(@files);

#  get the ngrams
$text->get_ngrams();

#  remove the miscellaneous file created by the Text::Positional::Ngram module
$text->remove_files();

# function to output "ask for help" message when the user's goofed up!
sub askHelp
{
    print STDERR "Type text-positional-ngram-driver.pl --help for help.\n";
}

# function to output the version number
sub showVersion
{
    print STDERR "text-positional-ngram-driver.pl -   version 0.5\n";
    print STDERR "Copyright (C) 2004-2007, Bridget Thomson McInnes\n";
    print STDERR "Date of Last Update 28/08/07\n";

}

# function to output a minimal usage note when the user has not provided any
# commandline options
sub minimalUsageNotes
{
    print STDERR "Usage: text-positional-nram-driver.pl [OPTIONS] DESTINATION SOURCE [[, SOURCE] ...]\n";
    askHelp();
}

# function to output help messages for this program
sub showHelp
{
    print "Usage: text-positional-ngram-driver.pl [OPTIONS] DESTINATION SOURCE [[, SOURCE] ...]\n\n";
	  
    print "Counts up the frequency of all n-grams occurring in SOURCE.\n";
    print "Sends to DESTINATION the list of n-grams found and their frequencies.\n";
	  
    print "OPTIONS:\n\n";
	  
    print "  --ngram N          Creates n-grams of N tokens each. N = 2 by\n";
    print "                     default.\n\n";
	  
    print "  --token FILE       Uses regular expressions in FILE to create\n";
    print "                     tokens. By default two regular expressions\n";
    print "                     are provided (see README).\n\n";
	  
    print "  --nontoken FILE    Removes all characters sequences that match\n";
    print "                     Perl regular expressions specified in FILE.\n\n";
	  
    print "  --stop FILE        Removes n-grams containing at least one (in\n"; 
    print "                     OR mode) or all stop words (in AND mode).\n"; 
    print "                     Stop words should be declared as Perl Regular\n"; 
    print "                     expressions in FILE.\n\n"; 

    print "  --stop_mode MODE   Sets the stop mode to OR or AND. OR mode removes\n";
    print "                     n-grams containing at least one stop word. AND \n";
    print "                     mode removes n-grams that contain all stop words.\n\n";
	  
    print "  --frequency N      Does not display n-grams that occur less\n";
    print "                     than N times.\n\n";
	  
    print "  --remove N         Ignores n-grams that occur less than N\n";
    print "                     times. Ignored n-grams are not counted and\n";
    print "                     so do not affect counts and frequencies.\n\n";
	  
    print "  --newLine          Prevents n-grams from spanning across the\n";
    print "                     new-line character.\n\n";
	  
    print "  --marginals        Prints the marginal counts of the\n";
    print "                     individual words in the n-gram\n\n";

    print "  --window N         Sets the size of the window in which\n";
    print "                     the positional ngram can be found in.\n\n";

    print "  --version          Prints the version number.\n\n";
	  
    print "  --help             Prints this help message.\n\n";
}
