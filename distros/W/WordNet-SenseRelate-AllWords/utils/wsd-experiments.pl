#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Getopt::Long;

# Perl libs
#   Prefix each lib with -I
#   Separate libs with a space
#   Example:
#   my $inclib = '-I/home/me/lib -I/home/you/lib';
#   my $inclib = ' ';
#################################

# vars
my $measure;
my @infile;
my $semcordir;
my $config;
my $outfile;
my $stoplist;
my $window = 3;
my $sense1 = 0;
my $random = 0;
my $pairScore = 0;
my $contextScor =0;
my $forcepos = 0;
my $nocompoundify = 0;
my $usemono = 0;
my $backoff = 0;
my $score;
my $s1nc;
my $contextScore = 0;
my $devnull; # null device; name varies on different systems
my $tracefile = $devnull = File::Spec->devnull;
my $keyfile = $devnull;
my $bg;
my $fixed;
my $help;
my $version;

my $basename;

# ignore these signals
# my netgear router will close connections on me; this should keep the
# tests running even if the ssh connection is closed
$SIG{HUP} = 'IGNORE';
$SIG{CONT} = 'IGNORE';


my $res = GetOptions ('type=s' => \$measure,
		      'sense1' => \$sense1,
		      'random' => \$random,
		      'file=s' => \@infile,
                    'semcor=s' => \$semcordir,
		      'stoplist=s' => \$stoplist,
		      'config=s' => \$config,
		      'window=i' => \$window,
		      'forcepos' => \$forcepos,
		      'nocompoundify' => \$nocompoundify,
		      'usemono' => \$usemono,
		      'backoff' => \$backoff,
		      'score=s' => \$score,		      	
		      'pairScore=f' => \$pairScore,
		      'contextScore=f' => \$contextScore,
                    'basename=s' => \$basename,
		      'bg' => \$bg,
		       help => \$help,
		       version => \$version,
                    'fixed' => \$fixed);

unless ($res) {
    exit 1;
}

if ($help) {
    usage ("Long");
    exit;
}

if ($version) {
    print "wsd-experiments.pl - driver for running wsd experiments\n";
    print 'Last modified by : $Id: wsd-experiments.pl,v 1.17 2009/05/19 21:59:24 kvarada Exp $';
    print "\n";
    exit;
}


unless ($measure or $sense1 or $random) {
    usage ();
    exit 2;
}

if (($sense1 and $random) or ($sense1 and $fixed) or ($random and $fixed)) {
    print STDERR "Only one scheme may be specified\n";
    usage ();
    exit 3;
}

unless (scalar @infile or $semcordir) {
    print STDERR "No input semcor-formatted file specified\n";
    usage ();
    exit 4;
}

if (scalar @infile and $semcordir) {
    print STDERR "Specify only --file or --semcor, not both\n";
    usage();
    exit 5;
}

unless ($basename) {
    print STDERR "No base name for output files specified\n";
    usage();
    exit 6;
}


$tracefile = $basename . '.tr';
$outfile   = $basename . '.out';
$keyfile   = $basename . '.key';

if (-e $tracefile){
	unlink($tracefile);
}

unless (open (TFH, '>>', $tracefile)) {
    die "Cannot open tracefile '$tracefile' for writing: $!\n";
}


# temp files
my $tmp = File::Spec->tmpdir;
my $t0 = File::Spec->catdir ($tmp, "$$.0.txt");
my $t1 = File::Spec->catdir ($tmp, "$$.1.txt");
my $t2 = File::Spec->catdir ($tmp, "$$.2.txt");
my $tinput = File::Spec->catdir ($tmp, "$$.in.txt");
my $tkey = File::Spec->catdir ($tmp, "$$.key.txt");


#END {
#    unlink $t0, $t1, $t2, $tkey, $tinput;
#}


system ("which semcor-reformat.pl > $devnull");
if ($? >> 8) {
    print STDERR "Can't find perl script semcor-reformat.pl. Please check your PATH variable.\n";
    exit 1;
}

system ("which wsd.pl > $devnull");
if ($? >> 8) {
    print STDERR "Can't find perl script wsd.pl. Please check your PATH variable.\n";
    exit 1;
}

system ("which scorer2-format.pl > $devnull");
if ($? >> 8) {
    print STDERR "Can't find perl script scorer2-format.pl. Please check your PATH variable.\n";
    exit 1;
}

system ("which allwords-scorer2.pl > $devnull");
if ($? >> 8) {
    print STDERR "Can't find perl script allwords-scorer2.pl. Please check your PATH variable.\n";
    exit 1;
}

