#!perl -T

use Test::More tests => 14;
use Text::GooglewikiFormat;

my $raw  = '*bold* _italic_ ~~strike~~';
my $html = Text::GooglewikiFormat::format($raw);
is($html, '<p> <strong>bold</strong> <i>italic</i> <span style="text-decoration: line-through">strike</span> </p>', '*bold* _italic_ ~~strike~~ works');

$raw  = 'a*bold*a i_italic_i s~~strike~~s';
$html = Text::GooglewikiFormat::format($raw);
is($html, '<p>a*bold*a i_italic_i s~~strike~~s</p>', 'a*bold*a i_italic_i s~~strike~~s works');

$raw  = '^superscript^ ,,subscript,, `inline code`';
$html = Text::GooglewikiFormat::format($raw);
is($html, '<p><sup>superscript</sup> <sub>subscript</sub> <tt>inline code</tt></p>', '^superscript^ works');

$raw  = '=Heading1=';
$html = Text::GooglewikiFormat::format($raw);
is($html, '<h1>Heading1</h1>', '=Heading1= works');

$raw  = '==Heading2==';
$html = Text::GooglewikiFormat::format($raw);
is($html, '<h2>Heading2</h2>', '==Heading2== works');

$raw  = '===Heading3===';
$html = Text::GooglewikiFormat::format($raw);
is($html, '<h3>Heading3</h3>', '===Heading3=== works');

$raw  = <<RAW;

Indent lists 2 spaces:
  * bullet item
  # numbered list

RAW
$html = Text::GooglewikiFormat::format($raw);
is($html, '<p>Indent lists 2 spaces:</p><ul><li>bullet item </li></ul><ol><li>numbered list </li></ol>', 'Indent lists 2 spaces works');

$raw  = <<RAW;
 quote la
 quote2 la
RAW
$html = Text::GooglewikiFormat::format($raw);
is($html, '<blockquote>quote la
quote2 la
</blockquote>', 'blockquote works');

$raw  = <<RAW;

WikiWordLink
[http://domain/page label]
http://domain/page2

RAW
$html = Text::GooglewikiFormat::format($raw);
like($html, qr/\<a href\=\"http\:\/\/domain\/page\" rel\=\"nofollow\"\>label\<\/a\>/, 'link works');
like($html, qr/\<a href\=\"http\:\/\/domain\/page2\" rel\=\"nofollow\"\>http\:\/\/domain\/page2\<\/a\>/, 'links 2 works');

$raw  = <<RAW;
http://code.google.com/images/code_sm.png
RAW
$html = Text::GooglewikiFormat::format($raw);
is($html, '<p><img src="http://code.google.com/images/code_sm.png" /> </p>', 'http://code.google.com/images/code_sm.png works');

$raw  = <<RAW;
|| *Year* || *Temperature (low)* || *Temperature (high)* ||
|| 1900 || -10 || 25 ||
|| 1910 || -15 || 30 ||
|| 1920 || -10 || 32 ||
|| 1930 || _N/A_ || _N/A_ ||
|| 1940 || -2 || 40 ||
RAW
$html = Text::GooglewikiFormat::format($raw);
is($html, q~<table><tr><td style="border: 1px solid #aaa; padding: 5px;"> <strong>Year</strong> </td><td style="border: 1px solid #aaa; padding: 5px;"> <strong>Temperature (low)</strong> </td><td style="border: 1px solid #aaa; padding: 5px;"> <strong>Temperature (high)</strong> </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1900 </td><td style="border: 1px solid #aaa; padding: 5px;"> -10 </td><td style="border: 1px solid #aaa; padding: 5px;"> 25 </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1910 </td><td style="border: 1px solid #aaa; padding: 5px;"> -15 </td><td style="border: 1px solid #aaa; padding: 5px;"> 30 </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1920 </td><td style="border: 1px solid #aaa; padding: 5px;"> -10 </td><td style="border: 1px solid #aaa; padding: 5px;"> 32 </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1930 </td><td style="border: 1px solid #aaa; padding: 5px;"> <i>N/A</i> </td><td style="border: 1px solid #aaa; padding: 5px;"> <i>N/A</i> </td></tr> <tr><td style="border: 1px solid #aaa; padding: 5px;"> 1940 </td><td style="border: 1px solid #aaa; padding: 5px;"> -2 </td><td style="border: 1px solid #aaa; padding: 5px;"> 40 </td></tr> </table>~, 'table works');

$raw  = <<RAW;
{{{
verbatim code block
next line
}}}
RAW
$html = Text::GooglewikiFormat::format($raw);
is($html, qq~<pre class="prettyprint">verbatim code block\nnext line\n</pre>~, 'code block works');

$raw  = <<RAW;
{{{
*verbatim code block*
}}}
RAW
$html = Text::GooglewikiFormat::format($raw);
is($html, qq~<pre class="prettyprint">*verbatim code block*\n</pre>~, 'code block works');