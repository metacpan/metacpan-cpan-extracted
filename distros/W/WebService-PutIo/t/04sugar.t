use Test::More tests=>6;
use WebService::PutIo::Files;
use WebService::PutIo::Messages;
use WebService::PutIo::Transfers;
use WebService::PutIo::URLs;
use WebService::PutIo::User;
use WebService::PutIo::Subscriptions;


{
	my $files=WebService::PutIo::Files->new();
	can_ok($files,qw/list create_dir info rename move delete search dirmap/);
};

{
	my $messages=WebService::PutIo::Messages->new();
	can_ok($messages,qw/list delete/);
};
{
	my $files=WebService::PutIo::Transfers->new();
	can_ok($files,qw/list add cancel/);
};

{
	my $urls=WebService::PutIo::URLs->new();
	can_ok($urls,qw/analyze extracturls/);
};

{
	my $user=WebService::PutIo::User->new();
	can_ok($user,qw/info friends/);
};

{
	my $subscriptions=WebService::PutIo::Subscriptions->new();
	can_ok($subscriptions,qw/list create edit delete pause info/);
};
