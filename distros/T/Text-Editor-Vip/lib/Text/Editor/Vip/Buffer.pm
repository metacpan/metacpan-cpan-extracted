
package Text::Editor::Vip::Buffer;

use strict;
use warnings ;
use Data::TreeDumper ;

BEGIN 
{
use Exporter ();

use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01;
@ISA         = qw (Exporter);
@EXPORT      = qw ();
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use Time::HiRes ;
use Carp qw(carp confess cluck);
use List::Util qw(min) ;

use Text::Editor::Vip::Buffer::List ;
use Text::Editor::Vip::Buffer::Constants ;
use Text::Editor::Vip::Selection ;
use Text::Editor::Vip::CommandBlock ;

#-------------------------------------------------------------------------------

=head1 NAME

Text::Editor::Vip::Buffer - Editing engine

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer ;
  my $buffer = new Text::Editor::Vip::Buffer() ;
  
=head1 DESCRIPTION

This module implements the core functionality for an editing engine. It knows about 
selection,  undo and plugins.

=head1 MEMBER FUNCTIONS

=cut

my $uid = 0 ; #well, hmm, good enough

sub new
{

=head2 new

Create a Text::Editor::Vip::Buffer .  

  my $buffer = new Text::Editor::Vip::Buffer() ;

=cut

my $invocant = shift ;

my $class = ref($invocant) || $invocant ;
my $buffer = {} ;

my ($package, $file_name, $line) = caller() ;
$file_name =~ s/[^0-9a-zA-Z_]/_/g ;

# push this object in a 'unique' class
# this lets us expand a single object functionality without expanding
# all objects
$class .= "::${file_name}_${line}_$uid" ;
$uid++ ;
  
my $buffer_package = __PACKAGE__;
eval "unshift \@${class}::ISA, '$buffer_package' ;" ;

bless $buffer, $class ;

$buffer->Setup(@_) ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::DoUndoRedo') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Indenter') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Selection') ;

return($buffer) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 Setup

Helper sub called by new. This is considerer private.

=cut

my $buffer = shift ;
my $expansions = $buffer->{EXPANSIONS} || [] ;

%$buffer = 
	(
	  NODES                        => new Text::Editor::Vip::Buffer::List()
	, EXPANSIONS                   => $expansions
	
	, MARKED_AS_EDITED             => 0
	
	, DO_PREFIX                    => ''
	, DO_STACK                     => []
	, UNDO_PREFIX                  => ''
	, UNDO_STACK                   => []
	, REDO_STACK                   => []
	
	, CLIPBOARDS                   => {}
	, MODIFICATION_LINE            => 0
	, MODIFICATION_CHARACTER       => 0
	, SELECTION                    => new Text::Editor::Vip::Selection()
	, @_
	) ;


$buffer->{NODES}->Push({TEXT => ''}) ;
}

#-------------------------------------------------------------------------------

=head2 Reset

Empties the buffer from it's contents as if it was newly created. L<Plugins> are still plugged into the buffer. This
is very practical when writting tests.

  $buffer->Reset() ;

=cut

*Reset = \&Setup ;

#-------------------------------------------------------------------------------

sub ExpandedWithOrLoad
{

=head2 ExpandedWithOrLoad

See L<PLUGINS>.

If the name passed as first argument doesn't match a sub within the object, the module, passed as second argument,
is loaded.

  # newly created buffer that is missing a functionality
  $buffer->SomeSub(); # perl dies
  
  # load plugin first
  $buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::SomePlugin') ;
  $buffer->SomeSub(); # ok
  
  # load the plugin only if the sub is available. This doesn't guarantee that 'SomeSub' has been
  # loaded from the passed Plugin.
  
  $buffer->ExpandedWithOrLoad('SomeSub', 'Text::Editor::Vip::Buffer::Plugins::SomePlugin') ;
  $buffer->SomeSub(); #ok

Returns 1 if the sub existed and 0 if it didn't and the module was loaded or the error type B<LoadAndExpandWith> generated.

=cut

my $buffer   = shift ;
my $sub_name = shift ;
my $module   = shift ;

my $class = ref($buffer) ;

my $sub ;
eval "\$sub = ${class}->can('${sub_name}') ;" ;

if(defined $sub)
	{
	push @{$buffer->{EXPANSIONS}}, {CALLER => [caller()],  LOOKING_FOR => $sub_name, FOUND => 1} ;
	return(1) ;
	}
else
	{
	$buffer->LoadAndExpandWith($module, 1) ;
	
	push @{$buffer->{EXPANSIONS}}, {CALLER => [caller()],  LOOKING_FOR => $sub_name, LOADING_MODULE => $module} ;
	return(0) ;
	}
}

