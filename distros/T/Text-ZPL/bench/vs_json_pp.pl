use strict; use warnings;
use Benchmark 'cmpthese';

use JSON::Tiny ();
use JSON::PP 'encode_json', 'decode_json';
use Text::ZPL;

my $struct = +{
  foo => 'bar',
  bar => 'baz',
  hash => +{
    x => 1, y => 2, z => 3,
    list => [ 1 .. 100 ],
  },
  hash2 => +{
    a => 1, b => 2, c => 3,
    list => [ 1 .. 100 ],
  },
};

my $tiny = JSON::Tiny->new;

my ($js, $tjs, $zpl);
cmpthese( 2_000, +{
  encode_jsonpp => sub {
    $js = encode_json $struct
  },
  encode_jsontiny => sub {
    $tjs = $tiny->encode($struct)
  },
  encode_zpl => sub {
    $zpl = encode_zpl $struct
  },
});

cmpthese( 2_000, +{
  decode_jsonpp => sub {
    decode_json $js
  },
  decode_jsontiny => sub {
    $tiny->decode($tjs)
  },
  decode_zpl => sub {
    decode_zpl $zpl
  },
});
