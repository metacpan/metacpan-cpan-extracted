package Text::Summarize;
use strict;
use warnings;
use Log::Log4perl;
use Text::Categorize::Textrank;
use Data::Dump qw(dump);

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '0.50';
	@ISA         = qw(Exporter);
	@EXPORT      = qw(getSumbasicRankingOfSentences);
	@EXPORT_OK   = qw(getSumbasicRankingOfSentences);
	%EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Routine to compute summaries of text.

=head1 NAME

C<Text::Summarize> - Routine to compute summaries of text.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Text::Summarize;
  use Data::Dump qw(dump);
  my $listOfSentences = [
    { id => 0, listOfTokens => [qw(all people are equal)] },
    { id => 1, listOfTokens => [qw(all men are equal)] },
    { id => 2, listOfTokens => [qw(all are equal)] },
  ];
  dump getSumbasicRankingOfSentences(listOfSentences => $listOfSentences);

=head1 DESCRIPTION

C<Text::Summarize> contains a routine to score a list of sentences
for inclusion in a summary of the text using the
SumBasic algorithm from the report I<Beyond SumBasic: Task-Focused Summarization with Sentence Simplification and Lexical Expansion>
by L. Vanderwendea, H. Suzukia, C. Brocketta, and A. Nenkovab.

=head1 ROUTINES

=head2 C<getSumbasicRankingOfSentences>

  use Text::Summarize;
  use Data::Dump qw(dump);
  my $listOfSentences = [
    { id => 0, listOfTokens => [qw(all people are equal)] },
    { id => 1, listOfTokens => [qw(all men are equal)] },
    { id => 2, listOfTokens => [qw(all are equal)] },
  ];
  dump getSumbasicRankingOfSentences(listOfSentences => $listOfSentences);

C<getSumbasicRankingOfSentences> computes the sumBasic score of the list of sentences
provided. It returns an array reference containing the pairs C<[id, score]> sorted
in descending order of score, where C<id> is from C<listOfSentences>.

=over

=item C<listOfSentences>

 listOfSentences => [{id => '..', listOfTokens => [...]}, ..., {id => '..', listOfTokens => [...]}]

C<listOfSentences> holds the list of sentences that are to be scored. Each
item in the list is a hash reference of the form C<{id =E<gt> '..', listOfTokens =E<gt> [...]}> where
C<id> is a unique identifier for the sentence and C<listOfTokens> is an array
reference of the list of tokens comprizing the sentence.

=item C<tokenWeight>

 tokenWeight => {}

C<tokenWeight> is a optional hash reference that provides the weight of the tokens defined
in C<listOfSentences>. If C<tokenWeight> is defined, but undefined for a token in a sentence,
then the tokens weight defaults to zero unless C<ignoreUndefinedTokens> is true,
in which case the token is ignored and not used to compute the average weight
of the sentences containing it. If C<tokenWeight> is undefined then the weights of the tokens
are either their frequency of occurrence in the filtered text, or their textranks if C<textRankParameters> is defined.

=item C<ignoreUndefinedTokens>

 ignoreUndefinedTokens => 0

If C<ignoreUndefinedTokens> is true, then any tokens for which C<tokenWeight> is
undefined are ignored and not used to compute the average weight of a
sentence; the default is false.

=item C<tokenWeightUpdateFunction>

 tokenWeightUpdateFunction => &subroutine (currentTokenWeight, initialTokenWeight, token, selectedSentenceId, selectedSentenceWeight)

C<tokenWeightUpdateFunction> is an optional parameter for defining the function that updates the
weight of a token when it is contained in a selected sentence. Five parameters are passed to the
subroutine: the token's current weight (float), the token's initial weight (float), the token (string), the C<id> of the
selected sentence (string), and the current average weight of the tokens in the selected sentence (float).
The default is L<tokenWeightUpdateFunction_Squared>.

=item C<textRankParameters>

  textRankParameters => undef

If C<textRankParameters> is defined, then the token weights
are computed using L<Text::Categorize::Textrank>. The parameters to use for L<Text::Categorize::Textrank>,
excluding the C<listOfTokens> parameters, can be set using the hash reference defined by C<textRankParameters>.
For example, C<textRankParameters =E<gt> {directedGraph =E<gt> 1}> would make the textrank weights
be computed using a directed token graph.

=back

=cut

