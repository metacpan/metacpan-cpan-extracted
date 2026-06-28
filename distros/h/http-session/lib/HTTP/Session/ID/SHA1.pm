package HTTP::Session::ID::SHA1;
use strict;
use warnings;
use Carp ();
use Digest::SHA ();
use Crypt::URandom ();

sub generate_id {
    my ($class, $sid_length) = @_;
    if ( !defined($sid_length) || $sid_length !~ /\A[1-9][0-9]*\z/ ) {
        Carp::croak "sid_length must be a positive integer";
    }
    # Hash cryptographically secure random bytes (CVE-2026-3256). sha1 output is
    # 160 bits, so 20 random bytes fully seed it; preserves the legacy hex format.
    return substr(Digest::SHA::sha1_hex(Crypt::URandom::urandom(20)), 0, $sid_length);
}

1;
