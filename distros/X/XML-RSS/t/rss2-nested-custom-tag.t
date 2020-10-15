#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use XML::RSS ();

{
    my $rss = XML::RSS->new();

    $rss->parse(<<'EOT');

<rss version="2.0">
  <channel>
    <item>
      <title>random title</title>
      <link>http://correct.url/</link>
      <description>some text</description>

      <random_custom_tag>
        <link>random text that's in a tag named link for whatever reason</link>
      </random_custom_tag>
    </item>
  </channel>
</rss>

EOT

    # TEST
    is($rss->{items}->[0]->{link}, 'http://correct.url/', 'item link parsed correctly');
}

__END__

=head1 ABOUT

See L<https://github.com/shlomif/perl-XML-RSS/issues/7>. Thanks to
L<https://github.com/jkramer> .
