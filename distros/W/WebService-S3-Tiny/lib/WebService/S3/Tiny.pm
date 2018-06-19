package WebService::S3::Tiny 0.003;

use strict;
use warnings;

use Carp;
use Digest::SHA qw/hmac_sha256 hmac_sha256_hex sha256_hex/;
use HTTP::Tiny 0.014;

my %url_enc = map { chr, sprintf '%%%02X', $_ } 0..255;

sub new {
    my ( $class, %args ) = @_;

    $args{access_key} // croak '"access_key" is required';
    $args{host}       // croak '"host" is required';
    $args{region}     //= 'us-east-1';
    $args{secret_key} // croak '"secret_key" is requried';
    $args{service}    //= 's3';
    $args{ua}         //= HTTP::Tiny->new;

    bless \%args, $class;
}

sub delete_bucket { $_[0]->request( 'DELETE', $_[1], undef, undef, $_[2]        ) }
sub    get_bucket { $_[0]->request( 'GET',    $_[1], undef, undef, $_[2], $_[3] ) }
sub   head_bucket { $_[0]->request( 'HEAD',   $_[1], undef, undef, $_[2]        ) }
sub    put_bucket { $_[0]->request( 'PUT',    $_[1], undef, undef, $_[2]        ) }
sub delete_object { $_[0]->request( 'DELETE', $_[1], $_[2], undef, $_[3]        ) }
sub    get_object { $_[0]->request( 'GET',    $_[1], $_[2], undef, $_[3], $_[4] ) }
sub   head_object { $_[0]->request( 'HEAD',   $_[1], $_[2], undef, $_[3]        ) }
sub    put_object { $_[0]->request( 'PUT',    $_[1], $_[2], $_[3], $_[4]        ) }

