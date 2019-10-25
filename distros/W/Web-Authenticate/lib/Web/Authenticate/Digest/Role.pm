use strict;
package Web::Authenticate::Digest::Role;
$Web::Authenticate::Digest::Role::VERSION = '0.013';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Digest object should contain.


requires 'generate';


requires 'validate';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Digest::Role - A Mouse::Role that defines what methods a Web::Authenticate::Digest object should contain.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 generate

All L</Web::Authenticate::Digest> objects should be able to digest text and return a hashed value.

    my $hash = $digest->generate($password);

=head2 validate

Validates the stored hash for the user against the user entered password.

    if ($digest->validate($hash, $password)) {
        # success
    } else {
        # failure
    }

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
