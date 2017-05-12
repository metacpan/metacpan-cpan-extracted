
package Text::Editor::Vip::Buffer::Selection;

use strict;
use warnings ;
use Carp qw(cluck) ;

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

sub GetSelection
{

=head2 GetSelection

Returns the selection object used by the buffer.

=cut

my $buffer = shift ;
return($buffer->{SELECTION}) ;
}

#-------------------------------------------------------------------------------

sub SetSelection
{

=head2 SetSelection

Sets the selection object passed as argument to use by the buffer

=cut

my $buffer = shift ;
my $new_selection = shift or die ;

my 
	(
	  $new_selection_start_line, $new_selection_start_character
	, $new_selection_end_line, $new_selection_end_character
	) = $new_selection->GetBoundaries() ;
	
my 
	(
	  $selection_start_line, $selection_start_character
	, $selection_end_line, $selection_end_character
	) = $buffer->GetBoundaries() ;


$buffer->PushUndoStep
		(
		  "\$buffer->SetSelectionBoundaries($new_selection_start_line, $new_selection_start_character, $new_selection_end_line, $new_selection_end_character) ;"
		, "\$buffer->SetSelectionBoundaries($selection_start_line, $selection_start_character, $selection_end_line, $selection_end_character) ;"
		) ;

$buffer->{SELECTION} = $new_selection ;
}

#-------------------------------------------------------------------------------

sub GetSelectionBoundaries
{

=head2 GetSelectionBoundaries

Returns the selection boundaries used by the buffer.

=cut

my $buffer = shift ;
return($buffer->{SELECTION}->GetBoundaries) ;
}

#-------------------------------------------------------------------------------

sub SetSelectionBoundaries
{

=head2 SetSelectionBoundaries

Sets the selection boundaries use by the buffer

=cut

my $buffer = shift ;


my 
	(
	  $new_selection_start_line, $new_selection_start_character
	, $new_selection_end_line, $new_selection_end_character
	) = @_ ;
	
my 
	(
	  $selection_start_line, $selection_start_character
	, $selection_end_line, $selection_end_character
	) = $buffer->GetSelectionBoundaries() ;


$buffer->PushUndoStep
		(
		  "\$buffer->SetSelectionBoundaries($new_selection_start_line, $new_selection_start_character, $new_selection_end_line, $new_selection_end_character) ;"
		, "\$buffer->SetSelectionBoundaries($selection_start_line, $selection_start_character, $selection_end_line, $selection_end_character) ;"
		) ;

$buffer->{SELECTION}->Set
	(
	  $new_selection_start_line, $new_selection_start_character
	, $new_selection_end_line, $new_selection_end_character
	) ;
}

#-------------------------------------------------------------------------------

sub GetSelectionText
{

=head2

Returns the selection contents joined with "\n" except for the last line

=cut

my $buffer = shift ;

my $selection_text = '' ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	$buffer->RunSubOnSelection
				(
				  sub
					{
					my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_;
					
					my 
						(
						  $selection_start_line, $selection_start_character
						, $selection_end_line, $selection_end_character
						) = $original_selection->GetBoundaries() ;
					
					if($selection_end_line == $selection_line_index)
						{
						# last line doesn't get a  \n
						$selection_text .= $text ;
						}
					else	
						{
						$selection_text .= "$text\n" ;
						}
						
					return($text) ;
					}
				  
				, sub { $buffer->PrintError("Mark selection please\n") ; }
				) ;
	}
	
return($selection_text) ;
}

#-------------------------------------------------------------------------------

sub DeleteSelection
{

=head2 DeleteSelection

Removes the text within the selection, if any,  from the buffer. Sets the modification position to the start of the selection

=cut

my $buffer = shift ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, '$buffer->DeleteSelection() ;', '   #', '# undo for $buffer->DeleteSeletion()', '   ') ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	my ($start_line, $start_character) = $buffer->{SELECTION}->GetBoundaries() ;
	
	$buffer->RunSubOnSelection
				(
				  sub { return(undef) ; }
				, sub { $buffer->PrintError("Mark selection please\n") ; }
				) ;
				
	$buffer->SetModificationPosition($start_line, $start_character) ;
	$buffer->{SELECTION}->Clear() ;
	}
}

#-------------------------------------------------------------------------------

