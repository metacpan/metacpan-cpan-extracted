
use strict ;
use warnings ;

#~ use Devel::SimpleTrace ;
#~ use Carp::Indeed ;

use lib qw(lib) ;

use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use Test::More qw(no_plan);
use Test::Differences ;
use Test::Exception ;

use Text::Editor::Vip::Buffer ;
use Text::Editor::Vip::Buffer::Test ;

#-----------------------------------------------------------------------------------------------------------

use Test::Builder ;
my $test_interface = new Test::Builder ;

my $redefined_sub_output = '' ;
sub TestPrintError
{
use Carp qw(longmess) ;

$redefined_sub_output = "$_[1]\n" . longmess() ;
}

sub is_error_generated 
{
my ($description) = @_ ;

my $ok = $redefined_sub_output ne '' ? 1 : 0 ;
$redefined_sub_output = '' ;

$test_interface->ok($ok, $description) || $test_interface->diag("        Expected error output") ;
}

sub isnt_error_generated 
{
my ($description) = @_ ;

my $ok = $redefined_sub_output eq '' ? 1 : 0 ;
my $redefined_sub_output_copy = $redefined_sub_output  ;
$redefined_sub_output = '' ;

$test_interface->ok($ok, $description) || $test_interface->diag("        Got unexpected: '$redefined_sub_output_copy'.") ;
}

#-----------------------------------------------------------------------------------------------------------

my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
EOT

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->ExpandWith('PrintError', sub {$redefined_sub_output = $_[1]}) ;

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Selection') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Clipboard') ;

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

# SetClipboardContents, GetClipboardContents
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

is($buffer->GetClipboardContents('unexistant'), '', 'unexistant clipboard is empty') ;

$buffer->GetClipboardContents() ;
is_error_generated('undefined clipboard generates error') ;

$buffer->SetClipboardContents(undef, '') ;
is_error_generated('setting undef clipboard generates error') ;

$buffer->SetClipboardContents('', '') ;
is_error_generated('setting empty clipboard generates error') ;

$buffer->SetClipboardContents([], '') ;
is_error_generated('array clipboard name generates error') ;

$buffer->SetClipboardContents('name') ;
is_error_generated('wrong number of arguments generates error') ;

$buffer->SetClipboardContents('string', 'string') ;
is($buffer->GetClipboardContents('string'), 'string', 'getting clipboard named with string') ;

$buffer->SetClipboardContents(1, 1) ;
is($buffer->GetClipboardContents(1), 1, 'getting clipboard named with figure') ;

$buffer->SetClipboardContents('array', 'string') ;
is($buffer->GetClipboardContents('string'), 'string', 'getting clipboard named with string') ;

$buffer->SetClipboardContents('array_ref', ['string']) ;
is($buffer->GetClipboardContents('string'), 'string', 'getting clipboard named with string') ;

# clearing 
$buffer->SetClipboardContents('string', 'string') ;
is($buffer->GetClipboardContents('string'), 'string', 'getting clipboard named with string') ;

$buffer->ClearClipboardContents('string') ;
is($buffer->GetClipboardContents('string'), '', 'cleared clipboard is empty') ;

$buffer->ClearClipboardContents('string', 'extra') ;
is_error_generated('extra arguments generates error') ;

$buffer->ClearClipboardContents() ;
is_error_generated('clearing to undef clipboard generates error') ;

$buffer->ClearClipboardContents('') ;
is_error_generated('clearing empty clipboard name generates error') ;

$buffer->ClearClipboardContents([]) ;
is_error_generated('array name generates error') ;

#AppendToClipboardContents

$buffer->AppendToClipboardContents('string', 'string') ;
is($buffer->GetClipboardContents('string'), 'string', 'getting clipboard named with string') ;

$buffer->AppendToClipboardContents('string', 'string2') ;
is($buffer->GetClipboardContents('string'), 'stringstring2', 'getting clipboard named with string') ;

$buffer->AppendToClipboardContents('test', ["test\n", "test"]) ;
is($buffer->GetClipboardContents('test'), "test\ntest", 'getting clipboard named with string') ;

$buffer->AppendToClipboardContents('string') ;
is_error_generated('wrong number of arguments generates error') ;
is($buffer->GetClipboardContents('string'), 'stringstring2', 'clipboard unchanged') ;

$buffer->AppendToClipboardContents(undef, 'something') ;
is_error_generated('appending to undef clipboard generates error') ;

$buffer->AppendToClipboardContents('', 'something') ;
is_error_generated('appending empty clipboard name generates error') ;