#-------------------------------------------------------------------------------

sub LoadAndExpandWith
{

=head2 LoadAndExpandWith

See L<PLUGINS>.

Loads a perl module (plugin) and adds all it functionality to the buffer

  $buffer->LoadAndExpandWith('Text::Editor::Vip::Plugins::Buffer::File') ;
  
  # we can now read files
  $buffer->InsertFile(__FILE__) ;

=cut

# look at Export::Cluster, Export::Dispatch

my $buffer     = shift ;
my $module     = shift ;
my $no_history = shift ;

eval "use $module ;" ;
die __PACKAGE__ . " couldn't load '$module':\n$@\n" if $@ ;

my $class = ref($buffer) ;
eval "push \@${class}::ISA, '$module' ;" ;

$buffer->PushUndoStep
		(
		  "\$buffer->LoadAndExpandWith('$module') ;"
		, "# undo for \$buffer->LoadAndExpandWith('$module') ;"
		) ;

unless($no_history)
	{
	push @{$buffer->{EXPANSIONS}}, {CALLER => [caller()],  LOADING_MODULE => $module} ;
	}

#alternative way to expend the object

# expands the current's package ISA not the objects isa
#~ push @ISA, $module ;

#~ my $class = ref($buffer) ;

#~ my $symbole_tabel = "main::${module}::" ;

#~ no strict ;
#~ if($symbole_tabel->{EXTEND_VIP_BUFFER})
	#~ {
	#~ for(sort  @{*{$symbole_tabel->{EXTEND_VIP_BUFFER}}{ARRAY}})
		#~ {
		#~ if(*{$symbole_tabel->{$_}}{CODE})
			#~ {
			#~ print "code => $_\n" ;
			#~ $buffer->ExpandWith($_, *{$symbole_tabel->{$_}}{CODE})
			#~ }
		#~ }
	#~ }
}

#-------------------------------------------------------------------------------

sub ExpandWith
{

=head2 ExpandWith

See L<PLUGINS>.

Adds a sub to a buffer instance. 

  $buffer->ExpandWith
		(
		  'GotoBufferStart' # member function name
		, \&some_sub    # implementaton for GotoBufferStart
		) ;
  
  # we can now go  to the buffers start
  $buffer->GotoBufferStart() ;

The second argument is optional, if it is not given, Text::Editor::Vip::Buffer will take the sub from the caller namespace

  sub GotoBufferStart
  {
  my $buffer = shift ; # remember we are a plugin to an object oriented module
  $buffer->SetModificationPosition,(0, 0) ;
  }
  
  $buffer->ExpandWith( 'GotoBufferStart') ;
  $buffer->GotoBufferStart() ;

DEV. WARNING!
	This is going to give us troubles when using it for macros that are saved to disk!
	we must find a way to replug when loading the macro back

=cut

my $buffer =  shift ;
my $sub_name = shift ;
my $sub = shift ;

my $class = ref($buffer) ;

my $warning = '' ;
local $SIG{'__WARN__'} = sub {$warning = $_[0] ;} ;

#~ $DB::single = 1 ;

my ($package, $file_name, $line) = caller() ;
$package ||= '' ;

my $location = "$file_name:$line" ;

if($sub)
	{
	die __PACKAGE__ . " not a sub reference '$sub_name' at $location:\n" unless 'CODE' eq ref $sub ;
	
	eval "*${class}::${sub_name} = \$sub;" ;
	push @{$buffer->{EXPANSIONS}}, {CALLER => [caller()],  SUB_REF => $sub_name} ;
	}
else
	{
	# load the named sub from the caller package
	
	die __PACKAGE__ . " error exapnding with undefined named sub at $location\n" unless defined $sub_name and $sub_name ne '' ;

	my $found_sub ;
	eval "\$found_sub = ${package}->can('${sub_name}') ;" ;
	die __PACKAGE__ . " error exapnding with named sub '$sub_name' at $location.\n" unless defined $found_sub ;

	eval "*${class}::${sub_name} = \\\&$package\::${sub_name};" ;
	die __PACKAGE__ . " error exapnding with named sub ''$sub_name' at $location:\n$@\n" if $@ ;

	push @{$buffer->{EXPANSIONS}}, {CALLER => [$package, $file_name, $line],  SUB_REF_IN_CALLER_SPACE => $sub_name} ;
	}
}

