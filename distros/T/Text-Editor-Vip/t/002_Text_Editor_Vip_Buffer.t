# -*- perl -*-

# t/002_load.t - check module loading and create testing directory
# proudly stole some tests from Text::Buffer

use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
my ($text, $expected_text) = ('', undef) ;

use Test::More tests => 187 ;
use Test::Exception ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

#------------------------------------------------------------------------------------------------- 
# Empty buffer tests

my $buffer = Text::Editor::Vip::Buffer->new();
isa_ok($buffer, 'Text::Editor::Vip::Buffer');

is($buffer->GetNumberOfLines(), 1, 'empty line count') ;
is($buffer->GetLastLineIndex(), 0, 'empty line count') ;
is($buffer->GetModificationLine(), 0, 'line pos is 0' ) ;
is($buffer->GetText(), '', 'new buffer is empty' ) ;
is($buffer->IsBufferMarkedAsEdited(), 0, 'buffer not marked as edited') ;

$buffer->MarkBufferAsEdited() ;
is($buffer->IsBufferMarkedAsEdited(), 1, 'buffer marked as edited') ;

$buffer->MarkBufferAsUnedited() ;
is($buffer->IsBufferMarkedAsEdited(), 0, 'buffer not marked as edited') ;

#------------------------------------------------------------------------------------------------- 
# ExpandWith

$buffer = Text::Editor::Vip::Buffer->new();

dies_ok {$buffer->PrintError("should die") ;} 'Default method dies' ;

my $redefined_sub_output = '' ;
my $expected_output = 'Redefined PrintError is working' ;
$buffer->ExpandWith('PrintError', sub {$redefined_sub_output = $_[1]}) ;
lives_ok {$buffer->PrintError($expected_output) ;} 'Calling added method' ;
is($redefined_sub_output , $expected_output, 'Calling added method') ;

dies_ok 
	{
	$buffer->ExpandWith() ;
	} 'Expanding with nothing' ;

dies_ok 
	{
	$buffer->ExpandWith('') ;
	} 'Expanding with unnamed sub' ;

dies_ok 
	{
	$buffer->ExpandWith('hi') ;
	} 'Expanding with unexisting named sub' ;

dies_ok 
	{
	$buffer->ExpandWith('hi', 'there') ;
	} 'Expanding with non sub ref' ;

#~ dies_ok 
	#~ {
	#~ $buffer->ExpandWith(''") ;
	#~ }'' ;

# indenter
sub my_indenter
	{
	# modification position is set at the new line 
	
	my $this = shift ; # the buffer
	my $line_index = shift ; # usefull if we indent depending on previous lines
	
	my $undo_block = new Text::Editor::Vip::CommandBlock($this, "IndentNewLine(\$buffer, $line_index) ;", '   #', '# undo for IndentNewLine() ;', '   ') ;
	$this->Insert('   ') ;  # some silly indentation
	$this->MarkBufferAsEdited() ;
	}

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->ExpandWith('IndentNewLine', \&my_indenter) ;
$buffer->Insert("hi\nThere\nWhats\nYour\nName\n") ;
is($buffer->GetLineText(1), "   There", "Same text") ;

#------------------------------------------------------------------------------------------------- 
# LoadAndExpandWith
$buffer->Reset() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Display') ;
$buffer->SetTabSize(3) ;
is($buffer->GetTabSize(), 3, 'LoadAndExpandWith suceeded') ;

#------------------------------------------------------------------------------------------------- 
# ExpandedWithOrLoad
$buffer = Text::Editor::Vip::Buffer->new();
dies_ok {$buffer->SomeSub() ;} 'Unknown sub' ;

my $sub_exists = 0 ;
$sub_exists = $buffer->ExpandedWithOrLoad('SetTabSize', 'Text::Editor::Vip::Buffer::Plugins::Display') ;

is($sub_exists , 0, "sub didn't exist before module loading") ;
lives_ok {$buffer->SetTabSize(3) ;} 'Known sub' ;

