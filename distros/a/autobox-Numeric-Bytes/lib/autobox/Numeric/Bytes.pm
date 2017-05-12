package autobox::Numeric::Bytes;

use strict;
use warnings;
use Carp;

use bigint;
use base qw(autobox);

our $VERSION = '0.02';

sub import {
    shift->SUPER::import(NUMBER => 'autobox::Numeric::Bytes::Impl', @_);
}

package # hide from pause
    autobox::Numeric::Bytes::Impl;

sub bytes {
    return $_[0];
}
*byte = \&bytes;

sub kilobytes {
    return $_[0] * 1024;
}
*kilobyte = \&kilobytes;

sub megabytes {
    return $_[0] * 1024 * 1024;
}
*megabyte = \&megabytes;

sub gigabytes {
    return $_[0] * 1024 * 1024 * 1024;
}
*gigabyte = \&gigabytes;

sub terabytes {
    return $_[0] * 1024 * 1024 * 1024 * 1024;
}
*terabyte = \&terabytes;

sub petabytes {
    return $_[0] * 1024 * 1024 * 1024 * 1024 * 1024;
}
*petabyte = \&petabytes;

sub exabytes {
    return $_[0] * 1024 * 1024 * 1024 * 1024 * 1024 * 1024;
}
*exabyte = \&exabytes;

1;

__END__

=for stopwords ActiveSupport autobox

=head1 NAME

autobox::Numeric::Bytes - ActiveSupport equivalent to Perl numeric variables

=head1 SYNOPSIS

    use autobox::Numeric::Bytes;

    print 2->byte;      # 2
    print 2->kilobyte;  # 2048
    print 3->megabytes; # 3145728
    print 2->exabyte;   # 2305843009213693952

=head1 DESCRIPTION

autobox::Numeric::Bytes is an autobox module to add Byte-related
methods to core integer values by using constant overloading. Inspired
by ActiveSupport (Rails) Core extensions to Numeric values.

=head1 METHODS

=over 4

=item bytes, byte

=item kilobytes, kilobyte

=item megabytes, megabyte

=item gigabytes, gigabyte

=item terabytes, terabyte

=item petabytes, petabyte

=item exabytes, exabyte

=back

=head1 SEE ALSO

L<http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/Numeric/Bytes.html>

L<autobox>, L<bigint>

=head1 AUTHOR

HIROSE Masaaki, C<< <hirose31@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-autobox-numeric-bytes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
