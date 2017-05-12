package Text::Corpus::Summaries::Wikipedia;

use utf8;
use strict;
use warnings;
use Carp;

use Cwd;
use Encode;
use Log::Log4perl;
use File::Path qw(make_path);
use LWP::UserAgent;
use Forks::Super;
use HTML::TreeBuilder::XPath;
use utf8;
use Digest::MD5 qw(md5_hex);
use Date::Manip;
use File::Copy;
use XML::Code;
use Data::Dump qw(dump);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.22';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME
 
C<Text::Corpus::Summaries::Wikipedia> - Creates corpora for summarization testing.

=head1 SYNOPSIS

  use Text::Corpus::Summaries::Wikipedia;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  $corpus->create;
  dump $corpus->getListOfXmlFiles;

=head1 DESCRIPTION

C<Text::Corpus::Summaries::Wikipedia> creates corpora for single document summarization testing
using the featured articles of various Wikipedias.

A criterion for an article in a Wikipedia to be I<featured> is that it
have a well written lead section, or introduction. So the featured articles
of a Wikipedia can make an excellent corpus for testing single document summarization methods.
This module creates a corpus from the featured articles of a Wikipedia by fetching
and saving their content as HTML, text, and XML, with the appropriate sections
labeled as either C<summary> or C<body>.

=begin html

The Wikimedia <a href="http://meta.wikimedia.org/wiki/Wikipedia_featured_articles">featured articles</a> page
has the number of featured articles on various Wikipedias including links to their rating criteria (if they exist). For
example, the English Wikipedia has an article on the
<a href="http://en.wikipedia.org/wiki/Wikipedia:Featured_article_criteria">criteria for a featured article</a>
and the criteria for a good <a href="http://en.wikipedia.org/wiki/Wikipedia:Lead_section">introduction</a>.

=end html

=head1 CONSTRUCTOR

=head2 C<new>

The constructor C<new> creates an instance of the C<Text::Corpus::Summaries::Wikipedia>
class with the following parameters:

=over

=item C<languageCode>

 languageCode => 'en'

C<languageCode> is the language code of the Wikipedia from which the
corpus of featured articles are to be created. The supported language codes are
C<af>:Afrikaans, C<ar>:Arabic, C<az>:Azerbaijani, C<bg>:Bulgarian, C<bs>:Bosnian, C<ca>:Catalan, 
C<cs>:Czech, C<de>:German, C<el>:Greek, C<en>:English, C<eo>:Esperanto, C<es>:Spanish, C<eu>:Basque, 
C<fa>:Persian, C<fi>:Finnish, C<fr>:French, C<he>:Hebrew, C<hr>:Croatian, C<hu>:Hungarian, 
C<id>:Indonesian, C<it>:Italian, C<ja>:Japanese, C<jv>:Javanese, C<ka>:Georgian, C<kk>:Kazakh, 
C<km>:Khmer, C<ko>:Korean, C<li>:Limburgish, C<lv>:Latvian, C<ml>:Malayalam, C<mr>:Marathi, 
C<ms>:Malay, C<mzn>:Mazandarani, C<nl>:Dutch, C<nn>:Norwegian (Nynorsk), C<no>:Norwegian (Bokm?l), 
C<pl>:Polish, C<pt>:Portuguese, C<ro>:Romanian, C<ru>:Russian, C<sh>:Serbo-Croatian, 
C<simple>:Simple English, C<sk>:Slovak, C<sl>:Slovenian, C<sr>:Serbian, C<sv>:Swedish, 
C<sw>:Swahili, C<ta>:Tamil, C<th>:Thai, C<tl>:Tagalog, C<tr>:Turkish, C<tt>:Tatar, 
C<uk>:Ukrainian, C<ur>:Urdu, C<vi>:Vietnamese, C<vo>:Volap?k, and C<zh>:Chinese.
If the language code is C<all>, then the corpus for each supported language is
created (which takes a long time). The default is C<en>.

=item C<corpusDirectory>

 corpusDirectory => 'cwd'

C<corpusDirectory> is the corpus directory that the summaries and articles will
be stored in; the directory is created if it does not exist. The default
is the C<cwd>.

A language subdirectory is created at C<corpusDirectory/languageCode> that
will contain the directories C<log>, C<html>, C<unparsable>, C<text>, and C<xml>.  The directory
C<log> will contain the file C<log.txt> that all errors, warnings, and
informational messages are logged to using L<Log::Log4perl>. The directory
C<html> will contain copies of the HTML versions of the featured
article pages fetched using L<LWP>.
The directory C<text>
will contain two files for each article; one file will end with C<_body.txt>
and contain the body text of the article, the other will end with
C<_summary.txt> and will contain the summary. The directory C<unparsable> will contain the
HTML files that could not be parsed into I<body> and I<summary> sections. All files are
UTF-8 encoded.

=back

=cut

sub new
{
  my ($Class, %Parameters) = @_;
  my $Self = bless {}, ref($Class) || $Class;

  # timeOfLast fetch is the time of the last page fetch.
  $Self->{timeOfLastFetch} = 0;
  $Self->{minSecondsBetweenFetches} = 2;

  # make the user agent
  $Self->{userAgent} = LWP::UserAgent->new;
  $Self->{userAgent}->agent ("Text::Corpus::Summaries::Wikipedia/$VERSION");

  # get the corpus directory.
  $Parameters{corpusDirectory} = getcwd unless exists $Parameters{corpusDirectory};

  # create the corpusDirectory if it does not exist.
  unless (-d $Parameters{corpusDirectory})
  {
    make_path ($Parameters{corpusDirectory}, {verbose => 0, mode => 0700});
  }
  unless (-d $Parameters{corpusDirectory})
  {
    croak ("Could not create directory '" . $Parameters{corpusDirectory} . "'.\n");
  }
  $Self->{corpusDirectory} = $Parameters{corpusDirectory};

  # set the log file to $Self->{corpusDirectory}/log.txt at first.
  $Self->initializeLogger (logDirectory => $Self->{corpusDirectory});

  # make the featured subdirectory.
  $Self->{featuredDirectory} = File::Spec->catfile ($Self->{corpusDirectory}, 'featured');
  make_path ($Self->{featuredDirectory}, {verbose => 0, mode => 0700});
  unless (-d $Self->{featuredDirectory})
  {
    croak ("Could not create directory '" . $Self->{featuredDirectory} . "'.\n");
  }

  # set the links to the featured article pages on the wikipedias and the xpath expressions
  # to extract the links from the pages.
  $Self->_getFeaturedArticleLinkXpathPerLanguage ();

  # get the language code.
  $Parameters{languageCode} = 'en' unless exists $Parameters{languageCode};
  $Self->{languageCode} = lc $Parameters{languageCode};
  $Self->{languageCode} = $1 if ($Self->{languageCode} =~ /^([a-z\-]+)/);
  unless (defined $Self->_getFeatureArticleUrlAndXPathExpression ())
  {
    croak "Language with code '" . $Parameters{languageCode} . "' is not supported.\n";
  }
  $Self->{languageDirectory} = File::Spec->catfile ($Parameters{corpusDirectory}, $Parameters{languageCode});

  # create the languageDirectory if it does not exist.
  unless (-d $Self->{languageDirectory})
  {
    make_path ($Self->{languageDirectory}, {verbose => 0, mode => 0700});
  }
  unless (-d $Self->{languageDirectory})
  {
    croak ("Could not create directory '" . $Self->{languageDirectory} . "'.\n");
  }

  # make the log subdirectory.
  $Self->{logDirectory} = File::Spec->catfile ($Self->{languageDirectory}, 'log');
  make_path ($Self->{logDirectory}, {verbose => 0, mode => 0700});
  unless (-d $Self->{logDirectory})
  {
    croak ("Could not create directory '" . $Self->{logDirectory} . "'.\n");
  }

  # initialize log4perl system to the log file for the language.
  $Self->initializeLogger;

  # make the text subdirectory.
  $Self->{textDirectory} = File::Spec->catfile ($Self->{languageDirectory}, 'text');
  make_path ($Self->{textDirectory}, {verbose => 0, mode => 0700});
  unless (-d $Self->{textDirectory})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not create directory '" . $Self->{textDirectory} . "'.\n");
  }

  # make the xml subdirectory.
  $Self->{xmlDirectory} = File::Spec->catfile ($Self->{languageDirectory}, 'xml');
  make_path ($Self->{xmlDirectory}, {verbose => 0, mode => 0700});
  unless (-d $Self->{xmlDirectory})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not create directory '" . $Self->{xmlDirectory} . "'.\n");
  }

  # make the html subdirectory.
  $Self->{htmlDirectory} = File::Spec->catfile ($Self->{languageDirectory}, 'html');
  make_path ($Self->{htmlDirectory}, {verbose => 0, mode => 0700});
  unless (-d $Self->{htmlDirectory})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not create directory '" . $Self->{htmlDirectory} . "'.\n");
  }

  # make the unparsed subdirectory.
  $Self->{unparsableDirectory} = File::Spec->catfile ($Self->{languageDirectory}, 'unparsable');
  make_path ($Self->{unparsableDirectory}, {verbose => 0, mode => 0700});
  unless (-d $Self->{unparsableDirectory})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not create directory '" . $Self->{unparsableDirectory} . "'.\n");
  }

  # set the hash of the mapping from the language codes to their English name
  $Self->_setWikipediaLanguageCodes;

  # set the information about the features articles (total counts, last update time).
  $Self->_setWikipediaFeatureArticleInfo;

  return $Self;
}


=head1 METHODS

=head2 C<create>

The method C<create> fetches the featured articles and creates the text and
XML versions of the files.

  use Text::Corpus::Summaries::Wikipedia;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  $corpus->create;
  dump $corpus->getListOfXmlFiles;
  dump $corpus->getListOfTextFiles;

=over

=item C<maxProcesses>

 maxProcesses => 1

C<maxProcesses> is the maximum number of processes that can be running
simultaneously to parse the files. Parsing the files for the summary
and body sections may be computational intensive so the module L<Forks::Super> is used
for parallelization. The default is one.

=item C<test>

 test => 0

If C<test> is a positive integer than it will be treated as the maximum number of pages that
may be fetched and parsed. The default is zero, meaning all possible pages are fetched and
parsed.

=back

=cut

sub create
{
  my ($Self, %Parameters) = @_;

  # get the list of featured article titles.
  my $listOfUrls = $Self->_getListOfFeaturedArticleUrls ();

  # set the maximum number of processes to use to parse the articles.
  my $maxProcesses = 1;
  $maxProcesses = int abs $Parameters{maxProcesses} if exists $Parameters{maxProcesses};
  $maxProcesses = 1 if ($maxProcesses < 1);
  $Forks::Super::MAX_PROC = $maxProcesses;
  $Forks::Super::ON_BUSY = 'block';

  # fetch each article and parse out the summary and body.
  for (my $i = 0; $i < @$listOfUrls; $i++)
  {
    my $url = $listOfUrls->[$i];

    # use the md5 hex of the title as the file name since the title may be nonprintable and
    # in some cases it is too long to be a file name.
    my $fileBasename = md5_hex (encode_utf8 ($url)) . '.html';
    my $htmlFile = File::Spec->catfile ($Self->{htmlDirectory}, $fileBasename);

    # convert the page title to utf8
    $Self->_getPage (url => $url, outputFile => $htmlFile) if ($Self->_isFileTooOld (filePath => $htmlFile));

    if ($maxProcesses == 1)
    {
      $Self->parseArticlePage (htmlFile => $htmlFile);
    }
    else
    {
      my $pid = fork { sub => \&parseArticlePage, args => [$Self, 'htmlFile', $htmlFile] };
    }

    # if testing fetch just a few articles.
    return undef if (exists ($Parameters{test}) && $Parameters{test} && ($i > $Parameters{test}));
  }
}


