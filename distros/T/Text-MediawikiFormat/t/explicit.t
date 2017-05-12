#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 13;
use Test::NoWarnings;
use Test::Warn;

use Text::MediawikiFormat as => 'wf', process_html => 0;

my $wikitext = <<WIKI;

[Ordinary extended link]

[http://nowhere.com explicit URI]

[[Usemod extended link]]

WIKI

my $htmltext = wf($wikitext);
like $htmltext, qr!'Ordinary'>extended link</a>!m, 'extended links rendered correctly with default delimiters';
like $htmltext, qr!'http://nowhere\.com'>explicit URI</a>!m, 'explicit URIs rendered correctly with default delimiters';
like $htmltext, qr!Usemod%20extended%20link'>Usemod extended link</a>!m,
	'Wiki URIs rendered correctly with default delimiters';

# Redefine the delimiters to the same thing again.
my %tags = ( extended_link_delimiters => qr/(\[(?:\[[^][]*\]|[^][]*)\])/, );

$htmltext = wf( $wikitext, \%tags );
like $htmltext, qr!'Ordinary'>extended link</a>!m, 'extended links rendered correctly with default delimiters';
like $htmltext, qr!'http://nowhere\.com'>explicit URI</a>!m, 'explicit URIs rendered correctly with default delimiters';
like $htmltext, qr!Usemod%20extended%20link'>Usemod extended link</a>!m,
	'Wiki URIs rendered correctly with default delimiters';

# Redefine the delimiters to something different.
%tags = ( extended_link_delimiters => [qw([ ])], );

$htmltext = wf( $wikitext, \%tags );

unlike $htmltext, qr!'Ordinary'>extended link</a>!m,           'extended links ignored with overridden delimiters';
unlike $htmltext, qr!'http://nowhere\.com'>explicit URI</a>!m, 'explicit URIs ignored with overridden delimiters';
like $htmltext,   qr!Usemod extended link</a>[^\]]!m,          '...and new delimiters recognised';

# Make sure we handle empty delimiters
%tags = ( extended_link_delimiters => '', );

$htmltext = wf( $wikitext, \%tags );

#warning_like {$htmltext = wf ($wikitext, \%tags)}
#	     {carped => [map {qr/^Ignoring/} (1..3)]},
#	     "warn of empty extended_link_delimiters";

unlike $htmltext, qr!'Ordinary'>extended link</a>!m,           'extended links ignored with empty delimiters';
unlike $htmltext, qr!'http://nowhere\.com'>explicit URI</a>!m, 'explicit URIs ignored with empty delimiters';
unlike $htmltext, qr!Usemod extended link</a>[^\]]!m,          'Wiki URIs ignored with empty delimiters';