#-------------------------------------------------------------------------------

sub PrintExpansionHistory
{

=head2 PrintExpansionHistory

Displays the expansion done to the buffer

=cut

my $buffer = shift ;
my $message = shift || '' ;

my ($package, $file_name, $line) = caller() ;
$message .= " @ '$file_name:$line'" ;

print DumpTree($buffer->{EXPANSIONS}, $message) ;
}

#-------------------------------------------------------------------------------

sub Do
{

=head2 Do

Let you run any perl code on the buffer. The variable $buffer is made available in your perl code.

  ($result, $message) = $buffer->Do("# comment\n\$buffer->Insert('bar') ;") ;
  is($buffer->GetText(), "bar", 'buffer contains \'bar\'' ) ;

Returns (1) on success and (0, "error message") on failure.

=cut

my $buffer = shift ;
my $perl_script = shift || '' ;

our $buffer = $buffer ;
eval $perl_script ;

if($@)
	{
	$buffer->PrintError("\n* Failed evaluating buffer command *\n$perl_script\n$@\n") ;
	return(0, $@) ;
	}
else
	{
	return(1) ;
	}
}

#-------------------------------------------------------------------------------

sub PrintError
{

=head2 PrintError

This sub is called when an error occures. It should be overriden by the buffer user. We use this
sub to abstract error handling and allow different handling dependind on the buffer user.

If the user is a plain perl script, the error might just be logged while a dialogue might be displayed
if the user is a full UI.

=cut

my $buffer = shift ;
my $message = shift ;

my ($package, $file_name, $line) = caller() ;

confess "\n\n Using default PrintError wich dies !!\n\n$message" ;
}

#-------------------------------------------------------------------------------

sub GetText
{

=head2 GetText

Returns the buffer contents joined with "\n".

See L<GetTextAsArrayRef>.

=cut

my $buffer = shift ;

my $text = '' ;

for(0 .. ($buffer->GetNumberOfLines() - 2))
	{
	$text .= $buffer->GetLine($_)->{TEXT} . "\n" ;
	}

$text .= $buffer->GetLine(($buffer->GetNumberOfLines() - 1))->{TEXT} ;

return($text) ;
}

#-------------------------------------------------------------------------------

sub GetTextAsArrayRef
{

=head2 GetTextAsArrayRef

Returns a copy of the buffers content as an array reference.

See L<GetText>.

=cut

my $buffer = shift ;

my @text ;

for(0 .. ($buffer->GetNumberOfLines() - 1))
	{
	push @text, $buffer->GetLine($_)->{TEXT} ;
	}

return(\@text) ;
}

#-------------------------------------------------------------------------------

sub SetLineAttribute
{

=head2 SetLineAttribute

Attaches a named attribute to a line. 

  $buffer->SetLineAttribute(0, 'TEST', $some_data) ;
  $retrieved_data = $buffer->GetLineAttribute(0'TEST', $some_data) ;

=cut

my ($buffer, $line, $attribute_name, $attribute) = @_ ;
$line = $buffer->GetModificationLine() unless defined $line ;

$buffer->GetLine($line)->{$attribute_name} = $attribute ;
}

#-------------------------------------------------------------------------------

sub GetLineAttribute
{

=head2 SetLineAttribute

Retrieves  a named attribute from a line. 

  $buffer->SetLineAttribute(0, 'TEST', $some_data) ;
  $retrieved_data = $buffer->GetLineAttribute(0, 'TEST') ;

=cut

my ($buffer, $line, $attribute_name, $attribute) = @_ ;

$line = $buffer->GetModificationLine() unless defined $line ;

return($buffer->GetLine($line)->{$attribute_name}) ;
}

#-------------------------------------------------------------------------------

=head2 MarkedBufferAsEdited

Used to mak the buffer as edited after a modification. You should not need to use this function 
if you access the buffer through it's interface. Which you should always do.

=head2 MarkedBufferAsUndited

Used to mak the buffer as unedited You should not need to use this function.

=head2 IsBufferMarkedAsEdited