$buffer->ClearClipboardContents([], 'something') ;
is_error_generated('appending array name generates error') ;

# reset empties clipboards
$buffer->Reset() ;
is($buffer->GetClipboardContents('string'), '', 'getting clipboard named with string') ;
is($buffer->GetClipboardContents(1), '', 'getting clipboard named with figure') ;

$buffer->GetClipboardContents('valid', 'extra arguments') ;
is_error_generated('extra arguments generates error') ;

# CopySelectionToClipboard
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->CopySelectionToClipboard(undef) ;
is_error_generated('copying selection to undef clipboard generates error') ;

$buffer->CopySelectionToClipboard('') ;
is_error_generated('copying to empty clipboard generates error') ;

$buffer->CopySelectionToClipboard([]) ;
is_error_generated('array name generates error') ;

$buffer->CopySelectionToClipboard('valid', 'extra arguments'), ;
is_error_generated('extra arguments generates error') ;

$buffer->SetClipboardContents('string', 'string') ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), 'string', 'copy empty selection changes nothing') ;

# set selection
$buffer->ClearClipboardContents('string') ;
$buffer->SetSelectionBoundaries(0, 1, 1, 2) ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), "ine 1 - 1\nli", 'getting clipboard named with string and from selection') ;

$buffer->ClearClipboardContents('string') ;
$buffer->CopySelectionToClipboard(1) ;
is($buffer->GetClipboardContents(1), "ine 1 - 1\nli", 'getting clipboard named with figure and from selection') ;

$buffer->ClearClipboardContents('string') ;
$buffer->SetSelectionBoundaries(0, 0, 1, 0) ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), "line 1 - 1\n", 'getting clipboard named with string and from selection') ;

$buffer->ClearClipboardContents('string') ;
$buffer->SetSelectionBoundaries(-10, 0, 2, 0) ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), "line 1 - 1\nline 2 - 2 2\n", 'getting clipboard named with string and from selection') ;

$buffer->ClearClipboardContents('string') ;
$buffer->SetSelectionBoundaries(0, 0, 3, 0) ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), "line 1 - 1\nline 2 - 2 2\n", 'getting clipboard named with string and from selection') ;

# InsertClipboardContents
$buffer->Reset() ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->InsertClipboardContents('unexistant') ;
is($buffer->GetText(), '', 'Insert unexisting Clipboard changes nothing') ;

$buffer->InsertClipboardContents() ;
is_error_generated('inserting un-namedclipboard generates error') ;
is($buffer->GetText(), '', 'Inserting undef Clipboard changes nothing') ;

$buffer->InsertClipboardContents('') ;
is_error_generated('Inserting un-named clipboard generates error') ;
is($buffer->GetText(), '', 'Inserting un-named Clipboard changes nothing') ;

$buffer->InsertClipboardContents([]) ;
is_error_generated('Inserting un-named clipboard generates error') ;
is($buffer->GetText(), '', 'Inserting un-named Clipboard changes nothing') ;

$buffer->SetClipboardContents('string', $text) ;
$buffer->InsertClipboardContents('string') ;
is($buffer->GetText(), $text, 'Inserted Clipboard content == buffer content') ;

#YankLineToClipboard
#-------------------
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->YankLineToClipboard(1, '') ;
is_error_generated('setting undef clipboard generates error') ;

$buffer->YankLineToClipboard(1, []) ;
is_error_generated('array clipboard name generates error') ;

$buffer->YankLineToClipboard(1, undef) ;
is_error_generated('array clipboard name generates error') ;

$buffer->YankLineToClipboard(1) ;
is_error_generated('wrong number of arguments generates error') ;

$buffer->YankLineToClipboard(undef, 1) ;
is_error_generated('undefined line generates error') ;

$buffer->YankLineToClipboard(-1 , 1) ;
is_error_generated('invalid line generates error') ;

$buffer->YankLineToClipboard(10 , 1) ;
is_error_generated('invalid line generates error') ;

# verify content
my $number_of_lines = $buffer->GetNumberOfLines() ;
my $line_0 = $buffer->GetLineTextWithNewline(0) ;

$buffer->YankLineToClipboard(0 , 1) ;

isnt_error_generated("valid yank doesn't generate an error") ;
is($buffer->GetClipboardContents(1), $line_0, 'right line yanked to clipboard') ;
is($number_of_lines, $buffer->GetNumberOfLines() + 1, "line removed from buffer") ;

my $line_1 = $buffer->GetLineTextWithNewline(0) ;

$buffer->YankLineToClipboard(0 , 1) ;

