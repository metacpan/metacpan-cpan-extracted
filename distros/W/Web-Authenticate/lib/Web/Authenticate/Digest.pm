use strict;
package Web::Authenticate::Digest;
$Web::Authenticate::Digest::VERSION = '0.011';
use Mouse;
use Mouse::Util::TypeConstraints;
use Crypt::PBKDF2;
#ABSTRACT: The default implementation of Web::Authenticate::Digest::Role.

with 'Web::Authenticate::Digest::Role';


has crypt => (
    isa => 'Crypt::PBKDF2',
    is => 'ro',
    required => 1,
    default => sub {
        Crypt::PBKDF2->new(
            hash_class => 'HMACSHA2',
            hash_args => {
                sha_size => 512,
            },
            iterations => 10000,
            salt_len => 10,
        );
    },
);


sub generate {
    my ($self, $password) = @_;
    return $self->crypt->generate($password);
}


sub validate {
    my ($self, $hash, $password) = @_;
    return $self->crypt->validate($hash, $password);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Digest - The default implementation of Web::Authenticate::Digest::Role.

=head1 VERSION

version 0.011

=head1 METHODS

=head2 crypt

Sets the L<Crypt::PBKDF2> object that is used to create and validate digests. Below is the default:

    Crypt::PBKDF2->new(
        hash_class => 'HMACSHA2',
        hash_args => {
            sha_size => 512,
        },
        iterations => 10000,
        salt_len => 10,
    )

=head2 generate

Accepts a password and returns the hex digest of that password using L</crypt>.

    my $password_digest = $digest->generate($password);

=head2

Uses L<Crypt::PBKDF2/"validate">.

    my $validate_success = $digest->validate($hash, $password);

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