sub getSumbasicRankingOfSentences
{
	my (%Parameters) = @_;

	# get the list of sentences.
	my $listOfSentences = $Parameters{listOfSentences} if exists $Parameters{listOfSentences};
	return [] unless defined $listOfSentences;

	# get the original token weights.
	my $originalTokenWeights;
	$originalTokenWeights = $Parameters{tokenWeight} if (exists($Parameters{tokenWeight}) && defined($Parameters{tokenWeight}));
	
	# if textRankParameters is defined, compute the token weights via textrank.
	if (exists($Parameters{textRankParameters}) && defined($Parameters{textRankParameters}))
	{
    $originalTokenWeights = _getTextRankWeightOfTokens(%Parameters, listOfSentences => $listOfSentences);
	}

  # if $originalTokenWeights is not defined, then use the frequency of the tokens as their weight.
  if (!defined ($originalTokenWeights))
  {
    $originalTokenWeights = _getFrequencyWeightOfTokens(listOfSentences => $listOfSentences);
  }

	# get the function to update the weights of the tokens.
	my $tokenWeightUpdateFunction = \&tokenWeightUpdateFunction_Squared;
	$tokenWeightUpdateFunction = $Parameters{tokenWeightUpdateFunction} if exists $Parameters{tokenWeightUpdateFunction};

	# set the flag for ignoreUndefinedTokens.
	my $ignoreUndefinedTokens = exists $Parameters{ignoreUndefinedTokens} && $Parameters{ignoreUndefinedTokens};

	# copy the weights of only the tokens that occur in the sentences.
	# the default weight of a token is zero.
	my %tokenWeight;
	for (my $i = 0 ; $i < @$listOfSentences ; $i++)
	{

		# if the sentence has no id, skip it.
		unless (exists $listOfSentences->[$i]->{id})
		{

			# get the list of tokens in the sentence as a string.
			my $stringOfTokens;
			if (exists($listOfSentences->[$i]->{listOfTokens}))
			{
				$stringOfTokens = join(' ', @{ $listOfSentences->[$i]->{listOfTokens} });
			}

			# create the message to log.
			my $logger = Log::Log4perl->get_logger();
			my $message;
			if (defined $stringOfTokens)
			{
				$message = "warning: skipping sentence number $i with tokens $stringOfTokens since it is missing an id.\n";
			}
			else
			{
				$message = "warning: skipping sentence number $i since it is missing an id and listOfTokens.\n";
			}

			# log the message as a warning.
			$logger->logwarn($message);

			# skip processing the sentence.
			next;
		}

		# get the listOfTokens of the sentence.
		if ((exists $listOfSentences->[$i]->{listOfTokens}) && (@{ $listOfSentences->[$i]->{listOfTokens} }))
		{
			my $listOfTokens = $listOfSentences->[$i]->{listOfTokens};
			foreach my $token (@$listOfTokens)
			{

				# if the weight is already defined for the token, skip it.
				next if exists $tokenWeight{$token};

				# if weight for token not defined, it defaults to zero if ignoreUndefinedTokens is false.
				if (exists $originalTokenWeights->{$token})
				{
					$tokenWeight{$token} = $originalTokenWeights->{$token};
				}
				elsif (!$ignoreUndefinedTokens)
				{
					$tokenWeight{$token} = 0;
				}
			}
		}
	}

	# normalize the token weights to sum to one.
	my $sum = 0;
	while (my ($token, $weight) = each %tokenWeight) { $sum += $weight; }
	$sum = 1 if ($sum == 0);
	while (my ($token, $weight) = each %tokenWeight) { $tokenWeight{$token} /= $sum; }

	# keep a copy of the initial token weights.
	my %initialTokenWeight = %tokenWeight;

	# @listOfEmptySentenceIds will hold the list of empty sentence ids.
	my @listOfEmptySentenceIds;

	# make a copy of the list of sentences
	my @localListOfSentences;
	for (my $i = 0 ; $i < @$listOfSentences ; $i++)
	{

		# if the sentence has no id, skip it.
		next unless exists $listOfSentences->[$i]->{id};

		# copy the id of the sentence.
		my %sentence;
		$sentence{id} = $listOfSentences->[$i]->{id};

		# convert the list of tokens in a sentence to a hash with the key as the token and the value its occurance in the sentence.
		if ((exists $listOfSentences->[$i]->{listOfTokens}) && (@{ $listOfSentences->[$i]->{listOfTokens} }))
		{
			my %tokenCount;
			my $empty = 1;
			foreach my $token (@{ $listOfSentences->[$i]->{listOfTokens} })
			{

				# if the weight for the token is not defined, skip it.
				if (exists $tokenWeight{$token})
				{
					++$tokenCount{$token};
					$empty = 0;
				}
			}

			# if the sentence has no defined tokens, store the id on @listOfEmptySentenceIds.
			if ($empty)
			{
				push @listOfEmptySentenceIds, [ $listOfSentences->[$i]->{id}, scalar @{ $listOfSentences->[$i]->{listOfTokens} } ];
			}
			else
			{
				$sentence{tokenCounts} = \%tokenCount;

				# store the sentence in a list.
				push @localListOfSentences, \%sentence;
			}
		}
		else
		{

			# if the sentence has no tokens, store the id on @listOfEmptySentenceIds.
			push @listOfEmptySentenceIds, [ $listOfSentences->[$i]->{id}, scalar @{ $listOfSentences->[$i]->{listOfTokens} } ];
		}
	}

	# compute the average weight of each sentence and initialize its selected flag to false.
	for (my $i = 0 ; $i < @localListOfSentences ; $i++)
	{

		# get the pointer to the sentence.
		my $sentence = $localListOfSentences[$i];

		# compute the weight of the sentence.
		my $weight        = 0;
		my $tokenCountSum = 0;
		while (my ($token, $count) = each %{ $sentence->{tokenCounts} })
		{
			$weight += $count * $tokenWeight{$token};
			$tokenCountSum += $count;
		}
		$sentence->{size}   = $tokenCountSum;
		$sentence->{weight} = $weight / $sentence->{size};

		# initialize each sentence as not selected.
		$sentence->{selected} = 0;
	}

	# build the inverted index of the sentences and tokens, called tokenSentenceIndex.
	my %tokenSentenceIndex;
	for (my $i = 0 ; $i < @localListOfSentences ; $i++)
	{

		# get the pointer to the sentence.
		my $sentence = $localListOfSentences[$i];

		# get the list of tokens in the sentence.
		foreach my $token (keys %{ $sentence->{tokenCounts} })
		{

			# add the weightSentence pointer to the tokenSentenceIndex.
			$tokenSentenceIndex{$token} = [] unless exists $tokenSentenceIndex{$token};

			# note we are storing the index of the sentence, not the pointer to the sentence.
			push @{ $tokenSentenceIndex{$token} }, $i;
		}
	}

	# make the list of just the tokens.
	my @listOfTokens = keys %tokenWeight;

	# @rankedListOfSentences will hold the sentences in sumbasic order.
	my @rankedListOfSentences;

	# loop over the sentences until they have all been selected.
	while (scalar(@rankedListOfSentences) < scalar(@localListOfSentences))
	{

		# if there are no tokens left, exit the loop.
		last unless @listOfTokens > 0;

		# get the token with the greatest (weight, length, -order).
		my $maxIndex       = 0;
		my $maxToken       = $listOfTokens[$maxIndex];
		my $maxTokenWeight = $tokenWeight{$maxToken};
		for (my $i = 1 ; $i < scalar(@listOfTokens) ; $i++)
		{
			my $cmp;
			if ($maxTokenWeight < $tokenWeight{ $listOfTokens[$i] })
			{

				# $maxTokenWeight is smaller.
				$cmp = -1;
			}
			elsif ($maxTokenWeight > $tokenWeight{ $listOfTokens[$i] })
			{

				# $maxTokenWeight is larger.
				$cmp = 1;
			}
			else
			{

				# weights are equal, compare token lengths, choose the longer one.
				$cmp = length($maxToken) <=> length($listOfTokens[$i]);

				# if tokens have equal length, choose the one lexically smaller.
				if ($cmp == 0) { $cmp = $listOfTokens[$i] cmp $maxToken; }
			}

			# if the current max is smaller, replace it.
			if ($cmp == -1)
			{
				$maxIndex       = $i;
				$maxToken       = $listOfTokens[$maxIndex];
				$maxTokenWeight = $tokenWeight{$maxToken};
			}
		}

		# copy the last token to where the max was, it may be popped off if there are no
		# sentences left containing it.
		$listOfTokens[$maxIndex] = $listOfTokens[-1];
		$listOfTokens[-1] = $maxToken;

		# if there are no sentences remaining with the token, move on to the next token.
		unless (exists $tokenSentenceIndex{$maxToken})
		{
			pop @listOfTokens;
			next;
		}

		# get the list of sentences that have the token.
		my $listOfSentencesWithToken = $tokenSentenceIndex{$maxToken};

		# if there are no sentences remaining with the token, move on to the next token.
		unless (scalar(@$listOfSentencesWithToken) > 0)
		{
			pop @listOfTokens;
			delete $tokenSentenceIndex{$maxToken};
			next;
		}

		# find the sentence having the token with the highest weight not yet selected.
		my $maxSentenceIndex;
		my $maxSentence;
		my @remainingListOfSentencesWithToken;
		foreach my $sentenceIndex (@$listOfSentencesWithToken)
		{

			# get the pointer to the sentence.
			my $sentence = $localListOfSentences[$sentenceIndex];

			# skip the sentence if already selected.
			next if $sentence->{selected};

			# if no sentence has been selected, just take the first valid sentence.
			unless (defined($maxSentence))
			{
				$maxSentence      = $sentence;
				$maxSentenceIndex = $sentenceIndex;
				next;
			}

			# choose the sentence with the greater weight, or the greater size, or the lesser id.
			my $cmp =
				   ($sentence->{weight} <=> $maxSentence->{weight})
				|| ($sentence->{size} <=> $maxSentence->{size})
				|| ($sentence->{id} cmp $maxSentence->{id});

			# store the new maximum sentence.
			if ($cmp == 1)
			{

				# store the previous maximum as an unselected sentence.
				push @remainingListOfSentencesWithToken, $maxSentenceIndex;
				$maxSentence      = $sentence;
				$maxSentenceIndex = $sentenceIndex;
			}
			else
			{

				# store the current sentence as unselected.
				push @remainingListOfSentencesWithToken, $sentenceIndex;
			}
		}

		# update the list of sentences with the token that were not selected for the summary.
		if (@remainingListOfSentencesWithToken == 0)
		{
			delete $tokenSentenceIndex{$maxToken};
		}
		else
		{

			# update the list of sentences that the token is contained in.
			$tokenSentenceIndex{$maxToken} = \@remainingListOfSentencesWithToken;
		}

		# if no sentence selected, then there are no unselected sentences with the
		# token, so move on to the next token.
		unless (defined $maxSentence)
		{
			pop @listOfTokens;
			delete $tokenSentenceIndex{$maxToken};
			next;
		}

		# store the sentence selected and its weight.
		$maxSentence->{selected} = 1;
		push @rankedListOfSentences, [ $maxSentence, $maxSentence->{weight} ];

		# update the weight of all the tokens in the max sentence.
		my @sentenceTokens = keys %{ $maxSentence->{tokenCounts} };
		foreach my $token (@sentenceTokens)
		{

			# (currentTokenWeight, initialTokenWeight, token, selectedSentenceId, selectedSentenceWeight)
			$tokenWeight{$token} =
				&$tokenWeightUpdateFunction($tokenWeight{$token}, $initialTokenWeight{$token}, $token, $maxSentence->{id}, $maxSentence->{weight});
		}

		# get all of the sentences that share tokens with the max sentence.
		my %sentencesToUpdate;
		foreach my $token (@sentenceTokens)
		{
			next unless exists $tokenSentenceIndex{$token};
			foreach my $sentenceIndex (@{ $tokenSentenceIndex{$token} })
			{
				$sentencesToUpdate{$sentenceIndex} = 1;
			}
		}
		my @listOfSentencesToUpdate = keys %sentencesToUpdate;

		# recompute the weight of the sentences that have tokens whose weight changed.
		# floating point calculations will become unstable due to rounding errors if the
		# old weights are subtracted and the new weights added. slower, but best to
		# recompute the average weights by summing.
		foreach my $sentenceIndex (@listOfSentencesToUpdate)
		{

			# get the pointer to the sentence.
			my $sentence = $localListOfSentences[$sentenceIndex];

			# skip the sentence if it was already selected.
			next if $sentence->{selected};

			# compute the weight of the sentence.
			my $weight = 0;
			while (my ($token, $count) = each %{ $sentence->{tokenCounts} })
			{
				$weight += $count * $tokenWeight{$token};
			}
			$sentence->{weight} = $weight / $sentence->{size};
		}
	}

	# normalize the sentence weights so they sum to one.
	my $totalSentenceWeight = 0;
	foreach my $sentenceWeight (@rankedListOfSentences)
	{
		$totalSentenceWeight += $sentenceWeight->[1];
	}
	$totalSentenceWeight = 1 if ($totalSentenceWeight == 0);

	foreach my $sentenceWeight (@rankedListOfSentences)
	{

		# normalize the sentence weight.
		$sentenceWeight = [ $sentenceWeight->[0]->{id}, $sentenceWeight->[1] / $totalSentenceWeight ];
	}

	# add the empty sentences to the list.
	push @rankedListOfSentences, map { [ $_->[0], 0 ] } sort { ($a->[1] <=> $b->[1]) || ($a->[0] cmp $b->[0]) } @listOfEmptySentenceIds;
	
	# adjust the weights to be descending (a kludge).
	if (@rankedListOfSentences)
	{
    my $totalSentenceWeight = 0;
    my $runningSum = 0;
    for (my $i = @rankedListOfSentences - 1; $i > -1; $i--)
    {
      $runningSum += $rankedListOfSentences[$i]->[1];
      $rankedListOfSentences[$i]->[1] = $runningSum;
      $totalSentenceWeight += $rankedListOfSentences[$i]->[1];
    }
    $totalSentenceWeight = 1 if ($totalSentenceWeight <= 0);
    foreach my $idWeight (@rankedListOfSentences)
    {
      $idWeight->[1] = abs ($idWeight->[1]/ $totalSentenceWeight);
    }
	}

	return \@rankedListOfSentences;
}

