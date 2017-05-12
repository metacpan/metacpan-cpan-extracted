#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 8;
use Test::NoWarnings;
use Text::MediawikiFormat
	as             => 'wf',
	implicit_links => 0,
	absolute_links => 0,
	process_html   => 0;

my $wikitext = <<'WIKI';

I download code from http://www.cpan.org/ or ftp://ftp.cpan.org/ and
email mailto:chromatic@example.com

WIKI

my $htmltext = wf( $wikitext, {}, { absolute_links => 1 } );

is $htmltext,
	  qq{<p>I download code from <a href='http://www.cpan.org/'>}
	. qq{http://www.cpan.org/</a> }
	. qq{or <a href='ftp://ftp.cpan.org/'>ftp://ftp.cpan.org/</a> and\n}
	. q{email <a href='mailto:chromatic@example.com'>}
	. q{mailto:chromatic@example.com</a>}
	. qq{</p>\n},
	'Picking up absolute links';

$htmltext = wf( $wikitext, {}, { absolute_links => 0 } );
is $htmltext,
	  qq{<p>I download code from http://www.cpan.org/ or ftp://ftp.cpan.org/ }
	. qq{and\n}
	. q{email mailto:chromatic@example.com}
	. qq{</p>\n},
	q{Doesn't pick up links when absolute_links is off};

$wikitext = "this is a moose:notalink";

$htmltext = wf( $wikitext, {}, { absolute_links => 1 } );
is $htmltext, qq{<p>this is a moose:notalink</p>\n}, q{Doesn't pick up things that might look like links};

$htmltext = wf( $wikitext, { schemas => ['moose'] }, { absolute_links => 1 } );
is $htmltext,
	qq{<p>this is a <a href='moose:notalink'>moose:notalink</a></p>\n},
	q{Schema tag allows specifying what is a link};

$wikitext = <<'WIKI';

http://www.cpan.org/.

A link in angle brackets: <http://link.org>.
WIKI

$htmltext = wf( $wikitext, {}, { absolute_links => 1 } );
like $htmltext, qr{href='http://www.cpan.org/'>}, 'Links work at beginning of line and lose cruft';
like $htmltext, qr{org/</a>\.},                   'Cruft restored after link';
like $htmltext, qr{>http://link\.org</a>>\.},     'Angle brackets around links are left alone';
