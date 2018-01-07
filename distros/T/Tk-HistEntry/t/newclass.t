# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1997,1998,2008,2016 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use strict;
use warnings;
use Test::More;
use Tk;
use Tk::HistEntry;

my $top = eval { new MainWindow };
if (!$top) {
    plan skip_all => "cannot open DISPLAY: $@";
}
$top->geometry('+10+10');

if (!eval {
    require Tk::FireButton;
    $top->event('generate', '<Button-1>');
    die "event generate is working different on Win32" if $^O eq 'MSWin32';
    1;
}) {
    plan skip_all => "Tk::FireButton and/or event missing";
}

plan tests => 14;

{
    package MyHistEntry;
    @MyHistEntry::ISA = qw(Tk::Frame);
    Construct Tk::Widget 'MyHistEntry';

    sub Populate {
	my($f, $args) = @_;

	no warnings 'once';

	my $e = $f->Component(SimpleHistEntry => 'entry');
	my $binc = $f->Component( FireButton => 'inc',
				  -bitmap  => $Tk::FireButton::INCBITMAP,
				  -command => sub { $e->historyUp },
				);

	my $bdec = $f->Component( FireButton => 'dec',
				  -bitmap  => $Tk::FireButton::DECBITMAP,
				  -command => sub { $e->historyDown },
				);

	$f->gridColumnconfigure(0, -weight => 1);
	$f->gridColumnconfigure(1, -weight => 0);

	$f->gridRowconfigure(0, -weight => 1);
	$f->gridRowconfigure(1, -weight => 1);

	$binc->grid(-row => 0, -column => 1, -sticky => 'news');
	$bdec->grid(-row => 1, -column => 1, -sticky => 'news');

	$e->grid(-row => 0, -column => 0, -rowspan => 2, -sticky => 'news');

	$f->ConfigSpecs
	    (-repeatinterval => ['CHILDREN', "repeatInterval",
				 "RepeatInterval", 100       ],
	     -repeatdelay    => ['CHILDREN', "repeatDelay",
				 "RepeatDeleay",   300       ],
	     DEFAULT => [$e],
	    );

	$f->Delegates(DEFAULT => $e);

	$f;

    }
}


$top->geometry($top->screenwidth . "x" .$top->screenheight . "+0+0");


my($b2, $lb2);
{
    my $bla;
    $b2 = $top->MyHistEntry(-textvariable => \$bla,
			    -repeatinterval => 30,
			    -bell => 1,
			    -dup => 1,
			    -command => sub {
				my($w, $s, $added) = @_;
				if ($added) {
				    $lb2->insert('end', $s);
				    $lb2->see('end');
				}
				$bla = '';
			    })->pack;
    ok $b2;
    $b2->update;
    pass "after calling update";
}

$lb2 = $top->Scrolled('Listbox', -scrollbars => 'osoe')->pack;

my $e   = $b2->Subwidget('entry');
my $inc = $b2->Subwidget('inc');
my $dec = $b2->Subwidget('dec');

$e->focus;
$e->insert("end", 'first');
$e->event('generate', "<Return>", -keysym => 'Return');
is_deeply [$b2->history], ['first'];

$e->event('generate', "<Up>", -keysym => 'Up');
is $e->get, 'first';

$e->event('generate', "<Down>", -keysym => 'Down');
is $e->get, '';

$e->insert(0, 'second');
$e->event('generate', "<Return>", -keysym => 'Return');
is_deeply [$e->history], ['first', 'second'];

$inc->invoke;
$inc->invoke;

is $e->get, 'first';

$dec->invoke;
is $e->get, 'second';

# The next two tests are disabled, because they fail on systems without
# configured Alt key.
if (0) {
    $e->focus;
    $e->event('generate', "<Alt-less>", -state => 8, -keysym => 'less');
    is $e->get, 'first';

    $e->event('generate', "<Alt-greater>", -state => 8, -keysym => 'greater');
    is $e->get, 'second';
}

$e->historyAdd("third");
{
    my @h = $e->history;
    is @h, 3;
    is $h[2], 'third';
}

$e->invoke("fourth");
{
    my @h = $lb2->get(0, 'end'); # only three elements (because of use of historyAdd)
    is @h, 3;
    is $h[2], 'fourth';
}

$e->delete(0, 'end');
$e->insert(0, 'bla');
$e->historyAdd;
{
    my @h = $e->history;
    is @h, 5;
    is $h[4], 'bla';
}

if ($ENV{PERL_TEST_INTERACTIVE}) {
    my $cb = $top->Button(-text => "Ok",
			  -command => sub { $top->destroy })->pack;
    $cb->focus;

    $top->after(30000, sub { $top->destroy });

    MainLoop;
}
