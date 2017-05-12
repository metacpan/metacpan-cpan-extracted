#!/usr/bin/perl
# $Id: wsd.pl,v 1.37 2009/05/19 21:59:41 kvarada Exp $

use strict;
use warnings;

use WordNet::SenseRelate::AllWords;
use WordNet::QueryData;
use WordNet::Tools;
use Getopt::Long;

our $measure = 'WordNet::Similarity::lesk';
our $mconfig;
our $contextf;
our $stoplist;
our $window = 3;
our $contextScore = 0;
our $pairScore = 0;
our $glosses;
our $nocompoundify;
our $usemono;
our $backoff;
our $trace;
our $help;
our $version;
our $scheme = 'normal';
our $outfile;
our $forcepos;
our $val;
our $i=0;
our $j=0;


our $format; # raw|tagged|wntagged
my $OK_CHARS='-a-zA-Z0-9_\'\n ';

my $ok = GetOptions ('type|measure=s' => \$measure,
		     'config=s' => \$mconfig,
		     'context=s' => \$contextf,
		     'stoplist=s' => \$stoplist,
		     'window=i' => \$window,
		     'pairScore=f' => \$pairScore,
		     'contextScore=f' => \$contextScore,
		     'scheme=s' => \$scheme,
		     forcepos => \$forcepos,
		     glosses => \$glosses,
		     nocompoundify => \$nocompoundify,
		     usemono => \$usemono,
	   	     backoff => \$backoff,
		     'trace=i' => \$trace,
		     help => \$help,
		     version => \$version,
		     'outfile=s' => \$outfile,
		     'format=s' => \$format,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "wsd.pl - assign a sense to all words in a context\n";
    print 'Last modified by : $Id: wsd.pl,v 1.37 2009/05/19 21:59:41 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $contextf) {
    showUsage ();
    exit 1;
}

unless ($format
        and (($format eq 'raw') or 
	     ($format eq 'tagged') or 
	     ($format eq 'wntagged'))) {
    showUsage ();
    exit 1;
}

unless ($scheme and (($scheme eq 'normal') or ($scheme eq 'random')
		     or ($scheme eq 'sense1') or ($scheme eq 'fixed'))) {
    showUsage ();
    exit 1;
}

#my $istagged = isTagged ($contextf);
my $istagged = $format eq 'tagged' ? 1 : 0;

if ($window < 2) {
    print STDERR "Error: the window must be 2 or larger!\n\n";
    exit 1;
}

    print STDERR "Current configuration:\n";
    print STDERR "    context file  : $contextf\n";
    print STDERR "    format        : $format\n";
    print STDERR "    scheme        : $scheme\n";
    print STDERR "    tagged text   : ", ($istagged ? "yes" : "no"), "\n";

    if (($scheme eq 'normal') or ($scheme eq 'fixed')) {
	# these items are only relevent to normal mode (not sense1 or random)
	print STDERR "    measure       : $measure\n";
	print STDERR "    window        : ", $window, "\n";
	print STDERR "    contextScore  : ", $contextScore, "\n";
	print STDERR "    pairScore     : ", $pairScore, "\n";
	print STDERR "    measure config: ", ($mconfig ? $mconfig : '(none)'), "\n";
	print STDERR "    glosses       : ", ($glosses ? "yes" : "no"), "\n";
	print STDERR "    nocompoundify : ", ($nocompoundify ? "yes" : "no"), "\n";
	print STDERR "    usemono      : ", ($usemono ? "yes" : "no"), "\n";
	print STDERR "    backoff      : ", ($backoff ? "yes" : "no"), "\n";
	print STDERR "    trace         : ", ($trace ? $trace : "no"), "\n";
	print STDERR "    forcepos      : ", ($forcepos ? "yes" : "no"), "\n";
    }

    print STDERR "    stoplist      : ", ($stoplist ? $stoplist : '(none)') , "\n";

local $| = 1;
print STDERR "Loading WordNet... ";
my $qd = WordNet::QueryData->new;
print STDERR "done.\n";

#...........................................................................
#
# Compoundifying is done using compoundify method of WordNet::Tools.
# The reason there was a --compounds option is that previoulsy we did
# not have a centralized compoundify module like we do now (WordNet::Tools)
# So each program would do their own compound identification.
# We think that this is no longer a good idea and hence we removed 
# --compounds option.
# WordNet::Tools object is passed while creating AllWords object. 
# AllWords.pm calls compoundify of using WordNet::Tools object reference.
# 
#...........................................................................

my $wntools = WordNet::Tools->new($qd);
$wntools or die "\nCouldn't construct WordNet::Tools object"; 

# options for the WordNet::SenseRelate constructor
my %options = (wordnet => $qd,
		wntools => $wntools,
	       measure => $measure,
	       );
$options{config} = $mconfig if defined $mconfig;
$options{stoplist} = $stoplist if defined $stoplist;
$options{trace} = $trace if defined $trace;
$options{pairScore} = $pairScore if defined $pairScore;
$options{contextScore} = $contextScore if defined $contextScore;
$options{outfile} = $outfile if defined $outfile;
$options{forcepos} = $forcepos if defined $forcepos;
$options{nocompoundify} = $nocompoundify if defined $nocompoundify;
$options{usemono} = $usemono if defined $usemono;
$options{backoff} = $backoff if defined $backoff;
$options{wnformat} = 1 if $format eq 'wntagged';

my $sr = WordNet::SenseRelate::AllWords->new (%options);



open (FH, '<', $contextf) or die "Cannot open '$contextf': $!";

my @sentences;
if ($format eq 'raw') {
    local $/ = undef;
    my $input = <FH>;

#...........................................................................
#
# Removed splitSentences. We do not do any kind of sentence 
# splitting in wsd.pl. It is required the input to already be sentence 
# boundary processed. A small utility program utils/sentence_split.pl 
# is provided in case needed. 
# The text is cleaned in a way that is consistent with the Web interface
#
#...........................................................................
	$input =~ s/\r+//g;	
	@sentences = split(/\n+/,$input);
    undef $input;
    foreach my $sent (@sentences) {
	$sent = cleanLine ($sent);
	if ($sent !~ /[a-zA-Z0-9]/) {
		die "\nSorry. Your context should contain atleast one alphanumeric character\n";
	}
    }
}
else {
    @sentences = <FH>;
}

close FH;

