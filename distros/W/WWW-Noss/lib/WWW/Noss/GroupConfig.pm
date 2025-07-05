package WWW::Noss::GroupConfig;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use parent 'WWW::Noss::BaseConfig';

sub new {

	my ($class, %param) = @_;

	my $self = bless {}, $class;

	$self->initialize(%param);

	return $self;

}

sub initialize {

	my ($self, %param) = @_;

	$self->SUPER::initialize(%param);
	$self->set_name($param{ name });
	$self->set_feeds($param{ feeds } // []);

	return 1;

}

sub name {

	my ($self) = @_;

	return $self->{ Name };

}

sub set_name {

	my ($self, $new) = @_;

	unless (defined $new) {
		die "group name cannot be undefined";
	}

	# ':' groups are reserved for internal use
	unless ($new =~ /^\:?\w+$/) {
		die "group name can only contain alphanumeric characters";
	}

	$self->{ Name } = $new;

}

sub feeds {

	my ($self) = @_;

	return $self->{ Feeds };

}

sub set_feeds {

	my ($self, $new) = @_;

	unless (ref $new eq 'ARRAY') {
		die "feeds must be an array ref";
	}

	$self->{ Feeds } = $new;

}

sub has_feed {

	my ($self, $feed) = @_;

	return !! grep { $feed eq $_ } @{ $self->feeds };

}

1;

=head1 NAME

WWW::Noss::GroupConfig - Class for storing feed group configurations

=head1 USAGE

  use WWW::Noss::GroupConfig;

  my $group = WWW::Noss::GroupConfig->new(
	  name  => 'name',
	  feeds => [ 'feed1', 'feed2' ],
  );

=head1 DESCRIPTION

B<WWW::Noss::GroupConfig> is a module that provides a class for storing feed
group configurations. This is a private module, please consult the L<noss>
manual for user documentation.

=head1 METHODS

Not all methods are documented here, as this class is derived from the
L<WWW::Noss::BaseConfig> module. Consult its documentation for additional
methods.

=over 4

=item $group = WWW::Noss::GroupConfig->new(%param)

Returns a blessed B<WWW::Noss::GroupConfig> object based on the parameters
provided in the C<%param> hash.

The following are valid fields for the C<%param> hash. The only required field
is C<name>.

=over 4

=item name

Name of the feed group. Can only contain alphanumeric and underscore
characters.

=item feeds

Array ref of feed names that the group contains.

=back

The following fields from the L<WWW::Noss::BaseConfig> module are also
available:

=over 4

=item limit

=item respect_skip

=item include_title

=item exclude_title

=item include_content

=item exclude_content

=item include_tags

=item exclude_tags

=item autoread

=item default_update

=item hidden

=back

=item $name = $group->name()

=item $group->set-name($name)

Getter/setter for the group's name attribute.

=item $feeds = $group->feeds()

=item $group->set_feeds($feeds)

Getter/setter for the group's feeds attribute.

=item $ok = $group->has_feed($feed)

Returns true if C<$group> has the feed C<$feed>.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<WWW::Noss::BaseConfig>, L<WWW::Noss::FeedConfig>, L<noss>

=cut

# vim: expandtab shiftwidth=4
