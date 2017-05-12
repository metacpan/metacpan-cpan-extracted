#!perl -T

use Test::More tests => 1;
use Text::GooglewikiFormat;

my $raw  = <<RAW;
=Heading1=
==Heading2==
===Heading3===

*bold*
_italic_
~~strike~~
^superscript^
,,subscript,,
`inline code`

Indent lists 2 spaces:
  * bullet item
  # numbered list

{{{
verbatim code block
}}}


WikiWordLink
[http://domain/page label]
http://domain/page

|| table || cells ||

 test quote
 test quote2

http://code.google.com/images/code_sm.png

|| *Year* || *Temperature (low)* || *Temperature (high)* ||
|| 1900 || -10 || 25 ||
|| 1910 || -15 || 30 ||
|| 1920 || -10 || 32 ||
|| 1930 || _N/A_ || _N/A_ ||
|| 1940 || -2 || 40 ||
RAW
my $html = Text::GooglewikiFormat::format($raw);
my $compare = <<HTML;
<h1>Heading1</h1><h2>Heading2</h2><h3>Heading3</h3><p> <strong>bold</strong> <br /> <i>italic</i> <br /> <span style="text-decoration: line-through">strike</span> <br /><sup>superscript</sup><br /><sub>subscript</sub><br /><tt>inline code</tt></p><p>Indent lists 2 spaces:</p><ul><li>bullet item </li></ul><ol><li>numbered list </li></ol><pre class="prettyprint">verbatim code block\n</pre><p><a href="WikiWordLink">WikiWordLink</a><br /><a href="http://domain/page" rel="nofollow">label</a><br /><a href="http://domain/page" rel="nofollow">http://domain/page</a></p><table><tr><td style="border: 1px solid #aaa; padding: 5px;"> table </td><td style="border: 1px solid #aaa; padding: 5px;"> cells </td></tr> </table><blockquote>test quote
test quote2
</blockquote><p><img src="http://code.google.com/images/code_sm.png" /> </p><table><tr><td style="border: 1px solid #aaa; padding: 5px;"> <strong>Year</strong> </td><td style="border: 1px solid #aaa; padding: 5px;"> <strong>Temperature (low)</strong> </td><td style="border: 1px solid #aaa; padding: 5px;"> <strong>Temperature (high)</strong> </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1900 </td><td style="border: 1px solid #aaa; padding: 5px;"> -10 </td><td style="border: 1px solid #aaa; padding: 5px;"> 25 </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1910 </td><td style="border: 1px solid #aaa; padding: 5px;"> -15 </td><td style="border: 1px solid #aaa; padding: 5px;"> 30 </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1920 </td><td style="border: 1px solid #aaa; padding: 5px;"> -10 </td><td style="border: 1px solid #aaa; padding: 5px;"> 32 </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1930 </td><td style="border: 1px solid #aaa; padding: 5px;"> <i>N/A</i> </td><td style="border: 1px solid #aaa; padding: 5px;"> <i>N/A</i> </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1940 </td><td style="border: 1px solid #aaa; padding: 5px;"> -2 </td><td style="border: 1px solid #aaa; padding: 5px;"> 40 </td></tr> </table>
HTML
chomp($compare);
is($html, $compare, 'works');
