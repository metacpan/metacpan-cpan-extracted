
use strict;
use warnings ;

use Data::TreeDumper ;

use constant ACTIONS  => 0 ;
use constant VIEW     => 1 ;
use constant BUFFER   => 2 ;
use constant KEY      => 3 ;
use constant MODIFIER => 4 ;

#------------------------------------------------------------------------------------------------------

=head1 KEYBOARD GENERATED ACTION, 

=head2 sub arguments

 sub 
 {
 my ($actions, $view, $buffer, $key, $modifiers) = @_ ;
 ....
 }

=cut

#------------------------------------------------------------------------------------------------------

sub Init
{
my ($view) = @_ ;
my ($buffer, $actions) = ($view->GetBuffer(), $view->GetActions()) ;

# UI specific should not be mixed with non UI actions to simplify reuse
#~ $actions->RegisterActions([ 'popup menu' => 'POPUP_MENU', '000' => \&ShowPopupMenu]) ;

# ASCII
for (32 .. 255)
	{
	$actions->RegisterActions
		(
		  ['Insert ' . chr($_) => chr($_) , '000' => \&InsertCharacter]
		, ['Insert ' . chr($_) => chr($_) , '00S' => \&InsertCharacter]
		) ;
	
	}

# Keypad numbers
for my $number (0 .. 9)
	{
	$actions->RegisterActions
		(
		[ undef , "KP_$number", '000' => sub{$_[BUFFER]->Insert("" . $number);} ]
		) ;
	}
	
$actions->RegisterActions( [ undef , 'KP_Decimal', '000' => sub{$_[BUFFER]->Insert('.');} ]) ;
$actions->RegisterActions( [ undef , 'Tab',       '000'  => sub{$_[BUFFER]->InsertTab();} ]) ;

# Other actions
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Movements') ;

$actions->RegisterActions
	(
	  [ undef , 'Return',    '000' => sub { $_[BUFFER]->Insert("\n") ;}]
	, [ undef , 'KP_Enter',  '000' => 'Return', '000']

	, [ undef , 'BackSpace', '000' => sub { $_[BUFFER]->Backspace(1) ;} ]	
	
	, [ undef , 'Delete'   , '000' => sub { $_[BUFFER]->Delete(1);}]
	, [ undef , 'KP_Delete', '000' => 'Delete', '000' ]
	
	, [ undef , 'Left',      '000' => sub { $_[BUFFER]->OffsetModificationPositionGuarded(0, -1) ;} ]
	, [ undef , 'KP_Left',   '000' => 'Left', '000' ]

	, [ undef , 'Up',        '000' => sub{$_[BUFFER]->OffsetModificationPositionGuarded(-1, 0) ;}  ]	
	, [ undef , 'KP_Up',     '000' => 'Up', '000']

	, [ undef , 'Right',     '000' => sub{$_[BUFFER]->OffsetModificationPositionGuarded(0, 1) ;} ]	
	, [ undef , 'KP_Right',  '000' => 'Right', '000']

	, [ undef , 'Down',      '000' => sub{$_[BUFFER]->OffsetModificationPositionGuarded(1, 0) ;} ]
	, [ undef , 'KP_Down',   '000' => 'Down', '000']

	, [ undef , 'Home',      'C00' => sub{$_[BUFFER]->MoveToTopOfBuffer();} ]
	, [ undef , 'KP_Begin',  '000' => 'Home', 'C00']

	, [ undef , 'Home',      '000' => sub{$_[BUFFER]->MoveHome();} ]
	, [ undef , 'KP_Home',   '000' => 'Home', '000' ]

	, [ undef , 'End',       '000' => sub{$_[BUFFER]->MoveToEndOfLine();} ]
	, [ undef , 'KP_End',    '000' => 'End', '000']

	#~ , [ undef , 'Page_Up',   '000' => sub{$_[BUFFER]->;} ]
	#~ , [ undef , 'KP_Page_Up','000' => sub{$_[BUFFER]->;} ]
	#~ , [ undef , 'Page_Down', '000' => sub{$_[BUFFER]->;} ]
	#~ , [ undef , 'KP_Page_Down', '000'  => sub{$_[BUFFER]->;} ]

	#~ , [ undef , 'Escape', '000'        => sub{$_[BUFFER]->;} ]

	#~ , [ undef , 'Insert',    '000' => sub{$_[BUFFER]->;} ]
	#~ , [ undef , 'KP_Insert', '000' => sub{$_[BUFFER]->;} ]

	) ;

#-------------------------------------------------------------------------------
# case

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;

$actions->RegisterActions
	(
	  [ 'Make selection upper case', 'u', 'C00' => sub {$_[BUFFER]->MakeSelectionUpperCase() ;}]
	, [ 'Make selection lower case', 'U', 'C0S' => sub {$_[BUFFER]->MakeSelectionLowerCase() ;}]
	) ;
	

#-------------------------------------------------------------------------------
# selection

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Selection') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Clipboard') ;

