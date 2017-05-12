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

use Tk;
my $top;
BEGIN {
    if (!eval { $top = new MainWindow }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
    $top->geometry('+10+10');
}

BEGIN { $^W = 1; $| = 1; $loaded = 0; $last = 15; print "1..$last\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tk::HistEntry;
use strict;
use vars qw($loaded $last $VISUAL);

$loaded = 1;
$VISUAL = $ENV{PERL_TEST_INTERACTIVE};

my $ok = 1;
print "ok " . $ok++ . "\n";

use Tk;

eval {
    require Tk::FireButton;
    $top->event('generate', '<Button-1>');
    die "event generate is working different on Win32" if $^O eq 'MSWin32';
};
if ($@) {
    print "ok " . $ok++ . " # Skipping this test (Tk::FireButton and/or event missing)\n";
    for ($ok .. $last) {
	print "ok # Skipping...\n";
    }
    exit;
}

package MyHistEntry;
@MyHistEntry::ISA = qw(Tk::Frame);
Construct Tk::Widget 'MyHistEntry';

{ my $foo = $Tk::FireButton::INCBITMAP;
     $foo = $Tk::FireButton::DECBITMAP; }

sub Populate {
    my($f, $args) = @_;

    my $e = $f->Component(SimpleHistEntry => 'entry');
    my $binc = $f->Component( FireButton => 'inc',
        -bitmap             => $Tk::FireButton::INCBITMAP,
        -command            => sub { $e->historyUp },
    );

    my $bdec = $f->Component( FireButton => 'dec',
        -bitmap             => $Tk::FireButton::DECBITMAP,
        -command            => sub { $e->historyDown },
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

package main;

$top->geometry($top->screenwidth . "x" .$top->screenheight . "+0+0");

my($bla);

my($b2, $lb2);
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
print "ok " . $ok++ . "\n";
$b2->update;
print "ok " . $ok++ . "\n";

$lb2 = $top->Scrolled('Listbox', -scrollbars => 'osoe'
		     )->pack;


my $e   = $b2->Subwidget('entry');
my $inc = $b2->Subwidget('inc');
my $dec = $b2->Subwidget('dec');

$e->focus;
$e->insert("end", 'first');
$e->event('generate', "<Return>", -keysym => 'Return');
print ((($b2->history)[-1] eq 'first' ? "" : "not ") . "ok " . $ok++ . "\n");

my @h = $e->history;
print ((@h == 1 && $h[0] eq 'first' ? "" : "not ") . "ok " . $ok++ . "\n");

$e->event('generate', "<Up>", -keysym => 'Up');
print (($e->get eq 'first' ? "" : "not ") . "ok " . $ok++ . "\n");

$e->event('generate', "<Down>", -keysym => 'Down');
print (($e->get eq '' ? "" : "not ") . "ok " . $ok++ . "\n");

$e->insert(0, 'second');
$e->event('generate', "<Return>", -keysym => 'Return');
@h = $e->history;
print ((@h == 2 && $h[1] eq 'second' ? "" : "not ") . "ok " . $ok++ . "\n");

$inc->invoke;
$inc->invoke;
print (($e->get eq 'first' ? "" : "not ") . "ok " . $ok++ . "\n");

$dec->invoke;
print (($e->get eq 'second' ? "" : "not ") . "ok " . $ok++ . "\n");

# The next two tests are disabled, because they fail on systems without
# configure Alt key.
$e->focus;
$e->event('generate', "<Alt-less>", -state => 8, -keysym => 'less');
#print (($e->get eq 'first' ? "" : "not ") . "ok " . $ok++ . "\n");
print "ok ". $ok++ . "\n";

$e->event('generate', "<Alt-greater>", -state => 8, -keysym => 'greater');
#print (($e->get eq 'second' ? "" : "not ") . "ok " . $ok++ . "\n");
print "ok ". $ok++ . "\n";

$e->historyAdd("third");
@h = $e->history;
print ((@h == 3 && $h[2] eq 'third' ? "" : "not ") . "ok " . $ok++ . "\n");

$e->invoke("fourth");
@h = $lb2->get(0, 'end'); # only three elements (because of use of historyAdd)
print ((@h == 3 && $h[2] eq 'fourth' ? "" : "not ") . "ok " . $ok++ . "\n");

$e->delete(0, 'end');
$e->insert(0, 'bla');
$e->historyAdd;
@h = $e->history;
print ((@h == 5 && $h[4] eq 'bla' ? "" : "not ") . "ok " . $ok++ . "\n");

my $cb = $top->Button(-text => "Ok",
		      -command => sub { $top->destroy })->pack;
$cb->focus;

$top->after(30000, sub { $top->destroy });

MainLoop if $VISUAL;

