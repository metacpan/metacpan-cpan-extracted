#!/usr/bin/perl 

=pod

=head1 NAME

umls-senserelate-evaluation.pl - This program evaluates the 
umls-senserelate algorithm using the semeval scorer program 

=head1 SYNOPSIS

This program evaluates the senses assigned by the UMLS-SenseRelate
algorithm using the semeval scorer program 

=head1 USAGE

Usage: umls-senserelate-evaluation.pl LOG_DIRECTORY

=head2 OUTPUT

=head2 Required Options

=head3 LOG_DIRECTORY

This is the directory outputted by the umls-targetword-senserelate.pl program 
which contains the key and answer files for each of the target 
words. 

=head2 General Options:

=head3 --info FILE

Prints out accuracy information to FILE

=head3 --senses DIR|File

Sometimes of the senses in the key file do not map directly to 
the senses in the answer file. This will happen when using the 
NLM-WSD dataset which uses tags to indicate the sense of the 
ambiguous word and then those tags are mapped to concepts in 
the UMLS. The key file would contain the CUIs while the answer 
file contains the tags. Therefore, we need the sense (sometimes 
called choice) files to evaluate the mappings. 

So this options takes the directory that contains the the sense file 
for each target word you are going to disambiguate or just the file 
itself. 

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
tagset and the 2007 tagset available. You can find them here:

  http://wsd.nlm.nih.gov/collaboration.shtml

=head3 --verbose

Prints out accuracy information to STDOUT. 

=head3 --version

Displays the version information.

=head3 --help

Displays the help information

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

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

Copyright (c) 2010-2012,

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

eval(GetOptions( "version", "verbose", "info=s", "help", "senses=s", "debug")) or die ("Please check the above mentioned option(s).\n");


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

#  turn on debug if defined
if( defined $opt_debug ) { 
    $debug = 1;
}

# At least 1 terms should be given on the command line.
if(scalar(@ARGV) < 1) {
    print STDERR "The umls-targetword-senserelate log directory must be given on the command line.\n";
    &minimalUsageNotes();
    exit;
}

local(*INFO);
if(defined $opt_info) { 
    open(INFO, ">$opt_info") || die "Could not open --info FILE ($opt_info)\n";
}

my $log = shift;

my %answerhash = ();
my %keyhash = ();

&getInputFiles($log);
&setSenses();
&evaluateUsingScorer();

#  evaluates the files in the log directory using the scorer program
sub evaluateUsingScorer {

    if($debug) { print STDERR "In evaluateUsingScorer\n"; }    

    my $total_precision = 0; my $total_tw = 0;
    foreach my $tw (sort keys %answerhash) { 
	
	if($tw eq "sd") { next; }
	if($tw eq "or") { next; }

	my $answerfile = $answerhash{$tw};
	my $keyfile    = $keyhash{$tw};
	
	#  check that the key file exists
	if(! (defined $keyfile)) { 
	    print STDERR "ERROR: The key does not exist for $tw.\n";
	    &minimalUsageNotes();
	    exit;
	}
	
	my $evaluationfile = "$log/$tw.evaluation";

	system "score.pl $log/$answerfile $log/$keyfile > $evaluationfile";

	open(EVAL, $evaluationfile) || die "Could not open $evaluationfile\n";
	my $precision = "";
	while(<EVAL>) { 
	    if($_=~/precision\:\s+([0-9\.]+) \(/) {
		$precision = $1;
	    }
	} close EVAL;
	
	if(defined $opt_verbose) { 
	    print STDERR "$tw\t$precision\n";
	}

	if(defined $opt_info) { 
	    print INFO "$tw\t$precision\n";
	}

	$total_precision += $precision; $total_tw++;
    }
    my $overall = $total_precision / $total_tw;
    print STDERR "Evaluation files are located in the input ($log) directory\n";
    print STDERR "The Overall Precision for this dataset is: $overall\n";
}
	    
#  gets the answer and key files from the log directory
sub getInputFiles {
    
    if($debug) { print STDERR "In getInputFiles\n"; }

    my $dir = shift;

    #  open the log directory
    opendir(DIR, $dir) || die "Could not open the log ($dir) directory\n";
    my @files= grep { $_ ne '.' and $_ ne '..' } readdir DIR;

    #  get each of the answer and key files in the directory
    foreach my $file (@files) { 

	if($file=~/(.*?).answers/) { 
	    $answerhash{$1} = $file;
	}
	if($file=~/(.*?).key/) { 
	    $keyhash{$1} = $file;
	}
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
	open(FILE, $files{$tw}) || die "Could not open --sense $file\n";
	my %sensehsah = ();
	while(<FILE>) {
	    chomp;
	    my($tag, $concept, $semantics, $cui) = split/\|/;
	    $sensehash{$tag} = $cui; 
	}close FILE;

	my $keyfile    = $keyhash{$tw};	
	my $nkeyfile   = $keyfile . ".sense";
	open(KEY, "$log/$keyfile") || die "Could not open key $log/$keyfile\n";
	open(NKEY, ">$log/$nkeyfile") || die "Could not open key $log/$nkeyfile\n";
	while(<KEY>) { 
	    chomp;
	    $_=~/(M[0-9]+)$/; 
	    my $tag = $1;
	    my $cui = $sensehash{$tag};
	    $_=~s/\%$tag/\%$cui/g;
	    print NKEY "$_\n";
	} close KEY; close NKEY;
	$keyhash{$tw} = $nkeyfile;
    }
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: umls-senserelate-evaluation.pl [OPTIONS] LOG_DIRECTORY\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility \n";
  
    print "Usage: umls-senserelate-evaluation.pl [OPTIONS] LOG_DIRECTORY\n\n";
    
    print "\n\nGeneral Options:\n\n";

    print "--senses FILE|DIR        File or directory containing the sense files\n\n";
    
    print "--verbose                Prints accuracy information to STDOUT\n\n";

    print "--info FILE              Prints accuracy information to FILE\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-senserelate-evaluation.pl,v 1.6 2013/05/23 17:48:13 btmcinnes Exp $';
    print "\nCopyright (c) 2010-2012, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-senserelate-evaluation.pl --help for help.\n";
}
    
