#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Text::WikiFormat;

my $wikitext = <<'WIKI';

I download code from http://www.cpan.org/ or ftp://ftp.cpan.org/ and
email mailto:chromatic@example.com

WIKI

my $htmltext = Text::WikiFormat::format( $wikitext, {}, { extended => 1, absolute_links => 1 } );

is( $htmltext,
    qq|<p>I download code from <a href="http://www.cpan.org/">http://www.cpan.org/</a> | .
    qq|or <a href="ftp://ftp.cpan.org/">ftp://ftp.cpan.org/</a> and<br />| . "\n" .
    q|email <a href="mailto:chromatic@example.com">mailto:chromatic@example.com</a></p>| . "\n",
    'Picking up absolute links'
  );

$htmltext = Text::WikiFormat::format( $wikitext, {}, { extended => 1, absolute_links => 0 } );
is( $htmltext,
    q|<p>I download code from http://www.cpan.org/ or ftp://ftp.cpan.org/ and<br />| . "\n" .
    q|email mailto:chromatic@example.com</p>| . "\n",
    q|Doesn't pick up links when absolute_links is off|
  );    

$htmltext = Text::WikiFormat::format($wikitext, {}, { extended => 1, absolute_links => 1, nofollow_extended => 1 } );
like($htmltext, qr{<a href="http://www.cpan.org/" rel="nofollow">http://www.cpan.org/</a>});

$wikitext = "this is a moose:notalink";

$htmltext = Text::WikiFormat::format( $wikitext, {}, { extended => 1, absolute_links => 1 } );
is( $htmltext,
     qq|<p>this is a moose:notalink</p>\n|,
     q|Doesn't pick up things that might look like links|
   );

$htmltext = Text::WikiFormat::format( $wikitext, {schemas => ['moose']}, { extended => 1, absolute_links => 1 } );
is( $htmltext,
     qq|<p>this is a <a href="moose:notalink">moose:notalink</a></p>\n|,
     q|Schema tag allows specifying what is a link|
   );


$htmltext = Text::WikiFormat::format('http://example.com', {}, { extended => 1, absolute_links => 1 } );
like($htmltext, qr{^<p><a href="http://example.com">http://example.com</a></p>});
