#!/usr/bin/perl

=head1 NAME

dns-resolution.t - query /etc/resolv.conf dns servers and check if reachable

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
		resolv.conf:
		    dns_retry  : 3
		    dns_timeout: 5
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
#use Test::More tests => 1;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';
use File::Slurp 'read_file';

eval "use Net::DNS::Resolver";
plan 'skip_all' => "need Net::DNS::Resolver to run dns tests" if $@;

plan 'skip_all' => 'can not read /etc/resolv.conf (nounix system?)'
	if not -r '/etc/resolv.conf';

# nameserver line in /etc/resolv.conf regexp
my $nameserver_line_regexp = qr/
	^
	nameserver
	\s+
	([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})
	\b
/xms;

my $config = LoadFile($Bin.'/test-server.yaml');
my $DNS_RETRY   = 3;
my $DNS_TIMEOUT = 5;

# override the defaults
if ($config and (exists $config->{'resolv.conf'})) {
	$DNS_RETRY = $config->{'resolv.conf'}->{'dns_retry'}
		if exists $config->{'resolv.conf'}->{'dns_retry'};
	$DNS_TIMEOUT = $config->{'resolv.conf'}->{'dns_timeout'}
		if exists $config->{'resolv.conf'}->{'dns_timeout'};
}

exit main();

sub main {
	my @resolv_conf = read_file('/etc/resolv.conf');
	@resolv_conf = grep { $_ =~ m/^nameserver\s/ } @resolv_conf;
	
	plan 'skip_all' => 'no nameservers found in /etc/resolv.conf'
		if not @resolv_conf;

	plan 'tests' => (scalar @resolv_conf)*2;
	
	# loop through 'namserver x.y.z.q' lines
	foreach my $nameserver_line (@resolv_conf) {
		SKIP: {
			# check the format
			like(
				$nameserver_line,
				$nameserver_line_regexp,
				'check nameserver line format'
			) or skip 'badly formated nameserver line: '.$nameserver_line, 1;
			
			# extract the ip
			my ($dns_server_ip) = ($nameserver_line =~ $nameserver_line_regexp);
			
			# create resolver that is quering only current dns server ip
			my $res = Net::DNS::Resolver->new(
				nameservers => [ $dns_server_ip ],
				retry       => $DNS_RETRY,
				udp_timeout => $DNS_TIMEOUT,
			);
			
			# send an answer and check if we got (any) response
			my $answer = $res->send('bratislava.pm.org');
			ok(defined $answer, 'lookup using '.$dns_server_ip);
		}
	}
		
	return 0;
}


__END__

=head1 NOTE

DNS resolution depends on L<Net::DNS::Resolver>.

=head1 AUTHOR

Jozef Kutej

=cut
