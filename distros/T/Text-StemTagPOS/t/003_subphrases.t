# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok('Text::StemTagPOS'); }

my $object = Text::StemTagPOS->new(listOfPOSTagsToKeep => [qw(CC CD DET EX FW IN JJ JJR JJS LS MD NN NNP NNPS NNS PDT POS PRP PRPS RB RBR RBS RP SYM TO UH VB VBD VBG VBN VBP VBZ WDT WP WPS WRB PP PPC PPD PPL PPR PPS LRB RRB)]);
isa_ok($object, 'Text::StemTagPOS');
ok (substringFindingTest (), 'Substring finding test');

# test the phrase finding routines.
sub substringFindingTest
{
  my $maxSentences = 200;
  my $maxSentenceLength = 30;
	my $totalTests = 300;
	for (my $i = 0 ; $i < $totalTests ; $i++)
	{
		my $totalSentences = getRandomInt(1, $maxSentences);
		my @sentenceLengths;
		for (my $i = 0 ; $i < $totalSentences ; $i++)
		{
			$sentenceLengths[$i] = getRandomInt(1, $maxSentenceLength);
		}
		my $sentences     = getRandomSentences(\@sentenceLengths);
		
		my ($phrasesToFind, $phrasePositions) = getPhrasesToFind($sentences);
		
		my $subphrasePositions = $object->getWordsPhrasesInTaggedText (
		  listOfStemmedTaggedSentences => $sentences,
		  listOfWordsOrPhrasesToFind => $phrasesToFind);
		  
    unless (arePositionsEqual ($phrasePositions, $subphrasePositions))
    {
      return 0;
    }
	}
	
	return 1;
}

# compare lists of phrase positions.
sub arePositionsEqual
{
  my ($OriginalPos, $ComputedPos) = @_;

  # must be the same length.
  return 0 if ($#$OriginalPos != $#$ComputedPos);

  # compare values.
  for (my $i = 0; $i < $#$OriginalPos; $i++)
  {
    my $origPair = $OriginalPos->[$i];
    my $computedPair = $ComputedPos->[$i][0];
    return 0 if ($origPair->[0] != $computedPair->[0]);
    return 0 if ($origPair->[1] != $computedPair->[1]);
  }

  return 1;
}


# returns a random integer i such that $MinValue <= i < $UpperBound.
sub getRandomInt
{
	my ($MinValue, $UpperBound) = @_;
	my $range = $UpperBound - $MinValue;
	$range = 0 if ($range < 1);
	return int(rand $range) + $MinValue;
}

# returns a list of random strings (each unique); the number of strings
# in each sentence is given by the array reference of lengths.
sub getRandomSentences
{
	my $Lengths   = shift;
	my $wordIndex = 0;
	my @listOfSentences;
	foreach my $len (@$Lengths)
	{
		my @sentence;
		for (my $i = 0 ; $i < $len ; $i++)
		{
			$sentence[$i] = [];
      $sentence[$i]->[Text::StemTagPOS::WORD_STEMMED] = 'x' . $wordIndex;
      $sentence[$i]->[Text::StemTagPOS::WORD_ORIGINAL] = 'x' . $wordIndex;
      $sentence[$i]->[Text::StemTagPOS::WORD_POSTAG] = '/FW';
      $sentence[$i]->[Text::StemTagPOS::WORD_INDEX] = $wordIndex++;
		}
		push @listOfSentences, \@sentence;
	}
	return \@listOfSentences;
}

sub getPhrasesToFind
{
  # get the list of sentences.
	my $sentences = shift;
	
	# compute the total number of words in all the sentences.
	my $totalWords = 0;
  foreach my $sentence (@$sentences) { $totalWords += $#$sentence + 1; }

  # compute the total number of phrases to extract.
  my $totalPhrases = int (2 * log($totalWords + 1)) + 1;
	
	my @allPhrases;
	my @subphrasePositions;
	while (@allPhrases < $totalPhrases)
	{
    # randomly select the sentence to extract phrases from.
	  my $sentence = $sentences->[getRandomInt (0, $#$sentences + 1)];
	
	  # get the total words in the sentence.
		my $wordsInSentence   = $#$sentence + 1;
		
		# get the starting index and length of the phrase to extract.
		my @phraseIndexList;
		my $startIndex = getRandomInt(0, $wordsInSentence);
		my $length     = getRandomInt(1, 10);
		$length = $wordsInSentence - $startIndex if ($startIndex + $length > $wordsInSentence);
		
		# copy the words.
		my @copyOfWords;
		for (my $j = $startIndex ; $j < $startIndex + $length; $j++)
		{
			push @copyOfWords, $sentence->[$j][1];
		}
		
		# store the subphrase.
		push @allPhrases, join (' ', @copyOfWords);
		push @subphrasePositions, [$sentence->[$startIndex][Text::StemTagPOS::WORD_INDEX], $sentence->[$startIndex + $length - 1][Text::StemTagPOS::WORD_INDEX]];
	}
	
	# return the list of phrases.
	return (\@allPhrases, \@subphrasePositions);
}
