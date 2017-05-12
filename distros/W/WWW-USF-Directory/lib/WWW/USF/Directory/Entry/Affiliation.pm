package WWW::USF::Directory::Entry::Affiliation;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.003001';

###########################################################################
# MOOSE
use Moose 0.89;
use MooseX::StrictConstructor 0.08;

###########################################################################
# MOOSE TYPES
use MooseX::Types::Common::String qw(
	NonEmptySimpleStr
);

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# OVERLOADED FUNCTIONS
__PACKAGE__->meta->add_package_symbol(q{&()}  => sub {                  });
__PACKAGE__->meta->add_package_symbol(q{&(""} => sub { shift->stringify });

###########################################################################
# ATTRIBUTES
has 'department' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{The department this role is in},
	clearer       => '_clear_department',
	predicate     => 'has_department',
);
has 'role' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{The role of the person in the department},
	required      => 1,
);

###########################################################################
# METHODS
sub stringify {
	# The default stringify method returns role: department or role
	my ($self) = @_;

	# Start the string with the role
	my $string = $self->role;

	if ($self->has_department) {
		# Add on the department
		$string .= ': ' . $self->department;
	}

	return $string;
}

###########################################################################
# CONSTRUCTOR
sub BUILDARGS {
	my ($class, @args) = @_;

	if (@args == 1 && ref $args[0] eq q{}) {
		# It looks like a single string was passed to the constructor, so
		# parse the string.
		my ($role, $department) = $args[0] =~ m{\A (.+?) (?: \s+ : \s+ (.+?) )? \z}msx;

		# Set the new arguments with the role
		@args = (role => $role);

		if (defined $department) {
			# Add the department if defined
			push @args, department => $department;
		}
	}

	# Continue building
	return $class->SUPER::BUILDARGS(@args);
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::Directory::Entry::Affiliation - Information about an affiliation of
an entry

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  # Print the afflilation
  say $affiliation;

  # Does the affiliation have a department?
  say $affiliation->has_department ? 'yes' : 'no';

=head1 DESCRIPTION

Information about an affiliation of an entry. These objects are typically
created by L<WWW::USF::Directory|WWW::USF::Directory>.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new object.

=over

=item B<new(%attributes)>

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($attributes)>

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($role_department_string)>

This is a special case where the C<$role_department_string> is a string that
came from the directory page in the format C<role \s+ : \s+ department>.

=back

=head1 ATTRIBUTES

=head2 department

This is the department in which the affiliation applies.

=head2 role

B<Required>. This is the role of the affiliation.

=head1 METHODS

=head2 stringify

This method is used to return a string that will be given when this object is
used in a string context. This returns "role: department" or "role".

  my $affiliation = WWW::USF::Directory::Entry::Affiliation->new(
      role       => 'My Role'
      department => 'Department'
  );

  say $affiliation; # Prints "My Role: Department"

=head1 DEPENDENCIES

=over

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-www-usf-directory at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW::USF::Directory>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

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
