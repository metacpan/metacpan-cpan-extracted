package dtRdr::Annotation::IO::YAML;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use YAML::Syck;


use base 'dtRdr::Annotation::IO';

=head1 NAME

dtRdr::Annotation::IO::YAML - read/write annotations from/to yml files

=head1 SYNOPSIS

=cut

=head1 Methods

=head2 init

  $io->init;

=cut

sub init {
  my $self = shift;

  my $uri = $self->uri or croak("must have uri");

  # fixup
  $uri =~ s#/*$#/#;
  $self->{uri} = $uri;

  if(-e $uri) {
    (-d $uri) or croak("'$uri' is not a directory");
  }
  else {
    # XXX too dwim?
    mkdir($uri) or die "cannot create $uri";
  }

  # to slurp-in all of the files now or read them individually later?
  my $store = $self->{_store} = {$self->_read_store('.yml')};
} # end subroutine init definition
########################################################################

=head2 _read_store

  %store = $self->_read_store($ext);

=cut

sub _read_store {
  my $self = shift;
  my ($ext) = @_;

  my $uri = $self->uri or croak("no uri");
  opendir(my $dh, $uri) or die;
  my @files = grep(/\Q$ext\E$/, readdir($dh));

  my %store;
  foreach my $file (@files) {
    my $filename = $uri . $file;
    $file =~ s/\Q$ext\E$// or die;
    my $data = YAML::Syck::LoadFile($filename);
    defined($data) or die "oops";
    $store{$file} = $data;
  }
  return(%store);
} # end subroutine _read_store definition
########################################################################

=head2 items

Return hashrefs for everything.  This gets called by base class methods
if it can't find a smarter way to search.

  @items = $io->items;

=cut

sub items {
  my $self = shift;
  return(values(%{$self->{_store}}));
} # end subroutine items definition
########################################################################

=head2 items_for

Return the hashrefs for a given book.

  @items = $io->items_for($book);

Likely to be replaced by something more general.

=cut

sub items_for {
  my $self = shift;
  my ($obj) = @_;

  # TODO parametric polymorphism
  eval {$obj->isa('dtRdr::Book')} or die "I only do books";

  my $want_id = $obj->id;
  defined($want_id) or croak("object '$obj' must have an id");

  grep({$_->{book} eq $want_id} $self->items);
} # end subroutine items_for definition
########################################################################

=head2 deleted

  @items = $io->deleted;

=cut

sub deleted {
  my $self = shift;

  my %del = $self->_read_store('.yml.deleted');
  return(values(%del));
} # end subroutine deleted definition
########################################################################

=head2 insert

  $io->insert($object, %args);

=cut

sub insert {
  my $self = shift;
  my ($obj) = @_;
  $obj->can('serialize') or croak("$obj won't work");

  # TODO put this stuff elsewhere?
  $obj->set_create_time(time) unless($obj->create_time);
  $obj->set_revision(0) unless(defined($obj->revision));

  # get a plain hashref
  my $data = $obj->serialize;
  0 and warn "got:\n", YAML::Syck::Dump($data), "\n ";

  my $id = $data->{id};
  $self->x_insert($id, $data);
} # end subroutine insert definition
########################################################################

=head2 delete

  $io->delete($object, %args);

=cut

sub delete {
  my $self = shift;
  my ($obj) = @_;

  my $id = $obj->id;
  $self->x_delete($id);
  if(1) { # preserve deleted status
    my $delfile = $self->_filename($id) . '.deleted';
    my $data = $obj->serialize;
    $data->{delete_time} = time;
    YAML::Syck::DumpFile($delfile, $data) or die;
  }
} # end subroutine delete definition
########################################################################

=head2 update

  $io->update($object, %args);

=cut

sub update {
  my $self = shift;
  my ($obj) = @_;
  $obj->can('serialize') or croak("$obj won't work");

  my $id = $obj->id;
  my $filename = $self->_filename($id);
  (-e $filename) or croak("cannot update -- $filename does not exist");

  # TODO put this stuff elsewhere?
  {
    unless($obj->create_time) {
      $obj->set_create_time((stat($filename))[9]);
    }
    $obj->set_mod_time(time);
    my $rev = $obj->revision || 0;
    $obj->set_revision($rev + 1);
  }

  # get a plain hashref
  my $data = $obj->serialize;

  $self->x_update($id, $data);
} # end subroutine update definition
########################################################################

