use Test2::V0 -target => 'Webservice::Judobase';

subtest url => sub {
    my $api = $CLASS->new();

    my $url = $api->contests->url;

    is $url, 'http://data.ijf.org/api/get_json',
        'Returns the correct default url';
};

done_testing;

