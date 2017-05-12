#!/usr/bin/perl

=head1 NAME

sites-ok.t - check web sites

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
	time-sync:
		tolerance: 5
	    ntp-servers:
	        - pool.ntp.org
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';


eval "use Net::NTP";
plan 'skip_all' => "need Net::NTP to run web tests" if $@;

# optional for highier precision then seconds
eval "use Time::HiRes";

my @ntp_servers = qw{ pool.ntp.org };
my $tolerance   = 5;

my $config = LoadFile($Bin.'/test-server.yaml');

exit main();

sub main {
	# get config values
	if ($config and $config->{'time-sync'}) {
		@ntp_servers = @{$config->{'time-sync'}->{'ntp-servers'}}
			if $config->{'time-sync'}->{'ntp-servers'};
		$tolerance = $config->{'time-sync'}->{'tolerance'}
			if $config->{'time-sync'}->{'tolerance'};
	}

	plan 'tests' => scalar @ntp_servers;
	
	foreach my $ntp_server (@ntp_servers) {
		my $res;
		eval { $res = { get_ntp_response($ntp_server) }; };
        
		SKIP: {
			skip 'failed to reach '.$ntp_server, 1
				if not defined $res;
			
			my $ntp_time = $res->{'Transmit Timestamp'};
			
			diag 'server time     (GMT): '.gmtime();
			diag 'ntp server time (GMT): '.gmtime($ntp_time);
			cmp_ok(
				abs($ntp_time - time()),
				'<=',
				$tolerance,
				'does the current time - ntp server ('.$ntp_server.') time fit to the tolerance'
			);
		}
	}
		
	return 0;
}


__END__

=head1 NOTE

Time checking depends on L<Net::NTP>.

=head1 AUTHOR

Jozef Kutej

for the idea thanks to Emmanuel Rodriguez Santiago.

=cut
