package Text::Corpus::Inspec::Document;

use strict;
use warnings;
use File::Slurp;
use Lingua::EN::Sentence qw(get_sentences);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.00';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Parse Inspec abstract for research.

=head1 NAME

C<Text::Corpus::Inspec::Document> - Parse Inspec abstract for research.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Text::Corpus::Inspec::Document> provides methods for accessing specific
portions of Inspec abstracts for researching and testing of information
processing methods.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of the C<Text::Corpus::Inspec> class with the following
parameters:

=over

=item C<filename> or C<uri>

 filename => '...' or uri => '...'

C<filename> or C<uri> must be the path name to the corpus document to be parsed. If the file
does not exist, C<undef> is returned. The path provided is returned by L<getUri>.

=back

=cut

sub new
{
  # create the class object.
  my ($Class, %Parameters) = @_;
  my $Self = bless {}, ref($Class) || $Class;

  # make sure a file path is defined.
  my $filename;
  $filename = $Parameters{filename} if exists $Parameters{filename};
  $filename = $Parameters{uri} if exists $Parameters{uri};

  # make sure the file exists;
  return undef unless defined $filename;
  return undef unless -f $Parameters{filename};

  # read in the file contents.
  my @lines = read_file ($Parameters{filename});

  # get the title.
  my $title = shift @lines;
  my $line = shift @lines;
  while (defined ($line) && ($line =~ m/^\s+/))
  {
    $title .= $line;
    $line = shift @lines;
  }
  $title =~ s/[\x00-\x20]+/ /g;
  $title =~ s/^\s+//;
  $title =~ s/\s+$//;
  $title = get_sentences ($title);
  $Self->{title} = $title;

  # join the remaining lines into the content.
  my $content = join ('', $line, @lines);
  $content =~ s/[\x00-\x20]+/ /g;

  # parse out the sentences.
  my $sentences = get_sentences ($content);
  $Self->{body} = $sentences;

  # store the list of sentences.
  $Self->{content} = [@$title, @$sentences];

  # create the name of the file with uncontrol categories.
  my $uncontrFile = $Parameters{filename};
  substr ($uncontrFile, -length ('abstr')) = 'uncontr';

  # read in the uncontroled categories and parse them into a list.
  $Self->{categories_uncontolled} = read_file ($uncontrFile);
  if (defined ($Self->{categories_uncontolled}))
  {
    $Self->{categories_uncontolled} = _normalizeCategories ($Self->{categories_uncontolled});
  }
  else
  {
    $Self->{categories_uncontolled} = [];
  }

  # create the name of the file with uncontrol categories.
  my $contrFile = $Parameters{filename};
  substr ($contrFile, -length ('abstr')) = 'contr';

  # read in the controlled categories and parse them into a list.
  $Self->{categories_contolled} = read_file ($contrFile);
  if (defined ($Self->{categories_contolled}))
  {
    $Self->{categories_contolled} = _normalizeCategories ($Self->{categories_contolled});
  }
  else
  {
    $Self->{categories_contolled} = [];
  }

  # build the list of all categories
  my %allCategories = (map {(lc $_, $_)} (@{$Self->{categories_uncontolled}}, @{$Self->{categories_contolled}}));
  $Self->{categories_all} = [sort values %allCategories];

  # store the uri of the document.
  $Self->{uri} = $Parameters{filename};

  return $Self;
}

# parses a string of categories into an array of strings.
# returns the list of categories as an array reference.
sub _normalizeCategories
{
  my $Categories = shift;

  $Categories =~ s/[\x00-\x20]+/ /g;
  my @categories = split (/;\s*/, $Categories);
  foreach my $category (@categories)
  {
    $category =~ s/^\s+//;
    $category =~ s/\s+$//;
  }

  # return duplicative categories.
  my %uniqueCategories = map {(lc $_, $_)} sort @categories;
  @categories = sort values %uniqueCategories;

  return \@categories;
}

=head1 METHODS

=head2 C<getBody>

  getBody ()

C<getBody> returns an array reference of strings of sentences that are the body of the article.

=cut

sub getBody
{
  my $Self = shift;
  return $Self->{body};
}

=head2 C<getCategories>

 getCategories (type => 'all')

The method C<getCategories> returns an array reference of strings that are the
categories assigned to the document. The C<type> must be either
C<'all'>, C<'controlled'>, or C<'uncontrolled'>, which specify the set of
categories to be returned. C<'uncontrolled'> categories are those assigned to the
document by an editor without machine assistance; whereas C<'controlled'> categories
were assigned with machine assistance. The option C<'all'> returns the union of the
categories under C<'controlled'> and C<'uncontrolled'>. The default is C<'all'>.

=cut

sub getCategories
{
  my ($Self, %Parameters) = shift;

  # set the category type.
  my $type = 'a';
  $type = lc substr ($Parameters{type}, 0, 1) if (exists ($Parameters{type}) && defined ($Parameters{type}) && length ($Parameters{type}));

  # return the list of categories.
  if ($type eq 'c')
  {
    return $Self->{categories_contolled};
  }
  elsif ($type eq 'u')
  {
    return $Self->{categories_uncontolled};
  }
  else
  {
    return $Self->{categories_all};
  }
}

=head2 C<getContent>

  getContent ()

C<getContent> returns an array reference of strings of sentences that form the
content of the article, the title and body of the article.

=cut

sub getContent
{
  my $Self = shift;
  return $Self->{content};
}

=head2 C<getTitle>

  getTitle ()

C<getTitle> returns an array reference of strings, usually one, of the title of the article.

=cut

sub getTitle
{
  my $Self = shift;
  return $Self->{title};
}

=head2 C<getUri>

  getUri ()

C<getUri> returns the URI of the document.

=cut

sub getUri
{
  my $Self = shift;
  return $Self->{uri};
}

sub DESTROY
{
  my $Self = shift;
  undef $Self;
}

=head1 INSTALLATION

For installation instructions see L<Text::Corpus::Inspec>.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

inspec, english corpus, information processing

=head1 SEE ALSO

L<File::Slurp>, L<Lingua::EN::Sentence>, L<Text::Corpus::Inspec>

=cut

1;
# The preceding line will help the module return a true value

