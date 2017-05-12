use strict;
use Test::More;

use constant RSS_VERSION       => "2.0";
use constant RSS_CHANNEL_TITLE => "Example 2.0 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xml:base="http://foo.com/">
 <channel>
  <title>Example 2.0 Channel</title>
  <link>http://example.com/</link>
  <description>To lead by example</description>
  <language>en-us</language>
  <copyright>All content Public Domain, except comments which remains copyright the author</copyright> 
  <managingEditor>editor\@example.com</managingEditor> 
  <webMaster>webmaster\@example.com</webMaster>
  <docs>http://backend.userland.com/rss</docs>
  <category  domain="http://www.dmoz.org">Reference/Libraries/Library_and_Information_Science/Technical_Services/Cataloguing/Metadata/RDF/Applications/RSS/</category>
  <generator>The Superest Dooperest RSS Generator</generator>
  <lastBuildDate>Mon, 02 Sep 2002 03:19:17 GMT</lastBuildDate>
  <ttl>60</ttl>

  <item>
   <title>News for September the Second</title>
   <link>http://example.com/2002/09/02</link>
   <description>other things happened today</description>
   <comments>http://example.com/2002/09/02/comments.html</comments>
   <author>joeuser\@example.com</author>
   <pubDate>Mon, 02 Sep 2002 03:19:00 GMT</pubDate>
   <guid isPermaLink="true">http://example.com/2002/09/02</guid>
  </item>

  <item>
   <title>News for September the First</title>
   <link>http://example.com/2002/09/01</link>
   <description>something happened today</description>
   <comments>http://example.com/2002/09/01/comments.html</comments>
   <author>joeuser\@example.com</author>
   <pubDate>Sun, 01 Sep 2002 12:01:00 GMT</pubDate>
   <guid isPermaLink="true">http://example.com/2002/09/02</guid>
  </item>

 </channel>
</rss>);

plan tests => 10;

use_ok("XML::RSS::LibXML");

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

cmp_ok($xml->{'_internal'}->{'version'},"eq",RSS_VERSION,"Is RSS version ".RSS_VERSION);
cmp_ok($xml->{channel}->{'title'},"eq",RSS_CHANNEL_TITLE,"Feed title is ".RSS_CHANNEL_TITLE);
cmp_ok(ref($xml->{items}),"eq","ARRAY","\$xml->{items} is an ARRAY ref");
cmp_ok($xml->version, 'eq', RSS_VERSION, 'Version attribute should be set');
cmp_ok($xml->encoding, 'eq', 'utf-8', 'Encoding should be set');
cmp_ok($xml->base, 'eq', 'http://foo.com/', 'Base attribute should be set');

my $ok = 1;

foreach my $item (@{$xml->{items}}) {

  my $min = 0;
  foreach my $el ("title","description") {
    if (exists $item->{$el}) {
      $min ||= 1;
    }
  }

  $ok = $min;
  last if (! $ok);
}

ok($ok,"All items have either a title or a description element");


__END__

=head1 NAME

2.0-parse.t - tests for parsing RSS 2.0 data with XML::RSS::LibXML.pm

=head1 SYNOPSIS

 use Test::Harness qw (runtests);
 runtests (./XML-RSS/t/*.t);

=head1 DESCRIPTION

Tests for parsing RSS 2.0 data with XML::RSS::LibXML.pm

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2002/11/19 23:56:53 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://backend.userland.com/rss2

=cut
