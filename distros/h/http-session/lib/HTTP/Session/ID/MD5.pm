package HTTP::Session::ID::MD5;
use strict;
use warnings;
use Carp ();
use Digest::MD5 ();
use Crypt::URandom ();

# Digest::MD5 was first released with perl 5.007003

sub generate_id {
    my ($class, $sid_length) = @_;
    if ( !defined($sid_length) || $sid_length !~ /\A[1-9][0-9]*\z/ ) {
        Carp::croak "sid_length must be a positive integer";
    }
    # Hash cryptographically secure random bytes (CVE-2026-3256). md5 output is
    # 128 bits, so 16 random bytes fully seed it; preserves the legacy hex format.
    return substr(Digest::MD5::md5_hex(Crypt::URandom::urandom(16)), 0, $sid_length);
}

1;