Used to query the buffer about its state. Returns (1) if the buffer was edit. (0) otherwise.

=head2 GetLastEditionTImestamp

Returns the time of the last edition.

=cut

sub IsBufferMarkedAsEdited {return($_[0]->{MARKED_AS_EDITED}) ;}
sub MarkBufferAsEdited { $_[0]->{MARKED_AS_EDITED} = 1 ; $_[0]->{EDITED_AT_TIME} = Time::HiRes::time() ;}
sub MarkBufferAsUnedited {$_[0]->{MARKED_AS_EDITED} = 0 ;}

sub GetLastEditionTImestamp {$_[0]->{EDITED_AT_TIME};}

#-------------------------------------------------------------------------------

sub GetNumberOfLines
{

=head2 GetNumberOfLines

Returns the number of lines in the buffer.

=cut

return($_[0]->{NODES}->GetNumberOfNodes()) ;
}

#------------------------------------------------------------------------------

sub GetLastLineIndex
{

=head2 GetLastfLineIndex

Returns theindex of the last line. the buffer always contains at least one line thus the last line index is always 0 or more.

=cut

return($_[0]->{NODES}->GetNumberOfNodes() - 1) ;
}

#------------------------------------------------------------------------------

sub GetModificationPosition
{

=head2 GetModificationPosition

Returns the position, line and character, where the next modification will occure.

=cut

return($_[0]->{MODIFICATION_LINE}, $_[0]->{MODIFICATION_CHARACTER}) ;
}

#-------------------------------------------------------------------------------

sub SetModificationPosition
{

=head2 SetModificationPosition

Sets the position, line and character, where the next modification will occure.

   $buffer->SetModificationPosition(0, 15) ;

=cut

my ($buffer, $line, $character) = @_ ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "\$buffer->SetModificationPosition($line, $character) ;", '   #', "# undo for \$buffer->SetModificationPosition($line, $character) ;", '   ') ;

$buffer->SetModificationLine($line) ;
$buffer->SetModificationCharacter($character) ;
}

#-------------------------------------------------------------------------------

sub OffsetModificationPosition
{

=head2 OffsetModificationPosition

Offset the position, line and character, where the next modification will occure. an exception is thrown if position is not valid

   $buffer->OffsetModificationPosition(0, 15) ;

=cut

my ($buffer, $line_offset, $character_offset) = @_ ;

my $undo_block = new Text::Editor::Vip::CommandBlock
			(
			  $buffer
			, "\$buffer->OffsetModificationPosition($line_offset, $character_offset) ;"
			, '   #'
			, "\$buffer->OffsetModificationPosition(-($line_offset), -($character_offset)) ;"
			, '   '
			) ;

$buffer->SetModificationLine($buffer->GetModificationLine() + $line_offset) ;
$buffer->SetModificationCharacter($buffer->GetModificationCharacter() + $character_offset) ;
}

#-------------------------------------------------------------------------------

sub OffsetModificationPositionGuarded
{

=head2 OffsetModificationPositionGuarded

Offsets the position, line and character, where the next modification will occure. Nothing happends if the new position is invalid

   $buffer->OffsetModificationPositionGuarded(0, 15) ;

=cut

my ($buffer, $line_offset, $character_offset) = @_ ;

my $new_line = $buffer->GetModificationLine() + $line_offset ;
my $new_character = $buffer->GetModificationCharacter() + $character_offset ;

if
	(
 	   $new_line < $buffer->GetNumberOfLines()
	&& 0 <= $new_line
	&& 0 <= $new_character
	)
	{
	$buffer->OffsetModificationPosition($line_offset, $character_offset) ;
	return(1) ;
	}
else
	{
	return(0) ;
	}
}

#-------------------------------------------------------------------------------

sub GetModificationLine
{

=head2 GetModificationLine

Returns the line where the next modification will occure.

=cut

return($_[0]->{MODIFICATION_LINE}) ;
}

#-------------------------------------------------------------------------------

