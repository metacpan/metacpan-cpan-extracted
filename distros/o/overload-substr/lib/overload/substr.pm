#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2012 -- leonerd@leonerd.org.uk

package overload::substr;

use strict;
use warnings;

use Carp;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION );

=head1 NAME

C<overload::substr> - overload Perl's C<substr()> function

=head1 SYNOPSIS

 package My::Stringlike::Object;

 use overload::substr;

 sub _substr
 {
    my $self = shift;
    if( @_ > 2 ) {
       $self->replace_substr( @_ );
    }
    else {
       return $self->get_substr( @_ );
    }
 }

 ...

=head1 DESCRIPTION

This module allows an object class to overload the C<substr> core function,
which Perl's C<overload> pragma does not allow by itself.

It is invoked similarly to the C<overload> pragma, being passed a single named
argument which should be a code reference or method name to implement the
C<substr> function.

 use overload::substr substr => \&SUBSTR;

 use overload::substr substr => "SUBSTR";

The referred method will be invoked as per core's C<substr>; namely, it will
take the string to be operated on (which will be an object in this case), an
offset, optionally a length, and optionally a replacement.

 $str->SUBSTR( $offset );
 $str->SUBSTR( $offset, $length );
 $str->SUBSTR( $offset, $length, $replacement );

In each case, whatever it returns will be the return value of the C<substr>
function that invoked it.

If the C<substr> argument is not provided, it defaults to a method called
C<_substr>.

It is not required that the return value be a plain string; any Perl value may
be returned unmodified from the C<substr> method, or passed in as the value of
the replacement. This allows objects to behave in whatever way is deemed most
appropriate.

=cut

sub import
{
   my $class = shift;
   my %args = @_;

   my $package = caller;

   my $substr = delete $args{substr};
   defined $substr or $substr = "_substr";

   keys %args and
      croak "Unrecognised extra keys to $class: " . join( ", ", sort keys %args );

   no strict 'refs';

   unless( ref $substr ) {
      $substr = \&{$package."::$substr"};
   }

   # This somewhat steps on overload.pm 's toes
   *{$package."::(substr"} = $substr;
}

=head1 TODO

=over 8

=item *

More testing - edge cases, especially in LVALUE logic.

=item *

Test for memory leaks, especially in LVALUE logic.

=item *

Look into / implement fixup of substr() ops compiled before module is loaded

=item *

Consider if implementations of split(), and C<m//> and C<s///> regexps should
be done that also uses the overloaded substr() method.

=back

=head1 ACKNOWLEDGEMENTS

With thanks to Matt S Trout <mst@shadowcat.co.uk> for suggesting the
possibility, and Joshua ben Jore <jjore@cpan.org> for the inspiration by way
of L<UNIVERSAL::ref>.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
