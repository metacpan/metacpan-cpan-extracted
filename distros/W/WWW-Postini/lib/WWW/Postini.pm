package WWW::Postini;

use strict;
use warnings;

use WWW::Postini::Assert;
use WWW::Postini::Exception::LoginFailure;
use WWW::Postini::Exception::InvalidParameter;
use WWW::Postini::Exception::UnexpectedResponse;
use WWW::Postini::UserAgent;
use WWW::Postini::Constants ':all';

use HTML::TokeParser;
use HTTP::Request;
use HTTP::Status;

use vars '$VERSION';

use constant DEFAULT_LOGIN_HOST   => 'login.postini.com';

use constant QUARANTINE_PAGE_SIZE => 1000;

use constant LOG_IN_TITLE         => 'Log in';
use constant CHOOSE_SESSION_TITLE => 'Choose Session Type';
use constant ADMIN_TITLE          => 'System Administration';

$VERSION = '0.01';

#################
## constructor ##
#################

sub new {

	my $class = shift;
	my $self = bless {}, $class;
	$self->_init(@_);
	$self;

}

#################
## initializer ##
#################

sub _init {
	
	my $self = shift;

	if (@_) {

		$self->login_host(shift);
		
	} else {
	
		$self->{'_login_host'} = DEFAULT_LOGIN_HOST;
	
	}
	
	$self->{'_user_agent'} = new WWW::Postini::UserAgent();
	return;
	
}

######################
## accessor methods ##
######################

# user agent

sub user_agent {

	my $self = shift;
	
	if (@_) {
	
		$self->{'_user_agent'} = shift;
	
	}
	
	return $self->{'_user_agent'} if defined wantarray;	

}

# login host

sub login_host {
	
	my $self = shift;
	
	if (@_) {
		
		$self->{'_login_host'} = shift;
		
	}
	
	return $self->{'_login_host'} if defined wantarray;
	
}

# admin host

sub admin_host {
	
	my $self = shift;
	
	if (@_) {
		
		$self->{'_admin_host'} = shift;
		
	}
	
	return $self->{'_admin_host'} if defined wantarray;
	
}

#####################
## utility methods ##
#####################

# login

sub login {
	
	my $self = shift;
	
	throw WWW::Postini::Exception::InvalidParameter('Email address not specified')
		unless defined $_[0] && length $_[0]
	;
	throw WWW::Postini::Exception::InvalidParameter('Password not specified')
		unless defined $_[1] && length $_[1]
	;
	
	my $email_address = shift;
	my $password = shift;
	my $response;
	
	# try
	
	eval {
	
		# attempt to log in
		
		$response = $self->{'_user_agent'}->get(
			"https://$self->{'_login_host'}/exec/login?"
			."email=$email_address"
			."&pword=$password"
			."&action=login"
		);

		assert($response, 'Response returned');

		my $code = $response->code();		
		assert($code == RC_OK, 'Response code is '.RC_OK);

		my $content = $response->content();	
		my $p = new HTML::TokeParser(\$content);

		# determine title
		
		my $tag = $p->get_tag('title');
		assert($tag, 'Title tag exists');
		
		my $token = $p->get_token();
		assert($token, 'Token exists');		
		assert($token->[0] eq 'T', 'Token is text');
		assert(
			$token->[1] eq LOG_IN_TITLE || $token->[1] eq CHOOSE_SESSION_TITLE,
			'Title recognized'
		);
		
		# log in
		
		if ($token->[1] eq LOG_IN_TITLE) {

			$tag = $p->get_tag('br');
			assert($tag, 'Break tag exists');
			
			$tag = $p->get_tag('b');
			assert($tag, 'Bold tag exists');
			
			my $text = $p->get_trimmed_text();
			assert($text, 'Bold has text');

			throw WWW::Postini::Exception::LoginFailure($text);

		# choose session (transfer phase)
		
		} elsif ($token->[1] eq CHOOSE_SESSION_TITLE) {
	
			$tag = $p->get_tag('a');
			assert($tag, 'Administration link exists');
			assert($tag->[1]->{'href'}, 'Administration URL defined');

			# make certain user is administrator
			
			my $text = $p->get_trimmed_text();
			assert($text eq ADMIN_TITLE, 'User is administrator');
			
			# determine administration host
			
			my $url = $tag->[1]->{'href'};
			my ($admin_host) = $url =~ m!^https?://(.+?)/!;
			assert($admin_host, 'Administration site determined');
			$self->{'_admin_host'} = $admin_host;
									
			# send transfer code
			
			$response = $self->{'_user_agent'}->get($url);
			
			assert($response, 'Response returned');
		
			$code = $response->code();
			assert($code == RC_OK, 'Response code is '.RC_OK);

		}
		
	};
	
	# catch
	
	if (defined $@ && (length $@ || ref $@)) {

		if (UNIVERSAL::isa($@, 'WWW::Postini::Exception::LoginFailure')) {

			$@->rethrow();
			
		} else {

			throw WWW::Postini::Exception::UnexpectedResponse($@);
		
		}
		
	}

	return 1;
	
}

