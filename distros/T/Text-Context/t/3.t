#!/usr/bin/perl 
use Text::Context;
use Test::More 'no_plan';

# We want to test snippeting of things which should be marked up as HTML
# entities.
my $s = Text::Context->new('<html> find <me> s&z </html>', "me", "s&z");

my $output = '&lt;html&gt; find &lt;<span class="quoted">me</span>&gt; <span class="quoted">s&amp;z</span> &lt;/html&gt;';

is($s->as_html, $output, "entities are handled correctly");
