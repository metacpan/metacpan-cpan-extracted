use strict;
use warnings;
use Test::More tests => 6;

open( API, 'lib/XML/API.pm' ) || die "open: $!";

my @lines;
while ( my $line = <API> ) {
    next unless ( $line =~ m/^\s+use XML::API/ );
    push( @lines, $line );
    while ( my $line = <API> ) {
        last if ( $line !~ m/^\s/ );
        next if ( $line =~ m/^\s+print/ );
        push( @lines, $line );
    }
    last;
}
push( @lines, '$x;' );

my $res = eval "@lines";

ok( !$@, 'Eval ' . ( $@ ? $@ : '' ) );

isa_ok( $res, 'XML::API::XHTML' );

is(
    "$res", '<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<!-- My - -First- - XML::API document -->
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Test Page</title>
  </head>
  <body>
    <div id="content">
      <p class="test">Some &lt;&lt;odd&gt;&gt; input</p>
      <ns:p class="test">&amp; some other &stuff;</ns:p>
    </div>
  </body>
</html>', 'document ok'
);

open( RSS, 'lib/XML/API/RSS.pm' ) || die "open: $!";

@lines = ();

while ( my $line = <RSS> ) {
    next unless ( $line =~ m/^\s+use XML::API/ );
    push( @lines, $line );
    while ( my $line = <RSS> ) {
        last if ( $line !~ m/^\s/ );
        next if ( $line =~ m/^\s+print/ );
        push( @lines, $line );
    }
    last;
}
push( @lines, '$x;' );

$res = eval "@lines";

ok( !$@, 'Eval ' . ( $@ ? $@ : '' ) );

isa_ok( $res, 'XML::API::RSS' );

is(
    "$res", '<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
  <channel>
    <title>Liftoff News</title>
    <link>http://liftoff.msfc.nasa.gov/</link>
    <description>Liftoff to Space Exploration.</description>
    <language>en-us</language>
    <pubDate>Tue, 10 Jun 2003 04:00:00 GMT</pubDate>
    <lastBuildDate>Tue, 10 Jun 2003 09:41:01 GMT</lastBuildDate>
    <docs>http://blogs.law.harvard.edu/tech/rss</docs>
    <generator>Weblog Editor 2.0</generator>
    <managingEditor>editor@example.com</managingEditor>
    <webMaster>webmaster@example.com</webMaster>
    <item>
      <title>Star City</title>
      <link>http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp</link>
      <description>A description of sorts.</description>
      <pubDate>Tue, 03 Jun 2003 09:39:21 GMT</pubDate>
      <guid>http://liftoff.msfc.nasa.gov/2003/06/03.html#item573</guid>
    </item>
  </channel>
</rss>', 'document ok'
);
