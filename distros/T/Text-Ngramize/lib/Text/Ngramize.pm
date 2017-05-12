package Text::Ngramize;

require 5.008_000;
use strict;
use warnings;
use integer;
use Carp;

use constant INDEX_TOKEN => 0;
use constant INDEX_POSITION => 1;
use constant INDEX_LENGTH => 2;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.03';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME

C<Text::Ngramize> - Computes lists of n-grams from text.

=head1 SYNOPSIS

  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (normalizeText => 1);
  my $text = "This sentence has 7 words; doesn't it?";
  dump $ngramizer-> (text => \$text);

=head1 DESCRIPTION

C<Text::Ngramize> is used to compute the list of n-grams derived from the
bytes, characters, or words of the text provided. Methods
are included that provide positional information about the n-grams
computed within the text.

=head1 CONSTRUCTOR

=head2 C<new>

  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new (normalizeText => 1);
  my $text = ' To be.';
  dump $ngramizer->getListOfNgrams (text => \$text);
  # dumps:
  # ["to ", "o b", " be", "be "]

The constructor C<new> has optional parameters that set how the
n-grams are computed. C<typeOfNgrams> is used to
set the type of tokens used in the n-grams, C<normalizeText> is used to set
normalization of the text before the tokens are extracted, and C<ngramWordSeparator>
is the character used to join n-grams of words.

=over

=item C<typeOfNgrams>

 typeOfNgrams => 'characters'

C<typeOfNgrams> sets the type of tokens to extract from the text
to form the n-grams: C<'asc'>
indicates the list of ASC characters comprising the bytes of the text are to be used, C<'characters'> indicates the
list of characters are to be used, and
C<'words'> indicates the words in the text are to be used. Note a word is defined
as a substring that matches the Perl regular expression '\p{Alphabetic}+', see L<perlunicode>
for details. The default is C<'characters'>.

=item C<sizeOfNgrams>

 sizeOfNgrams => 3

C<sizeOfNgrams> holds the size of the n-grams that are to be created from the tokens extracted. Note n-grams of
size one are the tokens themselves. C<sizeOfNgrams> should be a positive integer; the default is three.

=item C<normalizeText>

 normalizeText => 0

If C<normalizeText> evalutes to true, the text is normalized before the tokens are extracted;
normalization proceeds by converting the text to lower case, replacing all non-alphabetic
characters with a space, compressing multiple spaces to a single space, and removing
any leading space but not a trailing space. The
default value of C<normalizeText> is zero, or false.

=item C<ngramWordSeparator>

  ngramWordSeparator => ' '

C<ngramWordSeparator> is the character used to separate token-C<words> when forming n-grams from them. It is
only used when C<typeOfNgrams> is set to C<'words'>; the default is a space. Note, this is used to
avoid having n-grams clash, for example, with bigrams the word pairs C<'a aaa'> and C<'aa aa'> would
produce the same n-gram C<'aaaa'> without a space separating them.

=back

=cut

sub new
{
  my ($Class, %Parameters) = @_;
  my $Self = bless ({}, ref ($Class) || $Class);

  # set the default type of tokens.
  my $typeOfNgrams = 'characters';

  # get the type of tokens to create from the text.
  $typeOfNgrams = lc $Parameters{typeOfNgrams} if exists $Parameters{typeOfNgrams};
  unless ($typeOfNgrams =~ /^(a|c|w)/)
  {
    croak "Token type '" . $Parameters{typeOfNgrams} . "' is invalid; should be 'asc', 'characters', or 'words'.\n";
  }
  my %types = qw (a asc c characters w words);
  $typeOfNgrams = $types{substr ($typeOfNgrams, 0, 1)};
  $Self->{typeOfNgrams} = $typeOfNgrams;

  # set normalizeText.
  $Self->{normalizeText} = exists ($Parameters{normalizeText}) && $Parameters{normalizeText};

  # get the size of the ngrams.
  my $sizeOfNgrams = 3;
  $sizeOfNgrams = int abs $Parameters{sizeOfNgrams} if exists $Parameters{sizeOfNgrams};
  $sizeOfNgrams = 1 if ($sizeOfNgrams < 1);
  $Self->{sizeOfNgrams} = $sizeOfNgrams;

  # get the delimiter for words
  my $ngramWordSeparator = ' ';
  $ngramWordSeparator = $Parameters{ngramWordSeparator} if exists $Parameters{ngramWordSeparator};
  $Self->{ngramWordSeparator} = $ngramWordSeparator;

  # sets values used for returning hash values of n-grams.
  $Self->setBitsInInteger;
  $Self->setByteHashValues;

  return $Self;
}

=head1 METHODS

=head2 C<getTypeOfNgrams>

