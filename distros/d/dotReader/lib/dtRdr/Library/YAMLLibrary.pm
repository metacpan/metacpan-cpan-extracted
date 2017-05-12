package dtRdr::Library::YAMLLibrary;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);


use warnings;
use strict;
use Carp;

use base 'dtRdr::Library';
use dtRdr::Library (
  register => {
    type => 'YAMLLibrary'
  },
);
sub LIBTYPE {'YAMLLibrary';} # needs to go away when plugins work?
sub CORE_ATTRIBS {qw(name type id);}

use Class::Accessor::Classy;
no  Class::Accessor::Classy;

use YAML::Syck qw(
  LoadFile
  DumpFile
);

use File::Basename qw(
  dirname
);

=head1 NAME

dtRdr::Library::YAMLLibrary - a library in yaml

=head1 SYNOPSIS

=cut

=head1 Initializer

=head2 create

  dtRdr::Library::YAMLLibrary->create($file);

=cut

sub create {
  my $package = shift;
  my $file = shift;
  $file or croak("must have a filename");
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;

  my $id = exists($args{id}) ? $args{id} : '_setme_';

  my %data = (
    library_info => {
      id      => $id,
      type    => $package->LIBTYPE,
      version => $package->VERSION . '', # ensure stringification
    },
    books => [
    ],
  );
  DumpFile($file, \%data);
} # end subroutine create definition
########################################################################
sub _ylibrary_info { $_[0]->{yml}{library_info};}
sub _ybooks        { $_[0]->{yml}{books};}

=head1 Constructor

=head2 new

  my $library = dtRdr::Library::YAMLLibrary->new();

=cut

# XXX who said I needed this?
# sub new {
#   my $package = shift;
#   my $class = ref($package) || $package;
#   my $self = {};
#   bless($self, $class);
#   return($self);
# } # end subroutine new definition
# ########################################################################

=head1 Methods

=head2 load_uri

  $library->load_uri($uri);

=cut

sub load_uri {
  my $self = shift;
  my ($file) = @_;

  (-e $file) or croak("cannot find library file '$file'");
  $self->{location} = $file;
  $self->_load;
  $self->_setup_info;

} # end subroutine load_uri definition
########################################################################

=head2 _dumpload

Ensure that the on-disk and in-memory data are in sync.

  $self->_dumpload;

=cut

sub _dumpload {
  my $self = shift;
  $self->_dump;
  $self->_load;
} # end subroutine _dumpload definition
########################################################################

=head2 _dump

  $self->_dump;

=cut

sub _dump {
  my $self = shift;
  DumpFile($self->location, $self->{yml});
} # end subroutine _dump definition
########################################################################

=head2 _load

  $self->_load;

=cut

sub _load {
  my $self = shift;
  $self->{yml} = LoadFile($self->location);
} # end subroutine _load definition
########################################################################

=head2 _setup_info

  $self->_setup_info;

=cut

sub _setup_info {
  my $self = shift;

  my $L = $self->_ylibrary_info;
  # TODO check $L->{version};
  foreach my $key ($self->CORE_ATTRIBS) {
    $self->{$key} = $L->{$key} if(exists($L->{$key}));
  }

  my $dir = dirname($self->location);
  # TODO allow absolute path?
  my $storage = exists($L->{storage}) ? ('/' . $L->{storage}) : '';
  $self->{directory} = (defined($dir) ? $dir : '.') . $storage;
} # end subroutine _setup_info definition
########################################################################

=head2 set_id

Allows you to set the library id iff the current value is '_setme_'.

  $lib->set_id($id);

=cut

sub set_id {
  my $self = shift;
  my ($id) = @_;

  my $L = $self->_ylibrary_info;
  ($L->{id} eq '_setme_') or
    croak("the library's id is locked: '$L->{id}'");
  $L->{id} = $self->{id} = $id;
  $self->_dumpload;
} # end subroutine set_id definition
########################################################################

=head2 set_name

Change the library name.

  $lib->set_name($name);

=cut

sub set_name {
  my $self = shift;
  my ($name) = @_;

  my $L = $self->_ylibrary_info;
  $L->{name} = $self->{name} = $name;
  $self->_dumpload;
} # end subroutine set_name definition
########################################################################

=head2 set_storage

Set the library's storage location (relative to the library location.)
This ends up as the $lib->directory property.

  $lib->set_storage($storage);

=cut

sub set_storage {
  my $self = shift;
  my ($sdir) = @_;

  my $L = $self->_ylibrary_info;
  my $checkdir = dirname($self->location) . '/' . $sdir;
  (-e $checkdir) or
    croak("cannot set a non-existent path ($checkdir) ",
      "as the storage directory");
  $L->{storage} = $sdir;
  $self->_dumpload;
  $self->_setup_info;
} # end subroutine set_storage definition
########################################################################

=head2 add_book

Returns the unique id of the new entry.

  $id = $library->add_book(
    book_id => $id,
    title   => $title,
    uri     => $uri,
    type    => $type
  );

=cut

sub add_book {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%data) = @_;

  my $B = $self->_ybooks;
  if(defined(my $id = delete($data{id}))) {
    ($id == @$B) or croak("cannot use id '$id'");
  }
  my $v = push(@$B, \%data) - 1;

  $self->_dumpload;
  return($v);
} # end subroutine add_book definition
########################################################################

# XXX these two should go away {{{

=head2 get_info

  my $value = $library->get_info($key);

=cut

sub get_info {
  my $self = shift;
  my ($key) = @_;

  my $L = $self->_ylibrary_info;
  return($L->{$key});
} # end subroutine get_info definition
########################################################################

=head2 set_info

  $library->set_info($key, $value);

=cut

sub set_info {
  my $self = shift;
  my ($key, $value) = @_;

  my $L = $self->_ylibrary_info;
  $L->{$key} = $value;

  $self->_dumpload;
} # end subroutine set_info definition
########################################################################
# XXX these two should go away }}}

=head2 find_book_by

  $info = $lib->find_book_by($key, $value);

=cut

sub find_book_by {
  my $self = shift;
  my ($key, $value) = @_;

  my $B = $self->book_data;
  my @books = grep({$_->{$key} eq $value} @$B);
  return(@books);
} # end subroutine find_book_by definition
########################################################################


=head2 book_data

  $self->book_data;

=cut

sub book_data {
  my $self = shift;

  my $B = $self->_ybooks;
  # TODO make those persistent objects
  return([map({
    dtRdr::LibraryData::BookInfo->new(%{$B->[$_]},
      intid => $_, library => $self
    )
  } 0..$#$B)]);
} # end subroutine book_data definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

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

# vi:ts=2:sw=2:et:sta
1;
