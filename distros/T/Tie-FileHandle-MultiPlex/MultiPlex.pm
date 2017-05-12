#!/usr/local/bin/perl

=head1 NAME

Tie::FileHandle::MultiPlex - filehandle tie that sends output to many destinations

=head1 DESCRIPTION

This module, when tied to a filehandle, will send all of its output to all
of the sources listed upon its creation.

 Usage: tie *HANDLE, 'Tie::FileHandle::MultiPlex', *HANDLE1, *HANDLE2, *HANDLE3,...

=head1 TODO

=over 4

=item *

test.pl

=back

=head1 BUGS

This is a new module and has not been thoroughly tested.

=cut

package Tie::FileHandle::MultiPlex;

use base qw(Tie::FileHandle::Base);
use vars qw($VERSION);
$VERSION = 0.1;

# TIEHANDLE
# Usage: tie *HANDLE, 'Tie::FileHandle::MultiPlex', *HANDLE1, *HANDLE2, *HANDLE3,...
sub TIEHANDLE {
	bless [ map { \$_ } @_[1..$#_] ], $_[0];
}

# PRINT
sub PRINT {
	print $_ $_[1] for @{ $_[0] };
}

1;

=head1 AUTHORS AND COPYRIGHT

Written by Robby Walker ( robwalker@cpan.org ) for Point Writer ( http://www.pointwriter.com/ ).

You may redistribute/modify/etc. this module under the same terms as Perl itself.