$buffer->SetTabSize(3) ;
$sub_exists = $buffer->ExpandedWithOrLoad('SetTabSize', 'Text::Editor::Vip::Buffer::Plugins::Display') ;
is($sub_exists , 1, "sub existed no loading needed") ;

$buffer->PrintExpansionHistory() ;

#------------------------------------------------------------------------------------------------- 
# Position
$buffer = Text::Editor::Vip::Buffer->new();

is($buffer->GetModificationLine(), 0, 'line pos is 0' ) ;
is($buffer->GetModificationCharacter(), 0, 'char pos is 0' ) ;

my ($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 0 && $character == 0, 'position is OK' ) ;

$buffer->Insert('Bar') ;
is($buffer->GetModificationLine(), 0, 'line pos is 0' ) ;
is($buffer->GetModificationCharacter(), 3, 'char pos is 3' ) ;

($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 0 && $character == 3, 'position is OK' ) ;

$buffer->Insert("\nBaz\nFoo\n\n") ;
$buffer->SetModificationPosition(2, 2) ;
($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 2 && $character == 2, 'position is OK' ) ;

$buffer->SetModificationPosition(2, 500) ;
($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 2 && $character == 500, 'position is OK' ) ;

dies_ok {$buffer->SetModificationPosition(10, 0) ;} 'SetModificationPosition died' ;

# offset
$buffer->SetModificationPosition(0, 0) ;

$buffer->OffsetModificationPosition(2, 2) ;
($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 2 && $character == 2, 'position is OK' ) ;

$buffer->OffsetModificationPosition(2, 500) ;
($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 4 && $character == 502, 'position is OK' ) ;

dies_ok {$buffer->OffsetModificationPosition(-1000, 0) ;} 'OffsetModificationPosition died' ;

$buffer->SetModificationPosition(0, 0) ;
is(0, $buffer->OffsetModificationPositionGuarded(0, -1), 'Guarded OK') ;
is(0, $buffer->OffsetModificationPositionGuarded(-1000, 10), 'Guarded OK') ;

($line, $character) = $buffer->GetModificationPosition() ;
ok($line == 0 && $character == 0, 'position unchanged' ) ;

#------------------------------------------------------------------------------------------------- 
# Attributes
ok($buffer->SetLineAttribute(0, 'TEST', [0, [1, 2]]), 'SetAttribute') ;
is_deeply($buffer->GetLineAttribute(0, 'TEST'), [0, [1, 2]], 'GetAttribute') ;

$buffer->DeleteLine(0) ;
is($buffer->GetLineAttribute(0, 'TEST'), undef, 'Get unexisting attribute') ;

#------------------------------------------------------------------------------------------------- 
# Backspace
$buffer = Text::Editor::Vip::Buffer->new();

$buffer->Insert("Line 1\nLine 2") ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->Backspace(1) ;
is($buffer->GetText(), "Line 1\nLine 2", "Same text") ;

$buffer->SetModificationPosition(0, 1) ;
$buffer->Backspace(1) ;
is($buffer->GetText(), "ine 1\nLine 2", "Same text") ;

$buffer->SetModificationPosition(0, 1) ;
$buffer->Backspace(5) ;
is($buffer->GetText(), "ne 1\nLine 2", "Same text") ;

$buffer->SetModificationPosition(1, 0) ;
$buffer->Backspace(1) ;
is($buffer->GetText(), "ne 1Line 2", "Same text") ;

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("AAAAX1 - 1\nBBBB 2 - 2 2") ;

$buffer->SetModificationPosition(1, 0) ;
$buffer->Backspace(1) ;
is($buffer->GetText(), "AAAAX1 - 1BBBB 2 - 2 2", "Backspace") ;

$buffer->Backspace(1) ;
is($buffer->GetText(), "AAAAX1 - BBBB 2 - 2 2", "Backspace") ;

#------------------------------------------------------------------------------------------------- 
# GetLineText 
$buffer = Text::Editor::Vip::Buffer->new(); 