# get user id

sub get_user_id {
	
	my $self = shift;
	
	throw WWW::Postini::Exception::InvalidParameter('Email address not specified')
		unless defined $_[0] && length $_[0]
	;
	
	my $email_address = shift;
	my ($response, $user_id);
	
	# try
	
	eval {
	
		# avoid automatic redirect so user id can be ascertained
		
		$response = $self->{'_user_agent'}->simple_request(new HTTP::Request (
			GET =>
				'https://'
				.$self->{'_admin_host'}
				.'/exec/adminstart?'
				.'action=user_shortcut'
				."&targetAddress=$email_address"
				.'&next_action=Quarantine'
		));
		
		assert($response, 'Response returned');
		
		my $code = $response->code();
		assert($code == RC_FOUND, 'Response code is '.RC_FOUND);

		my $location = $response->headers->header('location');
		assert($location, 'Location defined');

		($user_id) = $location =~ /targetuserid=(\d+)/;
		assert($user_id, 'User ID defined');
		
	};
	
	# catch
	
	if (defined $@ && (length $@ || ref $@)) {

		if (UNIVERSAL::isa($@, 'WWW::Postini::Exception::UnexpectedResponse')) {

			$@->rethrow();
			
		} else {

			throw WWW::Postini::Exception::UnexpectedResponse($@);
		
		}
		
	}

	$user_id;
	
}

# list messages messages from quarantine

