package Wiki::Toolkit::Feed::Listing;

use strict;
use Carp qw( croak );

=head1 NAME

Wiki::Toolkit::Feed::Listing - parent class for Feeds from Wiki::Toolkit.

=head1 DESCRIPTION

Handles common data fetching tasks, so that child classes need only
worry about formatting the feeds.

Also enforces some common methods that must be implemented.

=head1 METHODS

=head2 C<fetch_recently_changed_nodes>

Based on the supplied criteria, fetch a list of the recently changed nodes

=cut

sub fetch_recently_changed_nodes {
    my ($self, %args) = @_;

    my $wiki = $self->{wiki};

    my %criteria = (
                   ignore_case => 1,
                   );

    # If we're not passed any parameters to limit the items returned, 
    #  default to 15.
    $args{days} ? $criteria{days}           = $args{days}
                : $criteria{last_n_changes} = $args{items} || 15;

    my %was_filter;
    if ( $args{filter_on_metadata} ) {
        %was_filter = %{ $args{filter_on_metadata} };
    }

    if ( $args{ignore_minor_edits} ) {
        %was_filter = ( %was_filter, major_change => 1 );
    }
  
    $criteria{metadata_was} = \%was_filter;

    my @changes = $wiki->list_recent_changes(%criteria);

    return @changes;
}

=head2 C<fetch_newest_for_recently_changed>

Based on the supplied criteria (but not using all of those used by
B<fetch_recently_changed_nodes>), find the newest node from the recently
changed nodes set. Normally used for dating the whole of a Feed.

=cut

sub fetch_newest_for_recently_changed {
    my ($self, %args) = @_;

    my @changes = $self->fetch_recently_changed_nodes( %args );
    return $changes[0];
}


=head2 C<fetch_node_all_versions>

For a given node (name or ID), return all the versions there have been,
including all metadata required for it to go into a "recent changes"
style listing.

=cut

sub fetch_node_all_versions {
    my ($self, %args) = @_;

    # Check we got the right options
    unless($args{'name'}) {
        return ();
    }

    # Do the fetch
    my @nodes = $self->{wiki}->list_node_all_versions(
                        name => $args{'name'},
                        with_content => 0,
                        with_metadata => 1,
    );

    # Ensure that all the metadata fields are arrays and not strings
    foreach my $node (@nodes) {
        foreach my $mdk (keys %{$node->{'metadata'}}) {
            unless(ref($node->{'metadata'}->{$mdk}) eq "ARRAY") {
                $node->{'metadata'}->{$mdk} = [ $node->{'metadata'}->{$mdk} ];
            }
        }
    }

    return @nodes;
}


=head2 C<recent_changes>

Build an Atom Feed of the recent changes to the Wiki::Toolkit instance,
using any supplied parameters to narrow the results.

If the argument "also_return_timestamp" is supplied, it will return an
array of the feed, and the feed timestamp. Otherwise it just returns the feed.

=cut

sub recent_changes {
    my ($self, %args) = @_;

    my @changes = $self->fetch_recently_changed_nodes(%args);
    my $feed_timestamp = $self->feed_timestamp(
                              $self->fetch_newest_for_recently_changed(%args)
    );

    my $feed = $self->generate_node_list_feed($feed_timestamp, @changes);

    if ($args{'also_return_timestamp'}) {
        return ($feed,$feed_timestamp);
    } else {
        return $feed;
    }
}


=head2 C<node_all_versions>

Build an Atom Feed of all the different versions of a given node.

If the argument "also_return_timestamp" is supplied, it will return an
array of the feed, and the feed timestamp. Otherwise it just returns the feed.

=cut

sub node_all_versions {
    my ($self, %args) = @_;

    my @all_versions = $self->fetch_node_all_versions(%args);
    my $feed_timestamp = $self->feed_timestamp( $all_versions[0] );

    my $feed = $self->generate_node_list_feed($feed_timestamp, @all_versions);

    if($args{'also_return_timestamp'}) {
        return ($feed,$feed_timestamp);
    } else {
        return $feed;
    }
} 

=head2 C<format_geo>

Using the geo and space xml namespaces, format the supplied node metadata
into geo: and space: tags, suitable for inclusion in a feed with those
namespaces imported.

=cut

sub format_geo {
    my ($self, @args) = @_;

    my %metadata;
    if(ref($args[0]) eq "HASH") {
        %metadata = %{$_[1]};
    } else {
        %metadata = @args;
    }

    my %mapping = (
            "os_x" => "space:os_x",
            "os_y" => "space:os_y",
            "latitude"  => "geo:lat",
            "longitude" => "geo:long",
            "distance"  => "space:distance",
    );

    my $feed = "";

    foreach my $geo (keys %metadata) {
        my $geo_val = $metadata{$geo};
        if(ref($geo_val) eq "ARRAY") {
            $geo_val = $geo_val->[0];
        }

        if($mapping{$geo}) {
            my $tag = $mapping{$geo};
            $feed .= "  <$tag>$geo_val</$tag>\n";
        }
    }

    return $feed;
}

# Utility method, to help with argument passing where one of a list of 
#  arguments must be supplied

sub handle_supply_one_of {
    my ($self,$mref,$aref) = @_;
    my %mustoneof = %{$mref};
    my %args = %{$aref};

    foreach my $oneof (keys %mustoneof) {
        my $val = undef;
        foreach my $poss (@{$mustoneof{$oneof}}) {
            unless($val) {
                if($args{$poss}) { $val = $args{$poss}; }
            }
        }
        if($val) {
            $self->{$oneof} = $val;
        } else {
            croak "No $oneof supplied, or one of its equivalents (".join(",", @{$mustoneof{$oneof}}).")";
        }
    }
}


=pod

The following are methods that any feed renderer must provide:

=head2 C<feed_timestamp>

All implementing feed renderers must implement a method to produce a
feed specific timestamp, based on the supplied node

=cut

sub feed_timestamp          { die("Not implemented by feed renderer!"); }

=head2 C<generate_node_list_feed>

All implementing feed renderers must implement a method to produce a
feed from the supplied list of nodes

=cut

sub generate_node_list_feed { die("Not implemented by feed renderer!"); }

=head2 C<generate_node_name_distance_feed>

All implementing feed renderers must implement a method to produce a
stripped down feed from the supplied list of node names, and optionally
locations and distance from a reference point.

=cut

sub generate_node_name_distance_feed { die("Not implemented by feed renderer!"); }

=head2 C<parse_feed_timestamp>

Take a feed_timestamp and return a Time::Piece object. 

=cut

sub parse_feed_timestamp { die("Not implemented by feed renderer!"); }

1;

__END__

=head1 MAINTAINER

The Wiki::Toolkit team, http://www.wiki-toolkit.org/.

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 the Wiki::Toolkit team.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
