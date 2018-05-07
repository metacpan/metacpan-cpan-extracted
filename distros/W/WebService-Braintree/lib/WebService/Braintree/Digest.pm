# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Digest;

use 5.010_001;
use strictures 1;

use Carp qw(confess);

use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use Digest;
use Digest::SHA;
use Digest::SHA1;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hexdigest);

sub hexdigest {
    my($key, $data) = @_;
    return _hexdigest($key, $data, "SHA-1");
}

# Methods below here are only used within this class.

sub algo_class {
    my ($algo) = @_;
    if ($algo eq "SHA-1") {
        return "Digest::SHA1";
    }
    confess "Unhandled algorithm '$algo'";
}

sub hmac {
    my($key, $algo) = @_;
    return Digest::HMAC->new($key, algo_class($algo));
}

sub _hexdigest {
    my ($key, $data, $algo) = @_;
    my $digested_key = key_digest($algo, $key);
    my $hmac = hmac($digested_key, $algo);
    $hmac->add($data);
    return $hmac->hexdigest;
}

sub key_digest {
    my ($alg, $key) = @_;
    my $sha = Digest->new($alg);
    $sha->add($key);
    return $sha->digest;
}

1;
__END__
