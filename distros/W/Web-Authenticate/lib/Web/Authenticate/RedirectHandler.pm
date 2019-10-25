use strict;
package Web::Authenticate::RedirectHandler;
$Web::Authenticate::RedirectHandler::VERSION = '0.013';
use Mouse;
use Carp;
#ABSTRACT: The default implementation of Web::Authentication::RedirectHandler::Role.

with 'Web::Authenticate::RedirectHandler::Role';


has exit_on_redirect => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => undef,
);


sub redirect {
    my ($self, $url) = @_;
    croak "must provide url" unless $url;

    print "Location: $url\n\n";
    exit if $self->exit_on_redirect;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::RedirectHandler - The default implementation of Web::Authentication::RedirectHandler::Role.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 exit_on_redirect

If set to true (1), then when a user is redirected in methods such as L</login> or L</authenticate>, exit will be called instead of returning.
Default is false.

=head2 redirect

Redirects to url.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
