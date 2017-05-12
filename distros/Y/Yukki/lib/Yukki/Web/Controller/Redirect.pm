package Yukki::Web::Controller::Redirect;
{
  $Yukki::Web::Controller::Redirect::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

use Yukki::Error qw( http_throw );

# ABSTRACT: Simple controller for handling internal redirects


sub fire {
    my ($self, $ctx) = @_;

    my $redirect = $ctx->request->path_parameters->{redirect};

    http_throw("no redirect URL named") unless $redirect;
 
    http_throw("Go to $redirect.", {
        status   => 'MovedPermanently', 
        location => $redirect,
    });
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Controller::Redirect - Simple controller for handling internal redirects

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

Simple controller for handling internal redirects.

=head1 METHODS

=head2 fire

When fired, performs the requested redirect.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
