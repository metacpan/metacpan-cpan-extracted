#!/usr/local/bin/perl

=head1 NAME

Tie::FileHandle::Buffer - filehandle tie that captures output

=head1 DESCRIPTION

This module, when tied to a filehandle, will capture and store all that
is output to that handle.  You may then act on that stored information in
one of the following ways.

 my $contents = (tied *HANDLE)->get_contents; # retrieves the stored output

 (tied *HANDLE)->clear; # clears the output buffer

This module goes hand in hand with the Output::Buffer module.

=head1 TODO

=over 4

=item *

test.pl

=back

=head1 BUGS

This is a new module and has not been thoroughly tested.

=cut

package Tie::FileHandle::Buffer;

use vars qw(@ISA $VERSION);
use base qw(Tie::FileHandle::Base);
$VERSION = 0.11;

# TIEHANDLE
# Usage: tie *HANDLE, 'Tie::FileHandle::Buffer'
sub TIEHANDLE {
	my $self = '';
	bless \$self, $_[0];;
}

# Print to the selected handle
sub PRINT {
	${$_[0]} .= $_[1];
}

# Retrieve the contents
sub get_contents {
	${$_[0]};
}

# Discard the contents
sub clear {
	${$_[0]} = '';
}

1;

=head1 AUTHORS AND COPYRIGHT

Written by Robby Walker ( robwalker@cpan.org ) for Point Writer ( http://www.pointwriter.com/ ).

You may redistribute/modify/etc. this module under the same terms as Perl itself.

