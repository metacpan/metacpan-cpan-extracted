use 5.010;
use JSON;
use XML::LibXML::Debugging;

my $dom    = XML::LibXML->new->parse_string(<<XML);
<html xmlns="http://www.w3.org/1999/xhtml"
	xmlns:dc="http://purl.org/dc/terms/"
	xml:lang="en">
	<head>
		<title>Test</title>
	</head>
	<body dc:title="Test">
		<h1>Test</h1>
		<p>Just a test!</p>
	</body>
</html>
XML

say "========";
say $dom->toClarkML;
say "--------";
say to_json($dom->toDebuggingHash, {pretty=>1, canonical=>1});
say "========";
