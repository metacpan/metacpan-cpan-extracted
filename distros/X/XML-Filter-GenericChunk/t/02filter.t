use Test;
BEGIN { plan tests => 11 }
END { ok(0) unless $loaded }

use XML::LibXML;
use XML::LibXML::SAX;
use XML::LibXML::SAX::Builder;

use XML::Filter::CharacterChunk;
$loaded = 1;

ok($loaded);

sub init_parser {
	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter    = XML::Filter::CharacterChunk->new(Handler=>$handler);
	my $generator = XML::LibXML::SAX->new(Handler=>$filter);
	return ($generator, $filter, $handler);
}



my $string = "<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>";
my $tstr   = "<foo/>foo<foo>bar</foo>";
my $value  = "foobar";


sub test_simple_string {
	my $string = "<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>";
	my $value  = "foobar";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( "a" );
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();

	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}
	if ( $root->string_value() ne $value ) {
		print "#  bad result\n";
		return 0;
	}
	return 1;
}

ok(test_simple_string());

sub test01_simple_string_using_ns {
	my $string = "<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>";
	my $value  = "foobar";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( "a" );
	$filter->set_namespace( "foo" );
	
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();
	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() ne $string ) {
		print "#  character chunk parsed while it should not\n";
		return 0;
	}

	return 1;
}

ok(test01_simple_string_using_ns());


sub test02_simple_string_using_ns {
	my $string = '<a><x:a xmlns:x="foo">&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</x:a></a>';	
	my $value  = "foobar";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( "a" );
	$filter->set_namespace( "foo" );
	
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();
	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	( $root ) = $dom->findnodes("/a/*[local-name() = 'a']");
	unless ( defined $root ) {
		print "#  no nodes found\n";
		return 0;
	}
	if ( $root->string_value() ne $value ) {
		print "#  character chunk parsed while it should not\n";
		return 0;
	}

	return 1;
}

ok(test02_simple_string_using_ns());


sub test_simple_string_relaxed_names {
	my $string1 = "<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>";
	my $string2 = '<a><x:a xmlns:x="foo">&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</x:a></a>';	
	my $value  = "foobar";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( "a" );
	$filter->set_namespace( "foo" );
	$filter->relaxed_names(1);

	my $dom = $generator->parse_string( $string2 );
	my $root = $dom->documentElement();
	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}
	if ( $root->toString() eq $string2 ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	( $root ) = $dom->findnodes("/a/*[local-name() = 'a']");
	if ( $root->string_value() ne $value ) {
		print "#  character chunk parsed while it should not\n";
		return 0;
	}

        $dom = $generator->parse_string( $string1 );
	$root = $dom->documentElement();
	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string1 ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	if ( $root->string_value() ne $value ) {
		print "#  character chunk parsed while it should not\n";
		return 0;
	}

	return 1;
}

ok(test_simple_string_relaxed_names());

sub test01_complex_string {
	my $string = q{
<bar>
<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>
<c>&lt;foo/&gt;bar&lt;foo&gt;foo&lt;/foo&gt;</c>
</bar>
};
	my $value  = "foobar";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( "a" );
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();

	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	my ($a, $b);
	( $a ) = $dom->findnodes( "//a" );
	( $b ) = $dom->findnodes( "//c" );
	if ( $a->string_value ne $value ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	if ( $b->string_value ne "<foo/>bar<foo>foo</foo>" ) {
		print "#  element parsed where it shouldn't\n";
		return 0;
	}
	
	return 1;
}

ok(test01_complex_string());

sub test02_complex_string {
	my $string = q{
<bar>
<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>
<c>&lt;foo/&gt;bar&lt;foo&gt;foo&lt;/foo&gt;</c>
</bar>
};
	my $valuea  = "foobar";
	my $valueb  = "barfoo";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( qw( a c ) );
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();

	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	my ($a, $b);
	( $a ) = $dom->findnodes( "//a" );
	( $b ) = $dom->findnodes( "//c" );
	if ( $a->string_value ne $valuea ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	if ( $b->string_value ne $valueb ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	return 1;
}

ok(test02_complex_string());

sub test03_complex_string {
	my $string = q{
<bar>
<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>
<a>&lt;foo/&gt;bar&lt;foo&gt;foo&lt;/foo&gt;</a>
</bar>
};
	my $valuea  = "foobar";
	my $valueb  = "barfoo";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( qw( a c ) );
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();

	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	my ($a, $b);
	( $a, $b ) = $dom->findnodes( "//a" );
	if ( $a->string_value ne $valuea ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	if ( $b->string_value ne $valueb ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	return 1;
}

ok(test03_complex_string());

sub test04_complex_string {
	my $string = q{
<bar><a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>&lt;foo/&gt;</bar>
};
	my $valuea  = "foobar";
	my $valueb  = "<foo/>";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( qw( a c ) );
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();

	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	my $a = $root->firstChild();
	my $b = $root->lastChild();
	if ( $a->string_value ne $valuea ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	if ( $b->string_value ne $valueb ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	return 1;
}

ok(test04_complex_string());

sub test05_complex_string {
	my $string = q{
<bar><a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a><c>&lt;foo/&gt;</c></bar>
};
	my $valuea  = "foobar";
	my $valueb  = "<foo/>";

	my ($generator, $filter, $handler) = init_parser();

	$filter->set_tagname( qw( a ) );
	my $dom = $generator->parse_string( $string );
	my $root = $dom->documentElement();

	unless ( defined $root ) {
		print "#  no document root found\n";
		return 0;
	}

	if ( $root->toString() eq $string ) {
		print "#  character chunk not parsed\n";
		return 0;
	}

	my ($a, $b);
	$a = $root->firstChild;
	$b = $root->lastChild;
	if ( $a->string_value ne $valuea ) {
		print "#  element not parsed\n";
		return 0;
	}
	
	unless ( $b->string_value eq $valueb ) {
		print "#  element not parsed (".$b->toString().")\n";
		return 0;
	}
	
	return 1;
}

ok(test05_complex_string());

sub test_iso_encoded_content {
	my $encoding  = "ISO-8859-1";
	my $value     = "bärföo";
	my $cdata     = "<foo/>bär<foo>föo</foo>";

	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter    = XML::Filter::CharacterChunk->new(
						Encoding=> $encoding,
						TagName => ["a"],
						Handler => $handler
							);

	$filter->start_document();
	$filter->start_element({Name=>"a", LocalName=>"a", Prefix=>""});
	$filter->characters( {Data=>$cdata} );
	$filter->end_element({Name=>"a", LocalName=>"a", Prefix=>""});
	$dom = $filter->end_document();

	unless ( defined $dom ) {
		print "#  parser error, filter did not create a document\n";
		return 0;
	}

	if ( defined $dom->encoding() and $dom->encoding() ne "UTF8" ) {
		print "#  document has not the expected encoding (". $dom->encoding() .")\n";
		return 0;
	}

	my $root = $dom->documentElement();
	unless ( defined $root ) {
		print "#  document has no document element\n";
		return 0;
	}	
	
	unless ( $root->nodeName() eq "a" ) {
		print "#  document element has a bad name \n";
		return 0;
	}

	unless ( defined $root->firstChild() and 
	         $root->firstChild->nodeName() eq "foo" ) {
		print "#  some parser error ocured\n";
		return 0;
	}
	
	unless ( $root->string_value() eq encodeToUTF8("ISO-8859-1",$value) ) {
		print "#  some encoding error ocured\n";
		return 0;
	}
	
	return 1;
}

ok(test_iso_encoded_content());
