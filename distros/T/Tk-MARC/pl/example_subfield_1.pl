#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}
use Tk;
use Tk::MARC::Subfield;
use MARC::Record;
use MARC::Editor;

my $mw = MainWindow->new;
$mw->title("Editor Test");
$mw->MARC_Subfield(-field => '245',
                   -label => 'a',
                   -value => 'Spam: The Fellowship of the Spam.',
                   )->pack;
$mw->MARC_Subfield(-field => '246',
                   -label => 'b',
                   -value => 'Spam: The Two Spammers.',
                   )->pack;
$mw->MARC_Subfield(-field => '247',
                   -label => 'c',
                   -value => 'Spam: The Return of the Spam.',
                   )->pack;

MainLoop;
