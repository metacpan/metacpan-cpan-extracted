package ThreatNet::Message::IPv4;

use strict;
use base 'ThreatNet::Message';
use Net::IP ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $msg   = shift;

	# Create the basic object from out parent class
	my $self = $class->SUPER::new($msg) or return undef;

	# Find the first non-whitespace segment
	$msg =~ /^(\S+)(\s+.+)?$/ or return undef;

	# Net::IP supports a variety of different formats.
	# We, on the other hand, don't.
	# Run a basic check to ensure the format is generally correct.
	# If we find at least one dot, then it won't be misrecognised.
	my $ip = $1;
	$ip =~ /\./ or return undef;

	# The rest of the line (if any) is the comment
	$self->{comment} = '';
	if ( defined $2 ) {
		$self->{comment} = $2;
		$self->{comment} =~ s/^\s+//;
	}

	# Complete the creation of the IP and message
	$self->{IP} = Net::IP->new( $ip, 4 ) or return undef;

	$self;		
}

sub IP { $_[0]->{IP} }

sub ip { $_[0]->IP->ip }

sub comment { $_[0]->{comment} }





#####################################################################
# Param::Coerce Support

sub __as_Net_IP { $_[0]->IP }

1;
