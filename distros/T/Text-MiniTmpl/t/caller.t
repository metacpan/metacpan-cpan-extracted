use warnings;
use strict;
use Test::More;

plan tests => 9;

use Text::MiniTmpl;

our $TMPL_PKG;


Text::MiniTmpl::render('t/tmpl/caller.txt');
Test::More::is $::TMPL_PKG, 'main',     'render from main';

package _qwe;
Text::MiniTmpl::render('t/tmpl/caller.txt');
Test::More::is $::TMPL_PKG, '_qwe',     'render from _qwe';

package _asd;
Text::MiniTmpl::render('t/tmpl/caller.txt');
Test::More::is $::TMPL_PKG, '_asd',     'render from _asd';

package main;
Text::MiniTmpl::tmpl2code('t/tmpl/caller.txt')->();
Test::More::is $::TMPL_PKG, 'main',     'tmpl2code from main';

package _qwe;
Text::MiniTmpl::tmpl2code('t/tmpl/caller.txt')->();
Test::More::is $::TMPL_PKG, '_qwe',     'tmpl2code from _qwe';

package _asd;
Text::MiniTmpl::tmpl2code('t/tmpl/caller.txt')->();
Test::More::is $::TMPL_PKG, '_asd',     'tmpl2code from _asd';

package main;
use Text::MiniTmpl qw( render );
Text::MiniTmpl::render('t/tmpl/include_caller.txt');
Test::More::is $::TMPL_PKG, 'main',     'render include from main';

package _qwe;
use Text::MiniTmpl qw( render );
Text::MiniTmpl::render('t/tmpl/include_caller.txt');
Test::More::is $::TMPL_PKG, '_qwe',     'render include from _qwe';

package _asd;
use Text::MiniTmpl qw( render );
Text::MiniTmpl::render('t/tmpl/include_caller.txt');
Test::More::is $::TMPL_PKG, '_asd',     'render include from _asd';


