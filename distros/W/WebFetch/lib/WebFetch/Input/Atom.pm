#
# WebFetch::Input::Atom - get headlines from remote Atom feed
#
# Copyright (c) 1998-2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch::Input::Atom;

use strict;
use base "WebFetch";

use Carp;
use Scalar::Util qw( blessed );
use Date::Calc qw(Today Delta_Days Month_to_Text);
use XML::Atom::Client;
use LWP::UserAgent;

use Exception::Class (
);

=head1 NAME

WebFetch::Input::Atom - WebFetch input from Atom feeds

=head1 SYNOPSIS

This is an input module for WebFetch which accesses an Atom feed.
The --source parameter contains the URL of the feed.

From the command line:

C<perl -w -MWebFetch::Input::Atom -e "&fetch_main" -- --dir directory
     --source atom-feed-url [...WebFetch output options...]>

In perl scripts:

    use WebFetch::Input::Atom;

    my $obj = WebFetch->new(
        "dir" => "/path/to/fetch/workspace",
	"source" => "http://search.twitter.com/search.atom?q=%23twiki",
	"source_format" => "atom",
	"dest" => "dump",
	"dest_format" = "/path/to/dump/file",
    );
    $obj->do_actions; # process output
    $obj->save; # save results


=head1 DESCRIPTION

This module gets the current headlines from a site-local file.

The I<--input> parameter specifies a file name which contains news to be
posted.  See L<"FILE FORMAT"> below for details on contents to put in the
file.  I<--input> may be specified more than once, allowing a single news
output to come from more than one input.  For example, one file could be
manually maintained in CVS or RCS and another could be entered from a
web form.

After this runs, the file C<site_news.html> will be created or replaced.
If there already was a C<site_news.html> file, it will be moved to
C<Osite_news.html>.

=cut


our @Options = ();
our $Usage = "";

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register( "cmdline", "input:atom" );

# called from WebFetch main routine
sub fetch
{
	my ( $self ) = @_;

	# set up Webfetch Embedding API data
	$self->data->add_fields( "id", "updated", "title", "author", "link",
		"summary", "content", "xml" );
	# defined which fields match to which "well-known field names"
	$self->data->add_wk_names(
		"id" => "id",
		"title" => "title",
		"url" => "link",
		"date" => "updated",
		"summary" => "summary",
	);

	# parse data file
	$self->parse_input();

	# return and let WebFetch handle the data
}

# extract a string value from a scalar/ref if possible
sub extract_value
{
        my $thing = shift;

        ( defined $thing ) or return undef;
        if ( ref $thing ) {
                if ( !blessed $thing ) {
                        # it's a HASH/ARRAY/etc, not an object
                        return undef;
                }
                if ( $thing->can( "as_string" )) {
                        return $thing->as_string;
                }
                return undef;
        } else {
                $thing =~ s/\s+$//s;
                length $thing > 0 or return undef;
                return $thing;
        }
}

# parse Atom input
sub parse_input
{
	my $self = shift;
	my $atom_api = XML::Atom::Client->new;
	my $atom_feed = $atom_api->getFeed( $self->{source} );

	# parse values from top of structure
	my ( %feed, @entries, $entry );
	@entries = $atom_feed->entries;
	foreach $entry ( @entries ) {
		# save the data record
		my $id = extract_value( $entry->id() );
		my $title = extract_value( $entry->title() );
		my $author = ( defined $entry->author )
			? extract_value( $entry->author->name ) : "";
		my $link = extract_value( $entry->link->href );
		my $updated = extract_value( $entry->updated() );
		my $summary = extract_value( $entry->summary() );
		my $content = extract_value( $entry->content() );
		my $xml = $entry->as_xml();
		$self->data->add_record( $id, $updated, $title,
			$author, $link, $summary, $content, $xml );
	}
}

1;
__END__
# POD docs follow

=head1 Atom FORMAT

Atom is an XML format defined at http://atompub.org/rfc4287.html

WebFetch::Input::Atom uses Perl's XML::Atom::Client to parse Atom feeds.

=head1 AUTHOR

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

=head1 SEE ALSO

=for html
<a href="WebFetch.html">WebFetch</a>

=for text
WebFetch

=for man
WebFetch

=cut
