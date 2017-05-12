#!/usr/bin/env perl

use strict;
use warnings;

my $corpusDirectory;
$corpusDirectory = $ENV{TEXT_CORPUS_INSPEC_CORPUSDIRECTORY} if exists $ENV{TEXT_CORPUS_INSPEC_CORPUSDIRECTORY};
die '$corpusDirectory' . " not defined.\n" unless defined $corpusDirectory;

{
  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  dump $corpus->getTotalDocuments;
}

{
  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  dump $corpus->test; 
}

{
  use Text::Corpus::Inspec;
  use Text::Corpus::Inspec::Document;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  my $document = $corpus->getDocument (index => 0);
  dump $document->getBody;
  dump $document->getCategories;
  dump $document->getContent;
  dump $document->getTitle;
  dump $document->getUri;
}

{
  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  my $totalDocuments = $corpus->getTotalDocuments ();
  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    eval
    {
      my $document = $corpus->getDocument (index => $i);
      my %documentInfo;
      $documentInfo{title} = $document->getTitle ();
      $documentInfo{body} = $document->getBody ();
      $documentInfo{content} = $document->getContent ();
      $documentInfo{categories} = $document->getCategories ();
      $documentInfo{uri} = $document->getUri ();
      dump \%documentInfo;
    };
  } 
}