$actions->RegisterActions
	(
	  [ 'Select all'                          , 'a'           , 'C00' => sub {$_[BUFFER]->SelectAll() ;}]
	
	#~ , [ 'Select line'                             , 'Triple_click'  , '000' => sub {$_[BUFFER]->SelectLine]

	, [ 'Select word'                  , 'LEFT_DOUBLE_CLICK'  , '000' => sub {$_[BUFFER]->SelectWord() ;}]
	, [ 'Select word'                         , 'Left_click'  , 'C00' => 'LEFT_DOUBLE_CLICK'  , '000']
	, [ 'Select word'                         , 'space'       , 'C0S' => 'LEFT_DOUBLE_CLICK'  , '000']
	
	, [ 'Extend selection'                    , 'Left_click'  , '00S' => sub {$_[BUFFER]->ExtendSelection() ;}]
	, [ 'Extend selection to end of line'     , 'End'         , '00S' => sub {$_[BUFFER]->ExtendSelectionToEndOfLine() ;}]
	, [ 'Extend selection to end of document' , 'End'         , 'C0S' => sub {$_[BUFFER]->ExtendSelectionToEndOfBuffer() ;}]
	, [ 'Extend selection to top of document' , 'Home'        , 'C0S' => sub {$_[BUFFER]->ExtendSelectionToStartOfBuffer() ;}]
	, [ 'Extend selection home'               , 'Home'        , '00S' => sub {$_[BUFFER]->ExtendSelectionHome() ;}]
	, [ 'Extend selection left'               , 'Left'        , '00S' => sub {$_[BUFFER]->ExtendSelectionLeft() ;}]
	, [ 'Extend selection right'              , 'Right'       , '00S' => sub {$_[BUFFER]->ExtendSelectionRight() ;}]
	, [ 'Extend selection to next word'       , 'Right'       , 'C0S' => sub {$_[BUFFER]->ExtendSelectionToNextWord() ;}]
	, [ 'Extend selection to previous word'   , 'Left'        , 'C0S' => sub {$_[BUFFER]->ExtendSelectionToPreviousWord() ;}]
	, [ 'Extend selection up'                 , 'Up'          , '00S' => sub {$_[BUFFER]->ExtendSelectionUp() ;}]
	, [ 'Extend selection down'               , 'Down'        , '00S' => sub {$_[BUFFER]->ExtendSelectionDown() ;}]
	
	#~ , [ 'Extend selection page up'                , 'Prior'       , '00S' => sub {$_[BUFFER]->ExtendSelectionPageUp() ;}]
	#~ , [ 'Extend selection page down'              , 'Next'        , '00S' => sub {$_[BUFFER]->ExtendSelectionPageDown() ;}]
	
	, [ 'Copy selection to systemclipboard'   , 'Insert'      , 'C00' => sub {$_[BUFFER]->PrintError("copy to main clipboard unimplemented!") ;}]
	, [ 'Insert system clipboard contents'    , 'Insert'      , '00S' => sub {$_[BUFFER]->PrintError("paste from main clipboard unimplemented!") ;}]
	
	, [ 'Copy selection to clipboard 1'       , '&'           , 'C00' => sub {$_[BUFFER]->CopySelectionToClipboard(1) ;}]
	, [ 'Insert clipboard contents 1'         , '1'           , 'C0S' => sub {$_[BUFFER]->InsertClipboardContents(1) ;}]
	, [ 'Copy selection to clipboard 2'       , 'é'           , 'C00' => sub {$_[BUFFER]->CopySelectionToClipboard(2) ;}]
	, [ 'Insert clipboard contents 2'         , '2'           , 'C0S' => sub {$_[BUFFER]->InsertClipboardContents(2) ;}]
	, [ 'Copy selection to clipboard 3'       , '"'           , 'C00' => sub {$_[BUFFER]->CopySelectionToClipboard(3) ;}]
	, [ 'Insert clipboard contents 3'         , '3'           , 'C0S' => sub {$_[BUFFER]->InsertClipboardContents(3) ;}]
	, [ 'Copy selection to clipboard 4'       , "'"           , 'C00' => sub {$_[BUFFER]->CopySelectionToClipboard(4) ;}]
	, [ 'Insert clipboard contents 4'         , '4'           , 'C0S' => sub {$_[BUFFER]->InsertClipboardContents(5) ;}]
	) ;

