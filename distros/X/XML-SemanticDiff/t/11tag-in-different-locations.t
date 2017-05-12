use strict;
use warnings;

use Test::More tests => 1;

use XML::SemanticDiff;

my $orig = <<'EOF';
<LocalPresentationManifest xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Properties>
    <Description>This presentation is a brief overview of the MediaLandscape Product and Service Offerings.</Description>
    <TimeZone>
      <Identifier>19</Identifier>
      <Name>Central Time</Name>
      <Description>(GMT-06:00) Central Time (US &amp; Canada)</Description>
      <Abbreviation>CST</Abbreviation>
    </TimeZone>
  </Properties>
</LocalPresentationManifest>
EOF

my $derived = <<'EOF';
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<LocalPresentationManifest>
  <Properties>
    <TimeZone>
      <Description>(GMT-06:00) Central Time (US &amp; Canada)</Description>
      <Abbreviation>CST</Abbreviation>
      <Identifier>19</Identifier>
      <Name>Central Time</Name>
    </TimeZone>
    <Description>This presentation is a brief overview of the MediaLandscape Product and Service Offerings.</Description>
  </Properties>
</LocalPresentationManifest>
EOF

my $diff = XML::SemanticDiff->new();

my @results = $diff->compare($orig, $derived);

# TEST
is_deeply (
    \@results,
    [],
    "Making sure two XMLs with variation of tag locations are considered identical - per bug #18491"
);
