package Text::Corpus::NewYorkTimes::Document;

use strict;
use warnings;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Path::Class qw(dir file);
use Date::Manip;

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION = '1.01';
	@ISA     = qw();
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Parse NYT article for research.

=head1 NAME

C<Text::Corpus::NewYorkTimes::Document> - Parse NYT article for research.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Text::Corpus::NewYorkTimes::Document> provides methods for accessing specific
portions of news articles from the New York Times corpus.

=head1 CONSTRUCTOR

=head2 C<new>

The constructor C<new> creates an instance of the C<Text::Corpus::NewYorkTimes::Document> class with the following
parameters:

=over

=item C<filename>

 filename => '...'

C<filename> is the path name to the XML document that is to be parsed.

=item C<dtdname>

 dtdname => '...'

C<dtdname> is the path name to the data type definition file provided with
the corpus;  it is usually something like C<.../nyt_corpus/dtd/nitf-3-3.dtd>. If
not defined an attempt is made to located it using the path provided by
C<filename>.

=back

=cut

# create the XPath object.
# filename => path to object.
{
  my $libxmlParser;
  my $dtdloaded;

  sub new
  {
    # create the class object.
    my ($Class, %Parameters) = @_;
    my $Self = bless {}, ref($Class) || $Class;

    # make sure a file path is defined.
    my $filename;
    $filename = $Parameters{filename} if exists $Parameters{filename};
    $filename = $Parameters{uri} if exists $Parameters{uri};
    	
  	# create the parser just once, not thread safe.
  	unless (defined ($libxmlParser))
  	{
      $libxmlParser = XML::LibXML->new();
      $libxmlParser->load_ext_dtd(0);
      $libxmlParser->no_network(1);

      if (!defined ($dtdloaded) && exists ($Parameters{dtdname}) && -f $Parameters{dtdname})
      {
        $libxmlParser->load_catalog($Parameters{dtdname});
        $dtdloaded = 1;
      }
      elsif (!defined ($dtdloaded))
      {
        my $dtdFiles = findDtdFiles ($filename);
        foreach my $file (@$dtdFiles)
        {
          $libxmlParser->load_catalog ($file);
        }
        $dtdloaded = 1;
      }
  	}
  	
  	if (defined ($filename))
  	{
  	  $Self->{filePath} = $filename;
      my $doc = $libxmlParser->parse_file($filename);
      $Self->{xpathEngine} = XML::LibXML::XPathContext->new($doc);
  	}

  	return $Self;
  }
}

# attempts to locate the dtd files given the location of one of the xml files
# in the corpus. assumes that dtd directory has not been moved after the
# corpus was extracted.
sub findDtdFiles
{
  my $XmlFilename = dir ($_[0])->absolute;
  my @dirs = $XmlFilename->dir_list;
  while (@dirs)
  {
    if ($dirs[-1] eq 'data')
    {
      pop @dirs;
      last;
    }
    pop @dirs;
  }
  my $dataFolder = Path::Class::Dir->new(@dirs, 'dtd');

  my @dtdFiles;
  if (-d $dataFolder)
  {
    while (my $file = $dataFolder->next)
    {
      next unless -f $file;
      my $fileStr = $file->stringify;
      push @dtdFiles, $fileStr if ($fileStr =~ /\.dtd$/i);
    }
  }
  return \@dtdFiles;
}

=head1 METHODS

=head2 C<getBody>

 getBody ()

C<getBody> returns an array reference of strings of sentences that are the body of the article.

=cut