Returns the type of n-grams computed as a string, either C<'asc'>,
C<'characters'>, or C<'words'>.

  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new ();
  dump $ngramizer->getTypeOfNgrams;
  # dumps:
  # "characters"

=cut

sub getTypeOfNgrams
{
  return $_[0]->{typeOfNgrams};
}

=head2 C<getSizeOfNgrams>

Returns the size of n-grams computed.

  use Text::Ngramize;
  use Data::Dump qw(dump);
  my $ngramizer = Text::Ngramize->new ();
  dump $ngramizer->getSizeOfNgrams;
  # dumps:
  # 3

=cut

sub getSizeOfNgrams
{
  return $_[0]->{sizeOfNgrams};
}

=head2 C<getListOfNgrams>

The function C<getListOfNgrams> returns an array reference to the list of n-grams computed
from the text provided or the list of tokens provided by C<listOfTokens>.

=over

=item C<text>

  text => ...

C<text> holds the text that the tokens are to be extracted from. It can be a single string,
a reference to a string, a reference to an array of strings, or any combination of these.

=item C<listOfTokens>

  listOfTokens => ...

Optionally, if C<text> is not defined, then the list of tokens to use in forming the
n-grams can be provided by C<listOfTokens>, which should point to an array reference of strings.

=back

An example using the method:

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

=cut

