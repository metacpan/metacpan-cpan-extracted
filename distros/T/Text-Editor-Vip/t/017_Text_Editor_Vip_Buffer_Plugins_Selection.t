# -*- perl -*-


use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
use warnings ;

use Test::More tests => 106 ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Selection') ;

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

is($buffer->IsSelectionEmpty(), 1, 'IsSelectionEmpty 1') ;
$buffer->SetSelectionBoundaries(3, 4, 5, 6) ;
is($buffer->IsSelectionEmpty(), 0, 'IsSelectionEmpty 0') ;

$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(3, 4, 5, 6) ;
$buffer->ClearSelection() ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'ClearSelection') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'ClearSelection') ;


$buffer->SetSelectionAnchor(4, 4) ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, 4, 4], 'SetSelectionAnchor') ;

$buffer->SetSelectionLine(2, 2) ;
is_deeply([$buffer->GetSelectionBoundaries()], [2, 2, 4, 4], 'SetSelectionLine') ;

is($buffer->GetSelectionStartLine(), 2, 'GetSelectionStartLine') ;
is($buffer->GetSelectionStartCharacter(), 2, 'GetSelectionStartCharacter') ;
is($buffer->GetSelectionEndLine(), 4, 'GetSelectionEndLine') ;
is($buffer->GetSelectionEndCharacter(), 4, 'GetSelectionEndCharacter') ;

is($buffer->IsCharacterSelected(2, 1), '', 'IsCharacterSelected') ;
is($buffer->IsCharacterSelected(2, 2), 1, 'IsCharacterSelected') ;
is($buffer->IsCharacterSelected(4, 3), 1, 'IsCharacterSelected') ;
is($buffer->IsCharacterSelected(4, 4), '', 'IsCharacterSelected') ;
is($buffer->IsCharacterSelected(4, 5), '', 'IsCharacterSelected') ;

$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
is($buffer->IsCharacterSelected(2, 0), 1, 'IsCharacterSelected') ;
is($buffer->IsCharacterSelected(3, 0), '', 'IsCharacterSelected') ;

$buffer->SelectAll() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 0, 7, 0], 'SelectAll') ;

$buffer->Reset() ;
$buffer->Insert("abc\n123") ;
$buffer->SelectAll() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 0, 1, 3], 'SelectAll') ;

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(4, 4) ;
$buffer->SetSelectionAnchorAtCurrentPosition() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, 4, 4], 'SetSelectionAnchorAtCurrentPosition') ;

$buffer->SetModificationPosition(2, 2) ;
$buffer->ExtendSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [2, 2, 4, 4], 'ExtendSelection up') ;

$buffer->SetModificationPosition(5, 2) ;
$buffer->ExtendSelection() ;
is_deeply([$buffer->GetSelectionBoundaries()], [4, 4, 5, 2], 'ExtendSelection down') ;

$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToEndOfLine() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 4, 1, 14], 'ExtendSelectionToEndOfLine no selection') ;

$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToEndOfLine() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 14, 2, 0], 'ExtendSelectionToEndOfLine existing selection') ;

$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToEndOfBuffer() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 4, 7, 0], 'ExtendSelectionToEndOfDocument no selection') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'ExtendSelectionToEndOfDocument no selection') ;

$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToEndOfBuffer() ;
is_deeply([$buffer->GetSelectionBoundaries()], [2, 0, 7, 0], 'ExtendSelectionToEndOfDocument existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'ExtendSelectionToEndOfDocument existing selection') ;

# ExtendSelectionToStartOfBuffer
$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToStartOfBuffer() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 0, 1, 4], 'ExtendSelectionToStartOfBuffer no selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'ExtendSelectionToEndOfDocument no selection') ;

$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToStartOfBuffer() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 0, 2, 0], 'ExtendSelectionToStartOfBuffer existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 0], 'ExtendSelectionToEndOfDocument existing selection') ;

#ExtendSelectionHome
$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionHome() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 2, 1, 4], 'ExtendSelectionHome no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'ExtendSelectionHome no selection') ;