sub list_messages {
	
	my $self = shift;
	my %args;
	
	# handle arguments
	
	if (@_) {
		
		# hash reference
		
		if (defined $_[0] && UNIVERSAL::isa($_[0], 'HASH')) {
		
			%args = %{$_[0]};
		
		# single parameter (user id)
	
		} elsif (@_ == 1) {
			
			$args{'user_id'} = shift;
		
		# array of key/value pairs
		
		} else {
		
			%args = @_;
		
		}
		
	}

	# require user id parameter
	
	throw WWW::Postini::Exception::InvalidParameter ('User ID not specified')
		unless defined $args{'user_id'} && length $args{'user_id'}
	;
	
	# set argument defaults
	
	$args{'show'} = SHOW_ALL unless defined $args{'show'};
	$args{'sort'} = SORT_NONE unless defined $args{'sort'};
	
	# define which messages will be shown
	
	my $show;
	
	if ($args{'show'} == SHOW_ALL) {
		
		$show = 'all';		
		
	} elsif ($args{'show'} == SHOW_QUARANTINED) {
		
		$show = 'visible';
		
	} elsif ($args{'show'} == SHOW_DELIVERED) {
		
		$show = 'delivered';
		
	} elsif ($args{'show'} == SHOW_DELETED) {
		
		$show = 'deleted';
	
	} else {
			
		throw WWW::Postini::Exception::InvalidParameter(
			'Invalid "show" parameter specified'
		);
		
	}

	# define sort method
	
	my $sort;
	
	if ($args{'sort'} == SORT_NONE) {
	
		$sort = '';
		
	} elsif ($args{'sort'} == SORT_RECIPIENT) {
		
		$sort = 'recip';
		
	} elsif ($args{'sort'} == SORT_SENDER) {
		
		$sort = 'sender';
		
	} elsif ($args{'sort'} == SORT_SUBJECT) {
		
		$sort = 'subject';
		
	} elsif ($args{'sort'} == SORT_FILTER) {
	
		$sort = 'block';
	
	}	else {

		throw WWW::Postini::Exception::InvalidParameter(
			'Invalid "sort" parameter specified'
		);
		
	}
	
	my $base_url = "https://$self->{'_admin_host'}/exec/admin_users?"
		."targetuserid=$args{'user_id'}"
		.'&action=display_Quarantine'
	;
	
	my %url_params = (
		pagesize => QUARANTINE_PAGE_SIZE,
		msgtype  => $show,
		msgsort  => $sort
	);
	
	# search for recipient
	
	$url_params{'filterRecip'} = $args{'recipient'}
		if defined $args{'recipient'}
	;	
	
	# search for sender
	
	$url_params{'filterSender'} = $args{'sender'}
		if defined $args{'sender'}
	;

	# search for subject

	$url_params{'filterSubject'} = $args{'subject'}
		if defined $args{'subject'}
	;

	# limit to specified filter

	$url_params{'filterBlock'} = $args{'filter'}
		if defined $args{'filter'}
	;
			
	my $page_number = 1;
	my @messages;

	# try
	
	eval {
		
		my $response;
		
		while (1) {

			# retrieve current page
			
			$response = $self->{'_user_agent'}->post(
				$base_url, [
					%url_params,
					firstmsg => (($page_number - 1) * QUARANTINE_PAGE_SIZE)
				]
			);
		
			assert($response, 'Response returned');
		
			my $code = $response->code();
			assert($code == RC_OK, 'Response code is '.RC_OK);

			my $content = $response->content();
			my $p = new HTML::TokeParser(\$content);	

			my ($tag, $start_range, $end_range, $total_messages);
		
			while (defined ($tag = $p->get_tag('td'))) {

				last if defined $tag->[1]->{'width'}
					&& defined $tag->[1]->{'align'}
					&& $tag->[1]->{'width'} eq '100%'
					&& $tag->[1]->{'align'} eq 'right'
				;
		
			}

			$tag = $p->get_tag('font');
			assert($tag, 'Font tag exists');
			
			my $token;
	
			while (defined ($token = $p->get_token())) {
		
				last if $token->[0] eq 'E' && $token->[1] eq 'font';

				if ($token->[0] eq 'T') {

					next unless $token->[1] =~ /\d+ - \d+ of \d+/s;

					($start_range, $end_range, $total_messages) = $token->[1] =~ /
						(\d+)	\s - \s	(\d+)
						\s of \s
						(\d+)
					/x;
					last;
			
				}
		
			}

			assert(defined ($total_messages), 'Total messages defined');
			assert(defined ($start_range), 'Start range defined');
			assert($start_range <= $total_messages, 'Valid start range');

			$tag = $p->get_tag('form');
			assert($tag, 'Form tag exists');
		
			$tag = $p->get_tag('tr');
			assert($tag, 'TR tag exists');
		
			while($tag = $p->get_tag('tr')) {
			
				next unless defined $tag->[1]->{'bgcolor'} && (
					$tag->[1]->{'bgcolor'} eq '#EEEEEE'
					|| $tag->[1]->{'bgcolor'} eq '#FFFFFF'
				);
				last unless defined $p->get_tag('font');
			
				my ($date, $recipient, $sender) = (
					$self->_get_message_field($p),
					$self->_get_message_field($p),
					$self->_get_message_field($p)
				);
			
				assert($date, 'Date defined');
				assert($recipient, 'Recipient defined');
				assert($sender, 'Sender defined');
			
				$tag = $p->get_tag('font');
				assert($tag, 'Font tag exists');
			
				$tag = $p->get_tag('a');
				assert($tag, 'Link exists');

				my $url = $tag->[1]->{'href'};
				assert($url, 'URL defined');
			
				my $subject = $p->get_trimmed_text();
				assert($subject, 'Subject defined');
			
				my $uri = (split m!\?!, $url)[1];
				assert($uri, 'URI defined');
			
				my %params;

				foreach my $pair (split /&/, $uri) {
			
					my ($key, $value) = split /=/, $pair;
					$params{$key} = $value;	
				
				}
				
				$tag = $p->get_tag('font');
				assert($tag, 'Font tag exists');
				
				my $filter = $p->get_trimmed_text();
				assert($filter, 'Filter defined');

				push @messages, {
					sender    => $sender,
					recipient => $recipient,
					subject   => $subject,
					date      => $date,
					filter    => $filter,
					id        => $params{'msgid'},
					uid       => $args{'user_id'}
				};
			
			}
			
			last if $end_range >= $total_messages;
			$page_number++;
			
		}
		
	};	
	
	# catch
	
	if (defined $@ && (length $@ || ref $@)) {

		if (UNIVERSAL::isa($@, 'WWW::Postini::Exception::UnexpectedResponse')) {

			$@->rethrow();
			
		} else {

			throw WWW::Postini::Exception::UnexpectedResponse($@);
			
		}
		
	}
	
	\@messages;

}