=head2 C<recreate>

The method C<recreate> recreates the text and XML versions of the files
from the list of previously fetched HTML files in the C<html> directory.

  use Text::Corpus::Summaries::Wikipedia;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  $corpus->recreate;
  dump $corpus->getListOfXmlFiles;
  dump $corpus->getListOfTextFiles;

=over

=item C<maxProcesses>

 maxProcesses => 1

C<maxProcesses> is the maximum number of processes that can be running
simultaneously to parse the files. Parsing the files for the summary
and body sections may be computational intensive so the module L<Forks::Super> is used
for parallelization. The default is one.

=item C<test>

 test => 0

If C<test> is a positive integer than it will be treated as the maximum number of pages that
may be parsed. The default is zero, meaning all possible pages are parsed.

=back

=cut

sub recreate
{
  my ($Self, %Parameters) = @_;

  # get the list of featured article titles.
  my $listOfHtmlFeatureArticleFiles = $Self->_getListOfHtmlFeatureArticleFiles ();

  # set the maximum number of processes to use to parse the articles.
  my $maxProcesses = 1;
  $maxProcesses = int abs $Parameters{maxProcesses} if exists $Parameters{maxProcesses};
  $maxProcesses = 1 if ($maxProcesses < 1);
  $Forks::Super::MAX_PROC = $maxProcesses;
  $Forks::Super::ON_BUSY = 'block';

  # fetch each article and parse out the text.
  for (my $i = 0; $i < @$listOfHtmlFeatureArticleFiles; $i++)
  {
    my $htmlFile = $listOfHtmlFeatureArticleFiles->[$i];

    if ($maxProcesses == 1)
    {
      $Self->parseArticlePage (htmlFile => $htmlFile);
    }
    else
    {
      my $pid = fork { sub => \&parseArticlePage, args => [$Self, 'htmlFile', $htmlFile] };
    }

    # if testing fetch just a few articles.
    return undef if (exists ($Parameters{test}) && $Parameters{test} && ($i > $Parameters{test}));
  }
}


=head2 C<getListOfTextFiles>

The method C<getListOfTextFiles> returns an array reference with each item in
the list having the form C<{body =E<gt> 'path_to_body_file', summary =E<gt> 'path_to_summary_file'}>.

  use Text::Corpus::Summaries::Wikipedia;
  use Data::Dump qw(dump);
  my $corpus = Text::Corpus::Summaries::Wikipedia->new;
  $corpus->create;
  dump $corpus->getListOfTextFiles;

=cut

sub getListOfTextFiles
{
  my $Self = $_[0];

  # open the xml directory for reading and die if it cannot be.
  local *DIR;
  unless (opendir (DIR, $Self->{textDirectory}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open directory '" . $Self->{textDirectory} . "' for reading.\n");
  }

  # get the list of all xml files in the directory.
  my @listOfTextFiles = grep { /_(body|summary)\.txt$/ }readdir DIR;
  close DIR;

  # create the pairs of files.
  my %listOfTextFiles;
  foreach my $file (@listOfTextFiles)
  {
    if ($file =~ /_body\.txt$/)
    {
      my $name = substr ($file, 0, length ($file) - length ('_body.txt'));
      $listOfTextFiles{$name} = {} unless defined $listOfTextFiles{$name};
      $listOfTextFiles{$name}->{body} = $file;
    }
    else
    {
      my $name = substr ($file, 0, length ($file) - length ('_summary.txt'));
      $listOfTextFiles{$name} = {} unless defined $listOfTextFiles{$name};
      $listOfTextFiles{$name}->{summary} = $file;
    }
  }

  # delete any names in the hash that are missing a body or content file.
  foreach my $name (keys %listOfTextFiles)
  {
    unless (exists ($listOfTextFiles{$name}->{body}))
    {
      delete $listOfTextFiles{$name};
      next;
    }
    unless (exists ($listOfTextFiles{$name}->{summary}))
    {
      delete $listOfTextFiles{$name};
      next;
    }
  }
  @listOfTextFiles = values %listOfTextFiles;

  # log a warning if no text files found.
  unless (@listOfTextFiles)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("No text files found in '" . $Self->{textDirectory} . "'.\n");
  }

  # convert the paths in the list to full absolute paths.
  my $basePath = Cwd::realpath ($Self->{textDirectory});
  foreach my $pair (@listOfTextFiles)
  {
    $pair->{body} = File::Spec->catfile ($basePath, $pair->{body});
    $pair->{summary} = File::Spec->catfile ($basePath, $pair->{summary});
  }

  return \@listOfTextFiles;
}


=head2 C<getListOfXmlFiles>

The method C<getListOfXmlFiles> returns an array reference containing the path
to each XML file.

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

=cut

sub getListOfXmlFiles
{
  my $Self = $_[0];

  # open the xml directory for reading and die if it cannot be.
  local *DIR;
  unless (opendir (DIR, $Self->{xmlDirectory}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open directory '" . $Self->{xmlDirectory} . "' for reading.\n");
  }

  # get the list of all xml files in the directory.
  my @listOfXmlFiles = grep { /\.xml$/ } readdir DIR;
  close DIR;

  # log a warning if not XML files found.
  unless (@listOfXmlFiles)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("No XML files found in '" . $Self->{xmlDirectory} . "'.\n");
  }

  # convert the paths in the list to full absolute paths.
  my $basePath = Cwd::realpath ($Self->{xmlDirectory});
  @listOfXmlFiles = map {File::Spec->catfile ($basePath, $_)} @listOfXmlFiles;

  return \@listOfXmlFiles;
}

# returns an array reference listing the HTML featured article files in the
# htmlDirectory directory.
sub _getListOfHtmlFeatureArticleFiles
{
  my $Self = $_[0];

  # open the html directory for reading and die if it cannot be.
  local *DIR;
  unless (opendir (DIR, $Self->{htmlDirectory}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open directory '" . $Self->{htmlDirectory} . "' for reading.\n");
  }

  # get the list of all html files in the directory.
  my @listOfHtmlFeatureArticleFiles =  map { File::Spec->catfile ($Self->{htmlDirectory}, $_) } grep { /\.html$/ } readdir DIR;
  close DIR;

  # log a warning if no HTML files found.
  unless (@listOfHtmlFeatureArticleFiles)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("No HTML files found in '" . $Self->{htmlDirectory} . "'.\n");
  }

  return \@listOfHtmlFeatureArticleFiles;
}


# copy the specified file to the unparsable directory.
sub _copyFileToUnparsable # (fileToMove)
{
  my ($Self, $FileToMove) = @_;
  my (undef, undef, $fileName) = File::Spec->splitpath ($FileToMove);
  return copy ($FileToMove, File::Spec->catfile ($Self->{unparsableDirectory}, $fileName));
}


sub parseArticlePage # (self => $Self, htmlFile => '...', xmlDirectory => '...', textDirectory => '...')
{
  my ($Self, %Parameters);

  if (ref ($_[0]) eq 'Text::Corpus::Summaries::Wikipedia')
  {
    ($Self, %Parameters) = @_;
  }
  else
  {
    %Parameters = @_;

    # get the object if called using it.
    $Self = $Parameters{self} if exists $Parameters{self};
  }

  # warn if the htmlFile parameter was not defined.
  unless (exists ($Parameters{htmlFile}) && defined ($Parameters{htmlFile}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Parameter htmlFile not defined.\n");
    return undef;
  }
  my $htmlFile = $Parameters{htmlFile};

  # parse the file into xml and text formats.
  my $parsedContent = getParsedArticlePage (%Parameters);

  # if errors, log them and return undef.
  unless (defined $parsedContent)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Could not parse file '$htmlFile'.\n");
    return undef;
  }

  # if no summary, skip the file.
  unless (defined $parsedContent->{text}{summary})
  {
    $Self->_copyFileToUnparsable ($htmlFile) if defined $Self;

    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Could not find the table of contents for the file '$htmlFile'; no summary generated.\n");

    return undef;
  }

  # get the basename of the file.
  my (undef, undef, $fileBasename) = File::Spec->splitpath ($htmlFile);
  my $postionOfDot = rindex ($fileBasename, '.');
  $fileBasename = substr ($fileBasename, 0, $postionOfDot) if ($postionOfDot > -1);

  # write the xml file of the page.
  my $writeXmlFile = 1;
  $writeXmlFile = 0 if (exists ($Parameters{xmlDirectory}) && !defined ($Parameters{xmlDirectory}));
  if ($writeXmlFile)
  {
    my $xmlDirectory;
    $xmlDirectory = $Parameters{xmlDirectory} if exists $Parameters{xmlDirectory};
    $xmlDirectory = $Self->{xmlDirectory} if (!defined ($xmlDirectory) && defined ($Self));
    if (defined $xmlDirectory)
    {
      my $outputFileName = $fileBasename . '.xml';
      my $outputFile = File::Spec->catfile ($xmlDirectory, $outputFileName);
      my $xmlString = $parsedContent->{xml};
      writeToFileInUtf8Mode ($outputFile, \$xmlString);
    }
  }

  # write the summary and body text files.
  my $writeTextFiles = 1;
  $writeTextFiles = 0 if (exists ($Parameters{textDirectory}) && !defined ($Parameters{textDirectory}));
  if ($writeTextFiles)
  {
    my $textDirectory;
    $textDirectory = $Parameters{textDirectory} if exists $Parameters{textDirectory};
    $textDirectory = $Self->{textDirectory} if (!defined ($textDirectory) && defined ($Self));

    if (defined $textDirectory)
    {
      my $outputFileName = $fileBasename . '_summary.txt';
      my $outputFile = File::Spec->catfile ($textDirectory, $outputFileName);
      my $outputString =  $parsedContent->{text}{summary};
      writeToFileInBinaryMode ($outputFile, \$outputString);

      $outputFileName = $fileBasename . '_body.txt';
      $outputFile = File::Spec->catfile ($textDirectory, $outputFileName);
      $outputString =  $parsedContent->{text}{body};
      writeToFileInBinaryMode ($outputFile, \$outputString);
    }
  }

  return undef;
}


