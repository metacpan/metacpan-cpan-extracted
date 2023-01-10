package WebService::DS::SOP::Auth::V1_1::Util;
use strict;
use warnings;
use Carp ();
use Digest::SHA qw(hmac_sha256_hex);
use Exporter qw(import);
use JSON::XS qw(decode_json);

our @EXPORT_OK = qw( create_signature is_signature_valid );

our $SIG_VALID_FOR_SEC = 10 * 60; # Valid for 10 min by default

sub create_signature {
    my ($params, $app_secret) = @_;
    my $data_string
            = ref($params) eq 'HASH'  ? create_string_from_hashref($params)
            : !ref($params)           ? $params
            : do { Carp::croak("create_signature does not handle type: ". ref($params)) };
    hmac_sha256_hex($data_string, $app_secret);
}

sub create_string_from_hashref {
    my $params = shift;
    join(
        '&',
        map {
            Carp::croak("Structured data not allowed") if ref $params->{$_};
            $_. '='. ($params->{$_} || '');
        } sort { $a cmp $b } grep { !m/^sop_/ } keys %$params
    );
}

sub is_signature_valid {
    my ($sig, $params, $app_secret, $time) = @_;
    $time ||= time;

    my $req_time = ref($params) ? $params->{time}
                 : decode_json($params)->{time};

    return if not $req_time;
    return if $req_time < ($time - $SIG_VALID_FOR_SEC)
           or $req_time > ($time + $SIG_VALID_FOR_SEC);

    $sig eq create_signature($params, $app_secret);
}

1;

__END__

=encoding utf-8

=head1 NAME

WebService::DS::SOP::Auth::V1_1::Util - SOP version 1.1 authentication handy utilities

=head1 SYNOPSIS

    use WebService::DS::SOP::Auth::V1_1 qw(create_signature is_signature_valid);

When creating a signature:

    my $params = {
        app_id => 12345,
        app_mid => 'my-uniq-id-12345',
        time => 123456,
    };
    $params->{sig} = create_signature($params, $app_secret);
    #=> "$params" is signed with a valid HMAC SHA256 hash signature.

or when validating a signature:

    my $sig = delete $params->{sig};
    my $is_valid = is_signature_valid($sig, $params, $app_secret);
    #=> "$is_valid" is 1 if "sig" value is acceptable.

=head1 METHODS

=head2 create_signature( $params, $app_secret )

Creates a HMAC SHA256 hash signature.
C<$params> can either be a SCALAR or a HASH-ref.

=head2 create_string_from_hashref( $params )

Creates a string from parameters in type hashref.

=head2 is_signature_valid( $sig, $params, $app_secret, $time )

Validates if a signature is valid for given parameters.
C<$time> is optional where C<time()> is used by default.

=head1 SEE ALSO

L<WebService::DS::SOP::Auth::V1_1>

=head1 LICENSE

Copyright (C) dataSpring, Inc.
Copyright (C) Research Panel Asia, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yoko.oyama [ at ] d8aspring.comE<gt>

=cut