# display

$actions->RegisterActions
	(
	  [ 'Center current line in display', 'C'       , 'C0S' => sub {$_[VIEW]->CenterCurrentLineInDisplay() ;}]
	, [ 'Flip display size'             , 'Return'  , 'C00' => sub {$_[VIEW]->FlipDisplaySize() ;}]
	, [ 'Flip line number display'      , 'L'       , '0A0' => sub {$_[VIEW]->FlipLineNumberDisplay() ;}]
	, [ 'display tab stops'             , 'T'       , '0A0' => sub {$_[VIEW]->DisplayTabStops() ;}]
	, [ 'Reduce tab size'               , 'Subtract', '0A0' => sub {$_[VIEW]->ReduceTabSize() ;}]
	, [ 'Expand tab size'               , 'Add'     , '0A0' => sub {$_[VIEW]->ExpandTabSize() ;}]
	) ;

}


#------------------------------------------------------------------------------------------------------

sub InsertCharacter
{
my (undef, undef, $buffer, $key) = @_ ;
$buffer->Insert($key) ;
} ;

#------------------------------------------------------------------------------------------------------

sub InsertNewLine {$_[BUFFER]->Insert("\n") ;} ;

#------------------------------------------------------------------------------------------------------
1 ;

__END__

#-------------------------------------------------------------------------------

#  called by CPP smed
#$this->AddCommand('000NEW_SELECTION'    , 'Smed::ExtendSelection()') ;

#-------------------------------------------------------------------------------

# insert, delete

$this->AddCommand('000DELETE', 'Delete',    \&Smed::Delete) ;
$this->AddCommand('000BACK',   'Backspace', \&Smed::BackspaceOne) ;

$this->AddCommand('000RETURN'   , 'Insert new line',               \&Smed::InsertNewLine) ;
$this->AddCommand('CS0L'        , 'Insert new line before current',\&Smed::InsertNewLineBeforeCurrent) ;
$this->AddCommand('C00L'        , 'Delete line',                   \&Smed::DeleteLine) ;
$this->AddCommand('C00BACK'     , 'Delete to begining of line',    \&Smed::DeleteToBeginingOfWord) ;
$this->AddCommand('C00DELETE'   , 'Delete to end of word',         \&Smed::DeleteToEndOfWord) ;
$this->AddCommand('000SPACE'    , 'Insert space',                  \&Smed::InsertSpace) ;
$this->AddCommand('000TAB'      , 'Insert tab',                    \&Smed::InsertTab) ;
$this->AddCommand('0S0TAB'      , 'Remove tab from selection',     \&Smed::RemoveTabFromSelection) ;

