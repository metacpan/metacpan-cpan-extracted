use strict;
use warnings;

package Tiny::OpenSSL;

# ABSTRACT: Portable wrapper for OpenSSL Command
our $VERSION = '0.1.3'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL - Portable wrapper for OpenSSL Command

=head1 VERSION

version 0.1.3

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CHANGES

=head2 Version 0.1.2 (2014-10-06)

=over 4

=item *

Set RSA block cipher to AES256

=item *

Don't encrypt private key unless a password is defined.

=item *

Load key if key file already exists when create is called.

=back

=head2 Version 0.1.1 (2014-09-28)

=over 4

=item *

Add missing Carp in Tiny::OpenSSL::CertificateSigningRequest [GH-1]

=back

=head2 Version 0.1.0 (2014-09-27)

=over 4

=item *

Initial Release

=back

=cut
