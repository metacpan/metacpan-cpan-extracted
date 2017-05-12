# -*- perl -*-

use strict ;

use Data::Hexdumper ;

use Test::More tests => 89 ;
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

$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

is_deeply([$buffer->ReplaceOccurence('not_found', 'yasmin')], [undef, undef, undef, undef], 'ReplaceOccurence non existing') ;
is_deeply([$buffer->ReplaceOccurence(undef, 'yasmin')], [undef, undef, undef, undef], 'Found occurence') ;
is_deeply([$buffer->ReplaceOccurence(undef, '')], [undef, undef, undef, undef], 'Found occurence') ;
is_deeply([$buffer->ReplaceOccurence(undef, undef)], [undef, undef, undef, undef], 'Found occurence') ;

($expected_text = $buffer->GetText()) =~ s/1/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('1', 'yasmin')], [0, 5, '1', 'yasmin'], 'Found occurence') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

($expected_text = $buffer->GetText()) =~ s/1/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('1', 'yasmin')], [0, 14, '1', 'yasmin'], 'Found occurence') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('2', 'yasmin')], [1, 5, '2', 'yasmin'], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

is_deeply([$buffer->ReplaceOccurence('6', 'yasmin')], [undef, undef, undef, undef], 'Search occurence 6') ;

#position outside line
$buffer->SetModificationPosition(3, 50) ;
is_deeply([$buffer->ReplaceOccurence('1', 'yasmin')], [undef, undef, undef, undef], 'Search outside line') ;