# get message info

sub get_message_info {
	
	my $self = shift;
	
	throw WWW::Postini::Exception::InvalidParameter('User ID not specified')
		unless defined $_[0] && length $_[0]
	;
	throw WWW::Postini::Exception::InvalidParameter('Message ID not specified')
		unless defined $_[1] && length $_[1]
	;
	
	my $user_id = shift;
	my $message_id = shift;
	my ($headers, $body, @attachments);

	eval {
		
		my $response = $self->{'_user_agent'}->get(
			"https://$self->{'_admin_host'}/exec/admin_users?"
			."targetuserid=$user_id"
			.'&action=display_Message'
			."&msgid=$message_id"
			.'&showheader=1'
		);

		assert($response, 'Response returned');
		
		my $code = $response->code();
		assert($code == RC_OK, 'Response code is '.RC_OK);

		my $content = $response->content();
		my $p = new HTML::TokeParser(\$content);

		my $tag = $p->get_tag('pre');
		assert($tag, 'PRE tag exists');

		$headers = $p->get_text();
		assert($headers, 'Headers exist');
		
		$headers =~ s/\s+$//gs;
		
		$tag = $p->get_tag('xmp');
		assert($tag, 'XMP tag exists');
		
		my $token;
		
		while (defined ($token = $p->get_token())) {
		
			# start tag
			
			if ($token->[0] eq 'S') {
			
				$body .= $token->[4];
			
			# end tag
			
			} elsif ($token->[0] eq 'E') {
			
				last if $token->[1] eq 'xmp';
				$body .= $token->[2];

			# text, comment, or declaration
			
			} elsif ($token->[0] eq 'T'
				|| $token->[0] eq 'C'
				|| $token->[0] eq 'D'
			) {
				
				$body .= $token->[1];
				
			# processing instruction
			
			} elsif ($token->[0] eq 'PI') {
			
				$body .= $token->[2];
			
			}		
		
		}
		
		$body =~ s/\s+$//sg;

		my ($text, $file);
		
		while (defined ($token = $p->get_token())) {
			
			last if $token->[0] eq 'E' && $token->[1] eq 'font';
			next unless $token->[0] eq 'T';
			
			if (($file) = $token->[1] =~ /name=\"?([^";]+?)\s*(?:"|\;|$)/s) {

				push @attachments, $file;
				
			}
			
		}				
	
	};

	# catch
	
	if (defined $@ && (length $@ || ref $@)) {

		if (UNIVERSAL::isa($@, 'WWW::Postini::Exception::UnexpectedResponse')) {

			$@->rethrow();
			
		} else {

			throw WWW::Postini::Exception::UnexpectedResponse($@);
		
		}
		
	}

	return {
		headers     => $headers,
		body        => $body,
		attachments => \@attachments	
	};

}

# delete specified messages

