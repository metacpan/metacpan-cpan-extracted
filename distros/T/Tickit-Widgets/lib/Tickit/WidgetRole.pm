#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2024 -- leonerd@leonerd.org.uk

package Tickit::WidgetRole 0.54;

use v5.14;
use warnings;

use Carp;

use meta 0.008;
no warnings 'meta::experimental';

BEGIN {
   # Since we have meta, we can use it to fake up a set_subname and avoid
   # pulling in Sub::Util
   *set_subname = sub {
      my ( $name, $sub ) = @_;
      meta::for_reference( $sub )->set_subname( $name );
      return $sub;
   };
}

sub import
{
   my $pkg = caller;
   my $class = shift;

   my $subs = $class->export_subs_for( $pkg, @_ );

   use Object::Pad 0.808 ':experimental(mop)';
   if( my $meta = Object::Pad::MOP::Class->try_for_class( $pkg ) ) {
      $meta->add_method( $_ => set_subname $_ => $subs->{$_} ) for keys %$subs;
   }
   else {
      carp "Using legacy Tickit::WidgetRole exporter for non-class";

      my $metapkg = meta::package->get( $pkg );

      $metapkg->add_named_sub( $_ => $subs->{$_} ) for keys %$subs;
   }
}

0x55AA;
