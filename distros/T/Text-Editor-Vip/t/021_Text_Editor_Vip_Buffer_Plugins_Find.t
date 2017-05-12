# -*- perl -*-

use strict ;

use Data::Hexdumper ;

use Test::More tests => 106 ;
use Test::Differences ;
use Test::Exception ;
use Test::Warn ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

#Find Forewards
#-------------------------------

my $buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Insert($text) ;

my ($match_line, $match_character, $match_word) ;
my $expected_text  ;

($match_line, $match_character, $match_word) = $buffer->FindOccurence(undef) ;
is($match_line, undef, 'Undef regex is ignored') ;

($match_line, $match_character, $match_word) = $buffer->FindOccurence('') ;
is($match_line, undef, 'empty regex is ignored') ;

($match_line, $match_character, $match_word) = $buffer->FindOccurence('cant_be_found') ;
is($match_line, undef, 'non matching regex is ignored') ;

($match_line, $match_character, $match_word) = $buffer->FindOccurence('line') ;
is($match_line, undef, 'At the end of buffer') ;

$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->FindOccurence('1')], [0, 5, '1'], 'Found occurence') ;

#directely passed arguments
is_deeply([$buffer->FindOccurence('1', 0, 0)], [0, 5, '1'], 'Found occurence 1') ;
is_deeply([$buffer->FindOccurence('2', 0, 0)], [1, 5, '2'], 'Found occurence 2') ;
is_deeply([$buffer->FindOccurence('5', 0, 0)], [4, 5, '5'], 'Found occurence 5') ;
is_deeply([$buffer->FindOccurence('6', 0, 0)], [undef, undef, undef], 'Search occurence 6') ;

#position outside line, buffer
is_deeply([$buffer->FindOccurence('1', 0, 50)], [undef, undef, undef], 'Search outside line') ;
is_deeply([$buffer->FindOccurence('1', 50, 0)], [undef, undef, undef], 'Search outside buffer') ;

#selection, position, text
$buffer->SetSelectionBoundaries(0, 5, 3, 4) ;
is_deeply([$buffer->FindOccurence('1', 0, 0)], [0, 5, '1'], 'Found occurence 1') ;

$buffer->SetSelectionBoundaries(10, 5, 13, 4) ;
is_deeply([$buffer->FindOccurence('1', 0, 0)], [0, 5, '1'], 'Found occurence 1') ;

$buffer->SetModificationPosition(5, 0) ;
is_deeply([$buffer->FindOccurence('1', 0, 0)], [0, 5, '1'], 'Found occurence 1') ;

$buffer->SetSelectionBoundaries(0, 0, 0, 0) ;
is_deeply([$buffer->FindOccurence('1', 0, 0)], [0, 5, '1'], 'Found occurence 1') ;
is($buffer->GetText(), $text, 'Text still the same') ;
is($buffer->GetSelectionText(), '', 'GetSelectionText empty') ;

#FindNextOccurence
$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->FindNextOccurence()], [0, 5, '1'], 'FindNextOccurence') ;

$buffer->SetModificationPosition(0, 5) ;
is_deeply([$buffer->FindNextOccurence()], [0, 9, '1'], 'FindNextOccurence') ;

# FindNextOccurenceForCurrentWord
$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->FindNextOccurenceForCurrentWord()], [1, 0, 'line'], 'FindNextOccurenceForCurrentWord') ;

$buffer->SetModificationPosition(1, 0) ;
is_deeply([$buffer->FindNextOccurenceForCurrentWord()], [2, 0, 'line'], 'FindNextOccurenceForCurrentWord') ;

$buffer->SetModificationPosition(4, 0) ;

is_deeply([$buffer->FindNextOccurenceForCurrentWord()], [undef, undef, undef], 'FindNextOccurenceForCurrentWord') ;

# Regex search
is_deeply([$buffer->FindOccurence(qr/..n[a-z]/, 0, 0)], [0, 0, 'line'], 'Found occurence with regex') ;

#Find Backwards
#-------------------------------

$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;

($match_line, $match_character, $match_word) = $buffer->FindOccurenceBackwards(undef) ;
is($match_line, undef, 'Undef regex is ignored') ;

($match_line, $match_character, $match_word) = $buffer->FindOccurenceBackwards('') ;
is($match_line, undef, 'empty regex is ignored') ;

