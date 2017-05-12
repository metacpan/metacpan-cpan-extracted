package TinyAuth;

=pod

=head1 NAME

TinyAuth - Extremely light-weight web-based authentication manager

=head1 STATUS

TinyAuth is currently currently feature-complete and undergoing polishing
and testing. Part of this process focuses on naming ("TinyAuth" is just
a working codename), reduction of dependencies, improvements to the
installer, and other similar tasks.

Releases are provided "as is" for the curious, and installation is not
recommended for production purposes at this time.

=head1 DESCRIPTION

B<TinyAuth> is a light-weight authentication management web application
with a focus on usability.

It was initially created to assist in managing a subversion repository but
also usable for anything where authentication can be run from a F<.htpasswd>
file.

It provides the basic functionality needed for adding and removing
users, and handling password maintenance with as little code and fuss
as possible, while still applying robust and correct security practices.

It is intended to be extremely easy to install and set up, even on shared
hosting accounts. The interface is so simple and pages are so small
(most under 1k) that it can be used on most limited-functionality browsers
such as the text-mode browsers, and the strange micro-browsers found inside
video games and mobile phones.

The goal is to allow users and be added, removed and fixed from
anywhere, even without a computer or "regular" internet connection.

=head2 Installing TinyAuth

B<TinyAuth> uses an installation module called L<Module::CGI::Install>.

The process involves firstly installing the TinyAuth distribution to your
(Unix, CGI-capable) system via the normal CPAN client, and then running a
"CGI Installer" program, which will install a working instance of the
application to a specific CGI path.

As well ensuring that the CGI setup is correct, this also means that
TinyAuth can be installed multiple times on a single host, any each copy
can be tweaked or modded as much as you like, without impacting any other
users.

At the present time, you will need the ability to install modules from CPAN
(which generally means root access) but once the application itself is
finished, additional improvements are planned to the installer to allow for
various alternative installation methods.

B<Step 1>

Install TinyAuth with your CPAN client

  adam@svn:~/svn.ali.as$ sudo cpan -i TinyAuth

B<Step 2>

Run the CGI installation, following the prompts

  adam@svn:~/svn.ali.as$ cgi_install TinyAuth
  CGI Directory: [default /home/adam/svn.ali.as] cgi-bin
  CGI URI: http://svn.ali.as/cgi-bin
  adam@svn:~/svn.ali.as$

The installation is currently extremely crude, so once installed, you
currently need to open the tinyauth.conf file created by the installer
and edit it by hand (this will be fixed in a forthcoming release).

The config file is YAML and should look something like this:

  adam@svn:~/svn.ali.as$ cat cgi-bin/tinyauth.conf
  ---
  email_from: adamk@cpan.org
  email_driver: SMTP
  htpasswd: /home/adam/svn.ali.as/cgi-bin/.htpasswd
  
  adam@svn:~/svn.ali.as$

(For the security concious amoungst you, yes I know that putting the
.htpasswd there is a bad idea. No, no real service is actually using
that file)

The C<email_driver> value is linked to L<Email::Send>. Use either
"Sendmail" to send via local sendmail, or "SMTP" to send via an SMTP
server on localhost.

=cut

use 5.005;
use strict;
use File::Spec           ();
use Scalar::Util         ();
use YAML::Tiny           ();
use CGI                  ();
use Authen::Htpasswd     ();
use Email::MIME          ();
use Email::MIME::Creator ();
use Email::Send          ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.98';
}





#####################################################################
# Embedded Functions

# Params::Util::_STRING
sub _STRING ($) {
	(defined $_[0] and ! ref $_[0] and length($_[0])) ? $_[0] : undef;
}

# Params::Util::_ARRAY
sub _ARRAY ($) {
	(ref $_[0] eq 'ARRAY' and @{$_[0]}) ? $_[0] : undef;
}

# Params::Util::_INSTANCE
sub _INSTANCE ($$) {
	(Scalar::Util::blessed($_[0]) and $_[0]->isa($_[1])) ? $_[0] : undef;
}






