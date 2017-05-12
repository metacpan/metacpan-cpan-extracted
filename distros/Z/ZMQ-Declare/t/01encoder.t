use strict;
use warnings;
use Test::More;

use ZMQ::Declare::ZDCF::Encoder::JSON;
use ZMQ::Declare::ZDCF::Encoder::DumpEval;
use ZMQ::Declare::ZDCF::Encoder::Storable;

my $test_structures = {
  empty => {},
  version => {version => 1.0},
  more => {
    version => 1.0,
    apps => {
      foo => {
        context => {iothreads => 1},
        devices => {
          foo => {
            sockets => {
              foo => {type => 'sub', bind => [qw(a b c)]},
            },
          }
        },
      },
    },
  },
};

my @encoders = qw(JSON DumpEval Storable);

foreach my $encoder (@encoders) {
  my $class = "ZMQ::Declare::ZDCF::Encoder::$encoder";
  my $obj = new_ok($class);
  foreach my $str_name (keys %$test_structures) {
    my $structure = $test_structures->{$str_name};
    my $out = $obj->encode($structure);
    is(ref($out), 'SCALAR', "$encoder: $str_name encoded to scalar ref");
    ok(!ref($$out), "$encoder: $str_name encoded to scalar ref to string");
    my $back = $obj->decode($out);
    is_deeply($back, $structure, "$encoder: $str_name roundtrip");
  }
}

done_testing();
