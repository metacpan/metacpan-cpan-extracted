#!/usr/bin/perl

use warnings;
use strict;

# -------------------------------------------------
# Here we fake connecting to the Net and getting
# back an RSS file. Thanks to Mark Fowler for this.

package LWP::Simple;

use vars qw(@EXPORT $RSS);
use base qw(Exporter);
@EXPORT = qw(get);

$RSS = qq{<?xml version="1.0" ?>

<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN" 
  "http://my.netscape.com/publish/formats/rss-0.91.dtd"> 

<rss version="0.91">
  <channel>
    <title>Example</title>
    <link>http://example.com/</link>
    <item>
      <title>Example item 1</title>
      <link>http://example.com/1.html</link>
      <description>The first example.</description>                            
    </item>
    <item>
      <title>Example item 2</title>
      <link>http://example.com/2.html</link>
      <description>The second example.</description>                           
    </item>
    <item>
      <title>Example item 3</title>
      <link>http://example.com/3.html</link>
      <description>The third example.</description>                            
    </item>
  </channel>
</rss>};

sub get
{
  return $RSS;
}

$INC{"LWP/Simple.pm"} = 1;

# -------------------------------------------------

package main;

use Test::More tests => 9;

# Create a temporary file, fill it with the RSS we defined
# earlier in the fake LWP::Simple.

use File::Temp;
# Use OO version of File::Temp; file will be unlinked when $tmp goes
# out of scope
my $tmp = new File::Temp;
my $rss_file = $tmp->filename;
print $tmp $LWP::Simple::RSS;
close $tmp;

#1
use_ok("Wiki::Toolkit::Plugin::RSS::Reader");

my $rss = Wiki::Toolkit::Plugin::RSS::Reader->new(
  file => $rss_file,
);

#2
isa_ok($rss, "Wiki::Toolkit::Plugin");

my @items = $rss->retrieve;

#3
is($items[0]{title}, 'Example item 1', 'Got local title');

#4
is($items[0]{link}, 'http://example.com/1.html', 'Got local link');

#5                                                                             
is($items[0]{description}, 'The first example.', 'Got local description');     
 
$rss = Wiki::Toolkit::Plugin::RSS::Reader->new(
  url => 'http://example.com/example.rss',
);

@items = $rss->retrieve;

#6
is($items[0]{title}, 'Example item 1', 'Got remote title');

#7
is($items[0]{link}, 'http://example.com/1.html', 'Got remote link');

#8                                                                             
is($items[0]{description}, 'The first example.', 'Got remote description');

my $died;

eval {
  local $SIG{__DIE__} = sub { $died = 1; };

  # Illegal usage.
  $rss = Wiki::Toolkit::Plugin::RSS::Reader->new(
    url  => 'http://example.com/example.rss',
    file => $rss_file,
  );
};

#9
is($died, 1, 'Caught illegal config options');

