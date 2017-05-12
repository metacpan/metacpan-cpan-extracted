use strict;
use warnings;

use Test::More;
use XML::Stream 'Node';
# this won't work if 'Node' is not listed there but in Net::XMPP it is working
# apparently by chance as one of the sub-modules import XML::Stream with Node option

# cases that are used in Net::XMPP
# when connecting to GTalk


plan tests => 3;

my $xs = XML::Stream->new(
   'style'      =>    'node',
   'debugfh'    =>    undef,
   'debuglevel' =>    '-1',
   'debugtime'  =>    0,
);
isa_ok $xs, 'XML::Stream';

$xs->Connect(
    'hostname'       => 'talk.google.com',
    'port'           => 5222,
    'namespace'      => 'jabber:client',
    'connectiontype' => 'tcpip',
    'timeout'        => 10,
    'ssl_verify'     => 0,
    'ssl'            => 0,
    '_tls'           => 1,
    'to'             => 'gmail.com',
);

isa_ok $xs, 'XML::Stream';

eval "use Test::Memory::Cycle";
my $fail = $@;
# TODO...
SKIP: {
    skip 'Needs Test::Memory::Cycle', 1 if $fail;
    memory_cycle_ok($xs);
}


