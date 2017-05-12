use strict;
use warnings;

use WWW::Postini;
use WWW::Postini::Constants qw( :show :recipient );

use constant STATE_QUIT         => 0;
use constant STATE_LOGIN        => 1;
use constant STATE_PASSWORD     => 2;
use constant STATE_AUTH         => 3;
use constant STATE_LIST         => 4;

use constant MAX_LOGIN_ATTEMPTS => 3;
use constant PAGE_SIZE          => 10;

use constant LOGIN_PROMPT       => 'Login: ';
use constant PASSWORD_PROMPT    => 'Password: ';
use constant COMMAND_PROMPT     => 'Command: ';

local $| = 1;

my $p = new WWW::Postini();
my $state = STATE_LOGIN;
my ($input, $output);
my ($login, $password);
my ($user_id, $messages, %info_cache);
my ($list_size, $page_start, $page_end);

my $login_attempt = 0;

print "WWW::Postini Shell $WWW::Postini::VERSION - Use 'help' for command syntax\n\n";

# main loop

while (1) {

	# special handling of quit state
	
	if ($state == STATE_QUIT) {

		last;
	
	# get prompt	
	
	} else {
	
		print GetPrompt();
	
	}
	
	# get input	
	$input = GetInput();
	
	# handle input	
	$output = HandleInput($input);
	
	# display output	
	print $output if defined $output;

}

exit;

# get user input

sub GetInput {

	chomp (my $input = <STDIN>);
	$input = '' unless defined $input;
	[ split /\s+/, $input ];

}

# get prompt for current state

sub GetPrompt {

	my $output;
	
	# login
	
	if ($state == STATE_LOGIN) {
	
		$output = LOGIN_PROMPT;
	
	# password
	
	} elsif ($state == STATE_PASSWORD) {
	
		$output = PASSWORD_PROMPT;
	
	# listing messages
	
	} elsif ($state == STATE_LIST) {

		my @commands;
		
		push @commands, '[p]rev' if $page_start > 0;
		push @commands, '[n]ext' if $page_end < $list_size - 1;
		
		$output = sprintf "Listing messages (%d - %d of %d)%s: ",
			$page_start + 1,
			$page_end + 1,
			$list_size,
			(scalar (@commands) ? ' '.(join ', ', @commands) : '')
		;			
	
	# all other states
	
	} else {
	
		$output = COMMAND_PROMPT;
	
	}
	
	$output;

}

# handle input from user

sub HandleInput {

	my $input = shift;
	return unless defined $input && scalar @$input;
	
	# login state
	
	if ($state == STATE_LOGIN) {

		return HandleLogin($input);
	
	# password state
	
	} elsif ($state == STATE_PASSWORD) {
		
		return HandlePassword($input);
	
	# listing messages state
		
	} elsif ($state == STATE_LIST) {
			
		# next page
			
		if ($input->[0] eq 'n' || $input->[0] eq 'next') {
			
			return HandleNext();
				
		# previous page
			
		} elsif ($input->[0] eq 'p' || $input->[0] eq 'prev') {
			
			return HandlePrevious();
				
		}
				
	}
	
	# quit
		
	if ($input->[0] eq 'quit') {
			
		return HandleQuit();
			
	# help
		
	} elsif ($input->[0] eq 'help') {
		
		return HandleHelp();

	# get message headers
			
	} elsif ($input->[0] eq 'headers') {
				
		return HandleHeaders($input);
			
	# get message body
			
	} elsif ($input->[0] eq 'body') {
				
		return HandleBody($input);
			
	# get message attachments
			
	} elsif ($input->[0] eq 'attach') {
				
		return HandleAttach($input);
			
	# list quarantined messages
		
	} elsif ($input->[0] eq 'list') {
			
		return HandleList($input);
			
	# set current user
		
	} elsif ($input->[0] eq 'user') {

		return HandleUser($input);
			
	# delete message
		
	} elsif ($input->[0] eq 'delete') {
		
		return HandleDelete($input);

	# release message
		
	} elsif ($input->[0] eq 'release') {
		
		return HandleRelease($input);

	}
	
	return "Unknown command - please see 'help' for a list of commands\n";

}

