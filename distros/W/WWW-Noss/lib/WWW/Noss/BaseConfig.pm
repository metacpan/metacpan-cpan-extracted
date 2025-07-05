package WWW::Noss::BaseConfig;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use List::Util qw(any all);

sub new {

	my ($class, %param) = @_;

	my $self = bless {}, $class;

	$self->initialize(%param);

	return $self;

}

sub initialize {

	my ($self, %param) = @_;

	$self->set_limit($param{ limit });
	$self->set_respect_skip($param{ respect_skip } // 1);
	$self->set_include_title($param{ include_title } // []);
	$self->set_exclude_title($param{ exclude_title } // []);
	$self->set_include_content($param{ include_content } // []);
	$self->set_exclude_content($param{ exclude_content } // []);
	$self->set_include_tags($param{ include_tags } // []);
	$self->set_exclude_tags($param{ exclude_tags } // []);
	$self->set_autoread($param{ autoread } // 0);
	$self->set_default_update($param{ default_update } // 1);
	$self->set_hidden($param{ hidden } // 0);

	return 1;

}

sub limit {

	my ($self) = @_;

	return $self->{ Limit };

}

sub set_limit {

	my ($self, $new) = @_;

	if (defined $new and $new <= 0) {
		die "limit must be greater than 0";
	}

	$self->{ Limit } = $new;

}

sub respect_skip {

	my ($self) = @_;

	return $self->{ RespectSkip };

}

sub set_respect_skip {

	my ($self, $new) = @_;

	$self->{ RespectSkip } = !! $new;

}

sub include_title {

	my ($self) = @_;

	return $self->{ IncludeTitle };

}

sub set_include_title {

	my ($self, $new) = @_;

	if (ref $new ne 'ARRAY') {
		die "include_title must be an array ref";
	}

	$self->{ IncludeTitle } = $new;

}

sub exclude_title {

	my ($self) = @_;

	return $self->{ ExcludeTitle };

}

sub set_exclude_title {

	my ($self, $new) = @_;

	if (ref $new ne 'ARRAY') {
		die "exclude_title must be an array ref";
	}

	$self->{ ExcludeTitle } = $new;

}

sub title_ok {

	my ($self, $title) = @_;

	if (@{ $self->include_title }) {
		unless (defined $title) {
			return 0;
		}
		unless (all { $title =~ $_ } @{ $self->include_title }) {
			return 0;
		}
	}

	if (@{ $self->exclude_title }) {
		unless (defined $title) {
			return 1;
		}
		if (any { $title =~ $_ } @{ $self->exclude_title }) {
			return 0;
		}
	}

	return 1;

}

sub include_content {

	my ($self) = @_;

	return $self->{ IncludeContent };

}

sub set_include_content {

	my ($self, $new) = @_;

	if (ref $new ne 'ARRAY') {
		die "include_content must be an array ref";
	}

	$self->{ IncludeContent } = $new;

}

sub exclude_content {

	my ($self) = @_;

	return $self->{ ExcludeContent };

}

sub set_exclude_content {

	my ($self, $new) = @_;

	if (ref $new ne 'ARRAY') {
		die "exclude_content must be an array ref";
	}

	$self->{ ExcludeContent } = $new;

}

sub content_ok {

	my ($self, $content) = @_;

	if (@{ $self->include_content }) {
		unless (defined $content) {
			return 0;
		}
		if (not all { $content =~ $_ } @{ $self->include_content }) {
			return 0;
		}
	}

	if (@{ $self->exclude_content }) {
		unless (defined $content) {
			return 1;
		}
		if (any { $content =~ $_ } @{ $self->exclude_content }) {
			return 0;
		}
	}

	return 1;

}

sub include_tags {

	my ($self) = @_;

	return $self->{ IncludeTags };

}

sub set_include_tags {

	my ($self, $new) = @_;

	if (ref $new ne 'ARRAY') {
		die "include_tags must be an array ref";
	}

	$self->{ IncludeTags } = $new;

}

sub exclude_tags {

	my ($self) = @_;

	return $self->{ ExcludeTags };

}

sub set_exclude_tags {

	my ($self, $new) = @_;

	if (ref $new ne 'ARRAY') {
		die "exclude_tags must be an array ref";
	}

	$self->{ ExcludeTags } = $new;

}

sub tags_ok {

	my ($self, $tags) = @_;

	my %tagmap = map { fc $_ => 1 } @$tags if defined $tags;

	if (@{ $self->include_tags }) {
		unless (defined $tags) {
			return 0;
		}
		if (any { not exists $tagmap{ fc $_ } } @{ $self->include_tags }) {
			return 0;
		}
	}

	if (@{ $self->exclude_tags }) {
		unless (defined $tags) {
			return 1;
		}
		if (any { exists $tagmap{ fc $_ } } @{ $self->exclude_tags }) {
			return 0;
		}
	}

	return 1;

}

sub autoread {

	my ($self) = @_;

	return $self->{ Autoread };

}

sub set_autoread {

	my ($self, $read) = @_;

	$self->{ Autoread } = !! $read;

}

sub default_update {

	my ($self) = @_;

	return $self->{ DefaultUpdate };

}

sub set_default_update {

	my ($self, $new) = @_;

	$self->{ DefaultUpdate } = !! $new;

}

sub hidden {

	my ($self) = @_;

	return $self->{ Hidden };

}

sub set_hidden {

	my ($self, $new) = @_;

	$self->{ Hidden } = !! $new;

}

=head1 NAME

WWW::Noss::BaseConfig - Base class for feed configuration classes

=head1 USAGE

  use parent 'WWW::Noss::BaseConfig';

=head1 DESCRIPTION

B<WWW::Noss::BaseConfig> is a class that implements the base functionality for
the L<WWW::Noss::FeedConfig> and L<WWW::Noss::GroupConfig> modules. This is a
private module, please consult the L<noss> manual for user documentation.

=head1 METHODS

=over 4

=item $conf = WWW::Noss::BaseConfig->new(%param)

Default constructor for B<WWW::Noss::BaseConfig>. Parameters are supplied via
the C<%param> hash.

The following are valid fields for C<%param>:

=over 4

=item limit

Post limit. Should be an integar that is greater than C<0>, or C<undef> for no
limit.

=item respect_skip

Boolean determining whether the B<skipHours> and B<skipDays> fields in RSS
feeds should be respected.

=item include_title

Array ref of regexes that post titles must match in order to not be filtered
out.

=item exclude_title

Array ref of regexes that post titles must NOT match in order to not be
filtered out.

=item include_content

Array ref of regexes that a post's content must match in order to not be
filtered out.

=item exclude_content

Array ref of regexes that a post's content must NOT match in order to not be
filtered out.

=item include_tags

Array ref of tags that a post must have in order to not be filtered out.

=item exclude_tags

Array ref of tags that a post must NOT have in order to not be filtered out.

=item autoread

Boolean determining whether new posts will automatically be marked as read or
not.

=item default_update

Boolean determining whether a feed should be included in a default update or
not.

=item hidden

Boolean determining whether a feed should be omitted from the C<list> command's
default listing.

=back

=item $limit = $conf->limit()

=item $conf->set_limit($limit)

Getter/setter for the C<limit> attribute.

=item $respect = $conf->respect_skip()

=item $conf->set_respect_skip($respect)

Getter/setter for the C<respect_skip> attribute.

=item \@inc = $conf->include_title()

=item $conf->set_include_title(\@inc)

=item \@exc = $conf->exclude_title()

=item $conf->set_exclude_title(\@exc)

Getter/setters for the C<include_title> and C<exclude_title> attributes.

=item \@inc = $conf->include_content()

=item $conf->set_include_content(\@inc)

=item \@exc = $conf->exclude_content()

=item $conf->set_exclude_content(\@exc)

Getter/setters for the C<include_content> and C<exclude_content> attributes.

=item \@inc = $conf->include_tags()

=item $conf->set_include_tags(\@inc)

=item \@exc = $conf->exclude_tags()

=item $conf->set_exclude_tags(\@exc)

Getter/setters for the C<include_tags> and C<exclude_tags> attributes.

=item $autoread = $conf->autoread()

=item $conf->set_autoread($autoread)

Getter/setter for the C<autoread> attribute.

=item $default = $conf->default_update()

=item $conf->set_default_update($default)

Getter/setter for the C<default_update> attribute.

=item $hidden = $conf->hidden()

=item $conf->set_hidden($hidden)

Getter/setter for the C<hidden> attribute.

=item $ok = $conf->title_ok($title)

=item $ok = $conf->content_ok($content)

=item $ok = $conf->tags_ok(\@tags)

Methods returning a boolean of whether the given title/content/tags are
acceptable according to their respective include and exclude attributes.

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

L<WWW::Noss::FeedConfig>, L<WWW::Noss::GroupConfig>, L<noss>

=cut

1;

# vim: expandtab shiftwidth=4
