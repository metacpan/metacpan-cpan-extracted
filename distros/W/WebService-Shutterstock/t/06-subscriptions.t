use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $client = WebService::Shutterstock::Client->new;
my $customer = WebService::Shutterstock::Customer->new(
	auth_info => { auth_token => 123, username => 'abc' },
	client    => $client
);
isa_ok($customer, 'WebService::Shutterstock::Customer');

can_ok $customer, 'subscriptions';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/abc/subscriptions.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		return $self->response(
			response(
				200,
				'[{"subscription_id":1,"unix_expiration_time":0,"license":"premier"},{"subscription_id":2,"unix_expiration_time":0,"license":"premier_digital","sizes":{"medium_jpg":{"format":"jpg","name":"medium"}}}]'
			)
		);
	});
	my $subscriptions = $customer->subscriptions;
	is @$subscriptions, 2, 'has subscriptions';
	isa_ok $subscriptions->[0], 'WebService::Shutterstock::Subscription';
	is $subscriptions->[0]->id, 1, 'has correct data';
	ok $subscriptions->[0]->is_expired, 'is_expired';
	ok !$subscriptions->[0]->is_active, 'is_active';
	is $customer->subscription(license => 'premier_digital')->id, 2, 'license lookup for subscription';
	is $customer->find_subscriptions(license => qr{^premier}), 2, 'all premier licenses returned';
	is $customer->find_subscriptions(license => sub { 0 }), 0, 'callback filter';
	ok !eval {$customer->find_subscriptions(bogus => 'blah'); 1}, 'dies OK';
	like $@, qr{bogus}, 'errors informatively';
}

done_testing;

sub response {
	@_ = [@_] unless ref $_[0] eq 'ARRAY';
	my $code = $_[0]->[0];
	my $data = $_[0]->[1];

	my $method = $_[1]->[0] || 'GET';
	my $uri = $_[1]->[1] || '/';

	my $response = HTTP::Response->new( $code, undef, ['Content-Type' => 'application/json'], $data );
	$response->request(HTTP::Request->new( $method, $uri ));
	return $response;
}
