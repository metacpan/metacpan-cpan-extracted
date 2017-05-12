use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Test::Script;
use Pod::Simple ();
use Pod::Text ();
use Pod::Xhtml ();
use File::Spec::Functions 'catfile';
diag('Pod::Parser version ' . $Pod::Parser::VERSION);
diag('Pod::Simple version ' . $Pod::Simple::VERSION);
diag('Pod::Text version '   . $Pod::Text::VERSION);
diag('Pod::Xhtml version '  . $Pod::Xhtml::VERSION);
use_ok('App::Grok');
use_ok('App::Grok::Parser::Pod5');
use_ok('App::Grok::Parser::Pod6');

SKIP: {
    skip "There's no blib", 1 unless -d "blib" and -f catfile qw(blib script grok);
    script_compiles(catfile('bin', 'grok'));
};
