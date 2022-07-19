use strict;
use warnings;

use Test::More;

use UID2::Client::Key;
use UID2::Client::KeyContainer;

my $key = UID2::Client::Key->new(
    id        => 1,
    site_id   => 2,
    created   => time - (60 * 60 * 24),
    activates => time - (60 * 60 * 24),
    expires   => time + (60 * 60 * 24),
    secret    => '',
);
isa_ok $key, 'UID2::Client::Key';
ok $key->is_active;

my $non_active_key = UID2::Client::Key->new(
    id        => 2,
    site_id   => 2,
    created   => time - (60 * 60 * 24),
    activates => time - (60 * 60 * 24),
    expires   => time - 1,
    secret    => '',
);
ok !$non_active_key->is_active;

my $keys = UID2::Client::KeyContainer->new($non_active_key);
isa_ok $keys, 'UID2::Client::KeyContainer';
ok !$keys->is_valid;
$keys = UID2::Client::KeyContainer->new($key, $non_active_key);
ok $keys->is_valid;

ok $keys->get(1);
ok !$keys->get(3);

is $keys->get_active_site_key(2)->id, 1;

done_testing;
