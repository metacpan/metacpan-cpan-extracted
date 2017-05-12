package XML::Atom::Ext::Inline;

use warnings;
use strict;

use base qw(XML::Atom::Base);

use XML::Atom::Link;
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::Atom::Util qw(childlist);

use Carp;

=head1 NAME

XML::Atom::Ext::Inline - In-lining Extensions for Atom

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

BEGIN {
	XML::Atom::Link->mk_object_accessor(inline => 'XML::Atom::Ext::Inline');
	no warnings;
	*XML::Atom::Link::set = sub {XML::Atom::Base::set(@_)}; # hack to eliminate backwards compatibility hack in XML::Atom::Link
}

=head1 SYNOPSIS

This module implements In-lining extesions for Atom. You can see the RFC draft
here: L<http://tools.ietf.org/html/draft-mehta-atom-inline-01>

The following code:

    use XML::Atom;
    use XML::Atom::Ext::Inline;

    my $feed = XML::Atom::Feed->new(Version => '1.0');
    my $parent_feed = XML::Atom::Feed->new(Version => '1.0');
    $parent_feed->title('foo bar');

    my $inline = XML::Atom::Ext::Inline->new();
    $inline->atom($parent_feed);
    
    my $link = XML::Atom::Link->new(Version => '1.0');
    $link->rel('up');
    $link->inline($inline);

    $feed->add_link($link);
    
    print $feed->as_xml();
    
will produce:

    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <link rel="up">
        <ae:inline xmlns:ae="http://purl.org/atom/ext/">
          <feed>
            <title>foo bar</title>
          </feed>
        </ae:inline>
      </link>
    </feed>

=head1 USAGE

=head2 atom($feed | $entry)

Returns an I<XML::Atom::Feed> or I<XML::Atom::Entry> object representing the
inline element contents or C<undef> if there is no contents.

If given an argument, adds the feed I<$feed> which must be an
I<XML::Atom::Feed> object or I<$entry> which must be I<XML::Atom::Entry>
object, into inline element.

=cut

sub atom {
	my $inline = shift;
	if (@_) {
		if ($_[0]->isa('XML::Atom::Feed')) {
			my ($feed) = @_;
			my $ns_uri = $feed->{ns};
			my @elem = childlist($inline->elem, $ns_uri, 'entry');
			$inline->elem->removeChild($_) for @elem;
			return $inline->set($ns_uri, 'feed', $feed);
		}
		elsif ($_[0]->isa('XML::Atom::Feed')) {
			my ($entry) = @_;
			my $ns_uri = $entry->{ns}->{uri};
			my @elem = childlist($inline->elem, $ns_uri, 'feed');
			$inline->elem->removeChild($_) for @elem;
			return $inline->set($ns_uri, 'entry', $entry);			
		}
		else {
			my $r = ref $_[0];
			carp "can't embed $r - should be XML::Atom::Feed or XML::Atom::Entry";
			return;
		}
	}
	else {
		# looking for feed or entry or the same stuff again with old NS URI
		return $inline->get_object('http://www.w3.org/2005/Atom', 'feed', 'XML::Atom::Feed')
			|| $inline->get_object('http://www.w3.org/2005/Atom', 'entry', 'XML::Atom::Entry')
			|| $inline->get_object('http://purl.org/atom/ns#', 'feed', 'XML::Atom::Feed')
			|| $inline->get_object('http://purl.org/atom/ns#', 'entry', 'XML::Atom::Entry');
	}
}

=head2 element_ns

Returns the L<XML::Atom::Namespace> object representing our xmlns:ae="http://purl.org/atom/ext/">.

=cut

sub element_ns {
	return XML::Atom::Namespace->new(
		'ae' => q{http://purl.org/atom/ext/}
	);
}

sub element_name {'inline'}

=head1 AUTHOR

Dmitri Popov, C<< <operator at cv.dp-net.com> >>

=head1 BUGS

Please report more bugs here: L<http://github.com/pin/xml-atom-ext-inline/issues>

=head1 SUPPORT

You can find more information and usefull links on project wiki: L<http://wiki.github.com/pin/xml-atom-ext-inline>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Dmitri Popov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of XML::Atom::Ext::Inline
