# -*- cperl -*-

use Test::More tests => 27;

BEGIN {
  use_ok( 'XML::DT' );
}

# normalize_space
is(XML::DT::_normalize_space("  teste  "), "teste");
is(XML::DT::_normalize_space("\tteste\t"), "teste");
is(XML::DT::_normalize_space("\tteste  "), "teste");

is(XML::DT::_normalize_space(" spaces   in   \t the middle\t"),
   "spaces in the middle");

# toxml as function
is(toxml("a",{},""), "<a/>");

is(tohtml("a",{},""), "<a></a>");
is(tohtml("br",{},""), "<br>");
is(tohtml("hr",{},""), "<hr>");
is(tohtml("link",{type=>"bar"},""), "<link type=\"bar\">");
is(tohtml("img",{src=>"foo"},""), "<img src=\"foo\">");

is(toxml("a",{},"c"), "<a>c</a>");
is(tohtml("a",{},"c"), "<a>c</a>");

is(toxml("a",{a=>1},"c"), "<a a=\"1\">c</a>");
is(tohtml("a",{a=>1},"c"), "<a a=\"1\">c</a>");

is(toxml({ -q => "html",
           -c => { -q => "head",
                   -c => { -q => "title",
                           -c => "Titulo da pagina" }}}),
   "<html><head><title>Titulo da pagina</title></head></html>");
is(tohtml({ -q => "html",
           -c => { -q => "head",
                   -c => { -q => "title",
                           -c => "Titulo da pagina" }}}),
   "<html><head><title>Titulo da pagina</title></head></html>");

is(toxml({ -q => "html",
           -c => { -q => "head",
                   -c => []
		 }
	 }),   "<html><head/></html>");
is(tohtml({ -q => "html",
	           -c => { -q => "head",
	                   -c => []
			 }
		 }),   "<html><head></head></html>");


is(toxml({ -q => "html",
           -c => { -q => "head",
                   -c => [ { -q => "title",
                             -c => "Titulo da pagina" },
			   { -q => "title",
                             -c => "Titulo da pagina" }]}}),
   "<html><head><title>Titulo da pagina</title>\n<title>Titulo da pagina</title></head></html>");
is(tohtml({ -q => "html",
           -c => { -q => "head",
                   -c => [ { -q => "title",
                             -c => "Titulo da pagina" },
			   { -q => "title",
                             -c => "Titulo da pagina" }]}}),
   "<html><head><title>Titulo da pagina</title>\n<title>Titulo da pagina</title></head></html>");


is(toxml({ -q => "html",
           -c => [ { -q => "head",
                     -c => [ { -q => "title",
                               -c => "Titulo da pagina" },
			     { -q => "title",
                               -c => "Titulo da pagina" }]},
		   { -q => "head",
                     -c => [ { -q => "title",
                               -c => "Titulo da pagina" },
			     { -q => "title",
                               -c => "Titulo da pagina" }]}]}),
   "<html><head><title>Titulo da pagina</title>\n<title>Titulo da pagina</title></head>\n<head><title>Titulo da pagina</title>\n<title>Titulo da pagina</title></head></html>");
is(tohtml({ -q => "html",
           -c => [ { -q => "head",
                     -c => [ { -q => "title",
                               -c => "Titulo da pagina" },
			     { -q => "title",
                               -c => "Titulo da pagina" }]},
		   { -q => "head",
                     -c => [ { -q => "title",
                               -c => "Titulo da pagina" },
			     { -q => "title",
                               -c => "Titulo da pagina" }]}]}),
   "<html><head><title>Titulo da pagina</title>\n<title>Titulo da pagina</title></head>\n<head><title>Titulo da pagina</title>\n<title>Titulo da pagina</title></head></html>");


# this is one of the most important tests for MathML
is(toxml("foo",{},"0"), "<foo>0</foo>");

# toxml with variables
$q = "a";
$c = "b";
%v = ();
is(toxml, "<a>b</a>");

$v{foo} = "bar";
is(toxml, "<a foo=\"bar\">b</a>");

$c = '0';
is(toxml, "<a foo=\"bar\">0</a>");
