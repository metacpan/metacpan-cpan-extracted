use strict;
use warnings;
use Test::More;
use Unblock::HTTP::_AltSvc;

{
    package TestAltSvcResponse;
    sub new {
        my ($class, @values) = @_;
        bless { values => \@values, age => undef }, $class;
    }
    sub header_values {
        my ($self, $name) = @_;
        return $name eq 'alt-svc' ? $self->{values} : [];
    }
    sub header {
        my ($self, $name) = @_;
        return $self->{age} if $name eq 'age';
        return;
    }
}

my $now = 1000;
my $cache = Unblock::HTTP::_AltSvc->new(
    clock => sub { $now },
    max_age => 400,
    max_entries => 2,
);
my $origin = 'https|example.test|443';
ok(!$cache->lookup($origin), 'no speculative discovery before advertisement');
$cache->observe($origin, TestAltSvcResponse->new('h3=":7443"; ma=120'));
is($cache->lookup($origin)->{port}, 7443, 'same-host alternative port cached');
$now += 119;
ok($cache->lookup($origin), 'entry remains fresh until expiry');
$now += 1;
ok(!$cache->lookup($origin), 'entry expires at exact deadline');

$cache->observe($origin, TestAltSvcResponse->new('h3=":443"; ma=99999'));
$now += 399;
ok($cache->lookup($origin), 'configured max age bounds long advertisements');
$now++;
ok(!$cache->lookup($origin), 'cache cap expires oversized max-age');

my $res = TestAltSvcResponse->new('h2=":443", h3=":8443"; ma=300');
$res->{age} = '299';
$cache->observe($origin, $res);
ok($cache->lookup($origin), 'Age shortens freshness rather than cancelling an entry');
$now++;
ok(!$cache->lookup($origin), 'Age adjusted freshness expires');

$res = TestAltSvcResponse->new('h3=":7443"; ma=100');
$res->{age} = '120';
$cache->observe($origin, $res);
ok(!$cache->lookup($origin), 'response older than advertisement rejected');

$cache->observe($origin, TestAltSvcResponse->new('h3="other.test:9443"; ma=200'));
ok(!$cache->lookup($origin), 'cross-host alternative not accepted');

for my $bad (
    'h3=":0"', 'h3=":65536"', 'h3=":999999999"',
    'h3=":-1"', 'h3=":8443"; ma=abc',
    'h3=":8443"; ma=-1', 'h3=":8443"; ma=20; ma=30',
    'h3=":8443"; invalid', 'h3=":8443', 'h3=:8443',
    'h3=":8443"; ma="20"',
) {
    $cache->observe($origin, TestAltSvcResponse->new($bad));
    ok(!$cache->lookup($origin), "malformed header ignored: $bad");
}

$cache->observe($origin, TestAltSvcResponse->new(
    'h2=":443", h3=":9443"; ma=80; persist=1; extension="ok"',
));
is($cache->lookup($origin)->{port}, 9443,
    'unknown well-formed parameters ignored');
$cache->observe($origin, TestAltSvcResponse->new('h3=":7443"; ma=10'));
is($cache->lookup($origin)->{port}, 7443, 'new advertisement replaces prior entry');
$cache->observe($origin, TestAltSvcResponse->new('clear'));
ok(!$cache->lookup($origin), 'clear removes existing entry');
$cache->observe($origin, TestAltSvcResponse->new('h3=":7443", clear'));
ok(!$cache->lookup($origin), 'clear wins over simultaneous alternative');

$cache->observe($origin, TestAltSvcResponse->new('h3=":7443"'));
is($cache->lookup($origin)->{port}, 7443, '24 hour default accepted within cap');
$cache->invalidate($origin);
ok(!$cache->lookup($origin), 'explicit failure invalidates alternative');

$cache->observe('a', TestAltSvcResponse->new('h3=":111"'));
$now++;
$cache->observe('b', TestAltSvcResponse->new('h3=":222"'));
$now++;
$cache->observe('c', TestAltSvcResponse->new('h3=":333"'));
ok(!$cache->lookup('a'), 'oldest entry evicted at capacity');
ok($cache->lookup('b'), 'newer entry remains');
ok($cache->lookup('c'), 'new entry remains');

done_testing;
