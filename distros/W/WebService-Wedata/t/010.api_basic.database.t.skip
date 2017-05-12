use Test::More tests => 36;
use WebService::Wedata;
use Data::Dumper;


my $my_api_key = 'YOUR_API_KEY';
my $wedata = WebService::Wedata->new($my_api_key);


########################################
# get all
my $databases = $wedata->get_databases;
ok(scalar(@$databases) > 0, 'got some databases');

my $database;
my $db_name = 'test_db_from_WebService::Wedata' . time;

TODO: {
    local $TODO = "NEED MORE THAN 50 DATABASES TO CHECK 'page' PARAMATER";
}


########################################
# create
$database = $wedata->create_database(
    name => $db_name,
    description => 'description about created database',
    required_keys => [qw/foo bar baz/],
    optional_keys => [qw/hoge fuga/],
    permit_other_keys => 1,
);

my $check_created_db = sub {             # tests = 5 + 3 + 2
    my($database) = @_;
    check_database($database, {
        name => $db_name,
        description => 'description about created database',
        required_keys => [qw/foo bar baz/],
        optional_keys => [qw/hoge fuga/],
        permit_other_keys => 1,
        resource_url => "http://wedata.net/databases/$db_name",
    });
};
$check_created_db->($database);

$database = $wedata->get_database($db_name);
$check_created_db->($database);


########################################
# update
$database = $wedata->update_database(
    name => $db_name,
    description => 'description about updated database',
    required_keys => [qw/foo_up bar_up baz_up/],
    optional_keys => [qw/hoge_up fuga_up/],
    permit_other_keys => '',
);
my $check_updated_db = sub {             # tests = 5 + 3 + 2
    my($database) = @_;
    check_database($database, {
        name => $db_name,
        description => 'description about updated database',
        required_keys => [qw/foo_up bar_up baz_up/],
        optional_keys => [qw/hoge_up fuga_up/],
        permit_other_keys => 0,
        resource_url => "http://wedata.net/databases/$db_name",
    });
};
$check_updated_db->($database);

$database = $wedata->get_database($db_name);
$check_updated_db->($database);


########################################
# delete
$wedata->delete_database(name => $db_name);

eval {$database = $wedata->get_database($db_name); };
like($@, '/Faild to get_database:404 Not Found/', "delete $db_name");




# tests = 5 + req_keys_num + opt_keys_num
sub check_database {
    my($database, $expect) = @_;
    is($database->{name}, $expect->{name}, 'database name');
    my $i;
    for ($i = 0; $i < scalar(@{$database->{required_keys}}); $i++) {
        is($database->{required_keys}->[$i],
           $expect->{required_keys}->[$i],
           "required_keys $i");
    }
    for ($i = 0; $i < scalar(@{$database->{optional_keys}}); $i++) {
        is($database->{optional_keys}->[$i],
           $expect->{optional_keys}->[$i],
           "optional_keys $i");
    }
    is(scalar(@{$database->{items}}), 0, 'no items');

    is($database->permit_other_keys, $expect->{permit_other_keys},
       join(' ',
            'permit_other_keys',
            $database->permit_other_keys,
            $expect->{permit_other_keys})
    );
    is($database->description, $expect->{description}, 'description');
    is($database->resource_url, $expect->{resource_url}, 'resource_url');
}
