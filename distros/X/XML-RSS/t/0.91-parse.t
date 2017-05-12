use strict;
use warnings;

use Test::More;

use constant RSS_VERSION       => "0.91";
use constant RSS_CHANNEL_TITLE => "Example 0.91 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0"?>
<rss version="0.91">
  <channel>
    <title>Example 0.91 Channel</title>
    <link>http://example.com</link>
    <description>To lead by example</description>
  </channel>
  <item>
     <title>News for September the Second</title>
     <link>http://example.com/2002/09/02</link>
     <description>other things happened today</description>
  </item>
  <item>
     <title>News for September the First</title>
     <link>http://example.com/2002/09/01</link>
     <description>something happened today</description>
  </item>
</rss>);

plan tests => 7;

use_ok("XML::RSS");

my $xml = XML::RSS->new();
isa_ok($xml,"XML::RSS");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

cmp_ok($xml->{'_internal'}->{'version'},
       "eq",
       RSS_VERSION,
       "Is RSS version ".RSS_VERSION);

cmp_ok($xml->{channel}->{'title'},
       "eq",
       RSS_CHANNEL_TITLE,
       "Feed title is ".RSS_CHANNEL_TITLE);

cmp_ok(ref($xml->{items}),
       "eq",
       "ARRAY",
       "\$xml->{items} is an ARRAY ref");

my $ok = 1;

foreach my $item (@{$xml->{items}}) {

  foreach my $el ("title","link","description") {
    if (! exists $item->{$el}) {
      $ok = 0;
      last;
    }
  }

  last if (! $ok);
}

ok($ok,"All items have title,link and description elements");

__END__

=head1 NAME

0.91-parse.t - tests for parsing RSS 0.91 data with XML::RSS.pm

=head1 SYNOPSIS

 use Test::Harness qw (runtests);
 runtests (./XML-RSS/t/*.t);

=head1 DESCRIPTION

Tests for parsing RSS 0.91 data with XML::RSS.pm

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2002/11/19 23:58:03 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://my.netscape.com/publish/formats/rss-spec-0.91.html

http://backend.userland.com/rss091

=cut
