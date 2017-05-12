#
# $Id: iesms.pm 350 2008-11-27 13:40:14Z mackers $

package WWW::SMS::IE::iesms;

=head1 NAME

WWW::SMS::IE::iesms - A module to send SMS messages using .ie websites

=head1 SYNOPSIS

To use a subclass:

  require WWW::SMS::IE::o2sms;

  my $carrier = new WWW::SMS::IE::o2sms;

  if ($carrier->login('o2_user', 'password'))
  {
    my $retval = $carrier->send('+353865551234', 'Hello World!');

    if (!$retval)
    {
      print $carrier->error() . "\n";
    }
  }

To extend this class:

  package WWW::SMS::IE::o2sms;
  require WWW::SMS::IE::iesms;
  @WWW::SMS::IE::o2sms::ISA = qw{WWW::SMS::IE::iesms};

=head1 DESCRIPTION

L<WWW::SMS::IE::iesms> is a module to send SMS messages via the command line
using the websites of Irish mobile operators. This is done by simulating a web
browser's interaction with those websites. This module requires a valid web
account with O2 Ireland, Vodafone Ireland or Meteor Ireland.

The L<WWW::SMS::IE::iesms> class is abstract, i.e. it is only used as a base
class for L<WWW::SMS::IE::o2sms>, L<WWW::SMS::IE::vodasms>,
L<WWW::SMS::IE::meteorsms> and L<WWW::SMS::IE::threesms> and should never be
instantiated as itself.

The following methods are available:

=over 4

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = sprintf("0.%02d", q$Revision: 350 $ =~ /(\d+)/);

#use TestGen4Web::Runner 0.04;
use File::stat;
use Storable;
use File::Basename;
use File::Temp;
use POSIX qw(ceil);
use Data::Dumper;

use constant LOGIN_LIFETIME => 60 * 30;
use constant TG4W_VERIFY_TITLES => 0;
use constant TG4W_QUIET => 0;
$Storable::forgive_me = 1; 

my %iesms_user_agent_strings = (
	"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" => 1.0,
	"Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)" => 0.4,
	"Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)" => 0.2,
	"Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)" => 0.7,
	"Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1)" => 0.4,
	"Mozilla/4.0 (compatible; MSIE 5.21; Mac_PowerPC)" => 0.2,
	"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q321120)" => 0.6,
	"Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)" => 0.4,
	"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.5) Gecko/20041107 Firefox/1.0" => 0.9,
	"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.0.1) Gecko/20020823 Netscape/7.0" => 0.7,
	"Mozilla/5.0 (X11; U; SunOS sun4u; en-US; rv:1.1) Gecko/20020827" => 0.1,
	"Mozilla/5.0 (X11; U; NetBSD i386; rv:1.7.3) Gecko/20041104 Firefox/0.10.1" => 0.1,
	"Opera/6.05 (Windows 2000; U)  [en]" => 0.4,
	"Opera/7.0 (Windows 2000; U)" => 0.6,
	"Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.5.5 (KHTML, like Gecko) Safari/125.11" => 0.7,
	);

=item $carrier = new WWW::SMS::IE::iesms

This is the object constructor. It should only be called internally by this
library. External code should construct L<WWW::SMS::IE::o2sms>,
L<WWW::SMS::IE::vodasms>, L<WWW::SMS::IE::meteorsms> and
L<WWW::SMS::IE::threesms> (and L<WWW::SMS::IE::aftsms>) objects.

=cut

sub new
{
	my $class = shift;
	my $self  = {};

	bless ($self, $class);

	$self->debug(0);
	$self->login_lifetime(LOGIN_LIFETIME);

	$self->_init();

	return $self;
}