=head1 Sync/Backend Methods

Intended for non-object manipulations of the data-store, but keeping the
internal IO object's state intact.

These should behave roughly like DBI operations with autocommit and
raise_error.


=head2 s_insert

  $io->s_insert($id, $hashref, $book);

=cut

sub s_insert {
  my $self = shift;
  my ($id, $item, $book) = @_;

  $self->x_insert($id, $item);
  $self->_tell_book('add', $item, $book) if($book);
} # end subroutine s_insert definition
########################################################################

=head2 s_update

  $io->s_update($id, $hashref, $book);

=cut

sub s_update {
  my $self = shift;
  my ($id, $item, $book) = @_;

  $self->x_update($id, $item);
  $self->_tell_book('change', $item, $book) if($book);

  return($item);
} # end subroutine s_update definition
########################################################################

=head2 s_delete

  $io->s_delete($id, $book);

=cut

sub s_delete {
  my $self = shift;
  my ($id, $book) = @_;

  my $item = $self->x_delete($id);
  if(1) { # preserve deleted status
    my $delfile = $self->_filename($id) . '.deleted.fin';
    $item->{delete_time} = time;
    YAML::Syck::DumpFile($delfile, $item) or die;
  }

  $self->_tell_book('delete', $item, $book) if($book);

  return($item);
} # end subroutine s_delete definition
########################################################################

=head2 x_read

  my $hashref = $io->x_read($id);

=cut

sub x_read {
  my $self = shift;
  my ($id) = @_;

  my $filename = $self->_filename($id);

  my $data = YAML::Syck::LoadFile($filename);
  defined($data) or die "nothing in $filename";
  return($data);
} # end subroutine x_read definition
########################################################################

=head2 x_insert

  $io->x_insert($id, $hashref);

=cut

sub x_insert {
  my $self = shift;
  my ($id, $data) = @_;

  $self->{_store}{$id} and croak("duped id? -- $id");
  $self->{_store}{$id} = $data;

  my $filename = $self->_filename($id);
  (-e $filename) and croak("duped id? -- $filename exists");
  YAML::Syck::DumpFile($filename, $data) or die;
} # end subroutine x_insert definition
########################################################################

=head2 x_update

  $io->x_update($id, $hashref);

=cut

sub x_update {
  my $self = shift;
  my ($id, $data) = @_;

  $self->{_store}{$id} or croak("cannot update -- nothing for $id");
  $self->{_store}{$id} = $data;

  my $filename = $self->_filename($id);
  (-e $filename) or croak("cannot update -- $filename does not exist");
  YAML::Syck::DumpFile($filename, $data) or die;
} # end subroutine x_update definition
########################################################################

=head2 x_delete

  $object = $io->x_delete($id);

=cut

sub x_delete {
  my $self = shift;
  my ($id) = @_;

  $self->{_store}{$id} or croak("cannot delete -- nothing for $id");
  my $data = delete($self->{_store}{$id});

  my $filename = $self->_filename($id);
  (-e $filename) or croak("no file to delete -- $filename");
  unlink($filename) or die;
  return($data);
} # end subroutine x_delete definition
########################################################################

=head2 x_finish_delete

  $self->x_finish_delete($id);

=cut

sub x_finish_delete {
  my $self = shift;
  my ($id) = @_;

  my $delfile = $self->_filename($id) . '.deleted';
  (-e $delfile) or die "deleted id '$id' file not found";
  my $fin = $delfile . '.fin';
  rename($delfile, $fin);
} # end subroutine x_finish_delete definition
########################################################################

=head1 Small Parts


=head2 _filename

  $self->_filename($id);

=cut

sub _filename {
  my $self = shift;
  my ($id) = @_;
  return($self->uri . $id . '.yml');
} # end subroutine _filename definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and Osoft, All Rights Reserved.

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
