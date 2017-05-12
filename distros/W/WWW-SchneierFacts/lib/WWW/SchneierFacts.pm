#!/usr/bin/perl

package WWW::SchneierFacts;
use Moose;

use Carp qw(croak);
use Web::Scraper;
use URI;

use WWW::SchneierFacts::Fact;

use namespace::clean -except => [qw(meta)];

our $VERSION = "0.02";

has cache => (
	isa => "HashRef[WWW::SchneierFacts::Fact]",
	is  => "rw",
	default => sub { {} },
);

has top_facts_uri => (
	isa => "URI",
	is  => "rw",
	default => sub { URI->new("http://geekz.co.uk/schneierfacts/facts/top") },
);

has random_fact_uri => (
	isa => "URI",
	is  => "rw",
	default => sub { URI->new("http://geekz.co.uk/schneierfacts/") },
);

has fact_base_uri => (
	isa => "URI",
	is  => "rw",
	default => sub { URI->new("http://geekz.co.uk/schneierfacts/fact/") },
);

sub fact {
	my ( $self, @args ) = @_;

	unless ( @args ) {
		return $self->random_fact;
	} else {
		if ( @args == 1 ) {
			unshift @args, ( ref $args[0] ? "link" : "id" );
		}

		return $self->new_fact(@args);
	}
}

sub top_facts {
	my $self = shift;
	$self->new_facts( $self->scrape( top_facts => $self->top_facts_uri ) );
}

sub random_fact {
	my $self = shift;
	$self->new_fact(%{ $self->scrape( fact => $self->random_fact_uri ) });
}

sub scrape {
	my ( $self, $what, $uri ) = @_;

	my $scraper = $self->_scraper($what);

	my $ret = $scraper->scrape($uri) or croak "$uri did not contain the desired data";

	my @ret = ref $ret eq 'ARRAY' ? @$ret : $ret;

	return $self->scrub( wantarray ? @ret : $ret[0] );
}

sub _scraper {
	my ( $self, $name ) = @_;
	my $method = $name . "_scraper";
	croak "Dunno how to scrape $name" unless $self->can($method);
	return $self->$method;
}

sub scrub {
	my ( $self, @blah ) = @_;

	foreach my $entry ( @blah ) {
		for ( grep { not ref } values %$entry ) {
			s/^\s+//;
			s/\s+$//;
		}

		$entry->{author} =~ s/^submitted by\s*//i;
		delete $entry->{author} if lc($entry->{author}) eq 'anonymous';
	}

	return wantarray ? @blah : $blah[0];
}

sub new_facts {
	my ( $self, @blah ) = @_;
	map { $self->new_fact(%$_) } @blah;
}

sub new_fact {
	my ( $self, %args ) = @_;

	my $id = $args{id};
	my $link = $args{link};
	my $cache = $self->cache;

	if ( my $fact = ( ( $id && $cache->{$id} ) || ( $link && $cache->{$link} ) ) ) {
		return $fact;
	} else {
		my $fact = $self->fact_class->new( %args, db => $self );
		return $cache->{$fact->link} = $cache->{$fact->id} = $fact;
	}
}

has fact_class => (
	isa => "ClassName",
	is  => "rw",
	default => "WWW::SchneierFacts::Fact",
);

has [map { $_ . "_scraper" } qw(top_facts fact_list fact)] => (
	isa => "Object",
	is  => "ro",
	lazy_build => 1,
);

sub _build_fact_scraper {
	scraper {
		process 'div#content' => content => scraper {
			process 'p.fact', fact => 'TEXT';
			process 'p.author', author => 'TEXT';
			process '//p[@class="actionbar"]/a[contains(text(), "permalink")]', link => '@href';
		};
		result 'content';
	};
}

sub _build_top_facts_scraper {
	scraper {
		process 'div#content' => content => scraper {
			process 'p.top-fact', 'facts[]' => scraper {
				process 'a', fact => 'TEXT', author => '@title', link => '@href';
			};
			result 'facts';
		};
		result 'content';
	};
}

sub _build_fact_list_scraper {
	scraper {
		process 'div#content' => content => scraper {
			process 'ul.fact-list li', 'facts[]' => scraper {
				process 'a', fact => 'TEXT', author => '@title', link => '@href';
			};
			result 'facts';
		};
		result 'content';
	};
}

__PACKAGE__

__END__

=pod

=head1 NAME

WWW::SchneierFacts - API for retrieving facts about Bruce Schneier

=head1 SYNOPSIS

	use WWW::SchneierFacts;

	my $db = WWW::SchneierFacts->new;

	foreach my $fact ( $db->top_facts ) {
		print "$fact\n",
		      ( $fact->author ? ( "  --", $fact->author, "\n" ) : () ),
		      "\n";
	}

=head1 DESCRIPTION

Bruce Schneier is the Chuck Norris of cryptography.

=head1 METHODS

=over 4

=item fact $id

=item fact $uri

=item fact

Return a fact with the ID C<id>, or if a L<URI> object is provided, at the link.

If no arguments are given a random fact will be fetched.

Returns a L<WWW::SchneierFacts::Fact> object.

=item top_facts

Get the top facts.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
