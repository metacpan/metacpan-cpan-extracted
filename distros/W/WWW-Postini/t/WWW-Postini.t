# due to the relatively complex nature of TestProtocol
# this is an all-inclusive test script for WWW::Postini
#
# this file may be split into smaller chunks in a later revision

use strict;
use warnings;

use Test::Simple tests => 45;

use WWW::Postini;
use WWW::Postini::Constants ':all';
use LWP::Protocol;

# constants

use constant NEW_LOGIN_HOST => 'some.site.com';
use constant BAD_LOGIN      => 'user@domain.com';
use constant BAD_EMAIL      => 'nobody@domain.com';
use constant SENDER         => 'sender2@domain.com';
use constant RECIPIENT      => 'recipient3@domain.com';
use constant SUBJECT        => 'Subject 4';
use constant FILTER         => 'Filter 5';

# set up protocol to intercept https requests

LWP::Protocol::implementor('https', 'TestProtocol');

# instantiate test objects

my $p = new WWW::Postini();
my $p2 = new WWW::Postini(NEW_LOGIN_HOST);

# start tests

ok(UNIVERSAL::isa($p, 'WWW::Postini'), 'Create object');
ok($p->login_host() eq $TestProtocol::LOGIN_HOST, 'Default init');
ok($p2->login_host() eq NEW_LOGIN_HOST, 'Init with login host');
ok($p2->login_host($TestProtocol::LOGIN_HOST) eq $TestProtocol::LOGIN_HOST, 'Set login host');
ok(UNIVERSAL::isa($p->user_agent(), 'WWW::Postini::UserAgent'), 'User agent defined');

# login

eval {

	$p->login(BAD_LOGIN, $TestProtocol::PASSWORD);

};

ok(UNIVERSAL::isa($@, 'WWW::Postini::Exception::LoginFailure'), 'Login failed');

eval {

	$p->login($TestProtocol::LOGIN, $TestProtocol::PASSWORD);

};

ok(!$@, 'Login successful');

# transfer

ok($p->admin_host() eq $TestProtocol::ADMIN_HOST, 'Admin host defined');

# get user id

eval {

	$p->get_user_id(BAD_EMAIL);

};

ok(UNIVERSAL::isa($@, 'WWW::Postini::Exception::UnexpectedResponse'), 'Failed to retrieve user ID');

my $user_id;

eval {

	$user_id = $p->get_user_id($TestProtocol::EMAIL);
	
};

ok($user_id == $TestProtocol::USER_ID, 'Successfully retrieved user ID');

# list messages

my $messages;

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		show    => SHOW_ALL
	);

};

ok(!$@, 'List messages');
ok(UNIVERSAL::isa($messages, 'ARRAY'), 'Message list is array reference');
ok(defined $messages && scalar (@$messages) == scalar (@TestProtocol::MESSAGES), 'Message list size is correct');

my $fail;

if (defined $messages) {

	$fail = 0;
	my @fields = qw( date sender recipient subject filter id );
	my $field;

	for (my $idx = 0; $idx < scalar (@$messages); $idx++) {
	
		foreach $field (@fields) {
		
			unless (
				$messages->[$idx]->{$field} eq $TestProtocol::MESSAGES[$idx]->{$field}
			) {
			
				$fail = 1;
				last;	
		
			}
		
		}
	
		last if $fail;
	
	}
	
} else {

	$fail = 1;

}

ok(!$fail, 'Message lists are identical');

# list filters

eval {

	$messages = $p->list_messages(
		user_id   => $TestProtocol::USER_ID,
		recipient => RECIPIENT
	);

};

ok(!$@, 'Filter messages (recipient)');
ok(defined $messages && scalar (@$messages) == 1, 'Filtered list size correct (recipient)');
ok(defined $messages && $messages->[0]->{'recipient'} eq RECIPIENT, 'Message recipient correct');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		sender  => SENDER
	);

};

