use strict;
use warnings;
use Test::More;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
plan tests => 27;
use WWW::MobileCarrierJP::DoCoMo::HTMLVersion;

my $vermap = WWW::MobileCarrierJP::DoCoMo::HTMLVersion->scrape;
is ref($vermap), 'ARRAY', 'this API returns arrayref';
cmp_ok scalar(@$vermap), '>', 4, 'docomo has many html versions';
cmp_ok scalar(grep !/^\d\.\d/, map { $_->{version} } @$vermap), '==', 0, 'all keys are version number';
cmp_ok scalar(grep !/[a-zA-Z0-9]+/, map { @{$_->{models}} } @$vermap), '==', 0;

for my $version (qw/1.0 2.0 3.0 4.0 5.0 6.0 7.0 7.1 7.2/) {
    ok scalar(grep { $_->{version} eq $version } @$vermap), "$version exists in the data.";
}

{
    my $prev = -1;
    for my $v (@$vermap) {
        cmp_ok $v->{version}, '>', $prev;
        $prev = $v->{version};
    }
}

do {
    my @expected = (
        '1.0' => [qw/
            D501i F501i N501i P501i
        /],
        '2.0' => [qw/
            D502i F502i N502i P502i NM502i SO502i F502it N502it SO502iWM SH821i N821i P821i
            D209i ER209i F209i KO209i N209i P209i P209iS R209i P651ps R691i F210i N210i P210i
            KO210i F671i
        /],
        '3.0' => [qw/
            D210i SO210i F503i F503iS P503i P503iS N503i N503iS SO503i SO503iS D503i D503iS F211i
            D211i N211i N211iS P211i P211iS SO211i R211i SH251i SH251iS R692i N2001 N2002 P2002
            D2101V P2101V SH2101V T2101V
        /],
        '4.0' => [qw/
            D504i F504i F504iS N504i N504iS SO504i P504i P504iS D251i D251iS F251i N251i N251iS P251iS
            F671iS F212i SO212i F661i F672i SO213i SO213iS SO213iWR F2051 N2051 P2102V F2102V N2102V
            N2701 NM850iG NM705i NM706i
        /],
        '5.0' => [qw/
            D505i SO505i SH505i N505i F505i P505i D505iS P505iS N505iS SO505iS SH505iS
            F505iGPS D252i SH252i P252i N252i P252iS D506i F506i N506i P506iC SH506iC SO506iC
            N506iS SO506i SO506iS N506iSII P506iCII D253i N253i P253i D253iWM P253iS P213i
            F900i N900i P900i SH900i F900iT P900iV N900iS D900i F900iC N900iL N900iG F880iES
            SH901iC F901iC N901iC D901i P901i SH901iS F901iS D901iS P901iS N901iS P901iTV F700i
            SH700i N700i P700i F700iS SH700iS SA700iS SH851i P851i F881iES D701i N701i P701iD
            D701iWM N701iECO SA800i L600i N600i L601i M702iS M702iG L602i
        /],
        # ... list of 6.0 is not stable at 2008-05 :(
    );

    while (my ($version, $expected) = splice(@expected, 0, 2)) {
        my ($got,) = map { $_->{models} } grep { $_->{version} eq $version } @$vermap;
        is_deeply $got, $expected, "CHECK $version";
    }
};


