use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message::Response;
use ZMQx::RPC::Header;
use JSON::XS;

subtest 'defaults' => sub {
    my $msg = ZMQx::RPC::Message::Response->new(
        status=>200,
        payload=>['hello','world']
    );
    my $packed = $msg->pack;
    is($packed->[0],200,'status');
    is($packed->[1],'string;','header (no timeout)');
    is($packed->[2],'hello','payload');
    is($packed->[3],'world','payload');
};

subtest 'unpack JSON' => sub {
    my $msg = ZMQx::RPC::Message::Response->unpack([
        200,
        'JSON;',
        '{"hase":"baer"}',
    ]);
    is($msg->status,200,'unpack: status');
    is($msg->payload->[0]{hase},'baer','unpack: JSON payload');
};

subtest 'error' => sub {
    my $msg = ZMQx::RPC::Message::Response->new_error(
        500, 'err'
    );
    is($msg->status,500,'error: status');
    is($msg->header->type,'string','error: header');
    is($msg->payload->[0],'err','error: payload');
};

subtest 'error' => sub {
    my $msg = ZMQx::RPC::Message::Response->new_error(
        500, 'err'
    );
    is($msg->status,500,'error: status');
    is($msg->payload->[0],'err','error: payload');
};



done_testing();

