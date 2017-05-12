#!/usr/bin/env perl
use strict;
use warnings;

use Text::Markdown;
use Text::Markdown::Discount;
use Text::Markdown::Hoedown;

use Benchmark qw(cmpthese);

my $markdown_text = <<'...';
[test]: http://google.com/ "Google"

# A heading

Just a note, I've found that I can't test my markdown parser vs others.
For example, both markdown.js and showdown code blocks in lists wrong. They're
also completely [inconsistent][test] with regards to paragraphs in list items.

A link. Not anymore.

<aside>This will make me fail the test because
markdown.js doesnt acknowledge arbitrary html blocks =/</aside>

* List Item 1

* List Item 2
  * New List Item 1
    Hi, this is a list item.
  * New List Item 2
    Another item
        Code goes here.
        Lots of it...
  * New List Item 3
    The last item

* List Item 3
The final item.

* List Item 4
The real final item.

Paragraph.
...

cmpthese(-5, {
    markdown => sub { Text::Markdown::markdown($markdown_text); },
    discount => sub { Text::Markdown::Discount::markdown($markdown_text); },
    hoedown  => sub { Text::Markdown::Hoedown::markdown($markdown_text); },
});
