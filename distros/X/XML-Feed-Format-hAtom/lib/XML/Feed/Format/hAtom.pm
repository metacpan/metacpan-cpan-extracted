package XML::Feed::Format::hAtom;

use strict;
use base qw( XML::Feed );
use Data::Microformat::hFeed;
use Data::Microformat::hCard;
use Data::Microformat::geo;

our $VERSION = "0.5";

sub identify {
    my $class   = shift;
    my $xml     = shift;
    my $tag     = $class->_get_first_tag($xml);
    return ($tag eq 'html');
}

sub init_empty {
	my ($feed, %args) = @_;

    $feed->{hatom} = Data::Microformat::hFeed->new(%args);
    $feed;
}

sub init_string {
	my  $feed = shift;
	my ($str) = @_;
	if ($str) {
		eval { $feed->{hatom} = Data::Microformat::hFeed->parse($str) };
		return $feed->error($@) if $@;
	}
	$feed;
}

sub format { 'hAtom' }

sub tagline     { shift->{hatom}->tagline(@_) }
sub description { shift->{hatom}->tagline(@_) }
sub title       { shift->{hatom}->title(@_) }
sub link        { shift->{hatom}->link(@_)  }
sub self_link   { shift->{hatom}->link(@_)  }
sub generator   { shift->{hatom}->generator(@_) }
sub id          { shift->{hatom}->id(@_) }
sub updated     { shift->{hatom}->modified(@_) }
sub modified    { shift->{hatom}->modified(@_) }
sub copyright   { 
	my $feed = shift;
	if (@_ && defined $_[0]) {
		$feed->{hatom}->copyright({ text => $_[0] });
	} else {
		$feed->{hatom}->copyright ? $feed->{hatom}->copyright->{text} : undef;
	}
}

sub lat  { shift->_do_geo('longitude', @_) }
sub long { shift->_do_geo('longitude', @_) }

sub _do_geo {
	my $thing = shift;
	my $what  = shift;
	my $geo   = $thing->geo;

	if (@_ && defined $_[0]) {
		$geo  = Data::Microformat::geo->new unless defined $geo;
		$geo->$what($_[0]);
		$thing->geo($geo);
	} elsif (defined $geo) {
		return $geo->$what;
	} else {
		return undef;	
	}	
}

sub category  { shift->{hatom}->categories(@_) } 

sub language { shift->{hatom}->language(@_) }

# TODO
# add_link

sub author {
	my $feed = shift;
	if (@_ && defined $_[0]) {
		my $person = Data::Microformat::hCard->new;
		$person->fn($_[0]);
		$feed->{hatom}->author($person);
	} else {
		$feed->{hatom}->author ? $feed->{hatom}->author->fn : undef;
	}
}

sub entries {
	my @entries;
  	for my $entry ($_[0]->{hatom}->entries) {
        push @entries, XML::Feed::Entry::Format::hAtom->wrap($entry);
    }
    @entries;
}

sub add_entry {
	my $feed  = shift;
	my $entry = shift || return;
	$entry    = $feed->_convert_entry($entry);
	$feed->{hatom}->entries($entry->{entry});
}

sub as_xml { shift->{hatom}->to_html }

package XML::Feed::Entry::Format::hAtom;
use strict;

use base qw( XML::Feed::Entry );
use XML::Feed::Content;
use Data::Microformat::hFeed::hEntry;
use Data::Microformat::geo;
use HTML::Entities;

sub init_empty {
	my $entry = shift;
	$entry->{entry} = Data::Microformat::hFeed::hEntry->new;
	$entry;
}

sub title    { shift->{entry}->title(@_)    }
sub source   { shift->{entry}->source(@_)   }
sub updated  { shift->{entry}->updated(@_)  }
sub base     { shift->{entry}->base(@_)     }
sub link     { shift->{entry}->link(@_)     }
sub id       { shift->{entry}->id(@_)       }
sub issued   { shift->{entry}->issued(@_)   } 
sub modified { shift->{entry}->modified(@_) }

sub lat  { shift->_do_geo('longitude', @_) }
sub long { shift->_do_geo('longitude', @_) }

sub _do_geo {
    my $thing = shift;
    my $what  = shift;
    my $geo   = $thing->{entry}->geo;

    if (@_ && defined $_[0]) {
        $geo  = Data::Microformat::geo->new unless defined $geo;
        $geo->$what($_[0]);
        $thing->geo($geo);
    } elsif (defined $geo) {
        return $geo->$what;
    } else {
        return undef;
    }
}


