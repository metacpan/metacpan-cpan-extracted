package WWW::Noss::FeedReader::Atom;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use DateTime;
use DateTime::Format::RFC3339;
use XML::LibXML;

use WWW::Noss::TextToHtml qw(text2html);

our $NS = 'http://www.w3.org/2005/Atom';

sub _name {

	my ($node) = @_;

	my ($email_node, $name_node);

	for my $n ($node->childNodes) {
		my $node_name = $n->nodeName;
		if ($node_name eq 'name') {
			$name_node = $n;
		} elsif ($node_name eq 'email') {
			$email_node = $n;
		}
	}

	my $name = '';

	if (defined $email_node and defined $name_node) {
		$name = sprintf "%s (%s)", $email_node->textContent, $name_node->textContent;
	} elsif (defined $email_node) {
		$name = $email_node->textContent;
	} elsif (defined $name_node) {
		$name = $name_node->textContent;
	}

	return $name ne '' ? $name : undef;

}

sub _link {

	my ($node) = @_;

	my $href = $node->getAttribute('href');

	return undef unless defined $href;

	my $rel = $node->getAttribute('rel') // 'alternate';

	return $rel eq 'alternate' ? $href : undef;

}

sub _time {

	my ($node) = @_;

	my $format = DateTime::Format::RFC3339->new;
	my $dt = eval { $format->parse_datetime($node->textContent) };
	return undef unless defined $dt;

	return $dt->epoch;

}

sub _content {

	my ($node) = @_;

	my $type = $node->getAttribute('type');
	my $src = $node->getAttribute('src');

	if (not defined $type or $type eq 'text') {
		return text2html($node->textContent);
	} elsif ($type eq 'html' or $type eq 'xhtml') {
		return $node->textContent;
	} elsif (defined $src) {
		return undef;
	} elsif ($type =~ /[\+\/]xml$/) {
		return $node->textContent;
	} elsif ($type =~ /^text/) {
		return text2html($node->textContent);
	} else {
		return undef;
	}

}

sub _summary {

	my ($node) = @_;

	my $type = $node->getAttribute('type') // 'text';

	if ($type =~ /^x?html$/) {
		return $node->textContent;
	} elsif ($type eq 'text') {
		return text2html($node->textContent);
	} else {
		return undef;
	}

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

	my $summary;

	for my $n ($node->childNodes) {

		my $name = $n->nodeName;

		if ($name eq 'id') {
			$entry->{ uid } = $n->textContent;
		} elsif ($name eq 'title') {
			$entry->{ title } = $n->textContent;
		} elsif ($name eq 'updated') {
			$entry->{ updated } = _time($n);
		} elsif ($name eq 'author') {
			$entry->{ author } = _name($n);
		} elsif ($name eq 'content') {
			$entry->{ summary } = _content($n);
		} elsif ($name eq 'link') {
			$entry->{ link } = _link($n);
		} elsif ($name eq 'summary') {
			$summary = _summary($n);
		} elsif ($name eq 'category') {
			my $term = $n->getAttribute('term');
			next unless defined $term;
			push @{ $entry->{ category } }, $term;
		} elsif ($name eq 'published') {
			$entry->{ published } = _time($n);
		}

	}

	if (not defined $entry->{ summary } and defined $summary) {
		$entry->{ summary } = $summary;
	}

	return undef unless defined $entry->{ summary };

	$entry->{ title } //= $entry->{ link };

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

	for my $n ($dom->documentElement->childNodes) {

		my $name = $n->nodeName;

		if ($name eq 'entry') {
			push @entry_nodes, $n;
		} elsif ($name eq 'title') {
			$channel->{ title } = $n->textContent;
		} elsif ($name eq 'link') {
			$channel->{ link } = _link($n);
		} elsif ($name eq 'updated') {
			$channel->{ updated } = _time($n);
		} elsif ($name eq 'author') {
			$channel->{ author } = _name($n);
		} elsif ($name eq 'category') {
			my $term = $n->getAttribute('term');
			next unless defined $term;
			push @{ $channel->{ category } }, $term;
		} elsif ($name eq 'generator') {
			$channel->{ generator } = $n->textContent;
		} elsif ($name eq 'logo') {
			$channel->{ image } = $n->textContent;
		} elsif ($name eq 'rights') {
			$channel->{ rights } = $n->textContent;
		} elsif ($name eq 'subtitle') {
			$channel->{ description } = $n->textContent;
		}

	}

	if (not defined $channel->{ title } or not defined $channel->{ updated }) {
		die sprintf "%s is not a valid Atom feed\n", $feed->name;
	}

	for my $n (@entry_nodes) {
		my $e = _read_entry($n);
		next unless defined $e;
		$e->{ feed } = $channel->{ nossname };
		push @$entries, $e;
	}

	unless (@$entries) {
		die sprintf "%s contains no posts\n";
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
		map { [ $_, $entries->[$_]] }
		0 .. $#$entries;

	return ($channel, $entries);

}

1;

# vim: expandtab shiftwidth=4