# given the html version of the page, parses it into xml and text versions.
sub getParsedArticlePage # (htmlFile => '...')
{
  #my ($Self, %Parameters) = @_;
  my (%Parameters) = @_;

  # warn if the htmlFile parameter was not defined.
  unless (exists ($Parameters{htmlFile}) && defined ($Parameters{htmlFile}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Parameter htmlFile not defined.\n");
    return undef;
  }

  # get the html file of the page.
  my $htmlFile = $Parameters{htmlFile};

  # if the file is missing log and throw a warning.
  unless (-f $htmlFile)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("No such file '$htmlFile'.\n");
    return undef;
  }

  # log parsing of the file.
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->info ("Starting to parse file '$htmlFile'.\n");
  }

  # parse the file.
  # my $htmlParser = HTML::TreeBuilder::XPath->new;

  # open and parse the file.
  my $filePtr;
  unless (open ($filePtr, "<:raw", $htmlFile))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$htmlFile' for reading.\n");
  }
  my $htmlParser = HTML::TreeBuilder::XPath->new;
  $htmlParser->parse_file ($filePtr);
  close $filePtr;

  #$htmlParser->parse_file ($htmlFile);
  
  my $xpathTitle = '/html/body//h1[@id="firstHeading"]';

  # xpathBodyContent is the base xpath to the content of the article.
  # my $xpathBodyContent = '/html/body/div[@id="globalWrapper"]/div[@id="column-content"]/div[@id="content"]/div[@id="bodyContent"]';
  #my $xpathBodyContent = '/html/body/div[@id="content"]/div[@id="bodyContent"]';
  my $xpathBodyContent = '//div[@id="bodyContent"]';

  # xpathContentParagraphs is the xpath to the paragraphs we want plus a little more that will be removed later.
  my $xpathContentParagraphs = $xpathBodyContent . '//p';
  #my $xpathContentParagraphs = '/html/body/div/div[@id="bodyContent"]/div/p';
  

  # xpathToc is the xpath to the table of contents; paragraphs before this are the summary.
  #my $xpathToc = $xpathBodyContent . '/table[@id="toc"]';
  #my $xpathToc = $xpathBodyContent . '//table[@id="toc"]';
  my $xpathToc = '//table[@class="toc"]';

  # xpathReferences is the xpath to the list of references, this and all after it are removed.
  #my $xpathReferences = $xpathBodyContent . '/div/ol[@class="references"]';
  #my $xpathReferences = $xpathBodyContent . '//ol[@class="references"]';
  my $xpathReferences = '//ol[@class="references"]';

  # xpathHeaders is a list of all the xpath headers h1 to h9.
  my @xpathHeaders;
  for (my $i = 1; $i < 9; $i++)
  {
    $xpathHeaders[$i-1] = $xpathBodyContent . '//h' . ($i + 1) . '/span[@class="mw-headline"]';
  }

  # xpathHeaders is the xpath expression to find any header h1 to h9.
  my $xpathHeaders = join ('|', @xpathHeaders);

  # xpaths is the xpath expression for all the content we want to find.
  my $xpaths = join ('|', $xpathTitle, $xpathContentParagraphs, $xpathToc, $xpathHeaders, $xpathReferences);

  # find all the nodes in the html containing content we want.
  my @contentNodes = $htmlParser->findnodes ($xpaths);
  
  # convert the nodes found into a list where each entry in the list is of the
  # form [type, content]. type is either 'paragraph', 'headerN', 'toc', or 'references'
  # and content is the text content of the node.
  my @lines;
  foreach my $node (@contentNodes)
  {
    # get the tag of the node.
    my $tag = $node->tag();
    
    # default type is a paragraph.
    my $type = 'paragraph';
    my $value = $node->findvalue ('.');

    # the strings returned should be utf8 encoded, if not, make them so.
    unless (Encode::is_utf8 ($value, 1))
    {
      eval { $value = decode_utf8 ($value, 0); };
      if ($@)
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->logwarn ("Problems utf8 encoding the text '$value' in file '$htmlFile'.\n");
      }
    }

    # most common is a paragraph.
    if ($tag eq 'p')
    {
      # skip the node if all white space.
      next if ($value =~ /^\s*$/);

      # store the paragraph.
      push @lines, ['paragraph', $value];
      
      next;
    }
    
    # if hN, it is a header.
    if ($tag =~ /^h(\d+)$/)
    {
      push @lines, ['header' . $1, $value];
      next;
    }
        
    # if span get the header with it.
    if ($tag eq 'span')
    {
      my $parentNode = $node->parent();
      my $parentNodeTag = $parentNode->tag();
      if ($parentNodeTag =~ /^h(\d)/)
      {
        my $headerDepth = $1;
        if ($value =~ /^\s*(Sees\*Also|Notes|References|External\s*Links)\s*$/i)
        {
          push @lines, ['references', $value];
        }
        else
        {
          push @lines, ['header' . $headerDepth, $value];
        }
        next;
      }
    }

    # check for 'toc' table.
    if ($tag eq 'table')
    {
      $type = 'toc';
      push @lines, [$type, $value];
      next;
    }

    # check if the node has the list of references.
    if ($tag eq 'ol')
    {
      $type = 'references';
      push @lines, [$type, $value];
      next;
    }

    # skip the node if all white space.
    next if ($value =~ /^\s*$/);

    # store the paragraph.
    push @lines, [$type, $value];
  }

  # remove references numbers from the text, like '[10]'.
  for (my $i = 0; $i < @lines; $i++)
  {
    $lines[$i]->[1] =~ s/\[\d+\]/ /g;
    $lines[$i]->[1] =~ s/[\p{SpacingMark}\p{Whitespace}\x{A0}]+/ /g;
  }

  # find the title, if there is one.
  my $titleText;
  for (my $i = 0; $i < @lines; $i++)
  {
    if ($lines[$i]->[0] eq 'header1')
    {
      $titleText = $lines[$i]->[1];
      last;
    }
  }

  # find the index for the 'toc' tag.
  my $tocIndex = -1;
  for (my $i = 0; $i < @lines; $i++)
  {
    if ($lines[$i]->[0] eq 'toc')
    {
      $tocIndex = $i;
      last;
    }
  }

  # if no toc found, then we cannot generate a summary.
  my @summary;
  if ($tocIndex >= 0)
  {
    # pull out the summary (lead paragraphs).
    for (my $i = 0; $i < $tocIndex; $i++)
    {
      if ($lines[$i]->[0] eq 'paragraph')
      {
        push @summary, $lines[$i];
      }
    }

    if (@summary)
    {
      # remove all the items up to and including the toc.
      splice (@lines, 0, $tocIndex + 1);
    }
  }
  else
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Parsing problems, could not find toc in file '$htmlFile'.\n");
  }

  # find the first reference tag and remove all lines after and including it.
  for (my $i = 0; $i < @lines; $i++)
  {
    if ($lines[$i]->[0] eq 'references')
    {
      $#lines = $i - 2;
      last;
    }
  }

  # remove any trailing non-paragraphs.
  for (my $i = @lines - 1; $i > -1; $i--)
  {
    if ($lines[$i]->[0] eq 'paragraph')
    {
      $#lines = $i;
      last;
    }
  }

  # used to hold the summary and content as lines of text.
  my @textSummary;
  my @textContent;

  # create the xml for the summary and text.
  my $xmlDocument = XML::Code->new ('document');
  $xmlDocument->version("1.0");
  $xmlDocument->encoding("UTF-8");
  my @xmlStack = ($xmlDocument);

  # add the title.
  if (defined $titleText)
  {
    my $title = XML::Code->new ('title');
    $xmlStack[-1]->add_child ($title);
    $title->set_text ($titleText);
  }

  # add the summary.
  my $summary = XML::Code->new ('summary');
  $xmlStack[-1]->add_child ($summary);
  push @xmlStack, $summary;
  foreach my $line (@summary)
  {
    my $p = XML::Code->new ('p');
    $p->set_text ($line->[1]);
    $xmlStack[-1]->add_child ($p);

    push @textSummary, $line->[1];
  }
  pop @xmlStack;

  # start the body.
  my $body = XML::Code->new ('body');
  $xmlStack[-1]->add_child ($body);
  push @xmlStack, $body;

  # compute the header hierarchy.
  my @headerStack;
  for (my $i = 0; $i < @lines; $i++)
  {
    if ($lines[$i]->[0] eq 'paragraph')
    {
      my $p = XML::Code->new ('p');
      $p->set_text ($lines[$i]->[1]);
      $xmlStack[-1]->add_child ($p);

      push @textContent, $lines[$i]->[1];
    }
    elsif (substr ($lines[$i]->[0], 0, 6) eq 'header')
    {
      # get the index of the header.
      my $headerIndex = substr ($lines[$i]->[0], -1, 1);

      # check if a new section is starting.
      if (@headerStack)
      {
        # make sure successive headers indices are at most one apart.
        $headerIndex = $headerStack[-1] + 1 if ($headerIndex > $headerStack[-1]);

        if ($headerIndex > $headerStack[-1])
        {
          my $section = XML::Code->new ('section');
          $xmlStack[-1]->add_child ($section);
          push @xmlStack, $section;

          my $header = XML::Code->new ('header');
          $header->set_text ($lines[$i]->[1]);
          $xmlStack[-1]->add_child ($header);

          push @textContent, $lines[$i]->[1];
          push @headerStack, $headerIndex;
        }
        else
        {
          while (@headerStack && ($headerIndex <= $headerStack[-1]))
          {
            pop @xmlStack;
            pop @headerStack;
          }

          my $section = XML::Code->new ('section');
          $xmlStack[-1]->add_child ($section);
          push @xmlStack, $section;

          my $header = XML::Code->new ('header');
          $header->set_text ($lines[$i]->[1]);
          $xmlStack[-1]->add_child ($header);

          push @textContent, $lines[$i]->[1];
          push @headerStack, $headerIndex;
        }
      }
      else
      {
        my $section = XML::Code->new ('section');
        $xmlStack[-1]->add_child ($section);
        push @xmlStack, $section;

        my $header = XML::Code->new ('header');
        $header->set_text ($lines[$i]->[1]);
        $xmlStack[-1]->add_child ($header);

        push @textContent, $lines[$i]->[1];
        push @headerStack, $headerIndex;
      }
    }
  }
  while (@headerStack)
  {
    pop @headerStack;
    pop @xmlStack;
  }
  pop @xmlStack;
  pop @xmlStack;

  # get the xml version of the document.
  my $xml = $xmlDocument->code ();

  # get the text version of the document.
  my $textSummary = join ("\n", @textSummary) if @textSummary;
  my $textBody =  join ("\n", @textContent) if @textContent;

  # delete the parser.
  $htmlParser->delete;

  # return the strings in a hash.
  return {xml => $xml, text => {summary => $textSummary, body => $textBody}};
}


# writes the string $stringToWrite to the file $filePathName
# in binary mode.
sub writeToFileInBinaryMode # ($filePathName, \$stringToWrite)
{
  # open the file for writing.
  local *OUT;
  unless (open(OUT, '>:raw', $_[0]))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$_[0]' for writing.\n");
  }

  # write the reference string.
  binmode OUT;
  {
    no warnings 'utf8';
    print OUT encode_utf8 (${$_[1]});
  }
  close OUT;
  return undef;
}

# writes the string $stringToWrite to the file $filePathName
# in utf8 mode.
sub writeToFileInUtf8Mode # $Self->($filePathName, \$stringToWrite)
{
  # open the file for writing.
  local *OUT;
  unless (open(OUT, '>:utf8', $_[0]))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$_[0]' for writing.\n");
  }

  # write the reference string.
  print OUT ${$_[1]};
  close OUT;
  return undef;
}


