package WWW::Wikipedia::TemplateFiller::Source::PubmedId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;
use Carp;

use Date::Calc qw/ Month_to_Text Decode_Month /;
use WWW::Search;
use HTML::Entities;
use Lingua::EN::Titlecase;

my %Journals = (
  Science => 'Science (journal)',
);

sub new {
  my( $pkg, %attrs ) = @_;
  $attrs{__search} = new WWW::Search('PubMedLite');
  return bless \%attrs, $pkg;
}

sub get {
  my( $self, $pmid ) = @_;

  my $article = $self->_search($pmid);

  die "no article matches the given PubMed ID ($pmid)" unless $article;

  # Strip trailing period from title if requested
  unless( $self->{dont_strip_trailing_period} ) {
    $article->{title} =~ s/\.$//;
  }

  my $lang = $article->{language_name} eq 'English' ? undef : $article->{language_name};

  my @authors = ref $article->{authors} ? @{ $article->{authors} } : ();
  my $author_list = $self->_author_list( \@authors, dont_use_etal => 1 );

  for my $field ( qw/ title journal_abbreviation / ) {
    $article->{$field} =~ s/\=/encode_entities('&#61;')/ge;
  }

  return $self->__source_obj( {
    __source_url => $article->url,
    %$article,
    author => $author_list,
    _authors => \@authors,
    language => $lang,
  } );
}

sub _author_list {
  my( $self, $authors, %args ) = @_;
  my @authors = ref $authors ? @$authors : split( /\s*,\s*/, $authors );
  my $all_authors = join ', ', @authors;
  return $args{dont_use_etal}
    ? $all_authors
    : @authors > 6
        ? join( ', ', @authors[0..2] ) . ", ''et al.''"
        : $all_authors;
}

sub template_name { 'cite journal' }
sub template_ref_name { 'pmid'.shift->{pmid} }
sub template_basic_fields {
  my( $self, %args ) = @_;

  my $journal_title = '';
  if( $args{full_journal_title} ) {
    $journal_title = Lingua::EN::Titlecase->new( $self->{journal} || '' )->title;
  } else {
    $journal_title = $self->{journal_abbreviation};
  }

  my $pages = $self->{page};
  my $ndash = decode_entities('&ndash;');
  $pages =~ s{\-}{$ndash}g;

  my $month = Decode_Month( $self->{month} ) if $self->{month};
     $month = Month_to_Text( $month ) if $month;

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    author   => { value => $self->{author} },
    title    => { value => $self->{title} },
    language => { value => $self->{language}, show => 'if-filled' },
    journal  => { value => $journal_title },
    volume   => { value => $self->{volume} },
    issue    => { value => $self->{issue} },
    pages    => { value => $pages },
    year     => { value => $self->{year} },
    month    => { value => $month,            show => 'if-filled' },
    pmid     => { value => $self->{pmid} },
    pmc      => { value => $self->{pmc_id},   show => 'if-filled' }, 
    doi      => { value => $self->{doi} },
    url      => { value => $self->{text_url} },
    issn     => { value => '',                show => 'if-extended' },
  );

  return \%fields;
}

my %JournalLinks = (
  'Science' => 'Science (journal)',
);

sub template_output_fields {
  my( $self, %args ) = @_;

  my $add_accessdate = exists $args{add_accessdate} ? $args{add_accessdate} : 1;

  tie( my %fields, 'Tie::IxHash' );
  $fields{accessdate} = { value => $self->__today_and_now } if $add_accessdate;
  $fields{url}        = { value => '' } if ! $args{add_text_url} or ( $self->{doi} and $args{omit_url_if_doi_filled} );
  $fields{author}     = { value => $self->_author_list( $self->{_basic_fields}->{author}->{value}, dont_use_etal => $args{dont_use_etal} ) };

  if( $args{link_journal} ) {
    my $journal_title = $self->{_basic_fields}->{journal}->{value};
    if( my $link = $JournalLinks{$journal_title} ) {
      $fields{journal} = { value => sprintf( '[[%s|%s]]', $link, $journal_title ) };
    } else {
      $fields{journal} = { value => sprintf( '[[%s]]', $journal_title ) };
    }
  }

  return \%fields;
}

1;