# Replacement has \\n"
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2/yasmin\n/ ;
is_deeply([$buffer->ReplaceOccurence('2', "yasmin\n")], [1, 14, '2', "yasmin\n"], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

#Replacement is ''" 
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2// ;
is_deeply([$buffer->ReplaceOccurence('2', '')], [2, 1, '2', ''], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# Regex find
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/..n[a-z]/regex/ ;
is_deeply([$buffer->ReplaceOccurence(qr/..n[a-z]/, 'regex')], [0, 0, 'line', 'regex'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# Regex find and replace
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/..(n[a-z])/xx$1/ ;
is_deeply([$buffer->ReplaceOccurence(qr/..(n[a-z])/, 'xx$1')], [1, 0, 'line', 'xxne'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# find and replace again
# the cursor is moved the length of the replcaement
$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;

$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/l/l/ ;
is_deeply([$buffer->ReplaceOccurence(qr/l/, 'l')], [0, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(0, 1) ;

($expected_text = $buffer->GetText()) =~ s/l/l/ ;
is_deeply([$buffer->ReplaceOccurence(qr/l/, 'l')], [1, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(1, 1) ;

($expected_text = $buffer->GetText()) =~ s/l/l/ ;
is_deeply([$buffer->ReplaceOccurence(qr/l/, 'l')], [2, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(2, 1) ;

#-----------------------------------------------------
my @boundaries = (2, 4, 5, 6) ;

$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

is_deeply([$buffer->ReplaceOccurence('not_found', 'yasmin')], [undef, undef, undef, undef], 'ReplaceOccurence non existing') ;
is_deeply([$buffer->ReplaceOccurence(undef, 'yasmin')], [undef, undef, undef, undef], 'Found occurence') ;
is_deeply([$buffer->ReplaceOccurence(undef, '')], [undef, undef, undef, undef], 'Found occurence') ;
is_deeply([$buffer->ReplaceOccurence(undef, undef)], [undef, undef, undef, undef], 'Found occurence') ;

($expected_text = $buffer->GetText()) =~ s/1/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('1', 'yasmin')], [0, 5, '1', 'yasmin'], 'Found occurence') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

($expected_text = $buffer->GetText()) =~ s/1/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('1', 'yasmin')], [0, 14, '1', 'yasmin'], 'Found occurence') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('2', 'yasmin')], [1, 5, '2', 'yasmin'], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

is_deeply([$buffer->ReplaceOccurence('6', 'yasmin')], [undef, undef, undef, undef], 'Search occurence 6') ;

#position outside line
$buffer->SetModificationPosition(3, 50) ;
is_deeply([$buffer->ReplaceOccurence('1', 'yasmin')], [undef, undef, undef, undef], 'Search outside line') ;

# Replacement has \\n"
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2/yasmin\n/ ;
is_deeply([$buffer->ReplaceOccurence('2', "yasmin\n")], [1, 14, '2', "yasmin\n"], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

#Replacement is ''" 
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2// ;
is_deeply([$buffer->ReplaceOccurence('2', '')], [2, 1, '2', ''], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# Regex find
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/..n[a-z]/regex/ ;
is_deeply([$buffer->ReplaceOccurence(qr/..n[a-z]/, 'regex')], [0, 0, 'line', 'regex'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# Regex find and replace
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/..(n[a-z])/xx$1/ ;
is_deeply([$buffer->ReplaceOccurence(qr/..(n[a-z])/, 'xx$1')], [1, 0, 'line', 'xxne'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# find and replace again
# the cursor is moved the length of the replcaement
$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;
$expected_text = $buffer->GetText() ;

$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->ReplaceOccurence(qr/l/, 'l')], [0, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(0, 1) ;

is_deeply([$buffer->ReplaceOccurence(qr/l/, 'l')], [1, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(1, 1) ;

is_deeply([$buffer->ReplaceOccurence(qr/l/, 'l')], [2, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(2, 1) ;

$buffer->SetModificationPosition(0, 0) ;
eq_or_diff([$buffer->ReplaceOccurence(qr/l/, 'l', 2, 0)], [2, 0, 'l', 'l'], 'Found and replaced with regex search') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
$buffer->SetModificationPosition(2, 1) ;

#invalid regex in find
my $redefined_sub_output = '' ;
$buffer->ExpandWith('PrintError', sub {$redefined_sub_output = $_[1]}) ;
lives_ok {$buffer->FindOccurence("(l", 2, 0)} 'invalid regex in FindOccurence' ;
ok($redefined_sub_output =~ /^Error in FindOccurence: Unmatched \( in regex/, 'invalid regex detected (1)') ;

#invalid regex in replace
$redefined_sub_output = '' ;
$buffer->SetModificationPosition(0, 0) ;
lives_ok {$buffer->ReplaceOccurence("(l", 'L', 2, 0)} 'invalid regex in ReplaceOccurence' ;
ok($redefined_sub_output =~ /^Error in FindOccurence: Unmatched \( in regex/, 'invalid regex detected (2)')
	or diag "*** $redefined_sub_output " ;

{
#invalid replacement
$redefined_sub_output = '' ;
$buffer->SetModificationPosition(0, 0) ;

warning_like 
	{
	lives_ok {$buffer->ReplaceOccurence(qr/l/, '$2', 2, 0)} 'invalid replacement doesn\'t die' ;
	} qr'Use of uninitialized value in substitution iterator', 'invalid replacement warning' ;
}

#-----------------------------------------
# Replace in selection
$text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->Insert($text) ;

$buffer->SetModificationPosition(0, 0) ;
@boundaries = (2, 4, 5, 6) ;
$buffer->SetSelectionBoundaries(@boundaries) ;

# catch error
use Test::Exception ;
dies_ok {$buffer->ReplaceOccurenceWithinBoundaries(undef) ;} 'invalid boundaries' ;
dies_ok {$buffer->ReplaceOccurenceWithinBoundaries(undef, undef, undef, undef, 5) ;} 'invalid boundaries2' ;

#undef regex
$buffer->SetModificationPosition(7, 0) ;
($match_line, $match_character, $match_word) = $buffer->ReplaceOccurenceWithinBoundaries(undef, undef, @boundaries) ;
is($match_line, undef, 'undef regex is ignored') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'unchanged selection boundaries') ;

#empty regex
$buffer->SetModificationPosition(7, 0) ;
($match_line, $match_character, $match_word) = $buffer->ReplaceOccurenceWithinBoundaries('', '', @boundaries) ;
is($match_line, undef, 'Empty regex is ignored') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'selection unchanged when no match') ;

# Search moves to selection start
$buffer->SetSelectionBoundaries(@boundaries) ;
$buffer->SetModificationPosition(7, 0) ;
eq_or_diff([$buffer->ReplaceOccurenceWithinBoundaries('line', 'X', @boundaries)], [3, 4, 'line', 'X'], 'Search moves to selection start') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'selection removed') ;


# add test
# Search from position within boundaries
$buffer->SetSelectionBoundaries(@boundaries) ;
$buffer->SetModificationPosition(7, 0) ;
eq_or_diff([$buffer->ReplaceOccurenceWithinBoundaries('line', 'X', @boundaries)], [4, 5, 'line', 'X'], 'Search moves to selection start') ;
is_deeply([$buffer->GetSelectionBoundaries()], [-1, -1, -1, -1], 'selection removed') ;

# Search without result stays at the same modification position
$buffer->SetSelectionBoundaries(@boundaries) ;
$buffer->SetModificationPosition(7, 0) ;
is_deeply([$buffer->ReplaceOccurenceWithinBoundaries('not to be found', '$1', @boundaries)], [undef], 'no match') ;
is_deeply([$buffer->GetModificationPosition()], [7, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'selection removed') ;

#find outside boundary
$buffer->SetSelectionBoundaries(@boundaries) ;
$buffer->SetModificationPosition(0, 0) ;
is_deeply([$buffer->ReplaceOccurenceWithinBoundaries('something', '$1', @boundaries)], [undef], 'match outside boundaries') ;
eq_or_diff([$buffer->GetModificationPosition()], [0, 0], 'stay at the same position') ;
is_deeply([$buffer->GetSelectionBoundaries()], [@boundaries], 'selection unchanged when no match') ;

#invalid replacement
{
$buffer->SetSelectionBoundaries(@boundaries) ;
$buffer->SetModificationPosition(7, 0) ;

warning_like 
	{
	is_deeply([$buffer->ReplaceOccurenceWithinBoundaries('3', '$2', @boundaries)], [2, 8, '3', ''], 'match outside boundaries') ;
	} qr'Use of uninitialized value in substitution iterator', 'invalid replacement warning' ;
}

TODO:
{
local $TODO = 'Test with search position passed as arguments' ;
fail($TODO) ;
}

$buffer->ExpandWith('TestInvalidBoundaries2') ;
$buffer->TestInvalidBoundaries2(-1, 4, 5, 6) ;
$buffer->TestInvalidBoundaries2(2, -4, 5, 6) ;
$buffer->TestInvalidBoundaries2(2, 4, 5000, 6) ;
$buffer->TestInvalidBoundaries2(2, 4, 5000, -1) ;
$buffer->TestInvalidBoundaries2(2, 4, 1, 6) ;
$buffer->TestInvalidBoundaries2(2, 4, -3, 6) ;

sub TestInvalidBoundaries2
{
my ($buffer, @boundaries) = @_ ;

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

$buffer->SetModificationPosition(0, 0) ;
$buffer->SetSelectionBoundaries(@boundaries) ;

# the tests
$buffer->SetModificationPosition(0, 0) ;
dies_ok {$buffer->ReplaceOccurenceWithinBoundaries('3', @boundaries) ;}  'invalid boundaries' ;
}

