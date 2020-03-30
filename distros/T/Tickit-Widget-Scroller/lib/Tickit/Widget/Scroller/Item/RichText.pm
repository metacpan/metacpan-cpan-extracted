#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2020 -- leonerd@leonerd.org.uk

use Object::Pad 0.17;
class Tickit::Widget::Scroller::Item::RichText 0.24
   extends Tickit::Widget::Scroller::Item::Text;

use Tickit::Utils qw( textwidth );

=head1 NAME

C<Tickit::Widget::Scroller::Item::RichText> - static text with render
attributes

=head1 SYNOPSIS

   use Tickit::Widget::Scroller;
   use Tickit::Widget::Scroller::Item::RichText;
   use String::Tagged;

   my $str = String::Tagged->new( "An important message" );
   $str->apply_tag( 3, 9, b => 1 );

   my $scroller = Tickit::Widget::Scroller->new;

   $scroller->push(
      Tickit::Widget::Scroller::Item::RichText->new( $str )
   );

=head1 DESCRIPTION

This subclass of L<Tickit::Widget::Scroller::Item::Text> draws static text
with rendering attributes, used to apply formatting. The attributes are stored
by supplying the text in an instance of a L<String::Tagged> object.

The recognised attributes are those of L<Tickit::Pen>, taking the same names
and values.

=cut

method _build_chunks_for ( $str )
{
   my @chunks;

   $str->iter_substr_nooverlap(
      sub {
         my ( $substr, %tags ) = @_;
         my $pen = Tickit::Pen->new_from_attrs( \%tags );
         # Don't worry if extra tags left over, they just aren't rendering attributes
         my @lines = split m/\n/, $substr, -1 or return;
         my $lastline = pop @lines;
         push @chunks, [ $_, textwidth( $_ ), pen => $pen, linebreak => 1 ] for @lines;
         push @chunks, [ $lastline, textwidth( $lastline ), pen => $pen ];
      },
   );

   return @chunks;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
