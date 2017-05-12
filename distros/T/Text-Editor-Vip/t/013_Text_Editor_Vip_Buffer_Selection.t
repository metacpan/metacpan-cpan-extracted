# -*- perl -*-


use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;
use Test::Differences ;

use strict ;
my $text = '' ;

use Test::More tests => 41 ;
use Test::Exception ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

#Selection

my $buffer = Text::Editor::Vip::Buffer->new();

is($buffer->GetSelection()->IsEmpty(), 1, 'default selection is empty') ;

$buffer->GetSelection()->SetAnchor(5, 5) ;
$buffer->GetSelection()->SetLine(6, 3) ;

is($buffer->GetSelection()->IsEmpty(), 0, 'selection not empty') ;
eq_or_diff([5, 5, 6, 3], [$buffer->GetSelection()->GetBoundaries()], 'selection is as set') ;


#DeleteSelection

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("line 1 - 1\nline 2 - 2 2") ;

lives_ok { $buffer->DeleteSelection() ;} 'DeletedSelection with empty selection didn\'t die' ;

$buffer->GetSelection()->SetAnchor(0, 1) ;
$buffer->GetSelection()->SetLine(1, 1) ;
$buffer->DeleteSelection() ;
is($buffer->GetText(), "line 2 - 2 2", 'DeletedSelection OK') ;

$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;

$buffer->SetModificationPosition(6, 0) ;
$buffer->SetSelectionBoundaries(6, 0, 6, 10) ;
$buffer->DeleteSelection() ;
eq_or_diff([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteSelection') or diag $buffer->PrintPositionData('DeleteToBeginingOfWord') ;
eq_or_diff([$buffer->GetModificationPosition()], [6, 0], 'DeleteSelection') ;
is($buffer->GetNumberOfLines, 8	, 'DeleteSelection') ;
is($buffer->GetLineText(6), '', 'DeleteSelection') ;
is($buffer->GetLineText(7), '', 'DeleteSelection') ;

# single line selection
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("line 1 - 1\nline 2 - 2 2") ;
$buffer->GetSelection()->SetAnchor(1, 1) ;
$buffer->GetSelection()->SetLine(1, 4) ;
$buffer->DeleteSelection() ;
is($buffer->GetText(), "line 1 - 1\nl 2 - 2 2", 'DeletedSelection OK') ;

# selection  with outside buffer
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("line 1 - 1\nline 2 - 2 2") ;
$buffer->GetSelection()->SetAnchor(1, 50) ;
$buffer->GetSelection()->SetLine(1, 60) ;
$buffer->DeleteSelection() ;
is($buffer->GetText(), "line 1 - 1\nline 2 - 2 2", 'DeletedSelection OK') ;

# selection partly outside
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("line 1 - 1\nline 2 - 2 2") ;
$buffer->GetSelection()->SetAnchor(0, 4) ;
$buffer->GetSelection()->SetLine(0, 60) ;
$buffer->DeleteSelection() ;
is($buffer->GetText(), "line\nline 2 - 2 2", 'DeletedSelection OK') ;

# insert delete selection too
my $do_buffer = <<'EODB' ;
$buffer->Insert(<<EOT) ;
AAAAX1 - 1
BBBB 2 - 2 2
CCCC 3 - 3X 3 3
EOT

$buffer->GetSelection()->SetAnchor(0, 4) ;
$buffer->GetSelection()->SetLine(2, 10) ;
EODB

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Do($do_buffer) ;

# replace selection with hi
$buffer->Insert('<inserted>') ;
is($buffer->GetText(), "AAAA<inserted>X 3 3\n", 'Inserting with selection') ;

# Delete delete selection too
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Do($do_buffer) ;
$buffer->Delete(1) ;
is($buffer->GetText(), "AAAAX 3 3\n", 'Deleting with selection') ;

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Do($do_buffer) ;
$buffer->Delete(2) ;
is($buffer->GetText(), "AAAA 3 3\n", 'Deleting with selection') ;

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Do($do_buffer) ;
$buffer->Delete(500) ;
is($buffer->GetText(), "AAAA", 'Deleting with selection') ;

#Backspace delete selection too
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Do($do_buffer) ;
$buffer->Backspace(1) ;
is($buffer->GetText(), "AAAAX 3 3\n", 'Backspacing with selection') ;

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Do($do_buffer) ;
$buffer->Backspace(2) ;
is($buffer->GetText(), "AAAX 3 3\n", 'Backspaceing more with selection') ;

#RunSubOnSelection
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("line\n" x 10) ;
$buffer->GetSelection()->SetAnchor(0, 0) ;
$buffer->GetSelection()->SetLine(10, 1) ; # last line not part of selection if character == 0

sub AddTab
{
my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_ ;

return("\t$text" );
}

$buffer->RunSubOnSelection(\&AddTab, sub{die}) ;

is($buffer->GetText, ("\tline\n" x 10) . "\t", "Added tab to selection") ;


#GetSelectionText
$buffer = Text::Editor::Vip::Buffer->new();
$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Insert($text) ;
$buffer->GetSelection()->Set(0, 0, 0, 0) ;
is($buffer->GetSelectionText(), '', 'GetSelectionText empty') ;
is($buffer->GetText(), $text, 'GetSelectionText text still the same') ;
eq_or_diff([0, 0, 0, 0], [$buffer->GetSelection()->GetBoundaries()], 'GetSelectionText unchanged selection') ;

$buffer->GetSelection()->Set(1, 1, 2, 6) ;
is($buffer->GetSelectionText(), "ine 2 - 2 2\nline 3", 'GetSelectionText text') ;
is($buffer->GetText(), $text, 'GetSelectionText still the same') ;
eq_or_diff([1, 1, 2, 6], [$buffer->GetSelection()->GetBoundaries()], 'GetSelectionText unchanged selection') ;

$buffer->GetSelection()->Set(1, 100, 2, 50) ;
is($buffer->GetSelectionText(), "\nline 3 - 3 3 3", 'GetSelectionText text') ;
is($buffer->GetText(), $text, 'GetSelectionText still the same') ;
eq_or_diff([1, 100, 2, 50], [$buffer->GetSelection()->GetBoundaries()], 'GetSelectionText unchanged selection') ;

$buffer->GetSelection()->Set(3, 1, 10, 4) ;
is($buffer->GetText(), $text, 'GetSelectionText still the same') ;

is($buffer->GetSelectionText(), "ine 4 - 4 4 4 4\nline 5 - 5 5 5 5 5\n", '$buffer->GetSelectionText() handles bad selection') ;
eq_or_diff([$buffer->GetSelection()->GetBoundaries()], [3, 1, 5, 4], 'Boxed selection') ;

# selection is not reset on undo

$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Selection') ;
$buffer->Reset() ;
$buffer->Insert($text) ;

# SelectWord
$buffer->SetModificationPosition(0, 0) ;
$buffer->SelectWord() ;

eq_or_diff([$buffer->GetSelectionBoundaries()], [0, 1, 0, 5], 'Selection') ;
eq_or_diff([$buffer->GetModificationPosition()], [0, 5], 'Modification position') ;

$buffer->Delete(1) ;

eq_or_diff([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'Selection') ;
eq_or_diff([$buffer->GetModificationPosition()], [0, 1], 'Modification position') ;

$buffer->Undo(1) ;

eq_or_diff([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'Selection boundaries not modified on undo') ;
eq_or_diff([$buffer->GetModificationPosition()], [0, 5], 'Modification position undone properly') ;
is($buffer->CompareText($text), '', 'Undo with selection') ;