($match_line, $match_character, $match_word) = $buffer->FindOccurenceBackwards('cant_be_found') ;
is($match_line, undef, 'non matching regex is ignored') ;

($match_line, $match_character, $match_word) = $buffer->FindOccurenceBackwards('line') ;
#~ is_deeply([$buffer->FindOccurenceBackwards('1')], [undef, undef, undef], 'Found occurence') ;
is_deeply([$buffer->FindOccurenceBackwards('2')], [1, 11, '2'], 'Found occurence') ;

$buffer->SetModificationPosition(1, 10) ;
is_deeply([$buffer->FindOccurenceBackwards('2')], [1, 9, '2'], 'Found occurence') ;

#directely passed arguments
is_deeply([$buffer->FindOccurenceBackwards('1', 0, 0)], [undef, undef, undef], 'Search occurence 1') ;

is_deeply([$buffer->FindOccurenceBackwards('1', 0, 10)], [0, 9, '1'], 'Found occurence 1') ;
is_deeply([$buffer->FindOccurenceBackwards('2', 1, 9)], [1, 5, '2'], 'Found occurence 2') ;
is_deeply([$buffer->FindOccurenceBackwards('5', 4, 7)], [4, 5, '5'], 'Found occurence 5') ;
is_deeply([$buffer->FindOccurenceBackwards('6', 0, 0)], [undef, undef, undef], 'Search occurence 6') ;

#position outside line, buffer
is_deeply([$buffer->FindOccurenceBackwards('1', 0, 50)], [0, 9, '1'], 'Search outside line') ;
is_deeply([$buffer->FindOccurenceBackwards('1', 50, 0)], [0, 9, '1'], 'Search outside buffer') ;

#selection, position, text
$buffer->SetSelectionBoundaries(0, 5, 3, 4) ;
is_deeply([$buffer->FindOccurenceBackwards('1', 0, 10)], [0, 9, '1'], 'Found occurence 1') ;

$buffer->SetSelectionBoundaries(10, 5, 13, 4) ;
is_deeply([$buffer->FindOccurenceBackwards('1', 1, 0)], [0, 9, '1'], 'Found occurence 1') ;

$buffer->SetModificationPosition(0, 10) ;
is_deeply([$buffer->FindOccurenceBackwards('2', 1, 10)], [1, 9, '2'], 'Found occurence') ;

$buffer->SetSelectionBoundaries(0, 0, 0, 0) ;
is_deeply([$buffer->FindOccurenceBackwards('2', 1, 10)], [1, 9, '2'], 'Found occurence 1') ;
is($buffer->GetText(), $text, 'Text still the same') ;
is($buffer->GetSelectionText(), '', 'GetSelectionText empty') ;
is_deeply([0, 0, 0, 0], [$buffer->GetSelectionBoundaries()], 'GetSelectionText unchanged selection') ;

#FindPreviousOccurence
$buffer->SetModificationPosition(1, 11) ;
is_deeply([$buffer->FindPreviousOccurence()], [1, 9 , '2'], 'FindPreviousOccurence') ;

$buffer->SetModificationPosition(1, 8) ;
is_deeply([$buffer->FindPreviousOccurence()], [1, 5, '2'], 'FindPreviousOccurence') ;

$buffer->SetModificationPosition(1, 5) ;
is_deeply([$buffer->FindPreviousOccurence()], [undef, undef, undef], 'FindPreviousOccurence') ;

# FindPreviousOccurenceForCurrentWord
$buffer->SetModificationPosition(1, 0) ;
is_deeply([$buffer->FindPreviousOccurenceForCurrentWord()], [0, 0, 'line'], 'FindNextOccurenceForCurrentWord') ;

$buffer->SetModificationPosition(3, 0) ;
is_deeply([$buffer->FindPreviousOccurenceForCurrentWord()], [2, 0, 'line'], 'FindNextOccurenceForCurrentWord') ;

$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->FindPreviousOccurenceForCurrentWord()], [undef, undef, undef], 'FindNextOccurenceForCurrentWord') ;

# search in selection
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
my @boundaries = (2, 4, 5, 6) ;
$buffer->SetSelectionBoundaries(@boundaries) ;

# catch error
use Test::Exception ;
dies_ok {$buffer->FindOccurenceWithinBoundaries(undef) ;} 'invalid boundaries' ;
dies_ok {$buffer->FindOccurenceWithinBoundaries(undef, undef, undef, undef, 5) ;} 'invalid boundaries 2' ;

