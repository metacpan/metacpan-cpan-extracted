
# -*- perl -*-

#~ use lib qw(lib) ;

use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
use warnings ;

use Test::More tests => 174 ;
use Test::Exception ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

my $buffer = new Text::Editor::Vip::Buffer() ;

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Movements') ;

# GetFirstNonSpacePosition

my $text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5
something
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(2, 2) ;
is($buffer->GetFirstNonSpacePosition(), 3, 'GetFirstNonSpacePosition') ;

is($buffer->GetFirstNonSpacePosition(1), 2, 'GetFirstNonSpacePosition') ;
is($buffer->GetFirstNonSpacePosition(0), 1, 'GetFirstNonSpacePosition') ;
is($buffer->GetFirstNonSpacePosition(5), 0, 'GetFirstNonSpacePosition empty line') ;
is($buffer->GetFirstNonSpacePosition(6), 0, 'GetFirstNonSpacePosition line starts with character') ;

dies_ok {$buffer->GetFirstNonSpacePosition(7) ;} 'GetFirstNonSpacePosition exception' ;

# SetModificationPositionAtSelectionStart
$buffer->SetModificationPosition(2, 2) ;
$buffer->SetModificationPositionAtSelectionStart() ;
is_deeply([$buffer->GetModificationPosition()], [2, 2], 'no selection') ;

$buffer->SetModificationPosition(2, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->SetModificationPositionAtSelectionStart() ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'SetModificationPositionAtSelectionStart') ;

# MoveToEndOfLineNoSelectionClear
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->MoveToEndOfLineNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 11], 'MoveToEndOfLineNoSelectionClear') ;

$buffer->MoveToEndOfLineNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 11], 'MoveToEndOfLineNoSelectionClear') ;

$buffer->SetModificationPosition(2, 50) ;
$buffer->MoveToEndOfLineNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [2, 17], 'MoveToEndOfLineNoSelectionClear no selection') ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->MoveToEndOfLineNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 20], 'MoveToEndOfLineNoSelectionClear') ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 5, 6, 7], "boxed selection") ;

# BoxSelection
$buffer->{SELECTION}->Clear() ;
$buffer->BoxSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->SetSelectionBoundaries(-1, 5, 10, 7) ;
$buffer->BoxSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 5, 6, 7], "selection invalid start line") ;

$buffer->SetSelectionBoundaries(4, -1, 10, 7) ;
$buffer->BoxSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 0, 6, 7], "selection invalid start character") ;

$buffer->SetSelectionBoundaries(4, 5, -1, 7) ;
$buffer->BoxSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 7, 4, 5], "selection invalid end line, reversing") ;

$buffer->SetSelectionBoundaries(4, 5, 5, 6) ;
$buffer->BoxSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 5, 5, 6], "selection OK") ;

# MoveToEndOfSelectionNoClear
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 5, 7) ;
$buffer->MoveToEndOfSelectionNoClear() ;
is_deeply([$buffer->GetModificationPosition()], [5, 7], 'MoveToEndOfSelectionNoClear') ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 5, 5, 7], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveToEndOfSelectionNoClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 2], 'MoveToEndOfSelectionNoClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 10, 7) ;
$buffer->MoveToEndOfSelectionNoClear() ;
is_deeply([$buffer->GetModificationPosition()], [6, 7], 'MoveToEndOfSelectionNoClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 5, 6, 7], "selection OK") ;

# MoveToEndOfLine, clears the selection
$buffer->SetModificationPosition(3, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveToEndOfLine() ;
is_deeply([$buffer->GetModificationPosition()], [3, 20], 'MoveToEndOfLine no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection cleared") ;

$buffer->SetModificationPosition(6, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveToEndOfLine() ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'MoveToEndOfLine no selection empty line') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection cleared") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(2, 3, 4, 5) ;
$buffer->MoveToEndOfLine() ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'MoveToEndOfLine with selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection cleared") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 10, 7) ;
$buffer->MoveToEndOfLine() ;
is_deeply([$buffer->GetModificationPosition()], [6, 7], 'MoveToEndOfLineNoSelectionClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection cleared") ;

# MoveToTopOfBuffer, clears the buffer
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 10, 7) ;
$buffer->MoveToTopOfBuffer() ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'MoveToTopOfBuffer') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection cleared") ;

# MoveToEndOfBuffer, clears the buffer
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 10, 7) ;
$buffer->MoveToEndOfBuffer() ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'MoveToEndOfBuffer') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection cleared") ;

# MoveToStartOfSelectionNoClear
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 5, 7) ;
$buffer->MoveToStartOfSelectionNoClear() ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'MoveToStartOfSelectionNoClear') ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 5, 5, 7], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveToStartOfSelectionNoClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 2], 'MoveToStartOfSelectionNoClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveToStartOfSelectionNoClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveToStartOfSelectionNoClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 5, 6, 7], "selection OK") ;

