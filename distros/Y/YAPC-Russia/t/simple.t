use Test::More;
use Test::Exception;

use YAPC::Russia;

sub check_incorrect_usage_no_year {

    throws_ok(
        sub {
            my $yr = YAPC::Russia->new();
        },
        qr/No "year"/,
        'new() dies if no year is specified',
    );

}

sub check_incorrect_usage_unknown_year {

    throws_ok(
        sub {
            my $yr = YAPC::Russia->new(
                year => 1714,
            );
        },
        qr/Sorry, no data for year "1714"/,
        'new() dies if unknown year is specified',
    );

}

sub check_get_dates {
    my $yr = YAPC::Russia->new(
        year => 2014,
    );

    my @dates = map { $_->get_d() } $yr->get_dates();

    is_deeply(
        \@dates,
        [qw(2014-06-13 2014-06-14)],
        'get_dates() return correct dates for YAPC::Russia 2014',
    );
}

sub main {

    check_incorrect_usage_no_year();
    check_incorrect_usage_unknown_year();

    check_get_dates();

    done_testing();

}
main();
