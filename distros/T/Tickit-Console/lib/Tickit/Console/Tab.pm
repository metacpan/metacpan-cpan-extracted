#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2020 -- leonerd@leonerd.org.uk

use v5.26; # signatures
use Object::Pad 0.43;  # ADJUST

use Tickit::Widget::Tabbed 0.024;

package Tickit::Console::Tab 0.10;
class Tickit::Console::Tab
   extends Tickit::Widget::Tabbed::Tab
   :strict(params);

use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::Scroller::Item::RichText;

use String::Tagged 0.10;

use POSIX ();
use Scalar::Util qw( blessed weaken );

=head1 NAME

C<Tickit::Console::Tab> - represent a single tab on a C<Tickit::Console>

=head1 DESCRIPTION

Objects in this class represent a single switchable tab within a
L<Tickit::Console>. They are not constructed directly, but instead are
returned by the C<add_tab> method of the underlying C<Tickit::Console> object.

=cut

=head1 PARAMETERS

The following extra parameters may be passed to the constructor, or via the
C<add_tab> method on the C<Tickit::Console> object:

=over 8

=item timestamp_format => STRING or String::Tagged

If defined, every line is prefixed with a timestamp built by applying the
C<POSIX::strftime> function to this string. If a L<String::Tagged> instance is
applied it will preserve all the formatting from it.

=item datestamp_format => STRING or String::Tagged

If defined, every time a line is added to the buffer, if it starts a new day
since the previous message (because the format yields a different string),
this message is added as well to the scroller.

=item localtime => CODE

If defined, provides an alternative function to C<CORE::localtime> for
converting an epoch value into a timestamp. For example, this may be set to

   sub { gmtime $_[0] }

to generate timestamps in UTC instead of using the local timezone.

=back

=cut

has $_scroller :param;
has $_console  :param;
has $_on_line  :param = undef;

has $_timestamp_format :param;
has $_datestamp_format :param;
has $_localtime        :param = sub ( $time ) { localtime $time };

ADJUST
{
   weaken( $_console );
}

=head1 METHODS

=cut

=head2 name

=head2 set_name

   $name = $tab->name

   $tab->set_name( $name )

Returns or sets the tab name text

=cut

method name ()
{
   return $self->label;
}

method set_name ( $name )
{
   $self->set_label( $name );
}

=head2 append_line

   $tab->append_line( $string, %opts )

Appends a line of text to the tab. C<$string> may either be a plain perl
string, or an instance of L<String::Tagged> containing formatting tags, as
specified by L<Tickit::Widget::Scroller>. Options will be passed to the
L<Tickit::Widget::Scroller::Item::Line> used to contain the string.

Also recognises the following options:

=over 8

=item time => NUM

Overrides the epoch C<time()> value used to generate a timestamp for this line

=item timestamp_format => STRING or String::Tagged

Overrides the stored format for generating a timestamp string.

=item datestamp_format => STRING or String::Tagged

Overrides the stored format for generating a datestamp string.

=back

=cut

sub strftime ( $format, @t )
{
   if( blessed $format and $format->isa( "String::Tagged" ) ) {
      my $fplain = $format->str;
      my $ret = String::Tagged->new;

      # Iterate format specifiers and other literal text
      foreach my $m ( $format->matches( qr/%[_0#^-]?[OE]?.|[^%]+/ ) ) {
         if( $m =~ m/^%/ ) {
            # Format specifier
            $ret->append_tagged( POSIX::strftime( $m, @t ),
               %{ $m->get_tags_at( 0 ) }
            );
         }
         else {
            # Literal
            $ret->append( $m );
         }
      }

      return $ret;
   }
   else {
      return POSIX::strftime( $format, @t );
   }
}

sub _make_item ( $string, %opts )
{
   if( blessed $string and $string->isa( "String::Tagged" ) ) {
      return Tickit::Widget::Scroller::Item::RichText->new( $string, %opts );
   }
   else {
      return Tickit::Widget::Scroller::Item::Text->new( $string, %opts );
   }
}

has $_dusk_datestamp;
has $_dawn_datestamp;

method _make_item_with_timestamp ( $string, %opts )
{
   if( my $timestamp_format = delete $opts{timestamp_format} // $_timestamp_format ) {
      my $time = delete $opts{time} // time();
      my $timestamp = strftime( $timestamp_format, $_localtime->( $time ) );

      $string = $timestamp . $string;
   }

   return _make_item( $string, %opts );
}

method append_line ( $string, %opts )
{
   if( my $datestamp_format = delete $opts{datestamp_format} // $_datestamp_format ) {
      my $time = $opts{time} //= time();
      my $plain = POSIX::strftime( $datestamp_format, my @t = $_localtime->( $time ) );

      if( ( $_dusk_datestamp // "" ) ne $plain ) {
         my $datestamp = strftime( $datestamp_format, @t );
         $_scroller->push( _make_item( $datestamp ) );

         $_dusk_datestamp = $plain;
         $_dawn_datestamp //= $plain;
      }
   }

   $_scroller->push( $self->_make_item_with_timestamp( $string, %opts ) );
}

*add_line = \&append_line;

=head2 prepend_line

   $tab->prepend_line( $string, %opts )

As C<append_line>, but prepends it at the beginning of the scroller.

=cut

method prepend_line ( $string, %opts )
{
   my $datestamp_item;
   if( my $datestamp_format = delete $opts{datestamp_format} // $_datestamp_format ) {
      my $time = $opts{time} //= time();
      my $plain = POSIX::strftime( $datestamp_format, my @t = $_localtime->( $time ) );

      $_scroller->shift if ( $_dawn_datestamp // "" ) eq $plain;

      my $datestamp = strftime( $datestamp_format, @t );
      $datestamp_item = _make_item( $datestamp );

      $_dawn_datestamp = $plain;
      $_dusk_datestamp //= $plain;
   }

   $_scroller->unshift( $self->_make_item_with_timestamp( $string, %opts ) );
   $_scroller->unshift( $datestamp_item ) if $datestamp_item;
}

=head2 bind_key

   $tab->bind_key( $key, $code )

Installs a callback to invoke if the given key is pressed while this tab has
focus, overwriting any previous callback for the same key. The code block is
invoked as

   $result = $code->( $tab, $key )

If C<$code> is missing or C<undef>, any existing callback is removed.

This callback will be invoked before one defined on the console object itself,
if present. If it returns a false value, then the one on the console will be
invoked instead.

=cut

has %_keybindings;

method bind_key ( $key, $code )
{
   if( not $_keybindings{$key} and $code ) {
      $_console->_inc_key_binding( $key );
   }
   elsif( $_keybindings{$key} and not $code ) {
      $_console->_dec_key_binding( $key );
   }

   $_keybindings{$key} = $code;
}

method _on_line ( $line )
{
   $_on_line or return 0;

   $_on_line->( $self, $line );

   return 1;
}

method _on_key ( $key )
{
   return 1 if $_keybindings{$key} and
      $_keybindings{$key}->( $self, $key );
   return 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