# parses out the titles of the featured articles from the feature articles page
# of the wikipedia for the specific language. returns an array reference listing
# the titles.
sub _getListOfFeaturedArticleUrls
{
  my $Self = $_[0];

  # get the feature article title and xpath expression.
  my %Parameters = $Self->_getFeatureArticleUrlAndXPathExpression ();

  # get the xpath of the featured articles page.
  my $xpathOrRoutine = $Parameters{xpath} if exists $Parameters{xpath};

  if (!ref ($xpathOrRoutine))
  {
    return $Self->_getListOfFeaturedArticleUrlsViaUrlAndXpath;
  }
  else
  {
    return $Self->$xpathOrRoutine;
  }
}


# parses out the urls of the featured articles for those languages that have their list of featured
# articles on only one page.
sub _getListOfFeaturedArticleUrlsViaUrlAndXpath
{
  my $Self = $_[0];

  # get the feature article title and xpath expression.
  my %Parameters = $Self->_getFeatureArticleUrlAndXPathExpression ();

  # get the url of the featured articles page.
  my $url = $Parameters{url} if exists $Parameters{url};

  # get the xpath to use to extract the urls.
  unless (exists $Parameters{xpath})
  {
    my $logger = Log::Log4perl->get_logger();
    my $languageCode = $Self->{languageCode};
    $logger->logdie ("The xpath parameter to extract featured article URLs missing for '$languageCode' Wikipedia.\n");
  }
  my $xpath = $Parameters{xpath};

  # fetch the page, make sure the page ends in htm here and not html. sloppy but files
  # ending in the htmlDirectory with html are the featured articles pages only.
  my $outputFile = File::Spec->catfile ($Self->{htmlDirectory}, '_featuredArticles.htm');
  my $fetchFile = $Self->_isFileTooOld (filePath => $outputFile, maxAge => 24 * 60 * 60);
  if ($fetchFile)
  {
    my $file = $Self->_getPage (url => $url, outputFile => $outputFile) ;
    return undef unless defined $file;
  }

  # open and parse the file.
  my $filePtr;
  unless (open ($filePtr, "<:utf8", $outputFile))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$outputFile' for reading.\n");
  }
  my $htmlParser = HTML::TreeBuilder::XPath->new;
  $htmlParser->parse_file ($filePtr);
  close $filePtr;

  # extract out the links for the featured articles from the html.
  my @urls = $htmlParser->findvalues ($xpath);
  
  # remove any titles that have substrings identifying them as not featured articles.
  my $totalUrls = 0;
  for (my $i = 0; $i < @urls; $i++)
  {
    use bytes;
    next unless length $urls[$i];
    next if (index ($urls[$i], 'action=edit') > -1);
    next if (index ($urls[$i], '/wiki/Help:') > -1);
    next if (index ($urls[$i], '/wiki/Wikipedia:') > -1);
    $urls[$totalUrls++] = $urls[$i];
  }
  $#urls = $totalUrls - 1;

  # make sure the urls were extracted.
  unless (@urls)
  {
    my $logger = Log::Log4perl->get_logger();
    my $languageCode = $Self->{languageCode};
    $logger->logdie ("No featured article URLs were extracted from the '$languageCode' Wikipedia featured article pages. Perhaps the formatting of the links has changed.\n");
  }

  # convert the URLs to absolutes.
  for (my $i = 0; $i < @urls; $i++)
  {
    $urls[$i] = URI->new_abs ($urls[$i], $url)->as_string;
  }

  # gotta delete HTML::TreeBuilder to prevent memory leaks.
  $htmlParser->delete;

  # log the list of featured article links extracted.
  {
    my $logger = Log::Log4perl->get_logger();
    my $languageCode = $Self->{languageCode};
    my $listOfLinksAsStrings = join ("\n", @urls) . "\n";
    $logger->info ("List of featured article links extracted: \n" . $listOfLinksAsStrings);
  }

  # check the number of extracted with the number logged in mediawiki.
  {
    my $langCodeFeatureArticlesInfo = $Self->{langCodeFeatureArticlesInfo};

    my $languageCode = $Self->{languageCode};
    if (exists ($langCodeFeatureArticlesInfo->{$languageCode}))
    {
      my $totalArticles = $langCodeFeatureArticlesInfo->{$languageCode}->[0];
      my $totalExtractedArticles = scalar @urls;
      my $relativeError = abs ($totalArticles - $totalExtractedArticles);
      $relativeError /= $totalArticles if $totalArticles;

      if (($relativeError > 0.10) && ($totalExtractedArticles < $totalArticles))
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->logwarn ("\nNumber of extracted featured articles for $languageCode, $totalExtractedArticles, differs by over 10 percent from $totalArticles, \nthe number of featured articles list at http://meta.wikimedia.org/wiki/Wikipedia_featured_articles.\n");
      }
    }
  }

  return \@urls;
}


# fetches a page either by a given url or by the title of the page.
# if url is defined it is used. if url is not defined and title is
# defines the page http://$languageCode.wikipedia.org/wiki/$title
# is fetched. if title is not defined undef is returned.
# the fetched page is written to outputFile, which must be defined.
sub _getPage # (url => '...', title => '...', outputFile => '...')
{
  my ($Self, %Parameters) = @_;

  # get the language code.
  my $languageCode = $Self->{languageCode};

  # create the page error cache if not defined yet. used to cache the url of
  # page fetches that caused an error so we don't keep asking for bad pages.
  $Self->{pageErrorCache} = {} unless exists $Self->{pageErrorCache};
  my $pageErrorCache = $Self->{pageErrorCache};

  # if url is defined, use it instead of the title.
  my $url;
  if (exists ($Parameters{url}) && defined ($Parameters{url}))
  {
    $url = $Parameters{url};
  }
  else
  {
    # get the title of the page.
    return undef unless exists $Parameters{title};
    my $title = $Parameters{title};

    # make the url of the article to fetch.
    $url = 'http://' . $languageCode . '.wikipedia.org/wiki/' . $title;
  }

  # if the url is in the page error cache and recent, return undef.
  return undef if (exists ($pageErrorCache->{$url}) && (time - $pageErrorCache->{$url} < 10 * 60));

  # get the file to write the output too.
  return undef unless exists $Parameters{outputFile};
  my $outputFile = $Parameters{outputFile};

  # if the last fetch was too soon, wait; can't use perl's sleep here since
  # Forks::Super conflicts with it.
  my $waitTime = $Self->{minSecondsBetweenFetches} - (time - $Self->{timeOfLastFetch});
  Forks::Super::pause ($waitTime) if ($waitTime > 0);
  $Self->{timeOfLastFetch} = time;

  # create the request.
  my $request = HTTP::Request->new (GET => $url);

  # pass request to the user agent and get a response back.
  my $response = $Self->{userAgent}->request($request);

  # check the outcome of the response
  if ($response->is_success)
  {
    # great, got something; save it to the file.
    #my $content = $response->content;
    my $content = $response->decoded_content;

    #writeToFileInBinaryMode ($outputFile, \$content);
    writeToFileInUtf8Mode ($outputFile, \$content);

    # log the good news.
    my $logger = Log::Log4perl->get_logger();
    $logger->info ("Fetched page '" . $url . "'.\n");

    # if the page previous generated an error, delete that it does not anymore.
    delete $pageErrorCache->{$url};
  }
  else
  {
    # bummer, could not get the page, so log the error.
    my $logger = Log::Log4perl->get_logger();
    $logger->warn ("Errors occurred attempting to fetch the page '$url'.\n" . $response->status_line . "\n");
    $pageErrorCache->{$url} = $Self->{timeOfLastFetch};
    return undef;
  }

  # return the path to the file saved.
  return $outputFile;
}


# initializes the root logger; we log everything (INFO) to the file
# $corpusDirectory/log.txt at first and then to the file
# $corpusDirectory/$languageCode/log/log.txt
sub initializeLogger
{
  my ($Self, %Parameters) = @_;
  my $logDirectory = $Self->{logDirectory} if exists $Self->{logDirectory};
  $logDirectory = $Parameters{logDirectory} if exists $Parameters{logDirectory};
  my $logFilePath = File::Spec->catfile ($logDirectory, 'log.txt');

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


# returns 1 if a file is not defined, does not exist, is empty, or
# is too old; otherwise returns 0.
sub _isFileTooOld
{
  my ($Self, %Parameters) = @_;

  # if the file was not defined, it is too old.
  return 1 unless exists $Parameters{filePath};

  # if the file does not exist, it is too old.
  return 1 unless -f $Parameters{filePath};

  # if the file is empty, it is too old.
  return 1 unless -s $Parameters{filePath};

  # get the max age of a file to be too old.
  my $maxAge = 7 * 24 * 60 * 60;
  $maxAge = $Parameters{maxAge} if exists $Parameters{maxAge};

  # get info about the file.
  my @fileInfo = stat ($Parameters{filePath});

  # if the file is too old, return 1.
  return 1 if (time - $fileInfo[9] >= $maxAge);

  # at this point the file is not too old.
  return 0;
}


# for the chosen language returns a hash of the url and xpath needed to get
# the list of featured articles from the wikipedia. returns undef if the
# language is not supported.
sub _getFeatureArticleUrlAndXPathExpression
{
  my $Self = $_[0];

  # if a url for the list of feature articles for the language code does not exist return undef.
  return undef unless exists $Self->{featuredArticlesUrls}->{$Self->{languageCode}};

  # if an xpath expression to extract the list of featured articles has not been defined return undef.
  return undef unless exists $Self->{featuredArticlesXpath}->{$Self->{languageCode}};

  # return the url and xpath for a hash.
  return
    (
      'url', $Self->{featuredArticlesUrls}->{$Self->{languageCode}},
      'xpath', $Self->{featuredArticlesXpath}->{$Self->{languageCode}}
    );

  return undef;
}


# on the english wikipedia feature article page is the list of corresponding
# featured article pages in other languages. this routine fetches the
# page http://en.wikipedia.org/wiki/Wikipedia:FA, saves its contents
# at $corpusDirectory/features/featured.html, then extracts the list of
# links for the featured articles pages in other languages. the
# list is stored in a hash $Self->{featuredArticlesUrls} keyed on the
# languages wikipedia code.
sub _getFeaturedArticleLinkXpathPerLanguage
{
  my $Self = $_[0];

  # make sure we do this only once.
  return undef if exists $Self->{featuredArticlesUrls};

  # set the url to use to get the list of all featured articles pages in all languages.
  my $enFeaturedUrl = 'http://en.wikipedia.org/wiki/Wikipedia:FA';

  # set the xpath to use to extract the urls of the featured articles.
  # my $xpath = '/html/body/div/div/div[8]/div/ul/li/a/@href';
  # my $xpath = '/html/body/div[5]/div[6]/div/ul/li/a/@href';
  my $xpath = '/html/body/div/div/div[@id="p-lang"]/div[@class="body"]/ul/li/a/@href';

  # fetch the page.
  my $fileName = 'featured.html';
  my $outputFile = File::Spec->catfile ($Self->{featuredDirectory}, $fileName);
  my $fetchFile = $Self->_isFileTooOld (filePath => $outputFile, maxAge => 7 * 24 * 60 * 60);
  if ($fetchFile)
  {
    my $file = $Self->_getPage (url => $enFeaturedUrl, outputFile => $outputFile) ;
    return undef unless defined $file;
  }

  # open and parse the file.
  my $filePtr;
  unless (open ($filePtr, "<:utf8", $outputFile))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$outputFile' for reading.\n");
  }
  my $htmlParser = HTML::TreeBuilder::XPath->new;
  $htmlParser->parse_file ($filePtr);
  close $filePtr;

  # extract out the links for the featured articles from the html.
  my @urls = $htmlParser->findvalues ($xpath);

  # make sure the titles were extracted.
  unless (@urls)
  {
    my $logger = Log::Log4perl->get_logger();
    my $languageCode = $Self->{languageCode};
    $logger->logdie ("Could not get the list of URLs of featured articles for all languages.\n");
  }

  # store the list of featured articles.
  my %featuredArticlesUrls;
  $featuredArticlesUrls{en} = $enFeaturedUrl;
  foreach my $url (@urls)
  {
    if ($url =~ /^http:\/\/([^\.]+)?\./)
    {
      $featuredArticlesUrls{lc $1} = $url;
    }
    elsif ($url =~ /^\/\/([^\.]+)?\./)
    {
      $featuredArticlesUrls{lc $1} = 'http:'.$url;
    }
  }

  $Self->{featuredArticlesUrls} = \%featuredArticlesUrls;

  # get the xpath expression to extract the article links also.
  $Self->_setXpathForFeaturedArticles ();

  # some wikipedias do not list their features articles on the main featured articles page.
  $Self->{featuredArticlesUrls}{id} = 'http://id.wikipedia.org/wiki/Wikipedia:Artikel_pilihan/Topik';
  $Self->{featuredArticlesUrls}{simple} = 'http://simple.wikipedia.org/wiki/Wikipedia:Very_good_articles/by_date';

  # gotta call delete on HTML::TreeBuilder, or we get a memory leak.
  $htmlParser->delete;

  # return featuredArticlesUrls.
  return $Self->{featuredArticlesUrls};
}


