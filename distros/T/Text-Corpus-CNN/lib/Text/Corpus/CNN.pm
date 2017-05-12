package Text::Corpus::CNN;

use strict;
use warnings;
use Carp;

use CHI;
use LWP::Simple;
use Digest::MD5 qw(md5_hex);
use Path::Class qw(dir file);
use File::Copy;
use XML::LibXML;
use Encode;
use Log::Log4perl;
use Text::Corpus::CNN::Document;
use URI::Escape;
use HTML::Encoding 'encoding_from_html_document';
my $el = "\n";

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.02';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Make a corpus of CNN documents for research.

=head1 NAME

C<Text::Corpus::CNN> - Make a corpus of CNN documents for research.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Text::Corpus::CNN> can be used to create a temporary corpus of CNN news documents
for personal research and testing of information processing methods. Read the
CNN Interactive Service Agreement to ensure you abide by it when using this module.

The categories, description, title, etc... of a specified document
are accessed using L<Text::Corpus::CNN::Document>. Also, all errors and
warnings are logged using L<Log::Log4perl>, which should be L<initialized|Log::Log4perl/How_to_use_it>.

=head1 CONSTRUCTOR

=head2 C<new>

The constructor C<new> creates an instance of the C<Text::Corpus::CNN> class
with the following parameters:

=over

=item C<corpusDirectory>

 corpusDirectory => '...'

C<corpusDirectory> is the directory that documents are cached into using
L<CHI>. If C<corpusDirectory> is not defined,
then the path specified in the environment variable C<TEXT_CORPUS_CNN_CORPUSDIRECTORY>
is used if it is defined. If the directory defined does not exist, it will be
created. A message is logged and an exception is thrown if no directory is specified.

=back

=cut

sub new
{
  my ($Class, %Parameters) = @_;
  my $Self = bless ({}, ref ($Class) || $Class);

  # set the corpusDirectory.
  unless (exists ($Parameters{corpusDirectory}))
  {
    if (%ENV && exists ($ENV{TEXT_CORPUS_CNN_CORPUSDIRECTORY}))
    {
      $Parameters{corpusDirectory} = $ENV{TEXT_CORPUS_CNN_CORPUSDIRECTORY};
    }
  }

  # define the cache path if not defined.
  unless (exists ($Parameters{corpusDirectory}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie("'corpusDirectory' parameter is not defined.\n");
  }
  $Self->{corpusDirectory} = $Parameters{corpusDirectory};

  # make the cache directory.
  my $cacheDir = dir ($Parameters{corpusDirectory}, 'cache');
  $cacheDir->mkpath (0, 0700) unless -d $cacheDir;
  $Self->{cacheDirectory} = sprintf $cacheDir;

  # get the caching engine.
  my $cacheEngine = CHI->new (driver => 'File', root_dir => $Self->{cacheDirectory});
  croak "could not create cache within '" . $Self->{cacheDirectory} . "': $!\n" unless defined $cacheEngine;
  $Self->{cacheEngine} = $cacheEngine;

  # make the sitenews new and old directories.
  my $sitenewsNewDirectory = dir ($Self->{corpusDirectory}, 'sitenews', 'new');
  $sitenewsNewDirectory->mkpath (0, 0700) unless -e $sitenewsNewDirectory;
  $Self->{sitenewsNewDirectory} = sprintf $sitenewsNewDirectory;

  my $sitenewsOldDirectory = dir ($Self->{corpusDirectory}, 'sitenews', 'old');
  $sitenewsOldDirectory->mkpath (0, 0700) unless -e $sitenewsOldDirectory;
  $Self->{sitenewsOldDirectory} = sprintf $sitenewsOldDirectory;

  # get the site news url.
  $Self->{siteMapNewsURL} = 'http://www.cnn.com/sitemap_news.xml';
  $Self->{siteMapNewsURL} = $Parameters{siteMapNewsURL} if exists $Parameters{siteMapNewsURL};

  # set the cache expiration.
  $Self->{cacheExpiration} = 'never';
  $Self->{cacheExpiration} = $Parameters{cacheExpiration} if defined $Parameters{cacheExpiration};

  # set the delay between page fetches in seconds.
  $Self->{delayInSeconds} = 8;
  $Self->{timeOfLastPageFetch} = 0;
  $Self->{maxFetchAttempts} = 4;

  # set the verbosity level.
  $Self->{verbose} = 0;
  $Self->{verbose} = $Parameters{verbose} if exists $Parameters{verbose};

  # get the document index from the cache.
  $Self->_getIndex ();

  return $Self;
}

# used LWP::Simple::getstore to fetch the CNN sitemap_news.xml file. keeps the
# time of the last fetch in the cache.
sub _fetchNewSiteNews
{
  my $Self = shift;

  # build the path to the file it will be stored in, the name is
  # base on the epoch time.
  my $fetchTime = time;
  my $filePathName = file ($Self->{sitenewsNewDirectory}, $fetchTime . '.sitemap_news.xml');

  # if the file already exists, return; calling the function way too much.
  return undef if -e $filePathName;

  # get the cache engine.
  my $cacheEngine = $Self->{cacheEngine};

  # get the time of the last fetch.
  my $lastFetchTime = $cacheEngine->get ('lastFetchTime');
  $lastFetchTime = 0 unless defined $lastFetchTime;

  # if too soon, do not fetch. the sitemap_news.xml file is only
  # updated when new documents for indexing are posted. so don't
  # access very often.
  return undef if (time - $lastFetchTime < 10*60);

  # fetch the page and store it in a file.
  my $fetchStatus = getstore ($Self->{siteMapNewsURL}, sprintf $filePathName);
  if ($fetchStatus != 200)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("fetch status of '" . $Self->{siteMapNewsURL} . "' is " . $fetchStatus . ".\n");
  }

  # store the time fetched.
  $cacheEngine->set ('lastFetchTime', $fetchTime, 'never');

  return undef;
}

