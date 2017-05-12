# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1997,1998,2008,2016 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use strict;
use warnings;
use File::Temp qw(tempfile);
use Test::More;
use Tk;

my $top = eval { new MainWindow };
if (!$top) {
    plan skip_all => "cannot open DISPLAY: $@";
}
$top->geometry('+10+10');

plan tests => 50;

use Tk::HistEntry;

my($he1, $e1);
{
    $he1 = $top->SimpleHistEntry(-textvariable => \my $foo,
				 -bell => 1,
				 -dup => 0,
				 -case => 1,
				 -auto => 1,
				 -match => 1,
				)->pack;
    ok Tk::Exists($he1);
    is $he1->class, 'SimpleHistEntry';

    $he1->update;
    pass 'ok after update';

    $e1 = $he1->_entry;
    ok $e1;
}

my($he2, $e2, $lb2);
{
    $he2 = $top->HistEntry(-textvariable => \my $bla,
			   -bell => 1,
			   -dup => 0,
			   -label => 'Browse:',
			   -labelPack => [-side => 'top'],
			  )->pack;
    ok Tk::Exists($he2);
    is $he2->class, 'HistEntry';
    $he2->update;
    pass 'ok after update';

 SEARCH: for my $sw ($he2->Subwidget) {
	if ($sw->isa('Tk::LabEntry')) {
	    for my $ssw ($sw->Subwidget) {
		if ($ssw->isa('Tk::Label')) {
		    my $t = $ssw->cget(-text);
		    is $t, 'Browse:';
		    last SEARCH;
		}
	    }
	}
    }

    $e2 = $he2->_entry;
    ok $e2;

    $lb2 = $he2->_listbox;
    ok $lb2;
}

for my $def (
	     [$e1, $he1, 1],
	     [$e2, $he2, 2],
	    ) {
    my($e, $he, $nr) = @$def;

    $e->insert(0, "first $nr");
    $he->historyAdd;
    is_deeply [$he->history], ["first $nr"];

    $he->historyAdd("second $nr");
    {
	my @h = $he->history;
	is $h[1], "second $nr";
	is @h, 2;
    }    

    $he->addhistory("third $nr");
    my @h = $he->history;
    is $h[2], "third $nr";
    is @h, 3;

    if ($he eq $he2) {
	is_deeply [$lb2->get(0, 'end')], \@h;
    }

    ok $he->can('addhistory');
    ok $he->can('historyAdd');
}

my %histfiles;
my %oldhist;

for my $widget (qw(HistEntry SimpleHistEntry)) {
    my @test_values = qw(bla foo bar);
    my($histfh,$histfile) = tempfile("hist.save.XXXXXXXX", UNLINK => 1);

    my $he = $top->$widget->pack;
    for (@test_values) { $he->historyAdd($_) }
    is_deeply [$he->history], \@test_values;

    $he->_entry->insert('end', 'blubber');
    $he->addhistory();
    is_deeply [$he->history], [@test_values, 'blubber'];
    $he->OnDestroy(sub { $he->historySave($histfile) });
    $histfiles{$widget} = $histfile;
    $oldhist{$widget} = [$he->history];
    $he->destroy;
}

for my $widget (qw(HistEntry SimpleHistEntry)) {
    my $he = $top->$widget;
    $he->historyMergeFromFile($histfiles{$widget});
    is_deeply [$he->history], $oldhist{$widget}, "historyMergeFromFile for $widget works";

    $he->historyReset;
    is_deeply [$he->history], [], "historyReset for $widget works";

    if ($widget eq 'HistEntry') {
	is_deeply [$he->_listbox->get(0, "end")], [];
    }

    $he->insert('end', 'blablubber');
    is $he->get, 'blablubber';

    $he->delete(0, 'end');
    is $he->get, '';
}

# check duplicates
for my $he ($he1, $he2) {
    my $hist_entries = 4;
    $he->historyAdd("foobar");
    is scalar $he->history, $hist_entries;
    $he->historyAdd("foobar");
    is scalar $he->history, $hist_entries;

    $hist_entries++;
    $he->historyAdd("foobar2");
    is scalar $he->history, $hist_entries;

    $he->_entry->delete(0, "end");
    $he->_entry->insert(0, "foobar");
    $he->historyAdd;
    is scalar $he->history, $hist_entries;
}

{
    my $he = $top->SimpleHistEntry(-history => [qw(1 2 3)]);
    is_deeply [$he->cget(-history)], [qw(1 2 3)], 'check -history option with SimpleHistEntry';
    is_deeply [$he->history],        [qw(1 2 3)];
}

{
    my $he = $top->HistEntry(-history => [qw(1 2 3)]);
    is_deeply [$he->cget(-history)], [qw(1 2 3)], 'check -history option with HistEntry';
    is_deeply [$he->history],        [qw(1 2 3)];
}

if ($ENV{PERL_TEST_INTERACTIVE}) {
    $top->Button(
		 -text => "OK",
		 -command => sub { $top->destroy },
		)->pack->focus;
    $top->after(60*1000, sub { $top->destroy });
    MainLoop;
}
