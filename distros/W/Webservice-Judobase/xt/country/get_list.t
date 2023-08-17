use Test2::V0 -target => 'Webservice::Judobase';

my $api  = $CLASS->new();
my $list = $api->country->get_list;

is scalar @$list, 244, 'Number of countries (Currently 244)';

is $list->[0],
    {
    id_country => 194,
    ioc        => 'AFG',
    name       => 'Afghanistan',
    },
    'First nation should be AFG';

is $list->[-1],
    {
    id_country => 154,
    ioc        => 'ZIM',
    name       => 'Zimbabwe',
    },
    'Last nation should be ZIM';

done_testing;
