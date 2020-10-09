#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Tickit::Widget::Entry::Plugin::History 0.01;

use v5.14;
use warnings;

=head1 NAME

C<Tickit::Widget::Entry::Plugin::History> - add readline-like history to a L<Tickit::Widget::Entry>

=head1 SYNOPSIS

   use Tickit::Widget::Entry;
   use Tickit::Widget::Entry::Plugin::History;

   my $entry = Tickit::Widget::Entry->new( ... );
   Tickit::Widget::Entry::Plugin::History->apply( $entry );

   ...

=head1 DESCRIPTION

This package applies code to a L<Tickit::Widget::Entry> instance to implement
a history mechanism, which stores previously-entered values allowing them to
be recalled and reused later.

=cut

=head1 METHODS

=cut

=head2 apply

   Tickit::Widget::Entry::Plugin::History->apply( $entry, %opts )

Applies the plugin code to the given L<Tickit::Widget::Entry> instance.

The following named options are recognised:

=over 4

=item storage => ARRAY

An optional reference to an array to store the history in. If absent, a new
anonymous array will be created.

=item ignore_duplicates => BOOL

If true, an entry will not be pushed into history if it is equal to the most
recent item already there.

=back

=cut

sub apply
{
   my $class = shift;
   my ( $entry, %opts ) = @_;

   my $storage = $opts{storage} // [];
   my $ignore_duplicates = !!$opts{ignore_duplicates};

   my $pending;
   my $history_index;

   $entry->bind_keys(
      Up => sub {
         my ( $entry ) = @_;

         if( !defined $history_index ) {
            $pending = $entry->text;
            return 1 unless @$storage;

            $history_index = $#$storage;
         }
         elsif( $history_index == 0 ) {
            # don't move
            return 1;
         }
         else {
            $history_index--;
         }

         my $line = $storage->[$history_index];
         $entry->set_text( $line );
         $entry->set_position( length $line );

         return 1;
      },

      Down => sub {
         my ( $entry ) = @_;

         return 1 unless defined $history_index;
         if( $history_index < $#$storage ) {
            $history_index++;
         }
         else {
            $entry->set_text( $pending );
            undef $history_index;
            return 1;
         }

         my $line = $storage->[$history_index];
         $entry->set_text( $line );
         $entry->set_position( length $line );

         return 1;
      },
   );

   my $orig_on_enter = $entry->on_enter;
   $entry->set_on_enter( sub {
      my $entry = shift;
      my ( $line ) = @_;

      $entry->$orig_on_enter( $line ) if $orig_on_enter;

      $entry->set_text( "" );

      push @$storage, $line unless $ignore_duplicates and @$storage and $line eq $storage->[-1];
      # TODO: manage history size

      undef $history_index;
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
