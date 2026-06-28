package HTTP::Session::ID::Urandom;
use strict;
use warnings;
use utf8;
use 5.008_001;
use Carp ();
use MIME::Base64 ();
use POSIX ();
use Crypt::URandom ();

sub generate_id {
    my ($class, $sid_length) = @_;
    if ( !defined($sid_length) || $sid_length !~ /\A[1-9][0-9]*\z/ ) {
        Carp::croak "sid_length must be a positive integer";
    }
    # bytes of CSPRNG input needed to yield at least $sid_length base64url chars
    my $src_len = POSIX::ceil($sid_length * 3.0 / 4.0);
    # Generate session id from a cryptographically secure source.
    my $buf = Crypt::URandom::urandom($src_len);
    my $result = MIME::Base64::encode_base64($buf, '');
    $result =~ tr|+/=|\-_|d; # make it url safe
    return substr($result, 0, $sid_length);
}

1;