ok(!$@, 'Filter messages (sender)');
ok(defined $messages && scalar (@$messages) == 1, 'Filtered list size correct (sender)');
ok(defined $messages && $messages->[0]->{'sender'} eq SENDER, 'Message sender correct');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		subject => SUBJECT
	);

};

ok(!$@, 'Filter messages (subject)');
ok(defined $messages && scalar (@$messages) == 1, 'Filtered list size correct (subject)');
ok(defined $messages && $messages->[0]->{'subject'} eq SUBJECT, 'Message subject correct');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		filter  => FILTER
	);

};

ok(!$@, 'Filter messages (filter)');
ok(defined $messages && scalar (@$messages) == 1, 'Filtered list size correct (filter)');
ok(defined $messages && $messages->[0]->{'filter'} eq FILTER, 'Message filter correct');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		show    => SHOW_DELIVERED
	);

};

ok(!$@, 'Show messages (delivered)');
ok(defined $messages && scalar (@$messages) == 5, 'Shown list size correct (delivered)');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		show    => SHOW_QUARANTINED
	);

};

ok(!$@, 'Show messages (quarantined)');
ok(defined $messages && scalar (@$messages) == 5, 'Shown list size correct (quarantined)');

# message information

my $info;

eval {

	$info = $p->get_message_info($TestProtocol::USER_ID, $messages->[0]->{'id'});

};

ok(!$@, 'Get message information');

my $info_ok = defined $info && UNIVERSAL::isa($info, 'HASH') ? 1 : 0;

ok(
	$info_ok,
	'Message information is hash reference'
);
ok(
	$info_ok && $info->{'headers'} eq $TestProtocol::HEADERS,
	'Header information correct'
);
ok(
	$info_ok && $info->{'body'} eq $TestProtocol::BODY,
	'Body information correct'
);

my $attach_ok = $info_ok
	&& defined $info->{'attachments'}
	&& UNIVERSAL::isa($info->{'attachments'}, 'ARRAY')
;

ok(
	$attach_ok,
	'Attachment information is array reference'
);
ok(
	$attach_ok && scalar (@{$info->{'attachments'}}) == 2,
	'Attachment list is correct size'
);
ok(
	$attach_ok
	&& $info->{'attachments'}->[0] eq 'File2.exe'
	&& $info->{'attachments'}->[1] eq 'File2.zip',
	'Attachment list contents correct'
);

# delete messages

my $deleted_count;

eval {

	$deleted_count = $p->delete_messages(
		$TestProtocol::USER_ID,
		$messages->[0]->{'id'}
	);

};

ok(!$@, 'Delete message');
ok($deleted_count == 1, 'Deleted message count correct');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		show    => SHOW_DELETED
	);

};

ok(!$@, 'Show messages (deleted)');
ok(defined $messages && scalar (@$messages) == 1, 'Shown list size correct (deleted)');

# process messages

my $processed_count;

eval {

	$processed_count = $p->process_messages(
		user_id   => $TestProtocol::USER_ID,
		messages  => [ $messages->[0]->{'id'} ],
		recipient => RECIPIENT_USER,
		mark      => 1,
		clean     => 1
	);

};

ok(!$@, 'Process message');
ok($processed_count == 1, 'Processed message count correct');

eval {

	$messages = $p->list_messages(
		user_id => $TestProtocol::USER_ID,
		show    => SHOW_DELIVERED
	);

};

ok(!$@, 'Show messages (delivered)');
ok(defined $messages && scalar (@$messages) == 6, 'Shown list size correct (delivered)');

exit;

# adapted from LWP::Protocol::data

package TestProtocol;

use strict;
use warnings;

use HTTP::Response;
use HTTP::Status;
use HTTP::Date 'time2str';
use URI::Escape;
use LWP::Protocol;

use vars qw(
	@ISA
	$LOGIN_HOST
	$ADMIN_HOST
	$LOGIN
	$PASSWORD
	$TRANSFER
	$EMAIL
	$USER_ID
	$BODY
	$HEADERS
	@MESSAGES
);

# initialize variables

