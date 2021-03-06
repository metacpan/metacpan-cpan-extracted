package Text::Summarize::En;
use strict;
use warnings;
use Log::Log4perl;
use Text::Summarize;
use Text::StemTagPOS;
use Text::Categorize::Textrank;
use Data::Dump qw(dump);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.50';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(getSummaryUsingSumbasic);
    @EXPORT_OK   = qw(getSummaryUsingSumbasic);
    %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Routine to summarize English text.

=head1 NAME

C<Text::Summarize::En> - Routine to summarize English text.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Text::Summarize::En;
  use Data::Dump qw(dump);
  my $summarizerEn = Text::Summarize::En->new();
  my $text         = 'All people are equal. All men are equal. All are equal.';
  dump $summarizerEn->getSummaryUsingSumbasic(listOfText => [$text]);

=head1 DESCRIPTION

C<Text::Summarize> contains routines for ranking the sentences in English text
for inclusion in a summary using the sumBasic algorithm.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of the C<Text::Summarize::En>
class with the following parameters:

=over

=item C<endingSentenceTag>

 endingSentenceTag => 'PP'

C<endingSentenceTag> is the part-of-speech tag that should be used to indicate
the end of a sentence. The default is 'PP'. The value of this tag must be
a tag generated by the module L<Lingua::EN::Tagger>.

=item C<listOfPOSTypesToKeep>

 listOfPOSTypesToKeep => [qw(CONTENT_WORDS)]

The sumBasic algorithm preprocesses the text so that only certain parts-of-speech (POS) are retained
and used to rank the sentences. The module L<Lingua::EN::Tagger> is used
to tag the parts-of-speech of the text. The parts-of-speech retained can be specified by
word types, where the type is a combination of 'ALL', 'ADJECTIVES', 'ADVERBS', 'CONTENT_ADVERBS', 'CONTENT_WORDS', 'NOUNS', 'PUNCTUATION',
'TEXTRANK_WORDS', or 'VERBS'. The default is C<[qw(CONTENT_WORDS)]>, which equates to
C<[qw(CONTENT_ADVERBS, VERBS, ADJECTIVES, NOUNS)]>.

=item C<listOfPOSTagsToKeep>

 listOfPOSTagsToKeep => [...]

C<listOfPOSTagsToKeep> provides finer control over the
parts-of-speech to be retained when filtering the tagged text. For a list
of all the possible tags call C<getListOfPartOfSpeechTags()>.

=back

=cut

sub new
{
  my ($Class, %Parameters) = @_;
  my $Self = bless ({}, ref ($Class) || $Class);

  # set the default POS type to keep to CONTENT_WORDS.
  $Parameters{listOfPOSTypesToKeep} = [qw(CONTENT_WORDS)] if (!exists($Parameters{listOfPOSTypesToKeep}) && !exists($Parameters{listOfPOSTagsToKeep}));

  # get the POS/stemmer engine.
  $Self->{posTaggerStemmerEngine} = Text::StemTagPOS->new (%Parameters);

  return $Self;
}

=head1 METHODS

=head2 C<getSummaryUsingSumbasic>

C<getSummaryUsingSumbasic> computes the summary of text using the sumBasic algorithm.

=over

=item C<listOfStemmedTaggedSentences>

 listOfStemmedTaggedSentences => [...]

C<listOfStemmedTaggedSentences> is an array reference containing the list of stemmed and part-of-speech
tagged sentences from L<Text::StemTagPos>. If C<listOfStemmedTaggedSentences> is not defined, then the
text to be processed should be provided via C<listOfText>.

=item C<listOfText>

 listOfText => [...]

C<listOfText> is an array reference containing the strings of text to be summarized. C<listOfText> is
only used if C<listOfStemmedTaggedSentences> is undefined.

=item C<tokenWeight>

 tokenWeight => {}

C<tokenWeights> is an optional hash reference that can provide the weights for
the tokens provided by C<listOfStemmedTaggedSentences> or C<listOfText>. If C<tokenWeights> is not defined
then the weight of a token is just its frequency of occurrence in the filtered text. If C<textRankParameters>
is defined, then the token weights are computed using L<Text::Categorize::Textrank>.

=item C<textRankParameters>

  textRankParameters => undef

If C<textRankParameters> is defined, then the token weights for the sumBasic algorithm
are computed using L<Text::Categorize::Textrank>. The parameters to use for L<Text::Categorize::Textrank>,
excluding the C<listOfTokens> parameters, can be set using the hash reference defined by C<textRankParameters>.
For example, C<textRankParameters =E<gt> {directedGraph =E<gt> 1}> would make the textrank weights
be computed using a directed token graph.

=back

=cut

sub getSummaryUsingSumbasic
{
  my ($Self, %Parameters) = @_;

  # get the text to process.
  my $listOfStemmedTaggedSentences;
  if (exists ($Parameters{listOfStemmedTaggedSentences}))
  {
    $listOfStemmedTaggedSentences = $Parameters{listOfStemmedTaggedSentences};
  }
  elsif (exists($Parameters{listOfText}))
  {
    $listOfStemmedTaggedSentences = $Self->{posTaggerStemmerEngine}->getStemmedAndTaggedText ($Parameters{listOfText});
  }
  else
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie("error: one of the parameters 'listOfStemmedTaggedSentences' or 'listOfText' must be defined.");
  }

  # set the default POS type to keep to CONTENT_WORDS.
  my $listOfPOSTypesToKeep = ['CONTENT_WORDS'];
  $listOfPOSTypesToKeep = ['TEXTRANK_WORDS'] if ((exists $Parameters{textRankParameters}) && (defined $Parameters{textRankParameters}));
  $listOfPOSTypesToKeep = $Parameters{listOfPOSTypesToKeep} if exists $Parameters{listOfPOSTypesToKeep};

  # filter the text down.
  my $listOfContentSentences = $Self->{posTaggerStemmerEngine}->getTaggedTextToKeep (listOfPOSTypesToKeep => $listOfPOSTypesToKeep, listOfStemmedTaggedSentences => $listOfStemmedTaggedSentences);

  # convert the stemmed tagged text to lists of only the stemmed words.
  my @listOfSentences;
  my $sentenceIndex = 0;
  my @listOfTokens;
  foreach my $stemmedTaggedSentence (@$listOfContentSentences)
  {
    if (@$stemmedTaggedSentence > 0)
    {
      my @sentenceTokensOnly = map {$_->[Text::StemTagPOS::WORD_STEMMED]} @$stemmedTaggedSentence;
      push @listOfTokens, \@sentenceTokensOnly;
      push @listOfSentences, {id => $sentenceIndex, listOfTokens => \@sentenceTokensOnly};
    }
    ++$sentenceIndex;
  }

  # get the summary ranking of the sentences.
  my $idScore = getSumbasicRankingOfSentences (%Parameters, listOfSentences => \@listOfSentences);

  # return the ranked sentences and the stemmed tagged sentences.
  return {idScore => $idScore, listOfStemmedTaggedSentences => $listOfStemmedTaggedSentences};
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

L<Log::Log4perl>, L<Text::Categorize::Textrank>, L<Text::Summarize>

=begin html

<p>The SumBasic algorithm for ranking sentences is from
<a href="http://bit.ly/sK5t7O">Beyond SumBasic: Task-Focused Summarization with Sentence Simplification and Lexical Expansion</a>
by L. Vanderwendea, H. Suzukia, C. Brocketta, and A. Nenkovab.</p>

=end html

=cut

1;

# The preceding line will help the module return a true value