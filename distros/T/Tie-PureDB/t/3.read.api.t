
use strict;
use Test::Simple tests => 33;
use Tie::PureDB;

ok(1);

my $final = 'fina.db';

my $p = Tie::PureDB::Read->new( $final)
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
    my @ll = $p->find( $k );
    my $val = $p->read( @ll );
    ok( @ll, "found $k at @ll");
    ok( $val eq $ha{$k} , "read it, and it matches \$ha{\$k}" );

    @ll = $p->puredb_find( $k );
    $val = $p->puredb_read( @ll );
    ok( @ll, "found $k at @ll");
    ok( $val eq $ha{$k} , "read it, and it matches \$ha{\$k}" );
}


ok( $p->getsize == $p->puredb_getsize, "successfully retrieved size");

ok( !
    defined( undef($p)),
    "not defined \$p"
);
