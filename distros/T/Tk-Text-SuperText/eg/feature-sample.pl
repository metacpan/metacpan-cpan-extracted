#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use FindBin qw($Bin);
use lib File::Spec->catdir($Bin, '..', 'lib');
use Tk;
use Tk::Text::SuperText;

# Run from any directory: perl /path/to/eg/feature-sample.pl
# Each scenario is a fresh scratch buffer; changing scenarios discards edits.
my @samples = (
    {
        name => 'Rectangle',
        help => 'Hold Ctrl and drag across the fruit column, or use Shift+Alt+arrow keys. '
              . 'Copy, cut or delete the rectangular selection. Escape clears it.',
        text => "Item    Fruit     Quantity\n001     apple     12\n002     pear      24\n003     plum      36\n004     peach     48\n",
        cursor => '2.8',
    },
    {
        name => 'Shift selection',
        help => 'Three lines are selected. Use the shift buttons or Ctrl+. / Ctrl+, '
              . 'to shift by one character; Ctrl+Alt+. / Ctrl+Alt+, shifts by a tab. '
              . 'Undo reverses a whole shift. Left shift removes characters before the selection.',
        text => "    apple   = 12\n    pear    = 24\n    plum    = 36\n",
        cursor => '1.4', selection => ['1.4', '3.end'],
    },
    {
        name => 'Inline paste',
        help => 'Click "Copy demo column" (replaces the clipboard), then "Inline paste". '
              . 'Each clipboard line is inserted at the same column on successive lines. '
              . 'Undo, then try normal Paste to compare. Shortcut: Ctrl+Shift+V.',
        text => "apple\npear\nplum\n",
        cursor => '1.0',
    },
    {
        name => 'Auto-indent',
        help => 'Press Return at the prepared cursor: the next line inherits four spaces. '
              . 'Shift+Return skips indentation; Ctrl+Return forces it. '
              . 'Insert toggles overwrite mode. Edits can be undone and redone.',
        text => "sub greet {\n    print \"Hello!\";\n}\n",
        cursor => '2.end',
    },
    {
        name => 'Matching pairs',
        help => 'The cursor is ON the opening parenthesis. Highlight (Ctrl+B) shows its partner; '
              . 'Jump (Ctrl+P) moves there. Try brackets and braces too. '
              . 'Typing a closing delimiter also highlights its visible partner.',
        text => "calculate(\n    [1, 2, { total => (3 + 4) }],\n    [5, 6, 7]\n);\n",
        cursor => '1.9',
    },
);

my $mw = MainWindow->new(
    -title => 'SuperText feature playground',
);
my $chooser = $mw->Frame->pack(-side => 'top', -fill => 'x');
my $help = '';
$mw->Label(-textvariable => \$help, -justify => 'left', -anchor => 'w',
    -wraplength => 760, -padx => 10, -pady => 10,
)->pack(-side => 'top', -fill => 'x');
my $tools = $mw->Frame->pack(-side => 'top', -fill => 'x');
my $paste_tools = $mw->Frame->pack(-side => 'top', -fill => 'x');
my $status = '';
$mw->Label(-textvariable => \$status, -anchor => 'w', -padx => 10,
)->pack(-side => 'bottom', -fill => 'x');
my $scrolled = $mw->Scrolled('SuperText',
    -scrollbars => 'se', -wrap => 'none',
    -width => 88, -height => 20, -font => ['Courier', 12],
    -background => 'white', -exportselection => 0,
    -indentmode => 'auto', -undodepth => undef, -redodepth => undef,
    -matchingcouples => '()[]{}', -showmatching => 1,
    -matchbackground => '#ffe080', -matchforeground => 'black',
    -matchhighlighttime => 2000,
)->pack(-fill => 'both', -expand => 1);
my $text = $scrolled->Subwidget('scrolled');
my $current = 0;
my $readonly = 0;
$paste_tools->Checkbutton(-text => 'Read-only', -variable => \$readonly,
    -command => sub {
        $text->configure(-readonly => $readonly);
        $text->focus;
    },
)->pack(-side => 'right');

sub load_sample {
    my ($index) = @_;
    $current = $index;
    my $sample = $samples[$index];
    $text->configure(-insertmode => 'insert');
    $text->escape;
    $text->removeMatch;
    $text->delete('1.0', 'end');
    $text->insert('1.0', $sample->{text});
    $text->resetUndo;  # Undo should affect the user's edits, not sample loading.
    $text->SetCursor($sample->{cursor});
    if ($sample->{selection}) {
        $Tk::selectionType = 'normal';
        $text->tagAdd('sel', @{$sample->{selection}});
    }
    $text->see('insert');
    $help = $sample->{help};
    $text->focus;
}

for my $i (0 .. $#samples) {
    my $index = $i;
    $chooser->Button(-text => $samples[$index]{name},
        -command => sub { load_sample($index) },
    )->pack(-side => 'left');
}
$chooser->Button(-text => 'Reset sample',
    -command => sub { load_sample($current) },
)->pack(-side => 'right');

# Buttons use the same virtual events as the default keyboard bindings.
for my $action (
    ['Undo', 'Undo'], ['Redo', 'Redo'],
    ['Shift left', 'SelectionShiftLeft'],
    ['Shift right', 'SelectionShiftRight'],
    ['Highlight pair', 'FlashMatchingChar'], ['Jump to pair', 'JumpToMatchingChar'],
) {
    my ($label, $event) = @$action;
    $tools->Button(-text => $label, -command => sub {
        $text->focus;
        $text->eventGenerate("<<$event>>");
    })->pack(-side => 'left');
}
$paste_tools->Button(-text => 'Copy demo column', -command => sub {
    # A trailing newline is needed for each line consumed by inlinePaste.
    $text->clipboardClear;
    $text->clipboardAppend("01  \n02  \n03  \n");
    $text->focus;
})->pack(-side => 'left');
for my $event ('Copy', 'Cut', 'Paste', 'InlinePaste') {
    my $command = $event;
    $paste_tools->Button(-text => $event eq 'InlinePaste' ? 'Inline paste' : $event,
        -command => sub {
            $text->focus;
            $text->eventGenerate("<<$command>>");
        },
    )->pack(-side => 'left');
}

$mw->repeat(150, sub {
    $status = 'Cursor: ' . $text->index('insert')
            . '    Mode: ' . $text->cget('-insertmode')
            . ($text->cget('-readonly') ? '    READ-ONLY' : '    Editable')
            . '    Scenario buttons reset the buffer; nothing is saved to disk.';
});
load_sample(0);
MainLoop;
