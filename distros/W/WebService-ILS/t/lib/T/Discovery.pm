package T::Discovery;

use Modern::Perl;

use Test::More;
use Data::Dumper;

#use Data::Random::WordList;
#use constant WORDLIST => $ENV{ILS_TEST_WORDLIST} || '/usr/share/dict/words';

sub search_query {
#   my $wl = new Data::Random::WordList(
#       wordlist => WORDLIST
#   );
#   while (1) {
#       my $w = ($wl->get_words)[0];
#       next unless $w =~ m/^[a-z]+$/o;

#       return $w;
#   }
    return 'art';
}

use constant DEFAULT_ITEM_FIELDS => [ qw(author media) ];
sub search {
    my ($ils, $item_fields) = @_;

    my $query = search_query();
    my $resp = $ils->search({query => $query});
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
        $ok_fields &&= exists( $item->{$_} ) foreach @{ $item_fields || DEFAULT_ITEM_FIELDS };
        ok( $ok_fields, "Search result item fields ($query)")
            or diag(Dumper($item));

        my $availability = $ils->item_availability($id);
        ok( defined $availability->{available}, "Item availability")
            or diag(Dumper($availability));

        my $pages = $resp->{pages};
        SKIP: {
            skip "No multiple pages", 1 unless $pages > 1;

            $resp = $ils->search(
                {query => $query, page => 2, page_size => $resp->{page_size}}
            );
            is( $resp->{page}, 2, "Search results page 2")
                or diag(Dumper($resp));
        }
    }

    return $items;
}

sub search_all_random_page {
    my ($ils, $floor) = @_;
    $floor ||= 1;

    my $resp = $ils->search;
    my $page = 1;
    if (my $pages = $resp->{pages}) {
        if ($floor > $pages) {
            diag("Min page requested: $floor; resultset has only $pages pages\n".Dumper($resp));
            return;
        }
        if ($floor < $pages) {
            $page = $floor + int(rand($pages - $floor)); # deliberately skew to lower page
            $resp = $ils->search( {page => $page, page_size => $resp->{page_size}} ) if $page > 1;
        }
    }
    else {
        diag("No 'pages' in Full collection search results\n".Dumper($resp));
        return if $floor > 1;
    }
    my $items = $resp->{items};
    return wantarray ? ($items, $page) : $items;
}

1;
