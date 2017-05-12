package Text::Categorize::Util;
use strict;
use warnings;
use Graph;
use List::Util qw(min max sum);
use Log::Log4perl;
use Text::StemTagPOS;
use Data::Dump qw(dump);

use constant SUBSTR_POSITION => 0;
use constant SUBSTR_LENGTH   => 1;

# TODO: need to set phraseBoundary by POS type.

BEGIN
{
  use Exporter ();
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = '0.51';
  @ISA         = qw(Exporter);
  @EXPORT      = qw(getKeywordsAndPhrases);
  @EXPORT_OK   = qw(getKeywordsAndPhrases);
  %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Method to get keywords and phrases of text.

=head1 NAME

C<Text::Categorize::Util> - Method to get keywords and phrases of text.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Text::Categorize::Textrank::En;
  use Text::Categorize::Util qw(getKeywordsAndPhrases);
  use Data::Dump qw(dump);
  my $textrankerEn = Text::Categorize::Textrank::En->new();
  my $text         = Text::Categorize::Util::getTestText();
  print $text;
  my $textrankInfo = $textrankerEn->getTextrankInfoOfText(listOfText => [$text]);
  my $keywordInfo = getKeywordsAndPhrases(
    %$textrankInfo,
    listOfStemmedTaggedDocuments => [ $textrankInfo->{listOfStemmedTaggedSentences} ],
    numberOfKeywords             => 9
  );
  dump $keywordInfo;
  my %phrases = map { ($_->{phrase}, 1) } map { (@$_) } @{ $keywordInfo->{keyphrases} };
  dump [ sort keys %phrases ];

=head1 DESCRIPTION

C<Text::Categorize::Util> provides a routine to select the keywords and related
phrases from the results of the routine
L<getTextrankInfoOfText|Text::Categorize::Textrank::En/getTextrankInfoOfText> in
L<Text::Categorize::Textrank::En>.

=head1 ROUTINES

=head2 C<getKeywordsAndPhrases>

From the results of the routine L<getTextrankInfoOfText|Text::Categorize::Textrank::En/getTextrankInfoOfText> in
L<Text::Categorize::Textrank::En> the routine C<getKeywordsAndPhrases> selects the keywords for the text and
their most common instance in the text (C<keywordOrderInstance>) plus
the keyphrases in the text associated with the selected keywords (C<keyphrases>).

More precisely, if C<$results> is the returned hash, then C<$results-E<gt>{keywordOrderInstance}>
contains an array reference of the selected keywords in their descending order of importance within
the text; each item in the list is C<{keyword =E<gt> '', instance =E<gt> ''}>, where C<keyword> is the identifier
used for the keyword and C<instance> is the most common form or instance of the keyword in the text.

C<$results-E<gt>{keyphrases}>
contains an array reference of hashes of the form C<{wordsOfPhrase =E<gt> [], keywordsOfPhrase =E<gt> [], phrase =E<gt> ''}>
where C<wordsOfPhrase> is a list of the words from C<listOfStemmedTaggedSentences> that comprise the phrase,
C<keywordsOfPhrase> is a list of the keywords that occur in the phrase, and
C<phrase> is the string of the phrase words.

=over

=item C<listOfStemmedTaggedDocuments>

 listOfStemmedTaggedDocuments => [...]

C<listOfStemmedTaggedDocuments> is an array reference where each item in the array is a list of stemmed and part-of-speech
tagged sentences from L<Text::StemTagPos>. If C<listOfStemmedTaggedDocuments> is not defined, then the
text to be processed should be provided via C<listOfText>.

=item C<hashOfTextrankValues>

  hashOfTextrankValues => {}

C<hashOfTextrankValues> holds the hash of the textrank values computed by
L<getTextrankOfListOfTokens|Text::Categorize::Textrank/getTextrankOfListOfTokens>. Selected phrases will only
begin and end with tokens for which C<hashOfTextrankValues> is defined and positive.

=item C<useStemmedWords>

  useStemmedWords => 1

If C<useStemmedWords> should be set to the same value when computing the textrank using the routine
L<getTextrankInfoOfText|Text::Categorize::Textrank::En/getTextrankInfoOfText> in L<Text::Categorize::Textrank::En>.
The default is true.

=item C<numberOfKeywords>

  numberOfKeywords => 10

C<numberOfKeywords> should be set to the number of keywords to select for the text. If it is greater than
the number of values in C<hashOfTextrankValues>, it is then set to that value. The default is 10.

=back

=cut

sub getKeywordsAndPhrases
{

  # get the parameters.
  my %Parameters = @_;

  # get the list of of tokens for each document.
  my @documentListOfTokens;
  foreach my $listOfStemmedTaggedSentences (@{ $Parameters{listOfStemmedTaggedDocuments} })
  {
    push @documentListOfTokens,
      _getListOfTokensWithTextrankInfo(%Parameters, listOfStemmedTaggedSentences => $listOfStemmedTaggedSentences);
  }
  $Parameters{documentListOfTokens} = \@documentListOfTokens;

  # get the basic information about the keywords and phrases from all the documents.
  my ($keywords, $documentPhrases) = _getKeywordsAndPhrases(%Parameters);

  # get the selected form of each keyword and its occurrence.
  my ($keywordInstance, $keywordOccurrence) = getKeywordInstance(keywords => $keywords, documentPhrases => $documentPhrases);

  # compute the sets of related keywords.
  my $keywordOrder = getKeywordOrdered(keywords => $keywords, documentPhrases => $documentPhrases, keywordOccurrence => $keywordOccurrence);

  # build the hash of the keyword and instance in the keyword order.
  my @keywordOrderInstance = map { ({ keyword => $_, instance => $keywordInstance->{$_} }) } @$keywordOrder;

  # get the list of phrases with their keywords.
  my $documentPhraseInfo = getKeyphraseInfo(%Parameters, keywords => $keywords, documentPhrases => $documentPhrases);

  # return the keyword info.
  return { keywordOrderInstance => \@keywordOrderInstance, keyphrases => $documentPhraseInfo };
}

# for each phrase compute the keywords that occur within it and build
# the string of the phrase.
sub getKeyphraseInfo    # (keywords => {}, $keyphrases => [], useStemmedWords => 1)
{

  # get the parameters.
  my %Parameters      = @_;
  my $keywords        = $Parameters{keywords};
  my $documentPhrases = $Parameters{documentPhrases};
  my $useStemmedWords = $Parameters{useStemmedWords};

  my @documentPhraseInfo;
  foreach my $keyphrases (@$documentPhrases)
  {
    my @phraseInfo;
    foreach my $phrase (@$keyphrases)
    {
      my %keywordsInPhrase;
      my @words;
      foreach my $token (@$phrase)
      {

        # set the id of the token.
        my $tokenId;
        my $word = ' ';
        if ($useStemmedWords)
        {
          if (exists $token->{orig})
          {
            $tokenId = $token->{orig}[Text::StemTagPOS::WORD_STEMMED];
            $word    = $token->{orig}[Text::StemTagPOS::WORD_ORIGINAL];
          }
        }
        else
        {
          if (exists $token->{orig})
          {
            $tokenId = lc $token->{orig}[Text::StemTagPOS::WORD_ORIGINAL];
            $word    = $token->{orig}[Text::StemTagPOS::WORD_ORIGINAL];
          }
        }

        # save the word of the phrase.
        push @words, $word;

        # put the token in the hash if it is a keyword.
        $keywordsInPhrase{$tokenId} = 1 if ((defined $tokenId) && (exists $keywords->{$tokenId}));
      }

      my @wordsOfPhrase = map { ($_->{orig}) } @$phrase;
      push @phraseInfo,
        { wordsOfPhrase => \@wordsOfPhrase, keywordsOfPhrase => [ sort keys %keywordsInPhrase ], phrase => join('', @words) };
    }
    push @documentPhraseInfo, \@phraseInfo;
  }

  return \@documentPhraseInfo;
}

# given the hash of keywords, keyphrases, and a hash of keywordOccurrence
# returns the keywords in their order of importance.
sub getKeywordOrdered
{

  # get the parameters.
  my %Parameters        = @_;
  my $keywords          = $Parameters{keywords};
  my $documentPhrases   = $Parameters{documentPhrases};
  my $keywordOccurrence = $Parameters{keywordOccurrence};

  # first compute the sets of related keywords.
  my @keywordSets;

  my $keywordGraph = Graph::Undirected->new();
  foreach my $keyphrases (@$documentPhrases)
  {
    foreach my $phrase (@$keyphrases)
    {

      # get the tokens in the phrase that are keywords.
      my @keyTokens = grep { exists($keywords->{$_}) } map { ($_->{id}) } grep { exists($_->{id}) } @$phrase;

      # if there are none, skip the rest.
      next unless @keyTokens;

      # add the first token to the graph.
      $keywordGraph->add_vertex($keyTokens[0]);

      # link the remaining tokens to the first token.
      for (my $i = 1 ; $i < @keyTokens ; $i++)
      {
        $keywordGraph->add_vertex($keyTokens[$i]);
        $keywordGraph->add_edge($keyTokens[0], $keyTokens[$i]);
      }
    }
  }

  # get the connected components of the graph.
  @keywordSets = $keywordGraph->connected_components();

  # sort the sets and keywords within by their total occurrence.
  my @keywordSetsSorted;
  foreach my $setOfKeywords (@keywordSets)
  {

    # sort the keywords in the set by their occurrence.
    $setOfKeywords = [ sort { $keywordOccurrence->{$b} <=> $keywordOccurrence->{$a} } @$setOfKeywords ];

    # get the total occurence of all the keywords in the set.
    my $totalOccurence = sum(map { ($keywordOccurrence->{$_}) } @$setOfKeywords);

    # store the sets of sorted keywords with their total occurence.
    push @keywordSetsSorted, [ $totalOccurence, $setOfKeywords ];
  }

  # sort the sets in descend order by their total occurrence.
  @keywordSets = sort { $b->[0] <=> $a->[0] } @keywordSetsSorted;

  # extract the sorted sets into one list.
  my @keywordsOrder = map { (@{ $_->[1] }) } @keywordSets;

  return \@keywordsOrder;
}

# given the hash of keywords and list of phrases, returns the pair
# (\%keywordFormSelected, \%keywordOccurrence), where %keywordFormSelected
# contains the most common, shortest form of the keyword amoungst the
# phrases and %keywordOccurrence contains the total occurrence of the
# keywords amoungst the phrases.
sub getKeywordInstance    # (keywords => {}, documentPhrases => [])
{

  # get the parameters.
  my %Parameters = @_;

  # get the basic information about the keywords and keyphrases.
  my $keywords        = $Parameters{keywords};
  my $documentPhrases = $Parameters{documentPhrases};

  # initialize the hash to hold the forms of each keyword.
  my %keywordForms;
  foreach my $token (keys %$keywords)
  {
    $keywordForms{$token} = {};
  }

  # count the different forms of the keywords and the number of
  # times it occurs.
  my %keywordOccurrence;
  foreach my $keyphrases (@$documentPhrases)
  {
    foreach my $phrase (@$keyphrases)
    {
      foreach my $token (@$phrase)
      {

        # skip the token if it has no id.
        next unless exists $token->{id};

        # skip the token if not a keyword.
        next unless exists $keywordForms{ $token->{id} };

        # count the form of the keyword.
        $keywordForms{ $token->{id} }->{ $token->{orig}[Text::StemTagPOS::WORD_ORIGINAL] } += 1;

        # count the occurrence of the keyword.
        ++$keywordOccurrence{ $token->{id} };
      }
    }
  }

  # choose the most common, shortest form for display.
  my %keywordFormSelected;
  while (my ($tokenId, $forms) = each %keywordForms)
  {
    my ($selectedForm, $occurrence);
    while (my ($form, $count) = each %$forms)
    {
      if (defined $occurrence)
      {
        if (   ($occurrence < $count)
            || (($occurrence == $count) && (length($selectedForm) > length($form)))
            || (($selectedForm cmp $form) == 1))
        {
          $selectedForm = $form;
          $occurrence   = $count;
        }
      }
      else
      {
        $selectedForm = $form;
        $occurrence   = $count;
      }
    }
    $keywordFormSelected{$tokenId} = $selectedForm;
  }

  return (\%keywordFormSelected, \%keywordOccurrence);
}

# given the listOfTokens, the hashOfTextrankValues, and numberOfKeywords to use, the routine
# returns the pair (\%keywords, \@keyphrases) where %keywords contains { stemmed-keyword => textrank-value },
# and @keyphrases contains the sublists from listOfTokens that are the selected phrases.
sub _getKeywordsAndPhrases    # (listOfTokens => [], hashOfTextrankValues => {}, numberOfKeywords => 10)
{

  # get the parameters.
  my %Parameters = @_;

  # get the hash of the textrank values and their stats.
  my $hashOfKeywordWeights = $Parameters{hashOfTextrankValues};

  # put the hash of keyword weights into a descendingly sorted list of pairs.
  my @weightKey = sort { $b->[1] <=> $a->[1] } map { ([ $_, $hashOfKeywordWeights->{$_} ]) } keys %$hashOfKeywordWeights;

  # get the number of keywords to use.
  my $numberOfKeywords = 10;
  $numberOfKeywords = int abs $Parameters{numberOfKeywords} if exists $Parameters{numberOfKeywords};
  $numberOfKeywords = min(scalar @weightKey, $numberOfKeywords);

  # if the number of keywords is zero, return the empty list.
  return () if $numberOfKeywords < 1;

  # get the threshold to use for the keyphrases, usually it is just the
  # weight of the $numberOfkeywords + 1 keyword.
  my $thresholdForKeywords = 0;
  if ($numberOfKeywords + 1 < @weightKey)
  {
    $thresholdForKeywords = $weightKey[ $numberOfKeywords + 1 ]->[1];
  }
  elsif ($numberOfKeywords < @weightKey)
  {
    $thresholdForKeywords = $weightKey[$numberOfKeywords]->[1];
  }

  # put the selected keywords into a hash.
  my %keywords;
  for (my $i = 0 ; $i < $numberOfKeywords ; $i++)
  {
    $keywords{ $weightKey[$i]->[0] } = $weightKey[$i]->[1];
  }

  # holds the list of words in the selected phrases of each document.
  my @documentPhrases;

  # compute the phrases for each document.
  foreach my $listOfTokens (@{ $Parameters{documentListOfTokens} })
  {

    # compute the keyphrases based on the keyword threshold.
    my @fullKeyphrases;

    # used to hold the current phrase of words being selected.
    my $currentPhrase = [];

    # holds the index of the most recent word in a selected keyphrase.
    my $lastSelectedIndex = -1;
    for (my $i = 0 ; $i < @$listOfTokens ; $i++)
    {
      if ($listOfTokens->[$i]{weight} > $thresholdForKeywords)
      {
        if ($i - 1 == $lastSelectedIndex)
        {

          # the phrase is continuing, so add the word to the phrase.
          push @$currentPhrase, $listOfTokens->[$i];
        }
        else
        {

          # the new selected word is not immediately after the last word
          # used in a keyphrase, so we are starting a new keyphrase.
          push @fullKeyphrases, $currentPhrase;
          $currentPhrase = [ $listOfTokens->[$i] ];
        }
        $lastSelectedIndex = $i;
      }
    }

    # if there was a phrase remaining in $currentPhrase save it.
    push @fullKeyphrases, $currentPhrase if (@$currentPhrase);

    # trim the phrases to only starting and ending with phraseBoundary
    # words (usually textrank words).
    my @trimmedPhrases;
    foreach my $phrase (@fullKeyphrases)
    {

      # get the index in the phrase of the first boundary token.
      my $indexOfFirstBoundaryToken = 0;
      while (!exists($phrase->[$indexOfFirstBoundaryToken]{phraseBoundary}))
      {
        ++$indexOfFirstBoundaryToken;
        last if ($indexOfFirstBoundaryToken >= @$phrase);
      }

      # get the index in the phrase of the last boundary token.
      my $indexOfLastSelected = @$phrase - 1;
      while (!exists($phrase->[$indexOfLastSelected]{phraseBoundary}))
      {
        --$indexOfLastSelected;
        last if ($indexOfLastSelected < 0);
      }

      # splice out the selected tokens from the phrase.
      my @newPhrase = splice(@$phrase, $indexOfFirstBoundaryToken, $indexOfLastSelected - $indexOfFirstBoundaryToken + 1);

      # save the trimmed phrase, if it is not empty.
      push @trimmedPhrases, \@newPhrase if @newPhrase;
    }

    push @documentPhrases, \@trimmedPhrases;
  }

  # return the hash of keywords and trimmed phrases.
  return (\%keywords, \@documentPhrases);
}

# using all information returned from computing the textrank of text, return the tokens
# in a single reference list with each token's info as a hash reference containing:
#  {
#    type => 'gap' or 'word',
#    orig => [Text::StemTagPOS...data],
#    position => character position of the token,
#    length => length position of the token,
#    id => stemmed version of the token,
#    weight => weight of the token,
#    phraseBoundary => 1 if a phrase can start or end on the token
#  }
sub _getListOfTokensWithTextrankInfo    # (listOfStemmedTaggedSentences => [], hashOfTextrankValues => {}, useStemmedWords => 1)
{

  # get the parameters.
  my %Parameters = @_;

  # get the list of stemmed, tagged sentences with their positional information.
  my $listOfStemmedTaggedSentences = $Parameters{listOfStemmedTaggedSentences};

  # get the hash of the textrank values.
  my $hashOfTokenValues;
  $hashOfTokenValues = $Parameters{hashOfTextrankValues} if exists $Parameters{hashOfTextrankValues};

  # set the id of the tokens (stemmed or unstemmed words).
  my $useStemmedWords = 1;
  $useStemmedWords = $Parameters{useStemmedWords} if exists $Parameters{useStemmedWords};

  # build the list of token information.
  my @listOfRankedTokens;
  my @listOfUnrankedTokens;
  my $stringLength = 0;
  foreach my $sentence (@$listOfStemmedTaggedSentences)
  {
    foreach my $word (@$sentence)
    {

      # if the position of the word is unknown, skip it.
      next if ($word->[Text::StemTagPOS::WORD_CHAR_POSITION] < 0);

      # build the hash to hold the position, length, and weight of the token.
      my %tokenInfo;

      # set the type of the token.
      if ($word->[Text::StemTagPOS::WORD_POSTAG] eq 'pgp')
      {
        $tokenInfo{type} = 'gap';
      }
      else
      {
        $tokenInfo{type} = 'token';
      }

      # set the original info about the token.
      $tokenInfo{orig} = $word;

      # set the position and length of the token.
      $tokenInfo{position} = $word->[Text::StemTagPOS::WORD_CHAR_POSITION];
      $tokenInfo{length}   = $word->[Text::StemTagPOS::WORD_CHAR_LENGTH];

      # set the id of the token.
      if ($useStemmedWords)
      {
        $tokenInfo{id} = $word->[Text::StemTagPOS::WORD_STEMMED];
      }
      else
      {
        $tokenInfo{id} = lc $word->[Text::StemTagPOS::WORD_ORIGINAL];
      }

      if (exists($hashOfTokenValues->{ $tokenInfo{id} }) && ($hashOfTokenValues->{ $tokenInfo{id} } > 0))
      {

        # set the weight of the token.
        $tokenInfo{weight} = $hashOfTokenValues->{ $tokenInfo{id} };

        # set that a phrase can start or end with this token.
        $tokenInfo{phraseBoundary} = 1;

        # separate this token from the unranked tokens.
        push @listOfRankedTokens, \%tokenInfo;
      }
      else
      {

        # separate this token from the ranked tokens.
        push @listOfUnrankedTokens, \%tokenInfo;
      }

      # compute the length of the the tokens where contained in.
      $stringLength = $tokenInfo{position} + $tokenInfo{length} if ($stringLength < $tokenInfo{position} + $tokenInfo{length});
    }
  }

  # get the list of tokens with the gaps added.
  my $listOfTokensWithWeightGaps = _getListOfTokensWithGapsInserted(listOfTokens => \@listOfRankedTokens, stringLength => $stringLength);

  # set the weight of the gaps via the weighted tokens.
  _addWeightToGaps(listOfTokens => $listOfTokensWithWeightGaps);

  # get all the tokens with all the gaps.
  my $listOfTokens = [ sort { $a->{position} <=> $b->{position} } (@listOfRankedTokens, @listOfUnrankedTokens) ];

  # copy the weights of the gaps in $listOfTokensWithWeightGaps to the gap-tokens in $listOfTokens
  # contained within those gaps. this process is merging two sorted lists.
  {

    # index to current token in $listOfTokensWithWeightGaps.
    my $weightedTokenIndex = 0;

    # index to current token in $listOfTokens.
    my $tokenIndex = 0;

    # keep comparing until the end of one of the lists is reached.
    while (($tokenIndex < @$listOfTokens) && ($weightedTokenIndex < @$listOfTokensWithWeightGaps))
    {

      # compare the two tokens.
      my $cmp = _compareTokenPositions($listOfTokens->[$tokenIndex], $listOfTokensWithWeightGaps->[$weightedTokenIndex]);

      if ($cmp == -1)
      {

        # $listOfTokens->[$tokenIndex] is before the current weighted token, so move to the next one.
        ++$tokenIndex;
      }
      elsif ($cmp == 1)
      {

        # $listOfTokens->[$tokenIndex] is after the current weighted token, so move to the next weighted token.
        ++$weightedTokenIndex;
      }
      else
      {

        # make sure $listOfTokens->[$tokenIndex] does not have a weight already; if so log the error and die.
        if (exists($listOfTokens->[$tokenIndex]{weight}))
        {
          if ($listOfTokens->[$tokenIndex]{weight} != $listOfTokensWithWeightGaps->[$weightedTokenIndex]{weight})
          {
            my $logger = Log::Log4perl->get_logger();
            $logger->logdie('error: copying of weights to tokens in gaps incorrect.');
          }
        }

        # set the weight of $listOfTokens->[$tokenIndex].
        $listOfTokens->[$tokenIndex]{weight} = $listOfTokensWithWeightGaps->[$weightedTokenIndex]{weight};

        # move on to the next unweighted token.
        ++$tokenIndex;
      }
    }

    # add the last weight to any remaining tokens.
    $weightedTokenIndex = @$listOfTokensWithWeightGaps - 1;
    while ($tokenIndex < @$listOfTokens)
    {
      $listOfTokens->[$tokenIndex]{weight} = $listOfTokensWithWeightGaps->[$weightedTokenIndex]{weight};
      $tokenIndex++;
    }
  }

  # force the weight of some tokens (periods) to be zero.
  for (my $tokenIndex = 0 ; $tokenIndex < @$listOfTokens ; $tokenIndex++)
  {
    if (exists($listOfTokens->[$tokenIndex]{orig}))
    {
      my $posTag = uc $listOfTokens->[$tokenIndex]{orig}[Text::StemTagPOS::WORD_POSTAG];
      $posTag =~ tr/A-Z//cd;
      if ($posTag eq Text::StemTagPOS::POSTAGS_PERIOD)
      {
        $listOfTokens->[$tokenIndex]{weight} = 0;
      }
    }
  }

  # add an index to each token (they are sorted by position).
  for (my $tokenIndex = 0 ; $tokenIndex < @$listOfTokens ; $tokenIndex++)
  {
    $listOfTokens->[$tokenIndex]{index} = $tokenIndex;
  }

  # return the list of tokens with weights.
  return $listOfTokens;
}

# compares the position of TokenA and TokenB. If TokenA starts before TokenB, -1 is
# returned. If TokenA starts after the end of the TokenB, 1 is returned. If TokenA
# starts with TokenB, 0 is returned.
sub _compareTokenPositions
{
  my ($TokenA, $TokenB) = @_;
  return -1 if ($TokenA->{position} < $TokenB->{position});
  return 1  if ($TokenA->{position} >= $TokenB->{position} + $TokenB->{length});
  return 0;
}

# given the list of tokens, sets the weight of each token that is a gap based on the
# weight of the surround non-gap tokens.
sub _addWeightToGaps
{

  # get the parameters.
  my %Parameters = @_;

  # get the list of tokens.
  my $listOfTokens = [];
  $listOfTokens = $Parameters{listOfTokens} if exists $Parameters{listOfTokens};

  # set the weight of each gap in $listOfTokens.
  for (my $i = 0 ; $i < @$listOfTokens ; $i++)
  {

    # get the token hash.
    my $token = $listOfTokens->[$i];

    # only computing weights for gaps.
    if ($token->{type} eq 'gap')
    {

      # get the previous tokens weight and length.
      my $previousTokenWeight = 0;
      my $previousTokenLength = 0;
      if (($i > 0) && (($listOfTokens->[ $i - 1 ]{type}) eq 'token') && exists($listOfTokens->[ $i - 1 ]{weight}))
      {
        $previousTokenWeight = $listOfTokens->[ $i - 1 ]{weight};
        $previousTokenLength = $listOfTokens->[ $i - 1 ]{length};
      }

      # get the next tokens weight and length.
      my $nextTokenWeight = 0;
      my $nextTokenLength = 0;
      if (($i + 1 < @$listOfTokens) && (($listOfTokens->[ $i + 1 ]{type}) eq 'token') && exists($listOfTokens->[ $i + 1 ]{weight}))
      {
        $nextTokenWeight = $listOfTokens->[ $i + 1 ]{weight};
        $nextTokenLength = $listOfTokens->[ $i + 1 ]{length};
      }

      # get the length of the tokens.
      my $previousNextTokensLength = $previousTokenLength + $nextTokenLength;

      # if the tokens have zero length, we have problems.
      if ($previousNextTokensLength < 1)
      {
        $token->{weight} = 0;
      }
      else
      {
        # initially set the weight of the gap to the weighted sum of the surrounding tokens.
        $token->{weight} = ($previousTokenWeight * $previousTokenLength + $nextTokenWeight * $nextTokenLength) / $previousNextTokensLength;
      }

      # compute the mean length of the surrounding tokens.
      my $meanLength = $previousNextTokensLength / 2;

      # if the length of the gap is greater than the mean length, reduce the weight by $meanLength / $token->{length}.
      if ($token->{length} > $meanLength)
      {
        $token->{weight} *= $meanLength / $token->{length};
      }
    }
  }

  return undef;
}

# given the list of tokens, returns a new list of them with the gaps between them
# included; the tokens are sorted by the positions.
sub _getListOfTokensWithGapsInserted    # (listOfTokens => [{}, ..., {}])
{

  # get the parameters.
  my %Parameters = @_;

  # get the list of tokens.
  my $listOfTokens = [];
  $listOfTokens = $Parameters{listOfTokens} if exists $Parameters{listOfTokens};

  # build the list of complete tokens.
  my @listOfCompleteTokens = @$listOfTokens;

  # get the list of substrings of the tokens.
  my @listOfSubstringPositions = map { ([ $_->{position}, $_->{length} ]) } @$listOfTokens;

  # get the list of missing substring positions.
  my $listOfMissingSubstrings = _getListOfMissingSubstringPositions(%Parameters, listOfSubstringPositions => \@listOfSubstringPositions);

  # add the gaps to the list.
  foreach my $positionLength (@$listOfMissingSubstrings)
  {
    my %substringWordInfo;
    $substringWordInfo{type}     = 'gap';
    $substringWordInfo{position} = $positionLength->[SUBSTR_POSITION];
    $substringWordInfo{length}   = $positionLength->[SUBSTR_LENGTH];
    push @listOfCompleteTokens, \%substringWordInfo;
  }

  # sort the substrings by position.
  @listOfCompleteTokens = sort { $a->{position} <=> $b->{position} } @listOfCompleteTokens;

  # if test is true, make sure things were computed correctly.
  if (exists($Parameters{test}) && $Parameters{test})
  {
    my $totalSubstrings = @listOfCompleteTokens;

    for (my $i = 1 ; $i < $totalSubstrings ; $i++)
    {

      # make sure the strings are sorted.
      if ($listOfCompleteTokens[ $i - 1 ]->{position} > $listOfCompleteTokens[$i]->{position})
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->logdie('error: substrings in $listOfSubstringInfo are not sorted and should be.');
      }

      # make sure the strings have at least one character.
      if ($listOfCompleteTokens[ $i - 1 ]->{length} < 1)
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->logdie('error: substrings in $listOfSubstringInfo has length less than one.');
      }
    }
  }

  # returns the complete lust of tokens sorted by their starting index in ascending order.
  return \@listOfCompleteTokens;
}

