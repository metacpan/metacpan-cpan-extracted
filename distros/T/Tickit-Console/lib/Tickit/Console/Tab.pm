#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Tickit::Console::Tab;

use strict;
use warnings;
use 5.010; # //
use base qw( Tickit::Widget::Tabbed::Tab );

our $VERSION = '0.07';

use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::Scroller::Item::RichText;

use String::Tagged 0.10;

use POSIX ();
use Scalar::Util qw( blessed );

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

=back

=cut

sub new
{
   my $class = shift;
   my ( $tabbed, %args ) = @_;

   my $self = $class->SUPER::new( @_ );

   $self->{timestamp_format} = $args{timestamp_format};
   $self->{datestamp_format} = $args{datestamp_format};

   return $self;
}

=head1 METHODS

=cut

=head2 $name = $tab->name

=head2 $tab->set_name( $name )

Returns or sets the tab name text

=cut

sub name
{
   my $self = shift;
   return $self->label;
}

sub set_name
{
   my $self = shift;
   my ( $name ) = @_;
   $self->set_label( $name );
}

=head2 $tab->append_line( $string, %opts )

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

sub strftime
{
   my ( $format, @t ) = @_;

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

sub _make_item
{
   my ( $string, %opts ) = @_;

   if( blessed $string and $string->isa( "String::Tagged" ) ) {
      return Tickit::Widget::Scroller::Item::RichText->new( $string, %opts );
   }
   else {
      return Tickit::Widget::Scroller::Item::Text->new( $string, %opts );
   }
}

sub _make_item_with_timestamp
{
   my $self = shift;
   my ( $string, %opts ) = @_;

   if( my $timestamp_format = delete $opts{timestamp_format} // $self->{timestamp_format} ) {
      my $time = delete $opts{time} // time();
      my $timestamp = strftime( $timestamp_format, localtime $time );

      $string = $timestamp . $string;
   }

   return _make_item( $string, %opts );
}

sub append_line
{
   my $self = shift;
   my ( $string, %opts ) = @_;

   my $scroller = $self->{scroller};

   if( my $datestamp_format = delete $opts{datestamp_format} // $self->{datestamp_format} ) {
      my $time = $opts{time} //= time();
      my $plain = POSIX::strftime( $datestamp_format, my @t = localtime $time );

      if( ( $self->{dusk_datestamp} // "" ) ne $plain ) {
         my $datestamp = strftime( $datestamp_format, @t );
         $scroller->push( _make_item( $datestamp ) );

         $self->{dusk_datestamp} = $plain;
         $self->{dawn_datestamp} //= $plain;
      }
   }

   $scroller->push( $self->_make_item_with_timestamp( $string, %opts ) );
}

*add_line = \&append_line;

=head2 $tab->prepend_line( $string, %opts )

As C<append_line>, but prepends it at the beginning of the scroller.

=cut

sub prepend_line
{
   my $self = shift;
   my ( $string, %opts ) = @_;

   my $scroller = $self->{scroller};

   my $datestamp_item;
   if( my $datestamp_format = delete $opts{datestamp_format} // $self->{datestamp_format} ) {
      my $time = $opts{time} //= time();
      my $plain = POSIX::strftime( $datestamp_format, my @t = localtime $time );

      $scroller->shift if ( $self->{dawn_datestamp} // "" ) eq $plain;

      my $datestamp = strftime( $datestamp_format, @t );
      $datestamp_item = _make_item( $datestamp );

      $self->{dawn_datestamp} = $plain;
      $self->{dusk_datestamp} //= $plain;
   }

   $scroller->unshift( $self->_make_item_with_timestamp( $string, %opts ) );
   $scroller->unshift( $datestamp_item ) if $datestamp_item;
}

=head2 $tab->bind_key( $key, $code )

Installs a callback to invoke if the given key is pressed while this tab has
focus, overwriting any previous callback for the same key. The code block is
invoked as

 $result = $code->( $tab, $key )

If C<$code> is missing or C<undef>, any existing callback is removed.

This callback will be invoked before one defined on the console object itself,
if present. If it returns a false value, then the one on the console will be
invoked instead.

=cut

sub bind_key
{
   my $self = shift;
   my ( $key, $code ) = @_;

   my $console = $self->{console};

   if( not $self->{keybindings}{$key} and $code ) {
      $console->{keybindings}{$key}[1]++;
      $console->_update_key_binding( $key );
   }
   elsif( $self->{keybindings}{$key} and not $code ) {
      $console->{keybindings}{$key}[1]--;
      $console->_update_key_binding( $key );
   }

   $self->{keybindings}{$key} = $code;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
