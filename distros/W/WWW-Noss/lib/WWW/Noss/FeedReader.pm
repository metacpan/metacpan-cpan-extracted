package WWW::Noss::FeedReader;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.00';

use Exporter qw(import);
our @EXPORT_OK = qw(read_feed);

use WWW::Noss::FeedReader::Atom;
use WWW::Noss::FeedReader::RSS;
use WWW::Noss::TextToHtml qw(strip_tags unescape_html);

# What is with difference between 'title' and 'displaytitle'?
# Prior to 1.09, there was only title, which served as both the title to use
# for internally identifying a post by using it in a post's nossuid, and
# also the title to show the user when querying posts. The issue is that if I
# ever wanted to change the way noss processed certain titles, this would
# interfere with generating posts' nossuids and cause them to be considered
# new posts. That is why I introduced displaytitle, so that it could serve
# as the human-readable version of a post's title which could be safely
# changed without causing issues for existing databases.
#
# So basically:
# title - Internal title used by noss for generating nossuids; should not
#         change.
# displaytitle - Title that will be shown to users; can be changed.

# TODO: Add feed option to truncate display titles like we do when generating
# titles from summaries?

sub _title_from_desc {

    my ($desc) = @_;

    return '' if not defined $desc;

    $desc = unescape_html(strip_tags($desc));
    $desc =~ s/\s+/ /g;
    $desc =~ s/^\s+|\s+$//g;
    my $long = length $desc > 40;
    $desc = substr $desc, 0, 40;
    $desc =~ s/ $//;
    $desc .= '...' if $long;

    return $desc;

}

sub read_feed {

    my ($feed) = @_;

    require XML::LibXML;

    my $channel;
    my $entries;

    my $dom = eval { XML::LibXML->load_xml(location => $feed->path) };

    if (not defined $dom) {
        die sprintf
            "Failed to parse %s as an XML document, %s might not be an RSS or Atom feed\n",
            $feed->path,
            $feed->name;
    }

    if ($dom->documentElement->nodeName eq 'rss') {
        ($channel, $entries) = WWW::Noss::FeedReader::RSS->read_feed(
            $feed,
            $dom
        );
    } elsif (
        $dom->documentElement->nodeName eq 'feed' and
        $dom->documentElement->getAttribute('xmlns') eq $WWW::Noss::FeedReader::Atom::NS
    ) {
        ($channel, $entries) = WWW::Noss::FeedReader::Atom->read_feed(
            $feed,
            $dom
        );
    } else {
        die sprintf "%s is not an RSS or Atom feed\n", $feed->name;
    }

    if (defined $channel->{ description }) {
        $channel->{ description } =~ s/\s+/ /g;
        $channel->{ description } =~ s/^ | $//g;
    }

    for my $i (0 .. $#$entries) {
        if (not defined $entries->[$i]{ displaytitle }) {
            if (defined $entries->[$i]{ summary }) {
                $entries->[$i]{ displaytitle } = _title_from_desc($entries->[$i]{ summary });
            } elsif (defined $entries->[$i]{ link }) {
                $entries->[$i]{ displaytitle } = $entries->[$i]{ link };
            }
        }
        unless ($feed->title_ok($entries->[$i]{ displaytitle })) {
            $entries->[$i] = undef;
            next;
        }
        unless ($feed->content_ok($entries->[$i]{ summary })) {
            $entries->[$i] = undef;
            next;
        }
        unless ($feed->tags_ok($entries->[$i]{ category })) {
            $entries->[$i] = undef;
            next;
        }
    }

    @$entries = grep { defined } @$entries;

    unless (@$entries) {
        die sprintf "%s does contain any posts\n", $feed->name;
    }

    if (defined $feed->limit and $feed->limit < @$entries) {
        @$entries = @$entries[-$feed->limit .. -1];
    }

    for my $i (0 .. $#$entries) {
        $entries->[$i]{ nossid  } = $i + 1;
        $entries->[$i]{ author  } //= $channel->{ author };
        $entries->[$i]{ nossuid } =
            join ";",
            map { $_ // '' }
            @{ $entries->[$i] }{ qw(uid feed title link published) };
    }

    return ($channel, $entries);

}

1;

=head1 NAME

WWW::Noss::FeedReader - RSS/Atom feed reader

=head1 USAGE

  use WWW::Noss::FeedReader qw(read_feed);

  my ($channel, $entries) = read_feed($feed);

=head1 DESCRIPTION

B<WWW::Noss::FeedReader> is a module that provides the C<read_feed()>
subroutine for reading RSS and Atom feeds. This is a private module, please
consult the L<noss> manual for user documentation.

=head1 SUBROUTINES

Subroutines are not exported automatically.

=over 4

=item (\%channel, \@entries) = read_feed($feed)

Reads the given L<WWW::Noss::FeedConfig> object and returns the channel and
entry data. Returns both as C<undef> on failure.

C<\%channel> should look something like this:

  {
    nossname    => ...,
    nosslink    => ...,
    title       => ...,
    link        => ...,
    description => ...,
    updated     => ...,
    author      => ...,
    category    => [ ... ],
    generator   => ...,
    image       => ...,
    rights      => ...,
    skiphours   => [ ... ],
    skipdays    => [ ... ],
  }

C<\@entries> will be a list of hash refs that look something like this:

  {
    nossid       => ...,
    status       => ...,
    feed         => ...,
    title        => ...,
    link         => ...,
    author       => ...,
    category     => [ ... ],
    summary      => ...,
    published    => ...,
    updated      => ...,
    uid          => ...,
    displaytitle => ...,
  }

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

L<WWW::Noss::FeedConfig>, L<noss>

=cut

# vim: expandtab shiftwidth=4
