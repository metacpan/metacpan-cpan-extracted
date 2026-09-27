use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use Encode qw(encode);
use WebDyne::Cloudflare::Hyperdrive::Transport;
use WebDyne::Cloudflare::Hyperdrive::Codec;
use WebDyne::Cloudflare::Hyperdrive::Blob;

my $codec='WebDyne::Cloudflare::Hyperdrive::Codec';
my $transport='WebDyne::Cloudflare::Hyperdrive::Transport';
my $scope_hr={ extensions => { 'webdyne.cloudflare.hyperdrive' => {
    version => 1, capability => 'request-token', bindings => ['DB'],
} } };
my $transport_or=$transport->new(scope => $scope_hr);
my $json_or=JSON::PP->new();
my $wire_hr;
my $response_hr={ version => 1, ok => JSON::PP::true, result => { connection => 'connection-token' } };
local $WebDyne::Cloudflare::Hyperdrive::Transport::HOST_CALL=sub {
    $wire_hr=$json_or->decode($_[0]);
    return $json_or->encode($response_hr);
};
is($transport_or->call('open')->get()->{'connection'}, 'connection-token', 'transport opens a logical connection');
is($wire_hr->{'capability'}, 'request-token', 'request capability supplied');
is($wire_hr->{'binding'}, 'DB', 'binding supplied');

my $params_ar=WebDyne::Cloudflare::Hyperdrive::Codec::parameters(undef,
    JSON::PP::false, '9007199254740993', '12345678901234567890.1234567890',
    encode('UTF-8', "日本🍷"), WebDyne::Cloudflare::Hyperdrive::Blob->new("\0\xff\x80"));
is_deeply($params_ar, [['null'], ['bool', JSON::PP::false], ['text', '9007199254740993'],
    ['text', '12345678901234567890.1234567890'], ['text', "日本🍷"], ['bytes', '00ff80']], 'explicit parameters preserve exact values');
foreach my $bad ({ arbitrary => 'object' }, ['array'], "nul\0text", "\xff") {
    eval { WebDyne::Cloudflare::Hyperdrive::Codec::parameters($bad) };
    ok($@, 'invalid parameter rejected');
}
eval { WebDyne::Cloudflare::Hyperdrive::Blob->new("🍷") };
like($@, qr/requires bytes/, 'wide blob rejected');

$response_hr->{'result'}={ columns => [map { { name => 'duplicate', oid => $_ } } (20, 1700, 17, 16, 114, 25, 1184)],
    rows => [[['text', '9007199254740993'], ['text', '12345678901234567890.1234567890'],
        ['bytes', '00ff80'], ['bool', JSON::PP::false], ['text', 'null'], ['null'],
        ['text', '2026-09-12 01:02:03.123456+09:30']]], count => 1, command => 'SELECT' };
my $result_hr=$transport_or->call('query', connection => 'connection-token', sql => 'select $1', params => $params_ar)->get();
is_deeply($wire_hr->{'params'}, $params_ar, 'transport does not reinterpret encoded parameters');
is_deeply($result_hr->{'rows'}[0], ['9007199254740993', '12345678901234567890.1234567890',
    "\0\xff\x80", JSON::PP::false, 'null', undef, '2026-09-12 01:02:03.123456+09:30'], 'exact decoded rows');
is(scalar(@{$result_hr->{'columns'}}), 7, 'duplicate column metadata preserved');

$response_hr={ version => 1, ok => JSON::PP::false, error => {
    name => 'DATABASE_ERROR', message => 'duplicate key', code => '23505', constraint => 'items_pkey' } };
eval { $transport_or->call('query', connection => 'connection-token', sql => 'select 1', params => [])->get() };
isa_ok($@, 'WebDyne::Cloudflare::Hyperdrive::Error');
is($@->code(), '23505', 'SQLSTATE retained');
is($@->details()->{'constraint'}, 'items_pkey', 'structured detail retained');
$response_hr->{'error'}={ code => 'CONNECTION_ERROR', message => 'connection failed', outcomeUnknown => JSON::PP::true };
eval { $transport_or->call('commit', connection => 'connection-token')->get() };
ok($@->outcome_unknown(), 'ambiguous commit retained');

foreach my $bad (['bytes', 'zz'], ['null', 1], ['bool', 0], ['special', 'bad'], ['number', 'NaN'], ['unknown', 1]) {
    eval { WebDyne::Cloudflare::Hyperdrive::Codec::cell($bad) };
    ok($@, 'malformed result cell rejected');
}
foreach my $bad ({}, { version => 99, ok => JSON::PP::true }, { version => 1, ok => 1 }) {
    $response_hr=$bad;
    eval { $transport_or->call('open')->get() };
    like($@, qr/Invalid Hyperdrive host response/, 'malformed envelope rejected');
}
eval { $transport_or->call('open', capability => 'other')->get() };
like($@, qr/Cannot override/, 'transport authority cannot be overridden');
eval { $transport->new(scope => $scope_hr, binding => 'PRIVATE') };
like($@, qr/unavailable/, 'unlisted binding rejected');
my $mysql_hr=WebDyne::Cloudflare::Hyperdrive::Codec::result({
    columns => [{ name => 'id', driver => 'mysql', type => 8 }],
    rows => [[['text', '9007199254740993']]], count => 1, command => 'SELECT' });
is($mysql_hr->{'rows'}[0][0], '9007199254740993', 'MySQL type metadata and exact bigint accepted');
foreach my $column_hr ({ name => 'x', type => 8 }, { name => 'x', driver => 'mysql', type => 'bad' }) {
    eval { WebDyne::Cloudflare::Hyperdrive::Codec::result({ columns => [$column_hr], rows => [] }) };
    like($@, qr/Invalid Hyperdrive column/, 'invalid MySQL metadata rejected');
}
my $mysql_error_or=WebDyne::Cloudflare::Hyperdrive::Error->new(code => 'ER_DUP_ENTRY', sqlstate => '23000', errno => 1062);
is($mysql_error_or->sqlstate(), '23000', 'MySQL SQLSTATE accessor');
is($mysql_error_or->errno(), 1062, 'MySQL error number accessor');
done_testing();
