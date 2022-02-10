use 5.012;
use UniEvent::HTTP;
use Net::SSLeay;

$0 = 'jw';
$SIG{PIPE} = 'IGNORE';

my $ctx = Net::SSLeay::CTX_new;
Net::SSLeay::CTX_use_certificate_file($ctx, 't/cert/ca.pem', &Net::SSLeay::FILETYPE_PEM) or sslerr();
Net::SSLeay::CTX_use_PrivateKey_file($ctx, 't/cert/ca.key', &Net::SSLeay::FILETYPE_PEM) or sslerr();

my $s = UniEvent::HTTP::Server->new({
        idle_timeout           => 2,
        max_headers_size       => 16384,
        max_body_size          => 1_000_000,
        tcp_nodelay            => 1,
        locations              => [{host => "*",port => 6669,ssl_ctx => $ctx}],
});
my $i = 0;
$s->request_callback(sub {
    my $request = shift;
    say "REQ ".(++$i);
    $request->respond({code => 404});
});

$s->run;
say "READY";
UE::Loop->default_loop->run;