=head2 C<tokenWeightUpdateFunction_Squared>

Returns the tokens current weight squared.

=cut

sub tokenWeightUpdateFunction_Squared    # (currentTokenWeight, initialTokenWeight, token, selectedSentenceId, selectedSentenceWeight)
{
	return $_[0] * $_[0];
}

=head2 C<tokenWeightUpdateFunction_Multiplicative>

Returns the tokens current weight times its intial weight.

=cut

sub tokenWeightUpdateFunction_Multiplicative   # (currentTokenWeight, initialTokenWeight, token, selectedSentenceId, selectedSentenceWeight)
{
	return $_[0] * $_[1];
}

=head2 C<tokenWeightUpdateFunction_Sentence>

Returns the tokens current weight times its the average weight of the tokens in the selected sentence.

=cut

sub tokenWeightUpdateFunction_Sentence         # (currentTokenWeight, initialTokenWeight, token, selectedSentenceId, selectedSentenceWeight)
{
	return $_[0] * $_[4];
}

# computes the textrank of the tokens.
sub _getTextRankWeightOfTokens
{
	my %Parameters = @_;

	# use any textrank parameters if defined.
	my %textRankParameters;
	%textRankParameters = %{ $Parameters{textRankParameters} } if ((exists $Parameters{textRankParameters}) && (defined $Parameters{textRankParameters}));

	# if no sentences, return now.
	return {} unless exists $Parameters{listOfSentences};
	my $listOfSentences = $Parameters{listOfSentences};

	# build the list of tokens.
	my @listOfTokens = map { ($_->{listOfTokens}) } @$listOfSentences;

	# return the textrank of each token.
	return getTextrankOfListOfTokens(%textRankParameters, listOfTokens => \@listOfTokens);
}

