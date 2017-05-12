# -*- perl -*-

use Test::More;
BEGIN { use_ok( 'Text::Corpus::NewYorkTimes' ); }
BEGIN { use_ok( 'Text::Corpus::NewYorkTimes::Document' ); }
BEGIN { use_ok( 'Log::Log4perl' ); }
BEGIN { use_ok( 'File::Temp' ); }
BEGIN { use_ok( 'Data::Dump' ); }
use File::Temp qw(tempdir);

if (defined (%ENV) && (exists ($ENV{TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY}) || exists ($ENV{TEXT_CORPUS_NEWYORKTIMES_FILELIST})))
{
  # get the temporary directory for the log file.
  my $tmpDirectory = tempdir (CLEANUP => 1);
  ok (-d $tmpDirectory, 'Temporary directory created.');

  # initialize log4perl.
  initializeLogger ($tmpDirectory);

  # create the object.
  diag ("\nTesting requires finding all files in the corpus;\n");
  diag ("it will take a while.\n");
  my $corpus = Text::Corpus::NewYorkTimes->new ();
  isa_ok ($corpus, 'Text::Corpus::NewYorkTimes');

  # test access to the corpus files.
  ok ($corpus->test, 'Access to corpus.');
}
else
{
  diag ("\nTesting done without access to corpus.\n");
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
