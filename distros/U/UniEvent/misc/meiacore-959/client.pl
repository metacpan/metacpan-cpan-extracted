use lib 'blib/lib', 'blib/arch';
use UniEvent;

$SIG{PIPE} = 'IGNORE';

my $sock = UE::Tcp->new;
$sock->connect("dev.crazypanda.ru", 6669);
$sock->use_ssl;
$sock->write("GET /chat HTTP/1.1");

UE::Loop->default_loop->run;
