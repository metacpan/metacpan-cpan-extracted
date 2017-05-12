package Yukki::Web::Request;
{
  $Yukki::Web::Request::VERSION = '0.140290';
}
use Moose;

use Plack::Request;

# ABSTRACT: Yukki request descriptor


has env => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);


has request => (
    is          => 'ro',
    isa         => 'Plack::Request',
    required    => 1,
    lazy_build  => 1,
    handles     => [ qw(
        address remote_host method protocol request_uri path_info path script_name scheme
        secure body input session session_options logger cookies query_parameters
        body_parameters parameters content raw_body uri base user headers uploads
        content_encoding content_length content_type header referer user_agent param
        upload 
    ) ],
);

sub _build_request {
    my $self = shift;
    return Plack::Request->new($self->env);
}


has path_parameters => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
);

1;

__END__

=pod

=head1 NAME

Yukki::Web::Request - Yukki request descriptor

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

This is an abstraction that looks astonishingly similar to L<Plack::Request>.

=head1 ATTRIBUTES

=head2 env

This is the PSGI environment. Do not use.

=head2 request

This is the internal L<Plack::Request> object. Do not use. Use one of the methods delegated to it instead:

  address remote_host method protocol request_uri path_info path script_name scheme
  secure body input session session_options logger cookies query_parameters
  body_parameters parameters content raw_body uri base user headers uploads
  content_encoding content_length content_type header referer user_agent param
  upload 

=head2 path_parameters

These are the variables found in the path during dispatch.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