# routine returns an array reference of the gaps or missing substrings given
# a list of substrings. for example, if listOfSubstringPositions is
# [[2,4], [9,2], [11,5], [20,1]] and stringLength is 25, then the list returned
# is [[0, 2], [6, 3], [16, 4], [21, 4]].
sub _getListOfMissingSubstringPositions    # (listOfSubstringPositions => \@, stringLength => n)
{

  # get the parameters.
  my %Parameters = @_;

  # if listOfSubstringPositions is not defined, we have one special case.
  if (!defined($Parameters{listOfSubstringPositions}))
  {
    if (!defined($Parameters{stringLength}))
    {

      # no parameters defined, so return the empty list.
      return [];
    }
    else
    {
      if (int($Parameters{stringLength}) > 0)
      {

        # positive string length, but no substrings, so gap is entire string.
        return [ 0, int($Parameters{stringLength}) - 1 ];
      }
      else
      {

        # non-positive string length, so return empty list.
        return [];
      }
    }
  }

  # get the list of [SUBSTR_POSITION, SUBSTR_LENGTH].
  my $listOfSubstringPositions = $Parameters{listOfSubstringPositions};

  # get the number of subtrings.
  my $totalSubstrings = $#$listOfSubstringPositions + 1;

  # skip substrings having length less than one or a negative position position.
  my @filteredListOfSubstringPositions;
  for (my $i = 0 ; $i < $totalSubstrings ; $i++)
  {
    next if ($listOfSubstringPositions->[$i][SUBSTR_LENGTH] < 1);
    next if ($listOfSubstringPositions->[$i][SUBSTR_POSITION] < 0);
    push @filteredListOfSubstringPositions, $listOfSubstringPositions->[$i];
  }
  $listOfSubstringPositions = \@filteredListOfSubstringPositions;
  $totalSubstrings          = $#$listOfSubstringPositions + 1;

  # get the entire strings length if defined.
  my $stringLength;
  $stringLength = int abs $Parameters{stringLength} if exists $Parameters{stringLength};

  # if $stringLength is undefined use the last substring to compute the length
  # of the entire string; the string will not end with a gap in this case.
  if (!defined($stringLength) && $totalSubstrings)
  {
    $stringLength = 0;
    foreach my $currentSubstringInfo (@$listOfSubstringPositions)
    {
      my $last = $currentSubstringInfo->[SUBSTR_POSITION] + $currentSubstringInfo->[SUBSTR_LENGTH];
      $stringLength = $last if $last > $stringLength;
    }
  }

  # if $stringLength is not defined at this point there are no gaps.
  return [] unless defined $stringLength;

  # if $totalSubstrings is zero, then the entire string is a gap.
  unless ($totalSubstrings)
  {
    my @substringGapInfo;
    $substringGapInfo[SUBSTR_POSITION] = 0;
    $substringGapInfo[SUBSTR_LENGTH]   = $stringLength;
    return [ \@substringGapInfo ];
  }

  # sort the pairs by their position.
  my @listOfSubstringPositions = sort { $a->[SUBSTR_POSITION] <=> $b->[SUBSTR_POSITION] } @$listOfSubstringPositions;

  # @listOfMissingSubstringPositions holds all the gaps.
  my @listOfMissingSubstringPositions;

  # get the first substring position.
  my $currentSubstringInfo = $listOfSubstringPositions[0];

  # if the first substring does not start with position 0, add the beginning gap.
  if ($currentSubstringInfo->[SUBSTR_POSITION] != 0)
  {
    my @substringGapInfo;
    $substringGapInfo[SUBSTR_POSITION] = 0;
    $substringGapInfo[SUBSTR_LENGTH]   = $currentSubstringInfo->[SUBSTR_POSITION];
    push @listOfMissingSubstringPositions, \@substringGapInfo;
  }

  # compute the gaps.
  for (my $i = 1 ; $i < $totalSubstrings ; $i++)
  {

    # get the information about the previous and current substrings.
    my $previousSubstringInfo = $listOfSubstringPositions[ $i - 1 ];
    my $currentSubstringInfo  = $listOfSubstringPositions[$i];

    # compute the starting index and length of the gap.
    my $gapStartPosition = $previousSubstringInfo->[SUBSTR_POSITION] + $previousSubstringInfo->[SUBSTR_LENGTH];
    my $gapEndPosition   = $currentSubstringInfo->[SUBSTR_POSITION] - 1;
    my $gapLength        = $gapEndPosition - $gapStartPosition + 1;

    # if the gap is not a positive size, skip it.
    # maybe a warning should be logged since it really should not happen.
    if ($gapLength > 0)
    {

      # store the information about the gap.
      my @substringGapInfo;
      $substringGapInfo[SUBSTR_POSITION] = $gapStartPosition;
      $substringGapInfo[SUBSTR_LENGTH]   = $gapLength;
      push @listOfMissingSubstringPositions, \@substringGapInfo;
    }
  }

  # add any trailing gap to the list.
  $currentSubstringInfo = $listOfSubstringPositions[-1];
  if ($currentSubstringInfo->[SUBSTR_POSITION] + $currentSubstringInfo->[SUBSTR_LENGTH] < $stringLength)
  {
    my @substringGapInfo;
    $substringGapInfo[SUBSTR_POSITION] = $currentSubstringInfo->[SUBSTR_POSITION] + $currentSubstringInfo->[SUBSTR_LENGTH];
    $substringGapInfo[SUBSTR_LENGTH] = $stringLength - ($currentSubstringInfo->[SUBSTR_POSITION] + $currentSubstringInfo->[SUBSTR_LENGTH]);
    push @listOfMissingSubstringPositions, \@substringGapInfo;
  }

  # if test is true, check if gaps were computed correctly.
  if (exists($Parameters{test}) && $Parameters{test})
  {
    my @allSubstrings =
      sort { $a->[SUBSTR_POSITION] <=> $b->[SUBSTR_POSITION] } (@listOfSubstringPositions, @listOfMissingSubstringPositions);
    my $totalSubstrings = @allSubstrings;

    for (my $i = 1 ; $i < $totalSubstrings ; $i++)
    {

      # make sure the strings are sorted.
      if ($allSubstrings[ $i - 1 ]->[SUBSTR_POSITION] + $allSubstrings[ $i - 1 ]->[SUBSTR_LENGTH] < $allSubstrings[$i]->[SUBSTR_POSITION])
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->logdie("error: missed computing a gap.");
      }
    }
  }

  # returns the list of missing substrings.
  return \@listOfMissingSubstringPositions;
}

