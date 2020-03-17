#!/usr/bin/env perl
# use this with https://testssl.sh (wget -O - https://testssl.sh)
# ./testssl.sh localhost:4500
use 5.020;
use warnings;

use Test::More;
use Panda::Event;
use Socket;
use Net::SSLeay ();

my $ctx = Net::SSLeay::CTX_new;
Net::SSLeay::CTX_use_certificate_file($ctx, 'ca.pem', Net::SSLeay::FILETYPE_PEM());
Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, 'ca.key', Net::SSLeay::FILETYPE_PEM());

my $loop = Panda::Event::Loop->default_loop;
my $sock = new Panda::Event::TCP();

$sock->use_ssl($ctx);
$sock->bind("localhost", 4500);
$sock->listen(4500, sub {
    my (undef, $sock) = @_;
    $sock->read_start;
    $sock->read_callback(sub {
    });
    my $t = Panda::Event::Timer->new; $t->once(3); $t->callback(sub {
        $sock->write("123456");
        $sock->disconnect;
        undef $t;
    });
});

$loop->update_time();
$loop->run();

done_testing();