#undef regex
$buffer->SetModificationPosition(7, 0) ;
($match_line, $match_character, $match_word) = $buffer->FindOccurenceWithinBoundaries(undef, @boundaries) ;
is($match_line, undef, 'empty regex is ignored') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'unchanged selection boundaries') ;

#empty regex
$buffer->SetModificationPosition(7, 0) ;
($match_line, $match_character, $match_word) = $buffer->FindOccurenceWithinBoundaries('', @boundaries) ;
is($match_line, undef, 'Undef regex is ignored') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'unchanged selection boundaries') ;

# search boundaries are not related to the selection
$buffer->SetSelectionBoundaries(@boundaries) ;

# Search moves to selection start
$buffer->SetModificationPosition(7, 0) ;
is_deeply([$buffer->FindOccurenceWithinBoundaries('line', @boundaries)], [3, 4, 'line'], 'Search moves to selection start') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'unchanged selection boundaries') ;

# Searchwithout result stays at the same modification position
$buffer->SetModificationPosition(7, 0) ;
is_deeply([$buffer->FindOccurenceWithinBoundaries('not to be found', @boundaries)], [undef], 'no match') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'unchanged selection boundaries') ;

#find outside boundary
$buffer->SetSelectionBoundaries(@boundaries) ;
$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->FindOccurenceWithinBoundaries('something', @boundaries)], [undef], 'match outside boundaries') ;
eq_or_diff([$buffer->GetModificationPosition()], [0, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'unchanged selection boundaries') ;

$buffer->ExpandWith('TestInvalidBoundaries') ;
$buffer->TestInvalidBoundaries(-1, 4, 5, 6) ;
$buffer->TestInvalidBoundaries(2, -4, 5, 6) ;
$buffer->TestInvalidBoundaries(2, 4, 5000, 6) ;
$buffer->TestInvalidBoundaries(2, 4, 5000, -1) ;
$buffer->TestInvalidBoundaries(2, 4, 1, 6) ;
$buffer->TestInvalidBoundaries(2, 4, -3, 6) ;


sub TestInvalidBoundaries
{
my ($buffer, @boundaries) = @_ ;


$buffer->Reset() ;
$buffer->Insert($text) ;

$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(@boundaries) ;

# the tests
$buffer->SetModificationPosition(0, 0) ;
dies_ok {$buffer->FindOccurenceWithinBoundaries('3', @boundaries) ;}  'invalid boundaries' ;
}

for
	(
	[$text, undef, undef, 'l...', [3, 4, 'line'], 'undefined start position'] ,
	[$text, -1   , -1   , 'l...', [3, 4, 'line'], 'invalid start position 1'] ,
	[$text, 50   , 50   , 'l...', [3, 4, 'line'], 'invalid start position 2'] ,
	[$text, 3    , -5   , 'l...', [3, 4, 'line'], 'invalid start position 3'] ,
	[$text, 3    , 5000 , 'l...', [4, 5, 'line'], 'invalid start position 4'] ,
	[$text, 3    , undef, 'l...', [3, 4, 'line'], 'invalid start position 5'] ,
	[$text, undef, 5000 , 'l...', [3, 4, 'line'], 'invalid start position 6'] ,
	[$text, 3    , undef, 'l...', [3, 4, 'line'], 'invalid start position 7'] ,
	[$text, 1    , 1    , 'l...', [3, 4, 'line'], 'start position before boundaries'] ,
	[$text, 5    , 7    , 'l...', [3, 4, 'line'], 'start position after boundaries'] ,
	[$text, 3    , 5    , 'l...', [4, 5, 'line'], 'second match'] ,
	)
	{
	TestFindOccurenceWithinBoundaries(@$_) ;
	}

sub TestFindOccurenceWithinBoundaries
{
my ($text, $start_line, $start_character, $regex, $result, $message) = @_ ;

my @boundaries = (2, 4, 5, 6) ;
my ($match_line, $match_character, $match_word, $replacement) ;

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 0, 3, 3) ;
$buffer->SetModificationPosition(0, 0) ;

eq_or_diff([$buffer->FindOccurenceWithinBoundaries($regex, @boundaries, $start_line, $start_character )], $result, $message) ;
eq_or_diff([$buffer->GetModificationPosition()], [0, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [0, 0, 3, 3], 'unchanged selection boundaries') ;
}

TODO:
{
local $TODO = "Regex search backwards" ;
fail($TODO) ;
}
