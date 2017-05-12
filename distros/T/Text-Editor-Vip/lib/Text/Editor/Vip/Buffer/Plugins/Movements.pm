
package Text::Editor::Vip::Buffer::Plugins::Movements;

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

Text::Editor::Vip::Buffer::Plugins::Movements- Add movement commands to Vip::Buffer

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer
  
=head1 DESCRIPTION

Add movement commands to Vip::Buffer. The commands use tab and a virtual buffer

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub SetModificationPositionAtSelectionStart
{

=head2 SetModificationPositionAtSelectionStart

=cut

my $buffer = shift ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	$buffer->SetModificationPosition($buffer->{SELECTION}->GetBoundaries()) ;
	}
}

#-------------------------------------------------------------------------------

sub GetFirstNonSpacePosition
{

=head2 GetFirstNonSpacePosition

Finds the first non space position at the B<line> argument or the current line if B<line> is not passed.

=cut

my $buffer     = shift ;
my $line_index = shift ;

$line_index = $buffer->GetModificationLine() unless defined $line_index ;

my $text = $buffer->GetLineText($line_index) ; 
 
if($text =~ /^([\t ]+)/)
	{
	return(length($1)) ;
	}
else
	{
	return(0) ;
	}
}

#-------------------------------------------------------------------------------

sub MoveToTopOfBuffer
{

=head2 MoveToTopOfBuffer

Clears the buffer and Sets the modification position at 0,0.

=cut

my $buffer = shift ;
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationLine(0) ;
$buffer->SetModificationCharacter(0) ;
}

#-------------------------------------------------------------------------------

sub MoveToEndOfBuffer
{

=head2 MoveToEndOfBuffer

Clears the selection and sets the modification position after the last character of the last line.

=cut

my $buffer = shift ;
$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationLine($buffer->GetNumberOfLines() - 1) ;
$buffer->MoveToEndOfLine() ;
}

#-------------------------------------------------------------------------------

sub MoveToEndOfLine
{

=head2 MoveToEndOfLine

Moves to the end of the line or the end of the selection if any.

=cut

my $buffer = shift ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	$buffer->MoveToEndOfSelectionNoClear() ;
	$buffer->{SELECTION}->Clear() ;
	}
else
	{
	$buffer->MoveToEndOfLineNoSelectionClear() ;
	}
}

#-------------------------------------------------------------------------------

sub MoveToEndOfSelectionNoClear
{

=head2 MoveToEndOfSelectionNoClear

Moves the modification to the end of the selection without clearing the selection.

=cut

my $buffer = shift ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	my (
	$selection_start_line, $selection_start_character
	, $selection_end_line, $selection_end_character
	) = $buffer->BoxSelection() ;
	
	$buffer->SetModificationPosition($selection_end_line, $selection_end_character) ;
	}
}

#-------------------------------------------------------------------------------

sub MoveToEndOfLineNoSelectionClear
{

=head2 MoveToEndOfLineNoSelectionClear

Moves to the end of the current line without clearing the selection (if any).

=cut

my $buffer = shift ;
$buffer->SetModificationCharacter
		(
		$buffer->GetLineLength
			(
			$buffer->GetModificationLine()
			)
		) ;
}

#-------------------------------------------------------------------------------

sub MoveHome # jumping frog
{

=head2 MoveHome

Moves the modification position to the begining of the line or to the first word (jumping frog style)

=cut

my $buffer = shift ;
my $first_non_space_position = $buffer->GetFirstNonSpacePosition($buffer->GetModificationLine()) ;

if($buffer->{SELECTION}->IsEmpty())
	{
	if($buffer->GetModificationCharacter() == $first_non_space_position)
		{
		$buffer->SetModificationCharacter(0) ;
		}
	else
		{
		$buffer->SetModificationCharacter($first_non_space_position) ;
		}
	}
else
	{
	$buffer->MoveToStartOfSelectionNoClear() ;
	$buffer->{SELECTION}->Clear() ;
	}		
}

#-------------------------------------------------------------------------------

sub MoveToStartOfSelectionNoClear
{

=head2 MoveToStartOfSelectionNoClear

Sets the modification position at the start of the selection, if any, without clearing the selection.

=cut

my $buffer = shift ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	my (
	$selection_start_line, $selection_start_character
	, $selection_end_line, $selection_end_character
	) = $buffer->BoxSelection() ;
	
	$buffer->SetModificationPosition($selection_start_line, $selection_start_character) ;
	}
}


#-------------------------------------------------------------------------------