BEGIN {

	@ISA = qw( LWP::Protocol );
	
	$LOGIN_HOST = 'login.postini.com';
	$ADMIN_HOST = 'admin.postini.com';
	$LOGIN      = 'admin@domain.com';
	$PASSWORD   = 'password';
	$EMAIL      = 'quarantine@domain.com';
	$USER_ID    = 12345678;
	$HEADERS    = 'Name: value';
	$BODY       = 'This is a test';
	$TRANSFER   = 'foobar';
	
	foreach my $idx (1..10) {

		push @MESSAGES, {
			sender      => "sender$idx\@domain.com",
			recipient   => "recipient$idx\@domain.com",
			subject     => "Subject $idx",
			date        => (sprintf "%02d-%02d", 1, $idx),
			filter      => "Filter $idx",
			id          => ($idx.'_msgs1'),
			type        => (($idx + 1) % 2 ? 'quarantined' : 'delivered'),
			headers     => $HEADERS,
			body        => $BODY,
			attachments => ["File$idx.exe", "File$idx.zip"]
		};

	}

}

# handle request

sub request {

	my ($self, $request, $proxy, $arg, $size) = @_;
	my $method = $request->method();

	# refuse unsupported methods
	
	unless ($method eq 'GET' || $method eq 'POST') {

		return new HTTP::Response(&HTTP::Status::RC_BAD_REQUEST, 'Method not allowed');
		
	}

	my $url = $request->url();

	my ($protocol, $host, $path, $stem) = $url =~ m!^([^:]+)://([^/]+)([^?]+)(?:\?(.+))?$!;
	my $get_vars = _parse_args($stem);
	my $post_vars = _parse_args($request->content());
	my $content;

	# only support https	

	if (defined $protocol && $protocol eq 'https') {
				
		# login host

		if ($host eq $LOGIN_HOST) {

			# login
		
			if ($path eq '/exec/login' && $get_vars->{'action'} eq 'login') {

				$content = $self->handle_login($get_vars->{'email'}, $get_vars->{'pword'});
		
			} else {

				$content = $self->handle_login();
			
			}
	
		# admin host

		} elsif ($host eq $ADMIN_HOST) {
					
			if ($path eq '/exec/adminstart') {
			
				# user shortcut
				
				if (defined $get_vars->{'action'}
					&& $get_vars->{'action'} eq 'user_shortcut'
				) {
					
					$content = $self->handle_get_user_id($get_vars->{'targetAddress'});

				# transfer	
				
				} else {
				
					$content = $self->handle_transfer($get_vars->{'transfer'});
					
				}
			
			} elsif ($path eq '/exec/admin_users') {
				
				if (defined $get_vars->{'action'}) {
				
					# list messages
				
					if ($get_vars->{'action'} eq 'display_Quarantine') {

						$content = $self->handle_list_messages($get_vars, $post_vars);
				
					# get message information
				
					} elsif ($get_vars->{'action'} eq 'display_Message') {
				
						$content = $self->handle_get_message_info($get_vars, $post_vars);
						
					}
					
				} elsif (defined $post_vars->{'action'}) {
				
					if ($post_vars->{'action'} eq 'processQuarantine') {
					
						if (defined $post_vars->{'submit'}) {
					
							# delete messages
						
							if ($post_vars->{'submit'} eq 'Delete') {

								$content = $self->handle_delete_messages($get_vars, $post_vars);
								
							# process messages
							
							} elsif ($post_vars->{'submit'} eq 'Process') {

								$content = $self->handle_process_messages($get_vars, $post_vars);
								
							}
						
						}					
					
					}
					
				}
			
			}
		
		}		
	
	}
	
	# default response (404)
	
	unless (defined $content) {

		return new HTTP::Response(&HTTP::Status::RC_NOT_FOUND, 'Page not found');
		
	}
	
	# return content if it is a full response
	
	return $content if UNIVERSAL::isa($content, 'HTTP::Response');
	
	# otherwise piece a new response together
	
	my $response = new HTTP::Response(&HTTP::Status::RC_OK, 'Document follows');
	$response->header(
		'Content-Type'   => 'text/html',
		'Content-Length' => length($content),
		'Date'           => time2str(time),
		'Server'         => "WWW-Postini/$WWW::Postini::VERSION"
	);
	$response->content($content);
	$response;

}

