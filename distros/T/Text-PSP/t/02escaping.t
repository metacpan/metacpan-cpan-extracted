use Test::More tests => 5;

BEGIN { use_ok 'Text::PSP' };

my $engine = Text::PSP->new('workdir' => 'tmp/work','template_root' => 't/templates');

my $t; 
ok ($t = $engine->template('/quotes.psp'),"parsing quotes.psp");

my @out = split(/\n/,join('',@{$t->run}));

is ($out[0] , "Text with some 'quotes' and \\backslashes\\","text quotes");
is ($out[1] , "Expression returning some 'quotes' and \\blackslashes\\","expression quotes");
is ($out[2] , "Parsetime code returning some 'quotes' and \\blackslashes\\","parsetime quotes");

