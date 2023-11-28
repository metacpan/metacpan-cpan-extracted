use Test2::V0;

use WebService::Readwise;

die 'You need to set WEBSERVICE_READWISE_TOKEN'
    unless $ENV{WEBSERVICE_READWISE_TOKEN};

my $sr = WebService::Readwise->new;

my $result = $sr->export;

is $result,
    {
    count          => E(),
    nextPageCursor => E(),
    results        => E(),
    },
    'Result returned correct keys';

is $result->{results}[0],
    {
    asin            => E(),
    author          => E(),
    book_tags       => E(),
    category        => E(),
    cover_image_url => E(),
    document_note   => E(),
    highlights      => E(),
    readable_title  => E(),
    readwise_url    => E(),
    source          => E(),
    source_url      => E(),
    title           => E(),
    unique_url      => E(),
    user_book_id    => E(),
    },
    'First record has correct structure';

is $result->{results}[0]{highlights}[0],
    {
    book_id        => E(),
    color          => E(),
    created_at     => E(),
    end_location   => E(),
    external_id    => E(),
    highlighted_at => E(),
    id             => E(),
    is_discard     => E(),
    is_favorite    => E(),
    location       => E(),
    location_type  => E(),
    note           => E(),
    readwise_url   => E(),
    tags           => E(),
    text           => E(),
    updated_at     => E(),
    url            => E(),
    },
    '1st highlight in 1st result is correct format';


# The following test relies on there being more than one page of results
# which is true of original author but may not be correct for others
my $result_page_2 = $sr->export(
    pageCursor => $result->{nextPageCursor},
);

is $result_page_2, {
    count => E(),
    nextPageCursor => undef,
    results => E(),
}, 'Second page of results structure is as expected';


done_testing;