$buffer->Insert(<<EOT) ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

is($buffer->GetLineText(3), 'line 4 - 4 4 4 4', 'Getting a specific line') ;

$buffer->SetModificationLine(4) ;
is($buffer->GetLineText(), 'line 5 - 5 5 5 5 5', 'Getting a specific line') ;

# set an erroneous modification line which 
dies_ok {$buffer->SetModificationLine(10) ; } 'PrintError died' ;

# the modification line didn't change
is($buffer->GetLineText(), 'line 5 - 5 5 5 5 5', 'Getting the current line') ;

#------------------------------------------------------------------------------------------------- 
# GetLineLenght

is($buffer->GetLineLength(3), length('line 4 - 4 4 4 4'), 'Getting a specific line length') ;

$buffer->SetModificationLine(4) ;
is($buffer->GetLineLength(), length('line 5 - 5 5 5 5 5'), 'Getting a specific line') ;

# set an erroneous modification line which 
dies_ok {$buffer->SetModificationLine(10) ; } 'PrintError died' ;

# the modification line didn't change
is($buffer->GetLineLength(), length('line 5 - 5 5 5 5 5'), 'Getting the current line') ;

dies_ok { $buffer->GetLineLength(10) ; } 'PrintError died' ;

#------------------------------------------------------------------------------------------------- 
# ClearLine
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("Line 1\nLine 2") ;

$buffer->ClearLine(0) ;
is($buffer->GetLineLength(0), 0, 'Clearing a specific line') ;


$buffer->SetModificationLine(1) ;
$buffer->ClearLine() ;
is($buffer->GetLineLength(), 0, 'Clearing the modification line') ;

dies_ok { $buffer->ClearLine(10) ; } 'PrintError died' ;

# test undo after ClearLine
is(TestDoUndo('$buffer->ClearLine(0) ;', '$buffer->Insert("Line 1\nLine 2") ;'), 1, 'test undo after ClearLine') ;
is(TestDoUndo('$buffer->ClearLine(1) ;', '$buffer->Insert("Line 1\nLine 2") ;'), 1, 'test undo after ClearLine') ;

#------------------------------------------------------------------------------------------------- 
#DeleteLine
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;
is($buffer->GetNumberOfLines(), 4, 'right line count before deletion') ;
is($buffer->GetLastLineIndex(), 3, 'right line index') ;

$buffer->DeleteLine(0) ;
is($buffer->GetNumberOfLines(), 3, 'right line count after first deletion') ;
is($buffer->GetLineText(0), 'Line 2', 'right line text after first deletion') ;

$buffer->SetModificationLine(1) ;
$buffer->DeleteLine() ;
is($buffer->GetNumberOfLines(), 2, 'right line count after third deletion') ;
is($buffer->GetLineText(), 'Line 4', 'right line text after thirddeletion') ;

dies_ok { $buffer->DeleteLine(10) ; } 'PrintError died' ;


$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;
$buffer->DeleteLine(3) ;
is($buffer->GetNumberOfLines(), 3, 'right line count after last line deletion') ;

# test undo after DeleteLine
is(TestDoUndo('$buffer->DeleteLine(0) ;', '$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;'), 1, 'test undo after DeleteLine') ;
is(TestDoUndo('$buffer->DeleteLine(3) ;', '$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;'), 1, 'test undo after DeleteLine') ;

#------------------------------------------------------------------------------------------------- 
#Delete
#------------------------------------------------------------------------------------------------- 
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;
$buffer->SetModificationPosition(0, 0) ;

my $do_buffer = $buffer->GetDoScript() ;

$buffer->Delete(2) ;
is($buffer->GetNumberOfLines(), 4, 'right line count') ;
is($buffer->GetLineText(0), 'ne 1', 'right line text') ;

is(TestDoUndo('$buffer->Delete(2) ;', $do_buffer), 1, 'test undo after Delete') ;
#----

$do_buffer = $buffer->GetDoScript() ; # include the deletion above

