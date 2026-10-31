use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

eval { require Tk; require Tk::Text::SuperText; 1 }
    or plan skip_all => "Perl/Tk required: $@";
my $mw = eval { Tk::MainWindow->new };
plan skip_all => "Tk display required: $@" unless $mw;
$mw->withdraw;

my $text = $mw->SuperText(-exportselection => 0);
my $other = $mw->SuperText(-readonly => 1);
is($text->cget('-readonly'), 0, 'editable by default');
is($other->readonly, 1, 'read-only can be set at construction');
$text->insert('1.0', "    alpha (beta)\n    gamma\n");
$text->resetUndo;
$text->insert('end', 'change');
$text->insert('end', 'redo');
$text->undo;
$text->SetCursor('1.4');
$text->tagAdd('sel', '1.4', '2.9');
$Tk::selectionType = 'normal';
my $before = $text->get('1.0', 'end');
my @selection = $text->tagRanges('sel');
my $undo = dclone($text->{UNDO});
my $redo = dclone($text->{REDO});
my $cursor = $text->index('insert');
$text->configure(-readonly => 1);

# Exercise public editing commands directly, including the inherited menu paths.
for my $command (qw(
    keyPress Insert enter autoIndentEnter noAutoIndentEnter tab ins
    del Delete backSpace Backspace deleteSelected deleteToWordStart
    deleteToWordEnd deleteToLineStart deleteToLineEnd deleteWord deleteLine
    selectionShiftLeft selectionShiftLeftTab selectionShiftRight
    selectionShiftRightTab cut clipboardCut paste clipboardPaste inlinePaste
    mousePasteSelection insertControlCode undo redo ReplaceSelectionsWith
)) {
    $text->$command('replacement');
    is($text->get('1.0', 'end'), $before, "$command leaves content unchanged");
    is_deeply([$text->tagRanges('sel')], \@selection, "$command preserves selection");
}
for my $event (qw(KeyPress Cut Paste InlinePaste Enter Undo Redo SelectionShiftRight)) {
    $text->eventGenerate("<<$event>>");
}
is($text->get('1.0', 'end'), $before, 'virtual editing events are blocked');
is($text->index('insert'), $cursor, 'blocked edits preserve cursor');
is_deeply($text->{UNDO}, $undo, 'blocked edits preserve undo history');
is_deeply($text->{REDO}, $redo, 'blocked edits preserve redo history');
ok(!$text->{ASCIICODE}, 'control-code command does not arm insertion');

$text->escape;
$text->SetCursor('1.10');
is($text->flashMatchingChar, '1.15', 'matching-pair lookup remains available');
$text->moveRight;
is($text->index('insert'), '1.11', 'navigation remains available');
$text->selectRight;
ok(scalar($text->tagRanges('sel')), 'selection remains available');
is($text->getSelected, 'b', 'selected text remains accessible for copying');

$Tk::selectionType = 'rect';
$text->tagRemove('sel', '1.0', 'end');
$text->tagAdd('sel', '1.4', '1.7');
$text->tagAdd('sel', '2.4', '2.7');
$text->deleteSelected;
$text->selectionShiftRight;
is($text->get('1.0', 'end'), $before, 'rectangular edits are blocked too');

$text->readonly(0);
is($text->cget('-readonly'), 0, 'method updates configuration');
is($other->readonly, 1, 'read-only is independent per widget');
$text->escape;
$Tk::selectionType = 'normal';
ok($text->redo, 'redo history survives read-only mode');
like($text->get('1.0', 'end'), qr/changeredo/, 'redo restores prior edit');
ok($text->undo, 'undo works again after unlocking');
is($text->get('1.0', 'end'), $before, 'undo restores content');
$text->Insert('editable');
like($text->get('1.0', 'end'), qr/editable/, 'interactive insertion works after unlocking');

$other->insert('1.0', 'application update');
is($other->get('1.0', 'end - 1c'), 'application update', 'programmatic insert is allowed');
$other->delete('1.0', '1.12');
is($other->get('1.0', 'end - 1c'), 'update', 'programmatic delete is allowed');
$text->insertControlCode;
$text->readonly(1);
ok(!exists $text->{ASCIICODE}, 'locking clears a pending control-code insertion');

$mw->destroy;
done_testing;
