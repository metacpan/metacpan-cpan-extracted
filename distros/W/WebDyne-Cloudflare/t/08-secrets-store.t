use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use WebDyne::Cloudflare::SecretsStore;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();
my $scope_hr={ extensions => { 'webdyne.cloudflare.secrets_store' => {
    version => 1, capability => 'secret-token', bindings => ['API_KEY'],
} } };
my $secret_or=WebDyne::Cloudflare::SecretsStore->new(scope => $scope_hr, binding => 'API_KEY');
is($secret_or->binding(), 'API_KEY', 'binding retained');
foreach my $value ('', '0', "dummy π\n\0", 'rotated') {
    local $WebDyne::Cloudflare::SecretsStore::HOST_CALL=sub {
        my ($wire)=@_;
        is_deeply($json_or->decode($wire), {
            version => 1, capability => 'secret-token', binding => 'API_KEY', operation => 'get',
        }, 'only capability and binding sent');
        return $json_or->encode({ ok => JSON::PP::true(), result => $value });
    };
    my $future_or=$secret_or->get();
    isa_ok($future_or, 'Future');
    is($future_or->get(), $value, 'secret text preserved');
}
foreach my $response ('PRIVATE_VALUE', '{"ok":true,"result":null}', '{"ok":true,"result":{}}',
    '{"ok":"PRIVATE_VALUE"}', '{"ok":false,"error":{"name":"PRIVATE_VALUE","message":"PRIVATE_VALUE"}}',
    '{"ok":false,"error":{"name":"SECRETS_STORE_READ_ERROR","cause":"PRIVATE_VALUE"}}') {
    local $WebDyne::Cloudflare::SecretsStore::HOST_CALL=sub { return $response; };
    my $future_or=$secret_or->get();
    ok($future_or->is_failed(), 'invalid or failed response fails Future');
    my ($error_or)=$future_or->failure();
    isa_ok($error_or, 'WebDyne::Cloudflare::SecretsStore::Error');
    unlike("$error_or", qr/PRIVATE_VALUE/, 'error payload is redacted');
}
{
    local $WebDyne::Cloudflare::SecretsStore::HOST_CALL=sub { die 'PRIVATE_VALUE'; };
    my $future_or=$secret_or->get();
    my ($error_or)=$future_or->failure();
    is($error_or->name(), 'SECRETS_STORE_HOST_ERROR', 'host exception classified');
    unlike("$error_or", qr/PRIVATE_VALUE/, 'host exception redacted');
}
eval { $secret_or->get('other')->get(); };
like($@, qr/accepts no arguments/, 'get rejects a secret name');
foreach my $opt_hr ({ scope => {} }, { scope => $scope_hr, binding => 'OTHER' },
    { scope => $scope_hr, binding => 'bad-name' }) {
    eval { WebDyne::Cloudflare::SecretsStore->new(%{$opt_hr}); };
    ok($@, 'invalid or unavailable capability rejected');
}
done_testing();
