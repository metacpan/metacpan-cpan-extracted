package Test::Override::UserAgent::Scope;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.004001';

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use LWP::Protocol; # Not actually required here, but want it to be loaded
use Scalar::Util;
use Sub::Install 0.90;
use Sub::Override;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# METHODS
sub scheme_implementor {
	my ($self, $scheme) = @_;

	# Lower-case scheme
	$scheme = lc $scheme;

	if (!exists $self->{_protocol_classes}->{$scheme}) {
		# Create a new scheme implementor
		$self->_create_scheme_implementor($scheme);
	}

	# Return the name of the class to use
	return $self->{_protocol_classes}->{$scheme};
}

###########################################################################
# CONSTRUCTOR
sub new {
	my ($class, @args) = @_;

	# Get the arguments as a plain hash
	my %args = @args == 1 ? %{shift @args}
	                      : @args
	                      ;

	# Create a hash with configuration information
	my %data = (
		# Attributes
		override => undef,

		# Private attributes
		_original_implementor_lookup => undef,
		_protocol_classes            => {},
	);

	# Set attributes
	foreach my $arg (grep { m{\A [^_]}msx } keys %data) {
		if (exists $args{$arg}) {
			$data{$arg} = $args{$arg};
		}
	}

	if (!defined $data{override}) {
		croak 'Must supply override attribute';
	}

	# Bless the hash to this class
	my $self = bless \%data, $class;

	# Set our unique name
	$self->{_uniq_name} = $class . '::Number' . Scalar::Util::refaddr($self);

	# Get the current implementor lookup
	$self->{_original_implementor_lookup} = \&LWP::Protocol::implementor;

	# Store the scope override reference
	$self->{_scope_override} = $self->_install_in_scope;

	# Return our blessed configuration
	return $self;
}

###########################################################################
# DESTRUCTOR
sub DESTROY {
	my ($self) = @_;

	# Destroy the override
	undef $self->{_scope_override};

	# Destroy all the created packages
	foreach my $scheme (keys %{$self->{_protocol_classes}}) {
		$self->_destroy_scheme_implementor($scheme);
	}

	return;
}

###########################################################################
# PRIVATE METHODS
sub _create_scheme_implementor {
	my ($self, $scheme) = @_;

	# Calculate a new scheme class name
	my $new_scheme_class = sprintf '%s::%s',
		$self->{_uniq_name}, $scheme;

	# Install new() into the scheme class
	Sub::Install::install_sub({
		into => $new_scheme_class,
		as   => 'new',
		code => $self->_generate_scheme_new,
	});

	# Install request() into the scheme class
	Sub::Install::install_sub({
		into => $new_scheme_class,
		as   => 'request',
		code => $self->_generate_scheme_request($scheme),
	});

	# Save the name of the new class
	$self->{_protocol_classes}->{$scheme} = $new_scheme_class;

	return $new_scheme_class;
}
sub _destroy_scheme_implementor {
	my ($self, $scheme) = @_;

	# Get the package name of the scheme
	my $package = $self->{_protocol_classes}->{$scheme};

	if (defined $package) {
		# Delete new and request methods
		undef &{$package . '::new'};
		undef &{$package . '::request'};
	}

	return;
}
sub _generate_scheme_new {
	my ($self) = @_;

	return sub {
		my ($class, $scheme, $ua) = @_;

		my $object = bless {
			scheme => $scheme,
			ua     => $ua,
		}, $class;

		return $object;
	}
}
sub _generate_scheme_request {
	my ($self, $scheme) = @_;

	# Copy self
	my $weak_self = $self;

	# Weaken the self reference
	Scalar::Util::weaken($weak_self);

	return sub {
		my ($proto_self, $request, $proxy, $arg, $size, $timeout) = @_;

		# Get the override object
		my $override = $weak_self->{override};

		# Process the request by us
		my $response = $override->handle_request(
			$request,
			live_request_handler => sub {
				# Get the normal implementor
				my $implementor_class = $weak_self->{_original_implementor_lookup}->($scheme);

				if (!defined $implementor_class) {
					croak "Protocol scheme '$scheme' is not supported";
				}

				# Create a new instance
				my $implementor = $implementor_class->new($proto_self->{qw(scheme ua)});

				# Make the request
				my $live_response = $implementor->request($request, $proxy, $arg, $size, $timeout);

				return $live_response;
			},
		);

		return $response;
	};
}
sub _install_in_scope {
	my ($self) = @_;

	# Get the current implementor lookup
	my $implementor_lookup = \&LWP::Protocol::implementor;

	# Created a weakened self to allow for destruction
	my $weak_self = $self;
	Scalar::Util::weaken($weak_self);

	# Create an override for the current scope
	my $override = Sub::Override->new(
		'LWP::Protocol::implementor' => sub { return $weak_self->scheme_implementor(shift); },
	);

	return $override;
}

1;

__END__

=head1 NAME

Test::Override::UserAgent::Scope - Scoping the user agent overrides

=head1 VERSION

This documentation refers to version 0.004001

=head1 SYNOPSIS

  # $scope created by Test::Override::UserAgent

  # Say the class name the implements the given scheme
  say $scope->scheme_implementor($scheme);

=head1 DESCRIPTION

This module is a used to specify a scope that L<LWP::UserAgent|LWP::UserAgent>
will be overridden with the specified configuration.

=head1 CONSTRUCTOR

=head2 new

This will construct a new configuration object to allow for configuring user
agent overrides.

=over 4

=item B<new(%attributes)>

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($attributes)>

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

=head2 override

This is a L<Test::Override::UserAgent|Test::Override::UserAgent> object that
specifies the configuration to use for this override.

=head1 METHODS

=head2 scheme_implementor

This takes the name of a scheme and returns the name of the class that will
implement L<LWP::Protocol|LWP::Protocol> for that scheme.

=head1 DEPENDENCIES

=over 4

=item * L<Carp|Carp>

=item * L<LWP::Protocol|LWP::Protocol>

=item * L<Scalar::Util|Scalar::Util>

=item * L<Sub::Install|Sub::Install> 0.90

=item * L<Sub::Override|Sub::Override>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-test-override-useragent at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Override-UserAgent>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Test::Override::UserAgent::Scope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Override-UserAgent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Override-UserAgent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Override-UserAgent>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Override-UserAgent/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