# use an xpath query to pull out the urls of the pages in
# the sitemap file. catches any exceptions thrown, most likely
# due to parsing errors.
sub _getUrlsFromSiteNewsFile
{
  my ($Self, %Parameters) = @_;

  # holds the urls in the file.
  my @urls;

  # get the file
  my $siteNewsFile = $Parameters{siteNewsFile};
  return \@urls unless defined $siteNewsFile;

  eval
  {
    # get the parser.
    my $libxmlParser = XML::LibXML->new;

    # make sure the network is not accessed.
    $libxmlParser->load_ext_dtd (0);
    $libxmlParser->no_network (1);

    # parse the file.
    my $doc = $libxmlParser->parse_file ($siteNewsFile);

    # prep the file for xpath searching.
    my $xp = XML::LibXML::XPathContext->new($doc);

    # set the default namespace prefix.
    # $xp->registerNs('x', 'http://www.google.com/schemas/sitemap/0.84');
    # TODO: make this a parameter.
    $xp->registerNs ('x', 'http://www.sitemaps.org/schemas/sitemap/0.9');

    # get the urls
    my @nodes = $xp->findnodes('/x:urlset/x:url/x:loc');
    foreach my $node (@nodes)
    {
      push @urls, $node->textContent();
    }
  };
  if ($@)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("caught exception, probably xml parsing error in file '"
                    . $siteNewsFile . "', skipping over the file: " . $@);
  }

  # if zero urls, then use regexp.
  if (@urls == 0)
  {
    # get the size of the file and log any errors.
    my $fileSize = -s $siteNewsFile;
    local *IN;
    if (!open (IN, $siteNewsFile))
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logdie ("could not open file '" . $siteNewsFile . "' for reading: $!\n");
    }

    # read the entire file into memory.
    binmode IN;
    my $fileContents;
    my $bytesRead = read (IN, $fileContents, $fileSize, 0);
    if ($fileSize != $bytesRead)
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logwarn ("problems reading from file '" . $siteNewsFile . "'.\n");
    }
    close IN;

    # parse out the urls of the documents.
    my %urls;
    while ($fileContents =~ m/<loc>(http[\x00-\xff]*?)<\/loc>/ig)
    {
      $urls{$1} = 1;
    }

    my @newUrls = keys %urls;
    my $totalUrlsFound = @newUrls;
    push @urls, @newUrls;

    # print warings that urls were found using regexp.
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("no urls found via XML parsing, $totalUrlsFound found using regular expression.\n");
  }

  return \@urls;
}

