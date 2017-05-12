#!/usr/bin/env perl

use strict;
use warnings;

# contains all the examples in the POD documentation for the module.

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new ();
  dump $ngramizer->getTypeOfNgrams;
  # dumps:
  # "characters"
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new ();
  dump $ngramizer->getSizeOfNgrams;
  # dumps:
  # 3
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (normalizeText => 1);
  my $text = ' To be.';
  dump $ngramizer->getListOfNgrams (text => \$text);
  # dumps:
  # ["to ", "o b", " be", "be "]
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1);
  my $text = "This isn't a sentence.";
  dump $ngramizer->getListOfNgrams (text => \$text);
  # dumps:
  # ["this isn t", "isn t a", "t a sentence"]
  dump $ngramizer->getListOfNgrams (listOfTokens => [qw(aa bb cc dd)]);
  # dumps:
  # ["aa bb cc", "bb cc dd"]
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1);
  my $text = " This  isn't a  sentence.";
  dump $ngramizer->getListOfNgramsWithPositions (text => \$text);
  # dumps:
  # [
  #   ["this isn t", 1, 11],
  #   ["isn t a", 7, 7],
  #   ["t a sentence", 11, 13],
  # ]
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1);
  my $text = "This isn't a sentence.";
  dump $ngramizer->getListOfNgramHashValues (text => \$text);
  # NOTE: hash values may vary across computers.
  # dumps:
  # [
  #   "4038955636454686726",
  #   "5576083060948369410",
  #   "6093054335710494749",
  # ]  dump $ngramizer->getListOfNgramHashValues (listOfTokens => [qw(aa bb cc dd)]);
  # dumps:
  # ["7326140501871656967", "5557417594488258562"]
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1);
  my $text = " This  isn't a  sentence.";
  dump $ngramizer->getListOfNgramHashValuesWithPositions (text => \$text);
  # NOTE: hash values may vary across computers.
  # dumps:
  # [
  #   ["4038955636454686726", 1, 11],
  #   ["5576083060948369410", 7, 7],
  #   ["6093054335710494749", 11, 13],
  # ]
}

{
  use Text::Ngramize;
  use Data::Dump qw(dump);
  use Encode;
  no warnings;
  my $totalNgrams = 0;
  my $ngramizer = Text::Ngramize->new ();
  my $iterations = 100;
  my $text = join ('', map {chr (int rand (0xffff))} (1..10000));
  #$text = encode ('utf8', $text, Encode::FB_QUIET);
  my $startTime = time;
  for (my $i = 0; $i < $iterations; $i++)
  {
    my $listOgNgrams = $ngramizer->getListOfNgrams (text => \$text);
    $totalNgrams += $#$listOgNgrams;
  }
  my $totalTime = time - $startTime;
  print 'getListOfNgrams: ' . $totalTime . " seconds\n";

  $startTime = time;
  for (my $i = 0; $i < $iterations; $i++)
  {
    my $listOgNgrams = $ngramizer->getListOfNgramHashValues (text => \$text);
    $totalNgrams -= $#$listOgNgrams;
  }
  $totalTime = time - $startTime;
  print 'getListOfNgramHashValues: ' . $totalTime . " seconds\n";
  print 'totalNgrams = ' . $totalNgrams . " should be zero; printed so it is not optimized away.\n";
}