sub MoveLeft
{

=head2 MoveLeft

Moves left, clearing the selection if any.

=cut

my $buffer = shift ;

# position  at begining of selection if any
$buffer->MoveLeftNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveLeftNoSelectionClear
{

=head2 MoveLeftNoSelectionClear

Moves left, no selection clearing is done.

=cut

my $buffer = shift ;

if($buffer->{SELECTION}->IsEmpty())
	{
	if(0 != $buffer->GetModificationCharacter())
		{
		$buffer->SetModificationCharacter($buffer->GetModificationCharacter() - 1) ;
		}
	#~ else
		#~ {
		#~ #uncomment to line wrap
		#~ my $modification_line = $buffer->GetModificationLine() ;
		#~ if(0 != $modification_line)
			#~ {
			#~ my $previous_line = $modification_line - 1 ;
			#~ $buffer->SetModificationLine($previous_line) ;
			#~ $buffer->SetModificationCharacter($buffer->GetLineLength($previous_line) ;
			#~ }
		#~ #else
			#~ # begining of document
		#~ }
	}
else
	{
	$buffer->MoveToStartOfSelectionNoClear() ;
	}
}

#-------------------------------------------------------------------------------

sub MoveRight
{

=head2 MoveRight

Moves Right, clearing the selection if any.

=cut

my $buffer = shift ;

# position  at begining of selection if any
$buffer->MoveRightNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveRightNoSelectionClear
{

=head2 MoveRightNoSelectionClear

Moves right without clearing the selection.

=cut

my $buffer = shift ;

if($buffer->{SELECTION}->IsEmpty())
	{
	# we don't limit the character position horizontaly
	
	$buffer->SetModificationCharacter($buffer->GetModificationCharacter() + 1) ;
	
	#~ #pseudo code to wrap
	#~ if(current_character == end_of_line)
		#~ {
		#~ if(line != last_line)
			#~ {
			#~ line = line++ ;
			#~ character = 0 ;
			#~ }
		#~ }
	#~ else
		#~ {
		#~ current_character++ ;
		#~ }
	}
else
	{
	$buffer->MoveToEndOfSelectionNoClear() ;
	}
}

#-------------------------------------------------------------------------------

sub MoveUp
{

=head2 MoveUp

Moves up, clearing the selection.

=cut

my $buffer = shift ;

$buffer->MoveUpNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveUpNoSelectionClear
{

=head2 MoveUpNoSelectionClear

Moves up, without clearing the selection.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('GetCharacterDisplayPosition', 'Text::Editor::Vip::Buffer::Plugins::Display') ;

if($buffer->{SELECTION}->IsEmpty())
	{
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
	}
else
	{
	$buffer->MoveToStartOfSelectionNoClear() ;
	}
}

#-------------------------------------------------------------------------------

sub MoveDown
{

=head2 MoveDown

Moves the modification position down, clearing the selection.

=cut

my $buffer = shift ;
$buffer->MoveDownNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveDownNoSelectionClear
{

=head2 MoveDownNoSelectionClear

Moves the modification position down, without clearing the selection. Moves to the end of the selection if any.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('GetCharacterDisplayPosition', 'Text::Editor::Vip::Buffer::Plugins::Display') ;

if($buffer->{SELECTION}->IsEmpty())
	{
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
	}
else
	{
	$buffer->MoveToEndOfSelectionNoClear() ;
	}
}

#-------------------------------------------------------------------------------

sub MoveToBeginingOfWord
{

=head2 MoveToBeginingOfWord

Moves the modification position to the begining of the current word, clearing the selection.

=cut

my $buffer = shift ;

$buffer->{SELECTION}->Clear() ;
return($buffer->MoveToBeginingOfWordNoSelectionClear()) ;
}

#-------------------------------------------------------------------------------

sub MoveToBeginingOfWordNoSelectionClear
{

=head2 MoveToBeginingOfWordNoSelectionClear

Moves the modification position to the begining of the current word, without clearing the selection. Return 'true' if 
the modification position was changed, 'false' if there was no current word.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('GetAlphanumericFilter', 'Text::Editor::Vip::Buffer::Plugins::GetWord') ;

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

my $search_end ;
if($modification_character > $buffer->GetLineLength())
	{
	$search_end = $buffer->GetLineLength() ;
	}
else
	{
	$search_end = $modification_character ;
	}

my $character_regex = $buffer->GetAlphanumericFilter() ;
my $text            = reverse(substr($buffer->GetLineText($modification_line), 0, $search_end)) ;

if($text =~ /^($character_regex)/)
	{
	#~ print "*** $modification_character,  <$1> " . length($1) ."\n" ;
	$buffer->SetModificationCharacter($search_end - length($1)) ;
	return(1) ;
	}
else
	{
	return(0) ;
	}
}

#-------------------------------------------------------------------------------

sub MoveToEndOfWord
{

=head2 MoveToEndOfWord

Moves the modification position to the end of the current word, clearing the selection.

=cut

my $buffer = shift ;

$buffer->MoveToEndOfWordNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveToEndOfWordNoSelectionClear
{

=head2 MoveToEndOfWordNoSelectionClear

Moves the modification position to the end of the current word, without clearing the selection. Return 'true' if 
the modification position was changed, 'false' if there was no current word.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('GetAlphanumericFilter', 'Text::Editor::Vip::Buffer::Plugins::GetWord') ;

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

my $search_start ;
if($modification_character >= $buffer->GetLineLength())
	{
	$search_start = $buffer->GetLineLength() ;
	}
else
	{
	$search_start = $modification_character ;
	}

my $character_regex = $buffer->GetAlphanumericFilter() ;
my $text            = substr($buffer->GetLineText($modification_line), $search_start) ;

if($text =~ /($character_regex)/)
	{
	$buffer->SetModificationCharacter($modification_character + index($text, $1) + length($1)) ;
	}
else
	{
	my $number_of_lines = $buffer->GetNumberOfLines() ;
	
	for(my $current_line_index = $modification_line + 1 ; $current_line_index < $number_of_lines ; $current_line_index++)
		{
		$text = $buffer->GetLineText($current_line_index) ;
		
		if($text =~ /($character_regex)/)
			{
			$buffer->SetModificationLine($current_line_index) ;
			$buffer->SetModificationCharacter(index($text, $1) + length($1)) ;
			last ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub MoveToNextWord
{

=head2 MoveToNextWord

Sets the modification position at the begining of the next word, potentialy on another line, and clears
the selection.

=cut

my $buffer = shift ;

$buffer->MoveToNextWordNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveToNextWordNoSelectionClear
{

=head2 MoveToNextWordNoSelectionClear

Sets the modification position at the begining of the next word, potentialy on another line, without clearing
the selection.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('GetAlphanumericFilter', 'Text::Editor::Vip::Buffer::Plugins::GetWord') ;

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;
my $text = $buffer->GetLineText($modification_line) ;

my $character_regex = $buffer->GetAlphanumericFilter() ;

my ($search_start, $skip_size) ;

if($modification_character >= $buffer->GetLineLength())
	{
	$search_start = $buffer->GetLineLength() ;
	$skip_size = 0 ;
	}
else
	{
	if(substr($text, $modification_character) =~ /^($character_regex)/)
		{
		$skip_size = length($1); 
		$search_start = $modification_character + $skip_size ;
		}
	else
		{
		$skip_size = 0 ;
		$search_start = $modification_character ;
		}
	}

$text = substr($text, $search_start) ;

if($text =~ /\W($character_regex)/)
	{
	$buffer->SetModificationCharacter($modification_character + index($text, $1) + $skip_size) ;
	}
else
	{
	my $number_of_lines = $buffer->GetNumberOfLines() ;
	
	for(my $current_line_index = $modification_line + 1 ; $current_line_index < $number_of_lines ; $current_line_index++)
		{
		$text = $buffer->GetLineText($current_line_index) ;
		
		if($text =~ /^($character_regex)/ || $text =~ /\W($character_regex)/)
			{
			$buffer->SetModificationLine($current_line_index) ;
			$buffer->SetModificationCharacter(index($text, $1)) ;
			last ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub MoveToPreviousWord
{

=head2 MoveToPreviousWord

Sets the modification position at the begining of the previous word, potentialy on another line, and clears
the selection.

=cut

my $buffer = shift ;

$buffer->MoveToPreviousWordNoSelectionClear() ;
$buffer->{SELECTION}->Clear() ;
}

#-------------------------------------------------------------------------------

sub MoveToPreviousWordNoSelectionClear
{

=head2 MoveToPreviousWordNoSelectionClear

Sets the modification position at the begining of the previous word, potentialy on another line, without clearing
the selection.

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('GetAlphanumericFilter', 'Text::Editor::Vip::Buffer::Plugins::GetWord') ;

my $character_regex = $buffer->GetAlphanumericFilter() ;
my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

if($modification_character >= $buffer->GetLineLength())
	{
	$modification_character = $buffer->GetLineLength() ;
	
	#handle case where we are after the line end and a word ends the line
	my $text = $buffer->GetLineText($modification_line) ;
	
	if(reverse(substr($text, 0, $modification_character)) =~ /^($character_regex)/)
		{
		$buffer->SetModificationCharacter($modification_character - length($1)) ;
		return ;
		}
	}

my $text = $buffer->GetLineText($modification_line) ;

my ($search_end, $skip_size) = ($modification_character, 0) ;

if($modification_character <= 0)
	{
	$search_end = 0 ;
	$skip_size = 0 ;
	}
elsif($modification_character == $buffer->GetLineLength())
	{
	#skip nothing if at end of line
	$search_end = $modification_character ;
	$skip_size = 0 ;
	}
elsif(substr($text, $modification_character, 1) !~ /$character_regex/)
	{
	#skip nothing if at end of word
	$search_end = $modification_character ;
	$skip_size = 0 ;
	}
elsif(reverse(substr($text, 0, $modification_character)) =~ /^($character_regex)/)
	{
	$skip_size = length($1);
	$search_end = $modification_character - $skip_size ;
	}

$text = reverse substr($text, 0, $search_end) ;

if($text =~ /($character_regex)/)
	{
	#~ print "search_end: $search_end skip size: $skip_size index: " .  index($text, $1) . " length: " . length($1) . " '$1'\n" ;
	
	$buffer->SetModificationCharacter($search_end - (index($text, $1) + length($1))) ;
	}
else
	{
	for(my $current_line_index = $modification_line - 1 ; $current_line_index >= 0 ; $current_line_index--)
		{
		$text = reverse $buffer->GetLineText($current_line_index) ;
		
		if($text =~ /($character_regex)/)
			{
			$buffer->SetModificationLine($current_line_index) ;
			$buffer->SetModificationCharacter(length($text) - (index($text, $1) + length($1))) ;
			last ;
			}
		}
	}
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