=head1 METHODS

=head2 C<getDocument>

 getDocument (index => $index, cacheOnly => 0)
 getDocument (uri => $uri, cacheOnly => 0)

C<getDocument> returns a L<Text::Corpus::CNN::Document> object for the
document with index C<$index> or uri C<$uri>. The document
indices range from zero to C<getTotalDocument()-1>; C<getDocument> returns
C<undef> if any errors occurred and logs them using L<Log::Log4perl>.

=over

=item C<index>

 index => '...'

C<index> should be the number of the document to return. It should be a
non-negative integer less than C<getTotalDocument>. If it is out of range
C<undef> is returned.

=item C<uri>

 uri => '...'

C<uri> should be the URL of the document to return. If the document is not in the cache,
it is fetched unless C<cacheOnly> evaluates to false, in that case C<undef> is returned.

=item C<cacheOnly>

 cacheOnly => 0

If C<cacheOnly> evaluates to true, then only documents in the cache are returned, otherwise C<undef> is returned. The default is false.

=back

An example:

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

=cut

sub getDocument
{
  my ($Self, %Parameters) = @_;

  # if the parameter uri is defined use it; if index is defined, use it instead.
  my $urlIndex = $Self->{urlIndex};
  my $urlHash = $Self->{urlHash};
  my $indexOfArticle;
  my $cacheOnly = exists ($Parameters{cacheOnly}) && $Parameters{cacheOnly};

  # if the index is defined and valid, use it.
  $indexOfArticle = int abs $Parameters{index} if exists $Parameters{index};
  if ($indexOfArticle >= @$urlIndex)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("document index '" . $indexOfArticle . "', has an invalid range.\n");
    $indexOfArticle = undef;
  }

  # if the index is not defined try the uri.
  if (!defined ($indexOfArticle) && exists ($Parameters{uri}))
  {
    my $url = $Parameters{uri};
    return undef unless ($url =~ /^http/);
    if (exists $urlHash->{$Parameters{uri}})
    {
      $indexOfArticle = $urlHash->{$Parameters{uri}};
    }
    else
    {
      my $totalDocuments = $Self->getTotalDocuments ();
      $urlIndex->[$totalDocuments] = $url;
      $urlHash->{$url} = $totalDocuments;
      $indexOfArticle = $totalDocuments;

      # store the urls in the cache. it is really slow to store this to the disk cache each time
      # a new document url is added.
      my $cacheEngine = $Self->{cacheEngine};
      $cacheEngine->set ('urlIndex', $urlIndex, $Self->{cacheExpiration});
    }
  }

  # if $indexOfArticle is not defined at this point, there is no article to return;
  # so log an error and return undef.
  unless (defined $indexOfArticle)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("document index and/or uri invalid, returned undefined.\n");
    return undef;
  }

  # get the articles url.
  my $url = $urlIndex->[$indexOfArticle];

  # get the html content of the article.
  my $htmlEncoding = $Self->_getArticle (index => $indexOfArticle, cacheOnly => $cacheOnly);
  return undef unless defined $htmlEncoding;

  # get the document object.
  my $document;
  eval
  {
    $document =  Text::Corpus::CNN::Document->new (htmlContent => $htmlEncoding->[0], uri => $url, encoding => $htmlEncoding->[1]);
  };
  if ($@)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("caught exception, probably html parsing error in file '"
                    . $url . "', skipping over the document: " . $@);
    $document = undef;
  }
  return $document;
}

