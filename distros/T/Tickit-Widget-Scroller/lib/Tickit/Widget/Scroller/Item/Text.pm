#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2020 -- leonerd@leonerd.org.uk

use Object::Pad 0.27;

package Tickit::Widget::Scroller::Item::Text 0.25;
class Tickit::Widget::Scroller::Item::Text;

use Tickit::Utils qw( textwidth cols2chars );

=head1 NAME

C<Tickit::Widget::Scroller::Item::Text> - add static text to a Scroller

=head1 SYNOPSIS

   use Tickit::Widget::Scroller;
   use Tickit::Widget::Scroller::Item::Text;

   my $scroller = Tickit::Widget::Scroller->new;

   $scroller->push(
      Tickit::Widget::Scroller::Item::Text->new( "Hello world" )
   );

=head1 DESCRIPTION

This implementation of L<Tickit::Widget::Scroller::Item> displays a simple
static piece of text. It will be wrapped on whitespace (characters matching
the C</\s/> regexp pattern).

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $item = Tickit::Widget::Scroller::Item::Text->new( $text, %opts )

Constructs a new text item, containing the given string of text. Once
constructed, the item is immutable.

The following options are recognised in C<%opts>:

=over 4

=item indent => INT

If the text item needs to wrap, indent the second and subsequent lines by this
amount. Does not apply to the first line.

=back

=cut

has $_indent;
has @_chunks;

has $_width; # width for which the @_lineruns are valid
has @_lineruns;

BUILD ( $text, %opts )
{
   $_indent = $opts{indent} if defined $opts{indent};

   @_chunks = $self->_build_chunks_for( $text );
}

=head1 METHODS

=cut

=head2 chunks

   @chunks = $item->chunks

Returns the chunks of text displayed by this item. Each chunk is represented
by an ARRAY reference of three fields, giving the text string, its width in
columns, and various options

   [ $text, $width, %opts ]

Recognised options are:

=over 8

=item pen => Tickit::Pen

Pen to render the chunk with.

=item linebreak => BOOL

If true, force a linebreak after this chunk; the next one starts on the
following line.

=back

=cut

method _build_chunks_for ( $text )
{
   my @lines = split m/\n/, $text, -1;
   my $lastline = pop @lines;
   return ( map { [ $_, textwidth( $_ ), linebreak => 1 ] } @lines ),
            [ $lastline, textwidth( $lastline ) ];
}

method chunks { @_chunks }

method height_for_width ( $width )
{
   $_width = $width;

   my @chunks = $self->chunks;
   undef @_lineruns;
   push @_lineruns, my $thisline = [];

   my $line_remaining = $width;

   while( @chunks ) {
      my $chunk = shift @chunks;
      my ( $text, $textwidth, %opts ) = @$chunk;

      if( $textwidth <= $line_remaining ) {
         push @$thisline, [ $text, $textwidth, $opts{pen} ];
         $line_remaining -= $textwidth;
      }
      else {
         # Split this chunk at most $line_remaining chars
         my $eol_ch = cols2chars $text, $line_remaining;

         if( $eol_ch < length $text && substr( $text, $eol_ch, 1 ) =~ m/\S/ ) {
            # TODO: This surely must be possible without substr()ing a temporary
            if( substr( $text, 0, $eol_ch ) =~ m/\S+$/ and
                ( $-[0] > 0 or @$thisline ) ) {
               $eol_ch = $-[0];
            }
         }

         my $partial_text = substr( $text, 0, $eol_ch );
         my $partial_chunk = [ $partial_text, textwidth( $partial_text ), $opts{pen} ];
         push @$thisline, $partial_chunk;

         my $bol_ch = pos $text = $eol_ch;
         $text =~ m/\G\s+/g and $bol_ch = $+[0];

         my $remaining_text = substr( $text, $bol_ch );
         my $remaining_chunk = [ $remaining_text, textwidth( $remaining_text ), %opts ];
         unshift @chunks, $remaining_chunk;

         $line_remaining = 0;
      }

      if( ( $line_remaining == 0 or $opts{linebreak} ) and @chunks ) {
         push @_lineruns, $thisline = [];
         $line_remaining = $width - ( $_indent || 0 );
      }
   }

   return scalar @_lineruns;
}

method render ( $rb, %args )
{
   my $cols = $args{width};

   # Rechunk if width changed
   $self->height_for_width( $cols ) if $cols != $_width;

   foreach my $lineidx ( $args{firstline} .. $args{lastline} ) {
      my $indent = ( $lineidx && $_indent ) ? $_indent : 0;

      $rb->goto( $lineidx, 0 );
      $rb->erase( $indent ) if $indent;

      foreach my $chunk ( @{ $_lineruns[$lineidx] } ) {
         my ( $text, $width, $chunkpen ) = @$chunk;
         $rb->text( $text, $chunkpen );
      }

      $rb->erase_to( $cols );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
