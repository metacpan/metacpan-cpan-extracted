use Test2::V0;
use Test2::Require::AuthorTesting;

use File::Spec;
use File::Temp qw( tempdir );

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $guide_html_bin = File::Spec->catfile( $repo_root, 'extras', 'zuzu-guide-html' );

ok -f $guide_html_bin, 'extras/zuzu-guide-html exists';

my $tmp_input = tempdir( CLEANUP => 1 );
my $tmp_output = tempdir( CLEANUP => 1 );
my $chapter_file = File::Spec->catfile( $tmp_input, '07-test.md' );
my $output_file = File::Spec->catfile( $tmp_output, '07-test.html' );

open my $chapter_fh, '>:encoding(UTF-8)', $chapter_file
	or die "Could not write '$chapter_file': $!\n";
print {$chapter_fh} <<'MARKDOWN';
# Chapter 7: Nested list check

1. **Readable first**
   You should be able to return to a script in six months and still
   understand what sleepy-past-you meant.

- Any
	- Null
	- Object
		- Collection

| Operator | Precedence |
| --- | --- |
| `*` | higher |
| `+` | lower |

Raw HTML should pass through: <br> and <i>Hello</i>.

Inline code must escape HTML: `<these angled brackets should be escaped>`.

```zuzu
let markup = "<still escaped in fenced code>";
```
MARKDOWN
close $chapter_fh;

my $cmd = "$^X $guide_html_bin --input-dir $tmp_input --output-dir $tmp_output 2>&1";
my $output = qx{$cmd};
my $exit = $? >> 8;
is $exit, 0, 'zuzu-guide-html exits successfully';
like $output, qr/Wrote \Q$output_file\E/, 'zuzu-guide-html writes the expected file';

open my $html_fh, '<:encoding(UTF-8)', $output_file
	or die "Could not read '$output_file': $!\n";
local $/;
my $html = <$html_fh>;
close $html_fh;

like $html, qr{<li>Any\s*<ul>\s*<li>Null\s*</li>\s*<li>Object\s*<ul>\s*<li>Collection\s*</li>\s*</ul>\s*</li>\s*</ul>\s*</li>}s,
	'Nested markdown lists render as nested HTML lists';
like $html, qr{<ol>\s*<li><strong>Readable first</strong>\s+You should be able to return to a script in six months and still\s+understand what sleepy-past-you meant\.\s*</li>\s*</ol>}s,
	'Ordered markdown list items include continuation lines inside the list item';
like $html, qr{<table>\s*<thead>\s*<tr>\s*<th>Operator</th>\s*<th>Precedence</th>\s*</tr>\s*</thead>\s*<tbody>\s*<tr>\s*<td><code>\*</code></td>\s*<td>higher</td>\s*</tr>\s*<tr>\s*<td><code>\+</code></td>\s*<td>lower</td>\s*</tr>\s*</tbody>\s*</table>}s,
	'Markdown tables render as HTML tables';

like $html, qr{Raw HTML should pass through:\s*<br>\s*and\s*<i>Hello</i>\.}s,
	'Raw HTML in markdown paragraphs is emitted without escaping';
like $html, qr{Inline code must escape HTML:\s*<code>&lt;these angled brackets should be escaped&gt;</code>\.}s,
	'Inline code escapes embedded HTML angle brackets';
like $html, qr{<pre class="zuzu-highlight">let markup = "&lt;still escaped in fenced code&gt;";\s*</pre>}s,
	'Fenced code blocks escape embedded HTML angle brackets';

done_testing;