# login

sub HandleLogin {

	my $input = shift;
	$login = $input->[0];
	$state = STATE_PASSWORD;
	return;

}

# password

sub HandlePassword {

$password = $input->[0];

	my $input = shift;
	my $output;
		
	# try
	
	eval {
		
		$p->login($login, $password);		
		
	};
		
	# catch
		
	if ($@) {
						
		$output = "Login failed ($@)\n";
		
		# too many failed login attempts
			
		if (++$login_attempt >= MAX_LOGIN_ATTEMPTS) {
				
			$state = STATE_QUIT;
				
		# start login process anew
			
		} else {

			$state = STATE_LOGIN;
				
		}
		
	# login successful

	} else {
		
		$output = "Login successful\n";
		$login_attempt = 0;
		$state = STATE_AUTH;			
		
	}
	
	$output;

}

# display help

sub HandleHelp {

	return qq!
Command syntax:

help          - Display command syntax
quit          - Quit shell
user EMAIL    - Set current user to EMAIL
list          - List currently quarantined messages (user must be set first)
headers INDEX - Get headers for message INDEX
body INDEX    - Get body for message INDEX
attach INDEX  - Get attachments for message INDEX
release INDEX - Release message INDEX
delete INDEX  - Delete message INDEX

!;

}

# quit

sub HandleQuit {

	$state = STATE_QUIT;
	"Goodbye!\n";

}

# set current user

sub HandleUser {

	my $input = shift;
	
	# syntax error
	
	unless (scalar @$input == 2) {
		
		return "Syntax: user EMAIL\n";
		
	}
				
	# try
	
	eval {

		$user_id = $p->get_user_id($input->[1]);
					
	};
				
	# catch
	
	if ($@) {
				
		return "Unable to set user\n";
		
	}
									
	return "User ID set to $user_id\n";

}

# delete message

sub HandleDelete {

	my $input = shift;
	
	# messages must currently be listed
			
	unless (defined $messages) {
			
		return "No messages - use 'list' first\n";

	}	
	
	# syntax error
	
	unless (scalar @$input == 2 && $input->[1] =~ /^\d+$/) {
				
		return "Syntax: delete INDEX\n";
				
	}
		
	my $idx = $input->[1] - 1;
		
	# message index out of bounds
	
	if ($idx < 0 || $idx >= $list_size) {
	
		return "Unable to retrieve message information\n";
		
	}
		
	# try
	
	eval {
			
		$p->delete_messages($user_id, $messages->[$idx]->{'id'});
				
	};
			
	# catch
	
	if ($@) {
			
		return "Unable to delete message ($@)\n";
			
	}
			
	return "Message deleted\n";		

}

# release message

sub HandleRelease {

	my $input = shift;
	
	# messages must currently be listed
			
	unless (defined $messages) {
			
		return "No messages - use 'list' first\n";

	}
	
	# syntax error
	
	unless (scalar @$input == 2 && $input->[1] =~ /^\d+$/) {
				
		return "Syntax: release INDEX\n";
				
	}
		
	my $idx = $input->[1] - 1;
		
	# message index out of bounds
	
	if ($idx < 0 || $idx >= $list_size) {
	
		return "Unable to retrieve message information\n";		
		
	}

	# try
	
	eval {

		$p->process_messages(
			user_id   => $user_id,
			messages  => [ $messages->[$idx]->{'id'} ],
			recipient => RECIPIENT_USER,
			mark      => 1,
			clean     => 1
		);

	};

	# catch
	
	if ($@) {

		return "Unable to release message ($@)\n";

	}

	return "Message released\n";

}

# list messages

