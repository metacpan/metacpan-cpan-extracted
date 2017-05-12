#!/usr/bin/env perl

use strict;
use warnings;

{
  use Text::Corpus::Summaries::Wikipedia;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  $corpus->create;
  dump $corpus->getListOfXmlFiles;
  dump $corpus->getListOfTextFiles;
}

{
  use Text::Corpus::Summaries::Wikipedia;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  $corpus->create;
  dump $corpus->getListOfTextFiles;
}

{
  use Text::Corpus::Summaries::Wikipedia;
  use XML::Simple;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  foreach my $xmlFile (@{$corpus->getListOfXmlFiles})
  {
    my $article;
    eval { $article = XMLin ($xmlFile) };
    if ($@) { dump \$@; } else { dump $article; }
  }
}

{
  use Text::Corpus::Summaries::Wikipedia;
  use Statistics::Descriptive;
  use File::Slurp;
  use Encode;

  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  my $statistics = Statistics::Descriptive::Full->new;
  foreach my $textFilePair (@{$corpus->getListOfTextFiles})
  {
    my $summary = lc decode ('utf8', read_file ($textFilePair->{summary}, binmode => ':raw'));
    my %summaryWords = map {($_, 1)} split (/\P{Letter}/, $summary);
    my $totalUniqueSummaryWords = keys %summaryWords;
    next unless $totalUniqueSummaryWords;

    my $body = lc decode ('utf8', read_file ($textFilePair->{body}, binmode => ':raw'));
    map {delete $summaryWords{$_}} split (/\P{Letter}/, $body);
    my $totalUniqueSummaryWordsNotInBody = keys %summaryWords;

    $statistics->add_data (1 - $totalUniqueSummaryWordsNotInBody / $totalUniqueSummaryWords);
  }

  print 'count: ', $statistics->count(), "\n";
  print 'median: ', $statistics->median(), "\n";
  print 'mean: ', $statistics->mean(), "\n";
  print 'standard deviation: ', $statistics->standard_deviation(), "\n";
}
