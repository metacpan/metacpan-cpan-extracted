# ABSTRACT: Atom feed for web

package Web::Atom;
BEGIN {
  $Web::Atom::VERSION = '0.1.0';
}
use strict;
use warnings;

=head1 NAME

Web::Atom - Atom feed for web

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

Write your own plugin to parse webpage and then generate Atom feed.

=head1 SYNOPSIS

    use Web::Atom;
    my $feed = Web::Atom->new(p => 'Bank::Cathaybk::Creditbank');
    $feed->id('http://feeds.hasname.com/feed/cathaybk.creditcard.atom');
    print $feed->as_xml;

=cut

use Any::Moose;
has 'feed' => (is => 'rw', isa => 'XML::Atom::Feed', lazy_build => 1, handles => {as_xml => 'as_xml', id => 'id'});
has 'p' => (is => 'ro', isa => 'Str', required => 1);
has 'plugin' => (is => 'rw', isa => 'Web::Atom::Plugin', lazy_build => 1);

use XML::Atom::Entry;
use XML::Atom::Feed;
use XML::Atom::Link;
use XML::Atom::Person;

sub _build_feed {
    my $self = shift;

    my $plugin = $self->plugin;

    my $author = XML::Atom::Person->new(Version => 1.0);
    $author->email($plugin->author_email);
    $author->name($plugin->author_name);

    my $link = XML::Atom::Link->new(Version => 1.0);
    $link->type('text/html');
    $link->rel('alternate');
    $link->href($plugin->url);

    my $feed = XML::Atom::Feed->new(Version => 1.0);
    $feed->add_link($link);
    $feed->author($author);
    $feed->title($plugin->title);

    foreach my $e (@{$plugin->entries}) {
	my $entry = XML::Atom::Entry->new(Version => 1.0);

	if (defined $entry->author) {
	    my $entryAuthor = XML::Atom::Author->new(Version => 1.0);
	    $entryAuthor->email($e->author_email);
	    $entryAuthor->name($e->author_name);
	    $entry->author($entryAuthor);
	} else {
	    $entry->author($author);
	}

	$entry->id($e->id);
	$entry->content($e->content);
	$entry->title($e->title);

	my $link = XML::Atom::Link->new(Version => 1.0);
	$link->type('text/html');
	$link->rel('alternate');
	$link->href($e->url);
	$entry->add_link($link);

	$feed->add_entry($entry);
    }

    return $feed;
}

sub _build_plugin {
    my $self = shift;

    my $p = $self->p;
    my $pname = "Web::Atom::$p";

    eval "require $pname;";
    $pname->new;
}

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license. See
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

1;