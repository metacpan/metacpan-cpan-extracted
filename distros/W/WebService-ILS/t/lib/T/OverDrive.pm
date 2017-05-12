package T::OverDrive;

use Modern::Perl;

use Test::More;
use Data::Dumper;

use T::Discovery;

my @ITEM_FIELDS = qw( author media subtitle publisher rating popularity );
sub search {
    my ($od) = @_;

    T::Discovery::search($od, \@ITEM_FIELDS);

    my $query = T::Discovery::search_query();
    my $resp = $od->search({query => $query, no_details => 1});
    ok( exists $resp->{total}, "Search results ($query)")
        or diag(Dumper($resp));
    my $items;
    SKIP: {
        skip "No search results", 1 unless $resp->{total};

        $items = $resp->{items};
        my $item = $items->[0];
        my $id = $item->{id}
            or BAIL_OUT("No item id in search results \n".Dumper($resp));

        ok( $item->{title}, "Search result item title ($query)")
            or diag(Dumper($item));

        my $ok_fields = 1;
        $ok_fields &&= exists( $item->{$_} ) foreach qw(subtitle media);
        ok( $ok_fields, "Search result item fields ($query)")
            or diag(Dumper($item));

        my $metadata = $od->item_metadata($id);
        ok( defined $metadata->{title}, "Item metadata")
            or diag(Dumper($metadata));
    }
}

sub native_search {
    my ($od) = @_;

    my $query = T::Discovery::search_query();
    my $resp = $od->native_search({q => $query});
    ok( exists $resp->{totalItems}, "Native search results ($query)")
        or diag("native_search: ".Dumper($resp));
    my $items;
    SKIP: {
        skip "No native search results", 1 unless $resp->{totalItems};

        $items = $resp->{products};
        my $item = $resp->{products}[0];
        my $id = $item->{id};
        ok ($id, "Item id in native search results")
            or diag(Dumper($resp));

        my $availability = $od->native_item_availability($item);
        ok( defined $availability->{available}, "Native item availability")
            or diag(Dumper($availability));

        my $metadata = $od->native_item_metadata($item);
        ok( defined $metadata->{title}, "Native item metadata")
            or diag(Dumper($metadata));

        my $multipage = $resp->{links}{next};
        SKIP: {
            skip "No multiple pages", 1 unless $multipage;

            $resp = $od->native_search_next($resp);
            ok( $resp->{offset} > 0, "Native search results page 2")
                or diag(Dumper($resp));

            $resp = $od->native_search_prev($resp);
            ok( $resp->{offset} == 0, "Native search results page 1")
                or diag(Dumper($resp));
        }

        $resp = $od->native_search_last($resp);
        ok( $multipage ? $resp->{offset} > 0 : $resp->{offset} == 0 , "Native search results last page")
            or diag(Dumper($resp));

        $resp = $od->native_search_first($resp);
        ok( $resp->{offset} == 0, "Native search results first page")
            or diag(Dumper($resp));
    }

    return $items;
}

sub patron {
    my ($od) = @_;

    my $patron = $od->patron;
    my ($patron_id, $hold_limit, $checkout_limit, $active);
    if ($patron) {
        $patron_id = $patron->{id};
        $hold_limit = $patron->{hold_limit};
        $checkout_limit = $patron->{checkout_limit};
    }
    ok($patron_id && defined($hold_limit) && defined($checkout_limit), "Patron")
      or diag(Dumper($patron));

    return $patron;
}
1;
