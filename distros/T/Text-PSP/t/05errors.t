use Test::More tests => 9;
use strict;
use warnings;
BEGIN { use_ok 'Text::PSP' };

my $engine = Text::PSP->new('workdir' => 'tmp/work','template_root' => 't/templates');

my $t = eval { $engine->template("error.psp") };
ok ($@,"Exceptions on compile error");
ok ($@ =~ /\.\n$/,"Dot at end");
ok ($@ =~ /line 4\.\n$/,"Line number");
ok (index($@,"t/templates/error.psp") > -1,"Full path");
$t = $engine->template("runtime-error.psp");
ok (!eval {
    $t->run();
},"Runtime exceptions");
ok ($@ =~ /\.\n$/,"Dot at end");
ok ($@ =~ /line 4\.\n$/,"Line number");
ok (index($@,"t/templates/runtime-error.psp") > -1,"Full path");



    
