#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2021 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.57;

package Tickit::Widget::Scroller::Item::RichText 0.30;
class Tickit::Widget::Scroller::Item::RichText
   :strict(params)
   :isa(Tickit::Widget::Scroller::Item::Text);

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
and values. To use a L<String::Tagged::Formatting> instance instead, use the
L</new_from_formatting> constructor.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new_from_formatting

   $item = Tickit::Widget::Scroller::Item::RichText->new_from_formatting( $str, %opts )

Constructs a new item containing the text given by the L<String::Tagged>
instance, converting the tags from the L<String::Tagged::Formatting>
convention into native L<Tickit::Pen> format.

=cut

sub _convert_color_tag ($n, $v)
{
   return $n => $v->as_xterm->index;
}

my %convert_tags = (
   bold      => "b",
   under     => "u",
   italic    => "i",
   strike    => "strike",
   blink     => "blink",
   monospace => sub ($, $v) { "af" => ( $v ? 1 : 0 ) },
   reverse   => "rv",
   fg        => \&_convert_color_tag,
   bg        => \&_convert_color_tag,
);

sub new_from_formatting ( $class, $str, %opts )
{
   return $class->new(
      # TODO: Maybe this should live somewhere more fundamental in Tickit itself?
      $str->clone(
         only_tags    => [ keys %convert_tags ],
         convert_tags => \%convert_tags,
      ),
      %opts
   );
}

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
