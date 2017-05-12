use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $ss = WebService::Shutterstock->new(api_username => "test", api_key => 123);
isa_ok($ss, 'WebService::Shutterstock');

can_ok $ss, 'client';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('new', sub {
		my $class = shift;
		my %args = @_;
		is $args{host}, 'https://api.shutterstock.com', 'default host';
		return $guard->original('new')->($class, @_);
	});
	ok $ss->client, 'client initialized';
}

$ss = WebService::Shutterstock->new(api_username => "test", api_key => 123);
{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('new', sub {
		my $class = shift;
		my %args = @_;
		is $args{host}, 'https://testing.com', 'override host';
		return $guard->original('new')->($class, @_);
	});
	local $ENV{SS_API_HOST} = 'https://testing.com';
	ok $ss->client, 'client initialized with non-default host';
}

done_testing;
