package WebService::ValidSign::API;

our $VERSION = '0.002';
use Moo::Role;
use namespace::autoclean;
with 'WebService::ValidSign::API::Constructor';

# ABSTRACT: A REST API client for ValidSign

use Carp qw(croak);
use HTTP::Request;
use JSON qw(decode_json);
use URI;
use WebService::ValidSign::Types qw(
    WebServiceValidSignURI
    WebServiceValidSignAuthModule
);

requires qw(action_endpoint);

has auth => (
    is       => 'ro',
    required => 1,
    isa      => WebServiceValidSignAuthModule,
);

sub get_endpoint {
    my ($self, @misc) = @_;
    my $uri = $self->endpoint->clone;
    my @path = $uri->path_segments;
    @path = grep { defined $_ } @path, @misc;
    $uri->path_segments(@path);
    return $uri;
}

sub call_api {
    my ($self, $req, %options) = @_;

    if ($options{with_token} && $self->can('auth')) {
        $req->header("Authentication", $self->auth->token);
    }

    $req->header("Authorization", join(" ", "Basic", $self->secret));

    my $res = $self->lwp->request($req);

    return decode_json($res->decoded_content) if $res->is_success;

    my $msg = join("$/", "", $req->as_string, $res->as_string);
    my $apikey = $self->secret;
    $msg =~ s/$apikey/APIKEYHIDDEN/g;
    croak("ValidSign error: $msg");
}

sub _build_lwp {
    require LWP::UserAgent;
    return LWP::UserAgent->new(
        agent                 => join('/', __PACKAGE__, "$VERSION"),
        protocols_allowed     => [qw(https)],
        ssl_opts              => { verify_hostname => 1 },
        requests_redirectable => [qw(HEAD GET)],
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::API - A REST API client for ValidSign

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebService::ValidSign;

    my $client = WebService::ValidSign->new(
        endpoint => 'https://hostname.validsign.nl/api'
    );

    $client->

=head1 ATTRIBUTES

=over

=item endpoint

The API URI endpoint as described in the Acceplication Integrator's Guide

=item lwp

An LWP::UserAgent object. If you extend this module you can use your own
builder or just inject something that respects the LWP::UserAgent API.

=back

=head1 METHODS

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
