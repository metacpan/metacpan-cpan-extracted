# $File: //member/autrijus/WWW-SherlockSearch/lib/WWW/SherlockSearch/Results.pm $ $Author: autrijus $
# $Revision: #10 $ $Change: 10623 $ $DateTime: 2004/05/22 08:07:29 $ vim: expandtab shiftwidth=4

package WWW::SherlockSearch::Results;

use strict;

=head1 NAME

WWW::SherlockSearch::Results - Sherlock search results

=head1 SYNOPSIS

    use WWW::SherlockSearch::Results;

    my $resultStruct = WWW::SherlockSearch::Results->new;

    $resultStruct->setServiceName($name);
    $resultStruct->setServiceDescription($description);
    $resultStruct->setBaseHREF($base_href);
    $resultStruct->setHost($host);
    $resultStruct->setPictureUrl($picture_url);
    $resultStruct->setChannelUrl($channel_url);
    $resultStruct->setQueryAttr($query_attr);
    $resultStruct->setBannerImage($banner_image_url);
    $resultStruct->setBannerLink($banner_url);

    $resultStruct->add($itemurl, $content, $relev, $rest, $fulltext, $date);
    # ... add some more entries

    my $text = $results->asString;
    my $atom = $results->asAtomString;
    my $rss  = $results->asRssString;
    my $html = $results->asHtmlString;

=head1 DESCRIPTION

This module represents the result set returned by a Sherlock query.

=cut

sub new {
    my $type = shift;
    my $self = {};
    $self->{'index'} = 0;
    $self->{'array'} = ();
    bless($self, $type);
    return $self;
}

sub add {
    my ($self, $url, $content, $rel, $summary, $fulltext, $date) = @_;
    push (
	@{ $self->{'array'} },
	{
	    'url'     => $url,
	    'content' => $content,
	    'rel'     => $rel,
	    'summary' => $summary,
	    'fulltext'=> $fulltext,
            'date'    => $date,
	}
    );
    return $self;
}

sub get {
    my ($self, $index) = @_;
    if (!$index) {
	$index = $self->{'index'};
	if ($index == $self->getNumResults) { $self->{'index'} = 0; return; }
	$self->{'index'}++;
    }
    my $temp = $self->{'array'}->[$index];
    return (@{$temp}{qw/url content rel summary fulltext date/});
}

sub reset {
    my $self = shift;
    $self->{'index'} = 0;
    return $self;
}

sub getNumResults {
    my $self = shift;
    return scalar(@{ $self->{'array'} || [] });
}

sub getBannerLink {
    my $self = shift;
    return $self->{banURL};
}

sub setBannerLink {
    my $self = shift;
    $self->{banURL} = shift;
    return $self;
}

sub getBannerImage {
    my $self = shift;
    return $self->{banImageURL};
}

sub setBannerImage {
    my $self = shift;
    $self->{banImageURL} = shift;
    return $self;
}

sub getServiceName {
    my $self = shift;
    return $self->{serviceName};
}

sub setServiceName {
    my $self = shift;
    $self->{serviceName} = shift;
    return $self;
}

sub getChannelUrl {
    my $self = shift;
    return $self->{channelUrl};
}

sub setChannelUrl {
    my $self = shift;
    $self->{channelUrl} = shift;
    return $self;
}

sub getQueryAttr {
    my $self = shift;
    return $self->{queryAttr};
}

sub setQueryAttr {
    my $self = shift;
    $self->{queryAttr} = shift;
    return $self;
}

sub getServiceDescription {
    my $self = shift;
    return $self->{serviceDescription};
}

sub setServiceDescription {
    my $self = shift;
    $self->{serviceDescription} = shift;
    return $self;
}

sub getPictureUrl {
    my $self = shift;
    return $self->{pictureUrl};
}

sub setPictureUrl {
    my $self = shift;
    $self->{pictureUrl} = shift;
    return $self;
}

sub getBaseHREF {
    my $self = shift;
    return $self->{baseHREF};
}

sub setBaseHREF {
    my $self = shift;
    $self->{baseHREF} = shift;
    return $self;
}

sub getHost {
    my $self = shift;
    return $self->{host};
}

sub setHost {
    my $self = shift;
    $self->{host} = shift;
    return $self;
}

sub asString {
    my $self = shift;

    my $string .= "\nResults :\n\n";

    $string .= "Banner Link : " . $self->getBannerLink . "\nBanner Image : ";
    $string .= $self->getBannerImage . "\n\n";

    if ($self->getNumResults == 0) { $string .= "No hits\n"; return $string; }

    $self->reset;
    my ($url, $cont, $rel, $summary, $fulltext, $date);
    while (($url, $cont, $rel, $summary, $fulltext, $date) = $self->get) {
	$string .= "Hit := $url\nRelevance : $rel\n";
	$string .= "Content := $cont\nSummary := $summary\nFulltext := $fulltext\n\n";
    }
    return $string;
}