# login

sub handle_login {

	my $self = shift;
	my $login = shift;
	my $password = shift;	
	# login failed

	if ($login ne $LOGIN || $password ne $PASSWORD) {
	
		return q!
			<html>
				<head>
					<title>Log in</title>
				</head>
				<body>
					<br>
					<b>Login failed</b>
				</body>
			</html>
    !;
	
	# login successful (transfer)
	
	} else {

		return qq!
			<html>
				<head>
					<title>Choose Session Type</title>
				</head>
				<body>
					<a href="https://$ADMIN_HOST/exec/adminstart?transfer=$TRANSFER">System Administration</a>
				</body>
			</html>
		!;	
	
	}

}

# transfer

sub handle_transfer {

	my $self = shift;
	my $transfer = shift;
	
	# incorrect transfer
	
	if ($transfer ne $TRANSFER) {
		
		return $self->handle_login();
	
	}
		
	# correct transfer
	
	return q!
		<html>
			<head>
				<title>System Administration</title>
			</head>
			<body>
			</body>
		</html>
	!;

}

# get user id

sub handle_get_user_id {

	my $self = shift;
	my $email = shift;

	if ($email eq $EMAIL) {
		
		my $content = 'Document found';		
		my $response = new HTTP::Response(&HTTP::Status::RC_FOUND, 'Document found');
		$response->header(
			'Content-Type'   => 'text/html',
			'Content-Length' => length($content),
			'Date'           => time2str(time),
			'Location'       => "/exec/admin_users?targetuserid=$USER_ID&action=display_Quarantine",
			'Server'         => "WWW-Postini/$WWW::Postini::VERSION"
		);
		$response->content($content);
		return $response;
	
	} else {
		
		return q!
			<html>
				<head>
					<title>System Administration</title>
				</head>
				<body>
					<center>
			  		<b>You have no permissions to access System Administration for "".</b>
					</center>
				</body>
			</html>
		!;		
	
	}

}

# list messages

sub handle_list_messages {

	my $self = shift;
	my $get_vars = shift;
	my $post_vars = shift;

	if ($get_vars->{'targetuserid'} == $USER_ID) {

		my $message_count = scalar @MESSAGES;
		my $start_idx = $message_count ? 1 : 0;
		
		my $content = qq!
			<html>
				<head>
					<title>User Overview</title>
				</head>
				<body>
				  <table>
				    <tr>
				      <td></td>
				    </tr>
				    <tr>
				    	<td width="100%" align="right">
				    		<font>
				    			<a href="#">Prev</a>
				    			|
				    			$start_idx - $message_count of $message_count
				    			|
				    			<a href="#">Next</a>
				    		</font>
				    	</td>
				    </tr>
					</table>
					<form>
						<table>
							<tr>
								<td>&nbsp;</td>
							</tr>
		!;
		
		my @bgcolors = ('#EEEEEE', '#FFFFFF');
		my $color_idx;

		for (my $idx = 0; $idx < $message_count; $idx++) {

			my $message = $MESSAGES[$idx];
			$color_idx = ($idx + 1) % 2 ? 1 : 0;
			
			# filter by recipient
			
			if (defined $post_vars->{'filterRecip'}
				&& length $post_vars->{'filterRecip'}
			) {
			
				next unless $message->{'recipient'} =~ /\Q$post_vars->{'filterRecip'}\E/i;
			
			}
			
			# filter by sender
			
			if (defined $post_vars->{'filterSender'}
				&& length $post_vars->{'filterSender'}
			) {
			
				next unless $message->{'sender'} =~ /\Q$post_vars->{'filterSender'}\E/i;
			
			}
			
			# filter by subject

			if (defined $post_vars->{'filterSubject'}
				&& length $post_vars->{'filterSubject'}
			) {

				next unless $message->{'subject'} =~ /\Q$post_vars->{'filterSubject'}\E/i;
			
			}
			
			# filter by block type
			
			if (defined $post_vars->{'filterBlock'}
				&& length $post_vars->{'filterBlock'}
			) {
			
				next unless $message->{'filter'} =~ /\Q$post_vars->{'filterBlock'}\E/i;
			
			}
			
			if (defined $post_vars->{'msgtype'}) {
			
				if ($post_vars->{'msgtype'} eq 'visible') {
				
					next unless $message->{'type'} eq 'quarantined';
				
				} elsif ($post_vars->{'msgtype'} eq 'delivered') {

					next unless $message->{'type'} eq 'delivered';			

				} elsif ($post_vars->{'msgtype'} eq 'deleted') {
				
					next unless $message->{'type'} eq 'deleted';			
			
				}
				
			}
	
			$content .= qq!
							<tr bgcolor="$bgcolors[$color_idx]">
								<td><font>&nbsp;</font></td>
								<td><font>$message->{'date'}</font></td>
								<td><font>$message->{'recipient'}</font></td>
								<td><font>$message->{'sender'}</font></td>
								<td>
									<font>
										<a href="/exec/admin_users?targetuserid=$USER_ID&action=display_Message&msgid=$message->{'id'}">$message->{'subject'}</a>
									</font>
								</td>
								<td><font>$message->{'filter'}</font></td>
							</tr>
			!;
			
		}

		$content .= q!
							</tr>
						</table>
					</form>
				</body>
			</html>
		!;

		return $content;
	
	}

}

