#!/usr/bin/env perl

use strict;
use warnings;

my $corpusDirectory;
$corpusDirectory = $ENV{TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY} if exists $ENV{TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY};
my $fileList = 'filelist.txt';
$fileList = $ENV{TEXT_CORPUS_NEWYORKTIMES_FILELIST} if exists $ENV{TEXT_CORPUS_NEWYORKTIMES_FILELIST};
die '$corpusDirectory' . " not defined.\n" unless defined $corpusDirectory;

{
  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
  dump $corpus->getTotalDocuments;
}

{
  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
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
  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
  dump $corpus->test;
}

{
  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
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
        $documentInfo{uri} = $document->getUri();
        dump \%documentInfo;
      };
  }
}
