
use strict;
use Test::Simple tests => 11;

use Tie::PureDB;

ok(1);

my $final = 'fina.db';

my $p = Tie::PureDB::Write->new("${final}.index", "${final}.data", $final)
    or die "EEEK [$final]: $!" ;

ok($p);

ok(2);

my %ha = (
    foo => 'bar',
    PodMaster => 'PodMaster',
    perlmonks => 'http://perlmonks.org',
    PerlMonks => 'http://www.perlmonks.org',
    vroom => 'vroom',
    diotalevi => 'diotalevi',
    tye => 'tye',
);

for my $k ( keys %ha ){
    ok(
        $p->add( $k => $ha{$k} ),
        "adding $k => $ha{$k}"
    );
}


ok( !
    defined( undef($p)),
    "not defined \$p"
);