sub HandleList {

	my $input = shift;

	# user must be set prior to listing messages
			
	unless (defined $user_id) {
			
		return "No user - set one with 'user'\n";

	}
			
	# try
	
	eval {
				
		$messages = $p->list_messages(
			user_id => $user_id,
			show    => SHOW_QUARANTINED
		);
				
	};
			
	# catch
	
	if ($@) {
			
		return "Unable to list messages\n";

	}

	$list_size = scalar @$messages;
	$page_start = 0;
	$page_end = $page_start + PAGE_SIZE - 1;
	$page_end = $list_size - 1 if $page_end >= $list_size;
	
	# clear message info cache
	
	%info_cache = ();	
	$state = STATE_LIST;
	
	# generate message list
	
	return GenerateList();			

}

# list message attachments

sub HandleAttach {

	my $input = shift;
	
	# messages must currently be listed
			
	unless (defined $messages) {
			
		return "No messages - use 'list' first\n";

	}	
	
	# syntax error
	
	unless (scalar @$input == 2 && $input->[1] =~ /^\d+$/) {
				
		return "Syntax: attach INDEX\n";
				
	}
				
	# get message information
	
	my $message = GetMessageInfo($input->[1]);
				
	# message does not exist
	
	unless (defined $message) {
				
		return "Unable to retrieve message information\n";
	
	}
				
	# return message attachments
	
	return sprintf "Displaying attachments for message %d\n\n%s\n\n",
		$input->[1],
		(join "\n", @{$message->{'attachments'}});
	;			

}

# show message body

sub HandleBody {

	my $input = shift;
	
	# messages must currently be listed
			
	unless (defined $messages) {
			
		return "No messages - use 'list' first\n";

	}	
	
	# syntax error
	
	unless (scalar @$input == 2 && $input->[1] =~ /^\d+$/) {
				
		return "Syntax: body INDEX\n";
				
	}
				
	# retrieve message information
	
	my $message = GetMessageInfo($input->[1]);
				
	# message does not exist
	
	unless (defined $message) {
				
		return "Unable to retrieve message information\n";
				
	}
				
	# return message body
	
	return sprintf "Displaying body for message %d\n\n%s\n\n",
		$input->[1],
		$message->{'body'}
	;

}

# show message headers

sub HandleHeaders {

	my $input = shift;

	# messages must currently be listed
			
	unless (defined $messages) {
			
		return "No messages - use 'list' first\n";

	}
		
	# syntax error
	
	unless (scalar @$input == 2 && $input->[1] =~ /^\d+$/) {
				
		return "Syntax: headers INDEX\n";
				
	}
				
	# retrieve message information
	
	my $message = GetMessageInfo($input->[1]);
				
	# message does not exist
	
	unless (defined $message) {
				
		return "Unable to retrieve message information\n";
				
	}
				
	# return message headers
	
	return sprintf "Displaying headers for message %d\n\n%s\n\n",
		$input->[1],
		$message->{'headers'}
	;			

}

# previous page

sub HandlePrevious {
	
	# keep message index in bounds
	
	if ($page_start - PAGE_SIZE >= 0) {
				
		$page_start -= PAGE_SIZE;
		$page_end = $page_start + PAGE_SIZE - 1;
		$page_end = $list_size - 1 if $page_end >= $list_size;

	}
				
	# generate message listing
	
	return GenerateList();

}

# next page

sub HandleNext {

	# keep message index in bounds
	
	if ($page_start + PAGE_SIZE < $list_size) {
				
		$page_start += PAGE_SIZE;
		$page_end = $page_start + PAGE_SIZE - 1;
		$page_end = $list_size - 1 if $page_end >= $list_size;

	}

	# generate message listing

	return GenerateList();

}

# retrieve message information