sub SetModificationLine
{

=head2 SetModificationLine

Set the line where the next modification will occure.

=cut

my $buffer = shift ;
my $a_new_modification_line = shift ;

my $current_line = $buffer->GetModificationLine() ;

if
	(
	$a_new_modification_line < $buffer->GetNumberOfLines()
	&& 0 <= $a_new_modification_line
	)
	{
	if($a_new_modification_line != $current_line)
		{
		PushUndoStep
			(
			$buffer
			, "\$buffer->SetModificationLine($a_new_modification_line) ;"
			, "\$buffer->SetModificationLine($current_line) ;"
			) ;
			
		$buffer->{MODIFICATION_LINE} = $a_new_modification_line ;
		}
	}
else
	{
	$buffer->PrintError("Invalid line index: $a_new_modification_line. Number of lines: " . $buffer->GetNumberOfLines(). "\n") ;
	}
}

#-------------------------------------------------------------------------------

sub GetModificationCharacter
{

=head2 GetModificationLine

Returns the character where the next modification will occure.

=cut

my $buffer = shift ;
return($buffer->{MODIFICATION_CHARACTER}) ;
}

#-------------------------------------------------------------------------------

sub SetModificationCharacter
{

=head2 GetModificationLine

Sets the character where the next modification will occure.

=cut

my $buffer = shift ;
my $a_new_modification_character = shift ;

my $current_character = $buffer->GetModificationCharacter() ;

if(0 <= $a_new_modification_character)
	{
	if($a_new_modification_character != $current_character)
		{
		PushUndoStep
			(
			$buffer
			, "\$buffer->SetModificationCharacter($a_new_modification_character) ;"
			, "\$buffer->SetModificationCharacter($current_character) ;"
			) ;
			
		$buffer->{MODIFICATION_CHARACTER} = $a_new_modification_character ;
		}
	}
else
	{
	$buffer->PrintError("Invalid character index: $a_new_modification_character\n") ;
	}
}

#-------------------------------------------------------------------------------

sub GetLine
{

=head2 GetLine

Returns the Line object used by the buffer. This is a private sub and should not be used directly.

See L<GetLineText>.

=cut

my $buffer       = shift ;
my $a_line_index = shift ;

return( $buffer->{NODES}->GetNodeData($a_line_index) ) ;
}

#-------------------------------------------------------------------------------

sub GetLineText
{

=head2 GetLineText

Returns the text of the line passes as argument or the current modification line if no argument is passed.

  my $line_12_text = $buffer->GetLineText(12) ;
  my $current_line_text = $buffer->GetLineText() ;

=cut

my $buffer       = shift ;
my $a_line_index = shift ;

$a_line_index = $buffer->GetModificationLine() unless defined $a_line_index ;

if(0 <= $a_line_index && $a_line_index < $buffer->GetNumberOfLines())
	{
	return($buffer->GetLine($a_line_index)->{TEXT}) ;
	}
else
	{
	$buffer->PrintError("GetLineText: Invalid line index: $a_line_index. Number of lines: " . $buffer->GetNumberOfLines(). "\n") ;
	return('') ;
	}
}

#-------------------------------------------------------------------------------

sub GetLineTextWithNewline
{

=head2 GetLineTextWithNewline

Returns the text of the line passes as argument or the current modification line if no argument is passed. A "\n" is
appended if the line is not the last line in the buffer.

  my $line_12_text = $buffer->GetLineTextWithNewline(12) ;
  my $current_line_text = $buffer->GetLineTextWithNewline() ;

=cut

my $buffer       = shift ;
my $a_line_index = shift ;

$a_line_index = $buffer->GetModificationLine() unless defined $a_line_index ;

if(0 <= $a_line_index && $a_line_index < $buffer->GetNumberOfLines())
	{
	if($a_line_index == $buffer->GetLastLineIndex())
		{
		return($buffer->GetLine($a_line_index)->{TEXT}) ;
		}
	else
		{
		return($buffer->GetLine($a_line_index)->{TEXT} . "\n") ;
		}
	}
else
	{
	$buffer->PrintError("GetLineText: Invalid line index: $a_line_index. Number of lines: " . $buffer->GetNumberOfLines(). "\n") ;
	return('') ;
	}
}

#-------------------------------------------------------------------------------

sub GetLineLength
{

=head2 GetLineLength

Returns the length of the text of the line passes as argument or the current modification line if no argument is passed.

  my $line_12_text = $buffer->GetLineText(12) ;
  my $current_line_text = $buffer->GetLineText() ;

=cut

my $buffer = shift ;
my $a_line_index = shift ;

$a_line_index = $buffer->GetModificationLine() unless defined $a_line_index ;

return(length($buffer->GetLineText($a_line_index))) ;
}

#-------------------------------------------------------------------------------