# the featured article page for each Wikipedia uses a different format, so
# each wikipedia needs a specific xpath expression to extract the list of
# featured articles. this is a weak point in the module, if the format of
# the page changes, the module breaks for the language.
sub _setXpathForFeaturedArticles
{
  my $Self = $_[0];

  # tested.
  my %featuredArticlesXpath;

  # single page featured article wikipedias require only an xpath to extract the featured article urls.
  #$featuredArticlesXpath{af} = '/html/body/div/div/table/tr/td/p//a/@href';
  $featuredArticlesXpath{af} = '/html/body/div[3]/div[3]/div[4]/table/tr[position()>3]/td/p/a/@href';
    
  #$featuredArticlesXpath{ar} = '/html/body/div/div/table/tr/td//a/@href';
  $featuredArticlesXpath{ar} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[2]/td/ul/li/a/@href'; 

  $featuredArticlesXpath{az} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/ol/li/a/@href';
  
  # $featuredArticlesXpath{'be-x-old'} = '/html/body/div[3]/div[3]/div[4]/table[4]/tr/td/p/a/@href';
  
  $featuredArticlesXpath{bs} = '/html/body/div[3]/div[3]/div[4]/table/tr[2]/td/dl/dd//a/@href';
  
  #$featuredArticlesXpath{bg} = '/html/body/div/div/div/table/tr/td/ul/li/a/@href';
  $featuredArticlesXpath{bg} = '/html/body/div[3]/div[3]/div[4]/div/table[4]/tr/td/ul/li/a/@href';
  
  #$featuredArticlesXpath{ca} = '/html/body/div/div/table[3]//a/@href';
  $featuredArticlesXpath{ca} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr/td//table/tr[2]/td//a/@href';
  
  #$featuredArticlesXpath{cs} = '/html/body/div/div/table/tr[2]//a/@href';
  $featuredArticlesXpath{cs} = '/html/body/div[3]/div[3]/div[4]/table/tr[2]/td/dl/dd/a/@href';
  
  #$featuredArticlesXpath{de} = '/html/body/div/div/table/tr[position()>2]//a/@href';
  $featuredArticlesXpath{de} = '/html/body/div[3]/div[3]/div[4]/table/tr[2]/td/table[2]/tr[position()>2]/td/table[2]/tr/td/p/a/@href';
  
  #$featuredArticlesXpath{el} = '/html/body/div/div/ol/li/b//a/@href';
  $featuredArticlesXpath{el} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr[2]/td/p/b/a/@href';
  
  #$featuredArticlesXpath{en} = '//span[@class="featured_article_metadata has_been_on_main_page"]/a/@href';
  $featuredArticlesXpath{en} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/p//a';
  
  #$featuredArticlesXpath{eo} = '/html/body/div/div/table/tr[position()>3]/td/p//a/@href';
  $featuredArticlesXpath{eo} = '/html/body/div[3]/div[3]/div[4]/table/tr[position()>3]/td/p/a/@href';

  #$featuredArticlesXpath{es} = '/html/body/div/div/table[3]/tr[3]/td//a/@href';
  $featuredArticlesXpath{es} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr[3]/td/p//a/@href';
  
  #$featuredArticlesXpath{eu} = '/html/body/div/div/ul/li/a/@href';
  $featuredArticlesXpath{eu} = '/html/body/div[3]/div[3]/div[4]/p/a/@href';

  #$featuredArticlesXpath{fa} = '/html/body/div/div/table[3]/tr[2]/td//a/@href';
  $featuredArticlesXpath{fa} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td//a/@href';

  #$featuredArticlesXpath{fi} = '/html/body/div/div/table[position()>3]//a/@href';
  $featuredArticlesXpath{fi} = '/html/body/div[3]/div[3]/div[4]/table[4]/tr/td/p/a/@href';
  
  $featuredArticlesXpath{he} = \&_getFeaturedArticlesOfLanguageCodeHe;

  #$featuredArticlesXpath{hr} = '/html/body/div/div/div/div[2]/table/tr[4]/td//a/@href';
  $featuredArticlesXpath{hr} = '/html/body/div[3]/div[3]/div[4]/table/tr[4]/td/p/font//a/@href';
  
  #$featuredArticlesXpath{hu} = '/html/body/div/div/table[3]/tr/td/p//a/@href';
  $featuredArticlesXpath{hu} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr/td/p/a/@href';
  
  #$featuredArticlesXpath{it} = '/html/body/div/div/table/tr[7]/td/dl/dd//a/@href';
  $featuredArticlesXpath{it} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr/td/table[2]/tr[6]/td/dl/dd//a/@href';
  
  #$featuredArticlesXpath{id} = '/html/body/div/div/table[2]/tr[2]/td//a/@href';
  $featuredArticlesXpath{id} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[2]/td/ul/li/div/div[2]/p/a/@href';

  #$featuredArticlesXpath{ja} = '/html/body/div/div/ul/li//a/@href';
  $featuredArticlesXpath{ja} = '/html/body/div[3]/div[3]/div[4]/ul[position()<10]/li//a/@href';

  $featuredArticlesXpath{jv} = '/html/body/div[3]/div[3]/div[4]/ul/li/a/@href';
 
  #$featuredArticlesXpath{ka} = '/html/body/div/div/div/table/tr[position()>2]//a/@href';
  $featuredArticlesXpath{ka} = '/html/body/div[3]/div[3]/div[4]/div/table/tr/td/table[2]/tr/td/p/a/@href';
  
  $featuredArticlesXpath{kk} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr/td/table[4]/tr/td/p/a/@href';
  
  $featuredArticlesXpath{km} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/ul/li//a/@href';
  
  #$featuredArticlesXpath{ko} = '/html/body/div/div/table/tr[3]/td//a/@href';
  $featuredArticlesXpath{ko} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/p/a/@href';
  
  $featuredArticlesXpath{li} = '/html/body/div[3]/div[3]/div[4]/ul[2]/li/a/@href';

  $featuredArticlesXpath{lv} = '/html/body/div[3]/div[3]/div[4]/table/tr/td/table[3]/tr/td/p//a/@href';

  #$featuredArticlesXpath{ml} = '/html/body/div/div/table/tr/td[2]//a/@href';
  $featuredArticlesXpath{ml} = '/html/body/div[4]/div[3]/div[4]/table/tr/td[2]/a/@href';

  #$featuredArticlesXpath{mr} = '//*[@id="bodyContent"]//b/a/@href';
  $featuredArticlesXpath{mr} = '/html/body/div[3]/div[3]/div[4]/ul/li/b/a/@href';
  
  #$featuredArticlesXpath{ms} = '/html/body/div/div/table/tr[3]/td//a/@href';
  $featuredArticlesXpath{ms} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/p/span/a/@href';
  
  $featuredArticlesXpath{mzn} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[2]/td/ul/li/b/a/@href';
  
  #$featuredArticlesXpath{nl} = '/html/body/div/div/table/tr/td/p//a/@href';
  $featuredArticlesXpath{nl} = '/html/body/div[3]/div[3]/div[4]/table/tr[position()>2]/td/p//a/@href';
  
  #$featuredArticlesXpath{nn} = '/html/body/div/div/table/tr/td/table/tr/td/table/tr/td/ul/li/a/@href';
  $featuredArticlesXpath{nn} = '/html/body/div[3]/div[3]/div[4]/table/tr[4]/td/table/tr/td/ul/li/a/@href';

  #$featuredArticlesXpath{no} = '/html/body/div/div/table/tr[position()>1]/td//a/@href';
  $featuredArticlesXpath{no} = '/html/body/div[3]/div[3]/div[4]/table/tr[position()>1]/td/table/tr/td/p//a/@href';

  #$featuredArticlesXpath{pl} = '/html/body/div/div/table/tr[3]/td//a/@href';
  $featuredArticlesXpath{pl} = '/html/body/div[3]/div[3]/div[4]/p[position()>1]/a/@href';
  
  #$featuredArticlesXpath{pt} = '/html/body/div/div/table/tr/td/dl/dd//a/@href';
  $featuredArticlesXpath{pt} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[3]/td/dl/dd//a/@href';

  #$featuredArticlesXpath{ro} = '/html/body/div/div/table[2]/tr[3]/td/dl/dd//a/@href';
  $featuredArticlesXpath{ro} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[3]/td/dl/dd/a/@href';

  $featuredArticlesXpath{ru} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr/td/table[4]/tr/td//a/@href';

  #$featuredArticlesXpath{sh} = '/html/body/div/div/div/div/ul/li/b//a/@href';
  $featuredArticlesXpath{sh} = '/html/body/div[3]/div[3]/div[4]/table/tr[4]/td/p/font/b/a/@href';

  #$featuredArticlesXpath{sk} = '/html/body/div/div/p//a/@href';
  $featuredArticlesXpath{sk} = '/html/body/div[3]/div[3]/div[4]/p/b//a/@href';
  
  $featuredArticlesXpath{simple} = '/html/body/div[3]/div[3]/div[4]/table[1]/tr/td[2]//a/@href';

  #$featuredArticlesXpath{sl} = '/html/body/div/div/table[2]/tr[3]/td//a/@href';
  $featuredArticlesXpath{sl} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[3]/td/p//a/@href';
  
  #$featuredArticlesXpath{sr} = '/html/body/div/div/div/div/table/tr/td/dl/dd//a/@href';
  $featuredArticlesXpath{sr} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr[3]/td/dl/dd/a/@href';
  
  #$featuredArticlesXpath{sv} = '/html/body/div/div/table/tr/td/table/tr/td/dl/dd/b//a/@href';
  $featuredArticlesXpath{sv} = '/html/body/div[3]/div[3]/div[4]/table/tr/td/table[3]/tr/td/dl/dd/a/@href';
  
  $featuredArticlesXpath{sw} = '/html/body/div[3]/div[3]/div[4]/div/div/div/a/@href';

  $featuredArticlesXpath{ta} = '/html/body/div[3]/div[3]/div[4]/p/b/a/@href';
  
  $featuredArticlesXpath{th} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr/td/ul/li//a/@href';
  
  $featuredArticlesXpath{tl} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/p/a/@href';
  
  #$featuredArticlesXpath{tr} = '/html/body/div/div/table/tr[3]/td/p//a/@href';
  $featuredArticlesXpath{tr} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/p//a/@href';
  
  $featuredArticlesXpath{tt} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr/td/table/tr/td/table[3]/tr/td/table[2]/tr/td/p/a/@href|/html/body/div[3]/div[3]/div[4]/table[2]/tr/td/table/tr/td/table[3]/tr/td/table[2]/tr/td//ul/li/a';
  
  $featuredArticlesXpath{uk} = '/html/body/div[3]/div[3]/div[4]/table[2]/tr[2]/td//ul/li/a/@href';
  
  $featuredArticlesXpath{ur} = '/html/body/div[3]/div[3]/div[4]/table/tr[3]/td/p/a/@href';
  
  #$featuredArticlesXpath{vi} = '/html/body/div/div/div/table/tr/td/p//a/@href';
  $featuredArticlesXpath{vi} = '/html/body/div[3]/div[3]/div[4]/div[2]/table/tr/td[2]/p//a/@href';
  
  $featuredArticlesXpath{vo} = '/html/body/div[3]/div[3]/div[4]/div/div/div/a';
  
  #$featuredArticlesXpath{zh} = '/html/body/div/div/table[3]//a/@href';
  $featuredArticlesXpath{zh} = '/html/body/div[3]/div[3]/div[4]/table[3]/tr/td/p/b/a/@href';

  # multi-page featured article wikipedias require a subroutine to extract the featured article urls.
  $featuredArticlesXpath{fr} = \&_getFeaturedArticlesOfLanguageCodeFr;

  $_[0]->{featuredArticlesXpath} = \%featuredArticlesXpath if @_;
  return \%featuredArticlesXpath;
}