system ("which scorer2-sort.pl > $devnull");
if ($? >> 8) {
    print STDERR "Can't find perl script scorer2-sort.pl. Please check your PATH variable.\n";
    exit 1;
}

if ($bg) {
    my $pid = fork;
    if ($pid) {
	close STDOUT;
	close STDERR;
	close STDIN;
	exec "/bin/true"; # do NOT call exit
    }
}

my $files;
if (scalar @infile) {
  $files = join ' ', @infile, @ARGV;

  foreach my $file (@infile, @ARGV) {
    unless (-e $file) {
	die "Input file '$file' does not exist\n";
    }
  }
  system ("cat $files > $t0");
}
else {
  unless (-d $semcordir) {
      die "Semcor directory '$semcordir' is not a valid directory\n";
  }
}

my $starttime = time ();

if (scalar @infile) {
  unless (-e $t0) {
     die "File '$t0' does not exist (error)\n";
  }
system ("semcor-reformat.pl --file $t0 > $tinput");

  #unlink ($t0) or warn "Cannot unlink $t0\n";
}
else {
  system ("semcor-reformat.pl --semcor $semcordir > $tinput");
}

if ($? >> 8) {
    exit 2;
}

if (scalar @infile) {
  system ("semcor-reformat.pl --file $t0 --key | scorer2-sort.pl > $tkey");
  if ($? >> 8) {
    exit 2;
  }
}
else {
  system ("semcor-reformat.pl --semcor $semcordir --key | scorer2-sort.pl > $tkey");

  if ($? >> 8) {
    exit 2;
  }
}

unless (open (STDERR, '>>', $tracefile)) {
    die "Cannot open tracefile '$tracefile' for writing: $!\n";
}

my $scheme = 'normal';
$scheme = 'sense1' if $sense1;
$scheme = 'random' if $random;
$scheme = 'fixed' if $fixed;

my $options = "--format wntagged --context $tinput";
$options .= " --window $window" if defined $window;
$options .= " --pairScore $pairScore" if defined $pairScore;
$options .= " --contextScore $contextScore" if defined $contextScore;
$options .= " --config $config" if $config;
$options .= " --stoplist $stoplist" if $stoplist;
$options .= " --scheme $scheme";
$options .= " --nocompoundify" if $nocompoundify;
$options .= " --usemono" if $usemono;
$options .= " --backoff" if $backoff;
$options .= " --forcepos" if $forcepos;

$options .= " --type $measure" if $measure;

$measure = '(none)' if $sense1 or $random;
$config = '(none)' unless $config;
print STDERR "\nInput files:\n";
print STDERR "   key file      : $keyfile\n";

if (scalar @infile) {
  print STDERR "   input files   : $files\n";
}
else {
  print STDERR "   input dir     : $semcordir\n";
}
print TFH "\n";

system ("wsd.pl $options > $t1");
my $exit_code = $? >> 8;

if (-z $t1) {
    print STDERR "wsd.pl seems to have terminated incorrectly\n";
    close STDERR;
    close TFH;
    die "wsd.pl failed\n";
}

if ($exit_code) {
    print STDERR "wsd.pl has terminated incorrectly\n";
    close STDERR;
    close TFH;
    die "Failure running wsd.pl (exit code $exit_code)\n";
}

close STDERR;

system ("scorer2-format.pl --file $t1 > $t2");


#unlink $t1;

if (-z $t2) {
    die "reformatting for scoring failed\n";
}

system ("scorer2-sort.pl $t2 > $outfile");

if (-z $outfile) {
    die "sorting failed";
}

#unlink $t2;

my $scorer_out;
if(defined $score){
	$scorer_out = `allwords-scorer2.pl --ansfile $outfile --keyfile $tkey --score $score`;
}else{
	$scorer_out = `allwords-scorer2.pl --ansfile $outfile --keyfile $tkey`;
}

print $scorer_out;
print TFH $scorer_out;

# move the temp keyfile to permanent location
system ("cat $tkey > $keyfile");

unless ($? >> 8) {
    #unlink ($tkey);
}

my $elapsed = time () - $starttime;

# silly Perl doesn't have an operator to do integer division
my $hour = int ($elapsed / 3600);
$elapsed -= $hour * 3600;
my $min  = int ($elapsed / 60);
$elapsed -= $min * 60;
my $sec  = $elapsed;

my $tstr = sprintf ("Elapsed time: %02d:%02d:%02d\n", $hour, $min, $sec);
print $tstr;
print TFH $tstr;

