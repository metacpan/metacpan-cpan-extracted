use Test::More;
use Test::Deep;

use WebService::KvKAPI::BasicProfile;
use Test::Mock::One;

my $client = WebService::KvKAPI::BasicProfile->new(
    api_key => 'testsuite',
);

my $operation;
my %args;

use Sub::Override;
my $override = Sub::Override->new(
    'WebService::KvKAPI::BasicProfile::api_call' => sub {
        shift;
        $operation = shift;
        %args = @_;
        return { foo => 'bar' };
    }
);

my %cmds = (
    get_basic_profile => {
        operation => 'getBasisprofielByKvkNummer',
        geodata => 1,
    },
    get_owner => {
        operation => 'getEigenaar',
        geodata => 1,
    },
    get_main_location => {
        operation => 'getHoofdvestiging',
        geodata => 1,
    },
    get_locations => {
        operation => 'getVestigingen',
        geodata => 0,
    }
);

foreach (sort keys %cmds) {
    can_ok($client, $_);

    my $res = $client->$_(1234567);
    cmp_deeply($res, { foo => 'bar' }, "Got the results from the KvK API");
    is($operation, $cmds{$_}{operation}, ".. with the correct operation");
    cmp_deeply(\%args, { kvkNummer => '01234567' }, ".. and the correct arguments");

    if ($cmds{$_}{geodata}) {
        my $res = $client->$_(1234567, 1);

        cmp_deeply($res, { foo => 'bar' }, "Got the results from the KvK API");
        is($operation, $cmds{$_}{operation}, ".. with the correct operation");

        cmp_deeply(
            \%args,
            { kvkNummer => '01234567', geoData => 1 },
            ".. and the correct arguments including geoData"
        );

    }
}

done_testing;
