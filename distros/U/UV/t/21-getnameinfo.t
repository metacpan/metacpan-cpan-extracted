use v5.14;
use warnings;

use Socket qw( AF_INET NI_NUMERICHOST NI_NUMERICSERV SOCK_STREAM inet_aton pack_sockaddr_in );
use UV::Loop ();

use Test::More;

my $loop = UV::Loop->default;

my $cb_called;

# All-numerical lookup so should be nicely portable
my $req = $loop->getnameinfo(
    pack_sockaddr_in(5678, inet_aton("8.7.6.5")),
    NI_NUMERICHOST|NI_NUMERICSERV,

    sub {
        my ($status, $host, $service) = @_;
        $cb_called++;

        cmp_ok($status, '==', 0, '$status is zero') or
            diag "Got status = $status";
        is($host, "8.7.6.5", '$host in callback');
        is($service, "5678", '$service in callback');
    },
);
isa_ok($req, 'UV::Req');
$loop->run;
ok($cb_called, 'getnameinfo callback was called');

done_testing();
