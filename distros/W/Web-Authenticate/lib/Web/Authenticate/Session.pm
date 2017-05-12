use strict;
package Web::Authenticate::Session;
$Web::Authenticate::Session::VERSION = '0.011';
use Mouse;
use Session::Token;
#ABSTRACT: The default implementation of Web::Authenticate::Session::Role.


has id => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);


has expires => (
    is => 'ro',
    required => 1,
);


has user => (
    does => 'Web::Authenticate::User::Role',
    is => 'ro',
    required => 1,
);

# here so that above methods exist
with 'Web::Authenticate::Session::Role';


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

Web::Authenticate::Session - The default implementation of Web::Authenticate::Session::Role.

=head1 VERSION

version 0.011

=head1 METHODS

=head2 id

Returns the session id.

=head2 expires

Returns the expiration time of this session.

=head2 user

Returns the user for this session

=head2 row

Has the user row as a hashref with columns as keys.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
