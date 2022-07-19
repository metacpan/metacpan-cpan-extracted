package UID2::Client::XS::DecryptionStatus;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    SUCCESS
    NOT_AUTHORIZED_FOR_KEY
    NOT_INITIALIZED
    INVALID_PAYLOAD
    EXPIRED_TOKEN
    KEYS_NOT_SYNCED
    VERSION_NOT_SUPPORTED
    INVALID_PAYLOAD_TYPE
    INVALID_IDENTITY_SCOPE
);

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::XS::DecryptionStatus - Decryption Status Constants for UID2::Client::XS

=head1 SYNOPSIS

  use UID2::Client::XS::DecryptionStatus;

=head1 DESCRIPTION

This module defines constants for L<UID2::Client::XS>.

=head1 CONSTANTS

=over

=item SUCCESS

=item NOT_AUTHORIZED_FOR_KEY

=item NOT_INITIALIZED

=item INVALID_PAYLOAD

=item EXPIRED_TOKEN

=item KEYS_NOT_SYNCED

=item VERSION_NOT_SUPPORTED

=item INVALID_PAYLOAD_TYPE

=item INVALID_IDENTITY_SCOPE

=back

=head1 SEE ALSO

L<UID2::Client::XS>

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
