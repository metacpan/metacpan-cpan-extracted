use 5.020;
use lib 'meia/var/lib', 'meia/lib';
use UE;
require POSIX;
use Net::SSLeay ();

#my $t = PE::Timer->new; $t->start(2); $t->callback(sub {

my $ctx = Net::SSLeay::CTX_new;
Net::SSLeay::CTX_use_certificate_file($ctx, 'certs/cert.pem', Net::SSLeay::FILETYPE_PEM());
Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, 'certs/key.pem', Net::SSLeay::FILETYPE_PEM());

$SIG{PIPE} = 'IGNORE';
$0 = 'jsrc';

our ($foo, @foo);


warn $$;

my $sock = UE::Tcp->new;
$sock->bind('*', 6669);

my $i=0;
$sock->listen(sub {
    my (undef, $cli) = @_;


push @foo, $cli;

warn "Z";
$cli->reset if ++$i % 2 == 0;

$cli->write("HTTP/1.0 301 Moved Permanently\r\nLocation: http://dev.crazypanda.ru:6669/\r\n\r\n");
$cli->shutdown;
$cli->disconnect;

} => 666);

UE::Loop->default->run;