sub getBody
{
  my $Self = shift;

  # if already computed return the body.
  return $Self->{body} if exists $Self->{body};

  # get the article body.
  my @linesOfText;
  my @nodes = $Self->{xpathEngine}->findnodes('/nitf/body/body.content/block[@class="full_text"]/p');
  foreach my $node (@nodes)
  {
    push @linesOfText, $node->textContent();
  }
  $Self->{body} = \@linesOfText;
  return $Self->{body} unless (@linesOfText);

  # copy the first paragraph.
  my $leadParagraph = $linesOfText[0];

  # pull off the word LEAD if it exists.
  $leadParagraph =~ s/^\s*LEAD\s*:*\s*//i;

  # if the lead paragraph reoccurs, delete it, assuming it is exact.
  my $leadParagraphReoccures = 0;
  for (my $i = 1 ; $i < @linesOfText ; $i++)
  {
    if (index($linesOfText[$i], $leadParagraph) > -1)
    {
      $leadParagraphReoccures = 1;
      last;
    }
  }

  # pop off the lead paragraph if it repeats in the text body.
  shift @linesOfText if ($leadParagraphReoccures);

  # return the title and lines of body text.
  $Self->{body} = \@linesOfText;
  return $Self->{body};
}

=head2 C<getCategories>

 getCategories (type => 'all')

The method C<getCategories> returns the categories of C<type> assigned to the document, where
C<type> must be C<'all'>, C<'controlled'>, or C<'uncontrolled'>. The C<'uncontrolled'>
categories are those assigned to the
document by an editor without machine assistance, the C<'controlled'> categories
are those assigned with machine assistance. The type C<'all'> returns the union of the
categories from C<'controlled'> and C<'uncontrolled'>. The default is C<'all'>.

=cut

# get the categories assigned to the document.
sub getCategories
{
  my ($Self, %Parameters) = shift;

  # set the category type.
  my $type = 'a';
  $type = lc substr ($Parameters{type}, 0, 1) if (exists ($Parameters{type}) && defined ($Parameters{type}) && length ($Parameters{type}));

  # return the list of categories.
  if ($type eq 'c')
  {
    return $Self->getCategoriesControlled;
  }
  elsif ($type eq 'u')
  {
    return $Self->getCategoriesUncontrolled;
  }
  else
  {
    return $Self->getCategoriesAll;
  }
}

# get the categories assigned to the document by a human editor.
sub getCategoriesUncontrolled
{
  my $Self = shift;

  # return the categories if previously computed.
  return $Self->{categories_uncontrolled} if exists $Self->{categories_uncontrolled};

  # below is a list of the xpath expressions to get all the hand assigned categories.
  my @xpathExpressions =
  (
  '/nitf/head/docdata/identified-content/classifier[@class="indexing_service" and @type="biographical_categories"]', # 2.2.3 biographic categories
  '/nitf/head/docdata/identified-content/classifier[@class="indexing_service" and @type="descriptor"]', # 2.2.15 descriptors
  '/nitf/head/docdata/identified-content/location[@class="indexing_service"]', # 2.2.22 locations
  '/nitf/head/docdata/identified-content/classifier[@class="indexing_service" and @type="names"]', # 2.2.23 names
  '/nitf/head/docdata/identified-content/org[@class="indexing_service"]', # 2.2.34 organizations
  '/nitf/head/docdata/identified-content/person[@class="indexing_service"]', # 2.2.36 people
  '/nitf/head/docdata/identified-content/object.title[@class="indexing_service"]', # 2.2.45 titles
  );

  # get the categories.
  my @categories;
  foreach my $xpathExpression (@xpathExpressions)
  {
    my @nodeset = $Self->{xpathEngine}->findnodes($xpathExpression);
    foreach my $node (@nodeset)
    {
      push @categories, $node->textContent();
    }
  }

  # remove duplicative, then cache and return the categories.
  my %uniqueCategories = map {(lc $_, $_)} sort @categories;
  @categories = sort values %uniqueCategories;
  $Self->{categories_uncontrolled} = \@categories;
  return $Self->{categories_uncontrolled};
}