$buffer->Delete(4) ;
is($buffer->GetNumberOfLines(), 4, 'right line count') ;
is($buffer->GetLineText(0), '', 'right line text') ;

is(TestDoUndo('$buffer->Delete(4) ;', $do_buffer), 1, 'test undo after Delete') ;

#----

# Delete at end of line
$do_buffer = $buffer->GetDoScript() ; # include the deletion above

$buffer->Delete(1) ;
is($buffer->GetNumberOfLines(), 3, 'right line count') ;
is($buffer->GetLineText(0), 'Line 2', 'right line text') ;

is(TestDoUndo('$buffer->Delete(1) ;', $do_buffer), 1, 'test undo after Delete') ;

#----

$buffer->SetModificationPosition(0, $buffer->GetLineLength(0)) ;
$do_buffer = $buffer->GetDoScript() ; # include the deletion above

$buffer->Delete(1) ;
is($buffer->GetNumberOfLines(), 2, 'right line count') ;
is($buffer->GetLineText(0), 'Line 2Line 3', 'right line text') ;

is(TestDoUndo('$buffer->Delete(1) ;', $do_buffer), 1, 'test undo after Delete') ;

#----

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;
$buffer->SetModificationPosition(0, $buffer->GetLineLength(0) + 2) ;

$do_buffer = $buffer->GetDoScript() ;

$buffer->Delete(1) ;
is($buffer->GetNumberOfLines(), 3, 'right line count') ;
is($buffer->GetLineText(0), 'Line 1  Line 2', 'right line text') ;

is(TestDoUndo('$buffer->Delete(1) ;', $do_buffer), 1, 'test undo after Delete') ;

#----------------------------------------------------------------------------------
# insert
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("0") ;
is($buffer->GetText(), "0", "inserting 0") ;


$buffer = Text::Editor::Vip::Buffer->new();

$buffer->Insert("bar") ;
is($buffer->GetLineLength(), 3, 'Line length is correct') ;
is($buffer->IsBufferMarkedAsEdited(), 1, 'buffer marked as edited') ;
is($buffer->GetNumberOfLines(), 1, 'correct line count after insert' ) ;

is($buffer->GetText(), "bar", 'buffer contains \'bar\'' ) ;
is(ref($buffer->GetTextAsArrayRef()), 'ARRAY', 'returned an array ref' ) ;
is(scalar(@{$buffer->GetTextAsArrayRef()}), 1, 'has one line' ) ;
is($buffer->GetTextAsArrayRef()->[0], 'bar', 'bar is the content' ) ;

$buffer->Backspace(1) ;
is($buffer->GetNumberOfLines(), 1, 'correct line count after Backspace' ) ;
is($buffer->GetModificationLine(), 0, 'line is 0' ) ;
is($buffer->GetModificationPosition(), 2, 'line pos is 2' ) ;
is($buffer->GetText(), "ba", 'buffer contains \'bar\'' ) ;

$buffer->Insert("\nFoo") ;
is($buffer->GetNumberOfLines(), 2, 'correct line count after Insert' ) ;
is($buffer->GetModificationLine(), 1, 'line is 1' ) ;
is($buffer->GetModificationPosition(), 3, 'line pos is 3' ) ;
is($buffer->GetText(), "ba\nFoo", 'buffer contains \'ba\nFoo\'' ) ;

$buffer->Reset() ;
is($buffer->GetNumberOfLines(), 1, 'empty line count') ;
is($buffer->GetModificationLine(), 0, 'line pos is 0' ) ;
is($buffer->GetText(), '', 'new buffer is empty' ) ;

# still works after Reset?
$buffer->Insert("bar") ;
is($buffer->GetNumberOfLines(), 1, 'correct line count after insert' ) ;
is($buffer->GetModificationLine(), 0, 'line pos is 0' ) ;
is($buffer->GetModificationPosition(), 3, 'char pos is 3' ) ;
is($buffer->GetText(), "bar", 'buffer contains \'bar\'' ) ;

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert("noone\nwants\nme\n");
is($buffer->GetNumberOfLines(), 4, 'correct line count after insert' ) ;
is($buffer->GetModificationLine(), 3, 'line pos is 3' ) ;
is($buffer->GetModificationPosition(), 0, 'char pos is 0' ) ;

