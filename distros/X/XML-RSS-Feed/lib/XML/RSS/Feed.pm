package XML::RSS::Feed;
use strict;
use warnings;
use XML::RSS;
use XML::RSS::Headline;
use Time::HiRes;
use Storable qw(store retrieve);
use Carp qw(carp);

use constant DEFAULT_DELAY => 3600;

our $VERSION = 2.4;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        process_count       => 0,
        rss_headlines       => [],
        rss_headline_ids    => {},
        max_headlines       => 0,
        init_headlines_seen => 0,
    }, $class;

    foreach my $method ( keys %args ) {
        if ( $self->can($method) ) {
            $self->$method( $args{$method} );
        }
        else {
            carp "Invalid argument '$method'";
        }
    }
    $self->_load_cached_headlines if $self->{tmpdir};
    $self->delay(DEFAULT_DELAY) unless $self->delay;
    return $self;
}

sub _load_cached_headlines {
    my ($self)       = @_;
    my $filename_sto = $self->{tmpdir} . '/' . $self->name . '.sto';
    my $filename_xml = $self->{tmpdir} . '/' . $self->name;
    if ( -s $filename_sto ) {
        my $cached = retrieve($filename_sto);
        my $title = $self->title || $cached->{title} || '';
        $self->set_last_updated( $cached->{last_updated} );
        $self->{process_count}++;
        $self->process( $cached->{items}, $title, $cached->{link} );
        warn "[$self->{name}] Loaded Cached RSS Storable\n" if $self->{debug};
    }
    elsif ( -T $filename_xml ) {    # legacy XML caching
        if ( open( my $fh, '<', $filename_xml ) ) {
            my $xml = do { local $/ = undef, <$fh> };
            close $fh;
            warn "[$self->{name}] Loaded Cached RSS XML\n" if $self->{debug};
            $self->{process_count}++;
            $self->parse($xml);
        }
        else {
            carp "[$self->{name}] Failed to load XML cache $filename_xml\n";
        }
    }
    else {
        warn "[$self->{name}] No Cache File Found\n" if $self->{debug};
    }
    return;
}

