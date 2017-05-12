# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Carp;
use strict;
use warnings;

use Test::More tests => 5;

my $totalTests = 10;
BEGIN { use_ok( 'Text::Ngramize' ); }
my $object = Text::Ngramize->new ();
isa_ok ($object, 'Text::Ngramize');
ok (testNgramsHashesComputedOverRange ($totalTests), 'Ngram hash computing.');
ok (testFindingOfWords($totalTests), 'Word finding.' );
ok (testNgramsComputedOverRange ($totalTests), 'Ngram computing.');


# type of tests to perform.
# create a string with the position of words knows and see that they are found
# and the n-grams are computed correctly.
# compute hash values and strings and ensure equal strings and equal hashes.
# add the same string to the beginning and end of text and compare the first and
# last hash values computed.

sub testNgramsHashesComputedOverRange
{
  my ($TotalTests) = @_;
  $TotalTests = 50 unless defined $TotalTests;
  my $typeOfNgrams;
  foreach my $typeOfNgrams ('asc', 'characters', 'words')
  {
    for (my $sizeOfNgrams = 1; $sizeOfNgrams < 64; $sizeOfNgrams += $sizeOfNgrams)
    {
      print 'testing ' . $typeOfNgrams . ' ngram hashes of size ' . $sizeOfNgrams . ' ';
      for (my $i = 0; $i < $TotalTests; $i++)
      {
        return 0 unless testNgramHashesComputedOnce ($sizeOfNgrams, $typeOfNgrams);
        print '.';
      }
      print "\n";
    }
  }
  return 1;
}

sub testNgramHashesComputedOnce
{
  my ($SizeOfNgrams, $TypeOfNgrams) = @_;
  $SizeOfNgrams = 1 unless defined $SizeOfNgrams;
  $TypeOfNgrams = 'characters' unless defined $TypeOfNgrams;

  # build the string to test on.

  # get a random word.
  my $ascOnly = ($TypeOfNgrams =~ m/^a/i);
  my $word = getRandomWord (2 * $SizeOfNgrams, $ascOnly);
  if (length ($word) < $SizeOfNgrams)
  {
    $word .= 'a' x ($SizeOfNgrams - length ($word));
  }
  $word = substr ($word, 0, $SizeOfNgrams);

  # get some random text.
  my ($text, undef) = getRandomText ();

  # prefix and suffix the word to the text. by doing this we ensure
  # the first and last ngram hash values generated should be the same,
  # for characters or bytes.
  my $prefix = $word . ' ';
  $prefix = $prefix x $SizeOfNgrams;
  my $suffix = ' ' . $word;
  $suffix = $suffix x $SizeOfNgrams;
  $text = $prefix . $text . $suffix;
  my $ngramizer = Text::Ngramize->new (sizeOfNgrams => $SizeOfNgrams, typeOfNgrams => $TypeOfNgrams);
  my $listOfNgramHashValuesWithPositions = $ngramizer->getListOfNgramHashValuesWithPositions (text => $text);
  my $listOfNgramHashValues = $ngramizer->getListOfNgramHashValues (text => $text);
  return 0 if (@$listOfNgramHashValuesWithPositions != @$listOfNgramHashValues);

  # first and last values should be same given how text was constructed.
  return 0 if ($listOfNgramHashValues->[-1] != $listOfNgramHashValues->[0]);

  # hash values of both methods should be equal.
  for (my $i = 0; $i < @$listOfNgramHashValuesWithPositions; $i++)
  {
    return 0 if ($listOfNgramHashValuesWithPositions->[$i][0] != $listOfNgramHashValues->[$i]);
  }

  return 1;
}

# tests the methods getListOfNgramsWithPositions and getListOfNgrams over
# a range of ngram sizes for 'asc' and 'character' ngrams.
sub testNgramsComputedOverRange
{
  my ($TotalTests) = @_;
  $TotalTests = 50 unless defined $TotalTests;
  my $typeOfNgrams;
  foreach my $typeOfNgrams ('asc', 'characters')
  {
    for (my $sizeOfNgrams = 1; $sizeOfNgrams < 64; $sizeOfNgrams += $sizeOfNgrams)
    {
      print 'testing ' . $typeOfNgrams . ' ngrams of size ' . $sizeOfNgrams . ' ';
      for (my $i = 0; $i < $TotalTests; $i++)
      {
        return 0 unless testNgramsComputedOnce ($sizeOfNgrams, $typeOfNgrams);
        print '.';
      }
      print "\n";
    }
  }
  return 1;
}