sub delete_messages {

	my $self = shift;
	my @message_ids;
	
	throw WWW::Postini::Exception::InvalidParameter('User ID not specified')
		unless defined $_[0] && length $_[0]
	;
	
	my $user_id = shift;
	
	# handle arguments
	
	if (@_) {
	
		# array reference
		
		if (defined $_[0] && UNIVERSAL::isa($_[0], 'ARRAY')) {
	
			@message_ids = @{$_[0]};
		
		# list of values
		
		} else {
			
			@message_ids = @_;		
		
		}
		
	}
	
	throw WWW::Postini::Exception::InvalidParameter('No messages specified')
		unless scalar @message_ids
	;
	
	my $message_count;
		
	# try
	
	eval {
		
		my @args = (
			action       => 'processQuarantine',
			targetuserid => $user_id,
			submit       => 'Delete'
		);
		
		foreach my $id (@message_ids) {
			
			push @args, ('msgid', $id);
			
		}

		my $response = $self->{'_user_agent'}->post(
			"https://$self->{'_admin_host'}/exec/admin_users",
			\@args
		);
		
		assert($response, 'Response returned');
		
		my $code = $response->code();
		assert($code == RC_OK, 'Response code is '.RC_OK);

		my $content = $response->content();
		my $p = new HTML::TokeParser(\$content);
		my ($tag, $text);
		
		while (defined ($tag = $p->get_tag('b'))) {
		
			my $text = $p->get_trimmed_text();			
			last if defined $text && $text eq 'Message Results';			
		
		}

		$tag = $p->get_tag('font');
		assert($tag, 'Font tag exists');
		
		$text = $p->get_trimmed_text();
		assert(
			$text =~ /^\d+ message\(s\) marked as deleted\./,
			'Message text recognized'
		);
		
		($message_count) = $text =~ /^(\d+)/;		
	
	};
	
	# catch
	
	if (defined $@ && (length $@ || ref $@)) {

		if (UNIVERSAL::isa($@, 'WWW::Postini::Exception::UnexpectedResponse')) {

			$@->rethrow();
			
		} else {

			throw WWW::Postini::Exception::UnexpectedResponse($@);
			
		}
		
	}
	
	$message_count;

}

# process quarantined messages

sub process_messages {

	my $self = shift;
	my %args;
	
	# handle arguments
	
	if (@_) {
	
		# array reference
		
		if (defined $_[0] && UNIVERSAL::isa ($_[0], 'HASH')) {
	
			%args = %{$_[0]};
		
		# list of values
		
		} else {
			
			%args = @_;		
		
		}
		
	}
	
	throw WWW::Postini::Exception::InvalidParameter('User ID not specified')
		unless defined $args{'user_id'} && length $args{'user_id'}
	;
	
	# set default parameters
	
	$args{'recipient'} = RECIPIENT_USER unless defined $args{'recipient'};
	$args{'mark'} = 1 unless defined $args{'mark'};
	$args{'clean'} = 1 unless defined $args{'clean'};
	
	# handle recipient parameter
	
	my $recipient;
	
	if ($args{'recipient'} == RECIPIENT_USER) {
	
		$recipient = 'user';
	
	} elsif ($args{'recipient'} == RECIPIENT_ADMIN) {
		
		$recipient = 'admin';	
	
	} else {
	
		throw WWW::Postini::Exception::InvalidParameter(
			'Invalid "recipient" parameter specified'
		);
	
	}
	
	# handle messages parameter
	
	my @message_ids;
	
	if (defined $args{'messages'}) {
	
		if (UNIVERSAL::isa ($args{'messages'}, 'ARRAY')) {
		
			@message_ids = @{$args{'messages'}};
		
		} else {
		
			@message_ids = $args{'messages'};
		
		}
	
	}
	
	# no messages passed
	
	throw WWW::Postini::Exception::InvalidParameter('No messages specified')
		unless scalar @message_ids
	;
	
	my $message_count;
	
	# try
	
	eval {
	
		my @args = (
			action       => 'processQuarantine',
			targetuserid => $args{'user_id'},
			submit       => 'Process',
			markdeliver  => ($args{'mark'} ? 1 : 0),
			preclean     => ($args{'clean'} ? 1 : 0),
			deliv_rcpt   => $recipient
		);
		
		foreach my $id (@message_ids) {
			
			push @args, ('msgid', $id);
			
		}
		
		my $response = $self->{'_user_agent'}->post(
			"https://$self->{'_admin_host'}/exec/admin_users",
			\@args
		);
		
		assert($response, 'Response returned');
		
		my $code = $response->code();
		assert($code == RC_OK, 'Response code is '.RC_OK);

		my $content = $response->content();
		my $p = new HTML::TokeParser(\$content);
		my ($tag, $text);

		while (defined ($tag = $p->get_tag('b'))) {
		
			my $text = $p->get_trimmed_text();
			last if defined $text && $text eq 'Message Results';			
		
		}
		
		$tag = $p->get_tag('font');
		assert($tag, 'Font tag exists');
		
		$text = $p->get_trimmed_text();
		assert(
			$text =~ /^\d+ message\(s\) queued for delivery/,
			'Message text recognized'
		);
		
		($message_count) = $text =~ /^(\d+)/;
	
	};
	
	# catch
	
	if (defined $@ && (length $@ || ref $@)) {

		# unexpected response
		
		if (UNIVERSAL::isa($@, 'WWW::Postini::Exception::UnexpectedResponse')) {

			$@->rethrow;
			
		# all other exceptions
		
		} else {

			throw WWW::Postini::Exception::UnexpectedResponse($@);
			
		}
		
	}
	
	$message_count;

}

