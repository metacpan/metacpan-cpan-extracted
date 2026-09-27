use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use WebDyne::Cloudflare::D1;

my $json_or=JSON::PP->new()->canonical();
my $scope_hr={extensions => {'webdyne.cloudflare.d1' => {
    version => 1, capability => 'batch-capability', bindings => ['DB', 'OTHER'],
}}};
my $db_or=WebDyne::Cloudflare::D1->new(scope => $scope_hr);
my $unbound_or=$db_or->prepare('SELECT ?1, ?2, ?3, ?4, ?5, ?6');
my $bound_or=$unbound_or->bind(0, '', undef, "\xcf\x80",
    $db_or->blob("\0\xff"), JSON::PP::false());
my @request;
local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
    my ($wire)=@_;
    push(@request, $json_or->decode($wire));
    return $json_or->encode({ok => JSON::PP::true(), result => [
        {success => JSON::PP::true(), meta => {changes => 1}, results => []},
        {success => JSON::PP::true(), meta => {}, results => [{
            type => 'blob', base64 => 'AA==', payload => {type => 'blob', base64 => 'AP8='},
            zero => 0, empty => '', missing => undef,
        }]},
    ]});
};

my $result_ar=$db_or->batch([$bound_or, $unbound_or])->get();
is(scalar(@request), 1, 'batch makes one host call');
is($request[0]{'operation'}, 'batch', 'batch operation selected');
is_deeply($request[0]{'statements'}, [
    {sql => 'SELECT ?1, ?2, ?3, ?4, ?5, ?6', params => [
        0, '', undef, 'π', {type => 'blob', base64 => 'AP8='}, JSON::PP::false(),
    ]},
    {sql => 'SELECT ?1, ?2, ?3, ?4, ?5, ?6', params => []},
], 'parameters preserve order, flags, Unicode and bytes without changing unbound statement');
is($result_ar->[0]{'meta'}{'changes'}, 1, 'first result retains metadata');
is_deeply($result_ar->[1]{'results'}[0], {
    type => 'blob', base64 => 'AA==', payload => "\0\xff", zero => 0, empty => '', missing => undef,
}, 'second result decodes only BLOB columns');
$db_or->batch([$bound_or, $unbound_or])->get();
is_deeply($request[1], $request[0], 'bound statements remain reusable');

foreach my $bad_ref (undef, [], {}, 'sql') {
    my $future_or=$db_or->batch($bad_ref);
    ok($future_or->is_failed(), 'invalid batch fails its Future');
    like(($future_or->failure())[0], qr/non-empty array/, 'invalid batch has a useful error');
}
foreach my $bad_ref (undef, {}, 'SELECT 1', $db_or) {
    my $future_or=$db_or->batch([$bound_or, $bad_ref]);
    like(($future_or->failure())[0], qr/entries must be D1 prepared statements/,
        'invalid entry rejected before host execution');
}
foreach my $other_or (
    WebDyne::Cloudflare::D1->new(scope => $scope_hr),
    WebDyne::Cloudflare::D1->new(scope => $scope_hr, binding => 'OTHER'),
    WebDyne::Cloudflare::D1->new(scope => {extensions => {'webdyne.cloudflare.d1' => {
        version => 1, capability => 'other-request', bindings => ['DB'],
    }}}),
) {
    my $future_or=$db_or->batch([$bound_or, $other_or->prepare('SELECT 1')]);
    like(($future_or->failure())[0], qr/same database object/, 'foreign statement rejected');
}
my $future_or=$db_or->batch([$bound_or, $unbound_or->bind({})]);
like(($future_or->failure())[0], qr/bind values/, 'invalid later parameter rejects whole batch');
is(scalar(@request), 2, 'no invalid batch reached the host');

{
    local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
        return $json_or->encode({ok => JSON::PP::false(),
            error => {name => 'D1_ERROR', message => 'constraint failed'}});
    };
    my $failed_or=$db_or->batch([$bound_or]);
    my ($error_or)=$failed_or->failure();
    isa_ok($error_or, 'WebDyne::Cloudflare::D1::Error');
    like("$error_or", qr/constraint failed/, 'provider error fails the whole Future');
}
foreach my $bad_ref (undef, {}, [], [{}], [{success => 1, results => {}}]) {
    local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
        return $json_or->encode({ok => JSON::PP::true(), result => $bad_ref});
    };
    my $failed_or=$db_or->batch([$bound_or]);
    my ($error_or)=$failed_or->failure();
    isa_ok($error_or, 'WebDyne::Cloudflare::D1::Error');
    is($error_or->name(), 'D1_PROTOCOL_ERROR', 'malformed batch result fails explicitly');
}
done_testing();