=head2 C<getTotalDocuments>

  getTotalDocuments ()

C<getTotalDocuments> returns the total number of documents in the corpus. The index to the
documents in the corpus ranges from zero to C<getTotalDocuments() - 1>.

=cut

# return the total number of articles in the corpus. this should
# increase as update is repeatedly called.

sub getTotalDocuments
{
  my $Self = shift;
  $Self->_getIndex ();
  return scalar (@{$Self->{urlIndex}});
}

=head2 C<getURIsInCorpus>

 getURIsInCorpus ()

C<getURIsInCorpus> returns an array reference of all the URIs in the corpus.

For example:

  use Cwd;
  use File::Spec;
  use Text::Corpus::CNN;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpusDirectory = File::Spec->catfile (getcwd(), 'corpus_cnn');
  my $corpus = Text::Corpus::CNN->new (corpusDirectory => $corpusDirectory);
  dump $corpus->getURIsInCorpus;

=cut

sub getURIsInCorpus
{
  my ($Self) = @_;
  return [@{$Self->{urlIndex}}];
}

=head2 C<update>

  update (verbose => 0)

This method updates the set of documents in the corpus by fetching
any newly listed documents in the C<sitemap_news.xml> file.

=over

=item C<verbose>

  verbose => 0

If C<verbose> is positive, then after each new document is fetched a message is
logged stating the number of documents remaining to fetch and the
approximate time to completion. C<update> returns the number of documents fetched.

=back

For example:

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

=cut

# TODO: document listOfArticleUrls in pod.

sub update # (test => 1) fetches only one document for testing.
{
  my ($Self, %Parameters) = @_;

  # get the previous urls.
  my $cacheEngine = $Self->{cacheEngine};
  my $urlIndex = $Self->{urlIndex};
  my $urlHash = $Self->{urlHash};

  # if listOfUrls is defined it is used.
  my $listOfArticleUrls;
  if (exists ($Parameters{listOfArticleUrls}))
  {
    $listOfArticleUrls = $Parameters{listOfArticleUrls};
  }
  else
  {
    $listOfArticleUrls = $Self->_getListOfNewArticleUrlsViaSitemap ();
  }

  # get the total urls.
  my $totalUrls = scalar (@$urlIndex);

  # put the urls into the hash to remove dupes.
  foreach my $url (@$listOfArticleUrls)
  {
    next unless ($url =~ /^http/i);
    next if exists $urlHash->{$url};
    $urlIndex->[$totalUrls] = $url;
    $urlHash->{$url} = $totalUrls;
    ++$totalUrls;
  }

  # store the urls in the cache.
  $cacheEngine->set ('urlIndex', $urlIndex, $Self->{cacheExpiration});

  # add new documents to the cache.
  return $Self->_primeCache (%Parameters);
}

