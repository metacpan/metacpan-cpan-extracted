[![Build Status](https://travis-ci.org/worthmine/Text-Password-AutoMigration.svg?branch=master)](https://travis-ci.org/worthmine/Text-Password-AutoMigration)
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

And verifies automatically the hash with
**CORE::crypt**, **MD5**, **SHA-1 by hex**, **SHA-256** and of course **SHA-512**.

All you have to do are those:

1\. use this module

2\. replace the hashes in your DB periodically.

## Constructor and initialization

### new()

No arguments are required. But you can set some parameters.

- default

    You can set default length with param 'default' like below:

        $pwd = Text::Pasword::AutoMiglation->new( default => 12 );

    It must be an Int, defaults to 8.

- readablity

    Or you can set default strength for password with param 'readablity'.

    It must be a Boolean, defaults to 1.

    If it was set as 0, you can generate stronger passwords with generate().

        $pwd = Text::Pasword::AutoMiglation->new( readability => 0 );

- migrate

    It must be a Boolean, defaults to 1.

    This module is for Administrators who try to replace hashes in their DB.
    However, if you've already done to replace them or start to make new Apps with this module,
    you can set param migrate as 0. 
    Then it will work a little faster without regenerating new hashes.

## Methods and Subroutines

### verify( $raw, $hash )

returns the true value if the verification succeeds.

Actually, the value is new hash with SHA-512 from $raw.

So you can replace hashes in your DB very easily like below:

    my $pwd = Text::Password::AutoMigration->new();
    my $input = $req->body_parameters->{passwd};
    my $hash = $pwd->verify( $input, $db{passwd} ); # returns hash with SHA-512, and it's true

    if ($hash) { # you don't have to execute this every time
       $succeed = 1;
       my $sth = $dbh->prepare('UPDATE DB SET passwd=? WHERE uid =?') or die $dbh->errstr;
       $sth->excute( $hash, $req->body_parameters->{uid} ) or die $sth->errstr;
    }

New hash length is at least 98. So you have to change your DB like below:

    ALTER TABLE User CHANGE passwd passwd VARCHAR(98);

### nonce($length)

generates the random strings with enough strength.

the length defaults to 8($self->default).

### encrypt($raw)

returns hash with unix\_sha512\_crypt().

salt will be made automatically.

### generate($length)

genarates pair of new password and it's hash.

less readable characters(0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"\`) are forbidden
unless $self->readability is 0.

the length defaults to 8($self->default).

**DON'T TRUST** this method.
According to [Password expert says he was wrong](https://www.usatoday.com/story/news/nation-now/2017/08/09/password-expert-says-he-wrong-numbers-capital-letters-and-symbols-useless/552013001/),
it's not a safe way. So, I will rewrite this method as soon as I find the better way.

# SEE ALSO

- [GitHub](https://github.com/worthmine/Text-Password-AutoMigration)
- [CPAN](http://search.cpan.org/perldoc?Text%3A%3APassword%3A%3AAutoMigration)
- [https://shattered.io/](https://shattered.io/)

# LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuki Yoshida(worthmine) &lt;worthmine!at!gmail.com>