sub request {
    my ( $self, $method, $bucket, $object, $content, $headers, $query ) = @_;

    $headers //= {};

    # Lowercase header keys.
    %$headers = map { lc, $headers->{$_} } keys %$headers;

    $query = HTTP::Tiny->www_form_urlencode( $query // {} );

    $headers->{host} = $self->{host} =~ s|^https?://||r;

    # Prefer user supplied checksums.
    my $sha = $headers->{'x-amz-content-sha256'} //= sha256_hex $content // '';

    my ( $path, $time, $date, $cred_scope )
        = $self->_common_prep( $bucket, $object );

    $headers->{'x-amz-date'} = $time;

    my $signed_headers = join ';', sort keys %$headers;

    my $creq = $self->_make_canonical_request(
        $method, $path, $query, $headers, $signed_headers, $sha );

    my $sig = $self->_sign_request( $creq, $time, $cred_scope );

    $headers->{authorization} = join(
        ', ',
        "AWS4-HMAC-SHA256 Credential=$self->{access_key}/$cred_scope",
        "SignedHeaders=$signed_headers",
        "Signature=$sig",
    );

    # HTTP::Tiny doesn't like us providing our own host header, but we have to
    # sign it, so let's hope HTTP::Tiny calculates the same value as us :-S
    delete $headers->{host};

    $self->{ua}->request(
        $method => "$self->{host}$path?$query",
        { content => $content, headers => $headers },
    );
}

sub delete_bucket_url { $_[0]->signed_url( 'DELETE', $_[1], undef, $_[2], $_[3]        ) }
sub    get_bucket_url { $_[0]->signed_url( 'GET',    $_[1], undef, $_[2], $_[3], $_[4] ) }
sub   head_bucket_url { $_[0]->signed_url( 'HEAD',   $_[1], undef, $_[2], $_[3]        ) }
sub    put_bucket_url { $_[0]->signed_url( 'PUT',    $_[1], undef, $_[2], $_[3]        ) }
sub delete_object_url { $_[0]->signed_url( 'DELETE', $_[1], $_[2], $_[3], $_[4]        ) }
sub    get_object_url { $_[0]->signed_url( 'GET',    $_[1], $_[2], $_[3], $_[4], $_[5] ) }
sub   head_object_url { $_[0]->signed_url( 'HEAD',   $_[1], $_[2], $_[3], $_[4]        ) }
sub    put_object_url { $_[0]->signed_url( 'PUT',    $_[1], $_[2], $_[3], $_[4]        ) }

sub signed_url {
    my ( $self, $method, $bucket, $object, $expires, $headers, $query ) = @_;
    $expires //= 604800; # One week, maximum

    $headers //= {};

    # Lowercase header keys.
    %$headers = map { lc, $headers->{$_} } keys %$headers;

    $headers->{host} = $self->{host} =~ s|^https?://||r;

    my ( $path, $time, $date, $cred_scope )
        = $self->_common_prep( $bucket, $object );

    my $signed_headers = join ';', sort keys %$headers;

    $query = {
        %{$query // {}},
        'X-Amz-Algorithm'     => 'AWS4-HMAC-SHA256',
        'X-Amz-Credential'    => "$self->{access_key}/$cred_scope",
        'X-Amz-Date'          => $time,
        'X-Amz-Expires'       => $expires,
        'X-Amz-SignedHeaders' => $signed_headers,
    };

    $query = HTTP::Tiny->www_form_urlencode( $query );

    my $creq = $self->_make_canonical_request(
        $method, $path, $query, $headers, $signed_headers, 'UNSIGNED-PAYLOAD' );

    my $sig = $self->_sign_request( $creq, $time, $cred_scope );

    $query .= '&X-Amz-Signature=' . $sig;

    return "$self->{host}$path?$query";
}

sub _common_prep {
    my ( $self, $bucket, $object ) = @_;

    utf8::encode my $path = _normalize_path( join '/', '', $bucket, $object // () );

    $path =~ s|([^A-Za-z0-9\-\._~/])|$url_enc{$1}|g;

    my ( $s, $m, $h, $d, $M, $y ) = gmtime;

    my $time = sprintf '%d%02d%02dT%02d%02d%02dZ',
        $y + 1900, $M + 1, $d, $h, $m, $s;

    my $date = substr $time, 0, 8;

    my $scope = "$date/$self->{region}/$self->{service}/aws4_request";

    return ( $path, $time, $date, $scope );
}

sub _make_canonical_request {
    my ( $self, $method, $path, $query_string, $headers, $signed_headers, $sha ) = @_;

    my $creq_headers = '';

    for my $k ( sort keys %$headers ) {
        my $v = $headers->{$k};

        $creq_headers .= "\n$k:";

        $creq_headers .= join ',',
            map s/\s+/ /gr =~ s/^\s+|\s+$//gr,
            map split(/\n/), ref $v ? @$v : $v;
    }

    utf8::encode my $creq = "$method\n$path\n$query_string$creq_headers\n\n$signed_headers\n$sha";

    return $creq;
}

sub _normalize_path {
    my @old_parts = split m(/), $_[0], -1;
    my @new_parts;

    for ( 0 .. $#old_parts ) {
        my $part = $old_parts[$_];

        if ( $part eq '..' ) {
            pop @new_parts;
        }
        elsif ( $part ne '.' && ( length $part || $_ == $#old_parts ) ) {
            push @new_parts, $part;
        }
    }

    '/' . join '/', @new_parts;
}

sub _sign_request {
    my ( $self, $creq, $time, $scope ) = @_;

    my $date = substr $time, 0, 8;

    return hmac_sha256_hex(
        "AWS4-HMAC-SHA256\n$time\n$scope\n" . sha256_hex($creq),
        hmac_sha256(
            aws4_request => hmac_sha256(
                $self->{service} => hmac_sha256(
                    $self->{region},
                    hmac_sha256( $date, "AWS4$self->{secret_key}" ),
                ),
            ),
        ),
    );
}

1;
