# -*- perl -*-
use strict;
use warnings;
use Crypt::CBC;
use Test::More tests => 32;
use Test::Exception;
use Tripletail qw(/dev/null);

my $ser;
lives_ok {
    $ser = $TL->newSerializer();
};
isa_ok $ser, 'Tripletail::Serializer';

# Tests without AES encryption
lives_and {
    my $val = {a => -5000, b => ['bar', 'baz'], c => 3.1415};
    is_deeply $ser->deserialize($ser->serialize($val)), $val;
};

lives_and {
    # The deserializer used to choke on LF in a payload.
    my $val = "Hello,\nWorld!";
    is $ser->deserialize($ser->serialize($val)), $val;
};

lives_and {
    # The serializer used to interpret the string like this as a
    # floating point number.
    my $val = '5098683801314e0309000005';
    is $ser->deserialize($ser->serialize($val)), $val;
};

lives_and {
    # This value will involve compression.
    my $val = [0, 0, 0, 0, 0, 0, 0, 0];
    is_deeply $ser->deserialize($ser->serialize($val)), $val;
};

lives_and {
    use utf8;
    my $val = 'Chào bạn.';

    local $SIG{__DIE__ } = 'DEFAULT';
    local $SIG{__WARN__} = sub { die shift };

    is $ser->deserialize($ser->serialize($val)), $val;
};

do {
    # The codec for integer is rather complicated, so we want to test
    # it extensively.
    my @ints = (
        0x0000000, # 0 octets
        0x0000001, # 1 octet
        0x000007F, # 1 octet
        0x0000080, # 2 octets
        0x0003FFF, # 2 octets
        0x0004000, # 3 octets
        0x01FFFFF, # 3 octets
        0x0200000, # 4 octets
        0x0FFFFFF, # 4 octets
        0x1000000  # 5 octets
       );
    foreach my $int (@ints, map {$_ * -1} @ints) {
        lives_and {
            is $ser->deserialize($ser->serialize($int)), $int, "integer: $int";
        };
    }
};

# Tests with AES encryption
my $key = Crypt::CBC->random_bytes(32);
is $ser->getCryptoKey, undef;
lives_ok {
    $ser->setCryptoKey($key);
};
is $ser->getCryptoKey, $key;

lives_and {
    my $val = {a => -5000, b => ['bar', 'baz'], 3 => 3.1415};
    is_deeply $ser->deserialize($ser->serialize($val)), $val;
};

lives_and {
    # This value will involve compression.
    my $val = [0, 0, 0, 0, 0, 0, 0, 0];
    is_deeply $ser->deserialize($ser->serialize($val)), $val;
};
