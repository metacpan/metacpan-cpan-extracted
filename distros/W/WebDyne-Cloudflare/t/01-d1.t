use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::D1;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();
my @request;
local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
    my ($wire)=@_;
    my $request_hr=$json_or->decode($wire);
    push @request, $request_hr;
    return $json_or->encode({
        ok     => JSON::PP::true(),
        result => $request_hr->{'operation'} eq 'first'
            ? { id => 7, name => 'WebDyne' }
            : {
                success => JSON::PP::true(),
                meta    => { changes => 1 },
                results => [{ id => 7, payload => { type => 'blob', base64 => 'AAH/' } }],
            },
    });
};

my $scope_hr={
    extensions => {
        'webdyne.cloudflare.d1' => {
            version    => 1,
            capability => 'capability-token',
            bindings   => ['DB'],
        },
    },
};
my $db_or=WebDyne::Cloudflare::D1->new(scope => $scope_hr, binding => 'DB');
is($db_or->binding(), 'DB', 'binding retained');

my $unbound_or=$db_or->prepare('SELECT ?1');
my $bound_or=$unbound_or->bind(WebDyne::Cloudflare::D1->blob("\0\1\xff"));
my $result_ref=$bound_or->run()->get();
is_deeply($request[0]{'params'}, [{ type => 'blob', base64 => 'AAH/' }], 'blob parameter encoded');
is($result_ref->{'results'}[0]{'payload'}, "\0\1\xff", 'blob result decoded');
is_deeply($unbound_or->bind(42)->run()->get()->{'meta'}, { changes => 1 }, 'statement remains reusable');
$unbound_or->bind("\xcf\x80")->run()->get();
is($request[-1]{'params'}[0], 'π', 'unflagged UTF-8 web text becomes Unicode');
is_deeply($db_or->first('SELECT id, name FROM things WHERE id=?1', 7)->get(),
    { id => 7, name => 'WebDyne' }, 'first convenience returns a row');

{
    local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
        return $json_or->encode({
            ok    => JSON::PP::false(),
            error => { name => 'D1_ERROR', code => 7500, message => 'no such table: missing' },
        });
    };
    my $future_or=$db_or->prepare('SELECT * FROM missing')->run();
    ok($future_or->is_failed(), 'host error fails the Future');
    my ($error_or)=$future_or->failure();
    ok(blessed($error_or) && $error_or->isa('WebDyne::Cloudflare::D1::Error'), 'failure is structured');
    like("$error_or", qr/D1_ERROR \[7500\]: no such table/, 'error text is useful');
}

eval { WebDyne::Cloudflare::D1->new(scope => { extensions => {} }) };
like($@, qr/has no webdyne\.cloudflare\.d1 capability/, 'missing capability rejected');
eval { $db_or->prepare('SELECT ?1')->bind([])->run()->get() };
like($@, qr/bind values must be scalars/, 'structured bind value rejected');

done_testing();
