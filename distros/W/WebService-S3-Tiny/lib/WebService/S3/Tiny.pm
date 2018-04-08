package WebService::S3::Tiny 0.001;

use strict;
use warnings;

use Carp;
use Digest::SHA qw/hmac_sha256 hmac_sha256_hex sha256_hex/;
use HTTP::Tiny;

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

    utf8::encode my $path = _normalize_path( join '/', '', $bucket, $object // () );

    $path =~ s|([^A-Za-z0-9\-\._~/])|$url_enc{$1}|g;

    $headers->{host} = $self->{host} =~ s|^https?://||r;

    my ( $s, $m, $h, $d, $M, $y ) = gmtime;

    my $time = $headers->{'x-amz-date'} = sprintf '%d%02d%02dT%02d%02d%02dZ',
        $y + 1900, $M + 1, $d, $h, $m, $s;

    my $date = substr $time, 0, 8;

    # Prefer user supplied checksums.
    my $sha = $headers->{'x-amz-content-sha256'} //= sha256_hex $content // '';

    my $creq_headers = '';

    for my $k ( sort keys %$headers ) {
        my $v = $headers->{$k};

        $creq_headers .= "\n$k:";

        $creq_headers .= join ',',
            map s/\s+/ /gr =~ s/^\s+|\s+$//gr,
            map split(/\n/), ref $v ? @$v : $v;
    }

    my $signed_headers = join ';', sort keys %$headers;

    utf8::encode my $creq = "$method\n$path\n$query$creq_headers\n\n$signed_headers\n$sha";

    my $cred_scope = "$date/$self->{region}/$self->{service}/aws4_request";

    my $sig = hmac_sha256_hex(
        "AWS4-HMAC-SHA256\n$time\n$cred_scope\n" . sha256_hex($creq),
        hmac_sha256(
            aws4_request => hmac_sha256(
                $self->{service} => hmac_sha256(
                    $self->{region},
                    hmac_sha256( $date, "AWS4$self->{secret_key}" ),
                ),
            ),
        ),
    );

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

1;
