#!perl

use utf8;
use FindBin;
require "$FindBin::Bin/Test/MyApp.pm";

use Test::More;
use Test::Mojo::WithRoles 'SubmitForm';
my $t = Test::Mojo::WithRoles->new;

my %form_one = (
    a => 'A',
    b => 'B',
    e => 'E',
    f => [ 'I', 'J' ],
    l => 'L',
    m => 'M',
    '$"bar' => 42,
    q{©☺♥} => 24,

    mult_a => [qw/A B/],
    mult_b => [qw/C D E/],
    mult_f => [qw/I J N/],
    mult_m => [qw/M Z/],
);

{ # Plain clicking
    $t->get_ok('/')->status_is(200)
        ->click_ok('form#one')->status_is(200)->json_is(\%form_one)

        ->get_ok('/')->click_ok('form#one [name=s]')
        ->json_is({ %form_one, s => 'S' })

        ->get_ok('/')->click_ok('form#one [name=p]')
        ->json_is({ %form_one, p => 'P' })

        ->get_ok('/')->click_ok('form#one [name=z]')
        ->json_is({ %form_one, 'z.x' => 1, 'z.y' => 1 })

        ->get_ok('/')->click_ok('form#two')
        ->json_is({})

        ->get_ok('/')->click_ok('form#two [name=q]')
        ->json_is({ q => 'Q' })

        ->get_ok('/')->click_ok('form#three')
        ->json_is({})

        ->get_ok('/')->click_ok('form#three [name=r]')
        ->json_is({ r => 'R' })

        ->get_ok('/')->click_ok('form#four')
        ->json_is({})

        ->get_ok('/')->click_ok('form#four [name=z]')
        ->json_is({ 'z.x' => 1, 'z.y' => 1 });

    ok ! eval { $t->get_ok('/')->click_ok('form#two [name=z]');},
        'Die when not matched a selector';
    like $@, qr/\QDid not find element matching selector form#two [name=z]\E/,
        'Error message is sane';

    $t->get_ok('/samepage')->status_is(200)
        ->click_ok('form#one')->status_is(200)->json_is({ a => A});
    $t->get_ok('/samepage')->status_is(200)
        ->click_ok('form#two')->status_is(200)->json_is({ a => A});
}

{ # Override form data
    $t->get_ok('/')->status_is(200)
        ->click_ok('form#one', {
            a => '42',
            f => [ 1..3 ],
            l => sub { my $r = shift; [ $r, 42 ] },
            e => sub { shift . 'offix'},
            '$"bar' => sub { 5 },
            '©☺♥' => sub { 55 },
            mult_m => [qw/FOO BAR/],
            mult_a => sub { my $r = shift; [ 1, 2, 3, @$r ] },
        })->status_is(200)->json_is({
            %form_one,
            a => '42',
            f => [ 1..3 ],
            l => [ 'L', 42],
            e => 'Eoffix',
            '$"bar' => 5,
            '©☺♥' => 55,
            mult_m => [qw/FOO BAR/],
            mult_a => [1, 2, 3, qw/A B/],
        })
}

{ # pass DOM objects
    $t->get_ok('/samepage');
    my $dom = $t->tx->res->dom->at('form#one');
    $t->click_ok($dom)->json_is({ a => 'A' });

    $t->get_ok('/');
    $dom = $t->tx->res->dom->at('form#two [name=q]');
    $t->click_ok($dom)->json_is({ q => 'Q' });

}

done_testing();

__END__

