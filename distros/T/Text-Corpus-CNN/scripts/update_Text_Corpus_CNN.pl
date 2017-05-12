#!/usr/bin/env perl

#12345678901234567890123456789012345678901234
#Script to update CNN news article corpus.

=head1 NAME

update_Text_Corpus_CNN.pl - Script to update CNN news article corpus.

=head1 SYNOPSIS

  update_Text_Corpus_CNN.pl [-d corpusDirectory -c -t -h]

=head1 DESCRIPTION

The script C<update_Text_Corpus_CNN.pl> may be used to create or update a temporary corpus of CNN news articles
for personal research and testing of information processing techniques. Read the
CNN Interactive Service Agreement to ensure you abide by it when using this script.

All errors and warnings are logged using L<Log::Log4perl> to the file C<corpusDirectory/log.txt>.

=head1 OPTIONS

=head2 C<-d corpusDirectory>

The option C<-d> sets the cache directory for the corpus of documents. If the directory does not exist, it will
be created. The default is a directory named C<'corpus_cnn'> in the current working directory.

=head2 C<-t>

If the option C<-t> is present, parsing tests will be performed on all the documents in the cache.

=head2 C<-v>

If the option C<-v> is present, then after each new document is fetched a message is
logged stating the number of documents remaining to fetch and the
approximate time to completion.

=head2 C<-h>

Causes documentation to be printed.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

cnn, cable news network, english corpus, information processing

=head1 SEE ALSO

=begin html

Read the <a href="http://www.cnn.com/interactive_legal.html">CNN Interactive Service Agreement</a> to ensure you abide by it
when using this script.

=end html

L<CHI>, L<Log::Log4perl>, L<Text::Corpus::CNN>, L<Text::Corpus::CNN::Document>

=cut

use strict;
use warnings;
use diagnostics;
use Text::Corpus::CNN;
use Text::Corpus::CNN::Document;
use Log::Log4perl;
use Proc::Pidfile;
use Getopt::Long;
use File::Basename;
use File::Path;
use Cwd qw(getcwd abs_path);
use Pod::Usage;
use Data::Dump qw(dump);

my $el = "\n";
my $corpusDirectory = "$ENV{HOME}/projects/corpora/cnn";
my $doParsingTest = 0;
my $helpMessage = 0;
my $verbose = 1;
my $logCacheHitsMisses = 0;
my $result = GetOptions ("d:s" => \$corpusDirectory, "t" => \$doParsingTest, "h|help" => \$helpMessage, "v|verbose" => \$verbose, "c" => \$logCacheHitsMisses);

# print info message
if ($helpMessage)
{
  pod2usage ({-verbose => 1, -output => \*STDOUT});
  exit 0;
}

# get the default path for the corpus directory.
unless (defined $corpusDirectory)
{
  $corpusDirectory = File::Spec->catfile (abs_path(getcwd), 'corpus_cnn');
}

# create the corpusDirectory.
mkpath ($corpusDirectory, 0, 0700);
unless (-e $corpusDirectory)
{
  die ("corpus directory '" . $corpusDirectory . "' does not exist and could not be created.");
}

# initialize the logging.
initializeLogger ($corpusDirectory);
my $logger = Log::Log4perl->get_logger();
$logger->info ("Started.\n");

# get the path to the pid file; used to ensure only one process running.
my $pid = File::Spec->catfile ($corpusDirectory, 'pid.txt');

# if another process running, exit silently; not even logged.
my $processInfo = Proc::Pidfile->new (pidfile => $pid, silent => 1);

# update the new list of files.
my $corpus = Text::Corpus::CNN->new(corpusDirectory => $corpusDirectory);
$corpus->update(verbose => $verbose, logCacheHitsMisses => $logCacheHitsMisses);

# test parsing of each article.
if ($doParsingTest)
{
  my $totalDocuments = $corpus->getTotalDocuments() . "\n";
  $logger->info ('total documents in cache is ' . $totalDocuments . ".\n");
  my $parsingProblems = 0;

  for (my $i = 0 ; $i < $totalDocuments ; $i++)
  {
    eval {
      my $document = $corpus->getDocument(index => $i);

      $document->getBody();
      $document->getCategories();
      $document->getContent();
      $document->getDate();
      $document->getDescription();
      $document->getHighlights();
      $document->getTitle();
      $document->getUri();
    };
    if ($@)
    {
      ++$parsingProblems;
    }
  }

  $logger->info ('total documents with parsing problems was ' . $parsingProblems . ".\n");
}
$logger->info ("Finished.\n");

# initializes the root logger.
sub initializeLogger
{
  my $LogFileDirectory = shift;
  my $logFilePath = File::Spec->catfile ($LogFileDirectory, 'log.txt');

  my $logConfig = q(
    log4perl.rootLogger                = INFO, Logfile
    log4perl.appender.Logfile          = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.mode     = append
    log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = --%P%n%d %p%n%l%n%m%n
    log4perl.appender.Screen           = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr    = 0
    log4perl.appender.Screen.layout    = Log::Log4perl::Layout::SimpleLayout
  );
  $logConfig .= 'log4perl.appender.Logfile.filename = ' . $logFilePath . "\n";
  Log::Log4perl::init (\$logConfig);
}

