package dtRdr::BookBag;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

=head1 NAME

dtRdr::BookBag - a bag of books

=head1 SYNOPSIS

  my $bag = dtRdr::BookBag->new(books => [
    $book1, $book2, $book3
  ]);

  $bag->add($book4);

  my $book = $bag->find($bookid);
  my $gone = $bag->delete($bookid);

=cut


=head2 new

  my $bag = dtRdr::BookBag->new(books => [@book_objs]);

=cut

sub new {
  my $package = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;
  my $books = $args{books} || [];
  my $self = {books => {}};
  foreach my $book (@$books) {
    $self->{books}{$book->id} = $book;
  }
  bless($self, $package);
  return($self);
} # end subroutine new definition
########################################################################

=head2 add

  $bag->add($book);

=cut

sub add {
  my $self = shift;
  my ($book) = @_;

  my $id = $book->id;
  exists($self->{books}{$id}) and croak("id '$id' already exists");
  $self->{books}{$id} = $book;
  return($id);
} # end subroutine add definition
########################################################################

=head2 find

Returns a book if it is in the bag, otherwise nothing.

  my $book = $bag->find($bookid);

=cut

sub find {
  my $self = shift;
  my ($id) = @_;

  exists($self->{books}{$id}) or return;

  return($self->{books}{$id});
} # end subroutine find definition
########################################################################

=head2 delete

  my $gone = $bag->delete($bookid);

=cut

sub delete {
  my $self = shift;
  my ($id) = @_;

  exists($self->{books}{$id}) or croak("id '$id' not found");

  return(delete($self->{books}{$id}));
} # end subroutine delete definition
########################################################################

=head2 list

  my @ids = $bag->list;

=cut

sub list {
  my $self = shift;

  return(keys(%{$self->{books}}));
} # end subroutine list definition
########################################################################

=head2 items

  my @books = $bag->items;

=cut

sub items {
  my $self = shift;
  return(values(%{$self->{books}}));
} # end subroutine items definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
