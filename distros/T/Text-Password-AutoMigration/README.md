# NAME

Text::Password::AutoMigration - generate and verify Password with any contexts

# SYNOPSIS

    my $pwd = Text::Password::AutoMigration->new();
    my( $raw, $hash ) = $pwd->genarate();          # list context is required
    my $input = $req->body_parameters->{passwd};
    my $data = $pwd->encrypt($input);              # salt is made automatically
    my $flag = $pwd->verify( $input, $data );

# DESCRIPTION

Text::Password::AutoMigration is the Module for lasy Administrators.

It always generates the password with SHA512.

And verifies Automatically the hash with
**CORE::crypt**, **MD5**, **SHA1 by hex**, **SHA256** and of course **SHA512**.

All You have to do are those:

1\. use this module

2\. replace periodically the hashes in your DB.

## Constructor and initialization

### new()

No arguments are required. But you can set some parameters.

- default

    You can set default length with param 'default' like below

        $pwd = Text::Pasword::AutoMiglation->new( default => 12 );

- readablity

    Or you can set default strength for password with param 'readablity'.

    It must be a Boolen, default is 1.

    If it was set as 0, you can generate stronger passwords with generate()

        $pwd = Text::Pasword::AutoMiglation->new( readability => 0 );
        

## Methods and Subroutines

### verify( $raw, $hash )

returns true if the verify is success

### nonce($length)

generates the strings with enough strength

the length defaults to 8($self->default)

### encrypt($raw)

returns hash with unix\_sha512\_crypt()

salt will be made automatically

### generate($length)

genarates pair of new password and it's hash

not much readable characters(0Oo1Il|!2Zz5sS\\$6b9qCcKkUuVvWwXx.,:;~\\-^'"\`) are fallen
unless $self->readability is 0.

the length defaults to 8($self->default)

# SEE ALSO

- [github](https://github.com/worthmine/Text-Password-AutoMigration)
- [cpan](http://search.cpan.org/perldoc?Text%3A%3APassword%3A%3AAutoMigration)

# LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuki Yoshida(worthmine) &lt;worthmine!at!gmail.com>
