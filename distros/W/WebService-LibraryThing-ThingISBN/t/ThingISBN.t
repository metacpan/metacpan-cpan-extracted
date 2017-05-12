#!perl

use Test::More tests => 10;
use WebService::LibraryThing::ThingISBN qw( thing_isbn_list );

# test lookups

my @test_isbns = qw( 0441172717 0340839937 0881036366 0399128964 0736683291 );

my $requests_start_time = time;
foreach my $isbn (@test_isbns) {
    my @isbns = thing_isbn_list($isbn);

    # we're looking for one of the other ISBNs
    my @isbns_to_match_list = grep { $_ ne $isbn } @test_isbns;
    my %isbns_to_match_hash = map { $_ => 1 } @isbns_to_match_list;

    ok( ( grep { $isbns_to_match_hash{$_} } @isbns ),
        "thing_isbn_list functional interface works: $isbn" );
}
my $requests_end_time = time;

my $requests_time_taken = $requests_end_time - $requests_start_time;
cmp_ok( $requests_time_taken, '>=', scalar(@test_isbns),
    'API requests are hardcoded to wait at least 1 second between requests' );

# test errors

foreach my $arg_group ( { args => ['isbn'], name => 'empty' },
                        {  args => [ 'isbn', '' ],
                           name => 'empty string'
                        },
                        {  args => [ 'isbn', 'Foo' ],
                           name => 'invalid text'
                        },
                        {  args => [ 'isbn', '199' ],
                           name => 'invalid num'
                        },
    ) {
    is_deeply( [ thing_isbn_list( @{ $arg_group->{args} } ) ],
          [],
          "thing_isbn_list returns empty list on error: $arg_group->{name}" );
}

# Local Variables:
# mode: perltidy
# End:
