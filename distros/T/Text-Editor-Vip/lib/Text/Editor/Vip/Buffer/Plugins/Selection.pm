
package Text::Editor::Vip::Buffer::Plugins::Selection;

use strict;
use warnings ;

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

=head1 NAME

Text::Editor::Vip::Buffer::Plugins::Selecton- Add extra selection commands to Vip::Buffer

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer
  
=head1 DESCRIPTION

Adds Selection commands to the buffer.

=head1 Functions

=cut

#-------------------------------------------------------------------------------

sub IsSelectionEmpty
{

=head2 IsSelectionEmpty

=cut

my $buffer = shift ;

return($buffer->{SELECTION}->IsEmpty()) ;
}

#-------------------------------------------------------------------------------

sub ClearSelection
{

=head2 ClearSelection

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->Clear()) ;
}

#-------------------------------------------------------------------------------

sub SetSelectionAnchor($$) # Expects line and character
{

=head2 SetSelectionAnchor

=cut

my $buffer = shift ;
my ($line, $character) = @_ ;

my ($original_line, $original_character) = $buffer->{SELECTION}->GetAnchor() ;

my $undo_block = new Text::Editor::Vip::CommandBlock
			(
			  $buffer
			, "\$buffer->SetSelectionAnchor($line, $character) ;"
			, '   #'
			, "\$buffer->SetSelectionAnchor($original_line, $original_character) ;"
			, '   #'
			) ;

return($buffer->{SELECTION}->SetAnchor($line, $character)) ;
}

#-------------------------------------------------------------------------------

sub SetSelectionLine($$) # Expects line and character
{

=head2 SetSelectionLine

=cut

my $buffer = shift ;
my ($line, $character) = @_ ;

my ($original_line, $original_character) = $buffer->{SELECTION}->GetLine() ;

my $undo_block = new Text::Editor::Vip::CommandBlock
			(
			  $buffer
			, "\$buffer->SetSelectionLine($line, $character) ;"
			, '   #'
			, "\$buffer->SetSelectionLine($original_line, $original_character) ;"
			, '   #'
			) ;

return($buffer->{SELECTION}->SetLine(@_)) ;
}

#-------------------------------------------------------------------------------

sub GetSelectionBoundaries
{

=head2 GetSelectionBoundaries

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->GetBoundaries()) ;
}

#-------------------------------------------------------------------------------

sub GetSelectionStartLine
{

=head2 GetSelectionStartLine

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->GetStartLine()) ;
}

#-------------------------------------------------------------------------------

sub GetSelectionStartCharacter
{

=head2 GetSelectionStartCharacter

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->GetStartCharacter()) ;
}

#-------------------------------------------------------------------------------

sub GetSelectionEndLine
{

=head2 GetSelectionEndLine

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->GetEndLine()) ;
}

#-------------------------------------------------------------------------------

sub GetSelectionEndCharacter
{

=head2 GetSelectionEndCharacter

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->GetEndCharacter()) ;
}

#-------------------------------------------------------------------------------

sub IsCharacterSelected($$) # Expects a line and a character index
{

=head2 IsCharacterSelected

Returns 'true' if the  character is within the boundaries of the selection.

  $buffer->IsCharacterSelected($line, $character) ;
  
=cut

my $buffer = shift ;
return($buffer->{SELECTION}->IsCharacterSelected(@_)) ;
}

#-------------------------------------------------------------------------------

sub IsLineSelected($)
{

=head2

Returns 'true' if the  line is within the boundaries of the selection.

  $buffer->IsLineSelected($line) ;
  
=cut

my $buffer = shift ;
return($buffer->{SELECTION}->IsLineSelected(@_)) ;
}

#-------------------------------------------------------------------------------

sub SelectAll
{

=head2 SelectAll

=cut

my $buffer = shift ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "#\$buffer->SelectAll() ;", '   ', "# undo for \$buffer->SelectAll() ;", '   ') ;

$buffer->SetSelectionAnchor(0, 0) ;
$buffer->SetSelectionLine
	(
	$buffer->GetNumberOfLines() - 1 
	, $buffer->GetLineLength($buffer->GetNumberOfLines() - 1)
	) ;
}

#-------------------------------------------------------------------------------

sub SetSelectionAnchorAtCurrentPosition
{

=head2 SetSelectionAnchorAtCurrentPosition

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchor
		(
		  $buffer->GetModificationLine()
		, $buffer->GetModificationCharacter()
		) ;
}

#-------------------------------------------------------------------------------

