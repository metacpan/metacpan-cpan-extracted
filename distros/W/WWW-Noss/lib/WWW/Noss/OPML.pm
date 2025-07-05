package WWW::Noss::OPML;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use XML::LibXML;

sub _read_outline {

	my ($self, $node, $groups) = @_;

	my $type = $node->getAttribute('type');

	return unless defined $type;

	my $title = $node->getAttribute('title');

	if ($type eq 'folder') {

		my @new = ($title // (), @$groups);

		for my $n ($node->findnodes('./outline')) {
			$self->_read_outline($n, \@new);
		}

	} elsif ($type eq 'rss') {

		my $name    = $title // return;
		my $xmlurl  = $node->getAttribute('xmlUrl') // return;
		my $text    = $node->getAttribute('text');
		my $htmlurl = $node->getAttribute('htmlUrl');

		push @{ $self->feeds }, {
			title    => $name,
			xml_url  => $xmlurl,
			text     => $text,
			html_url => $htmlurl,
			groups   => [ @$groups ],
		};

	} else {

		return;

	}

	return 1;

}

sub from_perl {

	my ($class, %param) = @_;

	my $self = bless {}, $class;

	$self->set_title($param{ title });
	$self->set_feeds($param{ feeds } // []);

	return $self;

}

sub from_xml {

	my ($class, $file) = @_;

	my $self = bless {}, $class;

	my $dom = eval { XML::LibXML->load_xml(location => $file) };

	unless (defined $dom) {
		die "Failed to read $file as an XML document\n";
	}

	my ($title) = $dom->findnodes('/opml/head/title');

	$self->set_title(
		defined $title ? $title->textContent : ''
	);

	$self->set_feeds([]);

	my @outs = $dom->findnodes('/opml/body/outline');

	for my $o (@outs) {
		$self->_read_outline($o, []);
	}

	return $self;

}

sub to_xml {

	my ($self, %param) = @_;

	my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');

	my $root = XML::LibXML::Element->new('opml');
	$root->setAttribute('version', '1.0');

	$dom->setDocumentElement($root);

	my $head = XML::LibXML::Element->new('head');
	my $title = XML::LibXML::Element->new('title');
	$title->addChild(
		XML::LibXML::Text->new($self->title)
	);
	$head->addChild($title);
	$root->addChild($head);

	my $body = XML::LibXML::Element->new('body');
	$root->addChild($body);

	my %folders;
	my @ungrouped;

	if (defined $param{ folders } and !$param{ folders }) {
		@ungrouped = @{ $self->{ Feeds } };
	} else {
		for my $f (@{ $self->{ Feeds } }) {
			if (@{ $f->{ groups } }) {
				for my $g (@{ $f->{ groups } }) {
					push @{ $folders{ $g } }, $f;
				}
			} else {
				push @ungrouped, $f;
			}
		}
	}

	for my $g (sort keys %folders) {

		my $folder = XML::LibXML::Element->new('outline');
		$folder->setAttribute('type', 'folder');
		$folder->setAttribute('title', $g);
		$folder->setAttribute('text', $g);
		$folder->setAttribute('description', $g);

		for my $f (@{ $folders{ $g } }) {
			my $feed = XML::LibXML::Element->new('outline');
			$feed->setAttribute('type', 'rss');
			$feed->setAttribute('title', $f->{ title });
			$feed->setAttribute('text', $f->{ text } // $f->{ title });
			$feed->setAttribute('xmlUrl', $f->{ xml_url });
			$feed->setAttribute('htmlUrl', $f->{ html_url }) if defined $f->{ html_url };
			$folder->addChild($feed);
		}

		$body->addChild($folder);

	}

	for my $f (sort { $a->{ title } cmp $b->{ title } } @ungrouped) {
		my $feed = XML::LibXML::Element->new('outline');
		$feed->setAttribute('type', 'rss');
		$feed->setAttribute('title', $f->{ title });
		$feed->setAttribute('text', $f->{ text } // $f->{ title });
		$feed->setAttribute('xmlUrl', $f->{ xml_url });
		$feed->setAttribute('htmlUrl', $f->{ html_url }) if defined $f->{ html_url };
		$body->addChild($feed);
	}

	return $dom;

}

sub to_file {

	my ($self, $file, %param) = @_;

	open my $fh, '>', $file
		or die "Failed to open $file for writing: $!\n";
	binmode $fh;
	$self->to_xml(%param)->toFH($fh, 1);
	close $fh;

	return $file;

}

sub to_fh {

	my ($self, $fh, %param) = @_;

	binmode $fh;
	$self->to_xml(%param)->toFH($fh, 1);

	return $fh;

}

sub title {

	my ($self) = @_;

	return $self->{ Title };

}

sub set_title {

	my ($self, $new) = @_;

	unless (defined $new) {
		die "title cannot be undefined";
	}

	$self->{ Title } = $new;

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

	for my $i (0 .. $#$new) {
		unless (defined $new->[$i]{ xml_url }) {
			die "feeds[$i] is missing xml_url";
		}
		unless (defined $new->[$i]{ title }) {
			die "feeds[$i] is missing title";
		}
		if (defined $new->[$i]{ groups } and ref $new->[$i]{ groups } ne 'ARRAY') {
			die "feeds[$i]{ groups } is not an array ref";
		}
	}

	$self->{ Feeds } = $new;

}

sub rename_group {

	my ($self, $old, $new) = @_;

	my $rn = 0;

	for my $f (@{ $self->{ Feeds } }) {

		next unless defined $f->{ groups };

		for my $i (0 .. $#{ $f->{ groups } }) {
			if ($f->{ groups }[$i] eq $old) {
				$f->{ groups }[$i] = $new;
				$rn++;
			}
		}

	}

	return $rn;

}

1;

=head1 NAME

WWW::Noss::OPML - OPML file reader/writer

=head1 USAGE

  use WWW::Noss::OPML;

  my $opml = WWW::Noss::OPML->from_perl(
      title => 'Name',
      feeds => [ { ... }, ... ],
  );

  $opml->to_file('path/to/xml');

  # Read from file
  $opml = WWW::Noss::OPML->from_xml('path/to/xml');

=head1 DESCRIPTION

B<WWW::Noss::OPML> is a module that provides an interface for reading and
writing OPML files. This is a private module, please consult the L<noss>
manual for user documentation.

=head1 METHODS

=over 4

=item $opml = WWW::Noss::OPML->from_perl(%param)

Creates a new B<WWW::Noss::OPML> object from the parameters supplied via the
C<%param> hash.

The following are a list of valid fields for the C<%param> hash. The only
required field is C<title>.

=over 4

=item title

Title string for the OPML file.

=item feeds

Array ref of outline feed hashes. The hashes should look something like this:

  {
	title    => ..., # required
	xml_url  => ..., # required
	text     => ...,
	html_url => ...,
	groups   => [ ... ],
  }

=back

=item $opml = WWW::Noss::OPML->from_xml($file)

Create B<WWW::Noss::OPML> object from the given OPML file.

=item $dom = $opml->to_xml([ %param ])

Returns a L<XML::LibXML::Document> DOM object representing the object.

C<%param> is an optional hash of additional parameters to configure the
converted XML structure. The following are valid values:

=over 4

=item folders

Boolean determining whether to include outline folders in the XML strucutre.
Defaults to true.

=back

=item $file = $opml->to_file($file, [ %param ])

Writes the OPML object's XML structure to C<$file>. Returns C<$file> on
success, dies on failure.

C<%param> is an optional hash of additional parameters. Accepts the same
options as C<to_xml()>.

=item $fh = $opml->to_fh($fh, [ %param ])

Writes the OPML object's XML structure to the C<$fh> file handle. Returns C<$fh>
on success, dies on failure.

C<%param> is an optional hash of additional parameters. Accepts the same
options as C<to_xml()>.

=item $title = $opml->title()

=item $opml->set_title($title)

Getter/setter for the OPML's title attribute.

=item \@feeds = $opml->feeds()

=item $opml->set_feeds(\@feeds)

Getter/setter for the OPML's feeds attribute.

=item $rn = $opml->rename_group($old, $new)

Goes through each feed's group list and renames the group C<$old> to C<$new>.
Returns the number of groups renamed.

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

L<XML::LibXML::Document>, L<noss>

=cut

# vim: expandtab shiftwidth=4
