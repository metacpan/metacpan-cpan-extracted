#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2022 -- leonerd@leonerd.org.uk

package Tickit::WidgetRole 0.52;

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

   no strict 'refs';
   *{"${pkg}::$_"} = set_subname $_ => $subs->{$_} for keys %$subs;
}

0x55AA;
