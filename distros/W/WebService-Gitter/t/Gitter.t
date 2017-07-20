use Test::More;
use Modern::Perl '2009';
use lib 'lib';
use WebService::Gitter;

BEGIN
{
	use_ok('Moo');
	use_ok('Function::Parameters');
	use_ok('WebService::Gitter');
	use_ok('LWP::Online', 'online');
	use_ok('WebService::Client');
	use_ok('Data::Dumper', 'Dumper');
}

my $true = 1;
my $false = 0;

# change $false to $true if you want to do advanced test
my $AUTHOR_TESTING = $true;

SKIP:
{
	skip "installation testing", 1 unless $AUTHOR_TESTING == $false;

	ok(my $git =
		WebService::Gitter->new(
			api_key => $ENV{GITTER_KEY}
		));

	SKIP:
	{
		skip "No internet connection", 1 unless online();

		my $group_id = '57542cf4c43b8c6019778297';
		my $user_id = '574f812ac43b8c6019763cf5';
		my $room_id = '54a2fa80db8155e6700e42c3';
		ok(my $current_user = $git->me(), "Get current logged in user");
		ok($git->show_dst($current_user), "Show current logged in user data structures");
		ok(my $groups = $git->groups(), "List groups");
		ok($git->show_dst($groups), "list groups dst");
		ok(my $rooms_group = $git->rooms_under_group($group_id), "list rooms under group");
		ok(my $rooms = $git->rooms(), "list rooms");
		ok($git->show_dst($rooms), "show_dst list_messages()");
		ok($git->rooms("FreeCodeCamp"), "list rooms based on query search");
	
		ok(my $room_users = $git->room_users($room_id), "list room's users");
		ok($git->show_dst($room_users), "show_dst rooms()"); 
		ok(my $messages = $git->list_messages($room_id), "list all messages in the room");
		ok($git->show_dst($messages), "show_dst list_messages()");
		ok(my $a_message = $git->single_message($room_id, "596a44a9329651f46e8dd496"), "get a single message from room");
		ok($git->show_dst($a_message), "show_dst single_message()");
		ok(my $send_message_resp = $git->send_message($room_id, "heh"), "send message");
	}
};

done_testing;