sub getListOfNgrams
{
  my ($Self, %Parameters) = @_;

  # get the size of the ngrams to compute.
  my $sizeOfNgrams = $Self->{sizeOfNgrams};

  # get the list of tokens from the user to the text provided.
  my $listOfTokens;
  if (exists ($Parameters{text}))
  {
    # compute the list of tokens from the text provided.
    $listOfTokens = $Self->getListOfTokens($Parameters{text});
  }
  elsif (exists ($Parameters{listOfTokens}))
  {
    # use the list of tokens provided by the user.
    $listOfTokens = $Parameters{listOfTokens};
  }
  else
  {
    # gotta have some tokens to make n-grams.
    croak "neither parameter 'text => ' nor 'listOfTokens => ' were defined; at least one of them must be defined.\n";
  }

  # if the list of tokens is empty or the size of the n-grams is one,
  # just return the list of tokens as the list of n-grams.
  return $listOfTokens if (($#$listOfTokens == -1) || ($sizeOfNgrams == 1));

  # get the string to use to merge the tokens.
  my $separator = '';
  $separator = $Self->{ngramWordSeparator} if ($Self->{typeOfNgrams} =~ /^w/);

  # compute the list of n-grams.
  my @listOfNgrams;
  my $indexOfLastTokenInNgram = $sizeOfNgrams - 1;
  my $indexOfLastNgram = scalar (@$listOfTokens) - $sizeOfNgrams + 1;
  for (my $i = 0; $i < $indexOfLastNgram; $i++, $indexOfLastTokenInNgram++)
  {
    push @listOfNgrams, join($separator, @$listOfTokens[$i..$indexOfLastTokenInNgram]);
  }

  # note, if the number of tokens in the list is less than sizeOfNgrams, then
  # no n-grams are returned, that is, @listOfNgrams is empty.
  return \@listOfNgrams;
}

=head2 C<getListOfNgramsWithPositions>

The function C<getListOfNgramsWithPositions> returns an array reference to the list of n-grams computed
from the text provided or the list of tokens provided by C<listOfTokens>. Each item in the list returned
is of the form C<['n-gram', starting-index, n-gram-length]>; the starting index and n-gram length are
relative to the unnormalized text. When  C<typeOfNgrams> is C<'asc'> the index and length refer to bytes,
when C<typeOfNgrams> is C<'characters'> or C<'words'> they refer to characters.

=over

=item C<text>

  text => ...

C<text> holds the text that the tokens are to be extracted from. It can be a single string,
a reference to a string, a reference to an array of strings, or any combination of these.

=item C<listOfTokens>

  listOfTokens => ...

Optionally, if C<text> is not defined, then the list of tokens to use in forming the
n-grams can be provided by C<listOfTokens>, which should point to an array reference where
each item in the array is of the form C<[token, starting-position, length]>, where
C<starting-position> and C<length> are integers indicating the position of the token.

=back

An example using the method:

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

=cut

sub getListOfNgramsWithPositions
{
  my ($Self, %Parameters) = @_;

  # get the size of the ngrams to compute.
  my $sizeOfNgrams = $Self->{sizeOfNgrams};

  # get the list of tokens from the user to the text provided.
  my $listOfTokens;
  if (exists ($Parameters{text}))
  {
    # compute the list of tokens from the text provided.
    $listOfTokens = $Self->getListOfTokensWithPositions (%Parameters);
  }
  elsif (exists ($Parameters{listOfTokens}))
  {
    # use the list of tokens provided by the user.
    $listOfTokens = $Parameters{listOfTokens};
  }
  else
  {
    # gotta have some tokens to make n-grams.
    croak "neither parameter 'text => ' nor 'listOfTokens => ' were defined; at least one of them must be defined.\n";
  }

  # if the list of tokens is empty or the size of the n-grams is one,
  # just return the list of tokens as the list of n-grams.
  return $listOfTokens if (($#$listOfTokens == -1) || ($sizeOfNgrams == 1));

  # get the string to use to merge the tokens.
  my $separator = '';
  $separator = $Self->{ngramWordSeparator} if ($Self->{typeOfNgrams} =~ /^w/);

  # compute the list of n-grams and their positions.
  my @listOfNgramsWithPositions;
  my @indices= (0..($sizeOfNgrams - 1));
  my $indexOfLastTokenInNgram = $sizeOfNgrams - 1;
  my $indexOfLastNgram = scalar (@$listOfTokens) - $sizeOfNgrams + 1;
  for (my $i = 0; $i < $indexOfLastNgram; $i++, $indexOfLastTokenInNgram++)
  {
    push @listOfNgramsWithPositions, [join ($separator, map {$listOfTokens->[$_+$i][0]} @indices),

    # index to start of first n-gram
    $listOfTokens->[$i][1],

    # length of the n-gram.
    $listOfTokens->[$i + $sizeOfNgrams - 1][1] + $listOfTokens->[$i + $sizeOfNgrams - 1][2] - $listOfTokens->[$i][1]];
  }

  # note, if the number of tokens in the list is less than sizeOfNgrams, then
  # no n-grams are returned, that is, @listOfNgrams is empty.
  return \@listOfNgramsWithPositions;
}

=head2 C<getListOfNgramHashValues>

The function C<getListOfNgramHashValues> returns an array reference to the list of integer hash values
computed from the n-grams
of the text provided or the list of tokens provided by C<listOfTokens>. The advantage of using
hashes over strings is that they take less memory and are theoretically faster to compute. With strings
the time to compute the n-grams is proportional to their size, with hashes it is not
since they are computed recursively. Also, the amount of memory used to store the n-gram strings
grows proportional to their size, with hashes it does not. The disadvantage lies with
hashing collisions, but these will be very rare. However, for small n-gram sizes hash values
may take more time to compute since all code is written in Perl.

=over

=item C<text>

  text => ...

C<text> holds the text that the tokens are to be extracted from. It can be a single string,
a reference to a string, a reference to an array of strings, or any combination of these.

=item C<listOfTokens>

  listOfTokens => ...

Optionally, if C<text> is not defined, then the list of tokens to use in forming the
n-grams can be provided by C<listOfTokens>, which should point to an array reference of strings.

=back

An example using the method:

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

=cut

sub getListOfNgramHashValues
{
  my ($Self, %Parameters) = @_;

  # get the size of the ngrams to compute.
  my $sizeOfNgrams = $Self->{sizeOfNgrams};

  # get the list of tokens from the user to the text provided.
  my $listOfTokens;
  if (exists ($Parameters{text}))
  {
    # compute the list of tokens from the text provided.
    $listOfTokens = $Self->getListOfTokens($Parameters{text});
  }
  elsif (exists ($Parameters{listOfTokens}))
  {
    # use the list of tokens provided by the user.
    $listOfTokens = $Parameters{listOfTokens};
  }
  else
  {
    # gotta have some tokens to make n-grams.
    croak "neither parameter 'text => ' nor 'listOfTokens => ' were defined; at least one of them must be defined.\n";
  }

  # get the list of hashes for the tokens.
  my $listOfHashesOfTokens = $Self->getHashValuesOfListOfStrings (listOfStrings => $listOfTokens);
  my $totalTokens = $#$listOfHashesOfTokens + 1;

  # if the list of tokens is empty or the size of the n-grams is one,
  # just return the list of hash values of the tokens.
  if (($totalTokens == 0) || ($sizeOfNgrams == 1))
  {
    return $listOfHashesOfTokens;
  }

  # holds the hash values computed.
  my @listOfHashValues;

  # compute the shifts need to add a hash code to the running hash value.
  my $bitInInteger = $Self->{bitsInInteger};
  my $addShiftRight = $bitInInteger - 1;

  # compute the value of the first hash.
  my $runningHashValue = 0;
  for (my $i = 0; $i < $sizeOfNgrams; $i++)
  {
    $runningHashValue = ($runningHashValue << 1) ^ $Self->rshift($runningHashValue,$addShiftRight) ^ $listOfHashesOfTokens->[$i];
  }
  push @listOfHashValues, $runningHashValue;

  # compute the shifts needed to remove the oldest hash code in the running hash value.
  my $indexToRemove = 0;
  my $removeShiftLeft = ($sizeOfNgrams - 1) % $bitInInteger;
  my $removeShiftRight = $bitInInteger - $removeShiftLeft;
  my $removeShiftMask = ~(-1 << $removeShiftLeft);
  my $addShiftMask = ~(-1 << 1);

  for (my $indexToAdd = $sizeOfNgrams; $indexToAdd < $totalTokens; $indexToRemove++, $indexToAdd++)
  {
    $runningHashValue ^= ($listOfHashesOfTokens->[$indexToRemove] << $removeShiftLeft) ^ (($listOfHashesOfTokens->[$indexToRemove] >> $removeShiftRight) & $removeShiftMask);
    $runningHashValue = ($runningHashValue << 1) ^ (($runningHashValue >> $addShiftRight) & $addShiftMask) ^ $listOfHashesOfTokens->[$indexToAdd];
    push @listOfHashValues, $runningHashValue;
  }

  # note, if the number of tokens in the list is less than sizeOfNgrams, then
  # no n-grams are returned, that is, @listOfHashValues is empty.
  return \@listOfHashValues;
}

=head2 C<getListOfNgramHashValuesWithPositions>

The function C<getListOfNgramHashValuesWithPositions> returns an array reference to the list of integer hash values and
n-gram positional information computed
from the text provided or the list of tokens provided by C<listOfTokens>. Each item in the list returned
is of the form C<['n-gram-hash', starting-index, n-gram-length]>; the starting index and n-gram length are
relative to the unnormalized text. When  C<typeOfNgrams> is C<'asc'> the index and length refer to bytes,
when C<typeOfNgrams> is C<'characters'> or C<'words'> they refer to characters.

The advantage of using
hashes over strings is that they take less memory and are theoretically faster to compute. With strings
the time to compute the n-grams is proportional to their size, with hashes it is not
since they are computed recursively. Also, the amount of memory used to store the n-gram strings
grows proportional to their size, with hashes it does not. The disadvantage lies with
hashing collisions, but these will be very rare. However, for small n-gram sizes hash values
may take more time to compute since all code is written in Perl.

=over

=item C<text>

  text => ...

C<text> holds the text that the tokens are to be extracted from. It can be a single string,
a reference to a string, a reference to an array of strings, or any combination of these.

=item C<listOfTokens>

  listOfTokens => ...

Optionally, if C<text> is not defined, then the list of tokens to use in forming the
n-grams can be provided by C<listOfTokens>, which should point to an array reference where
each item in the array is of the form C<[token, starting-position, length]>, where
C<starting-position> and C<length> are integers indicating the position of the token.

=back

An example using the method:

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

=cut

sub getListOfNgramHashValuesWithPositions
{
  my ($Self, %Parameters) = @_;

  # get the size of the ngrams to compute.
  my $sizeOfNgrams = $Self->{sizeOfNgrams};

  # get the list of tokens from the user to the text provided.
  my $listOfTokens;
  if (exists ($Parameters{text}))
  {
    # compute the list of tokens from the text provided.
    $listOfTokens = $Self->getListOfTokensWithPositions(%Parameters);
  }
  elsif (exists ($Parameters{listOfTokens}))
  {
    # use the list of tokens provided by the user.
    $listOfTokens = $Parameters{listOfTokens};
  }
  else
  {
    # gotta have some tokens to make n-grams.
    croak "neither parameter 'text => ' nor 'listOfTokens => ' were defined; at least one of them must be defined.\n";
  }

  # get the list of hashes for the tokens.
  my $listOfHashesOfTokens = $Self->getHashValuesOfListOfStrings (listOfStrings => [map {$_->[0]} @$listOfTokens]);
  my $totalTokens = $#$listOfHashesOfTokens + 1;

  # if the list of tokens is empty or the size of the n-grams is one,
  # just return the list of hash values of the tokens.
  if (($totalTokens == 0) || ($sizeOfNgrams == 1))
  {
    for (my $i = 0; $i < $totalTokens; $i++)
    {
      $listOfHashesOfTokens->[$i] = [$listOfHashesOfTokens->[$i], $listOfTokens->[$i][1], $listOfTokens->[$i][2]];
    }
    return $listOfHashesOfTokens;
  }

  # holds the hash values computed.
  my @listOfHashValues;

  # compute the shifts need to add a hash code to the running hash value.
  my $bitInInteger = $Self->{bitsInInteger};
  my $addShiftRight = $bitInInteger - 1;

  # compute the value of the first hash.
  my $runningHashValue = 0;
  for (my $i = 0; $i < $sizeOfNgrams; $i++)
  {
    $runningHashValue = ($runningHashValue << 1) ^ $Self->rshift($runningHashValue,$addShiftRight) ^ $listOfHashesOfTokens->[$i];
  }
  push @listOfHashValues, [$runningHashValue, $listOfTokens->[0][1], $listOfTokens->[$sizeOfNgrams - 1][1] + $listOfTokens->[$sizeOfNgrams - 1][2] - $listOfTokens->[0][1]];

  # compute the shifts need to remove the oldest hash code in the running hash value.
  my $indexToRemove = 0;
  my $removeShiftLeft = ($sizeOfNgrams - 1) % $bitInInteger;
  my $removeShiftRight = $bitInInteger - $removeShiftLeft;
  my $removeShiftMask = ~(-1 << $removeShiftLeft);
  my $addShiftMask = ~(-1 << 1);

  for (my $indexToAdd = $sizeOfNgrams; $indexToAdd < $totalTokens; $indexToRemove++, $indexToAdd++)
  {
    $runningHashValue ^= ($listOfHashesOfTokens->[$indexToRemove] << $removeShiftLeft) ^ (($listOfHashesOfTokens->[$indexToRemove] >> $removeShiftRight) & $removeShiftMask);
    $runningHashValue = ($runningHashValue << 1) ^ (($runningHashValue >> $addShiftRight) & $addShiftMask) ^ $listOfHashesOfTokens->[$indexToAdd];
    push @listOfHashValues, [$runningHashValue, $listOfTokens->[$indexToRemove + 1][1], $listOfTokens->[$indexToRemove + $sizeOfNgrams][1] + $listOfTokens->[$indexToRemove + $sizeOfNgrams][2] - $listOfTokens->[$indexToRemove + 1][1]];
  }

  # note, if the number of tokens in the list is less than sizeOfNgrams, then
  # no n-grams are returned, that is, @listOfHashValues is empty.
  return \@listOfHashValues;
}

sub getListOfTokens
{
  my ($Self, @Text) = @_;

  # if no text, return the empty list.
  return [] unless @Text;
  my $text = \@Text;

  # get the tokens.
  if ($Self->{typeOfNgrams} =~ /^a/)
  {
    return $Self->getListOfAsc ($text);
  }
  elsif ($Self->{typeOfNgrams} =~ /^c/)
  {
    return $Self->getListOfCharacters ($text);
  }
  elsif ($Self->{typeOfNgrams} =~ /^w/)
  {
    return $Self->getListOfWords ($text);
  }
  else
  {
    croak "programming error: parameter typeOfNgrams has value '" . $Self->{typeOfNgrams}. "' and should not.\n";
  }
}

# returns an array reference to the list of tokens found text provided
# including each tokens' position and length in the original text. Each
# entry in the array is of the form ['token', starting-position, length]
sub getListOfTokensWithPositions # (text => '..')
{
  my ($Self, %Parameters) = @_;

  # if no text, return the empty list.
  return [] unless exists $Parameters{text};
  my $text = $Parameters{text};

  # get the tokens.
  if ($Self->{typeOfNgrams} =~ /^a/)
  {
    return $Self->getListOfAscWithPositions (\$text);
  }
  elsif ($Self->{typeOfNgrams} =~ /^c/)
  {
    return $Self->getListOfCharactersWithPositions (\$text);
  }
  elsif ($Self->{typeOfNgrams} =~ /^w/)
  {
    return $Self->getListOfWordsWithCharacterPositions (\$text);
  }
  else
  {
    croak "programming error: parameter typeOfNgrams has value '" . $Self->{typeOfNgrams}. "' and should not.\n";
  }
}

# uses unpack to return the list of asc characters of the text.
sub getListOfAsc # ($text)
{
  use bytes;
  my $Self = shift;

  # get the text as a list of string references.
  my $listOfText = $Self->getListOfAllScalarsAsReferences (@_);

  my @listOfTokens;
  foreach my $stringRef (@$listOfText)
  {
    if ($Self->{normalizeText})
    {
      push @listOfTokens, map {chr} unpack ('C*', $Self->normalizeText ($stringRef));
    }
    else
    {
      push @listOfTokens, map {chr} unpack ('C*', $$stringRef);
    }
  }
  return \@listOfTokens;
}

# uses an empty split to get all the characters in the text.
sub getListOfCharacters # ($text)
{
  my $Self = shift;
  return $Self->getListOfTokensUsingRegexp ('', @_);
}

# returns a list of all substrings of letters.
sub getListOfWords # ($text)
{
  my $Self = shift;
  return $Self->getListOfTokensUsingRegexp ('[^\p{IsAlphabetic}]+', @_);
}

# regexp must be a regexp without bounding slashes.
sub getListOfTokensUsingRegexp # ($regexp, $text)
{
  my $Self = shift;
  my $regexp = shift;

  # get the text as a list of string references.
  my $listOfText = $Self->getListOfAllScalarsAsReferences (@_);

  my @listOfTokens;
  foreach my $stringRef (@$listOfText)
  {
    if ($Self->{normalizeText})
    {
      push @listOfTokens, split (/$regexp/, $Self->normalizeText ($stringRef));
    }
    else
    {
      push @listOfTokens, split (/$regexp/, $$stringRef);
    }
  }
  return \@listOfTokens;
}

# returns a copy of the text that is lower case, has all none letters replaced
# with spaces, and has all multiple spaces replaced with one space.
sub normalizeText # ($text)
{
  my $Self = shift;
  my $Text = shift;

  # make a copy of the text, and downcase it.
  my $type = ref ($Text);
  if ($type eq '')
  {
    $Text = lc $Text;
  }
  elsif ($type eq 'SCALAR')
  {
    $Text = lc $$Text;
  }

  # convert all none letters to spaces; tried to use tr/// but \p{IsAlphabetic} gave a
  # warning with it.
  $Text =~ s/\P{IsAlphabetic}/ /g;

  # compress mulitple spaces to one space.
  $Text =~ tr/ / /s;

  # remove leading spaces.
  $Text =~ s/^ +//;

  return $Text;
}

# if the tokens are to be ASC, positions without normalization with be just the
# byte number. to get the byte number with filtering, first we need to convert
# original text into characters with positions that include their byte index. then
# filter the text. so really we convert to characters first and generate either
# character positions or byte positions. from there we can get byte positions or
# characters positions or word positions.

# give a string reference returns an array reference of the form:
# [
#   [character, position = $OffSet, 1],
#   [character, position = $OffSet + 1, 1],
#   ...
#   [character, position = $Offset + length ($$StringRef) - 1, 1]
# ]
sub getCharactersWithCharacterPositions # ($StringRef, $OffSet)
{
  my $Self = shift;
  my $StringRef = shift;

  # default value of the offset is zero.
  my $Offset = shift;
  $Offset = 0 unless defined $Offset;

  # build the list of characters with their position.
  my @listOfCharacters = map { [$_, $Offset++, 1] } split //, $$StringRef;
  return \@listOfCharacters;
}

# give a string reference returns an array reference of the form:
# [
#   [character, byte-position, bytes::length (character)],
#   ...
#   [character, byte-position, bytes::length (character)]
# ]
sub getCharactersWithBytePositions # ($StringRef, $OffSet)
{
  my $Self = shift;
  my $StringRef = shift;

  # default value of the offset is zero.
  my $Offset = shift;
  $Offset = 0 unless defined $Offset;

  # build the list of characters with their byte position.
  my @listOfCharacters = split //, $$StringRef;
  {
    use bytes;
    foreach my $char (@listOfCharacters)
    {
      my $len = bytes::length ($char);
      $char = [$char, $Offset, $len];
      $Offset += $len;
    }
    no bytes;
  }
  return \@listOfCharacters;
}

# given the list of characters returned from getCharactersWithCharacterPositions or
# from getCharactersWithBytePositions returns a list of the normalized characters.
sub normalizeCharacterList
{
  my $Self = shift;

  # get the list of characters with position info.
  my $ListOfCharacters = shift;

  my @filteredList;
  my $previousCharIsSpace = 1;

  for (my $i = 0; $i < @$ListOfCharacters; $i++)
  {
    # get the pair [character, position].
    my $charPos = $ListOfCharacters->[$i];

    # lowercase the character or convert it to a space.
    my $newChar;
    if ($charPos->[0] =~ m/^\p{IsAlphabetic}$/o)
    {
      $newChar = lc $charPos->[0];
    }
    else
    {
      $newChar = ' ';
    }

    # add the new character to the list.
    if ($newChar ne ' ')
    {
      # if the new character is not a space, add it.
      $previousCharIsSpace = 0;
      push @filteredList, [$newChar, $charPos->[1], $charPos->[2]];
    }
    elsif (!$previousCharIsSpace)
    {
      # if the new character is a space but the previous was not, add it.
      $previousCharIsSpace = 1;
      push @filteredList, [$newChar, $charPos->[1], $charPos->[2]];
    }
  }

  # return the new list of characters and their positions.
  return \@filteredList;
}

# given a list of text (strings), returns an array reference to the list
# of ASC characters comprizing all the text, with their bytes positions and
# length (always 1) in the original text.
sub getListOfAscWithPositions # ($Text)
{
  my $Self = shift;

  # get the text as a list of string references.
  my $listOfText = $Self->getListOfAllScalarsAsReferences (@_);

  my @listOfTokensWithPosition;
  my $offset = 0;
  for (my $i = 0; $i < @$listOfText; $i++)
  {
    my $stringRef = $listOfText->[$i];

    # convert the string to a list of characters.
    my $listOfCharacters = $Self->getCharactersWithBytePositions ($stringRef, $offset);

    # normalize of the list of characters.
    if ($Self->{normalizeText})
    {
      $listOfCharacters = $Self->normalizeCharacterList ($listOfCharacters);
    }

    # expand each character into its list of bytes.
    {
      use bytes;

      for (my $j = 0; $j < @$listOfCharacters; $j++)
      {
        # get the characters, its position, and length.
        my $charPosLen = $listOfCharacters->[$j];

        # split the characters into ASC bytes.
        my @listOfAsc = map {chr} unpack ('C*', $charPosLen->[0]);

        my $byteOffset = $charPosLen->[1];
        foreach my $asc (@listOfAsc)
        {
          push @listOfTokensWithPosition, [$asc, $byteOffset++, 1];
        }
      }

      $offset += bytes::length ($$stringRef);
      no bytes;
    }
  }

  return \@listOfTokensWithPosition;
}

# given a list of text (strings), returns an array reference to the list
# of characters comprizing all the text, with their character positions and
# length in the original text.
sub getListOfCharactersWithPositions # ($Text)
{
  my $Self = shift;

  # get the text as a list of string references.
  my $listOfText = $Self->getListOfAllScalarsAsReferences (@_);

  my @listOfTokensWithPosition;
  my $offset = 0;
  for (my $i = 0; $i < @$listOfText; $i++)
  {
    my $stringRef = $listOfText->[$i];

    # convert the string to a list of characters.
    my $listOfCharacters = $Self->getCharactersWithCharacterPositions ($stringRef, $offset);

    # normalize of the list of characters.
    if ($Self->{normalizeText})
    {
      $listOfCharacters = $Self->normalizeCharacterList ($listOfCharacters);
    }

    # append the list of characters.
    push @listOfTokensWithPosition, @$listOfCharacters;

    # accumulate the character offsets.
    $offset += length ($$stringRef);
  }

  return \@listOfTokensWithPosition;
}

# given a list of text (strings), returns an array reference to the list
# of words comprizing all the text, with their character positions and
# length in the original text. [word, start-position, length]
sub getListOfWordsWithCharacterPositions # ($Text)
{
  my $Self = shift;

  # get the text as a list of string references.
  my $listOfText = $Self->getListOfAllScalarsAsReferences (@_);

  my @listOfTokensWithPosition;
  my $offset = 0;
  for (my $i = 0; $i < @$listOfText; $i++)
  {
    my $stringRef = $listOfText->[$i];

    # convert the string to a list of characters.
    my $listOfCharacters = $Self->getCharactersWithCharacterPositions ($stringRef, $offset);

    # normalize of the list of characters.
    if ($Self->{normalizeText})
    {
      $listOfCharacters = $Self->normalizeCharacterList ($listOfCharacters);
    }

    # get the list of words.
    my $listOfWords = $Self->getListOfWordsFromCharacterList ($listOfCharacters);

    # append the list of characters.
    push @listOfTokensWithPosition, @$listOfWords;

    # accumulate the character offsets.
    $offset += length ($$stringRef);
  }

  return \@listOfTokensWithPosition;
}

# given a list of text (strings), returns an array reference to the list
# of words comprizing all the text, with their bytes positions and
# length in the original text. [word, start-position, length]
sub getListOfWordsWithBytePositions # ($Text)
{
  my $Self = shift;

  # get the text as a list of string references.
  my $listOfText = $Self->getListOfAllScalarsAsReferences (@_);

  my @listOfTokensWithPosition;
  my $offset = 0;
  for (my $i = 0; $i < @$listOfText; $i++)
  {
    my $stringRef = $listOfText->[$i];

    # convert the string to a list of characters.
    my $listOfCharacters = $Self->getCharactersWithBytePositions ($stringRef, $offset);

    # normalize of the list of characters.
    if ($Self->{normalizeText})
    {
      $listOfCharacters = $Self->normalizeCharacterList ($listOfCharacters);
    }

    # get the list of words.
    my $listOfWords = $Self->getListOfWordsFromCharacterList ($listOfCharacters);

    # append the list of characters.
    push @listOfTokensWithPosition, @$listOfWords;

    # accumulate the byte offsets.
    $offset += length ($$stringRef);
  }

  return \@listOfTokensWithPosition;
}

sub getListOfWordsFromCharacterList # ($ListOfCharactersWithPositions)
{
  my $Self = shift;

  # get the list of characters with position info.
  my $ListOfCharacters = shift;

  my @listOfWords;
  my @currentWord;
  for (my $i = 0; $i < @$ListOfCharacters; $i++)
  {
    # get the pair [character, position, length].
    my $charPosLen = $ListOfCharacters->[$i];

    if ($charPosLen->[0] =~ m/^\p{IsAlphabetic}$/)
    {
      # got a letter so accumulate the letters of the word.
      push @currentWord, $charPosLen;
    }
    elsif (@currentWord)
    {
      # none letter, so concat all the characters of the word.
      my $word = join ('', map {$_->[0]} @currentWord);

      # get the position of the first character in the word.
      my $position = $currentWord[0]->[1];

      # compute total characters in the word.
      my $length = $currentWord[-1]->[1] - $currentWord[0]->[1] + $currentWord[-1]->[2];

      # store the word info.
      push @listOfWords, [$word, $position, $length];

      # clear the cache or word characters.
      $#currentWord = -1;
    }
  }

  # store the last word if there is one.
  if (@currentWord)
  {
    # none letter, so concat all the characters of the word.
    my $word = join ('', map {$_->[0]} @currentWord);

    # get the position of the first character in the word.
    my $position = $currentWord[0]->[1];

    # get to total characters in the word.
    my $length = $currentWord[-1]->[1] - $currentWord[0]->[1] + $currentWord[-1]->[2];

    # store the word info.
    push @listOfWords, [$word, $position, $length];
  }

  # return the new list of characters and their positions.
  return \@listOfWords;
}

# flattens a list of scalars, references, arrays, references to arrays, and
# any combination of them into a list of references to the scalars.
sub getListOfAllScalarsAsReferences
{
  my $Self = shift;

  my @listOfRefsToScalars;
  foreach my $item (@_)
  {
    my $type = ref ($item);
    if ($type eq '')
    {
      push @listOfRefsToScalars, \$item;
    }
    elsif ($type eq 'SCALAR')
    {
      push @listOfRefsToScalars, $item;
    }
    elsif ($type eq 'ARRAY')
    {
       push @listOfRefsToScalars, @{$Self->getListOfAllScalarsAsReferences (@$item)};
    }
    elsif ($type eq 'REF')
    {
       push @listOfRefsToScalars, @{$Self->getListOfAllScalarsAsReferences ($$item)};
    }
  }
  return \@listOfRefsToScalars;
}

# give an array reference defined using listOfStrings => ... that defines
# a list of strings. this routine returns the hash values computed for the
# strings.
sub getHashValuesOfListOfStrings
{
  use bytes;

  my ($Self, %Parameters) = @_;

  # get the bits to circular shift the hash values by.
  my $shiftBits = $Self->{bitsInInteger} - 1;
  my $mask = ~(-1 << 1);

  # get the hash values of the bytes.
  my $byteHashValues = $Self->{byteHashValues};

  my @listOfHashValues;
  foreach my $string (@{$Parameters{listOfStrings}})
  {
    my $value = 0;
    foreach my $byte (unpack ('C*', $string))
    {
      $value = ($value << 1) ^ (($value >> $shiftBits) & $mask) ^ $byteHashValues->[$byte];
    }
    push @listOfHashValues, $value;
  }
  return \@listOfHashValues;
}

# create and store the list of hash values used for bytes; used as a
# basis for all hash values.
sub setByteHashValues
{
  my ($Self, %Parameters) = @_;

  # get the seed to use for the random number generator.
  my $randomSeed = 1093;
  $randomSeed = $Parameters{randomSeed} if exists $Parameters{randomSeed};
  srand ($randomSeed);

  # create and store the list of byte hash values.
  my $size = 256;
  my @byteHashValues;
  my $maxValue = $Self->rshift(~0,1);
  for (my $i = 0; $i < $size; $i++)
  {
    push @byteHashValues, (int rand ($maxValue)) ^ ((int rand ($maxValue)) << 7);
  }
  $Self->{byteHashValues} = \@byteHashValues;
  return;
}

# compute and store the number of bits in an integer.
sub setBitsInInteger
{
  my $Self = shift;

  # maybe some day computer words will contain 1024 bits.
  my $maxIterations = 1024;
  my $bitsInInteger = 0;
  for (my $maxInteger = ~0; $maxInteger; $maxInteger <<= 1)
  {
    ++$bitsInInteger;

    # ensure the loop is finite.
    last if (--$maxIterations < 1);
  }
  $Self->{bitsInInteger} = $bitsInInteger;
  return;
}

# does a right bit shift even if the int is signed.
sub rshift
{
  return ($_[1] >> $_[2]) & ~(-1 << ($_[0]->{bitsInInteger} - $_[2])) if ($_[2]);
  return $_[1];
}

=head1 INSTALLATION

To install the module run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

information processing, ngram, ngrams, n-gram, n-grams, string, text

=head1 SEE ALSO

L<Encode>, L<perlunicode>, L<utf8>

=begin html

<a href="http://en.wikipedia.org/wiki/N-gram">n-gram</a>, <a href="http://perldoc.perl.org/functions/split.html">split</a>, <a href="http://perldoc.perl.org/functions/unpack.html">unpack</a>

=end html

=cut

1;
# The preceding line will help the module return a true value
