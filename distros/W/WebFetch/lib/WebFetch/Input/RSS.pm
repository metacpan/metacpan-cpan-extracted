#
# WebFetch::Input::RSS - get headlines from remote RSS feed
#
# Copyright (c) 1998-2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch::Input::RSS;

use strict;
use base "WebFetch";

use Carp;
use Scalar::Util qw( blessed );
use Date::Calc qw(Today Delta_Days Month_to_Text);
use XML::RSS;
use LWP::UserAgent;

use Exception::Class (
);

=head1 NAME

WebFetch::Input::RSS - download and save an RSS feed

=cut

our @Options = ();
our $Usage = "";

# configuration parameters

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register( "input:rss" );

=head1 SYNOPSIS

In perl scripts:

C<use WebFetch::Input::RSS;>

From the command line:

C<perl -w -MWebFetch::Input::RSS -e "&fetch_main" -- --dir directory
     --source rss-feed-url [...WebFetch output options...]>

=cut

# called from WebFetch main routine
sub fetch
{
	my ( $self ) = @_;

	# set up Webfetch Embedding API data
	$self->data->add_fields( "pubDate", "title", "link", "category",
		"description" );
	# defined which fields match to which "well-known field names"
	$self->data->add_wk_names(
		"title" => "title",
		"url" => "link",
		"date" => "pubDate",
		"summary" => "description",
		"category" => "category",
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

# parse RSS feed into hash structure
sub parse_rss
{
	my $text = shift;
	my $rss = new XML::RSS;
	$rss->parse($text);

	# parse values from top of structure
	my ( %feed, $field, $item, @buckets );
	foreach $field ( keys %$rss ) {
		if ( ref $rss->{$field} eq "HASH" ) {
			push @buckets, $field;
		}
		my $value = extract_value( $rss->{$field});
		( defined $value ) or next;
		$feed{$field} = $value;
	}

	# parse hashes, i.e. channel parameters, XML/RSS modeules, etc
	my $bucket;
	foreach $bucket ( @buckets ) {
		( defined $rss->{$bucket}) or next;
		$feed{$bucket} = {};
		foreach $field ( keys %{$rss->{$bucket}} ) {
			my $value = extract_value( $rss->{$bucket}{$field});
			( defined $value ) or next;
			$feed{$bucket}{$field} = $value;
		}
	}

	# parse each item from the news feed
	$feed{items} = [];
	foreach $item ( @{$rss->{items}}) {
		my $f_item = {};
		foreach $field ( keys %$item ) {
			my $value = extract_value( $item->{$field});
			( defined $value ) or next;
			$f_item->{$field} = $value;
		}
		push @{$feed{items}}, $f_item;
	}

	return \%feed;
}

# parse RSS input
sub parse_input
{
	my $self = shift;

	# parse data file
	my $raw_rss = $self->get();
	my $feed = parse_rss( $$raw_rss );

	# translate parsed RSS feed into the WebFetch Embedding API data table
	my ( $item, %label_hash, $pos );
	$pos = 0;
	foreach $item ( @{$feed->{items}} ) {

		# save the data record
		my $title = ( defined $item->{title}) ? $item->{title} : "";
		my $link = ( defined $item->{link}) ? $item->{link} : "";
		my $pub_date = ( defined $item->{pubDate})
			? $item->{pubDate} : "";
		my $category = ( defined $item->{category})
			? $item->{category} : "";
		my $description = ( defined $item->{description})
			? $item->{description} : "";
		$self->data->add_record( $pub_date, $title, $link,
			$category, $description );
		$pos++;
	}
}

1;
__END__
# POD docs follow

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

=head1 RSS FORMAT

RSS is an XML format defined at http://www.rssboard.org/rss-specification

WebFetch::Input::RSS uses Perl's XML::RSS to parse RSS "Really Simple
Syndication" version 0.9, 0.91, 1.0 or 2.0,
whichever is provided by the server.

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