#--------------------------------------------------------------------------) ;
# movement

$this->AddCommand('C00G', 'Goto line and character', \&Smed::GotoLine) ;

$this->AddCommand('0S0WHEEL_DOWN', 'Move right 10',           \&Smed::MoveRight10) ;
$this->AddCommand('0S0WHEEL_UP'  , 'Move left 10',            \&Smed::MoveLeft10) ;
$this->AddCommand('C00WHEEL_UP'  , 'Page up',                 \&Smed::PageUp) ;
$this->AddCommand('000PRIOR'     , 'Page up',                 \&Smed::PageUp) ;
$this->AddCommand('C00WHEEL_DOWN', 'Page down',               \&Smed::PageDown) ;
$this->AddCommand('000NEXT'      , 'Page down',               \&Smed::PageDown) ;
$this->AddCommand('C00HOME'      , 'Move to top of document', \&Smed::MoveToTopOfDocument) ;
$this->AddCommand('C00END'       , 'Move to end of document', \&Smed::MoveToEndOfDocument) ;
$this->AddCommand('CS0WHEEL_DOWN', 'Move to end of line',     \&Smed::MoveToEndOfLine) ;
$this->AddCommand('000END'       , 'Move to end of line',     \&Smed::MoveToEndOfLine) ;
$this->AddCommand('000HOME'      , 'Move home',               \&Smed::MoveHome) ; #a la microsoft
$this->AddCommand('CS0WHEEL_UP ' , 'Move home',               \&Smed::MoveHome) ; #a la microsoft
$this->AddCommand('000LEFT'      , 'Move left',               \&Smed::MoveLeft) ;
$this->AddCommand('000RIGHT'     , 'Move right',              \&Smed::MoveRight) ;
#$this->AddCommand(''     , 'Smed::MoveToEndOfWord()') ;
$this->AddCommand('C00LEFT'      , 'Move to previous word',   \&Smed::MoveToPreviousWord) ;
$this->AddCommand('C00RIGHT'     , 'Move to next word',       \&Smed::MoveToNextWord) ;
$this->AddCommand('000WHEEL_UP'  , 'Wheel up',                \&Smed::WheelUp) ;
$this->AddCommand('000WHEEL_DOWN', 'Wheel down',              \&Smed::WheelDown) ;
$this->AddCommand('000UP'        , 'Move up',                 \&Smed::MoveUp) ;
$this->AddCommand('000DOWN'      , 'Move down',               \&Smed::MoveDown) ;
$this->AddCommand('C00UP'        , 'Scroll up',               \&SmedView::ScrollUp) ;
$this->AddCommand('C00DOWN'      , 'Scroll down',             \&SmedView::ScrollDown) ;
                                                              
#-------------------------------------------------------------------------------

# bookmark
                                                            
$this->AddCommand('000F2', 'Goto next bookmark',            \&Smed::GotoNextBookmark) ;
$this->AddCommand('0S0F2', 'Goto Previous bookmark',        \&Smed::GotoPreviousBookmark) ;
$this->AddCommand('C00F2', 'Flip bookmark at current line', \&Smed::FlipBookmarkAtCurrentLine) ;
$this->AddCommand('CS0F2', 'Clear all bookmarks',           \&Smed::ClearAllBookmarks) ;
                                                            
$this->AddCommand('000F5', 'Goto next warning',             \&Smed::GotoNextWarning) ;
$this->AddCommand('0S0F5', 'Goto previous warning',         \&Smed::GotoPreviousWarning) ;
$this->AddCommand('C00F5', 'Flip warning at current line',  \&Smed::FlipWarningAtCurrentLine) ;
$this->AddCommand('CS0F5', 'Clear all warnings',            \&Smed::ClearAllWarnings) ;
                                                            
$this->AddCommand('C00F6', 'Add named bookmark',            \&Smed::AddNamedBookmark) ;
$this->AddCommand('000F6', 'Goto named bookmark',           \&Smed::GotoNamedBookmark) ;
                                                            
