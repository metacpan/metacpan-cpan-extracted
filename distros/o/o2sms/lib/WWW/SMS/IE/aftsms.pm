#
# $Id: o2sms.pm 288 2006-08-01 18:04:33Z mackers $

package WWW::SMS::IE::aftsms;

=head1 NAME

WWW::SMS::IE::aftsms - A module to send SMS messages using the AFT gateway.

=head1 SYNOPSIS

  require WWW::SMS::IE::aftsms;

  my $carrier = new WWW::SMS::IE::aftsms;

  if ($carrier->login('aft_user', 'password'))
  {
    my $retval = $carrier->send('+353865551234', 'Hello World!');

    if (!$retval)
    {
      print $carrier->error() . "\n";
    }
  }

=head1 DESCRIPTION

L<WWW::SMS::IE::o2sms> is a class to send SMS messages via the command line
using the AFT gateway.

For more information see L<WWW::SMS::IE::iesms>, 
L<http://computer.donutsoft.net/sms/pmwiki.php?n=Main.HomePage>

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = sprintf("0.%02d", q$Revision: 288 $ =~ /(\d+)/);

@WWW::SMS::IE::aftsms::ISA = qw{WWW::SMS::IE::iesms};

use constant LOGIN_START_STEP => 0;
use constant LOGIN_END_STEP => 0;
use constant SEND_START_STEP => 0;
use constant SEND_END_STEP => undef;
use constant REMAINING_MESSAGES_MATCH => 1;
use constant ACTION_FILE => "aftsms.action";
use constant SIMULATED_DELAY_MIN => 0;
use constant SIMULATED_DELAY_MAX => 0;
use constant SIMULATED_DELAY_PERCHAR => 0;

sub _init
{
	my $self = shift;

	$self->_log_debug("creating new instance of aft carrier");

	$self->_login_start_step(LOGIN_START_STEP);
	$self->_login_end_step(LOGIN_END_STEP);
	$self->_send_start_step(SEND_START_STEP);
	$self->_send_end_step(SEND_END_STEP);
	$self->_remaining_messages_match(REMAINING_MESSAGES_MATCH);
	$self->_action_file(ACTION_FILE);
	$self->_simulated_delay_max(SIMULATED_DELAY_MAX);
	$self->_simulated_delay_min(SIMULATED_DELAY_MIN);
	$self->_simulated_delay_perchar(SIMULATED_DELAY_PERCHAR);

	$self->full_name("AFT");
	$self->domain_name("sms.donutsoft.net");

	if ($self->is_win32())
	{
		$self->config_dir($ENV{TMP});
		$self->config_file($self->_get_home_dir() . "aftsms.ini");
		$self->message_file("aftsms_lastmsg.txt");
		$self->history_file("aftsms_history.txt");
		$self->cookie_file("aftsms.cookie");
		$self->action_state_file("aftsms.state");
	}
	else
	{
		$self->config_dir($self->_get_home_dir() . "/.aftsms/");
		$self->config_file("config");
		$self->message_file("lastmsg");
		$self->history_file("history");
		$self->cookie_file(".cookie");
		$self->action_state_file(".state");
	}
}

sub login
{
	my ($self, $username, $password) = @_;

	$self->_log_debug("performing dummy login for aft...");

	$self->_init_tg4w_runner() if (!$self->{tg4w_runner});

	$self->username($username) if (defined($username));
	$self->password($password) if (defined($password));

	return 1;
}

sub is_logged_in
{
	return 0;
}

sub is_aft
{
	return 1;
}

=head1 DISCLAIMER

The author accepts no responsibility nor liability for your use of this
software.  Please read the terms and conditions of the website of your mobile
provider before using the program.

=head1 SEE ALSO

L<WWW::SMS::IE::iesms>

L<http://www.mackers.com/projects/o2sms/>

L<http://computer.donutsoft.net/sms/pmwiki.php?n=Main.HomePage>

=head1 AUTHOR

David McNamara (me.at.mackers.dot.com)

=head1 COPYRIGHT

Copyright 2000-2006 David McNamara

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
