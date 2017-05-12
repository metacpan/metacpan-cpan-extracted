use Test::More tests => 4;
use_ok "Text::Context::Porter";

# Unit tests for the Ruby port
my $s = Text::Context::Porter->new("This is a test\n\nAnd   so is this.\n\nbut this has testing more words than the others", "word", "tested");

isa_ok($s, "Text::Context::Porter");
is($s->as_text, "but this has testing more words than the others", 
"Simple test passed");
is($s->as_html, 'but this has <span class="quoted">testing</span> more <span class="quoted">words</span> than the others',
"HTML test passed");