# tests the methods getListOfNgramsWithPositions and getListOfNgrams once on
# randomly generated text and ngrams specified size.
sub testNgramsComputedOnce
{
  my ($SizeOfNgrams, $TypeOfNgrams) = @_;
  $SizeOfNgrams = 1 unless defined $SizeOfNgrams;
  $TypeOfNgrams = 'characters' unless defined $TypeOfNgrams;

  my ($text, undef) = getRandomText ();
  my $ngramizer = Text::Ngramize->new (sizeOfNgrams => $SizeOfNgrams, typeOfNgrams => $TypeOfNgrams);
  my $listOfNgramsWithPositions = $ngramizer->getListOfNgramsWithPositions (text => $text);
  my $listOfNgrams = $ngramizer->getListOfNgrams (text => $text);
  return 0 if (@$listOfNgramsWithPositions != @$listOfNgrams);

  if ($TypeOfNgrams =~ /^c/i)
  {
    for (my $i = 0; $i < @$listOfNgramsWithPositions; $i++)
    {
      return 0 if ($listOfNgramsWithPositions->[$i][0] ne $listOfNgrams->[$i]);
      return 0 if (substr ($text, $listOfNgramsWithPositions->[$i][1], $listOfNgramsWithPositions->[$i][2]) ne $listOfNgrams->[$i]);
    }
  }
  elsif ($TypeOfNgrams =~ /^a/i)
  {
    use bytes;
    for (my $i = 0; $i < @$listOfNgramsWithPositions; $i++)
    {
      return 0 if ($listOfNgramsWithPositions->[$i][0] ne $listOfNgrams->[$i]);
      return 0 if (substr ($text, $listOfNgramsWithPositions->[$i][1], $listOfNgramsWithPositions->[$i][2]) ne $listOfNgrams->[$i]);
    }
  }
  return 1;
}

# tests the methods getListOfNgramsWithPositions and getListOfNgrams multiple
# times on different randomly generated text and ngrams of size 1.
sub testFindingOfWords
{
  my ($TotalTests) = @_;
  $TotalTests = 50 unless defined $TotalTests;

  print 'testing word finding';
  for (my $i = 0; $i < $TotalTests; $i++)
  {
    return 0 unless testFindingOfWordsOnce ();
    print '.';
  }
  print "\n";
  return 1;
}

# tests the methods getListOfNgramsWithPositions and getListOfNgrams once on
# randomly generated text and ngrams of size 1.
sub testFindingOfWordsOnce
{
  my ($text, $wordInfo) = getRandomText ();
  my $ngramizer = Text::Ngramize->new (typeOfNgrams => 'words', sizeOfNgrams => 1);
  my $listOfWordsWithPositions = $ngramizer->getListOfNgramsWithPositions (text => $text);
  my $listOfWords = $ngramizer->getListOfNgrams (text => $text);
  return 0 if (@$listOfWordsWithPositions != @$wordInfo);
  return 0 if (@$listOfWords != @$wordInfo);

  for (my $i = 0; $i < @$listOfWordsWithPositions; $i++)
  {
    return 0 if ($listOfWords->[$i] ne $wordInfo->[$i][0]);
    return 0 if ($listOfWordsWithPositions->[$i][0] ne $wordInfo->[$i][0]);
    return 0 if ($listOfWordsWithPositions->[$i][1] != $wordInfo->[$i][1]);
    return 0 if ($listOfWordsWithPositions->[$i][2] != $wordInfo->[$i][2]);
  }
  return 1;
}

