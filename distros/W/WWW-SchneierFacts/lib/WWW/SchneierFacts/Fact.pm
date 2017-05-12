#!/usr/bin/perl

package WWW::SchneierFacts::Fact;
use Moose;

use Carp qw(croak);
use URI;

use namespace::clean -except => [qw(meta)];

use overload '""' => 'stringify';

sub stringify { shift->fact }

sub BUILD {
	my $self = shift;

	croak "Either 'link' or 'id' is required" unless $self->has_id or $self->has_link;
}

has db => (
	is  => "rw",
	isa => "WWW::SchneierFacts",
	lazy_build => 1,
);

sub _build_db {
	require WWW::SchneierFacts;
	WWW::SchneierFacts->new;
}

has fact => (
	isa => "Str",
	is  => "rw",
	lazy_build => 1,
);

sub _build_fact {
	my $self = shift;
	$self->_get_fields->{fact};
}

has id => (
	isa => "Int",
	is  => "ro",
	lazy_build => 1,
);

sub _build_id {
	my $self = shift;

	croak "Can't guess ID without a link" unless $self->has_link;

	if ( $self->link->path =~ /(\d+)$/ ) {
		return $1;
	} else {
		croak "Can't guess ID from link (" . $self->link . ")";
	}
}

has link => (
	isa => "URI",
	is  => "rw",
	lazy_build => 1,
);

sub _build_link {
	my $self = shift;
	croak "Can't make a link without an ID" unless $self->has_id;
	URI->new_abs( $self->id, $self->db->fact_base_uri );
}

has author => (
	isa => "Maybe[Str]",
	is  => "rw",
	lazy_build => 1,
);

sub _build_author {
	my $self = shift;
	$self->_get_fields->{author};
}

sub _get_fields {
	my $self = shift;

	my $res = $self->db->scrape( fact => $self->link );

	foreach my $key ( keys %$res ) {
		$self->$key( $res->{$key} );
	}

	return $res;
}

__PACKAGE__

__END__

=pod

=head1 NAME

WWW::SchneierFacts::Fact - A fact about Bruce Schneier

=head1 SYNOPSIS

	use WWW::SchneierFacts::Fact;

	my $fact = WWW::SchneierFacts::Fact->new(
		id => 42,
	);

	$fact->fact; # the text

	$ stringifies
	warn "THIS IS A FACT: $fact";

	if ( $fact->has_author ) {
		warn $fact->author; # not set if anonymous
	}

=head1 DESCRIPTION

This is the class for a single Bruce Schneier fact.

=head1 ATTRIBUTES

Generally the attributes are fetched lazily.

L<WWW::SchneierFacts> does the hard work.

=over 4

=item fact

The fact text.

=item link

=item id

One of these is required. This is either the numeric ID or the link to the
fact.

To get a random fact, use L<WWW::SchneierFacts::Fact>.

=item author

The author of the fact.

=item db

The fact DB where this fact was obtained.

Used for scraping. Generally set by the DB itself.

=back

=head1 TODO

	WWW::SchneierFacts::Fact->new( fact => "foo", author => "me!" )->submit;

=cut


