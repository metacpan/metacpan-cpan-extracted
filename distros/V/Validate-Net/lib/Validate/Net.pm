package Validate::Net;

# Validate::Net is designed to allow you to test net related string to
# determine their relative "validity".

# We use Class::Default to allow us to create a "default" validator
# which has a "medium" setting. Settings are discussed later.

use 5.005;
use strict;
use base 'Class::Default';

# Globals
use vars qw{$VERSION $errstr $reason};
BEGIN {
	$VERSION = '0.6';
	$errstr  = '';
	$reason  = ''
}





#####################################################################
# Constructor and Friends

sub new {
	my $class = shift;
	my $depth = shift || 'local';

	# Create the validtor object
	my $self = bless {
		depth => undef,
		}, $class;

	# Set the depth
	$self->depth( $depth ) or return undef;
	$self;
}

sub depth {
	my $self = shift;
	unless ( ref $self ) {
		return $self->andError( "Cannot change the depth of the default object. You should instantiate instead" );
	}

	my $depth = shift;
	return $self->{depth} unless defined $depth;
	unless ( $depth eq 'fast' or $depth eq 'local' or $depth eq 'full' ) {
		return $self->andError( "Invalid depth '$depth'. Valid depths are 'fast', 'local'(default) or 'full'" );
	}
	$self->{depth} = $depth;
	1;
}





#####################################################################
# Testing

# Validate an ip address
sub ip {
	my $self = shift->_self;
	my $ip = shift or return undef;

	# Clear the reason
	$reason = '';

	# First, do a basic character test.
	# Just what we can get away with in a regex.
	unless ( $ip =~ /^[0-9]\d{0,2}(?:\.[0-9]\d{0,2}){3}$/ ) {
		return $self->withReason( 'Does not fit the basic dotted quad format for an ip' );
	}

	# Split into parts in preperation for the remaining tests
	my @quad = split /\./, $ip;

	# Make sure the basic numeric range is ok
	if ( scalar grep { $_ > 255 } @quad ) {
		return $self->withReason( 'The maximum value for an ip element is 255' );
	}

	# End of the fast tests
	return 1 if $self->{depth} eq 'fast';

	### Add tests for options

	1;
}

# Validate a full or partial domain name, or just a host name
sub domain {
	my $self = shift->_self;
	my $domain = lc shift or return undef;

	# Do a quick check for any invalid characters, or basic problems
	if ( $domain =~ /[^a-z0-9\.-]/ ) {
		return $self->withReason( "Domain '$domain' contains invalid characters" );
	}
	if ( $domain =~ /\.\./ ) {
		return $self->withReason( "Domain '$domain' contains consecutive dots" );
	}
	if ( $domain =~ /^\./ ) {
		return $self->withReason( "Domain '$domain' cannot start with a dot" );
	}

	# The use of a trailing dot is allowed, but we remove it for testing purposes.
	$domain =~ s/\.$//;

	# Split into elements
	my @elements = split /\./, $domain;

	# Check each element individually
	foreach my $element ( @elements ) {
		# Segments can be no more than 63 characters
		if ( length $element > 63 ) {
			return $self->withReason( "Domain section '$element' cannot be longer than 63 characters" );
		}

		# Segments are allowed to contain only digits
		next if $element =~ /^\d+$/;

		# Segment must start with a letter
		if ( $element !~ /^[a-z]/ ) {
			return $self->withReason( "Domain section '$element' must start with a letter" );
		}

		# Segment must end with a letter or number
		if ( $element !~ /[a-z0-9]$/ ) {
			return $self->withReason( "Domain section '$element' must end with a letter or number" );
		}

		# Cannot have two consecutive dashes ( RFC doesn't say so that I can find... is this correct? )
		if ( $element =~ /--/ ) {
			return $self->withReason( "Domain sections '$element' cannot have two dashes in a row" );
		}
	}

	return 1 if $self->{depth} eq 'fast';

	### Add tests for options

	1;
}

# Validate a host.
# A host is EITHER an ip address, or a domain
sub host {
	my $self = shift->_self;
	my $host = shift;

	# Test as an ip or a domain
	$host =~ /^\d+\.\d+\.\d+\.\d+$/
		? $self->ip( $host )
		: $self->domain( $host );
}

# Validate a port number
sub port {
	my $self = shift->_self;
	my $port = shift;

	# A port must be all numbers
	if ( $port =~ /[^0-9]/ ) {
		return $self->withReason( 'A port number must be an integer' );
	}

	# A port cannot start with 0
	if ( $port =~ /^0/ ) {
		return $self->withReason( 'A port number cannot start with zero' );
	}

	# A port must be less than or equal to 65535
	if ( $port > 65535 ) {
		return $self->withReason( 'The port number is too high' );
	}

	# Otherwise OK
	1;
}




#####################################################################
# Error and Message Handling

sub andError   { $errstr = $_[1]; undef }
sub withReason { $reason = $_[1]; '' }
sub errstr     { $errstr }
sub reason     { $reason }

1;

__END__

=pod

=head1 NAME

Validate::Net - Format validation for Net:: related strings

=head1 SYNOPSIS

  use Validate::Net;

  my $good = '123.1.23.123';
  my $bad = '123.432.21.12';

  foreach ( $good, $bad ) {
  	if ( Validate::Net->ip( $_ ) ) {
  		print "'$_' is a valid ip\n";
  	} else {
  		print "'$_' is not a valid ip address because:\n";
  		print Validate::Net->reason . "\n";
  	}
  }

  my $checker = Validate::Net->new( 'fast' );
  unless ( $checker->host( 'foo.bar.blah' ) ) {
  	print "You provided an invalid host";
  }

=head1 DESCRIPTION

Validate::Net is a class designed to assist with the validation of internet
related strings. It can be used to validate CGI forms, internally by modules,
and in any place where you want to check that an internet related string is
valid before handing it off to a Net::* modules.

It allows you to catch errors early, and with more detailed error messages
than you are likely to get further down in the Net::* modules.

Whenever a test is false, you can access the reason through the C<reason>
method.

=head1 METHODS

=head2 host $host

The C<host> method is used to see if a value is a valid host. That is, it is
either a domain name, or an ip address.

=head2 domain $domain [, @options ]

The C<domain> method is used to check for a valid domain name according to
RFC 1034. It additionally disallows two consective dashes 'foo--bar'. I've
never seen it used, and it's probably a mistaken version of 'foo-bar'.

Depending on the options, additional checks may be made. No options are
available at this time

=head2 ip $ip

The C<ip> method is used to validate the format, of an ip address.
If called with no options, it will just do a basic format check of the ip,
checking that it conforms to the basic dotted quad format.

Depending on the options, additional checks may be made. No options are
available at this time

=head2 port $port

The C<port> method is used to test for a valid port number.

=head1 BUGS

Unknown

=head1 TO DO

This module is not all that completed. Just enough to do some basics. Feel
free to send me patches to add anything you like.

=over 4

=item Add support for networks

=item Add "exists" support

=item Add "dns" support for host names

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Validate-Net>

For other inquiries, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

Net::*

=head1 COPYRIGHT

Copyright 2002 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
