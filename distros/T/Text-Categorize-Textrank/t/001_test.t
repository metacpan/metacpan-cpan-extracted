# -*- perl -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'Text::Categorize::Textrank' ); }
use Text::Categorize::Textrank qw(getTextrankOfListOfTokens);

ok (singletonTest(), 'Test number 1.');
ok (randomTests(), 'Test number 2.');
ok (staticTest(), 'Test number 3.');
done_testing ();

sub singletonTest
{
  my $ranks = getTextrankOfListOfTokens (listOfTokens => [[1]]);
  return 0 unless defined $ranks;
  return 0 unless exists $ranks->{1};
  return $ranks->{1} == 1;
}

sub randomTests
{
  for (my $size = 1; $size < 30; $size++)
  {
    my $listOfTokens = getRandomList ($size);
    my $ranks = getTextrankOfListOfTokens (listOfTokens => $listOfTokens);
    return 0 if (scalar (keys %$ranks) != $size);
  }
  return 1;
}

sub getRandomList
{
  my $maxWord = int abs $_[0];
  my $totalSentences = 1 + int rand $maxWord;
  my @listOfTokens;
  for (my $i = 0; $i < $totalSentences; $i++)
  {
    my $totalTokens = 1 + int rand $maxWord;
    my @sentence;
    for (my $j = 0; $j < $totalTokens; $j++)
    {
      push @sentence, int rand $maxWord;
    }
    push @listOfTokens, \@sentence;
    push @listOfTokens, [0..($maxWord - 1)];
  }
  return \@listOfTokens;
}

sub staticTest
{
  my $listOfTokens =
  [
    [qw(1 2 3 4 5)],
    [qw(6 7 8 9 10)],
    [qw(11 12 13 14 15)],
  ];

 my $ranks = getTextrankOfListOfTokens (listOfTokens => $listOfTokens);
 my $ranksStatic = {1=>0.0428301306760304,2=>0.0772473672767315,3=>0.0725688361622227,4=>0.0699734256535396,5=>0.0685451045916965,6=>0.0677797635812775,7=>0.0674072783452444,8=>0.0672961874265148,9=>0.0674072783452444,10=>0.0677797635812775,11=>0.0685451045916965,12=>0.0699734256535396,13=>0.0725688361622227,14=>0.0772473672767315,15=>0.0428301306760304};
 my $error = 0;
 while (my ($key, $value) = each %$ranksStatic)
 {
   my $diff = abs ($value - $ranks->{$key});
   $diff = abs ($diff/$value) if $value != 0;
   $error += $diff;
 }
 $error = $error / scalar (keys %$ranksStatic);
 return 0 if ($error > 1e-7);
 return 1;
}