# returns the text of the Gettysburg Address speech.
sub getTestText
{
  return 'Four score and seven years ago our fathers brought forth upon this
continent, a new nation, conceived in Liberty, and dedicated to the
proposition that all men are created equal. Now we are engaged in a
great civil war, testing whether that nation, or any nation so
conceived, and so dedicated, can long endure. We are met on a great
battle-field of that war. We have come to dedicate a portion of that
field, as a final resting place for those who here gave their lives,
that that nation might live. It is altogether fitting and proper that we
should do this. But, in a larger sense, we cannot dedicate-we cannot
consecrate-we cannot hallow-this ground. The brave men, living and dead,
who struggled here, have consecrated it far above our poor power to add
or detract. The world will little note, nor long remember, what we say
here, but it can never forget what they did here. It is for us the
living, rather, to be dedicated here to the unfinished work which they
who fought here, have, thus far, so nobly advanced. It is rather for us
to be here dedicated to the great task remaining before us-that from
these honored dead we take increased devotion to that cause for which
they here gave the last full measure of devotion-that we here highly
resolve that these dead shall not have died in vain-that this nation,
under God, shall have a new birth of freedom-and that, government of the
people, by the people, for the people, shall not perish from the earth.
';
}

=head1 INSTALLATION

To install the module run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 BUGS

Please email bugs reports or feature requests to C<bug-text-categorize-util@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Categorize-Util>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

categorize, keywords, keyphrases, nlp, textrank

=head1 SEE ALSO

L<Log::Log4perl>, L<Text::Categorize::Textrank::En>

=cut

1;

# The preceding line will help the module return a true value