# frog jump
$buffer->ExtendSelectionHome() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 0, 1, 4], 'ExtendSelectionHome no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 0], 'ExtendSelectionHome no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionHome() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 2, 2, 0], 'ExtendSelectionHome existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'ExtendSelectionHome existing selection') ;

# with selection # frog jump
$buffer->ExtendSelectionHome() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 0, 2, 0], 'ExtendSelectionHome existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 0], 'ExtendSelectionHome existing selection') ;

#ExtendSelectionLeft
$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionLeft() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 3, 1, 4], 'ExtendSelectionLeft no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 3], 'ExtendSelectionLeft no selection') ;

$buffer->ExtendSelectionLeft() ;
$buffer->ExtendSelectionLeft() ;
$buffer->ExtendSelectionLeft() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 0, 1, 4], 'ExtendSelectionLeft no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 0], 'ExtendSelectionLeft no selection') ;

$buffer->ExtendSelectionLeft() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 0, 1, 4], 'ExtendSelectionLeft no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 0], 'ExtendSelectionLeft no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionLeft() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 3, 2, 0], 'ExtendSelectionLeft existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 3], 'ExtendSelectionLeft existing selection') ;

#ExtendSelectionRight
$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionRight() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 4, 1, 5], 'ExtendSelectionRight no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 5], 'ExtendSelectionRight no selection') ;

$buffer->ExtendSelectionRight() for(1 .. 30) ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 4, 1, 35], 'ExtendSelectionRight no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 35], 'ExtendSelectionRight no selection') ;

# with selection
$buffer->SetSelectionBoundaries(1, 10, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionRight() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 5, 1, 10], 'ExtendSelectionRight existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 5], 'ExtendSelectionRight existing selection') ;

$buffer->ExtendSelectionRight() for(1 .. 30) ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 10, 1, 35], 'ExtendSelectionRight existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 35], 'ExtendSelectionRight existing selection') ;

#ExtendSelectionDown
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

$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionDown() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 4, 2, 4], 'ExtendSelectionDown no selection') ;
is_deeply([$buffer->GetModificationPosition()], [2, 4], 'ExtendSelectionDown no selection') ;

#~ diag DumpTree([$buffer->GetModificationPosition()]) ;

$buffer->ExtendSelectionDown() for (1 .. 6) ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 4, 7, 4], 'ExtendSelectionDown no selection') ;
is_deeply([$buffer->GetModificationPosition()], [7, 4], 'ExtendSelectionDown no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionDown() ;
is_deeply([$buffer->GetSelectionBoundaries()], [2, 0, 2, 4], 'ExtendSelectionDown existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [2, 4], 'ExtendSelectionDown existing selection') ;

my $text_with_tab = <<EOT ;
line 1 - 1
line 2 - 2 2
\tline 3 - 3 3 3
\t\tline 4 - 4 4 4 4

something
EOT

# ExtendSelectionDown, test with tab
$buffer->Reset() ;
$buffer->Insert($text_with_tab) ;

$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 9) ;
$buffer->ExtendSelectionDown() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 9, 2, 2], 'ExtendSelectionDown no selection') ;
is_deeply([$buffer->GetModificationPosition()], [2, 2], 'ExtendSelectionDown no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 9) ;
$buffer->ExtendSelectionDown() ;
is_deeply([$buffer->GetSelectionBoundaries()], [2, 0, 2, 2], 'ExtendSelectionDown existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [2, 2], 'ExtendSelectionDown existing selection') ;

$buffer->ExtendSelectionDown() ;
is_deeply([$buffer->GetSelectionBoundaries()], [2, 0, 3, 1], 'ExtendSelectionDown existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [3, 1], 'ExtendSelectionDown existing selection') ;


#ExtendSelectionUp
$buffer->ClearSelection() ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionUp() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 4, 1, 4], 'ExtendSelectionUp no selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 4], 'ExtendSelectionUp no selection') ;

$buffer->ExtendSelectionUp() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 4, 1, 4], 'ExtendSelectionUp no selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 4], 'ExtendSelectionUp no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionUp() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 4, 2, 0], 'ExtendSelectionUp existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 4], 'ExtendSelectionUp existing selection') ;

