use Test::More tests => 5;
use_ok("Text::Original");

# The bizarre love affair with Andrew Josey related email continues.
my $text = <<EOF;
On Fri, May 09, 2003 at 08:54:17AM +0100, Andrew Josey wrote:

> There was some discussion over the future of WG15, and the desire
> for the ISO representation to continue - most probably by some appointee
> from the SC22 level where the work will be transferred.

What are the perceived problems? Is WG15 about to be disbanded?
I think the main WG15 group is quite inactive but we are active e.g in the
Austin group.

best regards
Keld

EOF

is(first_lines($text),
"What are the perceived problems? Is WG15 about to be disbanded?",
"First line");
is(first_lines($text,2),
"What are the perceived problems? Is WG15 about to be disbanded?
I think the main WG15 group is quite inactive but we are active e.g in the",
"First and second line");
is(first_sentence($text),
"What are the perceived problems?",
"First sentence");
is(first_paragraph($text)."\n",<<EOF, "First paragraph");
What are the perceived problems? Is WG15 about to be disbanded?
I think the main WG15 group is quite inactive but we are active e.g in the
Austin group.
EOF