sub usage
{
    my $long = shift;
    print "Usage: wsd-experiments.pl {--type=MEASURE | --sense1 | --random} --basename=outputfile\n";
    print "                         {--semcor DIR | --file FILE [FILE ...]}\n";
    print "                         [--config=FILE] [--window=INT] [stoplist=FILE]\n";
    print "                         [--contextScore NUM] [--pairScore NUM] [--forcepos]\n";
    print "                         [--nocompoundify][--usemono][--score poly|s1nc|n][--backoff]\n";
    print "                         | {--help | --version}\n";
    if ($long) {
	print "Options:\n";
	print "\t--type MEASURE       the relatedness measure to use\n";
	print "\t--sense1             Use sense1 disambiguation scheme\n";
	print "\t--random             Use random disambiguation scheme\n";
	print "\t--basename           The basename for the output files\n";
	print "\t--semcor             The location of the SemCor directory\n";
	print "\t--file               one or more semcor-formatted files to process\n";
	print "\t--config FILE        a configuration file for the relatedness measure\n";
	print "\t--stoplist FILE      a file of regular expressions that define\n";
	print "\t                     the words to be excluded from --context\n";
	print "\t--window INT         window of context will include INT words\n";
	print "\t                     in all, including the target word.\n";
	print "\t--contextScore NUM   the  minimum required of a winning score\n";
	print "\t                     to assign a sense to a target word\n";
	print "\t--pairScore NUM      the minimum pairwise threshold when\n";
	print "\t                     measuring target and word in window\n";
       print "\t--forcepos           force all words in window of context\n";
       print "\t--nocompoundify      disable compoundifying\n";
       print "\t--usemono            enable assigning the only available sense to monosemy words\n";
       print "\t--backoff            Use most frequent sense if can't assign sense\n";
	print "\t--score poly         score only polysemes instances\n";
	print "\t        s1nc         score only the instances where the most frequent sense is not correct\n";
	print "\t           n         score only the instances having n number of sense\n"; 
       print "\t                     to be same pos as target (pos coercion)\n";
	print "\t                     are assigned\n";
	print "\t--help               show this help message\n";
	print "\t--version            show version information\n";
    }	
}

=head1 NAME

wsd-experiments.pl - driver for running wsd experiments

=head1 SYNOPSIS

wsd-experiments.pl {--type=MEASURE | --sense1 | --random} --basename=outputfile
                  {--semcor DIR | --file FILE [FILE ...]}
                  [--config=FILE] [--window=INT] [stoplist=FILE]
                  [--contextScore NUM] [--pairScore NUM] [--forcepos][--nocompoundify][--usemono][--score][--backoff]
                  | {--help | --version}
		    

=head1 EXAMPLE

wsd-experiments.pl --type='WordNet::Similarity::lesk' --basename='test-output' --file=br-a01 --window=2

=head1 DESCRIPTION

This script is used for running wsd experiments with different parameters.
Given the similarity measure and the input file/directory, the key file is created 
by calling semcor-reformat.pl. The key file is then sorted on columns using 
scorer2-sort.pl

SemCor sense tagged files are reformatted for use by wsd.pl using semcor-reformat.pl 
Then wsd.pl is called to disambiguate the text. The disambiguated text is reformatted 
using scorer2-format.pl. The answer file is created by sorting this text on columns. 

