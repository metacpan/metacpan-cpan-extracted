use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::Astro7Timer;

my $weather = Weather::Astro7Timer->new();

subtest 'Wrong input' => sub {
    like(dies {$weather->get()}, qr/product was not/, "Missing prod");
    like(
        dies {$weather->get(product => 'astro1')},
        qr/product not/,
        "Wrong prod"
    );
    like(
        dies {$weather->get(product => 'astro')},
        qr/lat between/,
        "Missing lat"
    );
    like(
        dies {$weather->get(product => 'astro', lat => 100)},
        qr/lat between/,
        "Invalid lat"
    );
    like(
        dies {$weather->get(product => 'astro', lat => 0)},
        qr/lon between/,
        "Missing lon"
    );
    like(
        dies {$weather->get(product => 'astro', lat => 0, lon => 190)},
        qr/lon between/,
        "Invalid lon"
    );
};

my $mock = Test2::Mock->new(
    class    => 'LWP::UserAgent',
    override => [
        get => sub {return HTTP::Response->new(401, 'ERROR', undef, '{}')},
    ],
);

subtest 'Error response' => sub {
    ok(lives {$weather = Weather::Astro7Timer->new(error => 'die')}, "New object");
    like(dies {$weather->get(lat => 0, lon => 0, product => 'civil')},
        qr/401 ERROR/, "LWP Error response");
};

done_testing;
