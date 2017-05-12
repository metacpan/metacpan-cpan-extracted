#!perl -T

use Test::More;
use Test::Deep;
use WWW::Namecheap::API;

plan skip_all => "No API credentials defined" unless $ENV{TEST_APIUSER};

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => $ENV{TEST_APIUSER},
    ApiKey => $ENV{TEST_APIKEY},
    DefaultIp => $ENV{TEST_APIIP} || '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my $domains = $api->domain->list;
isa_ok($domains, 'ARRAY');

my $tests = 2;

my %cleanslate = (
    EmailType => 'FWD',
    Hosts => [],
);

my @scenarios = (
    {
        DomainName => 'wwwnamecheapapi37272.com',
        EmailType => 'FWD',
        Hosts => [
            {
                Name => '@',
                Type => 'A',
                Address => '172.16.76.54',
            },
            {
                Name => '@',
                Type => 'AAAA',
                Address => '2001:db8:0:dead:beef:42::1',
                TTL => 3600,
            },
            {
                Name => 'www',
                Type => 'CNAME',
                Address => 'wwwnamecheapapi37272.com.',
            },
        ],
    },
    {
        DomainName => 'wwwnamecheapapi28897.com',
        EmailType => 'MX',
        Hosts => [
            {
                Name => '@',
                Type => 'URL301',
                Address => 'http://www.wwwnamecheapapi28897.com/',
                TTL => 1800, # value appears to be ignored for type=URL301
            },
            {
                Name => 'www',
                Type => 'A',
                Address => '10.42.42.42',
                TTL => 60,
            },
            {
                Name => '@',
                Type => 'MX',
                Address => 'mail.example.com.',
                MXPref => 4,
            },
            {
                Name => '@',
                Type => 'MX',
                Address => 'mail2.example.com.',
                MXPref => 42,
            },
        ],
    },
    {
        DomainName => 'wwwnamecheapapi50602.com',
        EmailType => 'MXE',
        Hosts => [
            {
                Name => '@',
                Type => 'AAAA',
                Address => '2001:DB8:0:dead::beef',
                TTL => 14400,
            },
            {
                Name => 'mail',
                Type => 'MXE',
                Address => '192.168.222.123',
            },
        ],
    },
    {
        DomainName => 'wwwnamecheapapi38381.com',
        EmailType => 'FWD',
        Hosts => [
            {
                Name => '@',
                Type => 'A',
                Address => '127.0.0.1',
            },
        ],
    },
);

foreach my $scenario (@scenarios) {
    my $setresult = $api->dns->sethosts($scenario);
    is($setresult->{Domain}, $scenario->{DomainName});
    is($setresult->{IsSuccess}, 'true');
    
    my $getresult = $api->dns->gethosts(DomainName => $scenario->{DomainName});
    is($getresult->{Domain}, $scenario->{DomainName});
    is($getresult->{IsUsingOurDNS}, 'true');
    
    # Deep bag comparison of results
    cmp_deeply($getresult->{Host}, bag(map { superhashof($_) } @{$scenario->{Hosts}}))
        || diag explain $getresult;
    
    # Reset to a clean slate so our next test run has something to change
    my $cleanresult = $api->dns->sethosts(DomainName => $scenario->{DomainName}, %cleanslate);
    is($cleanresult->{Domain}, $scenario->{DomainName});
    is($setresult->{IsSuccess}, 'true');
    
    $tests += 7;
}
    
done_testing($tests);
