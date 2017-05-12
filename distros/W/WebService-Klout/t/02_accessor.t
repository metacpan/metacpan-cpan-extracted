use strict;
use warnings;
use Test::More;
use WebService::Klout;

unless ($ENV{'KLOUT_API_KEY'}) {
    Test::More->import('skip_all' => 'no api key set, skipped.');
    exit;
}

my $klout = WebService::Klout->new;

my @users = qw(twitter twitpic);

$klout->score(@users);

subtest 'status' => sub {
    like($klout->status, qr/^\d{3}$/);
};

subtest 'json' => sub {
    like($klout->json, qr/^{.+}$/);
};

subtest 'raw' => sub {
    my $raw = $klout->raw;
    isa_ok($raw, 'HASH');
    for (qw(status users)) {
        ok(exists $raw->{ $_ }, $_);
    }
};

subtest 'error' => sub {
    my $warnings;
    local $SIG{'__WARN__'} = sub { $warnings = shift };

    my $klout = WebService::Klout->new('api_key' => 'NO_EXISTS');
    $klout->score(@users);

    like($warnings, qr/^403 Developer Inactive/);
    is($klout->error, '403 Forbidden');
};

done_testing;