# returns the list of urls from the sitemaps files in  $Self->{sitenewsNewDirectory} and
# moves files to $Self->{sitenewsOldDirectory}.
sub _getListOfNewArticleUrlsViaSitemap
{
  my ($Self, %Parameters) = @_;

  # fetch the latest site news file.
  $Self->_fetchNewSiteNews ();

  # get the list of new sitenews files.
  local *DIR;
  opendir (DIR, $Self->{sitenewsNewDirectory}) || croak "could not read directory '" . $Self->{sitenewsNewDirectory} . "': $!\n";
  my @newSiteNewsFiles = grep {/xml$/} readdir (DIR);
  close DIR;

  # foreach file read in the list of urls.
  my %hashOfArticleUrls;
  foreach my $siteNewsFile (@newSiteNewsFiles)
  {
    # get the full path to the file.
    my $fullPathSiteNewsFile = sprintf dir($Self->{sitenewsNewDirectory}, $siteNewsFile);

    # skip the file if it is empty.
    unless (-s $fullPathSiteNewsFile)
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logwarn ("skipping over file '" . $fullPathSiteNewsFile . "' since it is empty.\n");
      next;
    }

    # get all the urls in the file.
    my $listOfArticleUrls;
    eval
    {
      $listOfArticleUrls = $Self->_getUrlsFromSiteNewsFile (siteNewsFile => $fullPathSiteNewsFile);
    };
    if ($@)
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logwarn ("caught exception, probably xml parsing error in file '"
                      . $fullPathSiteNewsFile . "', skipping over the file: " . $@);
      $listOfArticleUrls = [];
    }

    # put the urls into the hash to remove dupes.
    foreach my $url (@$listOfArticleUrls)
    {
      next unless ($url =~ /^http/i);
      $hashOfArticleUrls{$url} = 1;
    }
  }

  # move the new site maps to the old directory.
  foreach my $siteNewsFile (@newSiteNewsFiles)
  {
    # get the full path to the file.
    my $fullPathSiteNewsFileNew = sprintf dir($Self->{sitenewsNewDirectory}, $siteNewsFile);

    # get the full path to where the file is to be moved to.
    my $fullPathSiteNewsFileOld = sprintf dir($Self->{sitenewsOldDirectory}, $siteNewsFile);

    move ($fullPathSiteNewsFileNew, $fullPathSiteNewsFileOld);
  }

  return [sort keys %hashOfArticleUrls];
}

# fetches the html page of an document given its url. first it looks in the
# cache, if not there it fetches it and and places the contents in the cache.
# returns undef if problems, otherwise a string reference to the pages html
# content.
sub _getArticle
{
  my ($Self, %Parameters) = @_;

  # get the url to fetch.
  my $md5OfUrl = $Parameters{md5OfUrl} if exists $Parameters{md5OfUrl};
  my $url = $Self->{urlIndex}->[$Parameters{index}] if exists $Parameters{index};

  # need to convert url to md5hex since cache uses it as filename
  # and urls could be too long.
  $md5OfUrl = md5_hex ($url) if defined $url;

  # if the page is in the cache, return it from there.
  my $cacheEngine = $Self->{cacheEngine};
  my $pageContents = $cacheEngine->get ($md5OfUrl);
  if (defined $pageContents)
  {
    # log the cache hit.
    if ($Parameters{logCacheHitsMisses})
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->info ("cache hit: $md5OfUrl: $url\n");
    }

    # return its contents, decoded.
    my $encoding = encoding_from_html_document($pageContents, xhtml => 0);
    $encoding = encoding_from_html_document($pageContents, xhtml => 1) unless defined $encoding;
    unless (defined $encoding)
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->logwarn ("could not determine encoding, defaulting to iso-8859-1: $md5OfUrl: $url\n");
    }
    $encoding = 'iso-8859-1' unless defined $encoding;
    $pageContents = decode ($encoding, $pageContents);
    return [$pageContents, $encoding];
  }

  # log the cache hit.
  if ($Parameters{logCacheHitsMisses})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->info ("cache miss: $md5OfUrl: $url\n");
  }

  # return now if only getting from the cache.
  return undef if (exists ($Parameters{cacheOnly}) && $Parameters{cacheOnly});

  # if we tried to fetch it too many times already don't try again.
  return undef if (exists ($Self->{problemUrls}->{$url}) && ($Self->{problemUrls}->{$url} >= $Self->{maxFetchAttempts}));

  # wait before fetching the page.
  my $delay = $Self->{delayInSeconds} - (time - $Self->{timeOfLastPageFetch});
  sleep $delay if ($delay > 0);

  # fetch the page.
  $pageContents = get ($url);

  $Self->{timeOfLastPageFetch} = time;
  unless (defined ($pageContents))
  {
    $Self->{problemUrls}->{$url} += 5;
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("problems fetching page '$url'.\n");
    return undef;
  }

  # cache the page
  $cacheEngine->set ($md5OfUrl, $pageContents, $Self->{cacheExpiration});
  $Self->{urlsInCache}->{$url} = 1;

  # return its contents, decoded.
  my $encoding = encoding_from_html_document($pageContents, xhtml => 0);
  $encoding = encoding_from_html_document($pageContents, xhtml => 1) unless defined $encoding;
  unless (defined $encoding)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("could not determine encoding, defaulting to iso-8859-1: $md5OfUrl: $url\n");
  }
  $encoding = 'iso-8859-1' unless defined $encoding;
  $pageContents = decode ($encoding, $pageContents);
  return [$pageContents, $encoding];
}