sub Backspace
{

=head2 Backspace

Deletes characters backwards. The number of characters to delete is passed as an argument.
Doing a Backspace while at the begining of a line warps to the previous line.

=cut

my $buffer = shift ;
my $number_of_character_to_delete = shift || 0 ;

return if 0 >= $number_of_character_to_delete  ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "\$buffer->Backspace($number_of_character_to_delete) ;", '   #', "# undo for \$buffer->Backspace($number_of_character_to_delete)", '   ') ;

if($buffer->{SELECTION}->IsEmpty())
	{
	for (1 .. $number_of_character_to_delete)
		{
		
		my $current_line     = $buffer->GetModificationLine() ;
		my $current_position = $buffer->GetModificationCharacter() ;

		if($current_position != 0)
			{
			$buffer->SetModificationCharacter($current_position - 1) ;
		
			if($current_position <= $buffer->GetLineLength($current_line))
				{
				$buffer->Delete(1) ;
				}
			#else
				#after end of line, already modified position
			}
		else
			{
			if($current_line != 0)
				{
				$buffer->SetModificationLine($current_line -1) ;
				
				#Move to end of line
				$buffer->SetModificationCharacter
					(
					$buffer->GetLineLength
						(
						$buffer->GetModificationLine()
						)
					) ;
					
				$buffer->Delete(1) ;
				}
			#else
				# at first line
			}
		}
	}
else
	{
	$buffer->DeleteSelection() ;
	$buffer->Backspace($number_of_character_to_delete - 1) ;
	}
}

#-------------------------------------------------------------------------------

sub ClearLine
{

=head2 ClearLine

Removes all text from  the passed line index or the current modification line if no argument is given.
The line itself is not deleted and the modification position is not modified.

  $buffer->ClearLine(0) ;

=cut

my $buffer = shift ;
my $line_index = shift ;

$line_index = $buffer->GetModificationLine() unless defined $line_index ;

my $modification_line = $buffer->GetModificationLine() ;
my $modification_character = $buffer->GetModificationCharacter() ;

if(0 <= $line_index && $line_index < $buffer->GetNumberOfLines())
	{
	my $line = $buffer->GetLine($line_index) ;
	my $text = $line->{TEXT} ;
	$line->{TEXT} = '' ;
	
	$buffer->MarkBufferAsEdited() ;
	
	PushUndoStep
		(
		$buffer
		, "\$buffer->ClearLine($line_index) ;"
		, [
		    "\$buffer->SetModificationPosition($line_index, 0) ;" 
		  , '$buffer->Insert("' . Stringify($text) .'") ;' 
		  , "\$buffer->SetModificationPosition($modification_line, $modification_character) ;" 
		  ]
		
		) ;
	}
else
	{
	$buffer->PrintError("GetLineText: Invalid line index: $line_index. Number of lines: " . $buffer->GetNumberOfLines(). "\n") ;
	}
}

#-------------------------------------------------------------------------------

sub Delete
{

=head2 Delete

Deleted, from the modification position, the number of characters passed as argument.

Deletes the selection if it exists; the deleted selection decrements the number of character to delete argument

=cut

my $buffer = shift ;
my $a_number_of_character_to_delete = shift || 0 ;

return if 0 >= $a_number_of_character_to_delete ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "\$buffer->Delete($a_number_of_character_to_delete) ;", '   #', "# undo for \$buffer->Delete($a_number_of_character_to_delete)", '   ') ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	$buffer->DeleteSelection() ;
	$a_number_of_character_to_delete-- ;
	}

return if 0 >= $a_number_of_character_to_delete ;

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;
my $line_length = $buffer->GetLineLength() ;

if($modification_character < $line_length)
	{
	my $line_ref = \($buffer->GetLine($modification_line)->{TEXT}) ;
	
	my $character_to_delete_on_this_line = min
						(
						  $line_length - $modification_character
						, $a_number_of_character_to_delete
						) ;
	my $deleted_text = substr
		(
		  $$line_ref
		, $modification_character
		, $character_to_delete_on_this_line
		, ''
		) ;
		
	PushUndoStep
		(
		  $buffer
		, "# deleting in current line"
		, [
		    '$buffer->Insert("' . Stringify($deleted_text) . '") ;'
		  , "\$buffer->SetModificationPosition($modification_line, $modification_character) ;"
		  ]
		) ;
		
	$a_number_of_character_to_delete -= $character_to_delete_on_this_line ;
	}