# generates a random word with at least one character.
sub getRandomWord # ($MaxCharactersInWord, $Type)
{
  my $MaxCharactersInWord = shift;
  my $AscOnly = shift;
  $AscOnly = 0 unless defined $AscOnly;

  $MaxCharactersInWord = 10 unless defined $MaxCharactersInWord;
  $MaxCharactersInWord = int abs $MaxCharactersInWord;
  my $charsInWord = 1 + int rand $MaxCharactersInWord;
  $charsInWord = 1 if ($charsInWord < 1);
  my @characters;
  for (my $i = 0; $i < 2 * $charsInWord; $i++)
  {
    my $ord;
    if ($AscOnly) { $ord = ord ('a') + int rand (ord('z') - ord ('a') + 1); }
    else { $ord = int rand (0xffff); }
    my $chr;
    my $doNext = 0;
    eval
    {
      no warnings;
      $chr = chr $ord;
      $doNext = 1 if ($chr =~ /^\P{IsAlphabetic}$/);
    };
    next if ($doNext || $@);
    next unless length ($chr);
    push @characters, $chr;
    last if (@characters >= $charsInWord);
  }
  push @characters, 'a' if (@characters == 0);
  return join ('', @characters);
}

# generates a random sentence of words ending with a period.
sub getRandomSentence # ($MaxWordsInSentence, $StartingPosition)
{
  my $MaxWordsInSentence = shift;
  $MaxWordsInSentence = 10 unless defined $MaxWordsInSentence;
  $MaxWordsInSentence = int abs $MaxWordsInSentence;
  $MaxWordsInSentence = 1 if ($MaxWordsInSentence < 1);

  my $StartingPosition = shift;
  $StartingPosition = 0 unless defined $StartingPosition;

  my @punctuation;
  foreach my $item (',', '#', '*', '_', '-', '+', '=', ';'. ':')
  {
    push @punctuation, $item if ($item =~ /^\P{IsAlphabetic}$/);
  }

  my @words;
  my @allWordInfo;
  my $wordPosition = $StartingPosition;
  for (my $i = 0; $i < $MaxWordsInSentence; $i++)
  {
    # add word with at least one letter.
    my $word = getRandomWord;
    my $wordSize = length ($word);
    next if ($wordSize < 1);
    push @words, $word;

    # store and update the position info of the word.
    push @allWordInfo, [$word, $wordPosition, $wordSize];
    $wordPosition += $wordSize;

    # if done, exit the loop.
    last unless ($i < $MaxWordsInSentence);

    # add a space 90% of the time.
    if (rand() < .9)
    {
      my $space = ' ';

      # sometimes add extra space.
      if (rand() < .1)
      {
        my $size = 2 + int rand (4);
        $space = ' ' x $size;
      }
      push @words, $space;
      $wordPosition += length ($space);
    }
    else
    {
      my $punc = $punctuation[rand(scalar(@punctuation))];
      push @words, $punc;
      $wordPosition += length ($punc);
    }
  }

  # compute the position and length of the words.
  my $sentence = join ('', @words) . '.';

  # sanity check, i really hope this never croaks.
  my $offset = $allWordInfo[0]->[1];
  foreach my $wordInfo (@allWordInfo)
  {
    if (substr ($sentence, $wordInfo->[1]-$offset, $wordInfo->[2]) ne $wordInfo->[0])
    {
      croak "progamming error: substr '" . $wordInfo->[0] . "' not equal to '" . substr ($sentence, $wordInfo->[1]-$offset, $wordInfo->[2]) . "'.\n";
    }
  }

  return ($sentence, \@allWordInfo);
}


sub getRandomText
{
  # get the total number of sentences to generate.
  my $TotalSentences = shift;
  $TotalSentences = 50 unless defined $TotalSentences;
  $TotalSentences = abs $TotalSentences;
  $TotalSentences = 1 if ($TotalSentences < 1);

  my @allSentences;
  my @allWordInfo;
  my $offset = 0;
  for (my $i = 0; $i < $TotalSentences; $i++)
  {
    my ($sentence, $wordInfo) = getRandomSentence (15, $offset);
    $offset += length ($sentence);
    push @allSentences, $sentence;
    push @allWordInfo, @$wordInfo;
  }

  # concat all the sentences.
  my $text = join ('', @allSentences);

  # sanity check, i really hope this also never croaks.
  foreach my $wordInfo (@allWordInfo)
  {
    if (substr ($text, $wordInfo->[1], $wordInfo->[2]) ne $wordInfo->[0])
    {
      croak "progamming error: substr '" . $wordInfo->[0] . "' not equal to '" . substr ($text, $wordInfo->[1], $wordInfo->[2]) . "'.\n";
    }
  }

  return ($text, \@allWordInfo);
}
