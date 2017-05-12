use strict;
use warnings;

use Test::More tests => 6;
use XML::Stream qw( Node );

my @tests;
$tests[4] = 1;

my $stream = XML::Stream->new( #debug=>"stdout",debuglevel=>99,
style=>"node");

$stream->SetCallBacks(node=>sub{ &onPacket(@_) });

my $sid = $stream->OpenFile("t/test.xml");
while( my %status = $stream->Process()) {
  last if ($status{$sid} == -1);
}

foreach (2..6) {
  ok $tests[$_];
}

sub onPacket {
  my $sid = shift;
  my ($packet) = @_;

  return unless $packet->get_attrib("test");

  if ($packet->get_attrib("test") eq "2") {
    $tests[2] = 1;
  }

  if ($packet->get_attrib("test") eq "3") {
    if (($packet->children())[1]->get_tag() eq "bar") {
      $tests[3] = 1;
    }
  }
  if ($packet->get_attrib("test") eq "4") {
    $tests[4] = 0;
  }
  if ($packet->get_attrib("test") eq "5") {
    if (((($packet->children())[1]->children())[1]->children())[1]->get_cdata() eq "This is a test.") {
      $tests[5] = 1;
    }
  }
  if ($packet->get_attrib("test") eq "6") {
    if ($packet->get_cdata() eq "This is cdata with <tags/> embedded <in>it</in>.") {
      $tests[6] = 1;
    }
  }
}

my $node = XML::Stream::Node->new("test","<foo/>");

is ($node->GetXML(),  "<test>&lt;foo/&gt;</test>");

