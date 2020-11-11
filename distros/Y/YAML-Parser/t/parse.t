use v5.12;
use Test::More;

use YAML::Parser;
use YAML::PP::Perl;

use XXX;

my $parser = YAML::Parser->new;

my $yaml = <<'...';
---
foo: [1, 2]
bar: |
  this
   is
    good
...

my @events = $parser->parse($yaml)->events;

my $events = YAML::PP::Perl->new(boolean=>"boolean")->dump(\@events);

my $expected = <<'...';
---
- event: stream_start
- event: document_start
  explicit: true
  version: null
- event: mapping_start
  flow: false
- event: scalar
  style: plain
  value: foo
- event: sequence_start
  flow: true
- event: scalar
  style: plain
  value: '1'
- event: scalar
  style: plain
  value: '2'
- event: sequence_end
- event: scalar
  style: plain
  value: bar
- event: scalar
  style: literal
  value: |
    this
     is
      good
- event: mapping_end
- event: document_end
  explicit: false
- event: stream_end
...

is $events, $expected, "YAML::Parser returns proper events";

$parser = YAML::Parser->new(
  receiver => PerlYamlReferenceParserTestReceiver->new,
);

my $got = $parser->parse($yaml)->receiver->output;

my $want = <<'...';
+STR
+DOC ---
+MAP
=VAL :foo
+SEQ []
=VAL :1
=VAL :2
-SEQ
=VAL :bar
=VAL |this\n is\n  good\n
-MAP
-DOC
-STR
...

is $got, $want, "YAML::Parser returns proper test output";

done_testing;

# vim: sw=2:
