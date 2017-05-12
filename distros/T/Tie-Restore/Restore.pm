#!/usr/local/bin/perl

=head1 NAME

Tie::Restore - restores ties to an existing object

=head1 DESCRIPTION

Provides the opposite of the 'tied' function.  Say you have %hash that
is tied to $object.  Then, it is relatively simple to get $object from
%hash simply by saying

 $object = tied %hash;

But, how does one go the other way?  Simple, with Tie::Restore

 tie %hash, 'Tie::Restore', $object;

Works for any kind of tie. (scalar, array, hash, filehandle)

=head1 HISTORY

=over 2

=item *

05/22/02 - fixed problem with old .tar.gz - version 0.11

=item *

11/03/01 - Robby Walker - added documentation - version 0.1

=back

=cut
#----------------------------------------------------------

package Tie::Restore;

our $VERSION = 0.11;

sub TIESCALAR { $_[1] }
sub TIEARRAY  { $_[1] }
sub TIEHASH   { $_[1] }
sub TIEHANDLE { $_[1] }

1;

__END__

=head1 BUGS

None known.  Hard to imagine anything serious in 6 lines of code...

=head1 AUTHORS AND COPYRIGHT

Written by Robby Walker ( webmaster@pointwriter.com ) for Point Writer ( http://www.pointwriter.com/ ).

You may redistribute/modify/etc. this module under the same terms as Perl itself.

