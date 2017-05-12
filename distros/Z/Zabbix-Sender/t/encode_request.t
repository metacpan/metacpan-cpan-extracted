use warnings;
use strict;
use Test::More tests => 10;
use Test::Deep;
use JSON::XS;
use_ok 'Zabbix::Sender';

# First, encode a short request and decode it in two ways:
# 1. The first way uses unpack 'V'
my $host = 'sender';
my $zs = Zabbix::Sender->new( server => 'server', hostname => $host );
my $item = 'test';
my $value = 42;
my $encoded = $zs->_encode_request([ [$host, $item, $value] ]);
#print $encoded;
my @list = unpack 'a4 b V V a*', $encoded;
use Data::Dumper;
#print Dumper \@list;

my $testmsg = '{"request":"sender data","data":[{"value":42,"key":"test","host":"sender"}]}';

cmp_ok(scalar(@list), '==', 5, 'unpack length');
cmp_ok($list[0], 'eq', 'ZBXD', 'Zabbix Header "ZBXD"');
cmp_ok($list[1], '==', 1, 'Zabbix Header "1"');
cmp_ok($list[2], '==', length($list[4]), 'Message Length (low 32 bit)');
cmp_ok($list[2], '==', length($testmsg), 'Message Length (low 32 bit)');
cmp_ok($list[3], '==', 0, 'Message Length (high 32 bit)');
my $res = decode_json($list[4]);
cmp_deeply {
  request => "sender data",
  data => [
    {
      value => 42,
      key => 'test',
      host => 'sender',
    }
  ]
}, $res;

# 2. The second way uses unpack 'C'
my @list2 = unpack 'a4 b C4 V a*', $encoded;
#print Dumper \@list2;
cmp_ok($list2[2], '==', 76, 'Message Length (low 8 bit)');

# Second, encode a long request with a length > 256
my $encoded2 = $zs->_encode_request([ [$host, 'item' x 200, '42' x 200] ]);
my @list3 = unpack 'a4 b V V a*', $encoded2;
#print Dumper \@list3;
cmp_ok($list3[2], '==', 200*6 + 76 - 4, 'Message Length (low 32 bit)');

