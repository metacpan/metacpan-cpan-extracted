use strict;
use warnings;

use Test::Fatal qw{exception};
use FindBin::libs;
use URI::Shortener;
use Capture::Tiny qw{capture_merged};

use Test::More tests => 3;

subtest 'happy path' => sub {
    my $s = URI::Shortener->new(
        domain => 'ACGT',
        prefix => 'https://go.mydomain.test/short',
        dbname => ':memory:',
        seed   => 1337,
        length => 10,
    );
    my $uri   = 'https://mydomain.test/somePath';
    my $short = $s->shorten($uri);
    is( $short,               'https://go.mydomain.test/short/CTTACCGGTC', "I do this...for da shorteez.  Especially URIs" );
    $short = $s->shorten($uri);
    is( $short,               'https://go.mydomain.test/short/CTTACCGGTC', "caching works" );
    is( $s->lengthen($short), $uri,                                "Lengthens, Hardens, Girthens & Fully Pleasures your URI" );
    $s->prune_before( time() + 10 );
    is( $s->lengthen($short), undef, "Pruning works" );

};

subtest 'Sovereign is he who tests his exceptions' => sub {
    my %bad;

    like( exception { URI::Shortener->new(%bad) }, qr/prefix/i, "You've just been pre-fixated" );
    $bad{prefix} = 'jumbo://hugs';
    like( exception { URI::Shortener->new(%bad) }, qr/dbname/i, "Get in the DB shinji" );
    $bad{dbname} = ':memory:';
    like( exception { URI::Shortener->new(%bad) }, qr/seed/i, "My seed hath slain the chess dragon" );
};

# pathological case
subtest 'going to the circle 8 track' => sub {
    my $s = URI::Shortener->new(
        domain => 'A',
        prefix => 'bar',
        dbname => ':memory:',
        seed   => 1337,
        length => 1,
    );
    is( $s->shorten('foo'), 'bar/A', "Works fine, right?");
    like( exception { capture_merged { $s->shorten('hug') } }, qr/too many failures/i, "Stack smashing guard encountered");
};
