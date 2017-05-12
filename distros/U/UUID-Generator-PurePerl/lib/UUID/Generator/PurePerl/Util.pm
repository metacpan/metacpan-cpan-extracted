package UUID::Generator::PurePerl::Util;

use strict;
use warnings;

use Exporter;
*import = \&Exporter::import;

our @EXPORT = qw( digest_as_octets digest_as_32bit digest_as_16bit );

use Carp;
use Digest;

sub fold_into_octets {
    my ($num_octets, $s) = @_;

    my $x = "\x0" x $num_octets;

    while (length $s > 0) {
        my $n = q{};
        while (length $x > 0) {
            my $c = ord(substr $x, -1, 1, q{}) ^ ord(substr $s, -1, 1, q{});
            $n = chr($c) . $n;
            last if length $s <= 0;
        }
        $n = $x . $n;

        $x = $n;
    }

    return $x;
}

{
    my $digester;

    sub digester {
        if (! defined $digester) {
            my $d;
            $d = eval { Digest->new('SHA-1') };
            $d = eval { Digest->new('MD5')   }  if $@;
            $d = UUID::Generator::PurePerl::Util::PseudoDigester->new() if $@;
            $digester = $d;
        }

        return $digester;
    }
}

sub digest_as_octets {
    my $num_octets = shift;

    my $d = digester();
    $d->reset();
    $d->add($_) for @_;

    return fold_into_octets($num_octets, $d->digest);
}

sub digest_as_32bit {
    return unpack 'N', digest_as_octets(4, @_);
}

sub digest_as_16bit {
    return unpack 'n', digest_as_octets(2, @_);
}

package UUID::Generator::PurePerl::Util::PseudoDigester;

sub new {
    my $class = shift;
    my $entity = q{};

    return bless \$entity, $class;
}

sub digest {
    my $self = shift;

    my $entity = $$self;

    my $source = q{};
    while (length $entity > 0) {
        # 4 bytes seems to be enough (8 bytes in ordinal crypt() impl.)
        my $token = substr($entity, 0, 4, q{}) . "\0\0\0\0";
        $source .= crypt $token, $token;
    }

    my @r = ( 0, 0, 0, 0 );     # 32bits * 4
    my $index = 0;
    while (length $source > 0) {
        my $token = substr($source, 0, 4, q{}) . "\0\0\0\0";
        $r[$index] ^= unpack 'N', $token;

        $index = ($index + 1) % 4;
    }

    return pack 'NNNN', @r;
}

sub reset {
    my $self = shift;
    $$self = q{};
    return $self;
}

sub add {
    my ($self, $data) = @_;
    $$self .= $data;
    return $self;
}

1;
__END__
