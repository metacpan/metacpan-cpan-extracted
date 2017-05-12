use Test::More;
use XRI::Resolution::Lite;

subtest 'resolver is http://xri.net/' => sub {
    my $r = XRI::Resolution::Lite->new;
    ok($r, 'Create instance using http://xri.net/');
    my $xrds = $r->resolve('=zigorou');
    is($xrds->documentElement->nodeName, 'XRDS', 'Root node is XRDS element');
    done_testing;
};

done_testing;

diag('Testing result format application/xrds+xml');
