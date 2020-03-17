use 5.012;
use UE;
use Net::SSLeay ();

say "start $$";

my $ctx = Net::SSLeay::CTX_new;
Net::SSLeay::CTX_use_certificate_file($ctx, 'cert.pem', Net::SSLeay::FILETYPE_PEM());
Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, 'key.pem', Net::SSLeay::FILETYPE_PEM());

my $sock = UE::TCP->new;
$sock->use_ssl($ctx);
$sock->bind('*', 4502);
$sock->listen(666, sub {
    my (undef, $cli) = @_;

    $cli->read_start;
    $cli->read_callback(sub {
        
    });
    $cli->write("OK");
    my $t = UE::Timer->new; $t->start(1); $t->callback(sub {
        #$cli->write("OK");
        undef $t;
        $cli->reset;
        undef $cli;
    });
});

UE::Loop->default->run;