isnt_error_generated("valid yank doesn't generate an error") ;
is($buffer->GetClipboardContents(1), $line_0 . $line_1, 'right line yanked to clipboard') ;
is($number_of_lines, $buffer->GetNumberOfLines() + 2, "line removed from buffer") ;

#PopClipboard
#-------------------

is($buffer->PopClipboard(1), $line_1, 'line 1 poped from clipboard') ;
isnt_error_generated("valid pop doesn't generate an error") ;

is($buffer->PopClipboard(1), $line_0, 'line 0 poped to clipboard') ;
isnt_error_generated("valid pop doesn't generate an error") ;

is($buffer->PopClipboard(1), '', 'empty clipboard returns empty string') ;
is_error_generated("empty clipboard poping generate an error") ;

$buffer->PopClipboard(1, 2, 3) ;
is_error_generated("wrong number of arguments generate an error") ;

$buffer->PopClipboard('') ;
is_error_generated('empty clipboard name generates error') ;

$buffer->PopClipboard([]) ;
is_error_generated('array clipboard name generates error') ;

$buffer->PopClipboard(undef) ;
is_error_generated('undef clipboard name generates error') ;

# GetNumberOfClipboardElements
#------------------------------------------------
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->YankLineToClipboard(0 , 1) ;
$buffer->YankLineToClipboard(0 , 1) ;

is($buffer->GetNumberOfClipboardElements(1), 2, 'clipboard has content') ;

is($buffer->GetNumberOfClipboardElements('new'), 0, 'accessing a non existant clipboard') ;
isnt_error_generated("no errors when accessing a non existant clipboard") ;

$buffer->GetNumberOfClipboardElements(1, 2, 3) ;
is_error_generated("wrong number of arguments generate an error") ;

$buffer->GetNumberOfClipboardElements('') ;
is_error_generated('empty clipboard name generates error') ;

$buffer->GetNumberOfClipboardElements([]) ;
is_error_generated('array clipboard name generates error') ;

$buffer->GetNumberOfClipboardElements(undef) ;
is_error_generated('undef clipboard name generates error') ;

# YankSelectionToClipboard
# ---------------------------
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->YankSelectionToClipboard('') ;
is_error_generated('empty clipboard name generates error') ;

$buffer->YankSelectionToClipboard([]) ;
is_error_generated('array clipboard name generates error') ;

$buffer->YankSelectionToClipboard(undef) ;
is_error_generated('undef clipboard name generates error') ;

#~ selection error
$buffer->YankSelectionToClipboard('selection') ;
is_error_generated('no selection generates error') ;

$buffer->SetSelectionBoundaries(0, 0, 0, 0) ;
$buffer->YankSelectionToClipboard('selection') ;
is_error_generated('no selection generates error') ;

#~ weird selection
$buffer->SetSelectionBoundaries(-10, 0, 0, 0) ;
$buffer->YankSelectionToClipboard('selection') ;
isnt_error_generated('Strange selection boundaries') ;

is($buffer->GetClipboardContents('selection'), '' , 'right contents yanked') ;
is($buffer->CompareText($text), '', "remaining buffer contents OK") ;
is(3, $buffer->GetNumberOfLines(), "line removed from buffer") ;

#~ weird selection
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->SetSelectionBoundaries(-10, 0, 10, 1000) ;
$buffer->YankSelectionToClipboard('selection') ;
isnt_error_generated('Strange selection boundaries') ;

is($buffer->GetClipboardContents('selection'), $text , 'right contents yanked') ;
is($buffer->CompareText(''), '', "remaining buffer contents OK") ;
is($buffer->GetNumberOfLines(), 1, "line removed from buffer (one line always remain)") ;

#~ ok selection
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->SetSelectionBoundaries(0, 0, 1, 5) ;

$buffer->YankSelectionToClipboard('selection') ;

is($buffer->GetClipboardContents('selection'), "line 1 - 1\nline " , 'right contents yanked') ;
is($buffer->CompareText("2 - 2 2\n"), '', "remaining buffer contents OK") ;
is(2, $buffer->GetNumberOfLines(), "line removed from buffer") ;

# select all
my $text2 = "line 1\nline 2\line 3 not ended with new line thus only three lines" ;

$buffer->Reset() ;
$buffer->Insert($text2) ;
$buffer->SelectAll() ;
$buffer->YankSelectionToClipboard('selection') ;

is($buffer->GetClipboardContents('selection'), $text2 , 'right contents yanked') ;
is($buffer->CompareText(''), '', "buffer emptied") ;
is($buffer->GetNumberOfLines(), 1, "line removed from buffer (one line always remain)") ;