sub _strip_whitespace {
    my ($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _mark_all_headlines_seen {
    my ($self) = @_;
    return unless $self->{process_count} || $self->{init_headlines_seen};
    $self->{rss_headline_ids}{ $_->id } = 1 for $self->late_breaking_news;
    return;
}

sub parse {
    my ( $self, $xml ) = @_;
    my $rss = XML::RSS->new();
    eval { $rss->parse($xml) };
    unless ($@) {
        warn "[$self->{name}] Parsed RSS XML\n" if $self->{debug};
        my $items = [ map { { item => $_ } } @{ $rss->{items} } ];

        $self->process(
            $items,
            ( $self->title || $rss->{channel}{title} ),
            $rss->{channel}{link}
        );

        return 1;
    }
    carp "[$self->{name}] [!!] Failed to parse RSS XML: $@\n";
    return;
}

sub process {
    my ( $self, $items, $title, $link ) = @_;
    return unless $items;
    $self->pre_process;
    $self->process_items($items);
    $self->title($title) if $title;
    $self->link($link)   if $link;
    $self->post_process;
    return 1;
}

sub pre_process {
    my ($self) = @_;
    $self->_mark_all_headlines_seen;
    return;
}

sub process_items {
    my ( $self, $items ) = @_;
    return unless $items;

    # used 'reverse' so order seen is preserved
    for my $item ( reverse @$items ) {
        $self->create_headline(%$item);
    }
    return 1;
}

sub post_process {
    my ($self) = @_;
    if ( $self->init ) {
        warn "[$self->{name}] "
            . $self->late_breaking_news
            . " New Headlines Found\n"
            if $self->{debug};
    }
    else {
        $self->_mark_all_headlines_seen;
        $self->init(1);
        warn "[$self->{name}] "
            . $self->num_headlines
            . " Headlines Initialized\n"
            if $self->{debug};
    }
    $self->{process_count}++;
    $self->cache;
    $self->set_last_updated;
    return;
}

sub create_headline {
    my ( $self, %args ) = @_;
    my $hlobj = $self->{hlobj} || 'XML::RSS::Headline';
    $args{headline_as_id} = $self->{headline_as_id};
    my $headline = $hlobj->new(%args);
    return unless $headline;

    unshift( @{ $self->{rss_headlines} }, $headline )
        unless $self->seen_headline( $headline->id );

    # remove the oldest if the new headline put us over the max_headlines limit
    if ( $self->max_headlines ) {
        while ( $self->num_headlines > $self->max_headlines ) {
            my $garbage = pop @{ $self->{rss_headlines} };

            # just in case max_headlines < number of headlines in the feed
            $self->{rss_headline_ids}{ $garbage->id } = 1;
            warn "[$self->{name}] Exceeded maximum headlines, removing "
                . "oldest headline\n"
                if $self->{debug};
        }
    }
    return;
}

sub num_headlines {
    my ($self) = @_;
    return scalar @{ $self->{rss_headlines} };
}

sub seen_headline {
    my ( $self, $id ) = @_;
    return 1 if exists $self->{rss_headline_ids}{$id};
    return;
}

sub headlines {
    my ($self) = @_;
    return wantarray ? @{ $self->{rss_headlines} } : $self->{rss_headlines};
}

sub late_breaking_news {
    my ($self) = @_;
    my @list = grep { !$self->seen_headline( $_->id ); }
        @{ $self->{rss_headlines} };
    return wantarray ? @list : scalar @list;
}

sub cache {
    my ($self) = @_;
    return unless $self->tmpdir;
    if ( -d $self->tmpdir && $self->num_headlines ) {
        my $tmp_filename = $self->tmpdir . '/' . $self->{name} . '.sto';
        eval { store( $self->_build_dump_structure, $tmp_filename ) };
        if ($@) {
            carp "[$self->{name}] Could not cache RSS XML to $tmp_filename\n";
            return;
        }
        else {
            warn "[$self->{name}] Cached RSS Storable to $tmp_filename\n" if $self->{debug};
            return 1;
        }
    }
    return;
}

sub _build_dump_structure {
    my ($self) = @_;
    my $cached = {};
    $cached->{title}        = $self->title;
    $cached->{link}         = $self->link;
    $cached->{last_updated} = $self->{timestamp_hires};
    $cached->{items}        = [];
    for my $headline ( $self->headlines ) {
        push @{ $cached->{items} }, {
            headline    => $headline->headline,
            url         => $headline->url,
            description => $headline->description,
            first_seen  => $headline->first_seen_hires,
            guid        => $headline->guid,
        };
    }
    return $cached;
}

sub set_last_updated {
    my ( $self, $hires_time ) = @_;
    $self->{hires_timestamp} = $hires_time if $hires_time;
    $self->{hires_timestamp} = Time::HiRes::time()
        unless $self->{hires_timestamp};
    return;
}

sub last_updated {
    my ($self) = @_;
    return int $self->{hires_timestamp};
}

sub last_updated_hires {
    my ($self) = @_;
    return $self->{hires_timestamp};
}

sub title {
    my ( $self, $title ) = @_;
    if ($title) {
        $title = _strip_whitespace($title);
        $self->{title} = $title if $title;
    }
    return $self->{title};
}

sub debug {
    my $self = shift @_;
    $self->{debug} = shift if @_;
    return $self->{debug};
}

sub init {
    my $self = shift @_;
    $self->{init} = shift if @_;
    return $self->{init};
}

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    return $self->{name};
}

sub delay {
    my $self = shift @_;
    $self->{delay} = shift if @_;
    return $self->{delay};
}

sub link {
    my $self = shift @_;
    $self->{link} = shift if @_;
    return $self->{link};
}

sub url {
    my $self = shift @_;
    $self->{url} = shift if @_;
    return $self->{url};
}

sub headline_as_id {
    my ( $self, $bool ) = @_;
    if ( defined $bool ) {
        $self->{headline_as_id} = $bool;
        $_->headline_as_id($bool) for $self->headlines;
    }
    return $self->{headline_as_id};
}

sub hlobj {
    my ( $self, $hlobj ) = @_;
    $self->{hlobj} = $hlobj if defined $hlobj;
    return $self->{hlobj};
}

sub tmpdir {
    my $self = shift @_;
    $self->{tmpdir} = shift if @_;
    return $self->{tmpdir};
}

sub init_headlines_seen {
    my $self = shift @_;
    $self->{init_headlines_seen} = shift if @_;
    return $self->{init_headlines_seen};
}

sub max_headlines {
    my $self = shift @_;
    $self->{max_headlines} = shift if @_;
    return $self->{max_headlines};
}

sub failed_to_fetch {
    carp __PACKAGE__ . '::failed_to_fetch has been deprecated';
    return;
}

sub failed_to_parse {
    carp __PACKAGE__ . '::failed_to_parse has been deprecated';
    return;
}

1;

__END__



=head1 NAME

=encoding utf-8

XML::RSS::Feed - Persistant XML RSS Encapsulation

=head1 VERSION

2.4

=head1 SYNOPSIS

A quick and dirty non-POE example that uses a blocking B<sleep>.  The
magic is in the B<late_breaking_news> method that returns only 
headlines it hasn't seen.

    use XML::RSS::Feed;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	url    => "http://www.jbisbee.com/rdf/",
	name   => "jbisbee",
	delay  => 10,
	debug  => 1,
	tmpdir => "/tmp", # optional caching
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

ATTENTION! - If you want a non-blocking way to watch multiple RSS sources 
with one process use L<POE::Component::RSSAggregator>.

If you want to fetch a feed, mark all the headlines as seen, then get 
events for any new headlines, pass 'init_headlines_seen => 1' to the
constructor.

=head1 CONSTRUCTOR

=head2 XML::RSS::Feed->new( url => $url, name => $name )

=over 4

=item B<Required Params>

=over 4

=item * B<name> 

Identifier and hash lookup key for the RSS feed. 

=item * B<url> 

The URL of the RSS feed

=back

=item B<Optional Params>

=over 4

=item * B<delay> 

Number of seconds between updates (defaults to 600)

=item * B<tmpdir> 

Directory to keep a cached feed (using Storable) to keep persistance between instances.

=item * B<init_headlines_seen>

Mark all headlines as seen from the intial fetch, and only report new headlines that
appear from that point forward.

=item * B<debug>

Turn debuging on.

=item * B<headline_as_id>

Boolean value to use the headline as the id when URL isn't unique within a feed.

=item * B<hlobj>

A class name sublcassed from L<XML::RSS::Headline>

=item * B<max_headlines>

The max number of headlines to keep.  (default is unlimited)

=back

=back

=head1 METHODS

=head2 $feed->parse( $xml_string )

Pass in a xml string to parse with XML::RSS and then call 
process to process the results.

=head2 $feed->process( $items, $title, $link )

=head2 $feed->process( $items, $title )

=head2 $feed->process( $items )

Calls B<pre_process>, B<process_items>, B<post_process>, B<title>, and B<link>
methods to process the parsed results of an RSS XML feed.

=over 4

=item * B<$items>

An array of hash refs which will eventually become L<XML::RSS::Headline> objects.  Look
at XML::RSS::Headline->new() for acceptable arguments.

=item * B<$title>

The title of the RSS feed.

=item * B<$link>

The RSS channel link (normally a URL back to the homepage) of the RSS feed.

=back

=head2 $feed->pre_process

Mark all headlines from previous run as seen.

=head2 $feed->process_items( $items )

Turn an array refs of hash refs into L<XML::RSS::Headline> objects and 
added to the internal list of headlines.

=head2 $feed->post_process

Post process cleanup, cache headlines (if tmpdir), and debug messages.

=head2 $feed->create_headline( %args)

Create a new L<XML::RSS::Headline> object and add it to the interal list.  
Check B<< XML::RSS::Headline->new() >> for acceptable values for B<< %args >>.

=head2 $feed->init_all_headlines_seen()

After fetching a feed for the first time, mark all headlines as seen so
we don't generate a flood of events.  Basically don't issue an event for
any existing headlines, but for any headline from that point on.

=head2 $feed->num_headlines

Returns the number of headlines for the feed.

=head2 $feed->seen_headline( $id )

Just a boolean test to see if we've seen a headline or not.

=head2 $feed->headlines

Returns an array or array reference (based on context) of 
L<XML::RSS::Headline> objects

=head2 $feed->late_breaking_news

Returns an array or the number of elements (based on context) of the 
B<latest> L<XML::RSS::Headline> objects.

=head2 $feed->cache

If tmpdir is defined the rss info is cached.

=head2 $feed->set_last_updated

=head2 $feed->set_last_updated( Time::HiRes::time )

Set the time of when the feed was last processed.  If you pass in a value
it will be used otherwise calls Time::HiRes::time.

=head2 $feed->last_updated

The time (in epoch seconds) of when the feed was last processed.

=head2 $feed->last_updated_hires

The time (in epoch seconds and milliseconds) of when the feed was last 
processed.

=head1 SET/GET ACCESSOR METHODS

=head2 $feed->title

=head2 $feed->title( $title )

The title of the RSS feed.

=head2 $feed->debug

=head2 $feed->debug( $bool )

Turn on debugging messages

=head2 $feed->init

=head2 $feed->init( $bool )

init is used so that we just load the current headlines and don't return all 
headlines.  in other words we initialize them.  Takes a boolean argument.

=head2 $feed->name

=head2 $feed->name( $name )

The identifier of an RSS feed.

=head2 $feed->delay

=head2 $feed->delay( $seconds )

Number of seconds between updates.

=head2 $feed->link

=head2 $feed->link( $rss_channel_url )

The url in the RSS feed with a link back to the site where the RSS feed 
came from.

=head2 $feed->url

=head2 $feed->url( $url )

The url in the RSS feed with a link back to the site where the RSS feed 
came from.

=head2 $feed->headline_as_id

=head2 $feed->headline_as_id( $bool )

Within some RSS feeds the URL may not always be unique, in these cases
you can use the headline as the unique id.  The id is used to check whether
or not a feed is new or has already been seen.

=head2 $feed->hlobj

=head2 $feed->hlobj( $class )

Ablity to use a subclass of L<XML::RSS::Headline>.  (See Perl Jobs example in 
L<XML::RSS::Headline::PerlJobs>).  This should just be the name of the subclass.

=head2 $feed->tmpdir

=head2 $feed->tmpdir( $tmpdir )

Temporay directory to store cached RSS XML between instances for persistance.

=head2 $feed->init_headlines_seen

=head2 $feed->init_headlines_seen( $bool )

Boolean value to mark all headlines as seen from the intial fetch, and only report 
new headlines that appear from that point forward.

=head2 $feed->max_headlines

=head2 $feed->max_headlines( $integer )

The maximum number of headlines you'd like to keep track of.  
(0 means infinate)

=head1 DEPRECATED METHODS

=head2 $feed->failed_to_fetch

This should was deprecated because, the object shouldn't really know
anything about fetching, it just processes the results.  This method 
currently will always return false

=head2 $feed->failed_to_parse

This method was deprecated because, $feed->parse now returns a bool value.
This method will always return false

=head1 AUTHOR

Jeff Bisbee, C<< <jbisbee at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-rss-feed at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-RSS-Feed>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::RSS::Feed

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-RSS-Feed>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-RSS-Feed>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-RSS-Feed>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-RSS-Feed>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Rocco Caputo, Martijn van Beers, Sean Burke, Prakash Kailasa
and Randal Schwartz for their help, guidance, patience, and bug reports. Guys 
thanks for actually taking time to use the code and give good, honest feedback.

Thank for to Carl Fürstenberg for providing feedback for new constructor param 
of 'init_headlines_seen' so you won't get flooded with headlines on the first 
fetch of the feed.

Thanks to Slaven Rezić for pointing out that t/008_store_retrieve.t pointed to
broken rss tests on jbisbee.com (that I don't own anymore)

Thanks to Aaron Krowne for patch for XML::RSS::Headline to use guid as the 
unique id instead of url if its available.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jeff Bisbee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::Fark>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

