package UID2::Client::XS::EncryptionStatus;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    SUCCESS
    NOT_AUTHORIZED_FOR_KEY
    NOT_INITIALIZED
    KEYS_NOT_SYNCED
    TOKEN_DECRYPT_FAILURE
    KEY_INACTIVE
    ENCRYPTION_FAILURE
);

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::XS::EncryptionStatus - Encryption Status Constants for UID2::Client::XS

=head1 SYNOPSIS

  use UID2::Client::XS::EncryptionStatus;

=head1 DESCRIPTION

This module defines constants for L<UID2::Client::XS>.

=head1 CONSTANTS

=over

=item SUCCESS

=item NOT_AUTHORIZED_FOR_KEY

=item NOT_INITIALIZED

=item KEYS_NOT_SYNCED

=item TOKEN_DECRYPT_FAILURE

=item KEY_INACTIVE

=item ENCRYPTION_FAILURE

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
