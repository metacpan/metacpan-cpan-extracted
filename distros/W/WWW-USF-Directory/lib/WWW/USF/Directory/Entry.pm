package WWW::USF::Directory::Entry;

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
use MooseX::Types::Email qw(
	EmailAddress
);

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has 'affiliations' => (
	is  => 'ro',
	isa => 'ArrayRef[WWW::USF::Directory::Entry::Affiliation]',

	default       => sub { [] },
	documentation => q{This is the list of affiliations to USF},
);
has 'campus' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the campus the entry is affiliated with},
	clearer       => '_clear_campus',
	predicate     => 'has_campus',
);
has 'campus_mailstop' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the mailstop for he entry on campus},
	clearer       => '_clear_campus_mailstop',
	predicate     => 'has_campus_mailstop',
);
has 'campus_phone' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the campus phone number},
	clearer       => '_clear_campus_phone',
	predicate     => 'has_campus_phone',
);
has 'college' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the college the entry is affiliated with},
	clearer       => '_clear_college',
	predicate     => 'has_college',
);
has 'email' => (
	is  => 'ro',
	isa => EmailAddress,

	documentation => q{This is the e-mail address},
	clearer       => '_clear_email',
	predicate     => 'has_email',
);
has 'family_name' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the family name},
	required      => 1,
);
has 'first_name' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the first name},
	required      => 1,
);
has 'given_name' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the given name},
	required      => 1,
);
has 'middle_name' => (
	is  => 'ro',
	isa => NonEmptySimpleStr,

	documentation => q{This is the middle name},
	clearer       => '_clear_middle_name',
	predicate     => 'has_middle_name',
);

###########################################################################
# METHODS
sub full_name {
	my ($self) = @_;

	# The full name is the given name and family name
	return join q{ }, $self->given_name, $self->family_name;
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::Directory::Entry - An entry in the USF online directory

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  # Print the family name
  say $entry->family_name;

=head1 DESCRIPTION

This represents an entry in the USF online directory. These objects are
typically created by L<WWW::USF::Directory|WWW::USF::Directory>.

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

=back

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 affiliations

This is the list of affiliations to USF as
L<WWW::USF::Directory::Entry::Affiliation|WWW::USF::Directory::Entry::Affiliation>
objects.

=head2 campus

This is the campus the entry is affiliated with.

=head2 campus_mailstop

This is the mailstop for he entry on campus.

=head2 campus_phone

This is the campus phone number.

=head2 college

This is the college the entry is affiliated with.

=head2 email

This is the e-mail address.

=head2 family_name

This is the family name.

=head2 first_name

This is the first name.

=head2 given_name

This is the given name.

=head2 middle_name

This is the middle name.

=head1 METHODS

=head2 full_name

This will return the full name, which is the given name and the family name
joined with a space.

=head2 has_campus

This returns a Boolean of if the L</campus> attribute is set.

=head2 has_campus_mailstop

This returns a Boolean of if the L</campus_mailstop> attribute is set.

=head2 has_campus_phone

This returns a Boolean of if the L</campus_phone> attribute is set.

=head2 has_college

This returns a Boolean of if the L</college> attribute is set.

=head2 has_email

This returns a Boolean of if the L</email> attribute is set.

=head2 has_middle_name

This returns a Boolean of if the L</middle_name> attribute is set.

=head1 DEPENDENCIES

=over 4

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<MooseX::Types::Moose|MooseX::Types::Moose>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-www-usf-directory at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-USF-Directory>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc WWW::USF::Directory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-USF-Directory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-USF-Directory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-USF-Directory>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-USF-Directory/>

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
