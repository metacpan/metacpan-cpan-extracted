#-*- perl -*-

use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;
use Test::Differences ;

use strict ;
use warnings ;

use Test::More tests => 72 ;
use Test::Exception ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::InsertDelete') ;
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

#InsertNewLineBeforeCurrent
$buffer->SetModificationPosition(0, 5) ;
$buffer->InsertNewLineBeforeCurrent() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'InsertNewLineBeforeCurrent') ;
is_deeply([$buffer->GetModificationPosition()], [1, 5], 'InsertNewLineBeforeCurrent') ;
is($buffer->GetNumberOfLines, 9	, 'InsertNewLineBeforeCurrent') ;

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(1, 10) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->InsertNewLineBeforeCurrent() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'InsertNewLineBeforeCurrent') ;
is_deeply([$buffer->GetModificationPosition()], [2, 10], 'InsertNewLineBeforeCurrent') ;
is($buffer->GetNumberOfLines, 9	, 'InsertNewLineBeforeCurrent') ;

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(7, 10) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->InsertNewLineBeforeCurrent() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'InsertNewLineBeforeCurrent') ;
is_deeply([$buffer->GetModificationPosition()], [8, 10], 'InsertNewLineBeforeCurrent') ;
is($buffer->GetNumberOfLines, 9	, 'InsertNewLineBeforeCurrent') ;


#DeleteToBeginingOfWord
$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

# invalid end position, stay put
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(7, 10) ;
$buffer->DeleteToBeginingOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [7, 10, 7, 10], 'DeleteToBeginingOfWord invalid position') or diag $buffer->PrintPositionData('DeleteToBeginingOfWord invalid position') ;
is_deeply([$buffer->GetModificationPosition()], [7, 10], 'DeleteToBeginingOfWord invalid position') ;
is($buffer->GetNumberOfLines, 8	, 'DeleteToBeginingOfWord invalid position') ;

# invalid position
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(6, 10) ;
$buffer->DeleteToBeginingOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteToBeginingOfWord') or diag $buffer->PrintPositionData('DeleteToBeginingOfWord') ;
is_deeply([$buffer->GetModificationPosition()], [6, 0], 'DeleteToBeginingOfWord') ;
is($buffer->GetNumberOfLines, 8	, 'DeleteToBeginingOfWord') ;
is($buffer->GetLineText(6), '', 'DeleteToBeginingOfWord') ;
is($buffer->GetLineText(7), '', 'DeleteToBeginingOfWord') ;

#~ #selection anchor before word
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->SetModificationPosition(6, 3) ;
$buffer->DeleteToBeginingOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteToBeginingOfWord') ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'DeleteToBeginingOfWord') ;
is($buffer->GetNumberOfLines, 6	, 'DeleteToBeginingOfWord') ;

$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

hi something
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->SetModificationPosition(6, 3) ;
$buffer->DeleteToBeginingOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteToBeginingOfWord') ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'DeleteToBeginingOfWord') ;
is($buffer->GetNumberOfLines, 6	, 'DeleteToBeginingOfWord') ;

#DeleteToEndOfWord
$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

# invalid end position, saty put
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(7, 10) ;
$buffer->DeleteToEndOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [7, 10, 7, 10], 'DeleteToEndOfWord invalid position') or diag $buffer->PrintPositionData('DeleteToEndOfWord invalid position') ;
is_deeply([$buffer->GetModificationPosition()], [7, 10], 'DeleteToEndOfWord invalid position') ;
is($buffer->GetNumberOfLines, 8	, 'DeleteToEndOfWord invalid position') ;

# invalid position
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(6, 5) ;
$buffer->DeleteToEndOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteToEndOfWord') or diag $buffer->PrintPositionData('DeleteToEndOfWord') ;
is_deeply([$buffer->GetModificationPosition()], [6, 5], 'DeleteToEndOfWord') ;
is($buffer->GetNumberOfLines, 8	, 'DeleteToEndOfWord') ;
is($buffer->GetLineText(6), 'somet', 'DeleteToEndOfWord') ;
is($buffer->GetLineText(7), '', 'DeleteToEndOfWord') ;

#~ #selection anchor before word
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->SetModificationPosition(6, 3) ;
$buffer->DeleteToEndOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteToEndOfWord') ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'DeleteToEndOfWord') ;
is($buffer->GetNumberOfLines, 6	, 'DeleteToEndOfWord') ;
is($buffer->GetLineText(4), '     ', 'DeleteToEndOfWord') ;

$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

