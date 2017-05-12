package Sys::Net;

=head1 NAME

Sys::Net - system network information or actions

=head1 SYNOPSIS

	my %if_named = %{Sys::Net::interfaces()};
	foreach my $if_name (keys %if_named) {
		print 'interface with name: ', $if_name, ' has ip: ', $if_named{$if_name}, "\n";
	}

	use Sys::Net 'resolv';
	my $hostname = resolv('127.0.0.1');
	my $ip       = resolv('localhost');


=head1 DESCRIPTION

The purpouse is to find out network information or perform system network
actions.

System network interfaces for the moment works just for Linux, and gets only
ipv4 ip of the system interfaces. Will be extended when a need arrise.

=cut

use warnings;
use strict;

our $VERSION = '0.06';

use Socket 'inet_ntoa', 'inet_aton', 'AF_INET';

use base 'Exporter';

our $IFCONFIG_CMD = '/sbin/ifconfig';
our $if_named;
our @EXPORT_OK = qw(resolv interfaces);

=head1 METHODS

=head2 EXPORTS

	our @EXPORT_OK = qw(resolv interfaces);

=head2 interfaces()

returns hash ref with:

	{
		'lo'   => { 'ip' => '127.0.0.1'     },
		'eth0' => { 'ip' => '192.168.100.6' },
	};

TODO more information than just an ip.

=cut

sub interfaces {
	return $if_named
		if defined $if_named;

	$if_named = {};

	# TODO use File::Which to look if there is ifconfig (also any more folders then just one)	
	my @ifconfig_out = `$IFCONFIG_CMD`;
	
	my $ifname;
	my $ifip;
	foreach my $line (@ifconfig_out) {
		# empty line resets the values
		if ($line =~ /^\s*$/) {
			$ifname = undef;
			$ifip   = undef;
		}

		# get columns 1, 2, 3
		my ($c1,$c2,$c3) = split /\s+/, $line;

		# get interface name
		$ifname = $c1
			if $c2 eq 'Link';
		# get ip address
		($ifip) = $c3 =~ m/addr:(.+)/
			if $c2 eq 'inet';
		
		# if we have both ip and interface name store it
		$if_named->{$ifname} = { 'ip' => $ifip }
			if ($ifname and $ifip);
	}
	
	return $if_named;
}


=head2 resolv()

Resolv hostname to an ip or ip to an hostname.

Using gethostbyaddr or gethostbyname so also hosts in /etc/hosts
are taken into an account.

=cut

sub resolv {
	my $name = shift;
	
	# resolv ip to a hostname
	if ($name =~ m/^\s*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*$/) {
		return scalar gethostbyaddr(inet_aton($name), AF_INET);
	}
	# resolv hostname to ip
	else {
		return inet_ntoa(scalar gethostbyname($name));
	}
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
