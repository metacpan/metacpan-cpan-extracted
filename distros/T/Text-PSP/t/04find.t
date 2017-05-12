use Test::More tests => 6;
use strict;
use warnings;
BEGIN { use_ok 'Text::PSP' };

my $engine = Text::PSP->new('workdir' => 'tmp/work','template_root' => 't/templates');

my $t; 
ok ($t = $engine->template('includes/inc2/find.psp'),"parsing includes/inc/find.psp");

my @out = split(/\n+/,join('',@{$t->run}));

ok($out[0] =~ /^Hello world - template/,"find file template output");


ok ($t = $engine->template('includes/inc2/rec_find.psp'),"parsing includes/inc/rec_find.psp");

@out = split(/\n+/,join('',@{$t->run}));

is($out[0],"In t/templates/includes" ,"recursive find file template output");

ok ($t = $engine->find_template('includes/inc2/helloworld.psp'),"find_template");