# get message information

sub handle_get_message_info {

	my $self = shift;
	my $get_vars = shift;
	my $post_vars = shift;
	my $message = _get_message($get_vars->{'msgid'}) or return;
	
	my $attach_content = join '<br>', (
		map { "application/octet-stream; name=$_" } @{$message->{'attachments'}}
	);
	
	return qq!
		<html>
			<head>
				<title>User Overview</title>
			</head>
			<body>
				<font>
					<pre>$message->{'headers'}</pre>
					<xmp>$message->{'body'}</xmp>
					Attachments:<br>
					$attach_content<br>
				</font>
			</body>
		</html>
	!;
	
}

# delete messages

sub handle_delete_messages {

	my $self = shift;
	my $get_vars = shift;
	my $post_vars = shift;
	my $message = _get_message($post_vars->{'msgid'}) or return;
	$message->{'type'} = 'deleted';

	return qq!
		<html>
			<head>
				<title>User Overview</title>
			</head>
			<body>
				<b>Message Results</b>
				<font>1 message(s) marked as deleted.</font>
			</body>
		</html>
	!;

}

# process messages

sub handle_process_messages {

	my $self = shift;
	my $get_vars = shift;
	my $post_vars = shift;
	my $message = _get_message($post_vars->{'msgid'}) or return;
	$message->{'type'} = 'delivered';

	return q!
		<html>
			<head>
				<title>User Overview</title>
			</head>
			<body>
				<b>Message Results</b>
				<font>1 message(s) queued for delivery to original recipient.</font>
			</body>
		</html>
	!;

}

# get message from array

sub _get_message {

	my $message_id = shift or return;
	my $message;
		
	for (my $idx = 0; $idx < scalar (@MESSAGES); $idx++) {
	
		if ($MESSAGES[$idx]->{'id'} eq $message_id) {
		
			$message = $MESSAGES[$idx];
			last;
		
		}	
	
	}
	
	$message;

}

# parse get/post arguments

sub _parse_args {

	my $args_text = shift;
	$args_text = '' unless defined $args_text;
	my %args;
	
	foreach my $pair (split /&/, $args_text) {
		
		$pair =~ s/\+/ /g;
		my ($key, $value) = split /=/, uri_unescape($pair);
		$args{$key} = $value;
		
	}

	\%args;	

}