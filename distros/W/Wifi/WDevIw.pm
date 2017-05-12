package Wifi::WDevIw;
use strict;

sub new{
	my($class,$ref) = @_;
	my($self) = {
		WDevIw => $ref,
	};
	bless($self,$class);
	
	return $self;
}

sub start{
	my($self) = @_;
	my($pid,$line,$command);

	$command  = "$self->{WDevIw}{CONFIGNET}{IWCONFIG} $self->{WDevIw}{CONFIGNET}{DEV} essid $self->{WDevIw}{CONFIGNET}{ESSID} channel $self->{WDevIw}{CONFIGNET}{CHANNEL} rate $self->{WDevIw}{CONFIGNET}{RATE}";
        if($self->{WDevIw}{CONFIGNET}{KEY} ne undef && $self->{WDevIw}{CONFIGNET}{ALG} ne undef){
	$command .= " key $self->{WDevIw}{CONFIGNET}{ALG} \"$self->{WDevIw}{CONFIGNET}{KEY}\"";
	}

	print "+ Start $self->{WDevIw}{CONFIGNET}{IWCONFIG}\n";
	
	$pid = open(PIPE,"$command |") || die "Impossible d'ouvrir $self->{WDevIw}{CONFIGNET}{IWCONFIG}";
	
	(kill 0,$pid) || die "$self->{WDevIw}{CONFIGNET}{IWCONFIG} invocation failed : $!";
	while(defined($line = <PIPE>)){
		print "LIGNE $line\n";
	}
	close(PIPE);
}
1;

__END__

=head1 NAME

Wifi::WDevIw - A class for iwconfig

=head1 SYNOPSIS

use Wifi::WDevIw;

$deviw = Wifi::WDevIw->new(REFERENCE Wifi::WFile);

$deviw->start;

=head1 DESCRIPTION

Wifi::WDevIw is used by Wifi::Manage for configuring iwconfig.

=head1 METHOD DESCRIPTIONS

This sections contains only the methods in WDevIw.pm itself.

=over 

=item *

start();

Start iwconfig.

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut
