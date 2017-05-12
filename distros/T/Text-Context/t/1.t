use Test::More tests => 15;
use_ok "Text::Context";

# Unit tests for the Ruby port
my $s = Text::Context->new("This is a test\n\nAnd   so is this.\n\nbut this has more words than the others", "TeSt",
"ThiS", "more  words");

isa_ok($s, "Text::Context");
is_deeply([$s->keywords], ["test", "this", "more words"], 
    "Keywords downcase properly");

$s->prepare_text;
my @things = @{$s->{text_a}};
is @things, 3, "Proper number of paras";
for (@things) { isa_ok $_, "Text::Context::Para" }
is $things[0]->as_text, "This is a test", "Text maintained OK";

for (@things) { $s->score_para($_) }
is $things[0]->{final_score}, 8, "Score is OK (first para)";
is_deeply [$things[0]->best_keywords], ["test", "this"], "Keywords OK";
is $things[-1]->{final_score}, 16, "Score is OK (last para)";

$s->get_appropriate_paras;
my @paras = @{$s->{app_paras}};
is(@paras,2, "We selected two paragraphs");
is_deeply([map{$_->{order}}@paras],[0,2],"We selected the correct paras");
is($paras[0]->marked_up, 'This is a <span class="quoted">test</span>',
"Can mark self up");

$s = Text::Context->new("This is a test\n\nAnd   so is this.\n\nbut this has more words than the others", "TeSt",
"ThiS", "more  words");
is($s->as_text, "This is a test ... but this has more words than the others", 
"Simple test passed");
