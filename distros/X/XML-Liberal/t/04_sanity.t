use strict;
use Test::Base;
use XML::Liberal;

sub scrub {
    XML::Liberal->new('LibXML')->parse_string($_[0])->toString();
}

filters { input => 'scrub' };
run_is 'input' => 'expected';

__END__

=== Good XML
--- input
<?xml version="1.0"?>
<foo />
--- expected
<?xml version="1.0"?>
<foo/>

=== Good XML
--- input
<?xml version="1.0"?>
<foo bar="1" />
--- expected
<?xml version="1.0"?>
<foo bar="1"/>

=== Good XML
--- input
<?xml version="1.0"?>
<foo><bar /></foo>
--- expected
<?xml version="1.0"?>
<foo><bar/></foo>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo>&</foo>
--- expected
<?xml version="1.0"?>
<foo>&amp;</foo>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo>&nbsp;</foo>
--- expected
<?xml version="1.0"?>
<foo>&#xA0;</foo>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo bar=baz />
--- expected
<?xml version="1.0"?>
<foo bar="baz"/>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo:bar>xxx</foo:bar>
--- expected
<?xml version="1.0"?>
<foo:bar xmlns:foo="http://example.org/unknown/foo#">xxx</foo:bar>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo:bar />
--- expected
<?xml version="1.0"?>
<foo:bar xmlns:foo="http://example.org/unknown/foo#"/>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo>&foo</foo>
--- expected
<?xml version="1.0"?>
<foo>&amp;foo</foo>

=== Good XML
--- input
<?xml version="1.0"?>
<foo>&#200;</foo>
--- expected
<?xml version="1.0"?>
<foo>&#xC8;</foo>

=== Good XML
--- input
<?xml version="1.0"?>
<foo>&#xC8;</foo>
--- expected
<?xml version="1.0"?>
<foo>&#xC8;</foo>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo>&#xC8;&#20;</foo>
--- expected
<?xml version="1.0"?>
<foo>&#xC8;</foo>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo nofoo />
--- expected
<?xml version="1.0"?>
<foo nofoo="nofoo"/>

=== Bad XML
--- input
<?xml version="1.0"?>
<foo><img></foo>
--- expected
<?xml version="1.0"?>
<foo><img/></foo>

=== Bad XML
--- input
<?xml version="1.0"?>
<content:encoded>foo</content:encoded>
--- expected
<?xml version="1.0"?>
<content:encoded xmlns:content="http://purl.org/rss/1.0/modules/content/">foo</content:encoded>

=== Good XML
--- input
<?xml version="1.0"?>
<foo>あいうえお</foo>
--- expected
<?xml version="1.0"?>
<foo>&#x3042;&#x3044;&#x3046;&#x3048;&#x304A;</foo>

=== Newline
--- input
<?xml version="1.0"?>
<foo>foo
bar</foo>
--- expected
<?xml version="1.0"?>
<foo>foo
bar</foo>

=== Newline
--- input
<?xml version="1.0"?>
<foo>foo&#x00;&#x0a;bar</foo>
--- expected
<?xml version="1.0"?>
<foo>foo
bar</foo>
