
use strict;
use Test::Simple tests => 14;
use Tie::PureDB;

$|=1;

ok(1);

my $final = 'fina.db';
my %db;
my $p = tie %db, 'Tie::PureDB::Write', "${final}.index", "${final}.data", $final;

ok($p);

ok( $p eq tied(%db), "tied");

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
    ok( $p->STORE($k,$ha{$k}), "STORE $k => $ha{$k}" );
}

ok( tied(%db), "\%db still tied" );

{
    my $warning = "";
    local $SIG{__WARN__} = sub { $warning = "@_"; };
    untie %db;

    ok( $warning =~ /untie attempted/ , "cannot untie \%db whilst \$p is defined" );
}

ok( !
    defined( undef($p)),
    "not defined \$p"
);

ok( untie %db, "successfully untie, cause \$p is undef");
