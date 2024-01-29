#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2023 -- leonerd@leonerd.org.uk

package Tickit::WidgetRole 0.53;

use v5.14;
use warnings;

use Carp;

BEGIN {
   if( eval { require Sub::Util; Sub::Util->VERSION( '1.40' ) } ) {
      *set_subname = \&Sub::Util::set_subname;
   }
   elsif( eval { require Sub::Name } ) {
      *set_subname = \&Sub::Name::subname;
   }
   else {
      *set_subname = sub { my ( $name, $sub ) = @_; return $sub };
   }
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
      carp "Using legacy Tickit::WidgetRole exporter using no strict 'refs'";

      no strict 'refs';
      *{"${pkg}::$_"} = set_subname $_ => $subs->{$_} for keys %$subs;
   }
}

0x55AA;
