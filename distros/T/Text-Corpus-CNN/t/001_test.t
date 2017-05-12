# -*- perl -*-

use Test::More;
BEGIN { use_ok( 'Text::Corpus::CNN' ); }
BEGIN { use_ok( 'Text::Corpus::CNN::Document' ); }
BEGIN { use_ok( 'Log::Log4perl' ); }
BEGIN { use_ok( 'File::Temp' ); }
BEGIN { use_ok( 'LWP::Simple' ); }
BEGIN { use_ok( 'File::Spec' ); }
use File::Temp qw(tempdir);

# get the temporary directory for the corpus for testing.
my $corpusDirectory = tempdir (CLEANUP => 1);
ok (-d $corpusDirectory, 'Temporary directory created.');

# initialize log4perl.
initializeLogger ($corpusDirectory);

# make sure a Text::Corpus::CNN is returned.
my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
isa_ok ($corpus, 'Text::Corpus::CNN');

# prompt for request to run tests that require network acccess.
if (%ENV && exists ($ENV{TEXT_CORPUS_CNN_FULL_TESTING}) && $ENV{TEXT_CORPUS_CNN_FULL_TESTING})
{
    diag ("\nTesting with network access.\n");

    # make sure there is network access
    my $testContent = get ('http://www.cnn.com');
    ok (0, 'Could not fetch page www.cnn.com.') unless defined $testContent;

    # should fetch at least one document and parse it.
    diag ("Next test can take up to two minutes.\n");
    ok (0, 'Checking update().') unless $corpus->update (testing => 1, verbose => 1);

    # make sure at least one document was obtained.
    ok (0, 'No documents retrieved.') unless $corpus->getTotalDocuments;

    # ensure the document can be parsed.
    my @ignore;
    eval {
      my $document = $corpus->getDocument(index => 0);
      isa_ok ($document, 'Text::Corpus::CNN::Document');
      push @ignore, $document->getTitle();
      push @ignore, $document->getBody();
      push @ignore, $document->getContent();
      push @ignore, $document->getCategories();
      push @ignore, $document->getDate();
      push @ignore, $document->getDescription();
      push @ignore, $document->getHighlights();
      push @ignore, $document->getUri();
    };
    if ($@)
    {
      ok (0, 'Parsing errors.');
    }
    else
    {
      ok ((@ignore == 8), 'Parsing completed.');
    }
}
else
{
  diag ("\nTests needing network access skipped.\nDefine environment variable\nTEXT_CORPUS_CNN_FULL_TESTING to 1\nto run complete tests.\n");
}

done_testing();

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
    log4perl.appender.Screen.stderr    = 1
    log4perl.appender.Screen.layout    = Log::Log4perl::Layout::SimpleLayout
  );
  $logConfig .= 'log4perl.appender.Logfile.filename = ' . $logFilePath . "\n";
  Log::Log4perl::init (\$logConfig);
}