sub summary { shift->_do_text('summary', @_) }
sub content { shift->_do_text('content', @_) } 

sub _do_text {
	my $entry = shift;
	my $field = shift;
	if (@_ && defined $_[0]) {
		if (ref($_[0]) eq 'XML::Feed::Content') {
			my $content = (defined $_[0]->type && $_[0]->type eq 'text/plain') ? encode_entities($_[0]->body) : $_[0]->body;
			$entry->{entry}->$field($content);			
		} else {
			$entry->{entry}->$field($_[0]);
		}
	} else {
		return XML::Feed::Content->new({ type => 'text/html', body => $entry->{entry}->$field });
	}
}

sub category { shift->{entry}->tags(@_) }

sub author {
	my $entry = shift;
	if (@_ && $_[0]) {
		my $person = Data::Microformat::hCard->new;
		$person->fn($_[0]);
		$entry->{entry}->author($person);
	} else {
		$entry->{entry}->author ? $entry->{entry}->author->fn : undef;
	}
}

sub as_xml { shift->{entry}->to_html }

1;

__END__
=head1 NAME

XML::Feed::Format::hAtom - plugin to provide transparent parsing and generation support for hAtom to XML::Feed

=head1 SYNOPSIS

    use XML::Feed;
    my $feed = XML::Feed->parse(URI->new('http://example.com/hatom.html'))
        or die XML::Feed->errstr;
    print $feed->title, "\n";
    for my $entry ($feed->entries) {
    }


=head1 DESCRIPTION

I<XML::Feed> is a syndication feed parser for both RSS and Atom feeds. It
also implements feed auto-discovery for finding feeds, given a URI.

I<XML::Feed::Format::hAtom> adds transparent support for the hAtom microformat.

	http://microformats.org/wiki/hatom	

=head1 METHODS

See I<XML::Feed> and I<XML::Feed::Entry> - hAtom support is transparent.

=head2 I<XML::Feed::Format::hAtom>->identify <content>

Whether or not this in hAtom feed.

=head2 I<XML::Feed::Format::hAtom>->init_string <content>

Initialise a new Feed from a string. 

Alias for C<parse>.

=head2 $feed->id

Returns the id of the feed.

=head2 $feed->format

Returns the format of the feed (C<hAtom>).

=head2 $feed->title([ $title ])

The title of the feed/channel.

=head2 $feed->base([ $base ])

The url base of the feed/channel.

=head2 $feed->link([ $uri ])

The permalink of the feed/channel.

=head2 $feed->tagline([ $tagline ])

The description or tagline of the feed/channel.

=head2 $feed->description([ $description ])

Alias for I<$feed-E<gt>tagline>.

=head2 $feed->author([ $author ])

The author of the feed/channel.

=head2 $feed->language([ $language ])

The language of the feed.

=head2 $feed->copyright([ $copyright ])

The copyright notice of the feed.

=head2 $feed->modified([ $modified ])

A I<DateTime> object representing the last-modified date of the feed.

If present, I<$modified> should be a I<DateTime> object.

=head2 $feed->updated([ $updated ])

Alias for I<modified>.

=head2 $feed->generator([ $generator ])

The generator of the feed.

=head2 $feed->category ([ $category ])

The category for this feed.

=head2 $feed->self_link ([ $uri ])

The Atom Self-link of the feed:

L<http://validator.w3.org/feed/docs/warning/MissingAtomSelfLink.html>

A string.

=head2 $feed->long ([ $lat ])

=head2 $feed->lat ([ $lat ])

The longitude and latitude of the entry if available.


=head2 $feed->entries

A list of the entries/items in the feed. Returns an array containing
I<XML::Feed::Entry> objects.

=head2 $feed->items

A synonym for I<$feed->entries>.

=head2 $feed->add_entry($entry)

Adds an entry to the feed. I<$entry> should be an I<XML::Feed::Entry>
object in the correct format for the feed.

=head2 $feed->as_xml

Returns an HTML representation of the feed, in the format determined by
the current format of the I<$feed> object.

=head1 LICENSE

I<XML::Feed::Format::hAtom> is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Written by Simon Wistow <swistow@sixapart.com>

Except where otherwise noted, I<XML::Feed::Format::hAtom> is Copyright 2008
Six Apart, cpan@sixapart.com. All rights reserved.

=head1 SUBVERSION

The latest version of I<XML::Feed::Format::hAtom> can be found at

    http://code.sixapart.com/svn/XML-Feed-Format-hAtom/trunk/

=cut


