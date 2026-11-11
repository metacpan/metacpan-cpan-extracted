package Web::VWF::Display::index;

# Display the index page.
# Certain variables are available to all templates,
# such as the stuff in the configuration file

use strict;
use warnings;

use Carp;
use Web::VWF::Display;
use Web::VWF::Utils qw(create_disc_cache);
use String::Random;

our @ISA = ('Web::VWF::Display');

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $info = $self->{_info};
	croak('Missing _info in object') unless $info;

	# Define allowed parameters (use state to avoid redeclaring in subsequent calls)
	# state $allowed = {
	my $allow = {
		'person' => undef,
		'action' => 'login',
		'name' => undef,
		'page' => 'index',
		'password' => undef,
		'lang' => qr/^[A-Z]{2}$/i,
		'lint_content' => qr/^\d$/,
	};

	my $config = $args{'config'};
	my $logger = $args{'logger'};
	my $params = $info->params({ allow => $allow });

	if(!defined($params)) {
		# No parameters to process: display the main index page
		return $self->SUPER::html();
	}

	# Parameters to exclude from further processing
	# my @exclude_keys = qw(page lint_content lang fbclid gclid);
	# local delete @params{@exclude_keys};
	delete local $params->{'page'};
	delete local $params->{'lint_content'};
	delete local $params->{'lang'};
	delete local $params->{'fbclid'};
	delete local $params->{'gclid'};

	# Database handle
	my $index = $args{'index'};
	croak("Missing 'index' handle") unless($index);

	if(scalar(keys %{$params}) == 0) {
		# No parameters to process: display the main index page
		return $self->SUPER::html(updated => $index->updated());
	}

	my $cache;
	if(defined($params->{'action'})) {
		$self->{'logindata'} ||= create_disc_cache(config => $config, logger => $logger, namespace => 'logindata', root_dir => $args{'cachedir'});
		$cache = $self->{'logindata'};
		if($params->{'action'} eq 'login') {
			if((!defined($params->{'name'})) || !defined($params->{'password'})) {
				return $self->SUPER::html({ error => 'Fill in name and password' });
			}
			# FIXME - read from configuration file
			if(($params->{'name'} ne 'VWF') || ($params->{'password'} ne 'Password')) {
				return $self->SUPER::html({ error => 'Incorrect name or password' });
			}
			my $rand = String::Random->new();
			my $key;
			do {
				$key = $rand->randregex('\w\w\w\w\w\w\w\w');
			} while($cache->get($key));     # FIXME: race condition
			$self->set_cookie('session' => $key);
			$self->{'logindata'}->set('VWF', $key, '1 day');
			my $script_name = $info->script_name();
			return "Location: $script_name?page=admin";
		}
	}
	if(my $cookie = $info->get_cookie(cookie_name => 'session')) {
		# No action was given, so the session store may not be open yet
		$self->{'logindata'} ||= create_disc_cache(config => $config, logger => $logger, namespace => 'logindata', root_dir => $args{'cachedir'});
		if(my $key = $self->{'logindata'}->get('VWF')) {
			if($cookie eq $key) {
				my $script_name = $info->script_name();
				return "Location: $script_name?page=admin";
			}
			# A wrong cookie must not end the real session: anyone could
			# send one, and so log the administrator out at will
		}
		return $self->SUPER::html({ error => 'You need to login to access the admin screen' });
	}

	if(!defined($info->person())) {
		return $self->SUPER::html({ error => 'Who do you want to contact?' });
	}

	# Look in the index.db for the name given as the CGI argument and
	# find their e-mail address
	my $to = ($index->email({ entry => $info->person() }))[0];

	# Insert code here to error if $to isn't defined
	if(!defined($to)) {
		croak('No email entry assigned to ', $info->person());
	}

	# Rate limit for sending e-mails
        if(my $remote_addr = $ENV{'REMOTE_ADDR'}) {
                if(($self->{'mailfrom'}->{$remote_addr} // 0) >= 2) {
                        $self->{_logger}->info("E-mail blocked to $to") if($self->{_logger});
                        return $self->SUPER::html({ error => 'You have reached your limit for sendmail e-mails' });
                }
                $self->{'mailfrom'}->{$remote_addr}++;
        }

	# Send the email
	if(open(my $fout, '|-', '/usr/sbin/sendmail -t')) {
		print $fout "To: $to\n",
			"From: webmaster\n",
			"Subject: VWF sending an e-mail\n\n",
			"Hello, world\n";

		close $fout;

		if($self->{_logger}) {
			$self->{_logger}->trace("E-mail sent to $to");
		}

		# Render the response that the email has been sent
		return $self->SUPER::html({ action => 'sent', updated => $index->updated() });
	}
	return $self->SUPER::html({ error => "Can't find /usr/sbin/sendmail", updated => $index->updated() });
}

1;