sub asHtmlString {
    my $self = shift;
    my ($url, $cont, $rel, $summary, $fulltext, $date);
    my $string;
    if ($url = $self->getBannerLink) {
	$string .= "<BR><A HREF=\"$url\"> <IMG SRC=\"";
	$string .= $self->getBannerImage . "\"> </A>\n";
    }

    if ($self->getNumResults == 0) {
	$string .= "<BR><I>No hits<I>\n";
	return $string;
    }

    $self->reset;
    while (($url, $cont, $rel, $summary, $fulltext, $date) = $self->get) {
	$string .= "<BR><A HREF=\"$url\">$cont</A> ";
	$string .= "<I>$rel%</I>" if ($rel);
	$string .= "<BR>$summary" if ($summary);
	$string .= "<BR>$fulltext" if ($fulltext);
	$string .= "\n\n";
    }
    return $string;
}

sub asAtomString {
    my $self = shift;

    require DateTime;
    require XML::Atom::Feed;
    require XML::Atom::Link;
    require XML::Atom::Entry;

    my $feed = XML::Atom::Feed->new;
    $feed->title($self->getServiceName);
    $feed->info($self->getServiceDescription);

    my $link = XML::Atom::Link->new;
    $link->type('text/html');
    $link->rel('alternate');
    $link->title($self->getServiceName);
    $link->href($self->getChannelUrl);
    $feed->add_link($link);
    $feed->modified(DateTime->now->iso8601 . 'Z');

    my $author = XML::Atom::Person->new;
    $author->name($self->getServiceName);

    $self->entry_callback(sub {
        my ($url, $cont, $rel, $summary, $fulltext, $date) = @_;

        my $dt = DateTime->from_epoch( epoch => $date );
        my $entry = XML::Atom::Entry->new;
        $entry->title($cont);
        $entry->content($fulltext);
        $entry->summary($summary);
        $entry->issued($dt->iso8601 . 'Z');
        $entry->modified($dt->iso8601 . 'Z');
        $entry->id($url);
        $entry->author($author);

        my $link = XML::Atom::Link->new;
        $link->type('text/html');
        $link->rel('alternate');
        $link->href($url);
        $link->title($cont);
        $entry->add_link($link);
        $feed->add_entry($entry);
    });

    my $xml = $feed->as_xml;
    $xml =~ s/<feed\b(?![^>]*version=)/<feed version="0.3"/;
    return $xml;
}

sub asRssString {
    my $self = shift;

    require XML::RSS;
    my $rss = XML::RSS->new(version => '1.0');

    $rss->add_module(
	prefix => 'content',
	uri    => 'http://purl.org/rss/1.0/modules/content/',
    );

    $rss->channel(
	title       => fixEm($self->getServiceName),
	link        => fixEm($self->getChannelUrl),
	description => fixEm($self->getServiceDescription)
    );

    $rss->image(
	title => fixEm($self->getServiceName),
	url   => fixEm($self->getPictureUrl),
	link  => fixEm($self->getHost)
    );

    $rss->textinput(
	title       => fixEm($self->getServiceName),
	description => "Search this site",
	name        => fixEm($self->getQueryAttr),
	link        => fixEm($self->getChannelUrl)
    );

    $self->entry_callback(sub {
        my ($url, $cont, $rel, $summary, $fulltext, $date) = @_;
	$rss->add_item(
	    title       => fixEm($cont),
	    link        => fixEm($url),
	    description => fixEm($summary),
(length $fulltext) ? (
	    content	=> {
		encoded => fixEm($fulltext),
	    }
) : (),
	);
    });

    return $rss->as_string;
}

sub entry_callback {
    my ($self, $callback) = @_;
    $self->reset;

    while (my ($url, $cont, $rel, $summary, $fulltext, $date) = $self->get) {
        if (!length $summary and length $fulltext and $WWW::SherlockSearch::ExcerptLength) {
            $summary = substr($fulltext, 0, $WWW::SherlockSearch::ExcerptLength);
            $summary .= '...' unless $summary eq $fulltext;
        }
        $callback->($url, $cont, $rel, $summary, $fulltext, $date);
    }
}

#This is a cludge to fix xml problems

sub fixEm {
    my $text = shift;

    $text =~ s/&/&amp;/gs;
    $text =~ s/</&lt;/gs;
    $text =~ s/>/&gt;/gs;

    return $text;
}

1;

=head1 SEE ALSO

L<WWW::SherlockSearch>

=head1 AUTHORS

=over 4

=item *

Damian Steer E<lt>D.M.Steer@lse.ac.ukE<gt>

=item *

Kang-min Liu E<lt>gugod@gugod.org<gt>

=item *

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 1999, 2000, 2001 by Damian Steer.

Copyright 2002, 2003 by Kang-min Liu.

Copyright 2002, 2003, 2004 by Autrijus Tang.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