# adds list of articles of the for listOfArticles => [[url, html], ..., [url, html]]
# to the index and cache. if an article is already in the cache it is not added.
# returns the total number of articles added.

sub addListOfArticles # (listOfArticles => [[url, html], ..., [url, html]])
{
  my ($Self, %Parameters) = @_;

  # get the uri index/hash.
  my $urlIndex = $Self->{urlIndex};
  my $urlHash = $Self->{urlHash};
  my $totalDocuments = $Self->getTotalDocuments ();

  # get the caching object.
  my $cacheEngine = $Self->{cacheEngine};

  # get the list of articles to add.
  my $listOfArticles = $Parameters{listOfArticles};

  my $totalAdded = 0;
  foreach my $urlHtmlPair (@$listOfArticles)
  {
    # get the url of the article.
    my $url = $urlHtmlPair->[0];

    # skip the article if already in the cache.
    if ($Self->_isDocumentInCache (url => $url) && exists ($urlHash->{$url}))
    {
      if ($Self->{verbose} > 1)
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->info ("cache hit: $url\n");
      }
      next;
    }

    if ($Self->{verbose})
    {
      my $logger = Log::Log4perl->get_logger();
      $logger->info ("cache miss: $url\n");
    }

    # get the html content of the page.
    my $htmlContent = $urlHtmlPair->[1];

    # need to convert url to md5hex since cache uses it as filename
    # and urls could be too long.
    my $md5OfUrl = md5_hex ($url);

    # cache the page.
    $cacheEngine->set ($md5OfUrl, $htmlContent, $Self->{cacheExpiration});

    # update the index to the documents.
    $urlIndex->[$totalDocuments] = $url;
    $urlHash->{$url} = $totalDocuments;
    ++$totalDocuments;
    ++$totalAdded;
  }

  # store the urls in the cache. it is really slow to store this to the disk cache each time
  # a new document url is added.
  $cacheEngine->set ('urlIndex', $urlIndex, $Self->{cacheExpiration});

  return $totalAdded;
}

# writes the contents of the cache to the file csvFile => '...' in
# csv format where each line is of the form url,html
# all formating and higher order bits are escaped using
# URI::Escape::uri_escape.

sub exportCacheToCsvFile
{
  my ($Self, %Parameters) = @_;

  # get the total documents in the cache.
  my $totalDocuments = $Self->getTotalDocuments();

  # get the path of the csv file.
  my $csvFile = $Parameters{csvFile};
  my $fh;
  unless (open ($fh, ">$csvFile"))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("could no open file '$csvFile' for writing: $!\n");
  }

  my $charsToEscape = "\x00-\x1f\x7f-\xff,";
  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    eval
    {
      # fetch the document.
      my $document = $Self->getDocument(index => $i, cacheOnly => 1);
      if (defined ($document))
      {
        # get the raw html of the document.
        my $html = $document->getHtml();
        next unless defined $html;

        # get the uri of the document.
        my $uri = $document->getUri();
        next unless defined $html;

        # escape all but letters and numbers.
        $html = uri_escape ($html, $charsToEscape);
        $uri = uri_escape ($uri, $charsToEscape);

        # write the escaped uri and html to the file.
        print $fh $uri . ',' . $html . "\n";
      }
      else
      {
        my $logger = Log::Log4perl->get_logger();
        $logger->logwarn ('problems with document number ' . $i . "; document skipped.\n");
      }
    };
  }

  close $fh;
}

