use Test::More;
use Test::Deep;
use lib lib;
use Data::Dumper;

plan qw/no_plan/;

use True::Truth;

{
    my $a = { a => 1, c => 3, d => { i => 2 }, r => {} };
    my $b = { b => 2, a => 100, d => { l => 4 } };
    my $c = True::Truth::merge $a, $b;
    ok($c);
    cmp_deeply( $c,
        { a => 100, b => 2, c => 3, d => { i => 2, l => 4 }, r => {} } );
    print Dumper $c;
}

{
    my $a = { s => { st => { a => 'b' } } };
    my $b = { d => { rr => { n => '1.2.3.4', t => 'A' } } };
    my $c = { d => { rr => { n => '1.2.3.5', t => 'A' }, y => 'n' } };
    my $d = True::Truth::merge $a, $b;
    $d = True::Truth::merge $d, $c;
    ok($d);
    cmp_deeply(
        $d,
        {
            d => { rr => { n => '1.2.3.5', t => 'A' }, y => 'n' },
            s => { st => { a => 'b' } }
        }
    );
    print Dumper $d;
}
{
    my $a = { s => { st => { a => 'b' } } };
    my $b = { d => { rr => { n => '1.2.3.4', t => 'A' } } };
    my $c = { d => { rr => { n => '1.2.3.5', t => 'A' }, y => 'n' } };
    my $d = True::Truth::merge $a, $c;
    $d = True::Truth::merge $d, $b;
    ok($d);
    cmp_deeply(
        $d,
        {
            d => { rr => { n => '1.2.3.4', t => 'A' }, y => 'n' },
            s => { st => { a => 'b' } }
        }
    );
    print Dumper $d;
}
{
    my $a = {
        domain => 'norbu09.org',
        status => 'active',
        owner  => 'lenz'
    };
    my $b = { dns => { rr => { 'norbu09.org' => '1.2.3.4', type => 'A' }, } };
    my $c = {
        dns => {
            rr     => { 'norbu09.org' => '1.2.3.5', type => 'A' },
            _truth => 'pending'
        }
    };
    my $d = True::Truth::merge $a, $b;
    $d = True::Truth::merge $d, $c;
    ok($d);
    cmp_deeply(
        $d,
        {
            owner  => 'lenz',
            domain => 'norbu09.org',
            dns    => {
                rr     => { 'norbu09.org' => '1.2.3.5', type => 'A' },
                _truth => 'pending'
            },
            status => 'active'
        }
    );
    print Dumper $d;
}