else
	{
	# at end of line, copy next line to this line
	
	return if $modification_line == ($buffer->GetNumberOfLines() - 1) ;
	
	$buffer->Insert($buffer->GetLine($modification_line + 1)->{TEXT}) ;
	$buffer->DeleteLine($modification_line + 1) ;
	$buffer->SetModificationPosition($modification_line, $modification_character) ;
	
	$a_number_of_character_to_delete-- ; # delete '\n'
	}
	
if($a_number_of_character_to_delete)
	{
	$buffer->Delete($a_number_of_character_to_delete) ;
	}

$buffer->MarkBufferAsEdited() ;
}

#-------------------------------------------------------------------------------

sub DeleteLine
{

=head2 DeleteLine

Deleted, the line passed as argument. if no argument is passed, the current line is deleted.
The selection and modification position are not modified.

=cut

my $buffer                   = shift ;
my $a_line_to_delete_index = shift ;

$a_line_to_delete_index = $buffer->GetModificationLine() unless defined $a_line_to_delete_index ;

return if $buffer->GetNumberOfLines() == 1 ; # buffer always has at least one line

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

my $text = Stringify($buffer->GetLineText($a_line_to_delete_index)) ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "# DeleteLine", '    ', '# undo for DeleteLine', '   ') ;

if($a_line_to_delete_index != ($buffer->GetNumberOfLines() - 1))
	{
	PushUndoStep
		(
		  $buffer
		, "\$buffer->DeleteLine($a_line_to_delete_index) ;"
		, [
		    "\$buffer->SetModificationPosition($a_line_to_delete_index, 0) ;"
		  , "\$buffer->Insert(\"$text\\n\") ;"
		  , "\$buffer->SetModificationPosition($modification_line, $modification_character) ;"
		  ]
		) ;
	}
else
	{
	#deleting last line 
	my $previous_line = $a_line_to_delete_index - 1 ;
	my $end_of_previous_line = $buffer->GetLineLength($previous_line) ;
	
	PushUndoStep
		(
		  $buffer
		, "\$buffer->DeleteLine($a_line_to_delete_index) ;"
		, [
		    "\$buffer->SetModificationPosition($previous_line, $end_of_previous_line) ;"
		  , "\$buffer->Insert(\"\\n$text\") ;"
		  , "\$buffer->SetModificationPosition($modification_line, $modification_character) ;"
		  ]
		) ;
	}
	
$buffer->{NODES}->DeleteNode($a_line_to_delete_index) if $buffer->GetNumberOfLines() > 1 ;
$buffer->MarkBufferAsEdited() ;
}

#-------------------------------------------------------------------------------

sub InsertNewLine
{

=head2 InsertNewLine

Inserts a new line at the modification position. If the modification position is after the end of the 
current line, spaces are used to pad the current line.

InsertNewLine takes one parameter that can be set to  SMART_INDENTATION or NO_SMART_INDENTATION.
If SMART_INDENTATION is used (default) , B<IndentNewLine> is called. B<IndentNewLine> does nothing by default.
This lets you define your own indentation strategy. See  B<IndentNewLine>.

  $buffer->Insert("hi\nThere\nWhats\nYour\nName\n") ;

=cut

my $buffer                  = shift ;
my $use_smart_indentation = shift || SMART_INDENTATION ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "InsertNewLine(\$buffer, $use_smart_indentation) ;", '   #', '# undo for InsertNewLine($use_smart_indentation)', '   ') ;

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

my $buffer_line = $buffer->GetLine($modification_line) ;
my $buffer_line_text = $buffer_line->{TEXT} ;

my $next_line_text = '' ;

if($modification_character < length $buffer_line_text)
	{
	$next_line_text = substr($buffer_line_text, $modification_character) ;
	}

$buffer_line_text = substr($buffer_line_text, 0, $modification_character) ;
								
$buffer_line->{TEXT} = $buffer_line_text ;
$buffer->{NODES}->InsertAfter($modification_line,  {TEXT => $next_line_text} ) ;

$buffer->SetModificationPosition($modification_line + 1, 0) ;

PushUndoStep
	(
	$buffer
	, "\$buffer->InsertNewLine($use_smart_indentation) ;"
	, '$buffer->Backspace(1) ;'	
	) ;

