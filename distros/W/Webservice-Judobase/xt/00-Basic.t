use Test2::V0 -target => 'Webservice::Judobase';

subtest status => sub {
    my $api = $CLASS->new();

    my $status = $api->status;

    is $status, 0, 'Returns the correct status';
};

done_testing;