# get message field

sub _get_message_field {
	
	my $self = shift;
	my $p = shift;	
	my $tag = $p->get_tag ('font');
	assert ($tag, 'Font tag exists');
	$p->get_trimmed_text;
	
}

1;

__END__

=head1 NAME

WWW::Postini - Interact with the Postini mail filtering service

=head1 SYNOPSIS

  use WWW::Postini;

  my $p = new WWW::Postini();
  $p->login($login, $password);

=head1 DESCRIPTION

This module is an attempt to provide a simple interface to the email
quarantine functionality offered by the Postini (L<http://www.postini.com/>)
mail filtering service.  Behind the scenes, this is achieved by
screen-scraping the Postini administration web site.

=head1 A NOTE ON EXCEPTIONS

Please note WWW::Postini makes extensive use of
L<Exception::Class|Exception::Class> objects for improved error handling.
Many object methods will throw (read: C<die()>) upon error with a subclass of
L<Exception::Class|Exception::Class>.

In order to properly handle such errors, it is important to enclose any calls
to this module in an C<eval{}> block.

  # try
  
  eval {
  
    my $p = new WWW::Postini();
    $p->login($email, $password);
  
  };
  
  # catch
  
  if ($@) {
  
    if (UNIVERSAL::isa($@, 'Exception::Class')) {
    
      printf "Caught an exception: %s\n", $@->as_string;
    
    } else {
    
      printf "Caught a native error: %s\n", $@;
    
    }
    
    exit;  
  
  }

For more information, please see L<Exception::Class>.  Wherever appropriate,
this document will detail which subclasses of Exception::Class may be thrown
from each method.

=head1 CONSTRUCTOR

=over 4

=item new()

=item new($host)

Creates a new instance of WWW::Postini.  If C<$host> is specified,
it is used as the object's login host, otherwise the default of
C<login.postini.com> is used.

  my $p = new WWW::Postini('login2.postini.com');

=back

=head1 OBJECT METHODS

=over 4

=item user_agent()

=item user_agent($ua)

Get or set the underlying
L<WWW::Postini::UserAgent|WWW::Postini::UserAgent> object

This method is present in case WWW::Postini needs to be subclassed or the
programmer needs access to the user agent itself for other reasons.

  my $user_agent = $p->user_agent();

=item login_host()

=item login_host($host)

Get or set login host.

The login host defaults to C<login.postini.com>, unless a host is specified in
the constructor.  Changing the login host is not necessary at this point, as
there is currently only one Postini login server.

=item admin_host()

=item admin_host($host)

Get or set administration host.

The administration host is determined automatically during the C<login()>
procedure.  Until a successful login has taken place, the value of
C<admin_host()> will be undefined.  It is not necessary to manually set the
administration host, but you may if desired.  In this case, be sure to
set C<admin_host()> after login, but before any other other methods are
called.

=item login($email,$password)

Attempt to login to the Postini mail filtering service with the credentials
C<$email> and C<$password>

On failure, this method will throw an instance of the class
L<WWW::Postini::Exception::LoginFailure|WWW::Postini::Exception::LoginFailure>
and it is up to the programmer to catch this exception.

=item get_user_id($email)

Returns the user ID of the supplied C<$email> argument.

On failure, this method will throw an instance of the class
L<WWW::Postini::Exception::UnexpectedResponse|WWW::Postini::Exception::UnexpectedResponse>.

=item list_messages($user_id)

=item list_messages(%args)

=item list_messages(\%args)

In its single-argument form, this method will retrieve a list of messages
quarantined for the specified C<$user_id>.

If this method is passed a list of key/value pairs or a hash reference, the
following keys may be used:

B<user_id> - Target user ID

B<show> - Scope of quarantine listing.

For a listing of values this parameter accepts, please see the
"Message searching" section of L<WWW::Postini::Constants>.
Defaults to C<SHOW_ALL>

B<sort> - Message sort method

For a listing of values this parameter accepts, please see the
"Message sorting" section of L<WWW::Postini::Constants>.
Defaults to C<SORT_NONE>

B<recipient> - Narrow searcg by recipient address

Only messages containing this text in the recipient field will be included
in the resulting message list.  Note: this is a partial text match.

B<sender> - Narrow search by sender address

B<subject> - Narrow search by subject

B<filter> - Narrow search by filter description

On success, this method returns an array reference populated with messages.
Each message is a hash reference formatted similar to the following:

  {
    sender    => $sender_address,
    recipient => $recipient_address,
    subject   => $subject,
    date      => $date,
    filter    => $filter_description,
    id        => $message_id,
    uid       => $user_id
  }

On failure, this method will throw a
L<WWW::Postini::Exception::UnexpectedResponse|WWW::Postini::Exception::UnexpectedResponse>
exception.

  use WWW::Postini::Constants ':show';
  
  # show only quarantined messages
  
  my $messages = $p->list_messages(
    user_id => $user_id,
    show    => SHOW_QUARANTINED    
  );
  
  print "Received the following messages\n\n";
  
  foreach my $msg (@$messages) {
  
    print "Message ID: $msg->{'id'}\n";
  
  }

=item get_message_info($user_id,$message_id)

Retrieve detailed information about the message C<$message_id> belonging
to C<$user_id>.

On sucess, a hash reference of the following format will be returned:

  {
    headers     => $header_text,
    body        => $body_text,
    attachments => [ $file1_name, $file2_name, ... ]  
  }

Note: the text returned may be truncated by Postini itself.  In addition,
C<attachments> will only contain filenames when the current message was
blocked due to a disallowed file attachment type.

On failure, this method will throw a
L<WWW::Postini::Exception::UnexpectedResponse|WWW::Postini::Exception::UnexpectedResponse>
exception.

=item delete_messages($user_id,@messages)

=item delete_messages($user_id,\@messages)

The specified C<@messages> for C<$user_id> will be marked as deleted.

On success, returns the number of messages successfully deleted.

On failure, this method will throw a
L<WWW::Postini::Exception::UnexpectedResponse|WWW::Postini::Exception::UnexpectedResponse>
exception.

=item process_messages(%args)

=item process_messages(\%args)

Process one or more messages.  The following parameters are recognized:

B<user_id> - C<$user_id>

B<recipient> - C<$recipient_value>

Specifies where to deliver message.  For appropriate values, please see
the "Message recipient" section of L<WWW::Postini::Constants>.
Defaults to C<RECIPIENT_USER>

B<mark> - C<0> or C<1>

Mark message as delivered.
Defaults to C<1>

B<clean> - C<0> or C<1>

Virus clean before delivering message.
Defaults to C<1>

On success, this method returns the number of messages processed.

On failure, this method will throw a
L<WWW::Postini::Exception::UnexpectedResponse|WWW::Postini::Exception::UnexpectedResponse>
exception.

=back

=head1 SEE ALSO

L<WWW::Postini::Base>, L<WWW::Postini::Constants>

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