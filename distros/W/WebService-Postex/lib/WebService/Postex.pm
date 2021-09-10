use utf8;

package WebService::Postex;
our $VERSION = '0.003';
use Moose;
use namespace::autoclean;

use LWP::UserAgent;
use HTTP::Request::Common;
use MooseX::Types::URI qw(Uri);
use Carp qw(croak);
use JSON::XS;

# ABSTRACT: A Postex WebService implemenation in Perl

has base_uri => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

has generator_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has secret => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has ua => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    builder => '_build_ua',
    trigger => \&_set_ua_defaults,
);


sub _set_ua_defaults {
    my ($self, $ua) = @_;
    $ua->default_header(Accept        => 'application/json');
    $ua->default_header(Authorization => "Bearer " . $self->secret);
    return $ua;

}

sub _build_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new(
        agent   => sprintf('%s/%s', __PACKAGE__, $VERSION),
        timeout => 30,
    );
    return $self->_set_ua_defaults($ua);
}

sub _call {
    my ($self, $req) = @_;

    my $res = $self->ua->request($req);

    unless ($res->is_success) {
        my $uri = $req->uri . "";
        die "Unsuccesful request to $uri: " . $res->status_line, $/;
    }

    my $json = decode_json($res->decoded_content);
    if ($json->{status} eq 'error') {
        die "Error occurred calling Postex", $/;
    }
    return $json;

}

sub generation_rest_upload {
    my ($self, %payload) = @_;

    my $uri = $self->_build_uri(qw(generation raw), $self->generator_id);
    my $req = $self->_prepare_post($uri, %payload);
    return $self->_call($req);
}

sub generation_rest_upload_check {
    my ($self, %payload) = @_;

    my $uri = $self->_build_uri(qw(generation raw), $self->generator_id);
    my $req = $self->_prepare_get($uri, %payload);
    return $self->_call($req);
}

sub generation_file_upload {
    my ($self, %payload) = @_;

    my $uri = $self->_build_uri(qw(generation upload), $self->generator_id);
    my $req = $self->_prepare_post($uri, %payload);
    return $self->_call($req);
}

sub generation_file_upload_check {
    my ($self, %payload) = @_;

    my $uri = $self->_build_uri(qw(generation upload), $self->generator_id);
    my $req = $self->_prepare_get($uri, %payload);
    return $self->_call($req);
}

sub generation_session_status {
    my ($self, $session_id) = @_;
    my $uri = $self->_build_uri(qw(generation session), $session_id);
    my $req = $self->_prepare_get($uri);
    return $self->_call($req);
}

sub profile_file_upload {
    my ($self, $recipient_id, %payload) = @_;

    my $uri = $self->_build_uri(qw(recipients upload), $recipient_id);
    my $req = $self->_prepare_post($uri, %payload);
    return $self->_call($req);
}

sub _build_uri {
    my ($self, $type, $call, $id) = @_;

    my $uri = $self->base_uri->clone;
    my @segments = $uri->path_segments;
    $uri->path_segments(@segments, qw(rest data v1), $type, $call, $id);
    return $uri;
}

sub _prepare_request {
    my ($self, $uri, %payload) = @_;

    if (my $file = delete $payload{file}) {
        $payload{file} = [$file, delete $payload{filename}];
        return (
            $uri,
            Content        => [%payload],
            'Content-Type' => 'form-data',
        );
    }

    return (
        $uri,
        %payload
        ? (
            Content        => encode_json(\%payload),
            'Content-Type' => 'application/json',
            )
        : (),
    );

}

sub _prepare_post {
    my ($self, $uri, %payload) = @_;
    return POST($self->_prepare_request($uri, %payload));
}

sub _prepare_get {
    my ($self, $uri, %payload) = @_;
    return GET($self->_prepare_request($uri, %payload));
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Postex - A Postex WebService implemenation in Perl

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::Postex;

    my $postex = WebService::Postex->new(
        base_uri     => 'https://demo.postex.com',
        generator_id => 1234,
        secret       => 'yoursecret',
    );

    my %args = ();
    $postex->generation_file_upload(%args);

=head1 DESCRIPTION

A Perl API for connecting with the Postex REST API

=head1 ATTRIBUTES

=head2 base_uri

Required. The endpoint to which to talk to

=head2 generator_id

Required. The generator ID you get from Postex

=head2 secret

Required. The secret for the authorization token.

=head1 METHODS

=head2 generation_file_upload

=head2 generation_file_upload_check

=head2 generation_rest_upload

=head2 generation_rest_upload_check

=head2 generation_session_status

=head2 profile_file_upload

=head1 SEE ALSO

=over

=item L<Postex|https://www.postex.com>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
