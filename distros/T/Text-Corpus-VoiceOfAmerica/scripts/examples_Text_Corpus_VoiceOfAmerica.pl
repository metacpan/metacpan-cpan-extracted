#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;

my $corpusDirectory;
$corpusDirectory = $ENV{TEXT_CORPUS_VOICEOFAMERICA_CORPUSDIRECTORY} if exists $ENV{TEXT_CORPUS_VOICEOFAMERICA_CORPUSDIRECTORY};
die '$corpusDirectory' . " not defined.\n" unless defined $corpusDirectory;

{
  use Cwd;
  use File::Spec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  use Text::Corpus::VoiceOfAmerica;
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_voa');
  my $corpus = Text::Corpus::VoiceOfAmerica->new (corpusDirectory => $corpusDirectory);
  $corpus->update (testing => 1, verbose => 1);
  my $document = $corpus->getDocument (index => 0);
  dump $document->getBody;
  dump $document->getCategories;
  dump $document->getContent;
  dump $document->getDate;
  dump $document->getDescription;
  dump $document->getTitle;
  dump $document->getUri;
}

{
  use Cwd;
  use File::Spec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  use Text::Corpus::VoiceOfAmerica;
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_voa');
  my $corpus = Text::Corpus::VoiceOfAmerica->new (corpusDirectory => $corpusDirectory);
  $corpus->update (testing => 1, verbose => 1);
  dump $corpus->getURIsInCorpus;
}

{
  use Cwd;
  use File::Spec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  use Text::Corpus::VoiceOfAmerica;
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_voa');
  my $corpus = Text::Corpus::VoiceOfAmerica->new (corpusDirectory => $corpusDirectory);
  $corpus->update (testing => 1, verbose => 1);
  dump $corpus->getTotalDocuments;
}

{
  use Cwd;
  use File::Spec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  use Text::Corpus::VoiceOfAmerica;
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_voa');
  my $corpus = Text::Corpus::VoiceOfAmerica->new (corpusDirectory => $corpusDirectory);
  $corpus->update (testing => 1, verbose => 1);
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
        $documentInfo{date} = $document->getDate();
        $documentInfo{content} = $document->getContent();
        $documentInfo{categories} = $document->getCategories();
        $documentInfo{description} = $document->getDescription();
        $documentInfo{uri} = $document->getUri();
        dump \%documentInfo;
      };
  }
}
