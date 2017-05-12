# -*- perl -*-

use Test::More;
BEGIN { use_ok( 'Text::Corpus::Summaries::Wikipedia' ); }
BEGIN { use_ok( 'File::Temp' ); }
BEGIN { use_ok( 'File::Spec' ); }

# check if tests using network access should be run.
if (%ENV && exists ($ENV{TEXT_CORPUS_SUMMARIES_WIKIPEDIA_FULL_TESTING}) && $ENV{TEXT_CORPUS_SUMMARIES_WIKIPEDIA_FULL_TESTING})
{
  use File::Temp qw(tempdir);
  use LWP::Simple;

  # get the temporary directory for the corpus for testing.
  my $corpusDirectory = tempdir (CLEANUP => 1);
  ok (-d $corpusDirectory, 'Temporary directory created.');
  diag ("\nTesting with network access.\n");

  # make sure there is network access
  my $testContent = get ('http://www.example.com');
  ok (defined $testContent, 'Testing network access.');

  # let the user know this may take some time.
  diag ("Following tests can take a 10 to 30 minutes.\n");

  # get the list of all supported language codes.
  my @listOfLanguageCodes = Text::Corpus::Summaries::Wikipedia::getListOfSupportedLanguageCodes();

  # build the corpus for each language.
  foreach my $languageCode (@listOfLanguageCodes)
  {
    eval
    {
      my $corpus = Text::Corpus::Summaries::Wikipedia->new (languageCode => $languageCode, corpusDirectory => $corpusDirectory);
      $corpus->create (maxProcesses => 1, test => 3);
    };
    if (@_)
    {
      ok (0, "Checking language code $languageCode.\n");
    }
    else
    {
      ok (1, "Checking language code $languageCode.\n");
    }
  }
}
else
{
  diag ("\nTests needing network access skipped.\nDefine environment variable\nTEXT_CORPUS_SUMMARIES_WIKIPEDIA_FULL_TESTING to true\nto run complete tests.\n");
}

done_testing();
