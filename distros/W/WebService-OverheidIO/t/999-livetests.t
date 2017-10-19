use strict;
use warnings;

use Test::Deep;
use Test::More;

use Sub::Override;
use WebService::OverheidIO::BAG;
use WebService::OverheidIO::KvK;

if (!$ENV{OVERHEIDIO_API_KEY}) {
    plan skip_all => "Live tests need an OverheidIO developer key: export OVERHEIDIO_API_KEY=verysecret";
}

{
    note "Live test OverheidIO::BAG";

    my $oio = WebService::OverheidIO::BAG->new(
        key => $ENV{OVERHEIDIO_API_KEY}
    );

    my $expected_data = {
        openbareruimtenaam   => "Muiderstraat",
        huisnummer           => "1",
        huisnummertoevoeging => "",
        huisletter           => "",
        woonplaatsnaam       => "Amsterdam",
        gemeentenaam         => "Amsterdam",
        postcode             => "1011PZ",
        provincienaam        => "Noord-Holland",
        url                  => "1011pz-muiderstraat-1",
        _links => { self => { href => "/api/bag/1011pz-muiderstraat-1" }, },
    };

    {
        my $answer        = $oio->search("Muiderstraat*");
        my $address       = $answer->{_embedded}{adres}[0];

        my @keys = sort keys(%{$address});
        my @expected_keys = sort keys(%{$expected_data});

        if(!cmp_deeply(\@keys, \@expected_keys, "Address search results looks sane")) {
            diag explain \@keys;
        }
    }

    {
        my $answer = $oio->search("Muiderstraat",
            filter => {
                huisnummer => 1,
                postcode   => '1011PZ'
            }
        );
        my $address = $answer->{_embedded}{adres}[0];

        is($answer->{totalItemCount}, 1, "One address found");
        cmp_deeply($address, $expected_data, "Address search result matches expected data");
    }

    {
        my $answer = $oio->search("Muiderstraat",
            filter => {
                huisnummer => 1,
                postcode   => '1095EW'
            }
        );
        is($answer->{totalItemCount}, 0, "No address found, filter denies");
    }

    {
        my $answer = $oio->search("Muiderstraa");
        is($answer->{totalItemCount}, 0, "No address found, exact search");
    }

    {
        my $answer = $oio->search(
            undef,
            filter => {
                huisnummer => "1",
                postcode   => "1011PZ",
            }
        );
        if (is($answer->{totalItemCount}, 1, "One address found by huisnummer/postcode filters")) {
            my $address       = $answer->{_embedded}{adres}[0];
            is_deeply($address, $expected_data,
                "Address search result matches expected data");
        }
    }

}

{
    my $oio = WebService::OverheidIO::KvK->new(
        key => $ENV{OVERHEIDIO_API_KEY}
    );

    {
        my $answer        = $oio->search("Euronet Com*");
        my $company       = $answer->{_embedded}{rechtspersoon}[0];
        my $expected_data = {
            subdossiernummer     => "0000",
            handelsnaam          => "Euronet Communications B.V.",
            vestigingsnummer     => "15999696",
            dossiernummer        => "33301540",
            huisnummer           => "21",
            huisnummertoevoeging => "",
            plaats               => "Hilversum",
            postcode             => "1211RH",
            straat               => "Wilhelminastraat",
            _links => { self => { href => "/api/kvk/33301540/0000" }, },
        };

        is_deeply($company, $expected_data,
            "EuroNet Communications found via wild card search");
    }

    {
        my $answer
            = $oio->search("Euronet Com*", filters => { huisnummer => 21 });
        is($answer->{totalItemCount}, 1, "One company found");
    }

    {
        my $answer
            = $oio->search("Euronet Com*", filter => { huisnummer => 22 });
        is($answer->{totalItemCount}, 0, "No company found, filter denies");
    }

    {
        my $answer = $oio->search("Euronet Com");
        is($answer->{totalItemCount}, 0, "No company found, exact search");
    }
    my $mintlab_data = {
        subdossiernummer     => "0000",
        handelsnaam          => "Mintlab B.V.",
        vestigingsnummer     => "21881022",
        dossiernummer        => "51902672",
        huisnummer           => "90",
        huisnummertoevoeging => "",
        plaats               => "Amsterdam-Duivendrecht",
        postcode             => "1114AD",
        straat               => "H.J.E. Wenckebachweg",
        _links => { self => { href => "/api/kvk/51902672/0000" }, },
    };

    {
        my $answer = $oio->search(
            "51902672",
            filter => {
                dossiernummer    => "51902672",
                vestigingsnummer => "21881022",
            }
        );
        my $company       = $answer->{_embedded}{rechtspersoon}[0];
        is_deeply($company, $mintlab_data,
            "Mintlab found with default filters");
    }

    {
        my $answer = $oio->search(
            undef,
            filter => {
                dossiernummer    => "51902672",
                vestigingsnummer => "21881022",
            }
        );
        my $company = $answer->{_embedded}{rechtspersoon}[0];

        is_deeply($company, $mintlab_data,
            "Mintlab found by dossier/vestigingsnummer filters");
    }
}

done_testing;
