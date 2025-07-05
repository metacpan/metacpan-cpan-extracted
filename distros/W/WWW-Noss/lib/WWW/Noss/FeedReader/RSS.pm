package WWW::Noss::FeedReader::RSS;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use DateTime;
use DateTime::Format::Mail;
use XML::LibXML;

sub _time {

	my ($node) = @_;

	my $format = DateTime::Format::Mail->new->loose;
	my $dt = eval { $format->parse_datetime($node->textContent) };

	return undef unless defined $dt;

	return $dt->epoch;

}

sub _image {

	my ($node) = @_;

	my ($url) = grep { $_->nodeName eq 'url' } $node->childNodes;

	return undef unless defined $url;

	return $url->textContent;

}

sub _skip {

	my ($node, $time) = @_;

	my @items =
		map { $_->textContent }
		grep { $_->nodeName eq $time }
		$node->childNodes;

	return @items ? \@items : undef;

}

sub _read_entry {

	my ($node) = @_;

	my $entry = {
		nossid    => undef,
		status    => undef,
		feed      => undef,
		title     => undef,
		link      => undef,
		author    => undef,
		category  => undef,
		summary   => undef,
		published => undef,
		updated   => undef,
		uid       => undef,
	};

	for my $n ($node->childNodes) {

		my $name = $n->nodeName;

		if ($name eq 'title') {
			$entry->{ title } = $n->textContent;
		} elsif ($name eq 'link') {
			$entry->{ link } = $n->textContent;
		} elsif ($name eq 'description') {
			$entry->{ summary } = $n->textContent;
		} elsif ($name eq 'author') {
			$entry->{ author } = $n->textContent;
		} elsif ($name eq 'category') {
			push @{ $entry->{ category } }, $n->textContent;
		} elsif ($name eq 'guid') {
			$entry->{ uid } = $n->textContent;
		} elsif ($name eq 'pubDate') {
			$entry->{ published } = _time($n);
		}

	}

	if (not defined $entry->{ title } and not defined $entry->{ summary }) {
		return undef;
	}

	return $entry;

}

sub read_feed {

	my ($class, $feed, $dom) = @_;

	my $channel = {
		nossname    => $feed->name,
		nosslink    => $feed->feed,
		title       => undef,
		link        => undef,
		description => undef,
		updated     => undef,
		author      => undef,
		category    => undef,
		generator   => undef,
		image       => undef,
		rights      => undef,
		skiphours   => undef,
		skipdays    => undef,
	};

	my $entries = [];

	my @entry_nodes;

	my ($channel_node) =
		grep { $_->nodeName eq 'channel' }
		$dom->documentElement->childNodes;

	unless (defined $channel_node) {
		die sprintf "%s is not a valid RSS feed\n", $feed->name;
	}

	for my $n ($channel_node->childNodes) {

		my $name = $n->nodeName;

		if ($name eq 'item') {
			push @entry_nodes, $n;
		} elsif ($name eq 'title') {
			$channel->{ title } = $n->textContent;
		} elsif ($name eq 'link') {
			$channel->{ link } = $n->textContent;
		} elsif ($name eq 'description') {
			$channel->{ description } = $n->textContent;
		} elsif ($name eq 'copyright') {
			$channel->{ rights } = $n->textContent;
		} elsif ($name eq 'lastBuildDate') {
			$channel->{ updated } = _time($n);
		} elsif ($name eq 'category') {
			push @{ $channel->{ category } }, $n->textContent;
		} elsif ($name eq 'generator') {
			$channel->{ generator } = $n->textContent;
		} elsif ($name eq 'image') {
			$channel->{ image } = _image($n);
		} elsif ($name eq 'skipHours') {
			$channel->{ skiphours } = _skip($n, 'hour');
		} elsif ($name eq 'skipDays') {
			$channel->{ skipdays } = _skip($n, 'day');
		}

	}

	for my $n (@entry_nodes) {
		my $e = _read_entry($n);
		next unless defined $e;
		$e->{ feed } = $channel->{ nossname };
		push @$entries, $e;
	}

	unless (@$entries) {
		die sprintf "%s does not contain any posts\n";
	}

	@$entries =
		map { $_->[1] }
		sort {
			my $at = $a->[1]{ published } // $a->[1]{ updated };
			my $bt = $b->[1]{ published } // $b->[1]{ updated };
			if (not defined $at and not defined $bt) {
				$a->[0] <=> $b->[0];
			} elsif (not defined $at) {
				-1;
			} elsif (not defined $bt) {
				1;
			} else {
				$at <=> $bt;
			}
		}
		map { [ $_, $entries->[$_] ] }
		0 .. $#$entries;

	return ($channel, $entries);

}

1;

# vim: expandtab shiftwidth=4
