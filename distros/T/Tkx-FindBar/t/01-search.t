use strict;
use warnings;
use Tkx;
use Tkx::FindBar;
use Test::More tests => 16;

my $mw      = Tkx::widget->new('.');
my $text1   = $mw->new_text(-wrap => 'word', -height => 5);
my $text2   = $mw->new_text(-wrap => 'word', -height => 5);
my $findbar = $mw->new_tkx_FindBar();

$text1->g_pack();
$findbar->g_pack(-anchor => 'w');
$text2->g_pack();

$text1->insert('end', <<EOT);
Now is the time for all good men to come to the aid of their country.
EOT

$text2->insert('end', <<EOT);
The quick brown fox jumped over the lazy dog.
EOT

$findbar->configure(-textwidget => $text1);
$findbar->configure(-highlightcolor => 'red');

is($findbar->cget(-textwidget), $text1, 'configure/cget for -textwidget');
is($findbar->cget(-highlightcolor), 'red', 'configure/cget for -highlightcolor');


# Why can't I generate key events and have them show up in the entry, trigger
# FAYT, etc.? Grr...
#Tkx::event('generate', $mw, '<Key-t>');
#Tkx::event('generate', $mw, '<Key-h>');
# Screw it. Forceful hacks follow
$findbar->_data->{what} = 'th';

$findbar->first();
is($text2->tag('ranges', 'highlight'), '',        'text widget 2 not searched');
is($text1->tag('ranges', 'highlight'), '1.7 1.9', 'highlight range - first()');

$findbar->next();
is($text1->tag('ranges', 'highlight'), '1.44 1.46', 'highlight range - next()');

$findbar->previous();
is($text1->tag('ranges', 'highlight'), '1.7 1.9', 'highlight range - previous()');

$findbar->_data->{what} = 'quick';
$findbar->first();
is($text1->tag('ranges', 'highlight'), '', 'highlight range - text not found');

$findbar->configure(-textwidget => $text2);
$findbar->_data->{what} = 'th';
$findbar->first();

is($text1->tag('ranges', 'highlight'), '',        'text widget 1 not searched');
is($text2->tag('ranges', 'highlight'), '1.0 1.2', 'highlight range - after text widget change');

$findbar->_data->{case} = 0;
$findbar->_data->{what} = 'Th';
$findbar->first();
$findbar->next();
is($text2->tag('ranges', 'highlight'), '1.32 1.34', 'case-insensitive search');

$findbar->_data->{case} = 1;
$findbar->_data->{what} = 'Th';
$findbar->first();
$findbar->next();
is($text2->tag('ranges', 'highlight'), '1.0 1.2', 'case-sensitive search');

$findbar->_data->{case}  = 0;
$findbar->_data->{regex} = 1;
$findbar->_data->{what} = 'T.e';

$findbar->first();
$findbar->next();
is($text2->tag('ranges', 'highlight'), '1.32 1.35', 'regex search');

$findbar->_data->{case}  = 1;
$findbar->first();
$findbar->next();
is($text2->tag('ranges', 'highlight'), '1.0 1.3', 'case-sensitive regex search');

$findbar->_data->{what} = 'the';
$findbar->_data->{case}  = 0;
$findbar->_data->{regex} = 0;
$findbar->first();
$findbar->next();
is($text2->tag('ranges', 'highlight'), '1.32 1.35', 'setup for hide/show test');
$findbar->hide();
is($text2->tag('ranges', 'highlight'), '', 'hide() removes highlight');

$findbar->show();
is($text2->tag('ranges', 'highlight'), '1.0 1.3', 'show() does "first" search');