# insert array
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->Insert(["Someone\n", "wants me\nNow"]);
is($buffer->GetLineLength(1), 8, 'Line length is correct') ;
is($buffer->GetNumberOfLines(), 3, 'correct line count after array insert' ) ;
is($buffer->GetModificationLine(), 2, 'line pos is 0' ) ;
is($buffer->GetModificationPosition(), 3, 'line pos is 3' ) ;

# insertion after end of line
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->SetModificationPosition(0,5) ;
$buffer->Insert("hi\n") ;
$buffer->Insert("\tthere") ;
$buffer->Backspace(1) ;
$buffer->Insert('u') ;
#~ diag "\n" . hexdump(data => $buffer->GetText()) ;
is($buffer->GetText(), "     hi\n\ttheru") ;

# insert delete insert
$buffer->Reset() ;
$buffer->Insert("this is lower case") ;
$buffer->SetModificationPosition(0, 8) ;
$buffer->Delete(5) ;
is($buffer->GetText(), 'this is  case', 'Insert, Delete, Insert') ;
$buffer->Insert('UPPER') ;
is($buffer->GetText(), 'this is UPPER case', 'Insert, Delete, Insert') ;

$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

#------------

$expected_text = <<EOT ;
line<123>1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 4, 0, 5) ;

$buffer->Insert('<123>') ;
is($buffer->CompareText($expected_text), '', 'Insertwith selection') ;


#upper case
#-------------
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;

$buffer->Insert("this is upper case") ;
$buffer->GetSelection()->Set(0, 8, 0, 13) ;

$buffer->Delete(1) ;
$buffer->Insert('UPPER') ;

is($buffer->GetText(), 'this is UPPER case', 'Upper casing selection') ;


#------------------------------------------------------------------------------------------------- 
# serialisation and multipline insertion
my $buffer_1 = $buffer->new();

isa_ok($buffer_1, 'Text::Editor::Vip::Buffer');

# test $ and @ serialisation
$buffer_1->Insert('my ($message, $lhb, $rhb) = @_ ;',  1) ;
is(TestSerialisation($buffer_1), 1, 'test test $ and @ serialisation') ;

# test \n serialisation
$buffer_1->Reset() ;
$buffer_1->Insert("\nuse strict ;\nuse warnings ;\n\nuse Data::TreeDumper ;\n", 1) ;
is(TestSerialisation($buffer_1), 1, 'test \n serialisation') ;

# test long lines
$buffer_1->Reset() ;
$buffer_1->Insert("k" x 50_000) ;
is(TestSerialisation($buffer_1), 1, 'test long serialisation') ;

# test ', " and \t serialisation
$buffer_1->Reset() ;
$buffer_1->Insert("#~ \$buffer->Insert(\"\tthere\") ;") ;
$buffer_1->Insert("#~ \$buffer->Insert(\"\tthere\") ;\n") ;
$buffer_1->Insert('#~ $buffer->Insert("\tthere") ;') ;
$buffer_1->Insert('#~ $buffer->Insert("\tthere") ;' . "\n") ;
$buffer_1->Insert('"\'' . "\n") ;
$buffer_1->Insert("\"'" . "\n") ;
is(TestSerialisation($buffer_1), 1, 'test \', " and \t serialisation') ;

$buffer_1->Reset() ;
$buffer_1->Insert('$buffer_2->Insert("#~ \$buffer->Insert(\"\tthere\") ;") ;') ;
is(TestSerialisation($buffer_1), 1, '# test serialisation') ;