# getting the list of featured articles for the french language requires that many pages
# be parsed.
sub _getFeaturedArticlesOfLanguageCodeFr
{
  my $Self = $_[0];

  # start at the page that has the start of the list of page with category Article_de_qualit%C3%A9.
  my $baseUrl = 'http://fr.wikipedia.org/w/index.php?title=Cat%C3%A9gorie:Article_de_qualit%C3%A9';

  my %listOfFeaturedArticleUrls;
  my $doneFetchingCategoryPages = 0;
  my $pageIndex = 0;
  my $url = $baseUrl;
  while ($url)
  {
    # fetch the page.
    my $fileName = '_featuredArticles' . sprintf ('%02d', ++$pageIndex) . '.html';
    my $outputFile = File::Spec->catfile ($Self->{htmlDirectory}, $fileName);
    my $fetchFile = $Self->_isFileTooOld (filePath => $outputFile, maxAge => 7 * 24 * 60 * 60);
    if ($fetchFile)
    {
      my $file = $Self->_getPage (url => $url, outputFile => $outputFile) ;
      last unless defined $file;
    }

    # open and parse the file.
    my $filePtr;
    unless (open ($filePtr, "<:utf8", $outputFile))
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logdie ("Could not open file '$outputFile' for reading.\n");
    }
    my $htmlParser = HTML::TreeBuilder::XPath->new;
    $htmlParser->parse_file ($filePtr);
    close $filePtr;

    # get the list of featured article urls.
    my @listOfUrls = $htmlParser->findvalues ('/html/body/div[3]/div[3]/div[4]/div[3]/div[2]/div/table/tr/td/ul/li/a/@href');

    # log a warning if no urls extracted.
    unless (@listOfUrls)
    {
      my $logger = Log::Log4perl->get_logger();
      my $languageCode = $Self->{languageCode};
      $logger->logdie ("No featured article URLs were extracted from the '$languageCode' Wikipedia featured article page $url. Perhaps the formatting of the links has changed.\n");
    }

    # convert the urls to absolute urls.
    for (my $i = 0; $i < @listOfUrls; $i++)
    {
      $listOfUrls[$i] = URI->new_abs ($listOfUrls[$i], $url)->as_string;
    }

    # save the urls extracted.
    my $repeats = 0;
    foreach my $link (@listOfUrls)
    {
      ++$repeats if exists $listOfFeaturedArticleUrls{$link};
      $listOfFeaturedArticleUrls{$link} = 1;
    }
    @listOfUrls = ();

    # if there are a lot of repeats there are parsing problems.

    my @potentialNextNodes = $htmlParser->findnodes ('/html/body//a');
    my $nextUrl;
    foreach my $node (@potentialNextNodes)
    {
      my $textOfNode = lc $node->findvalue ('.');
      if (index ($textOfNode, 'ments suivants') > -1)
      {
        $nextUrl = $node->findvalue ('@href');
        last;
      }
    }
    last unless (defined ($nextUrl) && length ($nextUrl));
    $htmlParser->delete;

    # convert the URL to an absolute url.
    $nextUrl = URI->new_abs ($nextUrl, $url)->as_string;
    $url = $nextUrl;

    # make sure the loop stops.
    if ($pageIndex > 40)
    {
      my $logger = Log::Log4perl->get_logger();
      my $languageCode = $Self->{languageCode};
      $logger->logdie ("Stopped extraction of featured article URLs from the '$languageCode' Wikipedia. Maybe the formatting of the links has changed.\n");
    }
  }

  return [keys %listOfFeaturedArticleUrls];
}


# getting the list of featured articles for the hebrew language requires that many pages
# be parsed.
sub _getFeaturedArticlesOfLanguageCodeHe
{
  my $Self = $_[0];

  # start at the page that has the start of the list of page with category Article_de_qualit%C3%A9.
  my $baseUrl = 'http://he.wikipedia.org/wiki/%D7%A7%D7%98%D7%92%D7%95%D7%A8%D7%99%D7%94:%D7%A2%D7%A8%D7%9B%D7%99%D7%9D_%D7%9E%D7%95%D7%9E%D7%9C%D7%A6%D7%99%D7%9D';

  my %listOfFeaturedArticleUrls;
  my $doneFetchingCategoryPages = 0;
  my $pageIndex = 0;
  my $url = $baseUrl;
  while ($url)
  {
    # fetch the page.
    my $fileName = '_featuredArticles' . sprintf ('%02d', ++$pageIndex) . '.html';
    my $outputFile = File::Spec->catfile ($Self->{htmlDirectory}, $fileName);
    my $fetchFile = $Self->_isFileTooOld (filePath => $outputFile, maxAge => 7 * 24 * 60 * 60);
    if ($fetchFile)
    {
      my $file = $Self->_getPage (url => $url, outputFile => $outputFile) ;
      last unless defined $file;
    }

    # open and parse the file.
    my $filePtr;
    unless (open ($filePtr, "<:utf8", $outputFile))
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logdie ("Could not open file '$outputFile' for reading.\n");
    }
    my $htmlParser = HTML::TreeBuilder::XPath->new;
    $htmlParser->parse_file ($filePtr);
    close $filePtr;

    # get the list of featured article urls.
    my @listOfUrls = $htmlParser->findvalues ('/html/body/div[3]/div[3]/div[4]/div/div/div/table/tr/td/ul/li/a/@href');

    # log a warning if no urls extracted.
    unless (@listOfUrls)
    {
      my $logger = Log::Log4perl->get_logger();
      my $languageCode = $Self->{languageCode};
      $logger->logdie ("No featured article URLs were extracted from the '$languageCode' Wikipedia featured article page $url. Perhaps the formatting of the links has changed.\n");
    }

    # convert the urls to absolute urls.
    for (my $i = 0; $i < @listOfUrls; $i++)
    {
      $listOfUrls[$i] = URI->new_abs ($listOfUrls[$i], $url)->as_string;
    }

    # save the urls extracted.
    my $repeats = 0;
    foreach my $link (@listOfUrls)
    {
      ++$repeats if exists $listOfFeaturedArticleUrls{$link};
      $listOfFeaturedArticleUrls{$link} = 1;
    }
    @listOfUrls = ();

    # if there are a lot of repeats there are parsing problems.
    my @potentialNextNodes = $htmlParser->findnodes ('/html/body/div[3]/div[3]/div[4]/div/div/a[2]');

    my $nextUrl;
    foreach my $node (@potentialNextNodes)
    {
      my $textOfNode = lc $node->findvalue ('.');
      my $nextPageLinkText = pack("H*","32303020d794d791d790d799d79d");
      if (($textOfNode =~ /$nextPageLinkText/i) || ($textOfNode =~ /הבאים/i))
      {
        $nextUrl = $node->findvalue ('@href');
        last;
      }
    }
    last unless (defined ($nextUrl) && length ($nextUrl));
    $htmlParser->delete;

    # convert the URL to an absolute url.
    $nextUrl = URI->new_abs ($nextUrl, $url)->as_string;
    $url = $nextUrl;

    # make sure the loop stops.
    if ($pageIndex > 20)
    {
      my $logger = Log::Log4perl->get_logger();
      my $languageCode = $Self->{languageCode};
      $logger->logdie ("Stopped extraction of featured article URLs from the '$languageCode' Wikipedia. Maybe the formatting of the links has changed.\n");
    }
  }

  return [keys %listOfFeaturedArticleUrls];
}


sub getListOfSupportedLanguageCodes
{
  return sort keys %{_setXpathForFeaturedArticles()};
}


