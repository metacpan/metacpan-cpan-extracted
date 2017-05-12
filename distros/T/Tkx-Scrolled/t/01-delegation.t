#!perl -T
use strict;
use warnings;
use Test::More tests => 7;
use Tkx;
use Tkx::Scrolled;

my $mw = Tkx::widget->new('.');
my $w  = $mw->new_tkx_Scrolled('text',
	-width  => 5,
	-height => 5,
	-wrap   => 'none',
);
$w->g_pack();

$mw->g_wm_withdraw();  # hide the mainwindow

ok($w, 'new');
is($w->g_winfo_class, 'Tkx_Scrolled', 'class');

my $text = "The quick brown fox jumped over the lazy dog.\n";

$w->insert('end', $text) for 1 .. 10;

is($w->get('1.0', '2.0'), $text, 'insert/get delegated to text widget');

$w->_kid('xscrollbar')->set(0, 1);
$w->_kid('yscrollbar')->set(0, 1);

is($w->_kid('xscrollbar')->get(), '0 1', 'xscrollbar before moveto');
is($w->_kid('yscrollbar')->get(), '0 1', 'yscrollbar before moveto');

$w->xview('moveto', 0.1);
$w->yview('moveto', 0.5);

Tkx::update();  # make the moveto effective

# I don't think that we can robustly predict exactly what get() will return,
# so settle for something other than the initial values.
isnt($w->_kid('xscrollbar')->get(), '0 1', 'xscrollbar after moveto');
isnt($w->_kid('yscrollbar')->get(), '0 1', 'yscrollbar after moveto');