# test multiline handling
$buffer_1->Reset() ;
$buffer_1->Insert(<<EOT) ;
("#~ \$buffer->Insert(\"\tthere\") ;") ;
("#~ \$buffer->Insert(\"\tthere\") ;\n") ;
('#~ $buffer->Insert("\tthere") ;') ;
('#~ $buffer->Insert("\tthere") ;' . "\n\r") ;
EOT
is(TestSerialisation($buffer_1), 1, '# test multiline handling') ;

$buffer_1->Reset() ;
$text = <<EOT ;
("#~ \$buffer->Insert(\"\tthere\") ;") ;
("#~ \$buffer->Insert(\"\tthere\") ;\n") ;
('#~ $buffer->Insert("\tthere") ;') ;
('#~ $buffer->Insert("\tthere") ;' . "\n\r") ;
EOT

$buffer_1->Insert($text) ;
is($buffer_1->GetText(), $text, 'text is equal') ;

# test miltiline handling, non evaluating
$buffer_1->Reset() ;
$buffer_1->Insert(<<'EOT') ;
$buffer->Insert("#~ \$buffer->Insert(\"\tthere\") ;") ;
$buffer->Insert("#~ \$buffer->Insert(\"\tthere\") ;\n") ;
$buffer->Insert('#~ $buffer->Insert("\tthere") ;') ;
$buffer->Insert('#~ $buffer->Insert("\tthere") ;' . "\n") ;
EOT
is(TestSerialisation($buffer_1), 1, 'test miltiline handling, non evaluating') ;

$buffer_1->Reset() ;
$text = <<'EOT' ;
$buffer->Insert("#~ \$buffer->Insert(\"\tthere\") ;") ;
$buffer->Insert("#~ \$buffer->Insert(\"\tthere\") ;\n") ;
$buffer->Insert('#~ $buffer->Insert("\tthere") ;') ;
$buffer->Insert('#~ $buffer->Insert("\tthere") ;' . "\n") ;
EOT

$buffer_1->Insert($text) ;
is($buffer_1->GetText(), $text, 'text is equal') ;

#------------------------------------------------------------------------------------------------- 

# Test do an undo. We do something in buffer #1, take the do commands from buffer #1 and apply it
# to buffer #2. The buffer #1 and #2 should be equal. We take the the undo commands from buffer #1
# and apply it to buffer #2. We then compare buffer #2 with buffer #3 which is blank from actions.

#------------------------------------------------------------------------------------------------- 

$buffer = Text::Editor::Vip::Buffer->new();

# ShutDown PrintError suicidal behaviour
$buffer->ExpandWith('PrintError', sub {}) ;

my ($result, $message) = $buffer->Do("this should not be valid perl!") ;
is($result, 0, 'Invalid perl') ;

($result, $message) = $buffer->Do("#this should be valid perl!") ;
is($result, 1, 'Valid perl') ;
diag($message) if $result == 0 ;

($result, $message) = $buffer->Do("#this should be valid perl!") ;
is($result, 1, 'Valid perl') ;
diag($message) if $result == 0 ;

($result, $message) = $buffer->Do("# comment\n\$buffer->Insert('bar') ;") ;
is($result, 1, 'Valid perl') ;
diag($message) if $result == 0 ;

is($buffer->GetText(), "bar", 'buffer contains \'bar\'' ) ;

#------------------------------------------------------------------------------------------------- 
# test Pluggin module loading, do, file insertion and undo

my $file = __FILE__ ;

is(TestDoUndo(<<EOS), 1, 'test do and undo after file insertion') ;	
\$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::File') ;
\$buffer->InsertFile('$file') ;
EOS

#undo and selection
#-----------------------

my $setup = <<'EOS' ;
my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 4, 0, 5) ;
EOS

my $commands = <<'EOC' ;
$buffer->Insert("<123>") ;
EOC

is(TestDoUndo($commands, $setup), 1, 'Test undo after Insert') ;

$setup = <<'EOS' ;
my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetSelectionBoundaries(0, 4, 0, 20) ;
EOS

$commands = <<'EOC' ;
$buffer->Insert("<123>") ;
EOC

is(TestDoUndo($commands, $setup), 1, 'Test undo after Insert') ;