# get the categories assigned to the document by a computer and verified by a human editor.
sub getCategoriesControlled
{
  my $Self = shift;

  # return the categories if previously computed.
  return $Self->{categories_controlled} if exists $Self->{categories_controlled};

  # below is a list of the xpath expressions to get all the hand assigned categories.
  my @xpathExpressions =
  (
  '/nitf/head/docdata/identified-content/classifier[@class="online_producer" and @type="general_descriptor"]', # 2.2.17 general online descriptors
  '/nitf/head/docdata/identified-content/classifier[@class="online_producer" and @type="descriptor"]', # 2.2.26 online descriptors
  '/nitf/head/docdata/identified-content/location[@class="online_producer"]', # 2.2.29 online locations
  '/nitf/head/docdata/identified-content/org[@class="online_producer"]', # 2.2.30 online organizations
  '/nitf/head/docdata/identified-content/person[@class="online_producer"]', # 2.2.31 online people
  '/nitf/head/docdata/identified-content/object.title[@class="online_producer"]', # 2.2.33 online titles
  );

  # get the categories.
  my @categories;
  foreach my $xpathExpression (@xpathExpressions)
  {
    my @nodeset = $Self->{xpathEngine}->findnodes($xpathExpression);
    foreach my $node (@nodeset)
    {
      push @categories, $node->textContent();
    }
  }

  # remove duplicative, then cache and return the categories.
  my %uniqueCategories = map {(lc $_, $_)} sort @categories;
  @categories = sort values %uniqueCategories;
  $Self->{categories_controlled} = \@categories;
  return $Self->{categories_controlled};
}

sub getCategoriesAll
{
  my $Self = shift;

  # return the categories if previously computed.
  return $Self->{categories_all} if exists $Self->{categories_all};

  # get the controlled and uncontrolled categories.
  my $categoriesControlled = $Self->getCategoriesControlled;
  my $categoriesUncontrolled = $Self->getCategoriesUncontrolled;

  # remove duplicative, then cache and return the merged list of categories.
  my %uniqueCategories = (map {(lc $_, $_)} sort (@{$categoriesControlled}, @{$categoriesUncontrolled}));
  my @categoriesAll = sort values %uniqueCategories;
  $Self->{categories_all} = \@categoriesAll;
  return $Self->{categories_all};
}

# The method getBaseDirAndFileName returns the pair (base-directory, base-file-name) of the
# document. For example, if the document has path nyt_corpus/data/1999/11/26/1156340.xml,
# then the pair returned is ('1999/11/26', '1156340').
sub getBaseDirAndFileName
{
  my $Self = shift;
  return ($1, $2) if ($Self->{filePath} =~ m|(\d\d\d\d.\d\d.\d\d).(\d{7})\.xml$|);
  return undef;
}

=head2 C<getContent>

 getContent ()

The method C<getContent> returns the content of the document as an array reference of the text
where each item in the array is a sentence, with the first sentence being the headline or title
of the article. If the lead sentence equals the headline of the article, then the headline is
not prefixed to the list.

=cut

# get the content of the document removing the repeating lead paragraph if it exists.
sub getContent
{
  my $Self = shift;

  # if already computed return the content.
  return $Self->{content} if exists $Self->{content};
  my $title = $Self->getTitle;
  my $body = $Self->getBody;

  # return the title and lines of body text.
  $Self->{content} = [ @$title, @$body ];
  return $Self->{content};
}

=head2 C<getDate>

 getDate (format => '%g')

C<getDate> returns the date and time of the article in the format speficied by C<format> that uses the print
directives of L<Date::Manip::Date|Date::Manip::Date/PRINTF_DIRECTIVES>.
The default is to return the date and time in RFC2822 format.

=cut

