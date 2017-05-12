package XML::Feed::Aggregator;
BEGIN {
  $XML::Feed::Aggregator::VERSION = '0.0401';
}
use Moose;
use MooseX::Types::Moose qw/ArrayRef Str/;
use MooseX::Types -declare => [qw/
    Sources Feed AtomFeed AtomEntry 
    RSSFeed RSSEntry Feeds Entry
    /];
use MooseX::Types::URI 'Uri';
use Moose::Util::TypeConstraints;
use URI;
use XML::Feed;
use Try::Tiny;
use namespace::autoclean;

class_type RSSEntry, {class => 'XML::Feed::Entry::Format::RSS'};
class_type AtomEntry, {class => 'XML::Feed::Entry::Format::Atom'};
class_type AtomFeed, {class => 'XML::Feed::Format::RSS'};
class_type RSSFeed, {class => 'XML::Feed::Format::Atom'};

subtype Sources,
    as ArrayRef[Uri];

coerce Sources,
    from ArrayRef[Str],
    via {
        [ map { Uri->coerce($_) } @{$_} ]
    };

subtype Feed,
    as AtomFeed|RSSFeed,
    message { "$_ is not a Feed!" };

subtype Entry,
    as AtomEntry|RSSEntry,
    message { "$_ is not an Entry!" };

has sources => (
    is => 'rw',
    isa => Sources,
    traits => [qw/Array/],
    default => sub { [] },
    coerce => 1,
    handles => {
        all_sources => 'elements',
        add_source => 'push',
    },
);

has feeds => (
    is => 'rw',
    isa => ArrayRef[Feed],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        all_feeds => 'elements',
        add_feed => 'push',
        feed_count => 'count',
    },
);

has entries => (
    is => 'rw',
    isa => ArrayRef[Entry],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        all_entries => 'elements',
        add_entry => 'push',
        sort_entries => 'sort_in_place',
        map_entries => 'map',
        entry_count => 'count',
    }
);

has _errors => (
    is => 'rw',
    isa => ArrayRef[Str],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        errors => 'elements',
        error_count => 'count',
        add_error => 'push',
    }
);

with 'XML::Feed::Aggregator::Sort';
with 'XML::Feed::Aggregator::Deduper';

sub fetch {
    my ($self) = @_;

    for my $uri ($self->all_sources) {
        try {
            $self->add_feed(XML::Feed->parse($uri));
        }
        catch {
            $self->add_error($uri->as_string." - failed: $_"); 
        };
    }

    return $self;
}

sub aggregate {
    my ($self) = @_;

    return $self if $self->entry_count > 0;

    for my $feed ($self->all_feeds) {
        $self->add_entry($feed->entries);
    }

    $self->grep_entries(sub { defined $_ });

    return $self;
}

sub grep_entries {
    my ($self, $filter) = @_;

    my @entries = grep { $filter->($_) } $self->all_entries;
    $self->entries(\@entries);

    return $self;
}

sub to_feed {
    my ($self, @params) = @_;

    my $feed = XML::Feed->new(@params);

    for my $entry ($self->all_entries) {
        $feed->add_entry($entry);
    }

    return $feed;
}

1;


=pod

=head1 NAME

XML::Feed::Aggregator

=head1 VERSION

version 0.0401

=head1 SYNOPSIS

    use XML::Feed::Aggregator;

    my $syndicator = XML::Feed::Aggregator->new(
        sources => [
            "http://blogs.perl.org/atom.xml",
            "http://news.ycombinator.com/"
        ],
        feeds => [ XML::Feed->parse('./slashdot.rss') ]
    
    )->fetch->aggregate->deduplicate->sort_by_date;

    $syndicator->grep_entries(sub {
        $_->author ne 'James'
    })->deduplicate;

    say $syndicator->map_entries(sub { $_->title } );

=head1 DESCRIPTION

This module aggregates feeds from different sources for easy filtering and sorting.

=head1 NAME

XML::Feed::Aggregator - Simple feed aggregator

=head1 ATTRIBUTES

=head2 sources

Sources to be fetched and loaded into the feeds attribute.

Coerces to an ArrayRef of URI objects.

=head2 feeds

An ArrayRef of XML::Feed objects.

=head2 entries

List of XML::Feed::Entry objects obtained from each feed

=head1 METHODS

=head2 fetch

Convert each source into an XML::Feed object, via XML::Feed->parse()

For a remote address this involves a http request.

=head2 aggregate

Combine all feed entries into a single 'entries' attribute

=head2 to_feed

Export aggregated feed to a single XML::Feed object. 

All parameters passed to L<XML::Feed> constructor.

=head1 FEED METHODS

Methods relating to the 'feeds' attribute

=head2 add_feed

Add a new feed to the 'feeds' attribute.

=head2 all_feeds

Return all feeds as an Array.

=head2 feed_count

Number of feeds.

=head1 ENTRY METHODS

Methods relating to the 'entries' attribute

=head2 sort_entries

See L<XML::Feed::Aggregator::Sort>

=head2 map_entries

Loop over all entries using $_ within a CodeRef.

=head2 grep_entries

Grep through entries using $_ within a CodeRef.

=head2 add_entry

Add a new entry to the aggregated feed.

=head2 entry_count

Number of entries.

=head2 all_entries

Returns all entries as an array

=head1 ROLES

This class consumes the following roles for sorting and deduplication.

L<XML::Feed::Aggregator::Deduper>
L<XML::Feed::Aggregator::Sort>

=head1 ERROR HANDLING

=head2 error_count

Number of errors occured.

=head2 errors

An ArrayRef of errors whilst fetching / parsing feeds.

=head1 SEE ALSO

L<XML::Feed::Aggregator::Deduper>

L<XML::Feed::Aggregator::Sort>

L<App::Syndicator> L<Perlanet> L<XML::Feed> L<Feed::Find>

=head1 AUTHOR

Robin Edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robin Edwards.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

