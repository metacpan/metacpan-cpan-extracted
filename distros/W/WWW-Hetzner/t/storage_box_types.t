use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

sub attempt {
    my ($code) = @_;
    my ($result, $error);
    my $ok = eval { $result = $code->(); 1 };
    $error = $@ unless $ok;
    return ($result, $error // '');
}

sub storage {
    my (%routes) = @_;
    my ($client, $error) = attempt(sub { mock_storage(%routes) });
    ok($client, 'Storage client is available') or return;
    return $client;
}

subtest 'Storage Box Types list, list_all, get, and get_by_name preserve pagination' => sub {
    my $first = load_fixture('storage_box_types_list');
    $first->{meta}{pagination}{per_page} = 1;
    $first->{meta}{pagination}{next_page} = 2;
    $first->{meta}{pagination}{last_page} = 2;
    $first->{meta}{pagination}{total_entries} = 2;
    my $second = load_fixture('storage_box_types_list');
    $second->{storage_box_types}[0]{id} = 2;
    $second->{storage_box_types}[0]{name} = 'bx30';
    $second->{meta}{pagination} = {
        page => 2, per_page => 1, previous_page => 1, next_page => undef, last_page => 2, total_entries => 2,
    };
    my @seen;
    my $storage = storage(
        'GET /storage_box_types' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$opts{params}, $opts{request}];
            my $page = ($opts{params} // {})->{page} // 1;
            return $page == 1 ? $first : $second;
        },
        'GET /storage_box_types/1' => sub { load_fixture('storage_box_types_get') },
    ) or return;
    my $types = $storage->storage_box_types;
    isa_ok($types, 'WWW::Hetzner::Storage::API::StorageBoxTypes');

    my $single = $types->list(per_page => 1);
    is_deeply([map { $_->id } @$single], [1], 'list remains a one-page call');

    @seen = ();
    my %params = (name => 'bx', per_page => 1);
    my $all = $types->list_all(%params);
    is_deeply([map { $_->id } @$all], [1, 2], 'list_all follows documented type pagination');
    is_deeply([map { $_->[0] } @seen], [
        {name => 'bx', per_page => '1'},
        {name => 'bx', per_page => '1', page => '2'},
    ], 'type list_all preserves name and per_page over pages');
    isa_ok($seen[0][1], 'WWW::Hetzner::HTTPRequest', 'type list raw request is available');
    is_deeply(\%params, {name => 'bx', per_page => 1}, 'type list_all does not mutate caller params');

    my $type = $types->get(1);
    isa_ok($type, 'WWW::Hetzner::Storage::StorageBoxType');
    is($type->id, 1, 'type id');
    is($type->snapshot_limit, undef, 'nullable snapshot_limit remains undef');
    is($type->automatic_snapshot_limit, undef, 'nullable automatic_snapshot_limit remains undef');
    is($type->deprecation, undef, 'nullable deprecation remains undef');
    is_deeply($type->data->{prices}[0]{price_monthly}, {gross => '3.8080', net => '3.2000'}, 'type raw pricing data remains available');

    @seen = ();
    my $named = $types->get_by_name('bx30');
    isa_ok($named, 'WWW::Hetzner::Storage::StorageBoxType', 'get_by_name returns a type');
    is($named->id, 2, 'get_by_name searches later pages');
    is_deeply([map { $_->[0] } @seen], [
        {name => 'bx30'},
        {name => 'bx30', page => '2'},
    ], 'get_by_name keeps its name query over pagination');
};

done_testing;
