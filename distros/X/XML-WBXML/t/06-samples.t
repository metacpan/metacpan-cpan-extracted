use strict;
use warnings;

use Test::More;
my @samples;
BEGIN {
    eval "require Test::XML";
    plan skip_all => "Test::XML required for this test" if $@;

    @samples = <t/samples/*.xml>;
    plan tests => 2+ 3*(scalar @samples);
    Test::XML->import;

    use_ok 'XML::WBXML';
    use_ok 'XML::SemanticDiff::BasicHandler';
    {
	no warnings 'redefine';
	*XML::SemanticDiff::BasicHandler::namespace_uri = sub {};
    }
} 

my %base64_oops = (
    "t/samples/drmrel-002.xml" => 1,
    "t/samples/drmrel-003.xml" => 1,
);

# libwbxml2 turns off string table support for WV:
# /* Wireless-Village CSP 1.1 / 1.2: content can be tokenized, so we mustn't
#    interfere with String Table stuff */
# but these files require it
my %wv_strtable_broken = (
    "t/samples/wv-040.xml" => 1,
    "t/samples/wv-047.xml" => 1,
    "t/samples/wv-061.xml" => 1,
    "t/samples/wv-078.xml" => 1,
);

# The TODO logic is complex.  Basically, there are a few conditions that should
# cause the *third test only* to be TODO (ie, it should convert both ways but
# just not compare right), and also a condition that makes them all TODO...

for my $sample_file (@samples) {
    TODO: {
	my $todo;
	local $TODO;

	open my $fh, '<', $sample_file or die "can't open $sample_file: $!";
	my $xml = do { local $/; <$fh> };

	$todo = "$sample_file: known that doesn't convert to wbxml" if $wv_strtable_broken{$sample_file};
	$TODO = $todo if $todo;

	my $wbxml = XML::WBXML::xml_to_wbxml($xml);
	ok(defined $wbxml, "$sample_file converted successfully to wbxml");
	my $xml_roundtrip = XML::WBXML::wbxml_to_xml($wbxml || '');
	# The && here makes it fail if $wbxml was undefined, but lets
	# $xml_roundtrip be defined so that the is_xml later doesn't crash.
	ok(defined $wbxml && defined $xml_roundtrip, "$sample_file converted successfully back to xml");

	$todo = "$sample_file: inconsistent =-termination in base64" if $base64_oops{$sample_file};
	$todo = "$sample_file: ota doesn't appear to work" if $sample_file =~ m{t/samples/ota-\d+\.xml};
	$todo = "$sample_file: there is a bug involving 0x12345 turning into 0" if $xml =~ /0x23829381/;

	$TODO = $todo if defined $todo;

	is_xml($xml_roundtrip, $xml, "sample $sample_file roundtrips successfully");
    }
} 
