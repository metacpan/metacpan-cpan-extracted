use 5.020;
use UE;
require POSIX;
use Net::SSLeay ();

#my $t = PE::Timer->new; $t->start(2); $t->callback(sub {

my $ctx = Net::SSLeay::CTX_new;
Net::SSLeay::CTX_use_certificate_file($ctx, 't/cert/cert.pem', Net::SSLeay::FILETYPE_PEM());
Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, 't/cert/key.pem', Net::SSLeay::FILETYPE_PEM());
#Net::SSLeay::SSL_CTX_set_options($ctx, Net::SSLeay::SSL_OP_NO_RENEGOTIATION());

$SIG{PIPE} = 'IGNORE';
$0 = 'jsrc';

my ($foo, @foo);

    my $t = UniEvent::Timer->new; $t->start(0.2); $t->callback(sub {
        $_->reset for (splice @foo);
        do {my$foo=$_, $_->write("shit", sub {undef $foo}), $_->reset} for (splice @foo);
    });


warn $$;

my $sock = UE::Tcp->new;
$sock->use_ssl($ctx);
$sock->bind('*', 6669);

$sock->listen(sub {
    my (undef, $cli) = @_;


push @foo, $cli;

=cut
$cli->write("shit", sub {
    shift->write("shit", sub {
        shift->reset;
        undef $cli;
        #shift->write("shit");
    });
});
=cut

$cli->write("shit", sub{
    $cli->write("jopa", sub {
#warn "@_";
        $cli->reset;
    });
#    $cli->reset;
    #undef $cli;
});
return;



    $cli->write("shit", sub {
        $cli->write("shit", sub {
            $cli->reset;
            undef $cli;
        });
    });



=cut
    $cli->read_start;
    $cli->read_callback(sub {

$foo = !$foo;


        #$cli->write("HTTP/1.0 301 Moved Permanently\r\nLocation: http://93.159.239.44:6666/\r\nConnection: close\r\n\r\n") if $foo;
        $cli->write("HTTP/1.0 301 Moved Permanently\r\nLocation: http://dev.crazypanda.ru:6666/\r\nConnection: close\r\n\r\n");

        #$cli->write("HTTP/1.0 302 Found\r\nLocation: http://ya.ru/\r\nConnection: close\r\n\r\n");
        $cli->shutdown;
        $cli->disconnect;

        undef $cli;

#use Devel::Peek ; Dump $_[0];

#        use DDP; p \@_; 1
    });
=cut



=cut
    $cli->write("OK");
    my $t = UniEvent::Timer->new; $t->start(1); $t->callback(sub {
        undef $t;
        $cli->reset;
#        $cli->shutdown;
#        $cli->disconnect;
#        undef $cli;
    });
=cut
} => 666);

UE::Loop->default->run;