# MoveHome, jumping frog
#--------------------------------------------------
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(4, 5, 5, 7) ;
$buffer->MoveHome() ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'MoveHome') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveHome() ;
is_deeply([$buffer->GetModificationPosition()], [3, 4], 'MoveHome no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

# jumping frog
$buffer->MoveHome() ;
is_deeply([$buffer->GetModificationPosition()], [3, 0], 'MoveHome jumping frog') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

# jumping frog
$buffer->SetModificationPosition(3, 2) ;
$buffer->MoveHome() ;
is_deeply([$buffer->GetModificationPosition()], [3, 4], 'MoveHome jumping frog backwards') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveHome() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveHome invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

#~ MoveLeftNoSelectionClear
# ----------------------------------------------
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 5], 'MoveLeftNoSelectionClear selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [3, 5, 4, 7], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveLeftNoSelectionClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 5, 6, 7], "selection OK") ;

# no selection
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(3, 2) ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 1], 'MoveLeftNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 0], 'MoveLeftNoSelectionClear invalid no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 0], 'MoveLeftNoSelectionClear invalid no selection no wrapping') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

#~ MoveLeft
# --------------------------------
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveLeft() ;
is_deeply([$buffer->GetModificationPosition()], [3, 5], 'MoveLeft selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveLeft() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveLeft invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

# no selection
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(3, 2) ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 1], 'MoveLeft no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 0], 'MoveLeft invalid no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveLeftNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 0], 'MoveLeft invalid no selection no wrapping') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

#~ MoveRightNoSelectionClear
#----------------------------------------------
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveRightNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [4, 7], 'MoveRightNoSelectionClear selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [3, 5, 4, 7], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveRightNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [6, 7], 'MoveRightNoSelectionClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 5, 6, 7], "selection OK") ;

# no selection
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(3, 2) ;
$buffer->MoveRightNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 3], 'MoveRightNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveRightNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 4], 'MoveRightNoSelectionClear invalid no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveRightNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 5], 'MoveRightNoSelectionClear invalid no selection no wrapping') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

#~ MoveRight
#-----------------------------------------
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveRight() ;
is_deeply([$buffer->GetModificationPosition()], [4, 7], 'MoveRight selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveRight() ;
is_deeply([$buffer->GetModificationPosition()], [6, 7], 'MoveRight invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

# no selection
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(3, 2) ;
$buffer->MoveRight() ;
is_deeply([$buffer->GetModificationPosition()], [3, 3], 'MoveRight no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->MoveRight() ;
is_deeply([$buffer->GetModificationPosition()], [3, 4], 'MoveRight no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(3, 50) ;
$buffer->MoveRight() ;
is_deeply([$buffer->GetModificationPosition()], [3, 51], 'MoveRight no selection no wrapping') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection empty") ;

#-------------------------------------------------------------------------------

#~ MoveUpNoSelectionClear
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveUpNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [3, 5], 'MoveUpNoSelectionClear selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [3, 5, 4, 7], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveUpNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveUpNoSelectionClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 5, 6, 7], "selection OK") ;

# no selection
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(2, 2) ;
$buffer->MoveUpNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveUpNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveUpNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 2], 'MoveUpNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveUpNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 2], 'MoveUpNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

# test with a tab
$buffer->Reset() ;
$buffer->Insert(<<EOT) ;
\t901234567890
EOT

$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(1, 1) ;
$buffer->MoveUpNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'MoveUpNoSelectionClear invalid no selection no wrapping') ;

#~ MoveUp
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveUp() ;
is_deeply([$buffer->GetModificationPosition()], [3, 5], 'MoveUp selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveUp() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveUp invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

# no selection
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(2, 2) ;
$buffer->MoveUp() ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveUp invalid no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveUp() ;
is_deeply([$buffer->GetModificationPosition()], [0, 2], 'MoveUp no selection') ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveUp() ;
is_deeply([$buffer->GetModificationPosition()], [0, 2], 'MoveUp no selection') ;

# test with a tab
$buffer->Reset() ;
$buffer->Insert(<<EOT) ;
\t901234567890
EOT

$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(1, 1) ;
$buffer->MoveUp() ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'MoveUp no selection') ;

#~ MoveDownNoSelectionClear
# -----------------------------------------------
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveDownNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [4, 7], 'MoveDownNoSelectionClear selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [3, 5, 4, 7], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveDownNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [6, 7], 'MoveDownNoSelectionClear invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 5, 6, 7], "selection OK") ;

# no selection

