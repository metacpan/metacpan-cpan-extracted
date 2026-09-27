use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'lib';
use WebDyne::Cloudflare::DurableObject;
use WebDyne::Cloudflare::DurableObject::Context;

my $json_or=JSON::PP->new()->allow_nonref();
my $scope_hr={extensions => {'webdyne.cloudflare.durable_object' => {
    version => 1, capability => 'capability-token', bindings => ['ROOMS'], id => 'a'x64,
}}};
my @calls;
local $WebDyne::Cloudflare::DurableObject::HOST_CALL=sub {
    my ($wire)=@_;
    my $request_hr=$json_or->decode($wire);
    push(@calls, $request_hr);
    return $json_or->encode({ok => JSON::PP::true, result => 'a'x64}) if ($request_hr->{'operation'} eq 'resolve');
    return $json_or->encode({ok => JSON::PP::true, result => $request_hr->{'args'}}) if ($request_hr->{'operation'} eq 'call');
    return $json_or->encode({ok => JSON::PP::true, result => WebDyne::Cloudflare::DurableObject::encode_value(
        {rows => [{value => 7}], rows_written => 1, rows_read => 1})});
};
my $namespace_or=WebDyne::Cloudflare::DurableObject->new(scope => $scope_hr, binding => 'ROOMS');
my $stub_or=$namespace_or->get_by_name('room')->get();
is($stub_or->id(), 'a'x64, 'resolved identity');
my $result_ar=$stub_or->call('echo', {t => 'bytes', v => 'ordinary'}, undef,
    WebDyne::Cloudflare::DurableObject::bytes("\0\xff"))->get();
is_deeply($result_ar->[0], {t => 'bytes', v => 'ordinary'}, 'unambiguous hash');
ok(!defined($result_ar->[1]), 'null survives');
is($result_ar->[2]->value(), "\0\xff", 'explicit bytes survive');
my $context_or=WebDyne::Cloudflare::DurableObject::Context->new($scope_hr);
is_deeply($context_or->selectrow_hashref('SELECT ?', undef, 7)->get(), {value => 7}, 'bound SQL result');
is_deeply(WebDyne::Cloudflare::DurableObject::decode_value($calls[-1]{'statement'}{'params'}), [7], 'parameters separate from SQL');
ok($context_or->do('DELETE FROM t', {})->is_failed(), 'unsupported attributes rejected');
my $cycle_hr={}; $cycle_hr->{'self'}=$cycle_hr;
ok(!eval { WebDyne::Cloudflare::DurableObject::encode_value($cycle_hr); 1 }, 'cycles rejected');
delete $cycle_hr->{'self'};
ok(!eval { WebDyne::Cloudflare::DurableObject->new(scope => $scope_hr, binding => 'SECRET'); 1 }, 'binding allowlist');
{
    local $WebDyne::Cloudflare::DurableObject::HOST_CALL=sub { return $json_or->encode({ok => JSON::PP::false,error => {name=>'REMOTE',message=>'failed',code=>'E_TEST'}}); };
    my $future_or=$stub_or->call('write');
    ok($future_or->is_failed(), 'error fails Future');
    my ($error_or)=$future_or->failure();
    isa_ok($error_or,'WebDyne::Cloudflare::DurableObject::Error');
    is($error_or->code(),'E_TEST','structured error preserved');
}
done_testing();
