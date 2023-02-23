use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::WeatherKit;

my (%opt, $weather);

subtest 'Wrong input' => sub {
    foreach (qw/1 1234567890/) {
        like(
            dies { Weather::WeatherKit->new(%opt) },
            qr/10 digit team_id expected./,
            "Incorrect team_id"
        );
        $opt{team_id} = $_;
    }

    foreach (qw/service_id key_id/) {
        like(
            dies { Weather::WeatherKit->new(%opt) },
            qr/$_ required./,
            "No $_ passed"
        );
        $opt{$_} = 1;
    }

    like(
        dies { Weather::WeatherKit->new(%opt) },
        qr/key or key_file required./,
        "No key/key_file"
    );

    $opt{key_file} = 'DoesNotExist';
    like(
        dies { Weather::WeatherKit->new(%opt) },
        qr/Can't open file/,
        "Not valid file"
    );
    $opt{key} = 1;

    ok(lives {$weather = Weather::WeatherKit->new(%opt)}, "Does not die");

    like(dies { $weather->get() }, qr/lat between/, "Missing lat");
    like(dies { $weather->get(lat=>100) }, qr/lat between/, "Invalid lat");
    like(dies { $weather->get(lat=>0) }, qr/lon between/, "Missing lon");
    like(dies { $weather->get(lat=>0, lon=>190) }, qr/lon between/, "Invalid lon");
};

subtest 'JWT creation error' => sub {
    like(dies {$weather->get(lat => 0, lon => 0)}, qr/JWT/, "Invalid JWT data");
};


my $mock = Test2::Mock->new(
    class => 'LWP::UserAgent',
    track => 1,
    override => [
        get => sub { return HTTP::Response->new(401, 'ERROR', undef, '{}') },
    ],
);

subtest 'Error response' => sub {
    $opt{key} = '-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgYirTZSx+5O8Y6tlG
cka6W6btJiocdrdolfcukSoTEk+hRANCAAQkvPNu7Pa1GcsWU4v7ptNfqCJVq8Cx
zo0MUVPQgwJ3aJtNM1QMOQUayCrRwfklg+D/rFSUwEUqtZh7fJDiFqz3
-----END PRIVATE KEY-----';
    ok(lives {$weather = Weather::WeatherKit->new(%opt)}, "New object");
    ok(lives {$weather->jwt}, "JWT created correctly");
    like(dies { $weather->get(lat=>0, lon=>0) }, qr/401 ERROR/, "LWP Error response");  
};

done_testing;
