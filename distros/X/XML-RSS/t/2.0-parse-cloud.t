use strict;
use warnings;

# Should be 11.
use Test::More tests => 11;

use XML::RSS;

use constant RSS_VERSION       => "2.0";
use constant RSS_CHANNEL_TITLE => "Example 2.0 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0"?>
<rss version="2.0">
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
  <cloud domain="rpc.rsscloud.org" port="5337" path="/rsscloud/pleaseNotify" registerProcedure="" protocol="http-post" />

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

my $xml = XML::RSS->new();
# TEST
isa_ok($xml,"XML::RSS");

eval { $xml->parse(RSS_DOCUMENT); };
# TEST
is($@,'',"Parsed RSS feed");

# TEST
is($xml->{channel}{cloud}{domain}, 'rpc.rsscloud.org');

# TEST
is($xml->{channel}{cloud}{port}, '5337');

# TEST
is($xml->{channel}{cloud}{path}, '/rsscloud/pleaseNotify');

# TEST
is($xml->{channel}{cloud}{registerProcedure}, '');

# TEST
is($xml->{channel}{cloud}{protocol}, 'http-post');


# TEST
cmp_ok($xml->{'_internal'}->{'version'},"eq",RSS_VERSION,"Is RSS version ".RSS_VERSION);

# TEST
cmp_ok($xml->{channel}->{'title'},"eq",RSS_CHANNEL_TITLE,"Feed title is ".RSS_CHANNEL_TITLE);

# TEST
cmp_ok(ref($xml->{items}),"eq","ARRAY","\$xml->{items} is an ARRAY ref");

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

# TEST
ok($ok,"All items have either a title or a description element");

__END__

=head1 NAME

2.0-parse-cloud.t - parse rssCloud:
https://rt.cpan.org/Ticket/Display.html?id=67241

=head1 SYNOPSIS

 use Test::Harness qw (runtests);
 runtests (./XML-RSS/t/*.t);

=head1 DESCRIPTION

Tests for parsing RSS 2.0 with rssCloud with XML-RSS.

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2002/11/19 23:56:53 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://backend.userland.com/rss2

=cut
