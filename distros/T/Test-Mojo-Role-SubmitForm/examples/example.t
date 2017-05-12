#!perl

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
}

{ # Override form data
    $t->get_ok('/')->status_is(200)
        ->click_ok('form#one', {
            a => '42',
            f => [ 1..3 ],
            l => sub { my $r = shift; [ @$r, 42 ] },
            z => sub { shift . 'offix'}
        })->status_is(200)->json_is({
            %form_one,
            a => '42',
            f => [ 1..3 ],
            l => [ 'L', 42],
            z => 'Zoffix',
        })
}

done_testing();

__END__