sub ExtendSelection
{

=head2 ExtendSelection

Extends the selection to the current modification position.

=cut

my $buffer = shift ;
$buffer->SetSelectionLine
		(
		  $buffer->GetModificationLine()
		, $buffer->GetModificationCharacter()
		) ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionToEndOfLine
{

=head2 ExtendSelectionToEndOfLine

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('MoveToEndOfLineNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->MoveToEndOfLineNoSelectionClear() ;
$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionToEndOfBuffer
{

=head2 ExtendSelectionToEndOfBuffer

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;

my $number_of_lines = $buffer->GetNumberOfLines() ;

$buffer->SetModificationLine($number_of_lines - 1) ;
$buffer->ExtendSelectionToEndOfLine() ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionToStartOfBuffer
{

=head2 ExtendSelectionToStartOfBuffer

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;

$buffer->SetModificationPosition(0, 0) ;

$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionHome
{

=head2 ExtendSelectionHome

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;

$buffer->ExpandedWithOrLoad('GetFirstNonSpacePosition', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

my $first_word_position = $buffer->GetFirstNonSpacePosition($buffer->GetModificationLine()) ;

if($first_word_position == $buffer->GetModificationCharacter())
	{
	$buffer->SetModificationCharacter(0) ;
	}
else
	{
	$buffer->SetModificationCharacter($first_word_position) ;
	}

$buffer->ExtendSelection() ;
}

#-----------------------------------------------------------------------

sub ExtendSelectionLeft
{

=head2 ExtendSelectionLeft

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;

if(0 != $buffer->GetModificationCharacter())
	{
	$buffer->SetModificationCharacter($buffer->GetModificationCharacter() - 1) ;
	}

$buffer->ExtendSelection() ;
}

#-----------------------------------------------------------------------

sub ExtendSelectionRight
{

=head2 ExtendSelectionRight

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;

$buffer->SetModificationCharacter($buffer->GetModificationCharacter() + 1) ;
$buffer->ExtendSelection() ;
}

#-----------------------------------------------------------------------

sub ExtendSelectionUp
{

=head2 ExtendSelectionUp

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->ExpandedWithOrLoad('MoveUpNoSelectionClea', 'Text::Editor::Vip::Buffer::Plugins::Display') ;

my $modification_line = $buffer->GetModificationLine() ;

if($modification_line != 0 )
	{
	$buffer->SetModificationCharacter
		(
		$buffer->GetCharacterPositionInText
			(
			  $modification_line - 1
			, $buffer->GetCharacterDisplayPosition
					(
					  $modification_line
					, $buffer->GetModificationCharacter()
					)
			)
		) ;

	$buffer->SetModificationLine($modification_line - 1) ;
	}
#else
	# at first line
	
$buffer->ExtendSelection() ;
}

#-----------------------------------------------------------------------

sub ExtendSelectionDown
{

=head2 ExtendSelectionDown

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;

$buffer->ExpandedWithOrLoad('GetCharacterDisplayPosition', 'Text::Editor::Vip::Buffer::Plugins::Display') ;

my $modification_line = $buffer->GetModificationLine() ;

if($modification_line != ($buffer->GetNumberOfLines() - 1))
	{
	$buffer->SetModificationCharacter
		(
		$buffer->GetCharacterPositionInText
			(
			  $modification_line + 1
			, $buffer->GetCharacterDisplayPosition
							(
							  $modification_line
							, $buffer->GetModificationCharacter()
							)
			)
		) ;
	
	$buffer->SetModificationLine($modification_line + 1) ;
	}
#else
	# at last line

$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

sub SelectWord
{

=head2 SelectWord

Selects the word at the current position.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('MoveToEndOfWordNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->MoveToPreviousWord() ;
$buffer->MoveToNextWord() ;
$buffer->SetSelectionAnchorAtCurrentPosition() ;
$buffer->MoveToEndOfWordNoSelectionClear() ;
$buffer->ExtendSelection() ;
}
	
#-----------------------------------------------------------------------

sub ExtendSelectionToBeginingOfWord
{

=head2 ExtendSelectionToBeginingOfWord

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('MoveToBeginingOfWordNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->MoveToBeginingOfWordNoSelectionClear() ;
$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionToNextWord
{

=head2 ExtendSelectionToNextWord

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->ExpandedWithOrLoad('MoveToEndOfWordNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->MoveToEndOfWordNoSelectionClear() ;
$buffer->ExtendSelection() ;
}

#-----------------------------------------------------------------------

sub ExtendSelectionToPreviousWord
{

=head2 ExtendSelectionToPreviousWord

=cut

my $buffer = shift ;
$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->ExpandedWithOrLoad('MoveToPreviousWordNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->MoveToPreviousWordNoSelectionClear() ;
$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

1 ;

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
