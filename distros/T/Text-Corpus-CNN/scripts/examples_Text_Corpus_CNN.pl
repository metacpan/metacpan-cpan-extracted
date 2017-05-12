#!/usr/bin/env perl

# contains all the examples in the POD documentation for the module.

use strict;
use warnings;

my $corpusDirectory;
$corpusDirectory = $ENV{TEXT_CORPUS_CNN_CORPUSDIRECTORY} if exists $ENV{TEXT_CORPUS_CNN_CORPUSDIRECTORY};
die '$corpusDirectory' . " not defined.\n" unless defined $corpusDirectory;

{
  use Cwd;
  use File::Spec;
  use Text::Corpus::CNN;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_cnn');
  my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
  $corpus->update (verbose => 1);
  dump $corpus->getTotalDocuments;
}

{
  use Cwd;
  use File::Spec;
  use Text::Corpus::CNN;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_cnn');
  my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
  $corpus->update (verbose => 1);
  my $document = $corpus->getDocument (index => 0);
  dump $document->getBody;
  dump $document->getCategories;
  dump $document->getContent;
  dump $document->getDate;
  dump $document->getDescription;
  dump $document->getHighlights;
  dump $document->getTitle;
  dump $document->getUri;
}

{
  use Cwd;
  use File::Spec;
  use Text::Corpus::CNN;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_cnn');
  my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
  dump $corpus->getURIsInCorpus;
}

{
  use Cwd;
  use File::Spec;
  use Text::Corpus::CNN;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_cnn');
  my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
  my $totalDocuments = $corpus->getTotalDocuments;
  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    eval
      {
        my $document = $corpus->getDocument(index => $i);
        next unless defined $document;
        my %documentInfo;
        $documentInfo{title} = $document->getTitle();
        $documentInfo{body} = $document->getBody();
        $documentInfo{content} = $document->getContent();
        $documentInfo{categories} = $document->getCategories();
        $documentInfo{description} = $document->getDescription();
        $documentInfo{highlights} = $document->getHighlights();
        $documentInfo{uri} = $document->getUri();
        dump \%documentInfo;
      };
  }
}

{
  use Cwd;
  use File::Spec;
  use Text::Corpus::CNN;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_cnn');
  my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
  my $totalDocuments = $corpus->getTotalDocuments;
  my %allCategories;
  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    eval
      {
        my $document = $corpus->getDocument(index => $i);
        next unless defined $document;
        my $categories = $document->getCategories();
        foreach my $category (@$categories)
        {
          my $categoryNormalized = lc $category;
          $allCategories{$categoryNormalized} = [0, $category] unless exists $allCategories{$categoryNormalized};
          $allCategories{$categoryNormalized}->[0]++;
        }
      };
  }
  my @allCategories = sort {$b->[0] <=> $a->[0]} values %allCategories;
  my $topCategories = 10;
  $topCategories = @allCategories if (@allCategories < $topCategories);
  for (my $i = 0; $i < $topCategories; $i++)
  {
    print join (' ', @{$allCategories[$i]}) . "\n";
  }
}
