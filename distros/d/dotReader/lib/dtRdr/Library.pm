package dtRdr::Library;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

# somebody said "use Universal", so bah
sub import {}

=head1 NAME

dtRdr::Library - library class frontend/base

=head1 SYNOPSIS

This module is still in need of some major hacking to get the plugin
loader worked out.  Metadata and other API aspects are also undecided.

=cut

use dtRdr::Library::YAMLLibrary; # XXX need plugin loader here

# NOTE I think all of these should be read-only, since the underlying
# implementation typically needs to save the attributes if they change.
# TODO use setter sub {shift->_saveval(@_);} # or so
use Class::Accessor::Classy;
ro 'id';
ro 'name';
ro 'type';
ro 'location';
rw 'book_data'; # XXX should be ro?
ro 'directory';
no  Class::Accessor::Classy;
{
  package dtRdr::LibraryData::BookInfo;
  use Class::Accessor::Classy;
  with 'new';
  ro 'intid';
  ro 'book_id';
  ro 'title';
  ro 'uri';
  ro 'type';
  ro 'library';
  no  Class::Accessor::Classy;
  # TODO id re-arranging metheds swap_id, move_before -- callbacks to library
}
# and maybe...
# {
#   package dtRdr::LibraryData::LibraryInfo;
#   use Class::Accessor::Classy;
#   with 'new';
#   ro 'id';
#   ro 'name';
#   no  Class::Accessor::Classy;
# }

=head1 Name

dtRdr::Library.pm - Library interface

=cut

# The default structure of a library object is a hash. The following
# are the standard elements:
#
# books = array ref of book objects
# metadata = array ref of metadata objects
# library_info = Book info hashes
#
# Subclass methods:
#
# _load_books - should load in the basic book info from whatever
#               backing store that they're in. Does not create book
#               objects, but does load in the info the library needs
#               to load in the book objects
	# NOTE let's call these "book handles" --Eric
#
# _load_metadata - Load in all the metadata objects from the library
#
# _load_book_objects - Load in all the book objects for the books in
#                      the library

use dtRdr::Traits::Class qw(
  NOT_IMPLEMENTED
  );

=head1 Class Methods

=head2 class_by_type

  dtRdr::Library->class_by_type($type);

=cut

sub class_by_type {
  my $self = shift;
  my ($type) = @_;

  # XXX any color of black...
  return('dtRdr::Library::' . $type);
} # end subroutine class_by_type definition
########################################################################


=head1 Constructor

=head2 new

Create a new empty library object.

  my $library = dtRdr::Library->new();

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {
    metadata => [],
    # books    => [], # XXX need to be able to do this here
    library_info => {},
	  };
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 load_uri

Load the library stored at C<URI> and set the location property.

=cut

sub load_uri { my $self = shift; $self->NOT_IMPLEMENTED(@_); }

=head2 get_books

Return a list of book objects for the books stored in a library object

=cut

sub get_books {
  my $self = shift;
  if (!defined $self->{books}) {
    $self->_load_book_objects;
  }
  return @{$self->{books}};
} # end subroutine get_books definition
########################################################################

=head2 get_metadata

Return a list of all the metadata objects stored in this library

=cut

sub get_metadata {
  my $self = shift;
  if(defined $self->{metadata}) {
    return @{$self->{metadata}};
  }
  else { # this wasn't even returning a value!
    do('./util/BREAK_THIS') or die;
    $self->_fetch_all_metadata();
  }
}

=head2 get_book_info

Return a list of book info objects.

  my @infos = $lib->get_book_info;

=cut

sub get_book_info {
  my $self = shift;
  return @{$self->book_data};
}

=head2 open_book

Return a book object matching a given key/value lookup pair.

  $lib->open_book(intid => $id);

or

  $lib->open_book(title => $title);

or

  $lib->open_book(book_id => $book_id);

=cut

sub open_book {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;
  my @valid = qw(intid title book_id);
  my ($key) = grep({exists($args{$_})} @valid);
  $key or croak('no valid key (',
    join(', ', @valid), ') in arguments: (', join(',', keys(%args)), ')');

  my @books = $self->find_book_by($key, $args{$key});
  @books or die "no books matching $key eq $args{$key}";
  (@books == 1) or die "too many books @books";
  my $B = $books[0];
  # this will get us by until config is operable
  # (and shouldn't break after it works either)
  require dtRdr::Plugins::Book;
  dtRdr::Plugins::Book->init();

  # requires that config sets type -> class prefs
  my $book_class = dtRdr::Plugins::Book->class_for_type($B->type);
  $book_class or die "cannot get a plugin for $B->{type}";
  0 and warn "book class: $book_class";
  my $book_object = $book_class->new();

  # TODO add abstraction somewhere in here
  #      (e.g. it might be http://, absolute, etc)
  my $uri = $self->directory . '/' . $B->uri;
  # NOTE:  Do not be tempted to (-e $uri) here, let the book die.
  0 and warn "book is $uri";
  $book_object->load_uri($uri);

  # XXX does it need the library?
  # $book_object->set('library', $self);

  return($book_object);
} # end subroutine open_book definition
########################################################################

=head2 find_book_by

Virtual:  find a book for a given $key/$value match.

  $info = $lib->find_book_by($key, $value);

=cut

sub find_book_by { my $self = shift; $self->NOT_IMPLEMENTED(@_); }

=head2 add_metadata

Add the C<metadata> object to the C<book>, stored in the library

=cut

sub add_metadata { my $self = shift; $self->NOT_IMPLEMENTED(@_); }

=head2 delete_metadata

Remove the C<metadata> from the specified C<book>, as it's stored in
the library.

  $lib->delete_metadata($book, $metadata);

=cut

sub delete_metadata { my $self = shift; $self->NOT_IMPLEMENTED(@_); }

=head2 add_book

=cut

sub add_book { my $self = shift; $self->NOT_IMPLEMENTED(@_); }

=head2 remove_book

Remove the book.

All metadata for the book will be deleted from the library.

=cut

sub remove_book { my $self = shift; $self->NOT_IMPLEMENTED(@_); }

=head1 AUTHOR

Dan Sugalski, <dan@sidhe.org>

Eric Wilhelm <ewilhelm at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2006-2007 by Dan Sugalski, Eric L. Wilhelm, and OSoft, All
Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

1;
# vim:ts=2:sw=2:et:sta