Finally, the answer file is scored against the key file using allwords-scorer2.pl script which 
is modeled after the scorer2 C program (http://www.senseval.org/senseval3/scoring). 

Note that allwords-scorer2.pl doesn't need the key and answer files to be sorted. However, the scorer2 C program
needs the input to be sorted. So the files are sorted in case you want to use scorer2 C program to compare the
results. 

=head1 OPTIONS

N.B., the I<=> sign between the option name and the option parameter is
optional.

=over

=item --type=B<MEAURE>

The relatedness measure to be used.  The default is WordNet::Similarity::lesk.

=item --sense1

WordNet sense 1 disambiguation  guesses that the correct sense for each word is the
first sense in WordNet because the senses of words in WordNet are ranked according to 
frequency. The first sense is more likely than the second, the second is more likely  
than the third, etc. 

wsd-experiments.pl --sense1 --basename='test-output' --file=br-a01

If you are using this option, don't use --type option or --random option. 

=item --random

Random selects one of the possible senses of the target word randomly. 

wsd-experiments.pl --random --basename='test-output' --file=br-a01

If you are using this option, don't use --type option or --sense1 option. 

=item --basename=outputfile

The basename for the output files. wsd-experiments.pl creats a number of output files, 
the key file, the answer file, the result file etc. 

For example for the following command, 

wsd-experiments.pl --type='WordNet::Similarity::lesk' --basename='test-output' --file=br-a01 

since the basename is test-output, it will create test-output.key, test-output.out and test-output.tr where 
test-output.key is the key file, test-output.out is the answer file and test-output.tr is the trace file.

The final output is also displayed on standard output. 

=item --semcor=semcor-dir

The location of the SemCor directory.  This directory will contain
several sub-directories, including 'brown1' and 'brown2'.  Do
not specify these sub-directories.  Only specify the directory name
that contains them.  For example, if /home/user/semcor3.0 contains
the brown1 and brown2 directories, you would only specify
/home/user/semcor3.0 as the value of this option.  Do not use this
option at the same time as the --file option.

wsd-experiments.pl --type='WordNet::Similarity::lesk' --basename='test-output' --semcor=/home/user/semcor3.0

=item --file=B<FILE>

One or more semcor-formatted files to process.  This can be used instead of the
previous option to only specify a few Semcor files or to specify
Senseval files.  When this option is used, multiple files can be
specified on the command line.  For example

wsd-experiments.pl --type='WordNet::Similarity::lesk' --basename='test-output' --file br-a01 br-a02 br-k18 br-m02 br-r05

Do not attempt to use this option when using the previous option.

=item --config=B<FILE>

The name of a configuration file for the specified relatedness measure.

=item --stoplist=B<FILE>

A file containing regular expressions (as understood by Perl), surrounded by
by slashes (e.g. /\d+/ removes any word containing a digit [0-9]).  Any word
in the text to be disambiguated that matches one of the regular  
expressions in the file is removed.  Each regular expression must be on  
its own line, and any trailing whitespace is ignored.

Care must be taken when crafting a stoplist.  For example, it is tempting
to use /a/ to remove the word 'a', but that expression would result in
all words containing the lowercase letter a to be removed.  A better
alternative would be /\ba\b/.

=item --window=B<INTEGER>

Defines the size of the window of context.  The default is 4.  A window
size of N means that there will be a total of N words in the context
window, including the target word.  If N is a (positive) even number,
then there will be one more word on the left side of the target word
than on the right.

For example, if the window size is 4, then there will be two words on
the left side of the target word and one on the right.  If the window
is 5, then there will be two words on each side of the target word.

The minimum window size is 2.  A smaller window would mean that there
were no context words in the window.

=item --contextScore=B<REAL>

If no sense of the target word achieves this minimum score, then
no winner will be projected (e.g., it is assumed that there is
no best sense or that none of the senses are sufficiently related
to the surrounding context).  The default is zero.

=item --pairScore=B<REAL>

The minimum pairwise score between a sense of the target word and
the best sense of a context word that will be used in computing
the overall score for that sense of the target word.  Setting this
to be greater than zero (but not too large) will reduce noise.
The default is zero.

=item --forcepos

Turn part of speech coercion on.  POS coercion attempts to force other words
in the context window to be of the same part of speech as the target word.
If the text is POS tagged, the POS tags will be ignored.
POS coercion  may be useful when using a measure of semantic similarity that
only works with noun-noun and verb-verb pairs.

=item --nocompoundify

Disable compoundifying. By default compoundifying is enabled. Using this option
will disable it. 

=item --usemono

If this flag is on the only available sense is assignsed to the monosemy words. 
By default this flag is off. 

=item --backoff

Use the most frequent sense if the measure can't assign sense because no relatedness
is found with the surrounding words. This happens for path based measures and Info 
content based measures. 

=item --score

Score only specific instances. Valid options are 

--score poly score only polysemes instances
--score s1nc score only the instances where the most frequent sense is not correct
--score n    score only the instances having n number of sense 

=back


=head1 AUTHORS

 Jason Michelizz

 Varada Kolhatkar, University of Minnesota, Duluth
 kolha002 at d.umn.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

This document last modified by : 
$Id: wsd-experiments.pl,v 1.17 2009/05/19 21:59:24 kvarada Exp $

=head1 SEE ALSO

 L<semcor-reformat.pl> L<scorer2-format.pl> L<scorer2-sort.pl> 


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, Varada Kolhatkar, Ted Pedersen, Jason Michelizzi

Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.2
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover
Texts.

Note: a copy of the GNU Free Documentation License is available on
the web at L<http://www.gnu.org/copyleft/fdl.html> and is included in
this distribution as FDL.txt.

=cut
