use Test2::V0 -target => 'Webservice::Judobase';

subtest url => sub {
    my $api = $CLASS->new();

    my $url = $api->url;

    is $url, 'http://data.judobase.org/api/',
        'Returns the correct default url';
};

done_testing;

