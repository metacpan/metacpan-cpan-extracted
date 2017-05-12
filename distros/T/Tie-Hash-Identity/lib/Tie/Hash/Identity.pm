package Tie::Hash::Identity;

use warnings;
use strict;

=head1 NAME

Tie::Hash::Identity - A hash that always returns the key

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tie::Hash::Identity;

    my %hash;
    tie %hash, 'Tie::Hash::Identity';

    $hash{abc} eq 'abc'; # true
    $hash{1+2+3} eq '6'; # true

=head1 DESCRIPTION

A hash that always returns the key. 

It's useful when interpolating EXPR in a double quoted string.

Maybe you should try Hash::Identity with a better importing interface.

It only support for retrieving data. Never storing data back, nor trying to iterate over it.

=cut

sub TIEHASH {
    bless {}, $_[0]
}

sub FETCH {
    $_[1]
}

=head1 SEE ALSO

L<Hash::Identity> - same thing, with a better importing interface.

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-hash-identity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Hash-Identity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tie::Hash::Identity