# ExtendSelectionUp, test with tab
my $text_with_tab2 = <<EOT ;
\tline 1 - 1
\t\tline 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4

something
EOT

$buffer->Reset() ;
$buffer->Insert($text_with_tab2) ;

$buffer->ClearSelection() ;
$buffer->SetModificationPosition(2, 9) ;
$buffer->ExtendSelectionUp() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 1, 2, 9], 'ExtendSelectionUp no selection') ;
is_deeply([$buffer->GetModificationPosition()], [1, 1], 'ExtendSelectionUp no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(1, 1) ;
$buffer->ExtendSelectionUp() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 2, 0], 'ExtendSelectionUp existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 1], 'ExtendSelectionUp existing selection') ;

$buffer->ExtendSelectionUp() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 2, 0], 'ExtendSelectionUp existing selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 1], 'ExtendSelectionUp existing selection') ;

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

# SelectWord
$buffer->SetModificationPosition(0, 0) ;
$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 0, 5], 'SelectWord no selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'SelectWord no selection') ;

$buffer->SetModificationPosition(0, 1) ;
$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 6, 0, 7], 'SelectWord no selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 7], 'SelectWord no selection') ;

$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 10, 0, 11], 'SelectWord no selection') ;
is_deeply([$buffer->GetModificationPosition()], [0, 11], 'SelectWord no selection') ;

# with selection
$buffer->SetSelectionBoundaries(2, 0, 3, 0) ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 0, 5], 'SelectWord') ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'SelectWord') ;

$buffer->SetSelectionBoundaries(-1, 0, 3, -1) ;
$buffer->SetModificationPosition(0, 1) ;
$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 6, 0, 7], 'SelectWord') ;
is_deeply([$buffer->GetModificationPosition()], [0, 7], 'SelectWord') ;

#with tab
$text_with_tab = <<EOT ;
\tline 1 - 1
\t\tline 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4

something
EOT

$buffer->Reset() ;
$buffer->Insert($text_with_tab) ;

# SelectWord
$buffer->SetModificationPosition(0, 0) ;
$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 0, 5], 'SelectWord tab') ;
is_deeply([$buffer->GetModificationPosition()], [0, 5], 'SelectWord tab') ;

$buffer->SetModificationPosition(1, 1) ;
$buffer->SelectWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 2, 1, 6], 'SelectWord tab') ;
is_deeply([$buffer->GetModificationPosition()], [1, 6], 'SelectWord tab') ;


#ExtendSelectionToBeginingOfWord
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

$buffer->SetModificationPosition(1, 4) ;
$buffer->ExtendSelectionToBeginingOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'ExtendSelectionToBeginingOfWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 2, 1, 4], 'ExtendSelectionToBeginingOfWord') ;

$buffer->SetModificationPosition(1, 3) ;
$buffer->ExtendSelectionToBeginingOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [1, 2], 'ExtendSelectionToBeginingOfWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [1, 2, 1, 4], 'ExtendSelectionToBeginingOfWord') ;

$buffer->ClearSelection() ;
$buffer->SetModificationPosition(0, 3) ;
$buffer->ExtendSelectionToBeginingOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 1], 'ExtendSelectionToBeginingOfWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 0, 3], 'ExtendSelectionToBeginingOfWord') ;

$buffer->SetSelectionAnchor(1, 4) ;
$buffer->SetModificationPosition(0, 3) ;
$buffer->ExtendSelectionToBeginingOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [0, 1], 'ExtendSelectionToBeginingOfWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 1, 1, 4], 'ExtendSelectionToBeginingOfWord') ;


$buffer->Reset() ;
$buffer->Insert($text) ;

#ExtendSelectionToBeginingOfWord
$buffer->SetModificationPosition(6, 10) ;
$buffer->ExtendSelectionToBeginingOfWord() ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'ExtendSelectionToBeginingOfWord') ;
is_deeply([$buffer->GetSelectionBoundaries()], [6, 0, 6, 10], 'ExtendSelectionToBeginingOfWord') ;