sub _init_tg4w_runner
{
	my $self = shift;

	return 1 if (defined($self->{tg4w_runner}));

	require TestGen4Web::Runner;

	$self->{tg4w_runner} = new TestGen4Web::Runner(debug=>($self->debug()));

	if ($self->{tg4w_runner}->VERSION < 0.11)
	{
		$self->_log_error("TestGen4Web::Runner version 0.11 or higher required");

		return 0;
	}

	$self->{tg4w_runner}->user_agent()->agent($self->_choose_agent_string());
	$self->{tg4w_runner}->verify_titles(TG4W_VERIFY_TITLES);
	$self->{tg4w_runner}->quiet(TG4W_QUIET);
	$self->{tg4w_runner}->load($self->_action_file());
	$self->{tg4w_runner}->debug($self->{debug});

        if ($self->cookie_file() =~ m#/#)
        {
                $self->{tg4w_runner}->cookie_jar_file($self->cookie_file());
        }
        else
        {
                $self->_log_debug("won't write '" . $self->cookie_file() . "' to working directory");
        }

	return 1;
}

=item $carrier->login($username, $password)

Logs in to the mobile operator's website. If provided, use the username and password specified
in C<$username> and C<$password>, otherwise use the username and password provided with the
C<username()> and C<password()> methods.

Returns true on success, false on failure. The last error message is returned by the C<error()>
method.

=cut

sub login
{
	my ($self, $username, $password) = @_;

#	if ($self->is_logged_in())
#	{
#		$self->_log_debug("last login still active, reusing");
#
#		return 1;
#	}

	$self->_init_tg4w_runner() if (!$self->{tg4w_runner});

	$self->username($username) if (defined($username));
	$self->password($password) if (defined($password));

	if (defined($self->{tg4w_runner}->cookie_jar()))
	{
		$self->_clear_cookie_jar();
	}

	$self->_log_debug("about to log in to '" . $self->domain_name() . "' with username '" . $self->username() . "' and password '" . $self->password() . "'");
	$self->_log_debug("user agent set to '" . $self->{tg4w_runner}->user_agent()->agent() . "'");

	my $retval =  $self->{tg4w_runner}->run($self->_login_start_step(), $self->_login_end_step());

	# save the error
	$self->error($self->{tg4w_runner}->error()) if (!$retval);

	$self->{matches} = $self->{tg4w_runner}->matches();

	$self->_log_debug("login " . ($retval?"succeeded":"failed with error '" . $self->error() . "'"));
	$self->_log_debug(scalar(@{$self->{matches}}) . " matches found in last assertion");

	if (!$retval)
	{
		$self->_clear_cookie_jar();
	}

	$self->_save_action_state();

	return $retval;
}

=item $carrier->send($number, $message)

Sends the SMS message in C<$message> to the recipient in C<$number>.

Returns true on success, false on failure. The last error message is returned by the C<error()>
method.

This method will fail if there is no login window, the number is invalid, or if there is
a problem sending via the operator.

After sending, the number of free messages remaining in your account is returned by
C<remaining_messages()>.

=cut

sub send
{
	my $self = shift;

	return $self->_real_send(@_);
}

sub _real_send
{
	my ($self, $raw_number, $message) = @_;

	$self->_init_tg4w_runner() if (!$self->{tg4w_runner});

	# validate this number
	my $number = $self->validate_number($raw_number);
	
	my $charsleft = $self->max_length() - length($message);
	
	if ($number == -1)
	{
		$self->error("Invalid number: $raw_number");
		return 0;
	}

	# format number how this operator likes it
	$number = $self->_format_number($number);

	# pad message with spaces if less than min_length
	if (length($message) < $self->min_length())
	{
		$message .= " " x ($self->min_length() - length($message));
		$self->_log_warning("padded message to " . $self->min_length() . " characters");
	}

	# trim message to max length (multiple messages should be handled by the client)
	if (length($message) > $self->max_length())
	{
		$message = substr($message, 0, $self->max_length());
		$self->_log_warning("trimmed message to " . $self->max_length() . " characters");
	}

	# try to load action state from file if not in memory
	if (!defined($self->{tg4w_runner}->action_state()))
	{
		if (!$self->_load_action_state())
		{
			$self->_log_debug("Failed to load action state file");

			# is this so bad? - action state files only needed for re-using logins...
			#$self->error("Failed to load action state file");
			#return 0;
		}
	}

	# save this state as this is where we always want to start sending from
	my $action_state = $self->{tg4w_runner}->action_state();

	$self->{tg4w_runner}->set_replacement("recipient", $number);
	$self->{tg4w_runner}->set_replacement("message", $message);
	$self->{tg4w_runner}->set_replacement("delay", $self->delay($message));
	$self->{tg4w_runner}->set_replacement("charsleft", $charsleft);
	$self->{tg4w_runner}->set_replacement("username", $self->{username});
	$self->{tg4w_runner}->set_replacement("password", $self->{password});
	
	$self->remaining_messages('?');

	# send the message
	$self->_log_debug("about to send the message '" . $message . "' to the recipient '" . $number . "'");

	if ($self->{dummy_send})
	{
		$self->_log_debug("performed dummy send");
		return 1;
	}

	my $retval = $self->{tg4w_runner}->run($self->_send_start_step(), $self->_send_end_step());

	# save the error
	$self->error($self->{tg4w_runner}->error()) if (!$retval);

	# handle the matches
	$self->{matches} = $self->{tg4w_runner}->matches();

	if (defined($self->{matches}[$self->_remaining_messages_match()]))
	{
		$self->remaining_messages($self->{matches}[$self->_remaining_messages_match()]);
	}

	$self->_log_debug("send " . ($retval?"succeeded":"failed with error '" . $self->error() . "'"));
	$self->_log_debug(scalar(@{$self->{matches}}) . " matches found in last assertion");

	# return the action state to what it was before
	$self->{tg4w_runner}->action_state($action_state);
	$self->_save_action_state();

	return $retval;
}

=item $carrier->validate_number($number)

Returns the telephone number in C<$number> converted to the international format, e.g.
C<+353865551234>.

Also verifies that the mobile provider can send to this number.

Returns -1 if the number is invalid, C<validate_number_error()> gets the error message.

=cut

sub validate_number
{
	my ($self, $number) = @_;

	# strip whitespace and hyphens from the number
	$number =~ s/[\s\-]//g;

	if ($number =~ /[^\d\+]/)
	{
		# has an invalid character
		$self->validate_number_error("number has an invalid character");
		return -1;
	}
	elsif ($number =~ /^0(8[3567])(\d*)/)
	{
		# is an irish mobile number - check length
		if (length($number) != 10)
		{
			$self->validate_number_error("number is the wrong length for an Irish mobile number");
			return -1;
		}

		# length ok - make international
		$number = "+353$1$2";
	}
	elsif ($number =~ /^\+(\d*)/)
	{
		# is a plus style international number -- is ok
	}
	elsif ($number =~ /^00(\d*)/)
	{
		# is an 00 international number -- make plus
		$number = "+$1";
	}
	elsif ($number =~ /959\d{2,5}/)
	{
		# is an aft 959xxxx number
	}
	else
	{
		# don't know what this is
		$self->validate_number_error("number is badly formed");
		return -1;
	}

	if (!$self->_is_valid_number($number))
	{
		return -1;
	}

	return $number;
}

=item $carrier->validate_number_error()

After a unsuccessful C<validate_number()>, returns the error message.

=cut

sub validate_number_error
{
	defined($_[1]) ? $_[0]->{validate_number_error} = $_[1] : $_[0]->{validate_number_error};
}

=item $carrier->is_logged_in()

Returns success if C<login()> has been called successfully in this or a previous instance and if the
login window has not expired.

=cut

sub is_logged_in()
{
	my ($self) = @_;

	if (-f $self->cookie_file())
	{
		my $fstat = stat($self->cookie_file());

		if ($fstat && ($fstat->mtime + $self->login_lifetime() > time()))
		{
			$self->_log_debug("found a fresh cookie file at " . $self->cookie_file());

			# touch to keep it up to date
			utime (time, time, $self->cookie_file());

			return 1;
		}
		else
		{
			$self->_log_debug("found an old cookie file at " . $self->cookie_file());

			return 0;
		}
	}

	$self->_log_debug("no cookie file found at " . $self->cookie_file());

	return 0;
}

=item $carrier->delay($message)

Some carriers required a pause of X seconds before the message is sent. This is
performed automatically by the C<send()> method.

This method will return how long that delay will be.

=cut

sub delay
{
	my ($self, $message) = @_;

	my $delay = ceil(length($message) * $self->_simulated_delay_perchar());
	$delay = $self->_simulated_delay_max() if ($delay > $self->_simulated_delay_max());
	$delay = $self->_simulated_delay_min() if ($delay < $self->_simulated_delay_min());

	return $delay;
}

=item $carrier->login_lifetime()

Set/retrieve the maximum length of time (seconds), between requests that a session is alive for.

=cut

sub login_lifetime
{
	defined($_[1]) ? $_[0]->{login_lifetime} = $_[1] : $_[0]->{login_lifetime};
}

=item $carrier->max_length()

Return the supported maximum length of a single SMS message.

This method can be overwritten by subclasses extending this class.

=cut

sub max_length
{
	return 160;
}

=item $carrier->min_length()

Return the supported minimum length of a single SMS message.

This method can be overwritten by subclasses extending this class.

=cut

sub min_length
{
	return 0;
}


=item $carrier->remaining_messages()

After a C<send()>, this method returns the number of free messages remaining in your account.

=cut

sub remaining_messages
{
	defined($_[1]) ? $_[0]->{remaining_messages} = $_[1] : $_[0]->{remaining_messages};
}

=item $carrier->write_message_file($message)

Write the string <$message> to the message file as returned by C<message_file()>.

=cut

sub write_message_file
{
	my $msgfile;
	my $self = $_[0];
	my $message = $_[1];

	chomp($message);

	if ($msgfile = $self->message_file())
	{
                if ($msgfile !~ m#/#)
                {
			$self->_log_debug("won't write '$msgfile' to working directory");
                }
		elsif (open (SMSMSG, "> $msgfile"))
		{
			print SMSMSG $message . "\n";
			close (SMSMSG);
		}
		else
		{
			$self->_log_warning("can't open message file '$msgfile' for writing: $@");
		}
	}

	return 1;
}

=item $carrier->write_history_file($message)

Append the string <$message> to the history file as returned by C<history_file()>.

=cut

sub write_history_file
{
	my $histfile;
	my $self = $_[0];
	my $message = $_[1];
	my $recipient = $_[2];

	chomp($message);

	if ($histfile = $self->history_file())
	{
                if ($histfile !~ m#/#)
                {
			$self->_log_debug("won't write '$histfile' to working directory");
                }
		elsif (open (SMSMSG, ">> $histfile"))
		{
			print SMSMSG "-- to $recipient at " . localtime() . " --\n";
			print SMSMSG $message . "\n";
			print SMSMSG "\n";
			close (SMSMSG);
		}
		else
		{
			$self->_log_warning("can't open history file '$histfile' for appending $@");
		}
	}

	return 1;
}

=item $carrier->username()

=item $carrier->password()

These methods get and set the username and password parameters respectively
used to log in to your provider's website.

=cut

sub username
{
	if (defined($_[1]))
	{
		$_[0]->{username} = $_[1];
		$_[0]->{tg4w_runner}->set_replacement("username", $_[1]);
	}
	else
	{
		return $_[0]->{username} || "";
	}
}

sub password
{
	if (defined($_[1]))
	{
		$_[0]->{password} = $_[1];
		$_[0]->{tg4w_runner}->set_replacement("password", $_[1]);
	}
	else
	{
		return $_[0]->{password} || "";
	}
}

sub cookie_file
{
	if (defined($_[1]))
	{
		my ($filename, $directories, $suffix) = fileparse($_[1]);
		mkdir ($directories, 0777) unless (-d $directories);
	
		$_[0]->{cookie_jar_file} = $_[1];

		$_[0]->{tg4w_runner}->cookie_jar_file($_[1]) if ($_[0]->{tg4w_runner});
	}
	else
	{
		return $_[0]->_abs_cf($_[0]->{cookie_jar_file});
	}
}

sub action_state_file
{
        my $self = $_[0];
	my $action_state_file = $_[1];

	if (defined($action_state_file))
	{
		$self->{action_state_file} = $action_state_file;
	}
	else
	{
		return $self->_abs_cf($self->{action_state_file});
	}
}

sub message_file
{
	defined($_[1]) ? $_[0]->{message_file} = $_[1] : $_[0]->_abs_cf($_[0]->{message_file});
}

sub history_file
{
	defined($_[1]) ? $_[0]->{history_file} = $_[1] : $_[0]->_abs_cf($_[0]->{history_file});
}

=item $carrier->full_name()

=item $carrier->domain_name()

These methods get/set the descriptive name and domain name respectively of this mobile operator.

These methods should be overwritten by subclasses extending this class.

=cut

sub full_name
{
	defined($_[1]) ? $_[0]->{full_name} = $_[1] : $_[0]->{full_name};
}

sub domain_name
{
	defined($_[1]) ? $_[0]->{domain_name} = $_[1] : $_[0]->{domain_name};
}

=item $carrier->is_vodafone()

=item $carrier->is_o2()

=item $carrier->is_meteor()

=item $carrier->is_three()

=item $carrier->is_aft()

These methods are used to determine what subclass is extending this class.

=cut

sub is_vodafone
{
	return 0;
}

sub is_o2
{
	return 0;
}

sub is_meteor
{
	return 0;
}

sub is_three
{
	return 0;
}

sub is_aft
{
	return 0;
}

=item $carrier->user_agent()

Return the C<LWP::UserAgent> object used internally.

=cut

sub user_agent
{
	my $self = shift;

	if (!defined($self->{tg4w_runner}))
	{
		$self->_init_tg4w_runner();
	}

	return $self->{tg4w_runner}->user_agent();
}

=item $carrier->config_file()

=item $carrier->config_dir()

Set/retrieve the location of the config dir/file.

=cut

sub config_file
{
	defined($_[1]) ? $_[0]->{config_file} = $_[1] : $_[0]->_abs_cf($_[0]->{config_file});
}


sub config_dir
{
	my ($self, $dir) = @_;

	if (!defined($dir))
	{
		return $self->{config_dir};
	}

	$dir .= "/" if ($dir !~ m#/$#);

	if (-d $dir)
	{
		$self->{config_dir} = $dir;

		$self->_log_debug("using config dir '" . $dir . "'");

		return 1;
	}
	else
	{
                # create config dir, failing silently if can't

                my $retval = mkdir($dir, 0700);

                if ($retval)
                {
                        $self->_log_debug("Created config directory '$dir'");
                        $self->{config_dir} = $dir;
                }
                else
                {
                        $self->_log_debug("Could not create config directory '$dir': $!");
                }
                
		return $retval;
	}
}

sub _abs_cf
{
	my ($self, $filename) = @_;

	if ($filename eq "")
	{
		return "";
	}
	elsif ($filename =~ m#^/#)
	{
		return $filename;
	}
	elsif ($self->config_dir())
	{
		return $self->config_dir() . $filename;
	}
	else
	{
		return $filename;
	}
}

=item $carrier->cookie_file()

=item $carrier->action_state_file()

=item $carrier->message_file()

=item $carrier->history_file()

These methods get/set the location of the files used by this module
to store session data between invocations and to log messages.

=cut

=item $carrier->_is_valid_number($number)

Mobile operator-specific checks on the number during a C<validate_number()>.

This methods should be overwritten by subclasses extending this class.

=cut

sub _is_valid_number
{
	return 1;
}

sub _format_number
{
	return $_[1];
}

=item $carrier->error()

Returns the last error after a login() or send().

=cut

sub error
{
	my ($self, $error) = @_;

	if (defined($error))
	{
		$self->{last_error} = $error;
	}
	elsif ($self->{last_error})
	{
		return $self->{last_error};
	}
	else
	{
		return 'Internal Error';
	}
}

=item $carrier->debug()

Set/retrieve the debug level for the module (0,1,2).

=cut

sub debug
{
	if (defined($_[1]))
	{
		$_[0]->{debug} = $_[1];

		$_[0]->{tg4w_runner}->debug($_[1]) if ($_[0]->{tg4w_runner});
	}
	else
	{
		return $_[0]->{debug};
	}
}

# private methods

sub dummy_send
{
	defined($_[1]) ? $_[0]->{dummy_send} = $_[1] : $_[0]->{dummy_send};
}

sub is_win32
{
	return ($^O eq 'MSWin32');
}

sub _get_home_dir
{ 
	if (defined($ENV{HOME}))
	{
		return $ENV{HOME};
	}
	elsif (is_win32() && defined($ENV{HOMEPATH}))
	{
		return $ENV{HOMEPATH} . "/";
	}
	else
	{
		return ".";
	}
}

sub _choose_agent_string
{
	my $self = shift;

	my @keys = keys(%iesms_user_agent_strings);
	my $string_count = scalar(@keys);
	my $min_prob = rand();

	my $idx = int(rand($string_count-1));

	for (my $i=0; $i<$string_count; $i++)
	{
		my $key = $keys[($idx+$i)%$string_count];

		$self->_log_debug("checking user agent string '$key' (index ".($idx+$i)%$string_count.") with probability '$iesms_user_agent_strings{$key}' against random seed '$min_prob'...", 2);

		if ($iesms_user_agent_strings{$key} >= $min_prob)
		{
			$self->_log_debug("selected user agent string: '$key'");
			return $key;
		}
	}

	$self->_log_error("failed to randomise user agent");

	return $keys[0];
}

sub _match
{
	my ($self, $match) = @_;

	return ($self->{matches}[$match]);
}

sub _login_start_step
{
	defined($_[1]) ? $_[0]->{login_start_step} = $_[1] : $_[0]->{login_start_step};
}

sub _login_end_step
{
	defined($_[1]) ? $_[0]->{login_end_step} = $_[1] : $_[0]->{login_end_step};
}

sub _send_start_step
{
	defined($_[1]) ? $_[0]->{send_start_step} = $_[1] : $_[0]->{send_start_step};
}

sub _send_end_step
{
	defined($_[1]) ? $_[0]->{send_end_step} = $_[1] : $_[0]->{send_end_step};
}

sub _simulated_delay_max
{
	defined($_[1]) ? $_[0]->{simulated_delay_max} = $_[1] : $_[0]->{simulated_delay_max};
}

sub _simulated_delay_min
{
	defined($_[1]) ? $_[0]->{simulated_delay_min} = $_[1] : $_[0]->{simulated_delay_min};
}

sub _simulated_delay_perchar
{
	defined($_[1]) ? $_[0]->{simulated_delay_perchar} = $_[1] : $_[0]->{simulated_delay_perchar};
}

sub _remaining_messages_match
{
	defined($_[1]) ? $_[0]->{remaining_messages_match} = $_[1] : $_[0]->{remaining_messages_match};
}

sub _action_file
{
	if (!defined($_[1]))
	{
		return $_[0]->{action_file};
	}

	if ($_[1] =~ m#/#)
	{
		# provided path
		$_[0]->{action_file} = $_[1];

		if (-f $_[0]->{action_file})
		{
			return 1;
		}
	}
	else
	{
		# search in include path
		my @files = map {"$_/WWW/SMS/IE/" . $_[1]} @INC;

		foreach my $file (@files)
		{
			if (-f $file)
			{
				$_[0]->{action_file} = $file;
				return 1;
			}
		}
	}

	$_[0]->_log_error("Can't find action file '" . $_[1] . "'");

	return 0;
}


sub _save_action_state
{
	my $action_state_file;
        my $self = $_[0];

        if ($action_state_file = $self->action_state_file())
        {
                if ($action_state_file !~ m#/#)
                {
			$self->_log_debug("won't write '$action_state_file' to working directory");
                        return 0;
                }
                elsif ($self->{tg4w_runner}->action_state())
                {
                        return store($self->{tg4w_runner}->action_state(), $action_state_file);
                }
                else
                {
                        return 0;
                }
        }
}

sub _load_action_state
{
	if (-f $_[0]->action_state_file())
	{
		$_[0]->{tg4w_runner}->action_state(retrieve($_[0]->action_state_file()));
		return 1;
	}
	else
	{
		return 0;
	}
}

sub _clear_cookie_jar
{
	my  $self = shift;

	$self->{tg4w_runner}->cookie_jar()->clear();
        
        if ($self->{tg4w_runner}->cookie_jar_file() && -f $self->{tg4w_runner}->cookie_jar_file())
        {
                unlink($self->{tg4w_runner}->cookie_jar_file());
        }

	$self->_log_debug("emptied cookie jar");
}

sub _log_debug
{
	if (!defined($_[2]))
	{
		$_[2] = 1;
	}

	if ($_[0]->debug() >= $_[2])
	{
		print "iesms: $_[1]\n";
	}
}

sub _log_error
{
	print STDERR "[ ERROR: $_[1] ]\n";
}

sub _log_warning
{
	print STDERR "[ warning: $_[1] ]\n";
}

=back

=head1 DISCLAIMER

The author accepts no responsibility nor liability for your use of this
software.  Please read the terms and conditions of the website of your mobile
provider before using the program.

=head1 SEE ALSO

L<WWW::SMS::IE::o2sms>,
L<WWW::SMS::IE::vodasms>,
L<WWW::SMS::IE::meteorsms>,
L<WWW::SMS::IE::threesms>,
L<WWW::SMS::IE::aftsms> 

L<http://www.mackers.com/projects/o2sms/>

=head1 AUTHOR

David McNamara (me.at.mackers.dot.com)

=head1 COPYRIGHT

Copyright 2000-2006 David McNamara

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

