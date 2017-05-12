use t::TestWikiText;

plan tests => 23;

#no_diff;

$t::TestWikiText::parser_module = 'WikiText::Socialtext::Parser';
$t::TestWikiText::emitter_module = 'WikiText::WikiByte::Emitter';

filters({wikitext => 'parse_wikitext'});

run_is 'wikitext' => 'wikibyte';

__DATA__
=== Old lists

--- wikitext
- one
- two
--- wikibyte
+ul
+li
 one
-li
+li
 two
-li
-ul

=== Headers Without Spaces

--- wikitext
^^Welcome to the Workspace

blah blah
--- wikibyte
+h2
 Welcome to the Workspace
-h2
+p
 blah blah
-p

=== Multiline Paragraphs

--- wikitext
this is a multiline blob of
text that should be in a
single paragraph

but this should be alone

--- wikibyte
+p
 this is a multiline blob of
 text that should be in a
 single paragraph
-p
+p
 but this should be alone
-p

=== H1 and Bold
--- wikitext
^ Hello

We are *Devo*.

--- wikibyte
+h1
 Hello
-h1
+p
 We are 
+b
 Devo
-b
 .
-p

=== H4 and Bold
--- wikitext
^^^^ Goodbye

We are not *Devo*.

--- wikibyte
+h4
 Goodbye
-h4
+p
 We are not 
+b
 Devo
-b
 .
-p

=== Strikeout and Monospace
--- wikitext
this is -strikeout- text, and `monospace` text.

--- wikibyte
+p
 this is 
+del
 strikeout
-del
  text, and 
+tt
 monospace
-tt
  text.
-p

=== Table Test 1
--- wikitext
|table|value|
| *one*|1|
|two|2|

Some text.

--- wikibyte
+table
+tr
+td
 table
-td
+td
 value
-td
-tr
+tr
+td
+b
 one
-b
-td
+td
 1
-td
-tr
+tr
+td
 two
-td
+td
 2
-td
-tr
-table
+p
 Some text.
-p

=== Unordered and Ordered Lists
--- wikitext
* one
** two a
** two b
* two
## -ol one-
## ol two
--- wikibyte
+ul
+li
 one
+ul
+li
 two a
-li
+li
 two b
-li
-ul
-li
+li
 two
+ol
+li
+del
 ol one
-del
-li
+li
 ol two
-li
-ol
-li
-ul

=== Italics and Indented
--- wikitext
> This is _italic_ indented text
> that has more indents

--- wikibyte
+blockquote
+p
 This is 
+i
 italic
-i
  indented text
 that has more indents
-p
-blockquote

=== Links and Named Links
--- wikitext
[Link to a page]
"other page"[Second link]

--- wikibyte
+p
+wikilink target="Link to a page"
 Link to a page
-wikilink
 
 
+wikilink target="Second link"
 other page
-wikilink
-p

=== pre text
--- wikitext
.pre
no *bold* here
.pre
but *bold* here

--- wikibyte
+pre
 no *bold* here
 
-pre
+p
 but 
+b
 bold
-b
  here
-p

=== WAFL Paragraph
--- wikitext
{foo: bar}

some text
--- wikibyte
=waflparagraph function="foo" options="bar"
+p
 some text
-p

=== Horizonal Rule
--- wikitext
line

----

goes here

--- wikibyte
+p
 line
-p
=hr
+p
 goes here
-p

=== Indents
--- wikitext
> 1a
>> 2a
>> 2b
>>> 3a
> 1b

--- wikibyte
+blockquote
+p
 1a
-p
+blockquote
+p
 2a
 2b
-p
+blockquote
+p
 3a
-p
-blockquote
-blockquote
+p
 1b
-p
-blockquote

=== HTTP Links
--- wikitext
I love the http://example.com site

I love the "Example"<http://example.com> site

I love the https://example.com site
--- wikibyte
+p
 I love the 
+hyperlink target="http://example.com"
 http://example.com
-hyperlink
  site
-p
+p
 I love the 
+hyperlink target="http://example.com"
 Example
-hyperlink
  site
-p
+p
 I love the 
+hyperlink target="https://example.com"
 https://example.com
-hyperlink
  site
-p

=== Asis Phrases
--- wikitext
This is {{ *not bold*}}. This is two right curlies: {{}}}} and two left: {{{{}}.

--- wikibyte
+p
 This is  *not bold*. This is two right curlies: }} and two left: {{.
-p

=== WAFL Phrase
--- wikitext
This is a "renamed"{wafly: with options} yo.

--- wikibyte
+p
 This is a 
+waflphrase function="wafly" options="with options"
 renamed
-waflphrase
  yo.
-p

=== IM Phrases
--- wikitext
* Ingy - aim:ingydotnet

--- wikibyte
+ul
+li
 Ingy - 
=im id="ingydotnet" type="aim"
-li
-ul

=== Email addresses
--- wikitext
My address is foo.bar@baz.quux but email me at <mailto:lala@dooda.blah>.

Otherwise email "Charlie"<charles@bukow.ski>.

--- wikibyte
+p
 My address is 
+mail address="foo.bar@baz.quux"
 foo.bar@baz.quux
-mail
  but email me at 
+mail address="lala@dooda.blah"
 lala@dooda.blah
-mail
 .
-p
+p
 Otherwise email 
+mail address="charles@bukow.ski"
 Charlie
-mail
 .
-p

=== Empty Lines
--- wikitext -trim


^ Hello

--- wikibyte
+h1
 Hello
-h1

=== Nested Phrases
--- wikitext
This is both *_Bold and Italic_*

--- wikibyte
+p
 This is both 
+b
+i
 Bold and Italic
-i
-b
-p

=== Bad Markup
--- wikitext
| *foo* | bar

baz
--- wikibyte
+p
 | *foo* | bar
-p
+p
 baz
-p

=== Phrases in Headers
--- wikitext
^^ The `foo()` method

--- wikibyte
+h2
 The 
+tt
 foo()
-tt
  method
-h2

