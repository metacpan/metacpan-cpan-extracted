package Text::Corpus::CNN::Document;
use strict;
use warnings;
use HTML::TreeBuilder::XPath;
use Lingua::EN::Sentence qw(get_sentences);
use Date::Manip;

BEGIN {
  use Exporter ();
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = '1.02';
  @ISA     = qw();
  @EXPORT      = qw();
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Parse CNN article for research.

=head1 NAME

C<Text::Corpus::CNN::Document> - Parse CNN article for research.

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
  my $document = $corpus->getDocument (index => 0);
  dump $document->getBody;
  dump $document->getCategories;
  dump $document->getContent;
  dump $document->getDate;
  dump $document->getDescription;
  dump $document->getHighlights;
  dump $document->getTitle;
  dump $document->getUri;

=head1 DESCRIPTION

C<Text::Corpus::CNN::Document> provides methods for accessing specific
portions of CNN news articles for personnel researching and testing of information
processing methods.

Read the CNN Interactive Service Agreement to ensure you abide with their
Service Agreement when using this module.

=head1 CONSTRUCTOR

=head2 C<new>

The constructor C<new> creates an instance of the C<Text::Corpus::CNN::Document>
class with the following parameters:

=over

=item C<htmlContent>

  htmlContent => '...'

C<htmlContent> must be a string containing the HTML of the document to be parsed. The
string should already be encoded as a Perl internal string.

=item C<uri>

  uri => '...'

C<uri> must be a string containing the URL of the document provided by C<htmlContent>; it is
also returned as the document's unique identifier with C<getUri>.

=item C<encoding>

  encoding => '...'

C<encoding> is the encoding that the HTML content of the document uses. It is
returned by C<getEncoding>.

=back

=cut

# htmlContent => 'html of page' to object.
sub new
{
  my ($Class, %Parameters) = @_;
	my $Self = bless {}, ref($Class) || $Class;
	
  $Self->{htmlParser} = HTML::TreeBuilder::XPath->new;
  $Self->{htmlContent} = $Parameters{htmlContent};
  $Self->{encoding} = $Parameters{encoding};

  # assuming here that the paser will convert the text from the pages encoding
  # to Perl's internal string representation.
  $Self->{htmlParser}->parse($Self->{htmlContent});

  # store the doc id and url.
  $Self->{uri} = $Parameters{uri} if exists $Parameters{uri};
  return $Self;
}

=head1 METHODS

=head2 C<getBody>

 getBody ()

C<getBody> returns an array reference of strings of sentences that are the body of the document.

=cut

# returns the body of the article.
sub getBody
{
  my $Self = shift;

  # if body already exists, return it now.
  return $Self->{body} if exists $Self->{body};

  # get the article body.
  my @linesOfText = $Self->{htmlParser}->findvalues('/html/body/div/div/div/div/div/p');
  @linesOfText = $Self->{htmlParser}->findvalues('/html/body/div/div/div/div/div/div/div/div/div/p') if (@linesOfText == 0);

  # peel off wrot text.
  foreach my $line (@linesOfText)
  {
    $line =~ s/\s*E-mail to a friend Share this.*$//i;
  }

  # peel off wrot text.
  my $i;
  for ($i = 0; $i < @linesOfText; $i++)
  {
    last if ($linesOfText[$i] =~ m/contributed to this report\.\s*$/i);
    last if ($linesOfText[$i] =~ m/we will send you an e-mail with a link and code to reset your password\.\s*$/i);
  }
  $#linesOfText = $i - 1;

  # return the title and lines of body text.
  my $body = \@linesOfText;
  $Self->_trim ($body);
  $Self->{body} = $body;
  return $Self->{body};
}

=head2 C<getCategories>

  getCategories ()

C<getCategories> returns an array reference of strings of categories assigned to the document. They are
the phrases and words extracted from the
C</html/head/meta[@name="KEYWORDS"]> field in the HTML of the
document, from the 'RELATED TOPICS' section of the document, and from the URL of the document.

=cut

sub getCategories
{
  my $Self = shift;

  # return the categories if already computed.
  return $Self->{categories_all} if exists $Self->{categories_all};

  # get the categories.
  my @categories = $Self->{htmlParser}->findvalues('/html/head/meta[@name="KEYWORDS"]/@content');
  my @relatedCategories = $Self->{htmlParser}->findvalues('/html/body/div/div/div/div/div/div/div[@class="cnn_strylctcntr cnn_strylctcqrelt"]/ul/li');
  push @categories, @relatedCategories;
  @categories = split (/\,\s*/, join (',', @categories));

  # extract possible categories from the url.
  my $url = $Self->getUri();
  if ($url =~ m|/\d+/([^/]+?)/index.html|i)
  {
    my $urlCategories = $1;
    my @urlCategories = split (/\./, $urlCategories);
    push @categories, @urlCategories;
  }
  $Self->_trim (\@categories);

  # remove duplicative, cache, and return the categories.
  my %uniqueCategories = map {(lc $_, $_)} sort @categories;
  @categories = grep {length ($_)} sort values %uniqueCategories;
  $Self->{categories_all} = \@categories;
  return $Self->{categories_all};
}

=head2 C<getContent>

 getContent ()

C<getContent> returns an array reference of strings of sentences that form the
content of the document, which are the title and body of the document.

=cut

# returns the content of the article.
sub getContent
{
  my $Self = shift;

  # if content already exists, return it now.
  return $Self->{content} if exists $Self->{content};

  # get the headline.
  my @linesOfText = @{$Self->getTitle};

  # get the article content.
  push @linesOfText, @{$Self->getBody};

  # copy the first paragraph.
  my $leadParagraph = $linesOfText[0];

  # if the lead paragraph reoccurs, delete it, assuming it is exact.
  my $leadParagraphRepeats = 0;
  for (my $i = 1 ; $i < @linesOfText ; $i++)
  {
    if (index($linesOfText[$i], $leadParagraph) > -1)
    {
      $leadParagraphRepeats = 1;
      last;
    }
  }

  # pop off the lead paragraph if it repeats in the text body.
  shift @linesOfText if ($leadParagraphRepeats);

  # peel off wrot text.
  foreach my $line (@linesOfText)
  {
    $line =~ s/\s*E-mail to a friend Share this.*$//i;
  }

  # only use lines with at least one letter or number in them.
  my @fullLines;
  foreach my $line (@linesOfText)
  {
    if ($line =~ m/[\p{L}\p{N}]/)
    {
      push @fullLines, $line;
    }
  }

  # return the title and lines of body text.
  my $content = \@fullLines;
  $Self->_trim ($content);
  $Self->{content} = $content;
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

  # if date already exists and defined, return it now.
  return UnixDate ($Self->{date}, $dateFormat) if (exists ($Self->{date}) && defined ($Self->{date}));

  # if date exists but could not be parsed, returned undefined.
  return undef if (exists ($Self->{date}));

  # get the date (for the new format).
  my $nodes = $Self->{htmlParser}->findnodes('//*[@class="cnn_strytmstmp"]/script');
  my $date = undef;
  foreach my $node (@$nodes)
  {
    my $javascript = $node->as_XML_compact();
    while ($javascript =~ m/document\.write\(\'(.+?)\'\)/g)
    {
      my $parsedDate = ParseDate ($1);
      if (defined ($parsedDate) && length ($parsedDate))
      {
        $date = $parsedDate;
        last;
      }
    }
  }

  # get the date (for the old format).
  unless (defined ($date))
  {
    my $nodes = $Self->{htmlParser}->findnodes('//*[@id="cnnTimeStamp"]/script');
    foreach my $node (@$nodes)
    {
      my $javascript = $node->as_XML_compact();
      while ($javascript =~ m/\'(.+?)\'/g)
      {
        my $cnnDate = $1;
        $cnnDate =~ s/updated//i;
        $cnnDate =~ s/\-//g;
        $cnnDate =~ s/\(.*$//g;
        $cnnDate =~ s/\s+/ /g;
        if ($cnnDate =~ m/(\w+) (\d+)[, ]+(\d{4}) (\d{2})(\d{2}) (\w+)/)
        {
          $cnnDate = "$1 $2 $4:$5 $6 $3";
        }
        my $parsedDate = ParseDate ($cnnDate);
        if (defined ($parsedDate) && length ($parsedDate))
        {
          $date = $parsedDate;
          last;
        }
      }
    }
  }

  # return the date.
  return undef unless defined $date;
  $Self->{date} = $date;
  return UnixDate ($Self->{date}, $dateFormat);
}

=head2 C<getDescription>

  getDescription ()

C<getDescription> returns an array reference of strings of sentences, usually one, that
describes the document content. It is from the C</html/head/meta[@name="description"]>
field in the HTML of the document.

=cut

sub getDescription
{
  my $Self = shift;

  # return the description if already computed.
  return $Self->{description} if exists $Self->{description};

  # get the $description.
  my @descriptions = $Self->{htmlParser}->findvalues('/html/head/meta[@name="description"]/@content');
  $Self->_trim (\@descriptions);

  # pull out the sentences.
  my @sentences = ();
  foreach my $description (@descriptions)
  {
    next unless defined $description;
    next unless length $description;
    push @sentences, @{get_sentences ($description)};
  }

  my $description = \@sentences;
  $Self->_trim ($description);
  $Self->{description} = $description;
  return $Self->{description};
}


=head2 C<getEncoding>

  getEncoding ()

C<getEncoding> returns the original encoding used by the HTML of the document.

=cut

sub getEncoding
{
  my $Self = shift;
  return $Self->{encoding} if exists $Self->{encoding};
  return undef;
}


=head2 C<getHighlights>

  getHighlights ()

C<getHighlights> returns an array reference of the highlights of the document.

=cut

sub getHighlights
{
  my $Self = shift;
  return $Self->{highlights} if exists $Self->{highlights};

  # get the categories.
  my @possibleHighlights = $Self->{htmlParser}->findvalues('/html/body/div/div/div/div/div/div/div/ul[@class="cnn_bulletbin cnnStryHghLght"]/li');
  @possibleHighlights = $Self->{htmlParser}->findvalues('/html/body/div/div/div/div[@id="cnnHeaderRightCol"]/ul/li') if (@possibleHighlights == 0);
  @possibleHighlights = $Self->{htmlParser}->findvalues('/html/body/div/div/div/div/div[@id="cnnHeaderRightCol"]/ul/li') if (@possibleHighlights == 0);

  my @highlights= ();
  foreach my $highlight (@possibleHighlights)
  {
    next if ($highlight eq 'Story Highlights');
    last if ($highlight =~ m/^Next Article/i);
    push @highlights, $highlight;
  }
  $Self->_trim (\@highlights);
  $Self->{highlights} = \@highlights;
  return $Self->{highlights};
}


=head2 C<getHtml>

  getHtml ()

C<getHtml> returns the HTML of the document as a string.

=cut

sub getHtml
{
  my $Self = shift;
  return $Self->{htmlContent} if exists $Self->{htmlContent};
  return undef;
}


=head2 C<getTitle>

 getTitle ()

C<getTitle> returns an array reference of strings, usually one, of the title of the document.

=cut

# return the title of the article
sub getTitle
{
  my $Self = shift;

  # if title already exists, return it now.
  return $Self->{title} if exists $Self->{title};

  # get the headline.
  my @titleLines = $Self->{htmlParser}->findvalues('/html/head/title/div/div/div/h1');
  unless (@titleLines)
  {
    @titleLines = $Self->{htmlParser}->findvalues('/html/head/title');
  }
  foreach my $line (@titleLines)
  {
    $line =~ s/\s*\-\s*CNN\.com\s*$//i;
  }

  # return the title.
  my $title = [@titleLines];
  $Self->_trim ($title);
  $Self->{title} = $title;
  return $Self->{title};
}

=head2 C<getUri>

  getUri ()

C<getUri> returns the URL of the document.

=cut

sub getUri
{
  my $Self = shift;
  return $Self->{uri};
}

# trims off white space from the beginning and end of a string.
sub _trim
{
  my $Self = shift;
  my $TextLinesToTrim = shift;
  foreach my $line (@$TextLinesToTrim)
  {
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
  }
  return undef;
}

# since we need to call delete on html::treebuilder, we implement DESTORY.
sub DESTROY
{
  my $Self = shift;
  $Self->{htmlParser}->delete if exists $Self->{htmlParser};
  undef $Self;
}

=head1 INSTALLATION

For installation instructions see L<Text::Corpus::CNN>.

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

cnn, cable news network, english corpus, information processing

=head1 SEE ALSO

=begin html

Read the <a href="http://www.cnn.com/interactive_legal.html">CNN Interactive Service Agreement</a> to ensure you abide with their
Service Agreement when using this module.

=end html

L<Date::Manip::Date>, L<HTML::TreeBuilder::XPath>, L<Lingua::EN::Sentence>, L<Log::Log4perl>,

=cut

1;
# The preceding line will help the module return a true value