#-------------------------------------------------------------------------------

# Interaction

$this->AddCommand('000ESCAPE', 'On escape',     \&SmedView::OnEscape) ;
$this->AddCommand('C00N', 'Run new smed',       \&SmedView::RunNewSmed) ;
                                                
#$this->AddCommand('C00Z'     , 'Smed::OnUndo()') ;
#$this->AddCommand('C00Y'     , 'Smed::OnRedo()') ;
                                                
$this->AddCommand('C00O', 'Open file'        ,  \&SmedView::OpenFile) ;
$this->AddCommand('C00S', 'Save'             ,  \&Smed::SaveDocument) ;
$this->AddCommand('CS0S', 'Save Document as.',  \&Smed::SaveDocumentAs) ;

$this->AddCommand('C00P', 'Display popup menu', \&SmedView::DisplayPopupMenu) ;
$this->AddCommand('C0AK', 'Print Keyboard mapping', \&SmedView::DisplayKeyboardMapping) ;


$this->AddPopupMenuFiller(\&CommonMenuFiller) ;

#-------------------------------------------------------------------------------

# find replace

$this->AddCommand('C00F' , 'Find ocurrence',                 \&FindOccurenceDialog) ;
$this->AddCommand('CS0F' , 'Find previous ocurrence ',       \&FindPreviousOccurenceDialog) ;
$this->AddCommand('000F3', 'Find next',                      \&Smed::FindNextOccurence) ;
$this->AddCommand('0S0F3', 'Find previous',                  \&Smed::FindPreviousOccurence) ;
$this->AddCommand('C00F3', 'Find next text under caret',     \&Smed::FindNextOccurenceForTextUnderCaret) ;
$this->AddCommand('CS0F3', 'Find previous text under caret', \&Smed::FindPreviousOccurenceForTextUnderCaret) ;

$this->AddCommand('C00H' , 'Replace',                        \&ReplaceOccurenceDialog) ;
$this->AddCommand('000F4', 'Replace again',                  \&Smed::ReplaceAgain) ;

#$this->AddCommand('C0AF' , 'Smed::IncrementalSearch()') ;

#-------------------------------------------------------------------------------

# Alignement

$this->AddCommand('C00ADD', 'Align right on equal signe', \&Smed::AlignRightOnEqualSign) ;
$this->AddCommand('C000', 'Align right', \&Smed::AlignRightOnDelimiter) ;

#-------------------------------------------------------------------------------

# Fold
#$this->AddCommand('' , 'Smed::FoldSelection()') ;
#$this->AddCommand('' , 'Smed::Unfold()') ;

#-------------------------------------------------------------------------------

#macro

$this->AddCommand('CS0R', 'Record macro', \&SmedView::RecordMacro) ;
$this->AddCommand('CS0P', 'Play macro',   \&SmedView::PlayMacro) ;
$this->AddCommand('CS0S', 'Save macro',   \&SmedView::SaveMacro) ;
$this->AddCommand('CS0L', 'Load macro',   \&SmedView::LoadMacro) ;

#-------------------------------------------------------------------------------

# undo, redo
$this->AddCommand('C00Z', 'Undo', \&Smed::Undo) ;
$this->AddCommand('C00Y', 'Redo', \&Smed::Redo) ;

#-------------------------------------------------------------------------------

# divers 
$this->AddCommand('C0AS', 'Check line spelling',       \&Smed::CheckLineSpelling) ;
$this->AddCommand('C00T', 'Start template dispatcher', \&SmedView::StartTemplateDispatcher) ;
$this->AddCommand('C00SPACE', 'Completion',            \&SmedView::IdentifierCompletion) ;
$this->AddCommand('C0AM', 'Make file read-write',      \&Smed::MakeFileReadWrite) ;

$this->AddCommand('C00P', 'Export to Html', \&SmedView::ExportToHtml) ;

use SmedView::ClipboardView ;
$this->AddCommand('000F12', 'General test', \&SmedView::OpenClipboardView) ;
}