sub getPodandHtmlStringOfLanguageInfo
{
  my $Self = $_[0];

  # get the sorted list of supported language codes.
  my @languageCodes = sort keys %{$Self->{featuredArticlesXpath}};

  # set the english name in the @languageCodes.
  my $enNameOfLanguageCode = $Self->{enNameOfLanguageCode};

  # convert the list of language codes to a string for the POD.
  {
    my $supportedLanuageCodes = 'empty.';

    my @languageCodesInPod;
    foreach my $langCode (@languageCodes)
    {
      if (exists $enNameOfLanguageCode->{$langCode})
      {
        push @languageCodesInPod, 'C<' . $langCode . '>:' . $enNameOfLanguageCode->{$langCode};
      }
      else
      {
        push @languageCodesInPod,  'C<' . $langCode . '>';
      }
    }

    if (@languageCodesInPod > 1)
    {
      my $lastLanguageCode = pop @languageCodesInPod;
      $supportedLanuageCodes = join (', ', @languageCodesInPod) . ', and ' . $lastLanguageCode . '.';
    }
    elsif (@languageCodesInPod == 1)
    {
      $supportedLanuageCodes = $languageCodesInPod[0] . '.';
    }
    @languageCodesInPod = undef;

    print $supportedLanuageCodes . "\n\n";
  }

  {
    # convert the list of language codes to a string for the html.
    my $featuredArticlesUrls = $Self->{featuredArticlesUrls};
    my $supportLanuageCodesHtml = 'empty.';

    my @languageCodesInHtml;
    foreach my $langCode (@languageCodes)
    {
      if (exists $enNameOfLanguageCode->{$langCode})
      {
        push @languageCodesInHtml,  '<a href="' . $featuredArticlesUrls->{$langCode} . '">' . $langCode . ':' . $enNameOfLanguageCode->{$langCode} . '</a>';
      }
      else
      {
        push @languageCodesInHtml,  '<a href="' . $featuredArticlesUrls->{$langCode} . '">' . $langCode . '</a>';
      }
    }

    if (@languageCodesInHtml > 1)
    {
      my $lastLanguageCode = pop @languageCodesInHtml;
      $supportLanuageCodesHtml = join (",\n", @languageCodesInHtml) . ", and\n" . $lastLanguageCode . '.';
    }
    elsif (@languageCodesInHtml == 1)
    {
      $supportLanuageCodesHtml = $languageCodesInHtml[0] . '.';
    }
    @languageCodesInHtml = undef;

    print $supportLanuageCodesHtml . "\n\n";
  }
}


# saves a copy of the page List_of_Wikipedias_by_language_family and extracts out the
# english name of the language codes for the wikipedias.
sub _setWikipediaLanguageCodes
{
  my $Self = $_[0];

  # set the url of the page of all wikipeida languages
  my $url = 'http://meta.wikimedia.org/wiki/List_of_Wikipedias';

  # build the full pathname of the file to save the page to.
  my $outputFile = File::Spec->catfile ($Self->{featuredDirectory}, 'List_of_Wikipedias.html');

  # only fetch the file if it is too old.
  my $fetchFile = $Self->_isFileTooOld (filePath => $outputFile, maxAge => 24 * 60 * 60);
  if ($fetchFile)
  {
    my $file = $Self->_getPage (url => $url, outputFile => $outputFile) ;
    return undef unless defined $file;
  }

  # open and parse the file.
  my $filePtr;
  unless (open ($filePtr, "<:utf8", $outputFile))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$outputFile' for reading.\n");
  }
  my $htmlParser = HTML::TreeBuilder::XPath->new;
  $htmlParser->parse_file ($filePtr);
  close $filePtr;

  # extract out the language info of each wikipedia language listed.
  # my $xpath = '/html/body/div/div/div/div[2]/ol/li';
  my $xpath = '/html/body/div[3]/div[3]/div[4]/table/tr';
  my @listOfRows = $htmlParser->findnodes ($xpath);

  # log a warning if no language found.
  unless (@listOfRows)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Could not extract corresponding English name of the language codes from page '$url'; format change my require a new xpath expression.\n");
  }

  my %enNameOfLanguageCode;
  foreach my $languageInfo (@listOfRows)
  {
    # get each column node.
    my @columns = $languageInfo->findnodes ('./td');
    
    # skip the row if it does not have 12 columns.
    next unless @columns == 12;
    
    my $enLanguageName = $languageInfo->findvalue ('./td[2]');
    my $languageCode = $languageInfo->findvalue ('./td[4]');
    $enNameOfLanguageCode{$languageCode} = $enLanguageName if (defined ($enLanguageName) && defined ($languageCode));
  }
  $Self->{enNameOfLanguageCode} = \%enNameOfLanguageCode;

  return undef;
}


# saves a copy of the page Wikipedia_featured_articles and extracts out the
# number of featured articles for each language.
sub _setWikipediaFeatureArticleInfo
{
  my $Self = $_[0];

  # set the url of the page of all wikipeida languages
  my $url = 'http://meta.wikimedia.org/wiki/Wikipedia_featured_articles';

  # build the full pathname of the file to save the page to.
  my $outputFile = File::Spec->catfile ($Self->{featuredDirectory}, 'Wikipedia_featured_articles.html');

  # only fetch the file if it is too old.
  my $fetchFile = $Self->_isFileTooOld (filePath => $outputFile, maxAge => 24 * 60 * 60);
  if ($fetchFile)
  {
    my $file = $Self->_getPage (url => $url, outputFile => $outputFile) ;
    return undef unless defined $file;
  }

  # open and parse the file.
  my $filePtr;
  unless (open ($filePtr, "<:utf8", $outputFile))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("Could not open file '$outputFile' for reading.\n");
  }
  my $htmlParser = HTML::TreeBuilder::XPath->new;
  $htmlParser->parse_file ($filePtr);
  close $filePtr;

  # extract out the language info of each wikipedia language listed.
  # my $xpath = '/html/body/div/div/div/div[2]/table/tr';
  my $xpath = '/html/body/div[3]/div[3]/div[4]/table/tr';
  my @listOfLanguageInfo = $htmlParser->findnodes ($xpath);

  # log a warning if no language info found.
  unless (@listOfLanguageInfo)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("Could not extract corresponding English name of the language codes from page '$url'; format change my require a new xpath expression.\n");
  }

  # extract out the languageCode, numberOfFeatureArticles, and time of last update for each language.
  my %langCodeFeatureArticlesInfo;
  foreach my $languageInfo (@listOfLanguageInfo)
  {
    my $url;
    $url = lc $languageInfo->findvalue ('td[1]/a/@href');
    next unless (defined ($url) && length ($url));
    my $languageCode;
    $languageCode = $2 if ($url =~ /^(http:)?\/\/([^\.]+)/);
    next unless defined $languageCode;

    my $name = $languageInfo->findvalue ('td[1]');
    my $numberOfFeatureArticles = $languageInfo->findvalue ('td[2]');
    if ($numberOfFeatureArticles =~ /(\d+)/) { $numberOfFeatureArticles = $1 } else { $numberOfFeatureArticles = 0; }
    next unless $numberOfFeatureArticles;

    my $lastUpdate = $languageInfo->findvalue ('td[4]');
    $lastUpdate = ParseDate ($lastUpdate);
    next unless (defined ($lastUpdate) && length ($lastUpdate));
    $lastUpdate = UnixDate ($lastUpdate, '%s');

    $langCodeFeatureArticlesInfo{$languageCode} = [$numberOfFeatureArticles, $lastUpdate];
  }
  $Self->{langCodeFeatureArticlesInfo} = \%langCodeFeatureArticlesInfo;

  return $Self->{langCodeFeatureArticlesInfo};
}

=head1 XML FORMAT

The XML files are created using L<XML::Code> with the simple structure outlined below:

  <document>
    <title>The Article Title</title>
    <summary>
      <p>This is the first paragraph of the summary.</p>
      <p>This is the second paragraph of the summary.</p>
    </summary>
    <body>
      <section>
        <header>Head of first section</header>
        <p>First paragraph of this section.</p>
        <p>Second paragraph of this section.</p>
      </section>
      <section>
        <p>First paragraph of this section.</p>
        <p>Second paragraph of this section.</p>
        <section>
          <header>Head of  sub-section</header>
          <p>First paragraph of this sub-section.</p>
          <p>Second paragraph of this sub-section.</p>
        </section>
      </section>
    </body>
  </document>

=head1 EXAMPLE

The following example computes and prints the median, mean, and standard deviation of the fraction of
words (ignoring repeats) in a summary that also occur in the body of the text for all the
articles in the corpora.

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

=head1 SCRIPTS

The script L<create_summary_corpus.pl> makes a corpus for summarization testing
using this module.

=head1 INSTALLATION

Use L<CPAN> to install the module and all its prerequisites:

  perl -MCPAN -e shell
  >install Text::Corpus::Summaries::Wikipedia

=head1 BUGS

This module creates corpora by parsing Wikipedia pages, the xpath
expressions used to extract links and text will become invalid as the format
of the various pages changes, causing some corpora not to be created.

Please email bugs reports or feature requests to C<bug-text-corpus-summaries-wikipedia@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Corpus-Summaries-Wikipedia>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2010 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

corpus, information processing, summaries, summarization, wikipedia

=head1 SEE ALSO

L<create_summary_corpus.pl>, L<Encode>, L<Forks::Super>, L<HTML::TreeBuilder::XPath>, L<Log::Log4perl>, L<LWP::UserAgent>, L<XML::Code>

=begin html

