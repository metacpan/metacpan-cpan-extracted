use warnings;
use strict;
use Test::More;

plan tests => 2;

use Text::MiniTmpl;

our $TMPL_PKG;


package _qwe;
use Text::MiniTmpl qw( render );
Text::MiniTmpl::render('t/tmpl/include_caller.txt');
Test::More::is $::TMPL_PKG, '_qwe',     'render include_caller from _qwe';

package _asd;
use Text::MiniTmpl qw( render );
Text::MiniTmpl::render('t/tmpl/include_caller_2.txt');
Test::More::is $::TMPL_PKG, '_asd',     'render include_caller_2 from _asd';


