#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 15;
use HTTP::Request::Common;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/lib";
use T::Discovery;
#se T::RecordedBooks;

use_ok('WebService::ILS::RecordedBooks::Partner');
use_ok('WebService::ILS::RecordedBooks::PartnerPatron');
use_ok('WebService::ILS::RecordedBooks::Patron');

SKIP: {
    skip "Not testing RecordedBooks Patron API, WEBSERVICE_ILS_TEST_RECORDEDBOOKS or WEBSERVICE_ILS_TEST_RECORDEDBOOKS_PATRON not set", 4
      unless $ENV{WEBSERVICE_ILS_TEST_RECORDEDBOOKS} || $ENV{WEBSERVICE_ILS_TEST_RECORDEDBOOKS_PATRON};

    my $rb_domain = $ENV{RECORDEDBOOKS_TEST_DOMAIN}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_DOMAIN not set");
    my $rb_secret = $ENV{RECORDEDBOOKS_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_CLIENT_SECRET not set");
    my $rb_library_id = $ENV{RECORDEDBOOKS_TEST_LIBRARY_ID}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_LIBRARY_ID not set");
    my $rb_user_id = $ENV{RECORDEDBOOKS_TEST_USER_ID} || $ENV{RECORDEDBOOKS_TEST_USER_EMAIL}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_USER_ID or RECORDEDBOOKS_TEST_USER_EMAIL not set");
    my $rb_password = $ENV{RECORDEDBOOKS_TEST_USER_PASSWORD}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_USER_PASSWORD not set");

    my $rb = WebService::ILS::RecordedBooks::Patron->new({
        client_secret => $rb_secret,
        library_id => $rb_library_id,
        user_id => $rb_user_id,
        password => $rb_password,
        domain => $rb_domain,
    });

#   $rb->user_agent->add_handler( response_done => sub {
#       my($response, $ua, $h) = @_;
#       diag(join "\n", $response->request->as_string, $response->as_string);
#   } );

    clear($rb) if $ENV{RECORDEDBOOKS_TEST_CLEAR};

    test_search("Patron", $rb);

    test_circ("Patron", $rb);
}

SKIP: {
    skip "Not testing RecordedBooks Partner API, WEBSERVICE_ILS_TEST_RECORDEDBOOKS or WEBSERVICE_ILS_TEST_RECORDEDBOOKS_PARTNER not set", 8
      unless $ENV{WEBSERVICE_ILS_TEST_RECORDEDBOOKS} || $ENV{WEBSERVICE_ILS_TEST_RECORDEDBOOKS_PARTNER};

    my $rb_domain = $ENV{RECORDEDBOOKS_TEST_DOMAIN}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_DOMAIN not set");
    my $rb_secret = $ENV{RECORDEDBOOKS_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_CLIENT_SECRET not set");
    my $rb_library_id = $ENV{RECORDEDBOOKS_TEST_LIBRARY_ID}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_LIBRARY_ID not set");
    my $rb_user_id = $ENV{RECORDEDBOOKS_TEST_USER_BARCODE} || $ENV{RECORDEDBOOKS_TEST_USER_EMAIL}
        or BAIL_OUT("Env RECORDEDBOOKS_TEST_USER_BARCODE or RECORDEDBOOKS_TEST_USER_EMAIL not set");

    my $rb = WebService::ILS::RecordedBooks::Partner->new({
        client_secret => $rb_secret,
        library_id => $rb_library_id,
        domain => $rb_domain,
    });

#   $rb->user_agent->add_handler( response_done => sub {
#       my($response, $ua, $h) = @_;
#       diag(join "\n", $response->request->as_string, $response->as_string);
#   } );

    ok($rb->native_libraries_search('wood'), "Suggestive search");

    test_search("Partner", $rb);

    my $patron_id = $rb->patron_id( $rb_user_id );
    ok( $patron_id, "patron_id()");
    BAIL_OUT("No patron $rb_user_id, cannot test circulation") unless $patron_id;

    clear($rb, $patron_id) if $ENV{RECORDEDBOOKS_TEST_CLEAR};

    test_circ("Partner", $rb, $patron_id);

    $rb = WebService::ILS::RecordedBooks::PartnerPatron->new({
        client_secret => $rb_secret,
        library_id => $rb_library_id,
        user_id => $rb_user_id,
        domain => $rb_domain,
    });

    test_circ("PartnerPatron", $rb);
}

sub test_circ {
    my ($module, $rb, $patron_id) = @_;

    my $init_checkouts = $rb->checkouts($patron_id);
    my $init_holds = $rb->holds($patron_id);

    my ($items, $random_page) = T::Discovery::search_all_random_page( $rb );
    BAIL_OUT("No items in search results, cannot test circulation") unless $items && @$items;

    subtest "Place hold $module" => sub {
        my $item;
        while ($items) {
            $item = pick_unused_item([@{ $init_checkouts->{items} }, @{ $init_holds->{items} }], $items);
            last if $item;
            diag( Dumper($init_checkouts, $init_holds, $items) );
            ($items, $random_page) = T::Discovery::search_all_random_page( $rb, $random_page + 1 );
        }
        BAIL_OUT("Cannot find appropriate item to place hold") unless $item;

        test_place_hold($rb, $patron_id, $init_holds, $item);
    };

    subtest "Checkout $module" => sub {
        my $item;
        while ($items) {
            $item = pick_unused_item([@{ $init_checkouts->{items} }, @{ $init_holds->{items} }], $items);
            last if $item;
            diag( Dumper($init_checkouts, $init_holds, $items) );
            ($items, $random_page) = T::Discovery::search_all_random_page( $rb, $random_page + 1 );
        }
        BAIL_OUT("Cannot find appropriate item to checkout") unless $item;

        test_checkout($rb, $patron_id, $init_checkouts, $item);
    };
}

sub test_place_hold {
    my ($rb, $patron_id, $init_holds, $item) = @_;

    my $isbn = $item->{isbn};
    my $hold = $patron_id
        ? $rb->place_hold($patron_id, $isbn)
        : $rb->place_hold($isbn)
    ;
    my $hold_isbn = $hold ? $hold->{isbn} : undef;
    my $ok = ok($hold_isbn && $hold_isbn eq $isbn && $hold->{total} == $init_holds->{total} + 1, "Place hold")
      or diag(Dumper($patron_id, $init_holds, $item, $hold));

    SKIP: {
        skip "Cannot place hold", 1 unless $ok;

        my $same_hold = $patron_id
            ? $rb->place_hold($patron_id, $isbn)
            : $rb->place_hold($isbn)
        ;
        ok( $same_hold->{isbn} eq $hold_isbn, "Place same hold")
          or diag(Dumper($patron_id, $same_hold, $hold));

        $ok = $patron_id
            ? $rb->remove_hold($patron_id, $isbn)
            : $rb->remove_hold($isbn)
        ;
        ok( $ok, "Remove hold" );

        $ok = $patron_id
            ? $rb->remove_hold($patron_id, $isbn)
            : $rb->remove_hold($isbn)
        ;
        ok( $ok, "Remove hold again");
    }
}

sub test_checkout {
    my ($rb, $patron_id, $init_checkouts, $item) = @_;

    my $isbn = $item->{isbn};
    my $checkout = $patron_id
        ? $rb->checkout($patron_id, $isbn)
        : $rb->checkout($isbn)
    ;
    my $checkout_isbn = $checkout ? $checkout->{isbn} : undef;
    my $ok = ok($checkout_isbn && $checkout_isbn eq $isbn && $checkout->{total} == $init_checkouts->{total} + 1, "Checkout")
      or diag(Dumper($patron_id, $init_checkouts, $item, $checkout));

    SKIP: {
        skip "Cannot checkout", 1 unless $ok;

        my $same_checkout = $patron_id
            ? $rb->checkout($patron_id, $isbn)
            : $rb->checkout($isbn)
        ;
        ok(
            $same_checkout->{isbn} eq $checkout->{isbn} &&
            $same_checkout->{expires} eq $checkout->{expires},
            "Same checkout"
        ) or diag(Dumper($patron_id, $same_checkout, $checkout));

        my $renewal = $patron_id
            ? $rb->renew($patron_id, $isbn)
            : $rb->renew($isbn)
        ;
        ok(
            $renewal->{isbn} eq $checkout->{isbn} &&
            $renewal->{expires} ge $checkout->{expires},
            "Renewal"
        ) or diag(Dumper($patron_id, $renewal, $checkout));

        # Nothing to test really
        #test_download_url($rb, $renewal);

        $ok = $patron_id
            ? $rb->return($patron_id, $isbn)
            : $rb->return($isbn)
        ;
        ok( $ok, "Return" );

        $ok = $patron_id
            ? $rb->return($patron_id, $isbn)
            : $rb->return($isbn)
        ;
        ok( $ok, "Return again" );
    }
}

sub test_download_url  {
    my ($rb, $item) = @_;

    #my $download_url = $item->{url};
    foreach (@{ $item->{files} }) {
        my $download_url = $_->{url}
          or die "No url: ".Dumper($item);
        my $data = $rb->get_response($download_url);
        $download_url = $data->{url};
        my $filename = $_->{filename} || "aa.whatever";
        my $req = HTTP::Request::Common::GET($download_url);
        my $resp = $rb->user_agent->request($req, $filename);
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
    my ($rb, $patron_id) = @_;

    my $holds = $rb->holds($patron_id);
    my $items = $holds->{items};
    $rb->remove_hold($patron_id, $_->{isbn}) foreach @$items;
    diag("Removed ".scalar(@$items)." holds");
}

sub test_search {
    my ($module, $rb) = @_;

    subtest "Search $module" => sub {
        my $res = $rb->named_query_search("most-popular", "ebook");
        my $item = $res && $res->{items} ? $res->{items}[0] : undef;
        ok($item, "named_query_search()");
        SKIP: {
            skip "No search results", 3 unless $item;
            ok($item->{url}, "item url")
              or diag(Dumper($item));
            SKIP: {
                skip "No item url", 1 unless $item->{url};
                my $req = HTTP::Request::Common::GET($item->{url});
                my $resp = $rb->user_agent->request($req);
                ok($resp->code == 200, "Item url")
                  or diag("$item->{url}\n".$resp->as_string);
            }
            my $metadata = $rb->item_metadata($item->{isbn});
            ok($metadata && $metadata->{title}, "item_metadata()")
              or diag(Dumper($metadata));
        }
    };

    SKIP: {
        skip "Facets stopped working", 1;
    }
    return;

    subtest "Facets $module" => sub {
        my $facets = $rb->facets;
        ok($facets && keys %$facets, "Facets");

        my @genre_facets = @{ $facets->{genre} }[0..1];
        my @audience_facets = @{ $facets->{audience} }[0..1];
        my %facet_search;
        $facet_search{genre} = \@genre_facets if @genre_facets;
        $facet_search{audience} = \@audience_facets if @audience_facets;

        SKIP: {
            skip "No facets to search on", 1 unless keys %facet_search;

            my $results = $rb->facet_search(\%facet_search);
            ok($results, "facet_search(() hashref");

            $results = $rb->facet_search([@genre_facets, @audience_facets]);
            ok($results, "facet_search(() arrayref");

            $results = $rb->facet_search($genre_facets[0] || $audience_facets[0]);
            ok($results, "facet_search(() single facet");
        }
    }
}

