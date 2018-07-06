use Test2::V0 -target => 'Webservice::Judobase';

subtest url => sub {
    my $api = $CLASS->new();

    my $url = $api->url;

    is $url, 'http://data.judobase.org/api/',
        'Returns the correct default url';
};

subtest status => sub {
    my $api = $CLASS->new();

    my $status = $api->status;

    is $status, 0, 'Returns the correct status';
};

subtest competitor_best_results => sub {
    my $api = $CLASS->new();

    # Best results for Teddy Riner (id 385)
    my $results = $api->competitor->best_results(id => 385);

    is $results->[0]{competition}, 'Grand Slam Paris 2013', 'Returns results OK';
};

done_testing;

