package WebService::Postex;
use v5.26;
use Object::Pad;

our $VERSION = '0.006';

# ABSTRACT: A Postex WebService implemenation in Perl

class WebService::Postex;
use Carp qw(croak);
use HTTP::Request::Common;
use JSON::XS;
use LWP::UserAgent;
use URI;

field $base_uri :param;
field $generator_id :param;
field $secret :param;

field $ua :param = undef;

method _set_ua_defaults() {
    $ua->default_header(Accept        => 'application/json');
    $ua->default_header(Authorization => "Bearer $secret");
}

ADJUSTPARAMS {
    my $args = shift;

    $ua //= LWP::UserAgent->new(
        agent   => sprintf('%s/%s', __PACKAGE__, $VERSION),
        timeout => 30,
    );
    $self->_set_ua_defaults;

    $base_uri = URI->new($base_uri) unless ref $base_uri;
}

method _call($req) {
    my $res = $ua->request($req);
    unless ($res->is_success) {
        my $uri = $req->uri . "";
        die "Unsuccesful request to $uri: " . $res->status_line, $/;
    }

    my $json = decode_json($res->decoded_content);
    if ($json->{data}{status} eq 'error') {
        die "Error occurred calling Postex", $/;
    }
    return $json;
}

method generation_rest_upload(%payload) {
    my $uri = $self->_build_uri('generators', $generator_id, 'generate');
    my $req = $self->_prepare_post($uri, %payload);
    return $self->_call($req);
}

method generation_rest_upload_check(%payload) {
    my $uri = $self->_build_uri('generators', $generator_id);
    my $req = $self->_prepare_get($uri, %payload);
    return $self->_call($req);
}

method generation_file_upload(%payload) {
    my $uri = $self->_build_uri('generators', $generator_id, 'generate');
    my $req = $self->_prepare_post($uri, %payload);
    return $self->_call($req);
}

method generation_file_upload_check(%payload) {
    my $uri = $self->_build_uri('generators', $generator_id, 'generate');
    my $req = $self->_prepare_get($uri, %payload);
    return $self->_call($req);
}

method generation_session_status($session_id) {
    my $uri = $self->_build_uri('generators', $generator_id, 'generate');
    my $req = $self->_prepare_get($uri);
    return $self->_call($req);
}

method profile_file_upload($recipient_id, %payload) {
    die "Unsupported method", $/;
    my $uri = $self->_build_uri(qw(recipients upload), $recipient_id);
    my $req = $self->_prepare_post($uri, %payload);
    return $self->_call($req);
}

method _build_uri(@data) {
    my $uri = $base_uri->clone;
    my @segments = $uri->path_segments;
    $uri->path_segments(@segments, qw(rest v2), @data);
    return $uri;
}

method _prepare_request($uri, %payload) {
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

method _prepare_post($uri, %payload) {
    return PUT($self->_prepare_request($uri, %payload));
}

method _prepare_get($uri, %payload) {
    return GET($self->_prepare_request($uri, %payload));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Postex - A Postex WebService implemenation in Perl

=head1 VERSION

version 0.006

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