<p>
Links to the featured article page for the supported language codes:
<a href="http://af.wikipedia.org/wiki/Wikipedia:Voorbladartikel">af:Afrikaans</a>,
<a href="http://ar.wikipedia.org/wiki/%D9%88%D9%8A%D9%83%D9%8A%D8%A8%D9%8A%D8%AF%D9%8A%D8%A7:%D9%85%D9%82%D8%A7%D9%84%D8%A7%D8%AA_%D9%85%D8%AE%D8%AA%D8%A7%D8%B1%D8%A9">ar:Arabic</a>,
<a href="http://az.wikipedia.org/wiki/Vikipediya:Se%C3%A7ilmi%C5%9F_m%C9%99qal%C9%99l%C9%99r">az:Azerbaijani</a>,
<a href="http://bg.wikipedia.org/wiki/%D0%A3%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%98%D0%B7%D0%B1%D1%80%D0%B0%D0%BD%D0%B8_%D1%81%D1%82%D0%B0%D1%82%D0%B8%D0%B8">bg:Bulgarian</a>,
<a href="http://bs.wikipedia.org/wiki/Wikipedia:Odabrani_%C4%8Dlanci">bs:Bosnian</a>,
<a href="http://ca.wikipedia.org/wiki/Viquip%C3%A8dia:Articles_de_qualitat">ca:Catalan</a>,
<a href="http://cs.wikipedia.org/wiki/Wikipedie:Nejlep%C5%A1%C3%AD_%C4%8Dl%C3%A1nky">cs:Czech</a>,
<a href="http://de.wikipedia.org/wiki/Wikipedia:Exzellente_Artikel">de:German</a>,
<a href="http://el.wikipedia.org/wiki/%CE%92%CE%B9%CE%BA%CE%B9%CF%80%CE%B1%CE%AF%CE%B4%CE%B5%CE%B9%CE%B1:%CE%91%CE%BE%CE%B9%CF%8C%CE%BB%CE%BF%CE%B3%CE%B1_%CE%AC%CF%81%CE%B8%CF%81%CE%B1">el:Greek</a>,
<a href="http://en.wikipedia.org/wiki/Wikipedia:FA">en:English</a>,
<a href="http://eo.wikipedia.org/wiki/Vikipedio:Elstaraj_artikoloj">eo:Esperanto</a>,
<a href="http://es.wikipedia.org/wiki/Wikipedia:Art%C3%ADculos_destacados">es:Spanish</a>,
<a href="http://eu.wikipedia.org/wiki/Wikipedia:Nabarmendutako_artikuluak">eu:Basque</a>,
<a href="http://fa.wikipedia.org/wiki/%D9%88%DB%8C%DA%A9%DB%8C%E2%80%8C%D9%BE%D8%AF%DB%8C%D8%A7:%D9%85%D9%82%D8%A7%D9%84%D9%87%E2%80%8C%D9%87%D8%A7%DB%8C_%D8%A8%D8%B1%DA%AF%D8%B2%DB%8C%D8%AF%D9%87">fa:Persian</a>,
<a href="http://fi.wikipedia.org/wiki/Wikipedia:Suositellut_artikkelit">fi:Finnish</a>,
<a href="http://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Articles_de_qualit%C3%A9">fr:French</a>,
<a href="http://he.wikipedia.org/wiki/%D7%A4%D7%95%D7%A8%D7%98%D7%9C:%D7%A2%D7%A8%D7%9B%D7%99%D7%9D_%D7%9E%D7%95%D7%9E%D7%9C%D7%A6%D7%99%D7%9D">he:Hebrew</a>,
<a href="http://hr.wikipedia.org/wiki/Wikipedija:Izabrani_%C4%8Dlanci">hr:Croatian</a>,
<a href="http://hu.wikipedia.org/wiki/Wikip%C3%A9dia:Kiemelt_sz%C3%B3cikkek_bemutat%C3%B3ja">hu:Hungarian</a>,
<a href="http://id.wikipedia.org/wiki/Wikipedia:Artikel_pilihan/Topik">id:Indonesian</a>,
<a href="http://it.wikipedia.org/wiki/Wikipedia:Vetrina">it:Italian</a>,
<a href="http://ja.wikipedia.org/wiki/Wikipedia:%E7%A7%80%E9%80%B8%E3%81%AA%E8%A8%98%E4%BA%8B">ja:Japanese</a>,
<a href="http://jv.wikipedia.org/wiki/Wikipedia:Artikel_pilihan">jv:Javanese</a>,
<a href="http://ka.wikipedia.org/wiki/%E1%83%95%E1%83%98%E1%83%99%E1%83%98%E1%83%9E%E1%83%94%E1%83%93%E1%83%98%E1%83%90:%E1%83%A0%E1%83%A9%E1%83%94%E1%83%A3%E1%83%9A%E1%83%98_%E1%83%A1%E1%83%A2%E1%83%90%E1%83%A2%E1%83%98%E1%83%94%E1%83%91%E1%83%98">ka:Georgian</a>,
<a href="http://kk.wikipedia.org/wiki/%D0%A3%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%A2%D0%B0%D2%A3%D0%B4%D0%B0%D1%83%D0%BB%D1%8B_%D0%BC%D0%B0%D2%9B%D0%B0%D0%BB%D0%B0%D0%BB%D0%B0%D1%80">kk:Kazakh</a>,
<a href="http://km.wikipedia.org/wiki/%E1%9E%9C%E1%9E%B7%E1%9E%82%E1%9E%B8%E1%9E%97%E1%9E%B8%E1%9E%8C%E1%9E%B6:%E1%9E%A2%E1%9E%8F%E1%9F%92%E1%9E%90%E1%9E%94%E1%9E%91%E1%9E%96%E1%9E%B7%E1%9E%9F%E1%9F%81%E1%9E%9F">km:Khmer</a>,
<a href="http://ko.wikipedia.org/wiki/%EC%9C%84%ED%82%A4%EB%B0%B1%EA%B3%BC:%EC%95%8C%EC%B0%AC_%EA%B8%80">ko:Korean</a>,
<a href="http://li.wikipedia.org/wiki/Wikipedia:Sjterartikel">li:Limburgish</a>,
<a href="http://lv.wikipedia.org/wiki/Vikip%C4%93dija:V%C4%93rt%C4%ABgi_raksti">lv:Latvian</a>,
<a href="http://ml.wikipedia.org/wiki/%E0%B4%B5%E0%B4%BF%E0%B4%95%E0%B5%8D%E0%B4%95%E0%B4%BF%E0%B4%AA%E0%B5%80%E0%B4%A1%E0%B4%BF%E0%B4%AF:%E0%B4%A4%E0%B4%BF%E0%B4%B0%E0%B4%9E%E0%B5%8D%E0%B4%9E%E0%B5%86%E0%B4%9F%E0%B5%81%E0%B4%A4%E0%B5%8D%E0%B4%A4_%E0%B4%B2%E0%B5%87%E0%B4%96%E0%B4%A8%E0%B4%99%E0%B5%8D%E0%B4%99%E0%B4%B3%E0%B5%8D%E2%80%8D">ml:Malayalam</a>,
<a href="http://mr.wikipedia.org/wiki/%E0%A4%B5%E0%A4%BF%E0%A4%95%E0%A4%BF%E0%A4%AA%E0%A5%80%E0%A4%A1%E0%A4%BF%E0%A4%AF%E0%A4%BE:%E0%A4%AE%E0%A4%BE%E0%A4%B8%E0%A4%BF%E0%A4%95_%E0%A4%B8%E0%A4%A6%E0%A4%B0/%E0%A4%AE%E0%A4%BE%E0%A4%97%E0%A5%80%E0%A4%B2_%E0%A4%85%E0%A4%82%E0%A4%95_%E0%A4%B8%E0%A4%82%E0%A4%97%E0%A5%8D%E0%A4%B0%E0%A4%B9">mr:Marathi</a>,
<a href="http://ms.wikipedia.org/wiki/Wikipedia:Rencana_pilihan">ms:Malay</a>,
<a href="http://mzn.wikipedia.org/wiki/%D9%88%DB%8C%DA%A9%DB%8C%E2%80%8C%D9%BE%D8%AF%DB%8C%D8%A7:%D8%AE%D8%A7%D8%B1_%D8%A8%D9%86%D9%88%DB%8C%D8%B4%D8%AA%D9%87">mzn:Mazandarani</a>,
<a href="http://nl.wikipedia.org/wiki/Wikipedia:Etalage">nl:Dutch</a>,
<a href="http://nn.wikipedia.org/wiki/Wikipedia:Gode_artiklar">nn:Norwegian (Nynorsk)</a>,
<a href="http://no.wikipedia.org/wiki/Wikipedia:Utmerkede_artikler">no:Norwegian (Bokm?l)</a>,
<a href="http://pl.wikipedia.org/wiki/Wikipedia:Artyku%C5%82y_na_medal">pl:Polish</a>,
<a href="http://pt.wikipedia.org/wiki/Wikipedia:Artigos_destacados">pt:Portuguese</a>,
<a href="http://ro.wikipedia.org/wiki/Wikipedia:Articole_de_calitate">ro:Romanian</a>,
<a href="http://ru.wikipedia.org/wiki/%D0%92%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%98%D0%B7%D0%B1%D1%80%D0%B0%D0%BD%D0%BD%D1%8B%D0%B5_%D1%81%D1%82%D0%B0%D1%82%D1%8C%D0%B8">ru:Russian</a>,
<a href="http://sh.wikipedia.org/wiki/Wikipedia:Izabrani_%C4%8Dlanci">sh:Serbo-Croatian</a>,
<a href="http://simple.wikipedia.org/wiki/Wikipedia:Very_good_articles/by_date">simple:Simple English</a>,
<a href="http://sk.wikipedia.org/wiki/Wikip%C3%A9dia:Zoznam_najlep%C5%A1%C3%ADch_%C4%8Dl%C3%A1nkov">sk:Slovak</a>,
<a href="http://sl.wikipedia.org/wiki/Wikipedija:Izbrani_%C4%8Dlanki">sl:Slovenian</a>,
<a href="http://sr.wikipedia.org/wiki/%D0%92%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%98%D0%B0:%D0%A1%D1%98%D0%B0%D1%98%D0%BD%D0%B8_%D1%82%D0%B5%D0%BA%D1%81%D1%82%D0%BE%D0%B2%D0%B8">sr:Serbian</a>,
<a href="http://sv.wikipedia.org/wiki/Wikipedia:Utm%C3%A4rkta_artiklar">sv:Swedish</a>,
<a href="http://sw.wikipedia.org/wiki/Wikipedia:Featured_articles">sw:Swahili</a>,
<a href="http://ta.wikipedia.org/wiki/%E0%AE%B5%E0%AE%BF%E0%AE%95%E0%AF%8D%E0%AE%95%E0%AE%BF%E0%AE%AA%E0%AF%8D%E0%AE%AA%E0%AF%80%E0%AE%9F%E0%AE%BF%E0%AE%AF%E0%AE%BE:%E0%AE%9A%E0%AE%BF%E0%AE%B1%E0%AE%AA%E0%AF%8D%E0%AE%AA%E0%AF%81%E0%AE%95%E0%AF%8D_%E0%AE%95%E0%AE%9F%E0%AF%8D%E0%AE%9F%E0%AF%81%E0%AE%B0%E0%AF%88%E0%AE%95%E0%AE%B3%E0%AF%8D">ta:Tamil</a>,
<a href="http://th.wikipedia.org/wiki/%E0%B8%A7%E0%B8%B4%E0%B8%81%E0%B8%B4%E0%B8%9E%E0%B8%B5%E0%B9%80%E0%B8%94%E0%B8%B5%E0%B8%A2:%E0%B8%9A%E0%B8%97%E0%B8%84%E0%B8%A7%E0%B8%B2%E0%B8%A1%E0%B8%84%E0%B8%B1%E0%B8%94%E0%B8%AA%E0%B8%A3%E0%B8%A3">th:Thai</a>,
<a href="http://tl.wikipedia.org/wiki/Wikipedia:Mga_napiling_artikulo">tl:Tagalog</a>,
<a href="http://tr.wikipedia.org/wiki/Vikipedi:Se%C3%A7kin_maddeler">tr:Turkish</a>,
<a href="http://tt.wikipedia.org/wiki/%D0%92%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%A1%D0%B0%D0%B9%D0%BB%D0%B0%D0%BD%D0%B3%D0%B0%D0%BD_%D0%BC%D3%99%D0%BA%D0%B0%D0%BB%D3%99%D0%BB%D3%99%D1%80">tt:Tatar</a>,
<a href="http://uk.wikipedia.org/wiki/%D0%92%D1%96%D0%BA%D1%96%D0%BF%D0%B5%D0%B4%D1%96%D1%8F:%D0%92%D0%B8%D0%B1%D1%80%D0%B0%D0%BD%D1%96_%D1%81%D1%82%D0%B0%D1%82%D1%82%D1%96">uk:Ukrainian</a>,
<a href="http://ur.wikipedia.org/wiki/%D9%85%D9%86%D8%B5%D9%88%D8%A8%DB%81:%D9%85%D9%86%D8%AA%D8%AE%D8%A8_%D9%85%D8%B6%D9%85%D9%88%D9%86">ur:Urdu</a>,
<a href="http://vi.wikipedia.org/wiki/Wikipedia:B%C3%A0i_vi%E1%BA%BFt_ch%E1%BB%8Dn_l%E1%BB%8Dc">vi:Vietnamese</a>,
<a href="http://vo.wikipedia.org/wiki/V%C3%BCkiped:Yegeds_gudik">vo:Volap?k</a>, and
<a href="http://zh.wikipedia.org/wiki/Wikipedia:%E7%89%B9%E8%89%B2%E6%9D%A1%E7%9B%AE">zh:Chinese</a>.
</p>

<p>
Copies of the data sets generated in May 2010 and February 2013 can be download <a href="http://jeffkubina.org/data/wfa">here</a>.
</p>

=end html

=cut

1;
# The preceding line will help the module return a true value
