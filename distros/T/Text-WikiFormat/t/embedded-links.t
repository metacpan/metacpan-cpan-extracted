#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Text::WikiFormat;

my $wikitext = <<WIKI;

[[SuperLink|[[Description|Desc]] of the [[Link]]]]

WIKI

# Redefine the delimiters to something different.
my %tags = ( extended_link_delimiters => [ '[[', ']]' ] );

my $htmltext =
	Text::WikiFormat::format( $wikitext, \%tags, { extended => 1 } );
is( $htmltext,
    '<p><a href="SuperLink"><a href="Description">Desc</a> of the '.
	    qq|<a href="Link">Link</a></a></p>\n|,
	'...processing all embedded links'
);

TODO:
{
	# Art Henry's bug; but not sure it's really a bug
	local $TODO = "Unsupported MediaWiki features.";

	$tags{link} = \&link_handler;

	# Or with the link handler overridden.
	$htmltext =
		Text::WikiFormat::format( $wikitext, \%tags, { extended => 1 } );
	is(
		$htmltext,
		'Desc of the Link',
		'...and also work with a handler override.'
	);
}

sub link_handler
{
	my ( $link, $opts ) = @_;
	( $link, my $title ) = split( /\|/, $link, 2 );
	return $title;
}
