use Test::More tests => 6;

BEGIN { use_ok 'Text::PSP';  };

my $engine = Text::PSP->new('workdir' => 'tmp/work','template_root' => 't/templates');

$engine->clear_workdir;

my $t; 
ok ($t = $engine->template('/simple_template.psp'),"parsing simple template");

my $out = join("\n",split(/\n/,join('',@{$t->run})));

is ($out, "Hello, World

I am a template of class Text::PSP::Generated::t::templates::simple_template_psp

I can even run a method!","output");

is ($engine->normalize_path("/"),"/","path translation: root");

is ($engine->normalize_path("/a/b/c/../d"),"/a/b/d","path translation: parent");
is ($engine->normalize_path("a/b/c/../d"),"a/b/d","path translation: parent2");

