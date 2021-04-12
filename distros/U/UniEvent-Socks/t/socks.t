use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Catch;

chdir 'clib';
catch_run('[socks]');
chdir '../';

my $tcp = new UniEvent::Tcp;

UniEvent::Socks::use_socks($tcp, "localhost", 1080);
UniEvent::Socks::use_socks($tcp, "socks5://localhost");
UniEvent::Socks::use_socks($tcp, URI::XS->new("socks5://localhost"));

$tcp->use_socks("localhost", 1080);
$tcp->use_socks("socks5://localhost");
$tcp->use_socks(URI::XS->new("socks5://localhost"));

done_testing();