sub importCsvFileIntoCache
{
  my ($Self, %Parameters) = @_;

  # get the path of the csv file.
  my $csvFile = $Parameters{csvFile};
  local *IN;
  unless (open (IN, "$csvFile"))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("could no open file '$csvFile' for reading: $!\n");
  }

  my @listOfArticles;
  while (my $line = <IN>)
  {
    # remove the end line chars.
    chop $line;

    # split the line at the comma.
    my ($uri, $htmlContent) = split (/,/, $line);

    # unescape the uri and content.
    $uri = uri_unescape ($uri);
    $htmlContent = uri_unescape ($htmlContent);
    push @listOfArticles, [$uri, $htmlContent];

    # add the list of articles to the cache.
    if (@listOfArticles > 100)
    {
      $Self->addListOfArticles (listOfArticles => \@listOfArticles);
      @listOfArticles = ();
    }
  }
  close IN;

  # add the remaining list of articles to the cache.
  if (@listOfArticles > 0)
  {
    $Self->addListOfArticles (listOfArticles => \@listOfArticles);
    @listOfArticles = ();
  }

  return undef;
}

# reads the index of the documents from the cache.
sub _getIndex
{
  my ($Self, %Parameters) = @_;

  # return if already set.
  return undef if exists $Self->{urlIndex};

  # get the index.
  my $urlIndex = $Self->{cacheEngine}->get ('urlIndex');
  my $problemUrls = $Self->{cacheEngine}->get ('problemUrls');
  my $urlsInCache = $Self->{cacheEngine}->get ('urlsInCache');

  # set the index to empty if it did not exist.
  $urlIndex = [] unless defined $urlIndex;
  $problemUrls = {} unless defined $problemUrls;
  $urlsInCache = {} unless defined $urlsInCache;

  # create the reverse hash of the index.
  my %urlHash;
  for (my $i = 0; $i < @$urlIndex; $i++)
  {
    $urlHash{$urlIndex->[$i]} = $i;
  }

  # store the index and exit.
  $Self->{urlIndex} = $urlIndex;
  $Self->{urlHash} = \%urlHash;
  $Self->{problemUrls} = $problemUrls;
  $Self->{urlsInCache} = $urlsInCache;
  return undef;
}

sub _primeCache
{
  my ($Self, %Parameters) = @_;

  # get the logger, will print a warning if not initialized.
  my $logger = Log::Log4perl->get_logger();

  # set default verbose level.
  $Parameters{verbose} = 0 unless exists $Parameters{verbose};

  # count the articles to fetch.
  my $totalDocuments = $Self->getTotalDocuments ();
  my @documentsToFetch;
  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    my $url = $Self->{urlIndex}->[$i];
    next if (exists ($Self->{problemUrls}->{$url}) && ($Self->{problemUrls}->{$url} >= $Self->{maxFetchAttempts}));
    next if exists $Self->{urlsInCache}->{$url};
    if ($Self->_isDocumentInCache (index => $i))
    {
      $Self->{urlsInCache}->{$url} = 1;
      next;
    }
    push @documentsToFetch, $i;
  }

  # fetch the documents.
  my $documentsLeft = scalar @documentsToFetch;
  my $totalDocumentsFetched = 0;

  foreach my $i (@documentsToFetch)
  {
    # compute the time remaining.
    if ($Parameters{verbose})
    {
      my $timeRemaining = $documentsLeft * $Self->{delayInSeconds};
      $timeRemaining = 1 if ($timeRemaining < 1);
      $timeRemaining = _convertDurationInSecondsToWords ($timeRemaining);
      my $message = $documentsLeft . ' documents left to fetch; time remaining about ' .
        $timeRemaining . ".\n";
      $logger->info ($message);
    }

    # fetch the document and put it in the cache.
    my $content;
    eval {$content = $Self->_getArticle (index => $i, %Parameters);};
    $Self->{problemUrls}->{$Self->{urlIndex}->[$i]} += 1 unless defined $content;

    # keep track of the documents left.
    --$documentsLeft;

    # count documents fetched.
    ++$totalDocumentsFetched;

    # if just testing fetch only one document.
    last if ($totalDocumentsFetched && exists ($Parameters{testing}));
  }

  # update the problemUrls data in the cache.
  $Self->{cacheEngine}->set ('problemUrls', $Self->{problemUrls}, $Self->{cacheExpiration});
  $Self->{cacheEngine}->set ('urlsInCache', $Self->{urlsInCache}, $Self->{cacheExpiration});

  return $totalDocumentsFetched;
}

