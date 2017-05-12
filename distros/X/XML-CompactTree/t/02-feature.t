
use Test::More tests => 2 + 4*13 + 4*20 + 4*13;
use strict;
use warnings;
BEGIN {
use_ok( 'XML::CompactTree' );
use_ok( 'XML::LibXML::Reader' );
import XML::CompactTree;
}

my $xml = <<EOF;
<foo bar="baz" 
     xmlns:f="http://foo.bar.baz"
     xmlns="http://a.bar.baz">
   <bar x="y">a<baz/>b</bar>
   <f:x/>
</foo>
EOF

print "block 1\n";

for my $flags (
  XCT_IGNORE_SIGNIFICANT_WS,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_KEEP_NS_DECLS,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_ATTRIBUTE_ARRAY,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_ATTRIBUTE_ARRAY | XCT_KEEP_NS_DECLS,
) {
  print "flags: $flags\n";
  my $reader;
  my %ns;
  ok( $reader = XML::LibXML::Reader->new(string => $xml), "reader ok");
  isa_ok($reader,"XML::LibXML::Reader");
  is( $reader->nextElement, 1, "first element ok");
  my $result;
  ok( $result = XML::CompactTree::readSubtreeToPerl($reader,$flags,\%ns), "result ok" );
  #use Data::Dumper;
  #print Dumper($result,\%ns);

  isa_ok( $result, 'ARRAY', "result not an array" );
  is( $result->[0], XML_READER_TYPE_ELEMENT, "node type" );
  is( $result->[1], 'foo', "node name" );
  my ($foo_ns,$a_ns);
  ok( ($a_ns = $ns{'http://a.bar.baz'}), "namespace 1 found" );
  is( $result->[2], $a_ns, "node namespace ok" );
  if ($flags & XCT_ATTRIBUTE_ARRAY) {
    ok( ref($result->[3]) eq 'ARRAY', "attributes are an array" );
    my %a = @{$result->[3]};
    ok( $a{bar} eq "baz", "attributes ok" );
  } else {
    ok( ref($result->[3]) eq 'HASH', "attributes are a hash" );
    ok( $result->[3]->{bar} eq "baz", "attributes ok" );
  }
  use Data::Dumper;
  print Dumper($result);
  ok( (ref($result->[4]) eq 'ARRAY' and @{$result->[4]} == 2), "children ok" );
  ok( ($foo_ns = $ns{'http://foo.bar.baz'}), "namespace 2 found" );
}

print "block 2\n";
for my $flags (
  XCT_IGNORE_SIGNIFICANT_WS,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_KEEP_NS_DECLS,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_ATTRIBUTE_ARRAY,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_ATTRIBUTE_ARRAY | XCT_KEEP_NS_DECLS,
) {
  print "flags: $flags\n";
  my $reader;
  my %ns;
  ok( $reader = XML::LibXML::Reader->new(string => $xml), "reader ok");
  $reader->nextElement('bar');
  isa_ok($reader,"XML::LibXML::Reader");

  my $result;
  ok( $result = XML::CompactTree::readLevelToPerl($reader,$flags,\%ns), "result ok" );
  isa_ok( $result, 'ARRAY', "result not an array" );
  is( scalar(@$result), 2, "number of results ok" );
  test_bar($result->[0],$flags,\%ns);
  test_x($result->[1],$flags,\%ns);
  #use Data::Dumper;
  #print Dumper($result,\%ns);
}

print "block 3\n";
for my $flags (
  XCT_IGNORE_SIGNIFICANT_WS,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_KEEP_NS_DECLS,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_ATTRIBUTE_ARRAY,
  XCT_IGNORE_SIGNIFICANT_WS | XCT_ATTRIBUTE_ARRAY | XCT_KEEP_NS_DECLS| XCT_LINE_NUMBERS,
) {
  print "flags: $flags\n";
  my $reader;
  my %ns;
  ok( $reader = XML::LibXML::Reader->new(string => $xml), "reader ok");
  $reader->nextElement('bar');
  isa_ok($reader,"XML::LibXML::Reader");

  my $result;
  ok( $result = XML::CompactTree::readSubtreeToPerl($reader,$flags,\%ns), "result ok" );
  test_bar($result,$flags,\%ns);
  ok( !exists($ns{'http://foo.bar.baz'}), "no other namespace" );
  #use Data::Dumper;
  #print Dumper($result,\%ns);
}

sub test_bar {
  my ($result,$flags,$ns)=@_;
  is( $result->[0], XML_READER_TYPE_ELEMENT, "node type" );
  is( $result->[1], 'bar', "node name" );
  my ($a_ns);
  ok( ($a_ns = $ns->{'http://a.bar.baz'}), "namespace 1 found" );
  is( $result->[2], $a_ns, "node namespace ok" );
  if ($flags & XCT_ATTRIBUTE_ARRAY) {
    ok( ref($result->[3]) eq 'ARRAY', "attributes are an array" );
    my %a = @{$result->[3]};
    ok( $a{x} eq "y", "attributes ok" );
  } else {
    ok( ref($result->[3]) eq 'HASH', "attributes are a hash" );
    ok( $result->[3]->{x} eq "y", "attributes ok" );
  }
  my $children_offset = 4 + ($flags & XCT_LINE_NUMBERS ? 1 : 0);
  isa_ok( $result->[$children_offset], 'ARRAY', "children ok");
  is(scalar @{$result->[$children_offset]},3, "children count ok" );
  my $line_no;
  if ($flags & XCT_LINE_NUMBERS) {
    $line_no = $result->[$children_offset][1][4]; # no way to be sure what XML::LibXML will give here
  }
  is_deeply($result->[$children_offset],
	    [ [ XML_READER_TYPE_TEXT, 'a' ],
	      [ XML_READER_TYPE_ELEMENT, 'baz', $ns->{'http://a.bar.baz'}, undef, (($flags & XCT_LINE_NUMBERS) ? $line_no : ()) ],
	      [ XML_READER_TYPE_TEXT, 'b' ],
            ],
	    "structure ok"
          );
}

sub test_x {
  my ($result,$flags,$ns)=@_;
  is( $result->[0], XML_READER_TYPE_ELEMENT, "node type" );
  is( $result->[1], 'x', "node name" );
  my ($foo_ns);
  ok( ($foo_ns = $ns->{'http://foo.bar.baz'}), "namespace 2 found" );
  is( $result->[2], $foo_ns, "node namespace ok" );
  ok( !defined($result->[3]), "no attributes");
  my $children_offset = 4 + ($flags & XCT_LINE_NUMBERS ? 1 : 0);
  ok( !exists($result->[$children_offset]), "no children");
}
