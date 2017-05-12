package Web::Authenticate::User::CredentialVerifier::LengthCredentialVerifier;
$Web::Authenticate::User::CredentialVerifier::LengthCredentialVerifier::VERSION = '0.011';
use strict;
use Mouse;

use Mouse::Util::TypeConstraints;
 
subtype 'Natural'
    => as 'Int'
    => where { $_ > 0 };
 
no Mouse::Util::TypeConstraints;


has name => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'Length',
);

with 'Web::Authenticate::User::CredentialVerifier::Role';


has min_length => (
    isa => 'Natural',
    is => 'ro',
    required => 1,
    default => 1,
);


has max_length => (
    isa => 'Natural',
    is => 'ro',
    required => 1,
    default => 100,
);


sub verify {
    my ($self, $value) = @_; 
    my $length = length($value);

    return $length >= $self->min_length && $length <= $self->max_length;
}


sub error_msg { 
    my ($self) = @_;
    return $self->name . ' must be between ' . $self->min_length . ' and ' . $self->max_length;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::User::CredentialVerifier::LengthCredentialVerifier

=head1 VERSION

version 0.011

=head1 METHODS

=head2 name

Sets the name of this L<Web::Authenticate::User::CredentialVerifier::Role>. Default is Length.

=head2 min_length

Sets the minimum length for a value. Default is 1.

=head2 max_length

Sets the maximum length for a value. Default is 100.

=head2 verify

Verifies that value is between L</min_length> and L</max_length>.

    my $success = $verifier->verify($value);

=head2 error_msg

Prints message in the form of:

    $name must be between $min_length and $max_length   

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