somthing1 something2
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(4, 5, 6, 7) ;
$buffer->SetModificationPosition(6, 1) ;
$buffer->DeleteToEndOfWord() ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'DeleteToEndOfWord') ;
is_deeply([$buffer->GetModificationPosition()], [4, 5], 'DeleteToEndOfWord') ;
is($buffer->GetNumberOfLines, 6	, 'DeleteToEndOfWord') ;
is($buffer->GetLineText(4), '      something2', 'DeleteToEndOfWord') ;


#InsertTab
#--------------------------------
$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

# simple insertion
my $expected_text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line\t 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(3, 4) ;
$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab no selection') ;


$expected_text = <<EOT ;
line 1 - 1
line 2 - 2 2   \t
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(1, 15) ;
$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab no selection') ;


$expected_text = <<EOT ;
line 1 - 1
\tline 2 - 2 2
\tline 3 - 3 3 3
\tline 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(1, 15) ;
$buffer->SetSelectionBoundaries(1, 0, 4, 0) ;
$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab') ;
is_deeply([$buffer->GetSelectionBoundaries()] ,[1, 0, 4, 0], 'Selection OK') ;

$expected_text = <<EOT ;
line 1 - 1
\t\tline 2 - 2 2
\tline 3 - 3 3 3
\tline 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(1, 0, 2, 0) ;
$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab') ;
is_deeply([$buffer->GetSelectionBoundaries()] ,[1, 0, 2, 0], 'Selection OK') ;

$expected_text = <<EOT ;
line\t 1 - 1
\t\tline 2 - 2 2
\tline 3 - 3 3 3
\tline 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->SetModificationPosition(1, 0) ;
$buffer->SetSelectionBoundaries(0, 4, 0, 6) ;
$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab') ;
is_deeply([$buffer->GetSelectionBoundaries()] ,[0, 4, 0, 6], 'Selection OK') ;
is_deeply([$buffer->GetModificationPosition()], [1, 0], 'InsertTab') ;

$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(4, 0, 6, 0) ;
lives_ok {$buffer->InsertTab() ;} 'InsertTab in non existing line' ;
eq_or_diff([$buffer->GetSelection()->GetBoundaries()], [4, 0, 5, 0], 'Boxed selection') ;

is($buffer->GetLineText(4), "\tline 5 - 5 5 5 5 5", 'InsertTab') ;
is($buffer->GetLineText(5), '', 'InsertTab') ;

#RemoveTabFromSelection
# ------------------------

$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

#~ #------------

$expected_text = <<EOT ;
line 1 - 1
\tline 2 - 2 2
\tline 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(1, 0, 3, 0) ;

$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab') ;

$buffer->RemoveTabFromSelection() ;
is($buffer->CompareText($text), '', 'RemoveTabFromSelection') ;

#------------

$expected_text = <<EOT ;
\tline 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 0, 0, 4) ;

$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab') ;

$buffer->RemoveTabFromSelection() ;
is($buffer->CompareText($text), '', 'RemoveTabFromSelection') ;

#------------

$expected_text = <<EOT ;
\tline 1 - 1
\tline 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 0, 1, 4) ;

$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab') ;

$buffer->RemoveTabFromSelection() ;
is($buffer->CompareText($text), '', 'RemoveTabFromSelection') ;

#------------

$expected_text = <<EOT ;
line\t 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;
$buffer->SetSelectionBoundaries(0, 4, 0, 4) ;

$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab empty selection') ;

$expected_text = <<EOT ;
line\t 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 4, 0, 5) ;

$buffer->InsertTab() ;
is($buffer->CompareText($expected_text), '', 'InsertTab empty selection') ;

$buffer->RemoveTabFromSelection() ;
is($buffer->CompareText($text), '', 'RemoveTabFromSelection') ;

# SetText
$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$expected_text = <<EOT ;
use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;
EOT


$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetText($expected_text) ;
is($buffer->CompareText($expected_text), '', 'SetText') ;

$expected_text = "no new line" ;
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetText($expected_text) ;
is($buffer->CompareText($expected_text), '', 'SetText') ;

$expected_text = "\nnew line and text" ;
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetText($expected_text) ;
is($buffer->CompareText($expected_text), '', 'SetText') ;

$expected_text = "text\nnew line and text" ;
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetText($expected_text) ;
is($buffer->CompareText($expected_text), '', 'SetText') ;

my $setup = <<'EOS' ;
my $text = "original text" ;
$buffer->Reset() ;
$buffer->Insert($text) ;
EOS

my $command = <<'EOC' ;
my $expected_text = "\nnew line and text\nother text\nstill another text" ;

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::InsertDelete') ;
$buffer->SetText($expected_text) ;
EOC

is(TestDoUndo($command, $setup), 1, 'test undo after SetText') ;
