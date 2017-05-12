package Test::Net::Service;

=head1 NAME

Test::Net::Service - test different network services

=head1 SYNOPSIS

	my $net_service = Test::Net::Service->new(
		'host'  => 'camel.cle.sk',
		'proto' => 'tcp',
	);
	
	eval {
		$net_service->test(
			'port'    => 22,
			'service' => 'ssh',
		);
	};

=head1 DESCRIPTION

This should a collection of basic test for network services. Check the list
and the description L<Services>.


=cut

use warnings;
use strict;

use IO::Socket::INET ();
use Carp::Clan 'croak';

our $VERSION = '0.06';

use base 'Class::Accessor::Fast';


=head1 PROPERTIES

All optional for constructor. Will be used as defaults if set.

	host
	socket
	proto
	port
	service

=cut

__PACKAGE__->mk_accessors(qw{
	host
	socket
	proto
	port
	service
});


=head1 METHODS

=head2 new()

Constructor. You set any property and it will be used as defaults for C<<->test()>>
method.

=cut

sub new {
	my $class = shift;
	
	return $class->SUPER::new({ @_ });
}


=head2 test()

Perform the service test. Add any additional || different parameters to the default
ones as function arguments.

=cut

sub test {
	my $self = shift;
	
	my %args    = (%$self, @_);
	my $socket  = $self->connect(%args);
	my $service = 'test_'.$args{'service'};
	
	croak 'failed to connect'
		if not defined $socket;
	
	croak 'do not know how to test '.$service
		if not $self->can($service);
	
	$self->$service(%args, 'socket' => $socket);

}


=head2 connect()

INTERNAL methd to connect to the host&port if needed. 

=cut

sub connect {
	my $self = shift;
	my %args = @_;
	
	return $args{'socket'}
		if $args{'socket'};
	
	return IO::Socket::INET->new(
		PeerAddr => $args{'host'},
        PeerPort => $args{'port'},
        Proto    => $args{'proto'},
	);
}



=head2 Services

=head3 test_dummy()

Will aways succeed if the connection is sucesfull. Additionaly
it will return hash ref of all the arguments that will be used
to connect and test. Can be used when you want to always pass
the test or for debugging.

=cut

sub test_dummy {
	my $self = shift;
	my %args = @_;
	
	return \%args;
}


=head3 test_ssh()

Will check for SSH string in the first line returned by server after
connection.

=cut

sub test_ssh {
	my $self   = shift;
	my %args   = @_;
	my $socket = $args{'socket'};
	
	my $reqexp_match = qr/SSH/;
	
	my $reply = <$socket>;
		
	return if $reply =~ $reqexp_match;
	die 'reply "', $reply, '" does not match ', $reqexp_match, "\n";
}


=head3 test_http()

Need 'host' to be passed. Will make GET http request for this host.

Checks if the first line of the server response beginns with 'HTTP'.

=cut

sub test_http {
	my $self   = shift;
	my %args   = @_;	
	my $socket = $args{'socket'};
	my $host   = $args{'host'};
	
	my $reqexp_match = qr{^HTTP/};
	
	print $socket "GET / HTTP/1.1\nHost: $host\n\n";
	my $reply = <$socket>;
		
	return 1 if $reply =~ $reqexp_match;
	die 'reply "', $reply, '" does not match ', $reqexp_match, "\n";
}


=head3 test_https()

TODO

=cut

sub test_https {
	my $self = shift;
	my %args = @_;	

	# TODO
	return;
}

1;


__END__


=head1 AUTHOR

Jozef Kutej

=cut
