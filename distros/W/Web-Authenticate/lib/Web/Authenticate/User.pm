use strict;
package Web::Authenticate::User;
$Web::Authenticate::User::VERSION = '0.013';
use Mouse;
#ABSTRACT: The default implementation of Web::Authentication::User::Role.


has id => (
    isa => 'Int',
    is => 'ro',
    required => 1,
);

# here so that 'id' sub exists
with 'Web::Authenticate::User::Role';


has row => (
    isa => 'HashRef',
    is => 'ro',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::User - The default implementation of Web::Authentication::User::Role.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 id

Returns the user's id. Read only.

=head2 row

Has the user row as a hashref with columns as keys.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