sub GetMessageInfo {

	my $idx = shift;
	$idx -= 1;
	return if $idx < 0 || $idx >= $list_size;
							
	# message already cached
	
	return $info_cache{$idx}
		if defined $info_cache{$idx}
	;
	
	# retrieve message from server
	
	my $message;
				
	eval {
				
		$message = $p->get_message_info($user_id, $messages->[$idx]->{'id'});
				
	};
				
	# catch
	
	if ($@) {
				
		return;
				
	}
	
	# set cache and return message
	
	$info_cache{$idx} = $message;

}

# generate message listing

sub GenerateList {

	my $output .= sprintf "\n%-3s %-5s %-20s %-20s %-27s\n",
		'ID',
		'Date',
		'Recipient',
		'Sender',
		'Subject'
	;
			
	for my $idx ($page_start..$page_end) {
			
		$output .= sprintf "%2d) %5s %-20s %-20s %-27s\n",
			$idx + 1,
			$messages->[$idx]->{'date'},
			substr ($messages->[$idx]->{'recipient'}, 0, 20),
			substr ($messages->[$idx]->{'sender'}, 0, 20),					
			substr ($messages->[$idx]->{'subject'}, 0, 27)
		;
	
	}
			
	$output .= "\n";
	$output;
	
}

__END__

=head1 NAME

pshell.pl - Interactive shell to interact with Postini email filtering service

=head1 SYNOPSIS

  perl pshell.pl

=head1 DESCRIPTION

This script is intended to demonstrate the capabilities of WWW::Postini via
an interactive shell.

=head1 COMMANDS

=over 4

=item C<help>

Display help

=item C<quit>

Exit shell

=item C<user EMAIL>

Sets the quarantine context to that of C<EMAIL>.  This step must be successfully
completed before the commands below.

=item C<list>

List quarantined messages, one page at a time

The C<next> and C<prev> commands may be used to navigate through the paged
data.  Abbreviated commands of C<n> and C<p> are also accepted.

=item C<headers INDEX>

Show header information for message number C<INDEX>

=item C<body INDEX>

Show body of message number C<INDEX>

=item C<attach INDEX>

Show attachments of message number C<INDEX>

=item C<delete INDEX>

Delete message number C<INDEX>.  To see this change reflected in the message
listing, please issue a new C<list> command.

=item C<release INDEX>

Process message number C<INDEX>, releasing it to the original recipient and
marking the message as delivered.  To see this change reflected in the message
listing, please issue a new C<list> command.

=back

=head1 SAMPLE SESSION

Below is a sample session to better illustrate to use of this shell.

  WWW::Postini Shell 0.01 - Use 'help' for command syntax

  Login: admin@company.com
  Password: password
  Login successful
  Command: user quarantine@company.com
  User ID set to 12345678
  Command: list

  ID  Date  Recipient            Sender               Subject                    
   1) 05-04 user1@company.com    user1@sender.com     Fw: Check this out
   2) 05-03 postmaster@company.c postmaster@sender.co DELIVERY FAILURE: User foo
   3) 05-04 user2@company.com    user2@sender.com     New version of software

  Listing messages (1 - 3 of 3): delete 1
  Message deleted
  Listing messages (1 - 3 of 3): list

  ID  Date  Recipient            Sender               Subject                    
   1) 05-03 postmaster@company.c postmaster@sender.co DELIVERY FAILURE: User foo
   2) 05-04 user2@company.com    user2@sender.com     New version of software

  Listing messages (1 - 2 of 2): release 2
  Message released
  Listing messages (1 - 2 of 2): list

  ID  Date  Recipient            Sender               Subject                    
   1) 05-03 postmaster@company.c postmaster@sender.co DELIVERY FAILURE: User foo

  Listing messages (1 - 1 of 1): quit
  Goodbye!

=head1 SEE ALSO

L<WWW::Postini>

=head1 AUTHOR

Peter Guzis, E<lt>pguzis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Peter Guzis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Postini, the Postini logo, Postini Perimeter Manager and preEMPT are
trademarks, registered trademarks or service marks of Postini, Inc. All
other trademarks are the property of their respective owners.

=cut