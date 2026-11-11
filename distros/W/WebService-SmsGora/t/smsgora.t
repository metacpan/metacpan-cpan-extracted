use strict;
use warnings;
use Test::More;
use JSON::PP;
use WebService::SmsGora;

# Fake HTTP::Tiny: records requests and returns canned answers.
package FakeHTTP;
sub new { bless { calls => [], reply => {} }, shift }
sub request {
    my ($self, $method, $url, $opts) = @_;
    push @{ $self->{calls} }, { method => $method, url => $url, headers => $opts->{headers},
        body => defined $opts->{content} ? JSON::PP->new->decode($opts->{content}) : undef };
    return { success => 1, status => 200, headers => {},
        content => '{"success":true,"data":{"message_ids":[1873]}}', %{ $self->{reply} } };
}
sub last_call { $_[0]{calls}[-1] }

package main;

my $http = FakeHTTP->new;
my $sms  = WebService::SmsGora->new(api_key => 'sgk_test', base_url => 'https://example.test/api/', http => $http);

my $res = $sms->send_sms(to => '+15551234567', message => 'Hi');
is_deeply $res, { message_ids => [1873] }, 'send_sms returns data';
is $http->last_call->{method}, 'POST';
is $http->last_call->{url}, 'https://example.test/api/send-sms';
is $http->last_call->{headers}{'x-api-key'}, 'sgk_test', 'api key header';
is_deeply $http->last_call->{body}, { recipients => ['+15551234567'], message => 'Hi' };

$sms->send_sms(to => ['+1', '+2'], message => 'x', device_id => 42, sim_slot => 1, schedule_at => '2026-12-01T08:00:00Z');
is $http->last_call->{url}, 'https://example.test/api/devices/42/send-sms', 'device path';
is $http->last_call->{body}{sim_slot}, 1;
is $http->last_call->{body}{schedule_at}, '2026-12-01T08:00:00Z';

$sms->send_bulk_sms(42, message_template => 't', messages => [{ recipients => ['+1'], message => 'a' }, { recipients => ['+2'] }]);
is $http->last_call->{url}, 'https://example.test/api/devices/42/send-bulk-sms';
is $http->last_call->{body}{messageTemplate}, 't';

$sms->list_received_sms(phone => '+1555', since => '2026-11-01');
is $http->last_call->{url}, 'https://example.test/api/received-sms?phone=%2B1555&since=2026-11-01', 'query encoding';
$sms->list_received_sms(device_id => 3);
is $http->last_call->{url}, 'https://example.test/api/devices/3/get-received-sms';
$sms->cancel_message(7);
is $http->last_call->{url}, 'https://example.test/api/messages/7/cancel';
$sms->create_webhook(url => 'https://my.app/hook');
is_deeply $http->last_call->{body}{events}, ['sms.received'], 'default webhook event';
$sms->delete_webhook(9);
is $http->last_call->{method}, 'DELETE';

eval { $sms->send_sms(to => [], message => 'x') };
like $@, qr/at least one recipient/, 'needs a recipient';
eval { WebService::SmsGora->new };
like $@, qr/api_key is required/, 'needs a key';

$http->{reply} = { success => '', status => 429, headers => { 'retry-after' => '12' },
    content => '{"success":false,"message":"Too many requests","errors":{"recipients":["bad"]}}' };
eval { $sms->get_account };
my $err = $@;
isa_ok $err, 'WebService::SmsGora::Error';
is $err->status, 429;
is $err->message, 'Too many requests';
is $err->retry_after, 12;
is_deeply $err->errors, { recipients => ['bad'] };
like "$err", qr/Too many requests \(HTTP 429\)/, 'stringifies';

$http->{reply} = { success => '', status => 502, headers => {}, content => '<html>bad gateway</html>' };
eval { $sms->list_devices };
is $@->message, 'HTTP 502';
is $@->body, '<html>bad gateway</html>';

my $raw = '{"event":"sms.received","data":{"from":"+15551234567"}}';
my $sig = 'sha256=e125c07dfbecb498e8979383d7b9f0815efb128755409794b486d4bbb7199583';
ok WebService::SmsGora::verify_webhook($raw, $sig, 'whsec_test'), 'signature ok';
ok(WebService::SmsGora->verify_webhook($raw, $sig, 'whsec_test'), 'works as class method');
ok !WebService::SmsGora::verify_webhook($raw, $sig, 'other'), 'wrong secret';
ok !WebService::SmsGora::verify_webhook('{}', $sig, 'whsec_test'), 'changed body';
ok !WebService::SmsGora::verify_webhook($raw, undef, 'whsec_test'), 'missing header';

done_testing;
