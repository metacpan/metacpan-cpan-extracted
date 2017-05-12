use Test::More tests => 18;
use WebService::Wedata;
use Data::Dumper;

my $my_api_key = 'YOUR_API_KEY';
my $now = time;
my $db_name = 'test_db_from_WebService::Wedata' . $now;
my $item_name = 'test_db_from_WebService::Wedata::Item' . $now;

my $wedata = WebService::Wedata->new($my_api_key);
my $database = $wedata->create_database(
    name => $db_name,
    required_keys => [qw/foo bar baz/],
    optional_keys => [qw/hoge fuga/],
    permit_other_keys => 1,
);


########################################
# get item
my $items = $database->get_items;
is(scalar(@$items), 0, 'no items');


########################################
# create
$item = $database->create_item(
    name => $item_name,
    data => {
        foo => 'foo_value',
        bar => 'bar_value',
        baz => 'baz_value',
    }
);

my $check_created_item = sub {
    my($item) = @_;
    check_item_by_name($item, {
        name => $item_name,
        data => {
            foo => 'foo_value',
            bar => 'bar_value',
            baz => 'baz_value',
        }
    });
};
$check_created_item->($item);

my $item_id;
$item_id = WebService::Wedata::Item::_id_from_resource_url($item->resource_url);

$item = $database->get_item(id => $item_id);
$check_created_item->($item);


########################################
# update
$item_id = WebService::Wedata::Item::_id_from_resource_url($item->resource_url);

$item = $database->update_item(
    id => $item_id,
    data => {
        foo => 'foo_up_value',
        bar => 'bar_up_value',
        baz => 'baz_up_value',
    }
);

my $check_updated_item = sub {
    my($item) = @_;
    check_item_by_id($item, {
        id => $item_id,
        data => {
            foo => 'foo_up_value',
            bar => 'bar_up_value',
            baz => 'baz_up_value',
        }
    });
};
$check_updated_item->($item);

$item = $database->get_item(id => $item_id);
$check_updated_item->($item);


########################################
# delete

$database->delete_item(id => $item_id);
eval { $item = $database->get_item(id => $item_id); };
like($@, '/Faild to get_item:404 Not Found/', "delete $item_name");


# CLEAN UP
$wedata->delete_database(name => $db_name);


sub check_item_by_id {
    my($item, $expect) = @_;
    $expect->{resource_url} = "http://wedata.net/items/" . $expect->{id};
    check_item($item, $expect);
}

sub check_item_by_name {
    my($item, $expect) = @_;
    is($item->{name}, $expect->{name}, 'name');
    check_item($item, $expect);
}

sub check_item {
    my($item, $expect) = @_;
    while (my($k, $v) = each(%{ $item->{data} })) {
        is($v, $expect->{data}->{$k}, 'data[' . $k . ']');
    }
    if (defined $expect->{resource_url}) {
        is($item->{resource_url}, $expect->{resource_url}, 'resource_url');
    }
}
