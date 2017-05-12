package URI::pack;

use 5.008003;
use strict;
use warnings 'all';

###############################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.002001';

###############################################################################
# MODULES
use Carp qw(croak);
use Const::Fast qw(const);
use URI;
use URI::Escape qw(uri_escape uri_unescape);

###############################################################################
# INHERIT FROM PARENT CLASS
use parent qw(URI::_generic);

###############################################################################
# CONSTANTS
const my $UNRESERVED  => qr{[0-9A-Za-z\-\._~]}msx;
const my $PCT_ENCODED => qr{\%[0-9A-Fa-f]{2}}msx;
const my $SUB_DELIMS  => qr{[!\$\&'\(\)\*\+,;=]}msx;
const my $PCHAR       => qr{(?:$UNRESERVED|$PCT_ENCODED|$SUB_DELIMS|[:\@])}msx;

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean;

###############################################################################
# METHODS
sub clear_package_uri {
	my ($self) = @_;

	# This will remove the package by changing the authority to q{}
	$self->authority(q{});

	return;
}
sub clear_part_name {
	my ($self) = @_;

	# This will remove the part name by changing the path to /
	$self->path(q{/});

	return;
}
sub has_package_uri {
	my ($self) = @_;

	# Does this URI have a package?
	return defined $self->authority && $self->authority ne q{};
}
sub has_part_name {
	my ($self) = @_;

	# Does this URI have a part name?
	return $self->path ne q{} && $self->path ne q{/};
}
sub package_uri {
	my ($self, $new_package) = @_;

	# Get the package according to ECMA-376, Part 2, section B.2
	# Call the normal authority and get the result
	my $authority = $self->authority;

	# Replace all commas with forward slashes
	$authority =~ s{,}{/}gmsx;

	# Unescape the authority
	$authority = uri_unescape($authority);

	if (defined $new_package) {
		# Set a new authority according to ECMA-376, Part 2, section B.3
		# Make sure the new package is a URI
		$new_package = URI->new($new_package);

		# Remove the fragment
		$new_package->fragment(q{});

		# Escape all %, ?, @, :, and , characters
		## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
		$new_package = uri_escape($new_package, '%?@:,');

		# Replace all forward slashes with commas
		$new_package =~ s{/}{,}gmsx;

		# Set the resulting string as the authority
		$self->authority($new_package);
	}

	# Return the authority as an URI object
	return URI->new($authority);
}
sub part_name {
	my ($self, $new_part_name) = @_;

	# The part name is simply the path
	my $part_name = $self->path;

	if (defined $new_part_name) {
		# Set the new part name
		if ($self->_is_valid_part_uri($new_part_name)) {
			# Set the new part name since it is valid
			$self->path($new_part_name);
		}
		else {
			croak 'The part name given was not a valid part name was thus was not set';
		}
	}

	if (!$self->has_part_name) {
		return;
	}

	return $part_name;
}
sub part_name_segments {
	my ($self, @new_part_name_segments) = @_;

	# Get the path segments
	my @path_segments = $self->path_segments;

	# Remove the first path segment, as it is q{}
	if (@path_segments && $path_segments[0] eq q{}) {
		shift @path_segments;
	}

	if (@new_part_name_segments) {
		# Set the new part name
		$self->part_name(q{/} . join q{/}, @new_part_name_segments);
	}

	return @path_segments;
}

###############################################################################
# PRIVATE METHODS
sub _check_uri {
	my ($self) = @_;

	# If the URI has a part name, check it
	if ($self->has_part_name) {
		# Check the part
		$self->_is_valid_part_uri($self->path);
	}

	# Must have either package or part name
	if (!$self->has_package_uri && !$self->has_part_name) {
		croak 'Not a valid URI';
	}

	return $self;
}
sub _init { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	my ($class, $uri, $scheme) = @_;

	# Create and bless into class using default _init
	my $self = $class->SUPER::_init($uri, $scheme);

	# Check the URI
	$self->_check_uri();

	return $self;
}
sub _is_valid_part_uri {
	my ($self, $part_uri) = @_;

	# Validate a part URI according to ECMA-376 Part 2, section 9.1.1.1.2

	if ($part_uri eq q{}) {
		croak 'A part URI shall not be empty [M1.1]';
	}

	if ($part_uri !~ m{\A /}msx) {
		croak 'A part URI shall start with a forward slash ("/") character [M1.4]';
	}

	if ($part_uri =~ m{/ \z}msx) {
		croak 'A part URI shall not have a forward slash as the last character [M1.5]';
	}

	# Split the part URI into segments
	my @segments = split m{/}msx, $part_uri;

	# Remove the first empty segment
	if ($segments[0] eq q{}) {
		shift @segments;
	}

	foreach my $segment (@segments) {
		if ($segment eq q{}) {
			croak 'A part URI shall not have empty segments [M1.3]';
		}

		if ($segment !~ m{\A (?:$PCHAR)+ \z}msx) {
			croak 'A segments shall not hold any characters other than pchar characters [M1.6]';
		}

		if ($segment =~ m{\%(?:2f|5c)}imsx) {
			croak 'A segments shall not contain percent-encoded forward slash ("/"), or backward slash ("\") characters [M1.7]';
		}

		while ($segment =~ m{%([0-9a-f]{2})}gimsx) {
			# Convert the byte into the original character
			my $character = chr hex $1;

			if ($character =~ m{\A [0-9A-Z\-\._~] \z}imsx) {
				croak 'A segment shall not contain percent-encoded unreserved characters [M1.8]';
			}
		}

		if ($segment =~ m{\. \z}msx) {
			croak 'A segment shall not end with a dot (".") character [M1.9]';
		}

		if ($segment !~ m{[^\.]+}msx) {
			croak 'A segment shall include at least one non-dot character [M1.10]';
		}
	}

	return 1;
}
sub _no_scheme_ok { return 0; } ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

1;

__END__

=head1 NAME

URI::pack - Support of the pack scheme in URI.

=head1 VERSION

This documentation refers to version 0.002001.

=head1 SYNOPSIS

  use URI;

  # New absolute pack URI
  my $pack_uri = URI->new('pack://application,,,/ResourceFile.xaml');

  # New relative pack URI
  my $rel_pack_uri = URI->new('/images/logo.png', 'pack');

=head1 DESCRIPTION

This module will have pack URIs as given to the L<URI module|URI> blessed into
this class instead of L<URI::_generic|URI::_generic>. This class provides extra
pack-specific functionality.

=head1 ATTRIBUTES

This object provides multiple attributes. Calling the attribute as a method
with no arguments will return the value of the attribute. Calling the attribute
with one argument will set the value of the attribute to be that value and
returns the old value.

  # Get the value of an attribute
  my $package = $uri->package_uri;

  # Set the value of an attribute
  my $old_package = $uri->package_uri($package);

=head2 package_uri

This is the L<URI|URI> of the package.

=head2 part_name

This is the part name in the pack URI. If there is no part name, then C<undef>
is returned.

=head2 part_name_segments

This is an array of the segments in the part name. A part name of
C</hello/world/doc.xml> has three segments: C<hello>, C<world>, C<doc.xml>.

=head1 METHODS

=head2 clear_package_uri

This will clear the L</package_uri> attribute.

=head2 clear_part_name

This will clear the L</part_name> attribute.

=head2 has_package_uri

This will return a Boolean of the presence of a L</package_uri> in the pack URI.

=head2 has_part_name

This will return a Boolean of the presence of a L</part_name> in the pack URI.

=head1 DEPENDENCIES

=over

=item * L<Carp|Carp>

=item * L<Const::Fast|Const::Fast>

=item * L<URI|URI>

=item * L<URI::Escape|URI::Escape>

=item * L<namespace::clean|namespace::clean>

=item * L<parent|parent>

=back

=head1 SEE ALSO

=over

=item * L<URI|URI> the the base class, so you may want to look at the methods that
are provided.

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-uri-pack at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-pack>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc URI::pack

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-pack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-pack>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-pack/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
