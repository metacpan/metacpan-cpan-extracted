#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Tickit::WidgetRole 0.51;

use v5.14;
use warnings;

use Carp;

BEGIN {
   if( eval { require Sub::Name } ) {
      *subname = \&Sub::Name::subname;
   }
   else {
      *subname = sub { return $_[1] };
   }
}

sub import
{
   my $pkg = caller;
   my $class = shift;

   my $subs = $class->export_subs_for( $pkg, @_ );

   no strict 'refs';
   *{"${pkg}::$_"} = subname $_ => $subs->{$_} for keys %$subs;
}

0x55AA;