$buffer->IndentNewLine($modification_line + 1) if $use_smart_indentation ;

$buffer->MarkBufferAsEdited() ;
}

#-------------------------------------------------------------------------------

sub Stringify
{

=head2 Stringify

Quotes a string or an array of string so it can be serialized in perl code

=cut

my $text_to_stringify = shift ;
$text_to_stringify = '' unless defined $text_to_stringify ;

my $stringified_text = '' ;

my @text_to_stringify = ref($text_to_stringify) eq 'ARRAY' ? @$text_to_stringify: ($text_to_stringify) ;

for(@text_to_stringify)
	{
	s/\\/\\\\/g ;
	
	s/\$/\\\$/g ;
	s/\@/\\\@/g ;
	s/"/\\"/g ;
	
	s/\n/\\n/g ;
	s/\t/\\t/g ;
	s/\r/\\r/g ;

	$stringified_text .= $_ ;
	}
	
return($stringified_text) ;
}

#-------------------------------------------------------------------------------

sub Insert
{

=head2 Insert

Inserts a string or a list of strings, passed as an array reference, into the buffer.

  $buffer->Insert("bar") ;
  
  my @text = ("Someone\n", "wants me\nNow") ;
  $buffer->Insert(\@text);
  
  $buffer->Insert("\t something \n new") ;

Only "\n" is considered special and forces the addition of a new line in the buffer.

B<Insert> takes a second argument . When set to SMART_INDENTATION (the default), 
B<IndentNewLine> is called to indent the newly inserted line. The default B<IndentNewLine>
does nothing but you can override it to implement any indentation you please. If you want to 
insert raw text, pass NO_SMART_INDENTATION as a second argument.

NO_SMART_INDENTATION is defined in Text::Editor::Vip::Buffer::Constants.

=cut

my $buffer                = shift ;
my $text_to_insert        = shift ;
my $use_smart_indentation = shift || SMART_INDENTATION ;

$text_to_insert ='' unless defined $text_to_insert ;
my @text_to_insert ;

if(ref($text_to_insert) eq 'ARRAY')
	{
	@text_to_insert = @$text_to_insert ;
	}
else
	{
	@text_to_insert = ($text_to_insert) ;
	}

my $stringified_text_to_insert = Stringify($text_to_insert);

my $undo_block = new Text::Editor::Vip::CommandBlock
			(
			$buffer
			, "\$buffer->Insert(\"$stringified_text_to_insert\", $use_smart_indentation) ;", '   #'
			, "# undo for \$buffer->Insert(\"$stringified_text_to_insert\", $use_smart_indentation)", '   '
			) ;

$buffer->DeleteSelection() ;

for(@text_to_insert)
	{
	for(split /(\n)/) # transform a\nb\nccc into 3 lines
		{
		if("\n" eq $_)
			{
			$buffer->InsertNewLine($use_smart_indentation) ;
			}
		else
			{
			my $line_ref = \($buffer->GetLine($buffer->GetModificationLine())->{TEXT}) ;
			my $modification_character = $buffer->GetModificationCharacter() ;
			my $line_length = length($$line_ref) ;
			
			#do we need padding
			if($modification_character - $line_length > 0)
				{
				$buffer->SetModificationCharacter($line_length) ;
				$buffer->Insert(' ' x ($modification_character - $line_length)) ;
				}
				
			# insert characters
			substr($$line_ref, $modification_character, 0, $_) ;
				
			my $text_to_insert_length = length($_) ;
			$stringified_text_to_insert = Stringify($_);
			
			PushUndoStep
				(
				$buffer
				, "\$buffer->Insert(\"$stringified_text_to_insert\", $use_smart_indentation) ;"
				, "\$buffer->Delete($text_to_insert_length) ;"
				) ;
				
			$buffer->SetModificationCharacter($modification_character + length()) ;
			}
		}
		
	$buffer->MarkBufferAsEdited() ;
	}
}

#-------------------------------------------------------------------------------

1 ;

=head1 PLUGINS

Vip::Buffer has a very simple plugin system. You can add a function to  the buffer with
L<ExpandWith>, L<LoadAndExpandWith> and  L<ExpandedWithOrLoad>. The functions
added through plugins are made available to the instance, calling the plugin sub, only. 

Think of it as a late inheritence that does the job it needs to do.

Perl is full of wonders.

=head1 BUGS

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net
	http:// no web site

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
