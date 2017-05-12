package Wifi::WRoute;
use strict;

sub new{
	my($class,$ref) = @_;
	my($self) = {
		WRoute => $ref,
	};
	bless($self,$class);
	
	return $self;
}

sub start{
	my($self) = shift;
	my($pid,$line);

	#print "$self->{WHEREROUTE} add default gw $self->{WRoute}{CONFIG}{GATEWAY}\n";

	print "+ Start $self->{WRoute}{CONFIGNET}{ROUTE}\n";

	$pid = open(PIPE,"$self->{WRoute}{CONFIGNET}{ROUTE} add default gw $self->{WRoute}{CONFIGNET}{GATEWAY} |") || die "Impossible d'ouvrir $self->{WRoute}{CONFIGNET}{ROUTE} : $!";
	(kill 0,$pid) || die "$self->{WRoute}{CONFIGNET}{ROUTE} invocation failed : $!";
	while(defined($line = <PIPE>)){
		print "LIGNE $line\n";
	}
	close(PIPE);
}
1;

__END__

=head1 NAME

Wifi::WRoute - A class for route

=head1 SYNOPSIS

use Wifi::WRoute;

$route = Wifi::WRoute->new(REFERENCE Wifi::WFile);

$route->start;

=head1 DESCRIPTION

Wifi::WRoute is used by Wifi::Manage for configuring route.

=head1 METHOD DESCRIPTIONS

This sections contains only the methods in WRoute.pm itself.

=over 

=item *

start();

Start route.

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut

