package Text::Similarity::Overlaps;

use 5.006;
use strict;
use warnings;

use Text::Similarity;
use Text::OverlapFinder;

our @ISA = qw(Text::Similarity);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Similarity::Overlaps ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.05';

# information about granularity is not used now
# the would be that you could figure out similarity
# unit by unit, that is sentence by sentence, 
# paragraph by paragraph, etc. however, at this 
# point similarity is only computed document by
# document

use constant WORD      => 0;
use constant SENTENCE  => 1;
use constant PARAGRAPH => 2;
use constant DOCUMENT  => 3;

my %finder;

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new (@_);
    if ($self->stoplist) {
	$finder{$self} = Text::OverlapFinder->new(stoplist => $self->stoplist);
    }
    else {
	$finder{$self} = Text::OverlapFinder->new;
    }

    #string_compare_initialize (0, undef);
    return $self;
}


sub finder : lvalue
{
    my $self = shift;
    $finder{$self};
} 

sub DESTROY
{
    my $self = shift;
    delete $finder{$self};
}

# this method requires that the input be provided in files. 
# this is now just a front end to getSimilarityStrings that 
# does file handling. Actual similarity measurements are
# performed between strings in getSimilarityStrings.

# this seems like it might want to move up into Similarity.pm

sub getSimilarity
{
    my $self = shift;

    # we created a separate method for getSimilarityStrings since overloading 
    # to accept both strings and file names as input parameters to 
    # getSimilarity would have required that we treat any file name that does
    # not have a corresponding file to be treated as a string, thus making it
    # impossible to really deal with missing file errors, and probably resulting
    # in quite a bit of user annoyance as 'textt1.txt' is measured for similarity
    # with the contents of 'text2.txt'

    my $file1 = shift;
    my $file2 = shift;

    # granularity is not currently supported

    my $granularity = shift;
    $granularity = DOCUMENT unless defined $granularity;

    unless (-e $file1) {
	$self->error ("The file '$file1' does not exist");
	return undef;
    }
    unless (-e $file2) {
	$self->error ("The file '$file2' does not exist");
	return undef;
    }

    unless (open (FH1, '<', $file1)) {
	$self->error ("Cannot open $file1: $!");
	return undef;
    }
    unless (open (FH2, '<', $file2)) {
	$self->error ("Cannot open $file2: $!");
	return undef;
    }
    
    my $str1;
    my $str2;
    while (<FH1>) {
	$str1 .= $self->sanitizeString ($_);
    }
    $str1 =~ s/\s+/ /g;
    while (<FH2>) {
	$str2 .= $self->sanitizeString ($_);
    }
    $str2 =~ s/\s+/ /g;

    # find compounds, not working right now

    $str1 = $self->compoundify ($str1);
    $str2 = $self->compoundify ($str2);

    close FH1;
    close FH2;

# add this call, to expose this method to users too (in case they want to
# just measure the similarity of two strings. So we have our files converted
# into strings, and now measure their similarity.

    my ($score, %allScores) = $self -> getSimilarityStrings ($str1,$str2);

# end getSimilarity here, making sure to return similarity value from 
# get SimilarityStrings

    return wantarray ? ($score, %allScores) : $score;
}

# this method measures the similarity between two strings. If a string is empty
# or missing then we generate an error and return undefined

sub getSimilarityStrings {

    my $self = shift;

    my $input1 = shift;
    my $input2 = shift;

# check to make sure you have a string! empty file or string should be rejected

    if (!defined($input1)) {
	    $self->error ("first input string is undefined: $!");
	    return undef;
    }
    if (!defined($input2)) {
	    $self->error ("second input string is undefined: $!");
	    return undef;
    }

    # clean the strings, maybe make this optional

    my $str1 .= $self->sanitizeString ($input1);
    my $str2 .= $self->sanitizeString ($input2);

    # find compounds, not working right now

    $str1 = $self->compoundify ($str1);
    $str2 = $self->compoundify ($str2);

    # this is where we find our overlaps....
    # then we score them using both the standard overlaps measure
    # as well as based on the lesk.pm module from WordNet-Similarity

    my ($overlaps, $wc1, $wc2) = $self->finder->getOverlaps ($str1, $str2);

    my $score = 0;
    my $raw_lesk = 0;
    my %allScores = ('wc1' => $wc1, 'wc2' => $wc2);
 
    if ($self->verbose) {
	print STDERR "keys: ", scalar keys %$overlaps, "\n";
    }

    foreach my $key (sort keys %$overlaps) {

	my @words = split /\s+/, $key;

	if ($self->verbose) {
	    print STDERR "-->'$key' len(", scalar @words, ") cnt(", $overlaps->{$key}, ")\n";
	}

	    # find out how many words match, add 1 for each match 

	#$score += scalar @words * scalar @words * ${$overlaps}{$key};
	$score += scalar @words * $overlaps->{$key};
	$allScores{'raw'} = $score;
            # find the length of the key, square it, multiply with its
            # value to get the lesk score for this particular match

        my $value = ($#words + 1) * ($#words + 1) * ${$overlaps}{$key};
        $raw_lesk += $value;

    }

    # fix for divide by zero error, will short circuit when score is 0
    # provided by cernst at esoft.com
    # who reported via rt.cpan.org ticket 29902

    if ($score == 0){
	$allScores{'raw'} = 0;
	$allScores{'precision'} = 0;
	$allScores{'recall'} = 0;
	$allScores{'F'} = 0;
	$allScores{'dice'} = 0;
	$allScores{'E'} = 0;
	$allScores{'cosine'} = 0;
	$allScores{'raw_lesk'} = 0;	    
	$allScores{'lesk'} = 0;
	
	return wantarray ? ($score, %allScores) : $score;
    }

    # end of fix

    my $prec = $score / $wc2;
    my $recall = $score / $wc1;
    my $f = 2 * $prec * $recall / ($prec + $recall);
    
    my $dice = 2 * $score / ($wc1 + $wc2) ;
    my $e = 1 - $f;
    my $cos = $score / sqrt ($wc1 * $wc2);
    my $lesk = $raw_lesk/ ($wc1 * $wc2);
    
    $allScores{'precision'} = $prec;
    $allScores{'recall'} = $recall;
    $allScores{'F'} = $f;
    $allScores{'dice'} = $dice;
    $allScores{'E'} = $e;
    $allScores{'cosine'} = $cos;
    $allScores{'raw_lesk'} = $raw_lesk;	    
    $allScores{'lesk'} = $lesk;
    
    # display them, if requested
    if ($self->verbose) {
	print STDERR "wc 1: $wc1\n";
	print STDERR "wc 2: $wc2\n";
	print STDERR " Raw score: $score\n";
	print STDERR " Precision: $prec\n";
	print STDERR " Recall   : $recall\n";
	print STDERR " F-measure: $f\n";
	print STDERR " Dice     : $dice\n";
	print STDERR " E-measure: $e\n";
	print STDERR " Cosine   : $cos\n";
	print STDERR " Raw lesk : $raw_lesk\n";
	print STDERR " Lesk     : $lesk\n";
	
#
# include might be the jaccard coefficient ....
# jaccard is 2*raw_score / union of string1 and string2
#
    }
    
    if ($self->normalize) {
	$score = $f;
    }
    
    return wantarray ? ($score, %allScores) : $score;    
}

sub doStop {0}

1;

__END__

=head1 NAME

Text::Similarity::Overlaps - Score the Overlaps Found Between Two Strings Based on Literal Text Matching

=head1 SYNOPSIS

          # you can measure the similarity between two input strings : 
	  # if you don't normalize the score, you get the number of matching words
          # if you normalize, you get a score between 0 and 1 that is scaled based
	  # on the length of the strings

	  use Text::Similarity::Overlaps;
 
	  # my %options = ('normalize' => 1, 'verbose' => 1);
	  my %options = ('normalize' => 0, 'verbose' => 0);
	  my $mod = Text::Similarity::Overlaps->new (\%options);
          defined $mod or die "Construction of Text::Similarity::Overlaps failed";

          my $string1 = 'this is a test for getSimilarityStrings';
          my $string2 = 'we can test getSimilarityStrings this day';

	  my $score = $mod->getSimilarityStrings ($string1, $string2);
       	  print "There are $score overlapping words between string1 and string2\n";

	  # you may want to measure the similarity of a document
          # sentence by sentence - the below example shows you
	  # how - suppose you have two text files file1.txt and
          # file2.txt - each having the same number of sentences.
          # convert those files into multiple files, where each
          # sentence from each file is in a separate file. 

	  # if file1.txt and file3.txt each have three sentences, 
          # filex.txt will become sentx1.txt sentx2.txt sentx3.txt

	  # this just calls getSimilarity( ) for each pair of sentences

	  use Text::Similarity::Overlaps;
	  my %options = ('normalize' => 1, 'verbose' =>1, 
					'stoplist' => 'stoplist.txt');
	  my $mod = Text::Similarity::Overlaps->new (\%options);
          defined $mod or die "Construction of Text::Similarity::Overlaps failed";

	  @file1s = qw / sent11.txt sent12.txt sent13.txt /;
	  @file2s = qw / sent21.txt sent22.txt sent23.txt /;

          # assumes that both documents have same number of sentences 

	  for ($i=0; $i <= $#file1s; $i++) {
	          my $score = $mod->getSimilarity ($file1s[$i], $file2s[$i]);
        	  print "The similarity of $file1s[$i] and $file2s[$i] is : $score\n";
	  }

	  my $score = $mod->getSimilarity ('file1.txt', 'file2.txt');
       	  print "The similarity of the two files is : $score\n";

=head1 DESCRIPTION

This module computes the similarity of two text documents or strings by 
searching for  literal word token overlaps. This just means that it 
determines how many word tokens are are identical between the two 
strings. Various scores are computed based on the number of shared 
words, and the length of the strings. 

At present similarity measurements are made between entire files or  
strings, and  finer granularity is not supported. Files are treated as 
one long input string, so overlaps can be found across sentence and 
paragraph boundaries. 

Files are first converted into strings by getSimilarity(), then 
getSimilarityStrings() does the actual processing. It counts the number 
of overlaps (matching words) and finds the longest common subsequences 
(phrases) between the two strings. However, most of the measures except 
for lesk do not use the information about phrasal matches. 

Text::Similarity::Overlaps returns the F-measure, which is a normalized 
value between 0 and 1. Normalization can be turned off by specifying 
--no-normalize, in which case the raw_score is returned, which is simply 
the number of words that overlap between the two strings. 

In addition, Overlaps returns the cosine, E-measure, precision, recall, 
Dice coefficient, and Lesk scores in the allScores table.

     precision = raw_score / length_file_2
     recall = raw_score / length_file_1
     F-measure = 2 * precision * recall / (precision + recall)
     Dice = 2 * raw_score / (sum of string lengths)
     E-measure = 1 - F-measure
     Cosine = raw_score / sqrt (precision + recall)
     Lesk = sum of the squares of the length of phrasal matches  
	 (normalized by dividing by the product of the string lengths)

The raw_score is simply the number of matching words between the two
inputs, without respect to their order. Note that matches are literal 
and must be exact, so 'cat' and 'cats' do not match. This corresponds to 
the idea of the intersection between the two strings. 

None of these measures (except lesk) considers the order of the matches. 
In those cases 'jim bit the dog' and 'the dog bit jim' are considered 
exact matches and will attain the highest possible matching score, 
which would be a raw_score of 4 if not normalized and 1 if the score is 
normalized (which would result in the f-measure being returned). 

lesk is different in that it looks for phrasal matches and scores them 
more highly. The lesk measure is based on the measure of the same name 
included in L<WordNet::Similarity>. There it is used to match the 
overlapping text found in the gloss entries of the lexical database / 
dictionary WordNet in order to measure semantic relatedness. 

The lesk measure finds the length of all the overlaps and squares them. 
It then sums those scores, and if the score is normalized divides them 
by the product of the lengths of the strings. For example:

	the dog bit jim
	jim bit the dog

The raw_score is 4, since the two strings are made up of identical 
words (just in different orders). The F-measure is equal to 1, as are 
the Cosine, and the Dice Coefficient. In fact, the F-Measure and the 
Dice Coefficient are always equivalent, but both are presented since 
some users may be more familiar with one formulation versus the other. 

The raw_lesk score is 2^2 + 1 + 1 = 6, because 'the dog' is a phrasal 
match between the strings and thus contributes it's length squared to 
the raw_lesk score. The normalized lesk score is 0.375, which is 6 / 
(4 * 4), or the raw_lesk score divided by the product of the lengths of 
the two strings. Note that the normalized lesk score has a maximum value 
of 1, since if there are n words in the two strings, then their maximum 
overlap is n words, which receives a raw_lesk score of n^2, which is 
the divided by the product of the string lengths, which is again n^2.. 

There is some cleaning of text performed automatically, which includes
removal of most punctuation except embedded apostrophes and
underscores. All text is made lower case. This occurs both for file and
string input.

=head1 SEE ALSO

L<http://text-similarity.sourceforge.net>

=head1 AUTHOR

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Jason Michelizzi

Last modified by : 
$Id: Overlaps.pm,v 1.6 2015/10/08 13:22:13 tpederse Exp $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