sub RunSubOnSelection
{

=head2 RunSubOnSelection

Runs a user supplied sub on the selection. The sub is called for each line in the selection.
It can return a string or undef if the section is to be removed.

=cut

my $buffer = shift ;
my ($function, $error_sub_ref) = @_ ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, '# $buffer->RunSubOnSelection() ;', '    ', '# undo for $buffer->DeleteSeletion()', '   ') ;
	
	$buffer->BoxSelection() ;
	
	my 
		(
		  $selection_start_line, $selection_start_character
		, $selection_end_line, $selection_end_character
		) = $buffer->{SELECTION}->GetBoundaries() ;
		
	my $original_selection = $buffer->{SELECTION}->Clone() ;
	
	$buffer->{SELECTION}->Clear() ; # we use buffer functionw that might call this sub otherwise

	my $removing_end_of_first_line = 0 ;

	my @lines_to_delete ;
	my $wrap_first_line = -1 ; # we need two confimations to wrap the first line

	for
		(
		my $selection_line_index = $selection_start_line 
		; $selection_line_index <= $selection_end_line
		; $selection_line_index++
		)
		{
		# we remove the text and replace it with the text returned by the user sub
		my $text ;
		eval {$text = $buffer->GetLineText($selection_line_index) ;} ;
		
		if($@)
			{
			$buffer->PrintError($@) ;
			last ;
			}
		
		my $modification_character ;
		my $whole_line_selected = 0 ;
		
		my $line_length = $buffer->GetLineLength($selection_line_index) ;
		
		my $corrected_selection_start_character = $selection_start_character < $line_length ? $selection_start_character : $line_length ;
		my $corrected_selection_end_character = $selection_end_character < $line_length ? $selection_end_character : $line_length ;
		
		if($selection_line_index == $selection_start_line && $selection_start_line == $selection_end_line)        
			{
			$text = substr($text, $corrected_selection_start_character, $corrected_selection_end_character - $corrected_selection_start_character) ;
			$modification_character = $selection_start_character ;
			
			$whole_line_selected++ if(length($text) == $line_length && 0 == $selection_start_character) ;
			}
		elsif($selection_line_index == $selection_start_line)
			{
			$text = substr($text, $corrected_selection_start_character) ;
			$modification_character = $selection_start_character ;
			$wrap_first_line++ ;
			}
		elsif($selection_line_index == $selection_end_line)
			{
			$text = substr($text, 0, $corrected_selection_end_character)  ;
			$modification_character = 0 ;
			}
		else
			{
			$modification_character = 0 ;
			$whole_line_selected++ ;
			}
			
		# the sub has access to the line before we modify it
		my $new_text = $function->($text, $selection_line_index, $modification_character, $original_selection, $buffer) ;
		
		# we should avoid unecessary modification if the text is the same
		#~ if(length($new_text) != length($text) || $new_text ne $text)
		
			{
			$buffer->SetModificationPosition($selection_line_index, $modification_character) ;
			$buffer->Delete(length($text)) ;
			
			if(defined $new_text)
				{
				$buffer->Insert($new_text) ;
				}
			else
				{
				if($selection_line_index == $selection_start_line)
					{
					$wrap_first_line++ ;
					}
					
				# deleted lines are not taken away before all lines are processed
				
				#~ print "$selection_line_index == $selection_end_line && $selection_end_character\n" ;
				
				if($whole_line_selected)
					{
					# last line is never deleted
					push @lines_to_delete, $selection_line_index unless ($selection_line_index == $selection_end_line) ;
					}
				}
			}
		}
		
	$buffer->DeleteLine($_) for (reverse @lines_to_delete) ;
	
	if($wrap_first_line == 1)
		{
		$buffer->SetModificationPosition($selection_start_line, $selection_start_character) ;
		$buffer->Delete(1) ;
		}
		
	$buffer->{SELECTION}->Set
		(
		  $selection_start_line, $selection_start_character
		, $selection_end_line, $selection_end_character
		)  ;
	}
else
	{
	$error_sub_ref->("No Selection!") ;
	}
}

#-------------------------------------------------------------------------------

sub BoxSelection
{

=head2 BoxSelection

Puts the selection boundaries within the buffer boundaries and returns the new selection boundaries.

Doesn't change the selection if it is empty. See L<SelectAll>.

=cut

my $buffer = shift ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	my ($selection_start_line, $selection_start_character
	, $selection_end_line, $selection_end_character
	) = $buffer->GetSelectionBoundaries() ;
	
	my $number_of_lines = $buffer->GetNumberOfLines() ;
	
	$selection_start_line = $selection_start_line >=  $number_of_lines ? ($number_of_lines - 1): $selection_start_line ;
	$selection_start_line = 0 if $selection_start_line < 0 ;
	
	$selection_start_character = 0 if $selection_start_character < 0 ;
	
	$selection_end_line = $selection_end_line >= $number_of_lines ? ($number_of_lines - 1) : $selection_end_line ;
	$selection_end_line = 0 if $selection_end_line < 0 ;
	
	$selection_end_character = 0 if $selection_end_character < 0 ;
	
	$buffer->{SELECTION}->Set
				(
				  $selection_start_line, $selection_start_character
				, $selection_end_line, $selection_end_character
				) ;
				
	return($buffer->GetSelectionBoundaries()) ;
	}
}

#-------------------------------------------------------------------------------

1;

=head1 NAME

Text::Editor::Vip::Buffer::Selection - Selection handling for buffer

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer::Selection
  

=head1 DESCRIPTION

Plugin for Vip::Buffer. It handles Selection.

=head1 USAGE

=head1 BUGS

=head1 SUPPORT

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
