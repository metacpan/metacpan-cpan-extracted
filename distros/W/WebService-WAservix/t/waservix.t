use strict;
use warnings;
use Test::More;
use JSON::PP;
use WebService::WAservix;

# Fake HTTP::Tiny: records requests and returns canned answers.
package FakeHTTP;
sub new { bless { calls => [], reply => {} }, shift }
sub request {
    my ($self, $method, $url, $opts) = @_;
    push @{ $self->{calls} }, { method => $method, url => $url, headers => $opts->{headers},
        body => defined $opts->{content} ? JSON::PP->new->decode($opts->{content}) : undef };
    return { success => 1, status => 200, headers => {},
        content => '{"success":true,"data":{"msgId":58213,"status":"in_progress"}}', %{ $self->{reply} } };
}
sub last_call { $_[0]{calls}[-1] }

package main;

my $http = FakeHTTP->new;
my $wa   = WebService::WAservix->new(api_key => 'wpk_test', base_url => 'https://example.test/api', http => $http);

my $res = $wa->send_text('+1555', 'hi');
is $res->{msgId}, 58213, 'send_text returns data';
is $http->last_call->{url}, 'https://example.test/api/send-message';
is $http->last_call->{headers}{Authorization}, 'Bearer wpk_test', 'bearer header';
is_deeply $http->last_call->{body}, { to => '+1555', text => 'hi' };

$wa->send_image('+1', 'https://x/y.jpg');
is_deeply $http->last_call->{body}, { to => '+1', imageUrl => 'https://x/y.jpg' }, 'no empty caption';
$wa->send_document('+1', 'https://x/a.pdf', file_name => 'a.pdf', caption => 'c');
is $http->last_call->{body}{fileName}, 'a.pdf';
is $http->last_call->{body}{text}, 'c';
$wa->send_location('+1', -1.9441, 30.0619, name => 'Shop');
is $http->last_call->{body}{location}{name}, 'Shop';
$wa->send_message('1203@g.us', poll => { name => 'Lunch?', options => ['Yes', 'No'] });
is $http->last_call->{body}{to}, '1203@g.us';

$wa->get_message_info(5);
is $http->last_call->{url}, 'https://example.test/api/messages/5/info';
$wa->edit_message(5, 't');
is $http->last_call->{method}, 'PUT';
$wa->on_whatsapp('+1555');
is $http->last_call->{url}, 'https://example.test/api/on-whatsapp/%2B1555', 'escapes +';
$wa->get_group_metadata('1203@g.us');
is $http->last_call->{url}, 'https://example.test/api/groups/1203%40g.us/metadata', 'escapes @';
$wa->connect_session(3);
is_deeply $http->last_call->{body}, { method => 'qr' };
$wa->connect_session(3, phone => '+1555');
is_deeply $http->last_call->{body}, { method => 'code', phone => '+1555' };

eval { $wa->send_text('', 'x') };
like $@, qr/"to" is required/, 'needs a recipient';

$http->{reply} = { success => '', status => 503, headers => {}, content => '{"success":false,"message":"Device reconnecting"}' };
eval { $wa->get_status };
isa_ok $@, 'WebService::WAservix::Error';
is $@->status, 503;
is $@->message, 'Device reconnecting';

$http->{reply} = { content => '{"success":false,"message":"Invalid number"}' };
eval { $wa->send_text('+1', 'x') };
is $@->message, 'Invalid number', 'success:false with HTTP 200 is an error';

ok WebService::WAservix::verify_webhook('abc', 'abc'), 'secret ok';
ok(WebService::WAservix->verify_webhook('abc', 'abc'), 'class method');
ok !WebService::WAservix::verify_webhook('abd', 'abc'), 'wrong';
ok !WebService::WAservix::verify_webhook('abcd', 'abc'), 'length differs';
ok !WebService::WAservix::verify_webhook(undef, 'abc'), 'missing';

done_testing;