# AppendCurrentLineToClipboardContents
# ------------------------------------
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$number_of_lines = $buffer->GetNumberOfLines() ;
my $buffer_text = $buffer->GetText() ;

$buffer->AppendCurrentLineToClipboardContents('string') ;
isnt_error_generated('AppendCurrentLineToClipboardContents generates no error') ;
is($buffer->GetClipboardContents('string'), "line 1 - 1\n", 'current line copied to clipboard') ;
is($buffer->GetNumberOfLines(), $number_of_lines, 'unmodified number of lines') ;
is($buffer->CompareText($buffer_text), '', "unmodified buffer contents") ;

$buffer->AppendCurrentLineToClipboardContents('string', 1, 2) ;
is_error_generated('wrong number of arguments generates error') ;
is($buffer->GetClipboardContents('string'), "line 1 - 1\n", 'clipboard unchanged') ;

$buffer->AppendCurrentLineToClipboardContents(undef) ;
is_error_generated('appending to undef clipboard generates error') ;

$buffer->AppendCurrentLineToClipboardContents('') ;
is_error_generated('appending empty clipboard name generates error') ;

$buffer->AppendCurrentLineToClipboardContents([]) ;
is_error_generated('appending array name generates error') ;

#~ line error
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(-10, -10) ; # doesn't modify position
$buffer->AppendCurrentLineToClipboardContents('string') ;
is_error_generated('AppendCurrentLineToClipboardContents with bad position generates error') ;
is($buffer->GetClipboardContents('string'), '', 'nothing copied to clipboard') ;


# AppendSelectionToClipboardContents
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$buffer->SetSelectionBoundaries(0, 1, 1, 2) ;
$buffer->AppendSelectionToClipboardContents('string') ;
is($buffer->GetClipboardContents('string'), "ine 1 - 1\nli", 'getting clipboard named with string and from selection') ;
$buffer->ClearClipboardContents('string') ;
is($buffer->GetClipboardContents('string'), '', 'getting clipboard named with string and from selection') ;

# select all
my $number_of_lines2 = $buffer->GetNumberOfLines() ;
my $buffer_text2 = $buffer->GetText() ;

$buffer->SelectAll() ;
$buffer->AppendSelectionToClipboardContents('string') ;
isnt_error_generated('AppendSelectionToClipboardContents generates no error') ;
is($buffer->GetClipboardContents('string'), $buffer_text2, 'current line copied to clipboard') ;
is($buffer->GetNumberOfLines(), $number_of_lines2, 'unmodified number of lines') ;
is($buffer->CompareText($buffer_text2), '', "unmodified buffer contents") ;

#empty buffer, paste clipboard
$buffer->Delete() ;
$buffer->InsertClipboardContents('string') ;
is($buffer->GetClipboardContents('string'), $buffer_text2, 'current line copied to clipboard') ;
is($buffer->GetNumberOfLines(), $number_of_lines2, 'unmodified number of lines') ;
is($buffer->CompareText($buffer_text2), '', "unmodified buffer contents") ;

# arg errors
$buffer->AppendSelectionToClipboardContents('string', 1, 2) ;
is_error_generated('wrong number of arguments generates error') ;
is($buffer->GetClipboardContents('string'), $buffer_text2, 'clipboard unchanged') ;

$buffer->AppendSelectionToClipboardContents(undef) ;
is_error_generated('appending to undef clipboard generates error') ;

$buffer->AppendSelectionToClipboardContents('') ;
is_error_generated('appending empty clipboard name generates error') ;

$buffer->AppendSelectionToClipboardContents([]) ;
is_error_generated('appending array name generates error') ;

#~selection error
$buffer->Reset() ;
$buffer->Insert($text) ;

# no selection
$buffer->AppendSelectionToClipboardContents('string') ;
is_error_generated('AppendSelectionToClipboardContents with no selection generates error') ;
is($buffer->GetClipboardContents('string'), '', 'nothing copied to clipboard') ;

$buffer->ClearClipboardContents('string') ;
$buffer->SetSelectionBoundaries(-10, 0, 2, 0) ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), $text, 'getting clipboard named with string and from selection') ;
isnt_error_generated('selection is boxed') ;

$buffer->ClearClipboardContents('string') ;
$buffer->SetSelectionBoundaries(0, 0, 3, 0) ;
$buffer->CopySelectionToClipboard('string') ;
is($buffer->GetClipboardContents('string'), $text, 'getting clipboard named with string and from selection') ;
isnt_error_generated('selection is boxed') ;