# returns true of the document with specified md5OfUrl, url, or index is in the cache.
sub _isDocumentInCache # (index => ...)
{
  my ($Self, %Parameters) = @_;

  # get the url to check.
  my $md5OfUrl;
  $md5OfUrl = $Parameters{md5OfUrl} if exists $Parameters{md5OfUrl};

  my $url;
  $url = $Parameters{url} if exists $Parameters{url};
  $url = $Self->{urlIndex}->[$Parameters{index}] if (!defined ($url) && exists ($Parameters{index}));

  # need to convert url to md5hex since cache uses it as filename
  # and urls could be too long.
  $md5OfUrl = md5_hex ($url) if (!defined ($md5OfUrl) && defined ($url));

  # if the page is in the cache, return it from there.
  my $cacheEngine = $Self->{cacheEngine};

  return $cacheEngine->is_valid ($md5OfUrl);
}

sub _convertDurationInSecondsToWords
{
  my $DurationInSeconds = shift;

  my $duration = $DurationInSeconds;
  my $timeInPast = '';
  if ($duration < 0)
  {
    $duration = -$duration;
    $timeInPast = ' in the past';
  }

  my @timeUnits = ([60, 'seconds'], [60, 'minutes'], [24, 'hours'], [7, 'days'], [365.25/(12*7), 'weeks'], [12, 'months'],  [10, 'years']);

  foreach my $timeUnit (@timeUnits)
  {
    if ($duration < $timeUnit->[0])
    {
      $duration = int ($duration * 100) / 100;
      return $duration . ' ' . $timeUnit->[1] . $timeInPast;
    }
    $duration /= $timeUnit->[0];
  }
  return $duration . ' decades' . $timeInPast;
}

=head1 EXAMPLES

The example below will print out all the information for each document in the corpus.

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

The example below will print some of the most frequent categories of all the articles in the corpus.

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

=head1 INSTALLATION

To install the module set C<TEXT_CORPUS_CNN_FULL_TESTING> to true and
run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

The module will install if C<TEXT_CORPUS_CNN_FULL_TESTING> is not defined
or false, but little testing will be performed.

=head1 BUGS

This module uses xpath expressions to extract links and text which may become invalid
as the format of various pages change, causing a lot of bugs.

Please email bugs reports or feature requests to C<text-corpus-cnn@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Text-Corpus-CNN>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

cnn, cable news network, corpus, english corpus, information processing

=head1 SEE ALSO

=begin html

Read the <a href="http://www.cnn.com/interactive_legal.html">CNN Interactive Service Agreement</a> to ensure you abide by it
when using this module.

=end html

L<CHI>, L<Log::Log4perl>, L<Text::Corpus::CNN::Document>

=cut

1;
# The preceding line will help the module return a true value