foreach my $sentence (@sentences) {
    my @context = split /\s+/, $sentence;
    next unless scalar @context > 0;
    pop @context while !defined $context[$#context];
	
    my @res = $sr->disambiguate (window => $window,
				 tagged => $istagged,
				 scheme => $scheme,
				 context => [@context]);

	if($glosses)
	{
		print STDOUT join (' ', @context), "\n";
		print STDOUT join (' ', @res), "\n";
	}
	for($i=0,$j=0; $i<=$#res ; $i++,$j++)
	{
		   my $val;
  		   my $tagindex=index($res[$i],"#");
		   my $tag=substr $res[$i], $tagindex;
		   
		   if($format eq 'raw')
		   {
			 if($res[$i] =~ /\_/ && $context[$j] !~ /\_/)
			 {
				my $count = ($res[$i] =~ tr/\_//);
				$val=$res[$i];
				$j=$j+$count;
			 }else{
				$val=$context[$j].$tag;
			 }
		   }
		   elsif($format eq 'tagged')
		   {
			 my ($tw,$tt)= ( $context[$j] =~ /(\S+)\/(\S+)/);
			 $val=$tw.$tag;
		   }	
  		   elsif($format eq 'wntagged')
		   {
			 my ($tw,$tt)= split /\#/, $context[$j];
			 $val=$tw.$tag;
		   }	

		   if($glosses)
		   {
			if($val =~ /\#o/ )
			{
				print STDOUT "\n$val : stopword";
			}
			elsif($val =~ /\#ND/) 
			{
				print STDOUT "\n$val : not in WordNet\n";
			}
			elsif($val =~ /\#NR/)
			{
				print STDOUT "\n$val: No relatedness found with the surrounding words\n";
			}
			elsif($val =~ /\#IT/)
			{
				print STDOUT "\n$val: Invalid Tag\n";
			}
			elsif($val =~ /\#NT/)
			{
				print STDOUT "\n$val: No Tag\n";
			}
			elsif($val =~ /\#CL/)
			{
				print STDOUT "\n$val: Closed Class Word\n";
			}
			elsif($val =~ /\#MW/)
			{
				print STDOUT "\n$val : Missing Word\n";
			}
			else
			{
				my ($gloss) = $qd->querySense ($res[$i], "glos");
				print STDOUT "\n$val : $gloss\n";
			}
		   }
		   else
		   {
			print $val." ";
		   }	   	
		}
 	       print "\n";

		if ($trace) 
		{
			my $tstr = $sr->getTrace ();
			print $tstr, "\n";
    		}
}

sub isTagged
{
    my $file = shift;
    open FH, '<', $file or die "Cannot open context file '$file': $!";
    my @words;
    while (my $line = <FH>) {
	chomp $line;
	push @words, split (/\s+/, $line);
	last if $#words > 20;
    }
    close FH;

    my $tag_count = 0;
    foreach my $word (@words) {
	$tag_count++ if $word =~ m|/\S|;
    }
    my $ratio = $tag_count / scalar @words;

    # we consider the corpus to be tagged if we found that 70% or more
    # of the first 20 words were tagged (70% is somewhat of an arbitrary
    # value).
    return 1 if $ratio > 0.7;
    return 0;
}

sub cleanLine
{
    	my $line = shift;
	chomp($line);
	my @words=split(/ +/,$line);
	foreach my $word (@words){
		next if($word eq "i.e." || $word eq "ie." || $word eq "et_al." || $word eq "al.");
		$word =~ s/([A-Z])/\L$1/g;
		if ($word =~ m/_/){
			$word =~ s/[.|!|?|,|;]+$/ /;
		}
		else{
			$word =~ s/[^$OK_CHARS]/ /g;
		}
	}
	return join (' ', @words);
}

sub showUsage
{
    my $long = shift;
    print "Usage: wsd.pl --context FILE --format FORMAT [--scheme SCHEME]\n";
    print "              [--type MEASURE] [--config FILE] \n";
    print "              [--stoplist file] [--window INT] [--contextScore NUM]\n";
    print "              [--pairScore NUM] [--outfile FILE] [--trace INT] \n";
    print "              [--glosses][--forcepos][--nocompoundify][--usemono][--backoff] \n";
    print "              | {--help | --version}\n";

    if ($long) {
	print "Options:\n";
	print "\t--context FILE       a file containing the text to be disambiguated\n";
	print "\t--format FORMAT      type of --context ('raw', 'tagged',\n";
       print "\t                     or 'wntagged')\n";
	print "\t--scheme SCHEME      disambiguation scheme to use. ('normal', \n";
	print "\t                     'fixed', 'sense1', or 'random')\n";
	print "\t--type MEASURE       the relatedness measure to use\n";
	print "\t--config FILE        a configuration file for the relatedness measure\n";
	print "\t--stoplist FILE      a file of regular expressions that define\n";
	print "\t                     the words to be excluded from --context\n";
	print "\t--window INT         window of context will include INT words\n";
	print "\t                     in all, including the target word.\n";
	print "\t--contextScore NUM   the  minimum required of a winning score\n";
	print "\t                     to assign a sense to a target word\n";
	print "\t--pairScore NUM      the minimum pairwise threshold when\n";
	print "\t                     measuring target and word in window\n";
	print "\t--outfile FILE       create a file with one word-sense per line\n";
	print "\t--trace INT          set trace levels. greater values show more\n";
	print "\t                     detail. may be summed to combine output. \n";
	print "\t--glosses            show glosses of each disambiguated word\n";
       print "\t--forcepos           force all words in window of context\n";
       print "\t                     to be same pos as target (pos coercion)\n";
	print "\t                     are assigned\n";
       print "\t--nocompoundify      disable compoundify\n";
       print "\t--usemono            enable assigning the only available sense to monosemy words\n";
       print "\t--backoff            Use most frequent sense if can't assign sense\n";
	print "\t--help               show this help message\n";
	print "\t--version            show version information\n";
    }
}

__END__

=head1 NAME

wsd.pl - automatically assign a meaning to every word in a text

=head1 SYNOPSIS

 wsd.pl --context FILE --format FORMAT [--scheme SCHEME] [--type MEASURE] 
           [--config FILE] [--stoplist FILE] 
           [--window INT] [--contextScore NUM] [--pairScore NUM] 
           [--outfile FILE] [--trace INT] [--forcepos] [--nocompoundify] [--usemono][--backoff]
		| --help | --version

=head1 DESCRIPTION

Disambiguates each word in the context file using the specified relatedness
measure (or WordNet::Similarity::lesk if none is specified).

=head1 OPTIONS

N.B., the I<=> sign between the option name and the option parameter is
optional.

=over

=item --context=B<FILE>

The input file containing the text to be disambiguated.  This
"option" is required.

=item --format=B<FORMAT>

The format of the input file. For all formats there must be one sentence
per line, one line per sentence.  Valid values are:

=over

=item raw

The input is raw text. Compounds will be identified, punctuation is 
ignored. 

=item tagged 

The input has been part-of-speech tagged with Penn Treebank tags.
Compounds are not identified, and untagged words are ignored. 

=item wntagged

The input has been part-of-speech tagged with WordNet tags (n, v, a, r).
Compounds are not identified, and untagged words are ignored. 

=back

=item --scheme=B<SCHEME>

The disambiguation scheme to use.  Valid values are "normal", "fixed",
"sense1", and "random". The default is "normal".  In fixed mode, once a word
is assigned a sense number, other senses of that word won't be considered
when disambiguating words to the right of that context word.  For example,
if the context is

  dogs run very fast

and 'dogs' has been assigned sense number 1, only sense 1 of dogs will
be used in computing relatedness values when disambiguating 'run', 'very',
and 'fast'.

WordNet sense 1
disambiguation  guesses that the correct sense for each word is the
first sense in WordNet because the senses of words in WordNet are
ranked according to frequency.   
The first sense is more likely than the second, the second is more likely  
than the third, etc. Random selects one of the possible senses of the 
target word randomly. 

=item --type=B<MEAURE>

The relatedness measure to be used.  The default is WordNet::Similarity::lesk.

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

=item --outfile=B<FILE>

The name of a file to which output should be sent. This file will display 
one word and its sense per line.  

=item --trace=B<INT>

Turn tracing on/off.  A value of zero turns tracing off, a non-zero value
turns tracing on.  The different trace levels can be added together
to see the combined traces.  The trace levels are:

  1 Show the context window for each pass through the algorithm.

  2 Display winning score for each pass (i.e., for each target word).

  4 Display the non-zero scores for each sense of each target
    word (overrides 2).

  8 Display the non-zero values from the semantic relatedness measures.

 16 Show the zero values as well when combined with either 4 or 8.
    When not used with 4 or 8, this has no effect.

 32 Display traces from the semantic relatedness module.

=item --forcepos

Turn part of speech coercion on.  POS coercion attempts to force other words
in the context window to be of the same part of speech as the target word.
If the text is POS tagged, the POS tags will be ignored.
POS coercion  may be useful when using a measure of semantic similarity that
only works with noun-noun and verb-verb pairs.

=item --nocompoundify

Disable compoundifying. By default AllWords.pm compoundifes the input raw text. 
Using this option will disable this. 

=item --usemono

If this flag is on the only available sense is assignsed to the usemono words. 
By default this flag is off. 

=item --backoff

Use the most frequent sense if the measure can't assign sense because no relatedness
is found with the surrounding words. This happens for path based measures and Info 
content based measures. 

=back

=head1 SEE ALSO

 L<WordNet::SenseRelate::AllWords>

The main web page for SenseRelate is

 L<http://senserelate.sourceforge.net/>

There are several mailing lists for SenseRelate:

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-users/>

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-news/>

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-developers/>

=head1 AUTHORS

 Jason Michelizzi 

 Ted Pedersen, University of Minnesota, Duluth
 E<lt>tpederse at d.umn.eduE<gt>

=head1 BUGS

Please report to senserelate-users mailing list. 

=head1 COPYRIGHT

Copyright (C) 2004-2008 Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