$buffer->SetModificationPosition(4, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveDownNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [5, 2], 'MoveDownNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveDownNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [6, 2], 'MoveDownNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveDownNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [6, 2], 'MoveDownNoSelectionClear no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

# test with a tab
$buffer->Reset() ;
$buffer->Insert(<<EOT) ;
no_tab_here
\t901234567890
EOT

$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(0, 1) ;
$buffer->MoveDownNoSelectionClear() ;
is_deeply([$buffer->GetModificationPosition()], [1, 0], 'MoveDownNoSelectionClear invalid no selection no wrapping') ;

#~ MoveDown
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(3, 5, 4, 7) ;
$buffer->MoveDown() ;
is_deeply([$buffer->GetModificationPosition()], [4, 7], 'MoveDown selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->SetModificationPosition(3, 2) ;
$buffer->SetSelectionBoundaries(-4, 5, 10, 7) ;
$buffer->MoveDown() ;
is_deeply([$buffer->GetModificationPosition()], [6, 7], 'MoveDown invalid selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

# no selection
$buffer->SetModificationPosition(4, 2) ;
$buffer->{SELECTION}->Clear() ;
$buffer->MoveDown() ;
is_deeply([$buffer->GetModificationPosition()], [5, 2], 'MoveDown no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveDown() ;
is_deeply([$buffer->GetModificationPosition()], [6, 2], 'MoveDown no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

$buffer->{SELECTION}->Clear() ;
$buffer->MoveDown() ;
is_deeply([$buffer->GetModificationPosition()], [6, 2], 'MoveDown no selection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], "selection OK") ;

#MoveToBeginingOfWord
#-------------------------------------------------------------------------------
$buffer->SetModificationPosition(1, 4) ;
is($buffer->MoveToBeginingOfWord(), '1', 'in a word') ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveToBeginingOfWord') ;

$buffer->SetModificationPosition(1, 3) ;
is($buffer->MoveToBeginingOfWord(), '1', 'in a word') ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveToBeginingOfWord') ;

$buffer->SetModificationPosition(1, 2) ;
is($buffer->MoveToBeginingOfWord(), '0', 'not in a word') ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveToBeginingOfWord') ;

$buffer->SetModificationPosition(1, 1) ;
is($buffer->MoveToBeginingOfWord(), '0', 'not in a word') ;
is_deeply([$buffer->GetModificationPosition()], [1, 1], 'MoveToBeginingOfWord') ;

#MoveToBeginingOfWordNoSelectionClear
$buffer->SetSelectionBoundaries(1, 2, 3, 4) ;
$buffer->SetModificationPosition(1, 4) ;
is($buffer->MoveToBeginingOfWordNoSelectionClear(), '1', 'in a word') ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveToBeginingOfWordNoSelectionClear') ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 2, 3, 4], 'MoveToBeginingOfWordNoSelectionClear') ;

$buffer->Reset() ;
$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5
     
something
EOT

$buffer->Insert($text) ;

$buffer->SetModificationPosition(6, 10) ;
is($buffer->MoveToBeginingOfWordNoSelectionClear(), 1, 'MoveToBeginingOfWordNoSelectionClear is moving') ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'ExtendSelectionToBeginingOfWord') ;

#~ MoveToEndOfWord
#-------------------------------------------------------------------------------

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
$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(3, 4, 5, 6) ;
$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'MoveToEndOfWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'MoveToEndOfWord clear selection') ;

$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 7], 'MoveToEndOfWord') ;

$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 11], 'MoveToEndOfWord last word') ;

$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [1, 6], 'MoveToEndOfWord next line') ;

$buffer->SetModificationPosition(4, 50) ;
$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 9], 'MoveToEndOfWord') ;

$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 9], 'MoveToEndOfWord') ;

$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 9], 'MoveToEndOfWord') ;

$buffer->SetModificationPosition(0, 6) ;
$buffer->MoveToEndOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 7], 'SelectWord no selection') ;

#~ MoveToNextWord
#-------------------------------------------------------------------------------
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(3, 4, 5, 6) ;
$buffer->MoveToNextWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 1], 'MoveToNextWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'MoveToNextWord clear selection') ;

$buffer->MoveToNextWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 6], 'MoveToNextWord') ;

$buffer->MoveToNextWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 10], 'MoveToNextWord last word') ;

$buffer->MoveToNextWord() ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveToNextWord next line') ;

$buffer->SetModificationPosition(4, 50) ;
$buffer->MoveToNextWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'MoveToNextWord') ;

$buffer->MoveToNextWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'MoveToNextWord') ;

#~ MoveToPreviousWord
#-------------------------------------------------------------------------------
my $reminder = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(3, 4, 5, 6) ;
$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'MoveToPreviousWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'MoveToPreviousWord clear selection') ;

$buffer->SetModificationPosition(6, 30) ;
$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'MoveToPreviousWord') ;

$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [4, 22], 'MoveToPreviousWord last word') ;

$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [4, 20], 'MoveToPreviousWord next line') ;

$buffer->SetModificationPosition(6, 5) ;
$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [4, 22], 'MoveToPreviousWord') ;

$buffer->SetModificationPosition(1, 7) ;
$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'MoveToPreviousWord') ;

$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 10], 'MoveToPreviousWord') ;

$buffer->SetModificationPosition(1, 3) ;
$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 10], 'MoveToPreviousWord') ;

# no previous word
$buffer->SetModificationPosition(0, 3) ;
$buffer->MoveToPreviousWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 3], 'MoveToPreviousWord') ;