#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check and set the config
	unless ( _INSTANCE($self->config, 'YAML::Tiny') ) {
		Carp::croak("Did not provide a config param");
	}

	# Create the htpasswd shadow
	unless ( $self->auth ) {
		# Check for a htpasswd value
		unless ( $self->htpasswd ) {
			Carp::croak("No htpasswd file provided");
		}
		unless ( -r $self->htpasswd ) {
			Carp::croak("No permission to read htpasswd file");
		}
		unless ( -w $self->htpasswd ) {
			Carp::croak("No permission to write htpasswd file");
		}
		$self->{auth} = Authen::Htpasswd->new( $self->htpasswd );
	}
	unless ( _INSTANCE($self->auth, 'Authen::Htpasswd') ) {
		 Carp::croak("Failed to create htpasswd object");
	}

	# Create the mailer
	unless ( $self->email_from ) {
		Carp::croak("No email_from address in config file");
	}
	unless ( $self->mailer ) {
		$self->{mailer} = Email::Send->new( {
			mailer => $self->email_driver,
			} );
	}
	unless ( _INSTANCE($self->mailer, 'Email::Send') ) {
		Carp::croak("Failed to create mailer");
	}

	# Set the header
	unless ( $self->header ) {
		$self->{header} = CGI::header( 'text/html' );
	}

	# Set the page title
	unless ( $self->title ) {
		$self->{title} ||= $self->config->[0]->{title};
		$self->{title} ||= __PACKAGE__ . ' ' . $VERSION;
	}

	# Set the homepage
	unless ( $self->homepage ) {
		$self->{homepage} ||= $self->config->[0]->{homepage};
		$self->{homepage} ||= 'http://search.cpan.org/perldoc?TinyAuth';
	}

	# Set the CGI object
	unless ( _INSTANCE($self->cgi, 'CGI') ) {
		$self->{cgi} = CGI->new;
	}

	# Determine the action
	unless ( $self->action ) {
		$self->{action} = $self->cgi->param('a') || '';
	}

	# Set the base arguments
	$self->{args} ||= {
		CLASS       => ref($self),
		VERSION     => $self->VERSION,
		SCRIPT_NAME => $ENV{SCRIPT_NAME},
		HOMEPAGE    => $self->homepage,
		TITLE       => $self->title,
		DOCTYPE     => $self->html__doctype,
		HEAD        => $self->html__head,
	};

	# Apply security policy
	my ($username, $password) = ();
	if ( $self->cgi->param('E') or $self->cgi->param('P') ) {
		$username = $self->cgi->param('E');
		$password = $self->cgi->param('P');
		$self->{user} = $self->authenticate( $username, $password );
	} elsif ( $self->cgi->cookie('e') and $self->cgi->cookie('p') ) {
		$username = $self->cgi->cookie('e');
		$password = $self->cgi->cookie('p');
		$self->{user} = $self->lookup_user( $username, $password );
		if ( $self->{user} and ! $self->{user}->check_password($password) ) {
			$self->{action} = 'o';
		}
	} else {
		delete $self->{user};
	}
	if ( ref $self->{user} ) {
		unless ( $self->is_user_admin($self->{user}) ) {
			$self->error('Only administrators are allowed to do that');
		}

		# Authenticated ok, set the cookies
		$self->{header} = CGI::header(
			-cookie => [
				CGI::cookie(
					-name    => 'e',
					-value   => $username,
					-path    => '/',
					-expires => '+1d',
				),
				CGI::cookie(
					-name    => 'p',
					-value   => $password,
					-path    => '/',
					-expires => '+1d',
				),
			],
		);

	} else {
		delete $self->{user};
	}

	return $self;
}

sub config_file {
	$_[0]->{config_file};
}

sub config {
	$_[0]->{config};
}

sub cgi {
	$_[0]->{cgi};
}

sub auth {
	$_[0]->{auth};
}

sub mailer {
	$_[0]->{mailer};
}

sub user {
	$_[0]->{user};
}

sub action {
	$_[0]->{action};
}

sub header {
	$_[0]->{header};
}

sub title {
	$_[0]->{title};
}

sub homepage {
	$_[0]->{homepage};
}

sub args {
	return { %{$_[0]->{args}} };
}

sub htpasswd {
	$_[0]->config->[0]->{htpasswd};
}