# computes the frequency of the tokens.
sub _getFrequencyWeightOfTokens
{
  my %Parameters = @_;

  # if no sentences, return now.
  return {} unless exists $Parameters{listOfSentences};
  my $listOfSentences = $Parameters{listOfSentences};

  # compute total occurrence and frequency of the tokens.
  my $totalOccurrence = 0;
  my %tokenFrequency;

  foreach my $sentence (@$listOfSentences)
  {
    foreach my $token (@{$sentence->{listOfTokens}})
    {
      ++$tokenFrequency{$token};
      ++$totalOccurrence;
    }
  }
  $totalOccurrence = 1 if $totalOccurrence < 1;

  while (my ($token, undef) = each %tokenFrequency)
  {
    $tokenFrequency{$token} /= $totalOccurrence;
  }

  # return the frequency of each token.
  return \%tokenFrequency;
}

=head1 INSTALLATION

Use L<CPAN> to install the module and all its prerequisites:

  perl -MCPAN -e shell
  >install Text::Summarize

=head1 BUGS

Please email bugs reports or feature requests to C<bug-text-summarize@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Summarize>.  The author
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

information processing, summary, summaries, summarization, summarize, sumbasic, textrank

=head1 SEE ALSO

L<Log::Log4perl>, L<Text::Categorize::Textrank>, L<Text::Summarize::En>

=begin html

<p>The SumBasic algorithm for ranking sentences is from
<a href="http://bit.ly/sK5t7O">Beyond SumBasic: Task-Focused Summarization with Sentence Simplification and Lexical Expansion</a>
by L. Vanderwendea, H. Suzukia, C. Brocketta, and A. Nenkovab.</p>

=end html

=cut

1;

# The preceding line will help the module return a true value

