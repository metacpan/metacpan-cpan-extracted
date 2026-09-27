use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::KV;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();
my @request;
local $WebDyne::Cloudflare::KV::HOST_CALL=sub {
    my ($wire)=@_;
    my $request_hr=$json_or->decode($wire);
    push @request, $request_hr;
    my $result_ref=$request_hr->{'operation'} eq 'get'
        ? ($request_hr->{'type'} eq 'bytes' ? { type => 'bytes', base64 => 'AAH/' }
            : $request_hr->{'type'} eq 'json' ? { answer => 42 } : 'WebDyne')
        : $request_hr->{'operation'} eq 'get_with_metadata'
            ? { value => 'WebDyne', metadata => { source => 'test' } }
            : $request_hr->{'operation'} eq 'list'
                ? { keys => [{ name => 'webdyne:key' }], list_complete => JSON::PP::true() }
                : JSON::PP::true();
    return $json_or->encode({ ok => JSON::PP::true(), result => $result_ref });
};

my $scope_hr={
    extensions => {
        'webdyne.cloudflare.kv' => {
            version => 1, capability => 'kv-capability', bindings => ['CACHE'],
        },
    },
};
my $kv_or=WebDyne::Cloudflare::KV->new(scope => $scope_hr, binding => 'CACHE');
is($kv_or->binding(), 'CACHE', 'KV binding retained');
is($kv_or->get('greeting')->get(), 'WebDyne', 'text value returned');
is($kv_or->get('binary', type => 'bytes')->get(), "\0\1\xff", 'byte value decoded');
is_deeply($kv_or->get('json', type => 'json')->get(), { answer => 42 }, 'JSON value returned');
is_deeply($kv_or->get_with_metadata('greeting')->get(), {
    value => 'WebDyne', metadata => { source => 'test' },
}, 'value and metadata returned');

ok($kv_or->put('binary', WebDyne::Cloudflare::KV->blob("\0\1\xff"),
    expiration_ttl => 60, metadata => { source => 'test' })->get(), 'blob put succeeds');
is_deeply($request[-1]{'value'}, { type => 'bytes', base64 => 'AAH/' }, 'blob put encoded');
is($request[-1]{'expiration_ttl'}, 60, 'expiration TTL preserved');
$kv_or->put('unicode', "\xcf\x80")->get();
is($request[-1]{'value'}, 'π', 'unflagged UTF-8 text becomes Unicode');
$kv_or->put_json('json', { answer => 42 })->get();
is_deeply($json_or->decode($request[-1]{'value'}), { answer => 42 }, 'put_json encodes structured data');
is_deeply($kv_or->list(prefix => 'webdyne:', limit => 10)->get()->{'keys'},
    [{ name => 'webdyne:key' }], 'list options return keys');
ok($kv_or->delete('greeting')->get(), 'delete succeeds');

{
    local $WebDyne::Cloudflare::KV::HOST_CALL=sub {
        return $json_or->encode({ ok => JSON::PP::false(),
            error => { name => 'KV_ERROR', code => 10000, message => 'KV unavailable' } });
    };
    my $future_or=$kv_or->get('greeting');
    ok($future_or->is_failed(), 'KV host error fails the Future');
    my ($error_or)=$future_or->failure();
    ok(blessed($error_or) && $error_or->isa('WebDyne::Cloudflare::KV::Error'), 'KV failure is structured');
    like("$error_or", qr/KV_ERROR \[10000\]: KV unavailable/, 'KV error text is useful');
}

eval { WebDyne::Cloudflare::KV->new(scope => { extensions => {} }) };
like($@, qr/has no webdyne\.cloudflare\.kv capability/, 'missing KV capability rejected');
eval { $kv_or->put('bad', [1, 2])->get() };
like($@, qr/value must be a scalar or KV blob/, 'structured KV value rejected');
eval { $kv_or->list(unknown => 1)->get() };
like($@, qr/Unknown KV list option/, 'unknown KV option rejected');

done_testing();
