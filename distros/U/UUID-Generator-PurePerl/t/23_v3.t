use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 5 + 5;

eval q{ use UUID::Generator::PurePerl; };
die if $@;

my $gen = UUID::Generator::PurePerl->new();

# randomly generated dns names
my @dnss = (
    'OmR3-YMjei.rJ.example.org',
    '43bdfd7f-7b4f-35b3-9b2a-4adce1dea760',

    'uFdQ.Efo7-i.example.net',
    '53047a8c-9328-3e24-a7d5-b674aa20e59a',

    'FJZ.Bkw25.7.example.org',
    '2fd9c909-4b15-3784-bd8b-e47700c7ff46',

    'JUp.dX.bT6Xc.example.net',
    'e65c4f18-4db9-34b8-9e84-057bfbccd6c3',

    'Xe-zmmg.example.net',
    '80dcb1c8-eafe-34b7-8d6e-d62fb0103ff8',
);

while (@dnss) {
    my ($name, $want) = splice @dnss, 0, 2;
    my $uuid = lc $gen->generate_v3(uuid_ns_dns(), $name)->as_string;

    is( $uuid, $want, 'ns:DNS:' . $name );
}

# randomly generated urls
my @urls = (
    'http://TaAe7.zQ5BQ.g.example.net/5S.oyF/tz-dfs',
    '10515fbf-4221-36ba-afde-dcddb821d211',

    'http://EYPi-Qcx.example.net/FZOW/wM7/Np5f-4',
    '4ab3c44c-c2c3-369c-a14a-915c413e75c6',

    'http://qFy.wQoT-k.example.org/DdYD-S',
    '881fa878-d5cf-3182-95d7-6dd633e98920',

    'http://dpkQb.YI.U.example.org/',
    '93ba72d9-eee4-34e0-a2ff-944eefdeff36',

    'http://JjcTj.example.org/p2Xq/uH0X/SFFz',
    'e52a1a15-c686-37a4-a548-ff6d7594da98',
);

while (@urls) {
    my ($name, $want) = splice @urls, 0, 2;
    my $uuid = lc $gen->generate_v3(uuid_ns_url(), $name)->as_string;

    is( $uuid, $want, 'ns:URL:' . $name );
}

# TODO: OID and X.500 ?

