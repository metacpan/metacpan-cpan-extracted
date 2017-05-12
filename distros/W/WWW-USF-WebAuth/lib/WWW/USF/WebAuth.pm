package WWW::USF::WebAuth;

use 5.008003;
use strict;
use warnings 'all';

# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.003001';

# MOOSE
use Moose 1.03;
use MooseX::Aliases 0.05;
use MooseX::StrictConstructor 0.09;

# MOOSE TYPES
use MooseX::Types::Moose qw(Str);

# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

# MOOSE PARENT CLASSES
extends 'Authen::CAS::External' => {-version => '0.05'};

# ATTRIBUTES
has '+cas_url' => (
	# Add the default URL to be WebAuth
	default => 'https://webauth.usf.edu',
);

# Setup an alias for netid to be the same as username
alias 'netid'       => 'username';
alias 'has_netid'   => 'has_username';
alias 'clear_netid' => 'clear_username';

# CONSTRUCTOR
around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;

	# Get the arguments as a HASHREF
	my $args = $class->$orig(@args);

	if (exists $args->{netid}) {
		# The constructor was provided with the netid argument. Re-map it
		# to the username argument (overwriting whatever was there).
		$args->{username} = delete $args->{netid};
	}

	return $args;
};

# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::WebAuth - Access to USF's WebAuth system

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  use Carp ();
  use WWW::USF::WebAuth ();

  # Create a new WebAuth object
  my $webauth = WWW::USF::WebAuth->new(
      netid    => 'teststudent',
      password => 'PassW0rd!',
  );

  my $response = $webauth->authenticate(
      # Connect to USF Blackboard system
      service => 'https://learn.usf.edu/webapps/login/?new_loc=useCas'
  );

  if (!$response->is_success) {
      # Authentication failed, so just bail here
      Carp::carp('Authentication with WebAuth failed');
  }

  # The authentication was successful
  printf qq{You may navigate to %s and be logged in as %s\n},
      $response->destination,
      $webauth->netid;

=head1 DESCRIPTION

This provides a way in which you can interact with the WebAuth system at the
University of South Florida.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with. Please see
the documentation for L<Authen::CAS::External|Authen::CAS::External>.

=head1 ATTRIBUTES

Please see the documentation for L<Authen::CAS::External|Authen::CAS::External>.

=head2 netid

This is a string which is the NetID of the user. This attribute directly maps
to the inherited C<username> attribute.

=head1 METHODS

This module provides the identical methods as
L<Authen::CAS::External|Authen::CAS::External> and you should look at the
documentation for the supported methods.

=head2 clear_netid

This will clear the value for L</netid>.

=head2 has_netid

This will report if the current instance has L</netid> defined.

=head1 DEPENDENCIES

=over 4

=item * L<Authen::CAS::External|Authen::CAS::External> 0.05

=item * L<Moose|Moose> 1.03

=item * L<MooseX::Aliases|MooseX::Aliases> 0.05

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.09

=item * L<MooseX::Types::Moose|MooseX::Types::Moose>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-www-usf-webauth at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-USF-WebAuth>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc WWW::USF::WebAuth

You can also look for information at:

=over 4

=item * RT: Request tracker for CPAN

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-USF-WebAuth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-USF-WebAuth>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-USF-WebAuth/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
