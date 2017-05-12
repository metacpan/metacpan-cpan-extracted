use Test::More tests => 15;

BEGIN { use_ok 'Text::PSP' };

my $engine = Text::PSP->new('workdir' => 'tmp/work','template_root' => 't/templates');

my $t; 
ok ($t = $engine->template('includes.psp'),"parsing includes.psp");

my @out = split(/\n/,join('',@{$t->run}));

is ($out[0],"Parsetime include","parsetime include");
is ($out[1],"Runtime include","runtime include");
is ($out[2],"Runtime include with arguments a b c","runtime include with arguments");

ok ($t = $engine->template('/directories.psp'),"parsing directories.psp");

@out = split(/\n+/,join('',@{$t->run}));

is ($out[0],"In t/templates","directory sanity check");
is ($out[1],"In t/templates/includes/inc2","to inc2");
is ($out[2],"In t/templates/includes","dir up");
is ($out[3],"In t/templates","back to template_dir");


ok ($t = $engine->template('directories_runtime.psp'),"parsing directories_runtime.psp");

@out = split(/\n+/,join('',@{$t->run}));

is ($out[0],"In t/templates","runtime sanity check");
is ($out[1],"In t/templates/includes/inc2","runtime inc2");
is ($out[2],"In t/templates/includes","runtime up");
is ($out[3],"In t/templates","runtime template_dir");


