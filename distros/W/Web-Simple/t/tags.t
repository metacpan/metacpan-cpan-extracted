use strict; use warnings FATAL => 'all';
use Test::More qw(no_plan);

my $globbery;
BEGIN { $globbery = join(', ', <t/globbery/o* t/globbery/t*>) }
{

  package Foo;

  sub foo {
    use XML::Tags qw(one two three);
    <one>, <two>, <three>;
  }

  sub bar {
    no warnings 'once'; # this is supposed to warn, it's broken
    <one>
  }

  sub baz {
    use XML::Tags qw(bar);
    </bar>;
  }

  sub quux {
    use HTML::Tags;
    <html>, <body id="spoon">, "YAY", </body>, </html>;
  }

  sub xquux {
    use HTML::Tags;
    <link href="#self" rel="me" />,
    <table>,<tr>,<td>,'x',<sub>,1,</sub>,</td>,</tr>,</table>;
  }

  sub fleem {
    use XML::Tags qw(woo);
    my $ent = 'one&two<three>"four';
    <woo ent="$ent">;
  }

  sub flaax {
    use XML::Tags qw(woo);
    my $data = "one&two<three>four";
    <woo>,  $data, </woo>,
    <woo>, \$data, </woo>;
  }

  sub HTML_comment {
    use HTML::Tags;
    <!-- this is a comment -->;
  }

  sub PI {
    use XML::Tags;
    <?xml version="1.0" encoding="UTF-8"?>;
  }

  sub DTD {
    use HTML::Tags;
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
  }

  sub globbery {
    <t/globbery/o* t/globbery/t*>;
  }
}

is(
  join(', ', XML::Tags::to_xml_string Foo::foo()),
  '<one>, <two>, <three>',
  'open tags ok'
);

ok(!eval { Foo::bar(); 1 }, 'Death on use of unimported tag');

is(
  join(', ', XML::Tags::to_xml_string Foo::baz()),
  '</bar>',
  'close tag ok'
);

is(
  join('', HTML::Tags::to_html_string Foo::quux),
  '<html><body id="spoon">YAY</body></html>',
  'HTML tags ok'
);

is(
  join('', HTML::Tags::to_html_string Foo::xquux),
  '<link href="#self" rel="me" />' .
  '<table><tr><td>x<sub>1</sub></td></tr></table>',
  'Conflicting HTML tags ok'
);

is(
  join('', XML::Tags::to_xml_string Foo::HTML_comment),
  '<!-- this is a comment -->',
  'HTML comment ok'
);

is(
  join('', XML::Tags::to_xml_string Foo::fleem),
  '<woo ent="one&amp;two&lt;three&gt;&quot;four">',
  'Escaping ok'
);

is(
  join('', XML::Tags::to_xml_string Foo::flaax),
  '<woo>one&amp;two&lt;three&gt;four</woo><woo>one&two<three>four</woo>',
  'Escaping user data ok'
);

is(
  join('', XML::Tags::to_xml_string Foo::PI),
  '<?xml version="1.0" encoding="UTF-8"?>',
  'XML processing instruction'
);

is(
  join('', HTML::Tags::to_html_string Foo::DTD),
  '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
  'DTD ok'
);

is(
  join(', ', Foo::globbery),
  $globbery,
  'real glob re-installed ok'
);