# return the date of the article
sub getDate
{
  my ($Self, %Parameters) = @_;

  # get the date/time format.
  my $dateFormat = '%g';
  $dateFormat = $Parameters{format} if (exists ($Parameters{format}));

  # if date already exists and is defined, return it now.
  return UnixDate ($Self->{date}, $dateFormat) if (exists ($Self->{date}) && defined ($Self->{date}));

  # if date exists but could not be parsed, returned undefined.
  return undef if (exists ($Self->{date}));

  # get the article date.
  my @dates;
  my @nodes = $Self->{xpathEngine}->findnodes('/nitf/head/pubdata/@date.publication');
  foreach my $node (@nodes)
  {
    push @dates, $node->textContent();
  }

  my $date;
  foreach my $foundDate (@dates)
  {
    my $pubDate = ParseDate ($foundDate);
    if (defined ($pubDate) && length ($pubDate))
    {
      $date = $pubDate;
      last;
    }
  }

  # return the date.
  return undef unless defined $date;
  $Self->{date} = $date;
  return UnixDate ($Self->{date}, $dateFormat);
}

=head2 C<getDescription>

  getDescription ()

C<getDescription> returns an array reference of strings of sentences that
describe the articles content.

=cut

sub getDescription
{
  my $Self = shift;
  return $Self->{description} if exists $Self->{description};

  # get the article description.
  my @linesOfText;
  my @nodes = $Self->{xpathEngine}->findnodes('/nitf/body/body.head/abstract');
  foreach my $node (@nodes)
  {
    push @linesOfText, $node->textContent();
  }

  $Self->{description} = \@linesOfText;
  return $Self->{description};
}

=head2 C<getTitle>

 getTitle ()

C<getTitle> returns an array reference of strings, usually one, of the title of the article.

=cut

sub getTitle
{
  my $Self = shift;

  # if already computed return the title.
  return $Self->{title} if exists $Self->{title};

  # get the print headline.
  my @titleLines;
  my @nodes = $Self->{xpathEngine}->findnodes('/nitf/body[1]/body.head/hedline/hl1');
  foreach my $node (@nodes)
  {
    push @titleLines, $node->textContent();
  }
  $Self->{title} = \@titleLines;
  return $Self->{title};
}

=head2 C<getUri>

  getUri (type => 'file')

C<getUri> returns the URI of the document where C<type> must be C<'file'> or C<'url'>.
If C<type> is C<'file'>, the file path of the document is returned; otherwise the URL
of the document is returned. The default is C<'file'>.

=cut

sub getUri
{
  my ($Self, %Parameters) = shift;

  # set the category type.
  my $type = 'f';
  $type = lc substr ($Parameters{type}, 0, 1) if (exists ($Parameters{type}) && defined ($Parameters{type}) && length ($Parameters{type}));
  return $Self->{filePath} if ($type eq 'f');
  return $Self->getUrl;
}

sub getUrl
{
  my $Self = shift;

  # return the url if previously computed.
  return $Self->{url} if exists $Self->{url};

  # get the possible urls.
  my @urls;
  my @nodeset = $Self->{xpathEngine}->findnodes('/nitf/head/meta[@name="alternate_url"]/@content');
  foreach my $node (@nodeset)
  {
    push @urls, $node->textContent();
  }

  if (@urls < 1)
  {
    @nodeset = $Self->{xpathEngine}->findnodes('/nitf/head/pubdata/@ex-ref');
    foreach my $node (@nodeset)
    {
      push @urls, $node->textContent();
    }
  }

  # cache and return the url.
  $Self->{url} = $urls[0];
  return $Self->{url};
}

sub DESTROY
{
  my $Self = shift;
  undef $Self;
}

=head1 INSTALLATION

For installation instructions see L<Text::Corpus::NewYorkTimes>.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

nyt, new york times, english corpus, information processing

=head1 SEE ALSO

=begin html

This module requires the <a href="http://www.ldc.upenn.edu/Catalog/CatalogEntry.jsp?catalogId=LDC2008T19">The New York Times Annotated Corpus</a>
from the Linguistic Data Consortium; discussions about the corpus are moderated at the
Google Group called <a href="http://groups.google.com/group/nytnlp">The New York Times Annotated Corpus Community</a>.

=end html

L<Log::Log4perl>, L<Text::Corpus::NewYorkTimes>, L<XML::LibXML>, L<XML::LibXML::XPathContext>

=cut

1;
# The preceding line will help the module return a true value
