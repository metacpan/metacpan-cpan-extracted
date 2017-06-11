#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 15;
use HTTP::Request::Common;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/lib";
use T::Discovery;
#se T::OneClickDigital;

use_ok('WebService::ILS::OneClickDigital::Partner');
use_ok('WebService::ILS::OneClickDigital::PartnerPatron');
use_ok('WebService::ILS::OneClickDigital::Patron');

SKIP: {
    skip "Not testing OneClickDigital Patron API, WEBSERVICE_ILS_TEST_ONECLICKDIGITAL or WEBSERVICE_ILS_TEST_ONECLICKDIGITAL_PATRON not set", 4
      unless $ENV{WEBSERVICE_ILS_TEST_ONECLICKDIGITAL} || $ENV{WEBSERVICE_ILS_TEST_ONECLICKDIGITAL_PATRON};

    my $ocd_domain = $ENV{ONECLICKDIGITAL_TEST_DOMAIN}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_DOMAIN not set");
    my $ocd_secret = $ENV{ONECLICKDIGITAL_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_CLIENT_SECRET not set");
    my $ocd_library_id = $ENV{ONECLICKDIGITAL_TEST_LIBRARY_ID}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_LIBRARY_ID not set");
    my $ocd_user_id = $ENV{ONECLICKDIGITAL_TEST_USER_ID} || $ENV{ONECLICKDIGITAL_TEST_USER_EMAIL}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_USER_ID or ONECLICKDIGITAL_TEST_USER_EMAIL not set");
    my $ocd_password = $ENV{ONECLICKDIGITAL_TEST_USER_PASSWORD}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_USER_PASSWORD not set");

    my $ocd = WebService::ILS::OneClickDigital::Patron->new({
        client_secret => $ocd_secret,
        library_id => $ocd_library_id,
        user_id => $ocd_user_id,
        password => $ocd_password,
        domain => $ocd_domain,
    });

#   $ocd->user_agent->add_handler( response_done => sub {
#       my($response, $ua, $h) = @_;
#       diag(join "\n", $response->request->as_string, $response->as_string);
#   } );

    clear($ocd) if $ENV{ONECLICKDIGITAL_TEST_CLEAR};

    test_search("Patron", $ocd);

    test_circ("Patron", $ocd);
}

SKIP: {
    skip "Not testing OneClickDigital Partner API, WEBSERVICE_ILS_TEST_ONECLICKDIGITAL or WEBSERVICE_ILS_TEST_ONECLICKDIGITAL_PARTNER not set", 8
      unless $ENV{WEBSERVICE_ILS_TEST_ONECLICKDIGITAL} || $ENV{WEBSERVICE_ILS_TEST_ONECLICKDIGITAL_PARTNER};

    my $ocd_domain = $ENV{ONECLICKDIGITAL_TEST_DOMAIN}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_DOMAIN not set");
    my $ocd_secret = $ENV{ONECLICKDIGITAL_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_CLIENT_SECRET not set");
    my $ocd_library_id = $ENV{ONECLICKDIGITAL_TEST_LIBRARY_ID}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_LIBRARY_ID not set");
    my $ocd_user_id = $ENV{ONECLICKDIGITAL_TEST_USER_BARCODE} || $ENV{ONECLICKDIGITAL_TEST_USER_EMAIL}
        or BAIL_OUT("Env ONECLICKDIGITAL_TEST_USER_BARCODE or ONECLICKDIGITAL_TEST_USER_EMAIL not set");

    my $ocd = WebService::ILS::OneClickDigital::Partner->new({
        client_secret => $ocd_secret,
        library_id => $ocd_library_id,
        domain => $ocd_domain,
    });

#   $ocd->user_agent->add_handler( response_done => sub {
#       my($response, $ua, $h) = @_;
#       diag(join "\n", $response->request->as_string, $response->as_string);
#   } );

    my $patron_id = $ocd->patron_id( $ocd_user_id );
    ok( $patron_id, "patron_id()");
    BAIL_OUT("No patron $ocd_user_id, cannot test circulation") unless $patron_id;

    clear($ocd, $patron_id) if $ENV{ONECLICKDIGITAL_TEST_CLEAR};

    ok($ocd->native_libraries_search('wood'), "Suggestive search");

    test_search("Partner", $ocd);

    test_circ("Partner", $ocd, $patron_id);

    $ocd = WebService::ILS::OneClickDigital::PartnerPatron->new({
        client_secret => $ocd_secret,
        library_id => $ocd_library_id,
        user_id => $ocd_user_id,
        domain => $ocd_domain,
    });

    test_circ("PartnerPatron", $ocd);
}

sub test_circ {
    my ($module, $ocd, $patron_id) = @_;

    my $init_checkouts = $ocd->checkouts($patron_id);
    my $init_holds = $ocd->holds($patron_id);

    my ($items, $random_page) = T::Discovery::search_all_random_page( $ocd );
    BAIL_OUT("No items in search results, cannot test circulation") unless $items && @$items;

    subtest "Place hold $module" => sub {
        my $item;
        while ($items) {
            $item = pick_unused_item([@{ $init_checkouts->{items} }, @{ $init_holds->{items} }], $items);
            last if $item;
            diag( Dumper($init_checkouts, $init_holds, $items) );
            ($items, $random_page) = T::Discovery::search_all_random_page( $ocd, $random_page + 1 );
        }
        BAIL_OUT("Cannot find appropriate item to place hold") unless $item;

        test_place_hold($ocd, $patron_id, $init_holds, $item);
    };

    subtest "Checkout $module" => sub {
        my $item;
        while ($items) {
            $item = pick_unused_item([@{ $init_checkouts->{items} }, @{ $init_holds->{items} }], $items);
            last if $item;
            diag( Dumper($init_checkouts, $init_holds, $items) );
            ($items, $random_page) = T::Discovery::search_all_random_page( $ocd, $random_page + 1 );
        }
        BAIL_OUT("Cannot find appropriate item to checkout") unless $item;

        test_checkout($ocd, $patron_id, $init_checkouts, $item);
    };
}

sub test_place_hold {
    my ($ocd, $patron_id, $init_holds, $item) = @_;

    my $isbn = $item->{isbn};
    my $hold = $patron_id
        ? $ocd->place_hold($patron_id, $isbn)
        : $ocd->place_hold($isbn)
    ;
    my $hold_isbn = $hold ? $hold->{isbn} : undef;
    my $ok = ok($hold_isbn && $hold_isbn eq $isbn && $hold->{total} == $init_holds->{total} + 1, "Place hold")
      or diag(Dumper($patron_id, $init_holds, $item, $hold));

    SKIP: {
        skip "Cannot place hold", 1 unless $ok;

        my $same_hold = $patron_id
            ? $ocd->place_hold($patron_id, $isbn)
            : $ocd->place_hold($isbn)
        ;
        ok( $same_hold->{isbn} eq $hold_isbn, "Place same hold")
          or diag(Dumper($patron_id, $same_hold, $hold));

        $ok = $patron_id
            ? $ocd->remove_hold($patron_id, $isbn)
            : $ocd->remove_hold($isbn)
        ;
        ok( $ok, "Remove hold" );

        $ok = $patron_id
            ? $ocd->remove_hold($patron_id, $isbn)
            : $ocd->remove_hold($isbn)
        ;
        ok( $ok, "Remove hold again");
    }
}

sub test_checkout {
    my ($ocd, $patron_id, $init_checkouts, $item) = @_;

    my $isbn = $item->{isbn};
    my $checkout = $patron_id
        ? $ocd->checkout($patron_id, $isbn)
        : $ocd->checkout($isbn)
    ;
    my $checkout_isbn = $checkout ? $checkout->{isbn} : undef;
    my $ok = ok($checkout_isbn && $checkout_isbn eq $isbn && $checkout->{total} == $init_checkouts->{total} + 1, "Checkout")
      or diag(Dumper($patron_id, $init_checkouts, $item, $checkout));

    SKIP: {
        skip "Cannot checkout", 1 unless $ok;

        my $same_checkout = $patron_id
            ? $ocd->checkout($patron_id, $isbn)
            : $ocd->checkout($isbn)
        ;
        ok(
            $same_checkout->{isbn} eq $checkout->{isbn} &&
            $same_checkout->{expires} eq $checkout->{expires},
            "Same checkout"
        ) or diag(Dumper($patron_id, $same_checkout, $checkout));

        my $renewal = $patron_id
            ? $ocd->renew($patron_id, $isbn)
            : $ocd->renew($isbn)
        ;
        ok(
            $renewal->{isbn} eq $checkout->{isbn} &&
            $renewal->{expires} ge $checkout->{expires},
            "Renewal"
        ) or diag(Dumper($patron_id, $renewal, $checkout));

        # Nothing to test really
        #test_download_url($ocd, $renewal);

        $ok = $patron_id
            ? $ocd->return($patron_id, $isbn)
            : $ocd->return($isbn)
        ;
        ok( $ok, "Return" );

        $ok = $patron_id
            ? $ocd->return($patron_id, $isbn)
            : $ocd->return($isbn)
        ;
        ok( $ok, "Return again" );
    }
}

sub test_download_url  {
    my ($ocd, $item) = @_;

    #my $download_url = $item->{url};
    foreach (@{ $item->{files} }) {
        my $download_url = $_->{url}
          or die "No url: ".Dumper($item);
        my $data = $ocd->get_response($download_url);
        $download_url = $data->{url};
        my $filename = $_->{filename} || "aa.whatever";
        my $req = HTTP::Request::Common::GET($download_url);
        my $resp = $ocd->user_agent->request($req, $filename);
        ok($resp->code == 200, "Download url")
          or diag("$download_url\n".$resp->as_string);;
    }
}

sub pick_unused_item {
    my ($used_items, $pool_items) = @_;

    POOL_ITEMS_LOOP:
    foreach my $pi (@$pool_items) {
        if ($used_items) {
            my $isbn = $pi->{isbn};
            foreach (@$used_items) {
                next POOL_ITEMS_LOOP if $_->{isbn} eq $isbn;
            }
        }
        return $pi;
    }
    return;
}

sub clear {
    my ($ocd, $patron_id) = @_;

    my $holds = $ocd->holds($patron_id);
    my $items = $holds->{items};
    $ocd->remove_hold($patron_id, $_->{isbn}) foreach @$items;
    diag("Removed ".scalar(@$items)." holds");
}

sub test_search {
    my ($module, $ocd) = @_;

    subtest "Search $module" => sub {
        my $res = $ocd->named_query_search("most-popular", "ebook");
        my $item = $res && $res->{items} ? $res->{items}[0] : undef;
        ok($item, "named_query_search()");
        SKIP: {
            skip "No search results", 3 unless $item;
            ok($item->{url}, "item url")
              or diag(Dumper($item));
            SKIP: {
                skip "No item url", 1 unless $item->{url};
                my $req = HTTP::Request::Common::GET($item->{url});
                my $resp = $ocd->user_agent->request($req);
                ok($resp->code == 200, "Item url")
                  or diag("$item->{url}\n".$resp->as_string);
            }
            my $metadata = $ocd->item_metadata($item->{isbn});
            ok($metadata && $metadata->{title}, "item_metadata()")
              or diag(Dumper($metadata));
        }
    };

    SKIP: {
        skip "Facets stopped working", 1;
    }
    return;

    subtest "Facets $module" => sub {
        my $facets = $ocd->facets;
        ok($facets && keys %$facets, "Facets");

        my @genre_facets = @{ $facets->{genre} }[0..1];
        my @audience_facets = @{ $facets->{audience} }[0..1];
        my %facet_search;
        $facet_search{genre} = \@genre_facets if @genre_facets;
        $facet_search{audience} = \@audience_facets if @audience_facets;

        SKIP: {
            skip "No facets to search on", 1 unless keys %facet_search;

            my $results = $ocd->facet_search(\%facet_search);
            ok($results, "facet_search(() hashref");

            $results = $ocd->facet_search([@genre_facets, @audience_facets]);
            ok($results, "facet_search(() arrayref");

            $results = $ocd->facet_search($genre_facets[0] || $audience_facets[0]);
            ok($results, "facet_search(() single facet");
        }
    }
}

