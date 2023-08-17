# WebFetch::RSS
# ABSTRACT: generate or read an RSS feed for WebFetch
#
# Copyright (c) 1998-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package WebFetch::RSS;
$WebFetch::RSS::VERSION = '0.3.2';
use base "WebFetch";

use if $] < 5.010, "version";
use WebFetch v0.15.5;
use Readonly;
use Carp;
use Try::Tiny;
use Scalar::Util qw( blessed );
use XML::RSS;

#use Data::Dumper; # TODO remove after troubleshooting
use Exception::Class ();

# configuration parameters
Readonly::Scalar my $default_rss_version => "2.0";

# no user-servicable parts beyond this point

# register capabilities with WebFetch
WebFetch->config( "Options", [qw(rss_config:s)] );
WebFetch->config( "Usage",   "--rss_config=filename" );
__PACKAGE__->module_register( "input:rss", "output:rss" );

# called from WebFetch main routine
sub fetch
{
    my ($self) = @_;

    # set up Webfetch Embedding API data
    $self->data->add_fields( "pubDate", "title", "link", "category", "description", "author", "id" );

    # defined which fields match to which "well-known field names"
    $self->data->add_wk_names(
        "title"    => "title",
        "url"      => "link",
        "date"     => "pubDate",
        "summary"  => "description",
        "category" => "category",
        "author"   => "author",
        "id"       => "id",
    );

    # parse data file
    $self->parse_input();

    # return and let WebFetch handle the data
    return;
}

# extract a string value from a scalar/ref if possible
sub extract_value
{
    my $thing = shift;

    ( defined $thing ) or return;
    if ( ref $thing ) {
        if ( !blessed $thing ) {

            # it's a HASH/ARRAY/etc ref
            if ( ref $thing eq "HASH" ) {

                # we need sub-hashes for module namespaces
                return $thing;
            }

            # other refs are not useable here
            return;
        }
        if ( $thing->can("as_string") ) {
            return $thing->as_string;
        }
        return;
    } else {
        $thing =~ s/\s+$//xs;
        length $thing > 0 or return;
        return $thing;
    }
}

# parse RSS feed into hash structure
sub parse_rss
{
    my @args    = @_;
    my $version = $default_rss_version;
    my %params;
    if ( ref $args[0] eq "HASH" ) {
        %params = %{ shift @args };
    }
    my $text = shift @args;
    my $rss  = XML::RSS->new( version => $version );
    try {
        $rss->parse($text);
    } catch {
        WebFetch::throw_network_get( error => "" . $_, client => $rss );
    };
    my ( %feed, @buckets );

    # copy RSS channel data to WebFetch feed data
    if ( exists $rss->{channel} ) {
        $feed{info} = $rss->{channel};
    }

    # parse values from top of structure
    foreach my $field ( keys %$rss ) {
        if ( ref $rss->{$field} eq "HASH" ) {
            push @buckets, $field;
        }
        my $value = extract_value( $rss->{$field} );
        ( defined $value ) or next;
        $feed{$field} = $value;
    }

    # parse hashes, i.e. channel parameters, XML/RSS modeules, etc
    foreach my $bucket (@buckets) {
        ( exists $rss->{$bucket} ) or next;
        $feed{$bucket} = {};
        foreach my $field ( keys %{ $rss->{$bucket} } ) {
            my $value = extract_value( $rss->{$bucket}{$field} );
            ( defined $value ) or next;
            $feed{$bucket}{$field} = $value;
        }
    }

    # parse each item from the news feed
    $feed{items} = [];
    foreach my $item ( @{ $rss->{items} } ) {
        my $f_item = {};
        foreach my $field ( keys %$item ) {
            my $value = extract_value( $item->{$field} );
            ( defined $value ) or next;
            $f_item->{$field} = $value;
        }
        push @{ $feed{items} }, $f_item;
    }

    return \%feed;
}

# retrieve first of multiple keys found in a hash
# The keys should be given in order from highest to lowest priority.
# This handles various RSS feeds which may use original RSS field names or new Dublin Core (dc) synonyms.
sub get_first
{
    my ( $hashref, @keys ) = @_;
    my $result = "";
    foreach my $key (@keys) {

        # search field alternatives in modules such as syndication(sy) or Dublin Core(dc)
        if ( index( $key, ':' ) != -1 ) {
            my ( $module, $field ) = split /:/x, $key, 2;
            if ( exists $hashref->{$module}{$field} ) {
                $result = $hashref->{$module}{$field};
                last;
            }
        }

        # search for key string
        if ( exists $hashref->{$key} ) {
            $result = $hashref->{$key};
            last;
        }
    }
    return $result;
}

# parse RSS input
sub parse_input
{
    my $self = shift;

    # parse data file
    my $raw_rss = $self->get();
    my %params;
    if ( exists $self->{rss_version} ) {
        $params{version} = $self->{rss_version};
    }
    my $feed = parse_rss( \%params, $$raw_rss );

    # copy channel info if present
    if ( exists $feed->{info} ) {
        $self->{data}{feed} = $feed->{info};
    }

    # translate parsed RSS feed into the WebFetch Embedding API data table
    foreach my $item ( @{ $feed->{items} } ) {

        # save the data record
        my $date        = get_first( $item, qw(pubDate date dc:date) );
        my $title       = get_first( $item, qw(title dc:title) );
        my $link        = get_first( $item, qw(link dc:source) );
        my $category    = get_first( $item, qw(category) );
        my $description = get_first( $item, qw(description dc:description) );
        my $author      = get_first( $item, qw(author dc:creator) );
        my $id          = get_first( $item, qw(id identifier dc:identifier) );
        $self->{data}->add_record( $date, $title, $link, $category, $description, $author, $id );
    }
    return;
}

# RSS-output format handler
sub fmt_handler_rss
{
    my ( $self, $filename ) = @_;

    # this is not implemented yet - you'll get an empty RSS structure from it right now

    # generate RSS
    # TODO remove Data::Dumper after troubleshooting
    my $rss = XML::RSS->new( version => '2.0' );

    #WebFetch::debug "self: ".Dumper($self);
    $self->raw_savable( $filename, $rss->as_string() );
    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebFetch::RSS - generate or read an RSS feed for WebFetch

=head1 VERSION

version 0.3.2

=head1 SYNOPSIS

In perl scripts:

  C<use WebFetch::RSS;>

From the command line:

  C<perl -w -MWebFetch::RSS -e "&fetch_main" -- --dir directory --source rss-feed-url [...output options...]>

or

  C<perl -w -MWebFetch::RSS -e "&fetch_main" -- --dir directory [...input options...]> --dest_format=rss --dest=file

=head1 DESCRIPTION

This module reads news items from an RSS feed, or writes previously-fetched data to an RSS file.

For input it uses WebFetch's I<--source> parameter to specify the URL of an RSS feed or a local file
containing RSS XML text.

For output it uses WebFetch's I<--dest> parameter to specify the RSS output file.
(RSS output is not complete yet as of this release.)

=head1 RSS FORMAT

RSS is an XML format defined at http://www.rssboard.org/rss-specification

WebFetch::RSS uses Perl's XML::RSS to generate or parse RSS "Really Simple
Syndication" version 0.9, 0.91, 1.0 or 2.0, whichever is provided by the server.
An optional "--rss_version" command-line parameter or "rss_version" initialization parameter
can set the RSS version number for the parser. If not specified, it defaults to RSS 2.0.

=head1 SEE ALSO

L<WebFetch>
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2022 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__
# POD docs follow

