package WWW::YNAB::UA;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::UA::VERSION = '0.02';

use 5.010;
use Moose;

use HTTP::Tiny;
use IO::Socket::SSL; # Necessary for https URLs on HTTP::Tiny.
use JSON::PP;
use Carp;

has access_token => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has base_uri => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has ua => (
    is       => 'ro',
    isa      => 'HTTP::Tiny',
    required => 1,
);

has rate_limit => (
    is        => 'ro',
    isa       => 'Int',
    writer    => '_set_rate_limit',
    predicate => 'knows_rate_limit',
);

has total_rate_limit => (
    is        => 'ro',
    isa       => 'Int',
    writer    => '_set_total_rate_limit',
    predicate => 'knows_total_rate_limit',
);

sub get {
    my $self = shift;
    $self->_request('get', @_);
}

sub post {
    my $self = shift;
    $self->_request('post', @_);
}

sub _request {
    my $self = shift;
    my ($method, $path, $params) = @_;

    if (0) {
        warn "\U$method\E $path";
    }

    my $base = $self->base_uri;
    $base =~ s{/$}{};
    $path =~ s{^/}{};
    my $uri = "$base/$path";

    my $response = $self->ua->$method(
        $uri,
        {
            ($params ? (content => encode_json($params)) : ()),
            headers => {
                'Content-Type'  => 'application/json; charset=UTF-8',
                'X-Accept'      => 'application/json',
                'Authorization' => 'Bearer ' . $self->access_token,
            },
        },
    );
    croak "Request for $uri failed ($response->{status}): $response->{content}"
        unless $response->{success};

    my $rate_limit = $response->{headers}{'x-rate-limit'};
    my ($current, $total) = split '/', $rate_limit;
    $self->_set_rate_limit($current);
    $self->_set_total_rate_limit($total);

    return decode_json($response->{content});
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::UA

=head1 VERSION

version 0.02

=for Pod::Coverage   get
  post

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
