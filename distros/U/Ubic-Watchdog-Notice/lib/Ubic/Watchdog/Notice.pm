package Ubic::Watchdog::Notice;
 
use strict;
use warnings;

use Sys::Hostname;
use Getopt::Long;
use File::Tail;
use MIME::Lite;
use URI;
use LWP::UserAgent;

our $VERSION = 0.31;

my $host = hostname;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

$SIG{TERM} = sub { exit 0 };

my $conf;
my $conf_file = '/etc/ubic/notice.cfg';

my $default = {
	log       => '/var/log/ubic/watchdog.log',
	hipchat   => {
		host  => 'https://api.hipchat.com',
	},
	slack     => {
		host  => 'https://slack.com',
	},
};

sub run {
	GetOptions(
		'config=s' => \$conf_file,
	);

	die "Configuration file <$conf_file> not exists" unless -e $conf_file;

	$conf = do $conf_file;

	for (qw/From To/) {
		die "Configuration value <$_> is required" unless $conf->{$_};
	}

	$conf->{log} ||= $default->{log};

	while (1) {
		# Maybe file not exists
		eval {
			my $F = File::Tail->new(name => $conf->{log}, maxinterval => 1);
			my $line;
			while (defined( $line = $F->read )) {
				if (my ($service) = $line =~ /\]\s*(\S+)\s+status.*restarting/) {
					notice($service, $line);
				}
			}
		};

		sleep 1;
	}
}

sub notice {
	my ($service, $txt) = @_;

	return unless $service;

	my $msg = MIME::Lite->new(
		From    => $conf->{From},
		To      => $conf->{To  },
		Subject => "[UBIC] $service down on $host",
		Data    => $txt,
	);
	$msg->attr("content-type.charset" => "utf-8");
	$msg->send("sendmail", "/usr/sbin/sendmail -t -oi -oem");

	if ($conf->{hipchat}) {
		my $h = $host;
		$h = substr $h, 0, 15 if length($h) > 15;

		my $response = $ua->post("$default->{hipchat}->{host}/v1/rooms/message", {
			auth_token     => $conf->{hipchat}->{token},
			room_id        => $conf->{hipchat}->{room },
			from           => $h,
			message        => $txt,
			message_format => 'text',
			notify         => 1,
			color          => 'yellow',
			format         => 'json',
		});

		unless ($response->is_success) {
			warn "Hipchat notification failed!";
			warn $response->status_line;
			warn $response->content;
		}
	}

	if($conf->{slack}) {
		my $t = $conf->{slack};
		$t->{text    }   = "[$service] down on $host";
		$t->{username} ||= 'Ubic Server Bot';

		my $url = URI->new("$default->{slack}->{host}/api/chat.postMessage");
		$url->query_form(%$t);
		my $response = $ua->get($url);

		unless ($response->is_success) {
			warn "Slack notification failed!";
			warn $response->status_line;
			warn $response->content;
		}
	}
}

1;

=pod
 
=head1 NAME

Ubic::Watchdog::Notice - Notice service for ubic.

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    Start notice service:
    $ ubic start ubic.notice

=head1 DESCRIPTION

Currently module can notice by email and to L<HIPCHAT|https://www.hipchat.com> or L<SLACK|https://slack.com> service.

=head1 INSTALLATION

Put this code in file `/etc/ubic/service/ubic/notice`:

    use Ubic::Service::SimpleDaemon;
    
    Ubic::Service::SimpleDaemon->new(
        bin => ['ubic-notice'],
    );

Put this configuration in file `/etc/ubic/notice.cfg`:


    {
	    From => 'likhatskiy@gmail.com',
	    To   => 'name@mail.com',
    };

Start it:

    $ ubic start ubic.notice

=head1 OPTIONS

=over

=item B< From >
    
Sets the email address to send from.

=item B< To >
    
Sets the addresses in `MIME::Lite` style to send to.

=item B< log >
    
Path to `ubic-watchdog` file for scan. Default is `/var/log/ubic/watchdog.log`.

=item B< hipchat >
    
Notice to L<HIPCHAT|https://www.hipchat.com> service.

	hipchat => {
		token => 'YOUR_TOKEN',
		room  => 'ROOM_NAME'
	},

=item B< slack >
    
Notice to L<SLACK|https://slack.com> service.

	slack => {
		token    => 'YOUR_TOKEN',
		channel  => '#CHANNEL_NAME'
		username => 'Ubic Server Bot'
	},

=back

=head1 SOURCE REPOSITORY

L<https://github.com/likhatskiy/Ubic-Watchdog-Notice>

=head1 AUTHOR

Alexey Likhatskiy, <likhatskiy@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 "Alexey Likhatskiy"

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
