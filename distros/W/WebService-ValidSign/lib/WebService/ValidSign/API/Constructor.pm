package WebService::ValidSign::API::Constructor;

our $VERSION = '0.004';
use Moo::Role;
use namespace::autoclean;

# ABSTRACT: A REST API client for ValidSign

use Carp qw(croak);
use HTTP::Request;
use JSON qw(decode_json);
use URI;
use Types::Standard qw(Str);
use WebService::ValidSign::Types qw(
    WebServiceValidSignURI
);

has lwp => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has endpoint => (
    is       => 'ro',
    isa      => WebServiceValidSignURI,
    default  => sub { 'https://try.validsign.nl/api' },
    coerce   => 1
);

has secret => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub args_builder {
    my $self = shift;
    return map { $_ => $self->$_ } qw(secret endpoint lwp);
}

sub _build_lwp {
    require LWP::UserAgent;
    return LWP::UserAgent->new(
        agent                 => "WebService::ValidSign/$VERSION",
        protocols_allowed     => [qw(https)],
        ssl_opts              => { verify_hostname => 1 },
        requests_redirectable => [qw(HEAD GET)],
    );
}

around '_build_lwp' => sub {
    my ($orig, $self, @args) = @_;

    my $lwp = $orig->($self, @args);

    $lwp->default_header("Authorization", join(" ", "Basic", $self->secret));
    return $lwp;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::API::Constructor - A REST API client for ValidSign

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use WebService::ValidSign;

    my $client = WebService::ValidSign->new(
        secret   => "Your API key",
        endpoint => 'https://hostname.validsign.nl/api'
    );

    $client->

=head1 ATTRIBUTES

=over

=item api_uri

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
