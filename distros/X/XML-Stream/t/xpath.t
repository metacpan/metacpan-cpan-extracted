use strict;
use warnings;

use Test::More tests=>105;

BEGIN{ use_ok("XML::Stream","Node","Tree"); }

my @value;

foreach my $type ("tree","node")
{
    my $parser = XML::Stream::Parser->new(style=>$type);
    isa_ok($parser,"XML::Stream::Parser");
    my $node = $parser->parsefile("t/test.xml");

    isa_ok($node,"ARRAY") if ($type eq "tree");
    isa_ok($node,"XML::Stream::Node") if ($type eq "node");

    
    @value = &XML::Stream::XPath($node,'last/@test');
    is( $#value, 0, "'last/\@test' - Only one match?");
    is( $value[0], 5, "correct value?");

    
    @value = &XML::Stream::XPath($node,'last/test1/test2/test3/text()');
    is( $#value, 0, "'last/test1/test2/test3/text()' - Only one match?");
    is( $value[0], "This is a test.", "correct value?");

    
    @value = &XML::Stream::XPath($node,'last/test1/test2/test3');
    is( $#value, 0, "'last/test1/test2/test3' - Only one match?");
    is( &XML::Stream::GetXMLData("value",$value[0]), "This is a test.", "correct value?");

    
    my %value = &XML::Stream::XPath($node,'foo/@*');
    is( scalar(keys(%value)), 1, "'foo/\@\*' - Only one attribute?");
    is( $value{test}, 3, "correct value?");


    @value = &XML::Stream::XPath($node,'last//test3');
    is( $#value, 0, "'last//test3' - Only one match?");
    is( &XML::Stream::GetXMLData("value",$value[0]), "This is a test.", "correct value?");
    

    @value = &XML::Stream::XPath($node,'a//e');
    is( $#value, 2, "'a//e' - Only three matches?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[0],"e"), "foo1", "correct value?");
    is( &XML::Stream::GetXMLData("tag",$value[1]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[1]), "foo1", "correct value?");
    is( &XML::Stream::GetXMLData("tag",$value[2]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[2]), "foo2", "correct value?");
    
    
    @value = &XML::Stream::XPath($node,'//e');
    is( $#value, 3, "'//e' - Only four matches?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[0],"e"), "foo1", "correct value?");
    is( &XML::Stream::GetXMLData("tag",$value[1]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[1]), "foo1", "correct value?");
    is( &XML::Stream::GetXMLData("tag",$value[2]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[2]), "foo2", "correct value?");
    is( &XML::Stream::GetXMLData("tag",$value[3]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[3]), "bar", "correct value?");
   

    @value = &XML::Stream::XPath($node,'a/b//d/e');
    is( $#value, 1, "'a/b//d/e' - Only two matches?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[0],"e"), "foo1", "correct value?");
    is( &XML::Stream::GetXMLData("tag",$value[1]), "e", "is it <e/>?");
    is( &XML::Stream::GetXMLData("value",$value[1]), "foo2", "correct value?");
    

    @value = &XML::Stream::XPath($node,'library//chapter//para/@test');
    is( $#value, 1, "'library//chapter//para/\@test' - Only two matches?");
    is( $value[0], "b", "correct value?");
    is( $value[1], "a", "correct value?");


    @value = &XML::Stream::XPath($node,'filter[@id and @mytest="2"]/text()');
    is( $#value, 0, "'filter[\@id and \@mytest=\"2\"]/text()' - Only one match?");
    is( $value[0], "valueA", "correct value?");


    @value = &XML::Stream::XPath($node,'newfilter[@bar and sub="foo1"]');
    is( $#value, 0, "'newfilter[\@bar and sub=\"foo1\"]' - Only one match?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "newfilter", "is it <newfilter/>?");
    is( &XML::Stream::GetXMLData("value",$value[0],"sub"), "foo1", "correct value?");
    
    
    @value = &XML::Stream::XPath($node,'startest/*[@test]');
    is( $#value, 1, "'startest/*[\@test]' - Only two matches?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "foo", "is the first one <foo/>?");
    is( &XML::Stream::GetXMLData("tag",$value[1]), "bing", "is the second one <bing/>?");

    
    @value = &XML::Stream::XPath($node,'startest/*[not(@test)]');
    is( $#value, 0, "'startest/*[not(\@test)]' - Only one matches?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "bar", "is it <bar/>?");

    @value = &XML::Stream::XPath($node,'startest/*[name() != "foo"]');
    is( $#value, 1, "'startest/*[name() != \"foo\"]' - Only two matches?");
    is( &XML::Stream::GetXMLData("tag",$value[0]), "bar", "is it <bar/>?");
    is( &XML::Stream::GetXMLData("tag",$value[1]), "bing", "is it <bing/>?");

    @value = &XML::Stream::XPath($node,'//e[starts-with(text(),"foo")]');
    is( $#value, 1, "'//e[starts-with(text(),\"foo\")]' - Only two matches?");
    is( &XML::Stream::GetXMLData("value",$value[0]), "foo1", "correct value?");
    is( &XML::Stream::GetXMLData("value",$value[1]), "foo2", "correct value?");

}