sub email_from {
	$_[0]->config->[0]->{email_from};
}

sub email_driver {
	$_[0]->config->[0]->{email_driver} || 'Sendmail';
}





#####################################################################
# Main Methods

sub run {
	my $self = shift;
	return 1 if $self->action eq 'error';

	return $self->action_logout  if $self->action eq 'o';
	return $self->view_forgot    if $self->action eq 'f';
	return $self->action_forgot  if $self->action eq 'r';
	return $self->view_change    if $self->action eq 'c';
	return $self->action_change  if $self->action eq 'p';
	return $self->view_new       if $self->action eq 'n';
	return $self->action_new     if $self->action eq 'a';
	return $self->view_list      if $self->action eq 'l';
	return $self->view_promote   if $self->action eq 'm';
	return $self->action_promote if $self->action eq 'b';
	return $self->view_delete    if $self->action eq 'd';
	return $self->action_delete  if $self->action eq 'e';

	return $self->view_index;
}

# Cloned and simplified from String::MkPasswd
sub mkpasswd {
	my @upper = ( 'A' .. 'Z' );
	my @lower = ( 'a' .. 'z' );
	my @nums  = ( 0   .. 9   );
	my @spec  = (
		qw| ^ & * ( ) - = _ + [ ] { } \ ; : < > . ? / |,
		",", "|", '"', "'",
	);

	# Assemble the password characters
	my @password = ();
	push @password, map { $upper[int rand $#upper] } (0..1);
	push @password, map { $spec[ int rand $#spec ] } (0..1);
	push @password, map { $nums[ int rand $#nums ] } (0..1);
	push @password, map { $lower[int rand $#lower] } (0..4);

	# Join the characters to get the final password
	return join( '', sort { rand(1) <=> rand(1) } @password );
}
# Inlined from Email::Stuff
sub send_email {
	my $self   = shift;
	my %params = @_;

	# Create the email
	my $email  = Email::MIME->create(
		header => [
			to      => $params{to},
			from    => $self->email_from,
			subject => $params{subject},
		],
		parts  => [
			Email::MIME->create(
				attributes => {
					charset      => 'us-ascii',
					content_type => 'text/plain',
					format       => 'flowed',
				},
				body => $params{body},
			),
		],
	);

	# Send the email
	$self->mailer->send( $email );

	return 1;
}





#####################################################################
# Main Methods

# The front page
sub view_index {
	my $self = shift;
	$self->print_template(
		$self->user
			? $self->html_index
			: $self->html_public
	);
	return 1;
}

# Logout
sub action_logout {
	my $self = shift;

	# Set the user/pass cookies to null
	$self->{header} = CGI::header(
		-cookie => [
			CGI::cookie(
				-name    => 'e',
				-value   => '0',
				-path    => '/',
				-expires => '-1y',
			),
			CGI::cookie(
				-name    => 'p',
				-value   => '0',
				-path    => '/',
				-expires => '-1y',
			),
		],
	);

	# Clear the current user
	delete $self->{user};
	
	# Return to the index page
	return $self->view_index;
}

# Show the "I forgot my password" form
sub view_forgot {
	my $self = shift;
	$self->print_template(
		$self->html_forgot,
	);
	return 1;
}

# Re-issue a password
sub action_forgot {
	my $self  = shift;
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}

	# Does the account exist
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# Create the new password
	my $password = $self->mkpasswd;
	$user->password($password);
	$self->auth->update_user($user);
	$self->{args}->{password} = $password;

	# Send the password email
	$self->send_forgot( $user );

	# Show the "password email sent" page
	$self->view_message("Password email sent");
}

sub send_forgot {
	my ($self, $user) = @_;
	$self->send_email(
		to      => $user->username,
		subject => '[TinyAuth] Forgot Your Password',
		body    => $self->template(
			$self->email_forgot,
		),
	);
}

sub view_list {
	my $self = shift;
	$self->admins_only or return 1;

	# Prepare the user list
	my @users = $self->all_users;
	my $list  = '';
	foreach my $user ( @users ) {
		my $item = $self->cgi->escapeHTML($user->username);
		if ( $self->is_user_admin($user) ) {
			$item = $self->cgi->b($item);
		}
		$list .= $item . $self->cgi->br . "\n";
	}

	# Show the page
	$self->{args}->{users} = $list;
	$self->print_template(
		$self->html_list,
	);
	return 1;
}

sub view_promote {
	my $self = shift;
	$self->admins_only or return 1;
	$self->{args}->{users} = $self->user_checkbox_list;
	$self->print_template(
		$self->html_promote,
	);
}

sub action_promote {
	my $self = shift;
	$self->admins_only or return 1;

	# Which accounts are we promoting
	my @accounts = $self->cgi->param('e');
	unless ( @accounts ) {
		return $self->error("You did not select an account");
	}

	# Check all the proposed promotions first
	my @users = ();
	foreach ( @accounts ) {
		my $account = _STRING($_);
		unless ( $account ) {
			return $self->error("Missing, invalid, or corrupt email address");
		}

		# Does the account exist
		my $user = $self->auth->lookup_user($account);
		unless ( $user ) {
			return $self->error("The account does not exist");
		}

		# We can't operate on admins
		if ( $self->is_user_admin($user) ) {
			return $self->error("You cannot control an admin account '$account'");
		}

		push @users, $user;
	}

	# Apply the promotions and send mails
	foreach my $user ( @users ) {
		$user->extra_info('admin');

		# Send the promotion email
		$self->{args}->{email} = $user->username;
		$self->send_promote($user);
	}

	# Show the "Promoted ok" page
	return $self->view_message(
		join( "\n", map {
			"Promoted account " . $_->username . " to admin"
		} @users )
	);
}

sub send_promote {
	my ($self, $user) = @_;
	$self->send_email(
		to      => $user->username,
		subject => '[TinyAuth] You have been promoted to admin',
		body    => $self->template(
			$self->email_promote,
		),
	);
}

sub view_delete {
	my $self = shift;
	$self->admins_only or return 1;
	$self->{args}->{users} = $self->user_checkbox_list;
	$self->print_template(
		$self->html_delete,
	);
}

sub action_delete {
	my $self = shift;
	$self->admins_only or return 1;

	# Which accounts are we deleting
	my @accounts = $self->cgi->param('e');
	unless ( @accounts ) {
		return $self->error("You did not select an account");
	}

	# Check all the proposed promotions first
	my @users = ();
	foreach ( @accounts ) {
		my $account = _STRING($_);
		unless ( $account ) {
			return $self->error("Missing, invalid, or corrupt email address");
		}

		# Does the account exist
		my $user = $self->auth->lookup_user($account);
		unless ( $user ) {
			return $self->error("The account '$account' does not exist");
		}

		# We can't operate on admins
		if ( $self->is_user_admin($user) ) {
			return $self->error("You cannot control admin account '$account'");
		}

		push @users, $user;
	}

	# Delete the accounts
	foreach my $user ( @users ) {
		$self->auth->delete_user($user);
	}

	# Show the "Deleted ok" page
	return $self->view_message(
		join( "\n", map {
			"Deleted account " . $_->username
		} @users )
	);
}

sub view_change {
	my $self = shift;
	$self->print_template(
		$self->html_change,
	);
	return 1;
}

sub action_change {
	my $self  = shift;
	my $user  = $self->authenticate(
		$self->cgi->param('e'),
		$self->cgi->param('p'),
	);

	# Check the new password
	my $new = _STRING($self->cgi->param('n'));
	unless ( $new ) {
		return $self->error("Did not provide a new password");
	}
	my $confirm = _STRING($self->cgi->param('c'));
	unless ( $confirm ) {
		return $self->error("Did not provide a confirmation password");
	}
	unless ( $new eq $confirm ) {
		return $self->error("New password and confirmation do not match");
	}

	# Set the new password
	$user->set('password' => $new);

	return $self->view_message("Your password has been changed");
}

sub view_new {
	my $self = shift;
	$self->admins_only or return 1;
	$self->print_template(
		$self->html_new,
	);
	return 1;
}

sub action_new {
	my $self = shift;
	$self->admins_only or return 1;

	# Get the new user
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}

	# Does the account exist
	if ( $self->auth->lookup_user($email) ) {
		return $self->error("That account already exists");
	}

	# Create the new password
	my $password = $self->mkpasswd;
	$self->{args}->{email}    = $email;
	$self->{args}->{password} = $password;

	# Add the user
	my $user = Authen::Htpasswd::User->new($email, $password);
	$self->auth->add_user($user);

	# Send the new user email
	$self->send_new($user);

	# Print the "added" message
	return $self->view_message("Added new user $email");
}

sub send_new {
	my ($self, $user) = @_;
	$self->send_email(
		to      => $user->username,
		subject => '[TinyAuth] Created new account',
		body    => $self->template(
			$self->email_new,
		),
	);
}

sub view_message {
	my $self = shift;
	$self->{args}->{message} = CGI::escapeHTML(shift);
	$self->{args}->{message} =~ s/\n/<br \/>/g;
	$self->print_template(
		$self->html_message,
	);
	return 1;
}

sub error {
	my $self = shift;
	$self->{args}->{error} = shift;
	$self->print_template(
		$self->html_error,
	);
	$self->{action} = 'error';
	return 1;
}





#####################################################################
# Support Functions

sub print {
	my $self = shift;
	if ( defined $self->header ) {
		# Show the page header if this is the first thing
		CORE::print( $self->header );
		$self->{header} = undef;
	}
	CORE::print( @_ );
}

sub template {
	my $self = shift;
	my $html = shift;
	my $args = shift || $self->args;
	# Allow up to 10 levels of recursion
	foreach ( 0 .. 10 ) {
		$html =~ s/\[\%\s+(\w+)\s+\%\]/$args->{$1}/g;
	}
	return $html;
}

sub print_template {
	my $self = shift;
	$self->print(
		$self->template( @_ )
	);
	return 1;
}

sub is_user_admin {
	my $self = shift;
	my $user = shift;
	my $info = $user->extra_info;
	return !! ( _ARRAY($info) and $info->[0] eq 'admin' );
}

sub all_users {
	my $self = shift;
	my @list = map { $_->[0] }
		sort {
			$b->[2] <=> $a->[2] # Admins first
			or
			$a->[1] cmp $b->[1] # Then by username
		}
		map { [ $_, $_->username, $self->is_user_admin($_) ] }
		$self->auth->all_users;
	return @list;
}

sub lookup_user {
	my ($self, $email, $password) = @_;

	# Check params
	unless ( defined _STRING($email) ) {
		return $self->error("Missing or invalid email address");
	}
	unless ( defined _STRING($password) ) {
		return $self->error("Missing or invalid password");
	}

	# Does the account exist
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	return $user;
}

sub authenticate {
	my $self = shift;
	my $user = $self->lookup_user(@_);
	return $user unless $user;

	# Get and check the password
	unless ( $user->check_password($_[1]) ) {
		sleep 3;
		return $self->error("Incorrect password");
	}

	return $user;
}

sub admins_only {
	my $self  = shift;
	my $admin = $_[0] ? shift : $self->{user};
	unless ( $admin and $self->is_user_admin($admin) ) {
		$self->error("Only administrators are allowed to do that");
		return 0;
	}
	return 1;
}

sub user_checkbox_list {
	my $self = shift;

	# Prepare the user list
	my $list  = '';
	foreach my $user ( $self->all_users ) {
		my $item = $self->cgi->escapeHTML($user->username);
		if ( $self->is_user_admin($user) ) {
			$list .= $self->cgi->b(
				$self->cgi->checkbox(
					-name     => '_',
					-value    => $user->username,
					-checked  => undef,
					-disabled => undef,
					-label    => $user->username,
				)
			);
		} else {
			$list .= $self->cgi->checkbox(
				-name     =>  'e',
				-value    => $user->username,
				-label    => $user->username,
			);
		}
		$list .= $self->cgi->br . "\n";
	}

	return $list;
}





#####################################################################
# Pages





sub html__doctype { <<'END_HTML' }
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
END_HTML





sub html__head { <<'END_HTML' }
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>[% TITLE %]</title>
</head>
END_HTML






sub html_public { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>User</h2>
<p><a href="[% SCRIPT_NAME %]?a=f">I forgot my password</a></p>
<p><a href="[% SCRIPT_NAME %]?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<form method="post" name="f" action="[% SCRIPT_NAME %]">
<p>Email</p>
<p><input type="text" name="E" size="30"></p>
<p>Password</p>
<p><input type="password" name="P" size="30"></p>
<p><input type="submit" name="s" value="Login"></p>
</form>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
END_HTML





sub html_index { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>User</h2>
<p><a href="[% SCRIPT_NAME %]?a=f">I forgot my password</a></p>
<p><a href="[% SCRIPT_NAME %]?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<p><a href="[% SCRIPT_NAME %]?a=n">Add a new account</a></p>
<p><a href="[% SCRIPT_NAME %]?a=l">List all accounts</a></p>
<p><a href="[% SCRIPT_NAME %]?a=d">Delete an account</a></p>
<p><a href="[% SCRIPT_NAME %]?a=m">Promote an account</a></p>
<p><a href="[% SCRIPT_NAME %]?a=o">Logout</a></p>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
END_HTML





sub html_forgot { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>You don't know your password</h2>
<form method="post" name="f" action="[% SCRIPT_NAME %]">
<input type="hidden" name="a" value="r">
<p>I can't tell you what your current password is, but I can send you a new one.</p>
<p>&nbsp;</p>
<p>Email Address</p>
<p><input type="text" name="e" size="30"></p>
<p><input type="submit" name="s" value="Email me a new password"></p>
</form>
</body>
</html>
END_HTML





sub html_change { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>You want to change your password</h2>
<p>I just need to know a few things to do that</p>
<form method="post" name="f">
<input type="hidden" name="a" value="p">
<table border="0" cellpadding="0" cellspacing="0">
<tr><td>
<p>What is your email address?</p>
<p>What is your current password?</p>
<p>Type in the new password you want&nbsp;&nbsp;</p>
<p>Type it again to prevent mistakes</p>
</td><td>
<p><input type="text" name="e" size="30"></p>
<p><input type="password" name="p" size="30"></p>
<p><input type="password" name="n" size="30"></p>
<p><input type="password" name="c" size="30"></p>
</td></tr>
</table>
<p>Hit the button when you are ready to go <input type="submit" name="s" value="Change my password"></p>
</form>
<script language="JavaScript">
document.f.e.focus();
</script>
</body>
</html>
END_HTML





sub html_list { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Account List</h2>
[% users %]
</body>
</html>
END_HTML





sub html_promote { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Select Account(s) to Promote</h2>
<form name="f" action="[% SCRIPT_NAME %]">
<input type="hidden" name="a" value="b">
[% users %]
<input type="submit" name="s" value="Promote">
</form>
</body>
</html>
END_HTML





sub html_delete { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Select Account(s) to Delete</h2>
<form name="f" action="[% SCRIPT_NAME %]">
<input type="hidden" name="a" value="e">
[% users %]
<input type="submit" name="s" value="Delete">
</form>
</body>
</html>
END_HTML





sub html_new { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Admin - Add a new user</h2>
<form method="post" name="f">
<input type="hidden" name="a" value="a">
<p>Email</p>
<p><input type="text" name="e" size="30"></p>
<p><input type="submit" name="s" value="Add New User"></p>
</form>
</body>
</html>
END_HTML





sub html_message { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h1>Action Completed</h1>
<h2>[% message %]</h2>
</body>
</html>
END_HTML





sub html_error { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h1>Error</h1>
<h2>[% error %]</h2>
</body>
</html>
END_HTML





sub email_forgot { <<'END_TEXT' }
Hi

You forgot your password, so here is a new one

Password: [% password %]

Have a nice day!
END_TEXT





sub email_new { <<'END_TEXT' }
Hi

A new account has been created for you

Email:    [% email %]
Password: [% password %]

Have a nice day!
END_TEXT





sub email_promote { <<'END_TEXT' }
Hi

Your account ([% email %]) has been promoted to an administrator.

You can now login to TinyAuth to get access to additional functions.

Have a nice day!
END_TEXT

1;

=pod

=head1 SUPPORT

For all issues, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<CGI::Capture>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
