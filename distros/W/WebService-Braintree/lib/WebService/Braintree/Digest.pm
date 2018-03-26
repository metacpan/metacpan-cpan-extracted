# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Digest;

use 5.010_001;
use strictures 1;

use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use Digest::SHA1;
use Digest::SHA256;
use Digest::SHA qw(hmac_sha256_hex);
use WebService::Braintree::DigestSHA256;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(hexdigest hexdigest_256);
our @EXPORT_OK = qw();

sub hexdigest {
    my($key, $data) = @_;
    return _hexdigest($key, $data, "SHA-1");
}

sub hexdigest_256 {
    my($key, $data) = @_;
    return _hexdigest($key, $data, "SHA-256");
}

# Methods below here are only used within this class.

sub algo_class {
    my ($algo) = @_;
    if ($algo eq "SHA-1") {
        return "Digest::SHA1";
    } else {
        return "WebService::Braintree::DigestSHA256";
    }
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

# UNUSED?
sub secure_compare {
    my ($left, $right) = @_;

    if ((not defined($left)) || (not defined($right))) {
        return 0;
    }

    my @left_bytes = unpack("C*", $left);
    my @right_bytes = unpack("C*", $right);

    if (scalar(@left_bytes) != scalar(@right_bytes)) {
        return 0;
    }

    my $result = 0;
    for (my $i = 0; $i < scalar(@left_bytes); $i++) {
        $result |= $left_bytes[$i] ^ $right_bytes[$i];
    }
    return $result == 0;
}

1;
__END__
