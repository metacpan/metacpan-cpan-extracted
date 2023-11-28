use Test2::V0;

use WebService::Readwise;

die 'You need to set WEBSERVICE_READWISE_TOKEN'
    unless $ENV{WEBSERVICE_READWISE_TOKEN};

my $sr = WebService::Readwise->new;

my $result = $sr->highlights();

is $result,
    {
    count    => E(),
    next     => E(),
    previous => E(),
    results  => E(),
    }, 'Result returned correct keys';

is $result->{results}[0],
    {
    book_id        => E(),
    color          => E(),
    highlighted_at => E(),
    id             => E(),
    location       => E(),
    location_type  => E(),
    note           => E(),
    tags           => E(),
    text           => E(),
    updated        => E(),
    url            => E(),
    }, 'First highlight has correct keys';

done_testing;
