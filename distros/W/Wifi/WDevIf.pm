package Wifi::WDevIf;
use strict;

sub new{
	my($class,$ref) = @_;
	my($self) = {
		WDevIf => $ref,
	};
	bless($self,$class);
	
	return $self;
}

sub start{
	my($self) = @_;
	my($pid,$line);

	#print "$self->{WHEREIFCONFIG} $self->{WDevIf}{CONFIG}{DEV} $self->{WDevIf}{CONFIG}{IP} netmask $self->{WDevIf}{CONFIG}{NETMASK} mtu 576\n";

	print "+ Start $self->{WDevIf}{CONFIGNET}{IFCONFIG}\n";
	
	$pid = open(PIPE,"$self->{WDevIf}{CONFIGNET}{IFCONFIG} $self->{WDevIf}{CONFIGNET}{DEV} $self->{WDevIf}{CONFIGNET}{IP} netmask $self->{WDevIf}{CONFIGNET}{NETMASK} mtu 576 |") || die "Impossible d'ouvrir $self->{WDevIf}{CONFIGNET}{IFCONFIG} : $!";
	(kill 0,$pid) || die "$self->{WDevIf}{CONFIGNET}{IFCONFIG} invocation failed : $!";
	while(defined($line = <PIPE>)){
		print "LIGNE $line\n";
	}
	close(PIPE);
}

sub stop{
        my($self) = @_;
	my($pid,$line);

	print "- Stop $self->{WDevIf}{CONFIGNET}{IFCONFIG}\n";

	$pid = open(PIPE,"$self->{WDevIf}{CONFIGNET}{IFCONFIG} $self->{WDevIf}{CONFIGNET}{DEV} down |") || die "Impossible d'ouvrir $self->{WDevIf}{CONFIGNET}{IFCONFIG} : $!";
	(kill 0,$pid) || die "$self->{WDevIf}{CONFIGNET}{IFCONFIG} invocation failed : $!";
	while(defined($line = <PIPE>)){
		print "LIGNE $line\n";
	}
	close(PIPE);
}
1;

__END__

=head1 NAME 

Wifi::WDevIf - A class for ifconfig

=head1 SYNOPSIS

use Wifi::WDevIf;

$devif = Wifi::WDevIf->new(REFERENCE Wifi::WFile);

$devif->start;

=head1 DESCRIPTION

Wifi::WDevIf is used by Wifi::Manage for configuring ifconfig.

=head1 METHOD DESCRIPTIONS

This sections contains only the methods in WDevIf.pm itself.

=over 

=item *

start();

Start ifconfig.

=item * 

stop();

Stop ifconfig.

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut

