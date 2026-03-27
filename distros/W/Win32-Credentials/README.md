# NAME

Win32::Credentials - Read/Write Windows Credential Manager via Win32 API

## SYNOPSIS

    use Win32::Credentials qw(cred_write cred_read cred_delete);

    # Store a secret
    cred_write('My_App/My_password', 'myapp', 'secret123');

    # Retrieve a secret
    my $secret = cred_read('My_App/My_password');

    # Retrieve secret and username
    my ($secret, $user) = cred_read('My_App/My_password');

    # Delete
    cred_delete('My_App/My_password');

## DESCRIPTION

Provides a simple Perl interface to the Windows Credential Manager
(CredWriteW, CredReadW, CredDeleteW) via Win32::API.
Secrets are protected by DPAPI (AES-256) tied to the current
Windows user account.

No XS compilation required — uses Win32::API.

## FUNCTIONS

### cred_write($target, $username, $secret)

Stores a secret in the Windows Credential Manager.
Maximum secret size: 512 bytes (CRED_TYPE_GENERIC limit).

### cred_read($target)

Retrieves a secret. In list context returns ($secret, $username).

### cred_delete($target)

Removes a credential from the vault.

## NOTES

* Requires 64-bit Windows and 64-bit Perl

* Uses CRED_TYPE_GENERIC and CRED_PERSIST_LOCAL_MACHINE

* Secret is stored as UTF-16LE (native Windows format)

## AUTHOR

Massimiliano Citterio mcitterio@cmcps.it

## LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


