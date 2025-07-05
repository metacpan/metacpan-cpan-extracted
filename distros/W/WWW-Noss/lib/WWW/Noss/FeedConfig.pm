package WWW::Noss::FeedConfig;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use parent 'WWW::Noss::BaseConfig';

use List::Util qw(any min);

sub new {

	my ($class, %param) = @_;

	my $self = bless {}, $class;

	$self->initialize(%param);

	return $self;

}

sub initialize {

	my ($self, %param) = @_;

	$self->SUPER::initialize;
	$self->set_name($param{ name });
	$self->set_feed($param{ feed });
	$self->set_path($param{ path });
	$self->set_etag($param{ etag });

	my $default = $param{ default };

	# Apply default parameters
	if (defined $default) {
		$self->set_limit($default->limit);
		$self->set_respect_skip($default->respect_skip);
		$self->set_include_title($default->include_title);
		$self->set_exclude_title($default->exclude_title);
		$self->set_include_content($default->include_content);
		$self->set_exclude_content($default->exclude_content);
		$self->set_include_tags($default->include_tags);
		$self->set_exclude_tags($default->exclude_tags);
		$self->set_autoread($default->autoread);
		$self->set_default_update($default->default_update);
		$self->set_hidden($default->hidden);
	}

	$self->set_groups($param{ groups } // []);

	if (@{ $self->groups }) {

		# Set lowest limit defined by groups if present
		my $limit = min grep { defined } map { $_->limit } @{ $self->groups };
		$self->set_limit($limit) if defined $limit;

		# If any group respects skip, we respect skip
		my $rs = any { $_->respect_skip } @{ $self->groups };
		$self->set_respect_skip($rs);

		# Overlay group filters
		push @{ $self->include_title },
			map { @{ $_->include_title // [] } }
			@{ $self->groups };
		push @{ $self->exclude_title },
			map { @{ $_->exclude_title // [] } }
			@{ $self->groups };
		push @{ $self->include_content },
			map { @{ $_->include_content // [] } }
			@{ $self->groups };
		push @{ $self->exclude_content },
			map { @{ $_->exclude_content // [] } }
			@{ $self->groups };
		push @{ $self->include_tags },
			map { @{ $_->include_tags // [] } }
			@{ $self->groups };
		push @{ $self->exclude_tags },
			map { @{ $_->exclude_tags // [] } }
			@{ $self->groups };

		# If any group wants autoread, we'll take autoread
		my $ar = any { $_->autoread } @{ $self->groups };
		$self->set_autoread($ar);

		# If any group does not want default_updates, we'll take no default
		# updates
		my $ndu = any { !$_->default_update } @{ $self->groups };
		$self->set_default_update(!$ndu);

		# If any groups wants hidden, take hidden
		my $hid = any { $_->hidden } @{ $self->groups };
		$self->set_hidden($hid);

	}

	if (defined $param{ limit }) {
		$self->set_limit($param{ limit });
	}
	if (defined $param{ respect_skip }) {
		$self->set_respect_skip($param{ respect_skip });
	}
	if (defined $param{ include_title }) {
		push @{ $self->include_title }, @{ $param{ include_title } };
	}
	if (defined $param{ exclude_title }) {
		push @{ $self->exclude_title }, @{ $param{ exclude_title } };
	}
	if (defined $param{ include_content }) {
		push @{ $self->include_content }, @{ $param{ include_content } };
	}
	if (defined $param{ exclude_content }) {
		push @{ $self->exclude_content }, @{ $param{ exclude_content } };
	}
	if (defined $param{ include_tags }) {
		push @{ $self->include_tags }, @{ $param{ include_tags } };
	}
	if (defined $param{ exclude_tags }) {
		push @{ $self->exclude_tags }, @{ $param{ exclude_tags } };
	}
	if (defined $param{ autoread }) {
		$self->set_autoread($param{ autoread });
	}
	if (defined $param{ default_update }) {
		$self->set_default_update($param{ default_update });
	}
	if (defined $param{ hidden }) {
		$self->set_hidden($param{ hidden });
	}

	return 1;

}

sub name {

	my ($self) = @_;

	return $self->{ Name };

}

sub set_name {

	my ($self, $name) = @_;

	unless (defined $name) {
		die "name cannot be undefined";
	}

	# ':' feeds are reserved for internal use
	unless ($name =~ /^\:?\w+$/) {
		die "name can only contain alphanumeric and underscore characters";
	}

	$self->{ Name } = $name;

}

sub feed {

	my ($self) = @_;

	return $self->{ Feed };

}

sub set_feed {

	my ($self, $feed) = @_;

	unless (defined $feed) {
		die "feed cannot be undefined";
	}

	$self->{ Feed } = $feed;

}

sub groups {

	my ($self) = @_;

	return $self->{ Groups };

}

sub set_groups {

	my ($self, $new) = @_;

	unless (ref $new eq 'ARRAY') {
		die "groups must be an array ref";
	}

	for my $i (0 .. $#$new) {
		unless ($new->[$i]->isa('WWW::Noss::GroupConfig')) {
			die "group[$i] is not a WWW::Noss::GroupConfig object";
		}
	}

	$self->{ Groups } = $new;

}

sub has_group {

	my ($self, $grp) = @_;

	return !! grep { $_->name eq $grp } @{ $self->groups };

}

sub path {

	my ($self) = @_;

	return $self->{ Path };

}

sub set_path {

	my ($self, $path) = @_;

	unless (defined $path) {
		die "path cannot be undefined";
	}

	$self->{ Path } = $path;

}

sub etag {

	my ($self) = @_;

	return $self->{ Etag };

}

sub set_etag {

	my ($self, $etag) = @_;

	$self->{ Etag } = $etag;

}

1;

=head1 NAME

WWW::Noss::FeedConfig - Class for storing feed configurations

=head1 USAGE

  use WWW::Noss::FeedConfig;

  my $feed = WWW::Noss::FeedConfig->new(
	  name => 'feed',
	  feed => 'https://feed.xml',
	  path => 'feed.xml',
  );

=head1 DESCRIPTION

B<WWW::Noss::FeedConfig> is a module that provides a class for storing L<noss>
feed configurations. This is a private module, please consult the L<noss>
manual for user documentation.

=head1 METHODS

Not all methods are documented here, as this class is derived from the
L<WWW::Noss::BaseConfig> module. Consult its documentation for additional
methods.

=over 4

=item $feed = WWW::Noss::FeedConfig->new(%param)

Returns a blessed B<WWW::Noss::FeedConfig> object based on the parameters
provided in the C<%param> hash.

The following are valid fields for the C<%param> hash. The C<name>, C<feed>,
and C<path> fields are the only required fields.

=over 4

=item name

The name of feed. Can only only contain alphanumeric and underscore
characters.

=item feed

The feed URL.

=item path

Path to the location to store the feed.

=item etag

Path to store the feed's etag.

=item groups

Array ref of L<WWW::Noss::GroupConfig> groups that the feed is a part of.

=item default

L<WWW::Noss::GroupConfig> object representing the default feed group.

=back

The following fields from L<WWW::Noss::BaseConfig> are also available:

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

=item $name = $feed->name()

=item $feed->set_name($name)

Getter/setter for the feed's name attribute.

=item $url = $feed->feed()

=item $feed->set_feed($url)

Getter/setter for the feed's feed attribute.

=item \@groups = $feed->groups()

=item $feed->set_groups(\@groups)

Getter/setter for the feed's groups attribute. Do note that modifying the
groups attribute does not affect the feed's configuration like it does during
initialization.

=item $ok = $feed->has_group($group)

Returns true if C<$feed> is a part of the group C<$group>.

=item $path = $feed->path()

=item $feed->set_path($path)

Getter/setter for the feed's path attribute.

=item $etag = $feed->etag()

=item $feed->set_etag($etag)

Getter/setter for the feed's etag attribute.

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

L<WWW::Noss::BaseConfig>, L<WWW::Noss::GroupConfig>, L<noss>

=cut

# vim: expandtab shiftwidth=4
