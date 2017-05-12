package WWW::Wikipedia::TemplateFiller::Source::ISBN;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use WWW::Scraper::ISBN;
use WWW::Mechanize;
use Tie::IxHash;
use Carp;

sub new {
  my( $pkg, %attrs ) = @_;
  $attrs{__scraper} = new WWW::Scraper::ISBN();
  $attrs{__scraper}->drivers('ISBNdb');
  $attrs{__mech} = new WWW::Mechanize();

  # isbndb_access_key must be set via WWW::Wikipedia::TemplateFiller->new( isbndb_access_key => '...' )
  $WWW::Scraper::ISBN::ISBNdb_Driver::ACCESS_KEY = $attrs{filler}->{isbndb_access_key} or die "no isbndb_access_key provided";

  return bless \%attrs, $pkg;
}

sub __scraper { shift->{__scraper} }
sub __mech { shift->{__mech} }

sub get {
  my( $self, $isbn ) = @_;
  $isbn =~ s/[^0-9X]//gi;

  my $search = eval { $self->__scraper->search($isbn) };
  return undef unless $search and $search->found;

  my $book = $search->book;

  $isbn = $book->{isbn};
  $self->__mech->get('http://isbn.org/converterpub.asp');
  $self->__mech->submit_form(
    form_name => 'frmconvert',
    fields => {
      txtisbn10 => ( $isbn && length($isbn) == 10 ? $isbn : '' ),
      txtisbn13 => ( $isbn && length($isbn) == 13 ? $isbn : '' )
    }
  );
  $self->__mech->form_name('frmconvert');
  $isbn = $self->__mech->value('txtisbn10') || $self->__mech->value('txtisbn13') || $isbn;

  return $self->__source_obj( {
    __source_url => $book->{_source_url},
    author => $book->{author},
    title => $book->{title},
    publisher => $book->{publisher},
    location => $book->{location},
    year => $book->{year},
    pages => '',

    # New fields (removed 'id')
    isbn => $isbn,
    oclc => '',
    doi => '',
    
    accessdate => '',
  } );
}

sub template_name { 'cite book' }
sub template_ref_name { 'isbn'.shift->{isbn} }
sub template_basic_fields {
  my $self = shift;

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    author     => { value => $self->{author} },
    authorlink => { value => '', show => 'if-extended' },
    editor     => { value => '', show => 'if-extended' },
    others     => { value => '', show => 'if-extended' },
    title      => { value => $self->{title} },
 			edition    => { value => '', show => 'if-extended' },
 			language   => { value => '', show => 'if-extended' },
    publisher  => { value => $self->{publisher} },
    location   => { value => $self->{location} },
    year       => { value => $self->{year} },
 			origyear   => { value => '', show => 'if-extended' },
 			pages      => { value => '' },
 			quote      => { value => '', show => 'if-extended' },
    isbn       => { value => $self->{isbn} },
    oclc       => { value => '' },
    doi        => { value => '' },
    url        => { value => '', show => 'if-extended' },
    accessdate => { value => '' },
  );

  return \%fields;
}

1;
