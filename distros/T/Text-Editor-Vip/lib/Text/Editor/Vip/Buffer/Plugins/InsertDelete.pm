
package Text::Editor::Vip::Buffer::Plugins::InsertDelete ;

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

Text::Editor::Vip::Buffer::Plugins::InsertDelete- Vip::Buffer plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

Text::Editor::Vip::Buffer::Plugins::InsertConstruct- Vip::Buffer plugin

=head1 FUNCTIONS

=cut

#-----------------------------------------------------------------------

sub SetText
{

=head2 SetText

Sets the buffers text.

=cut

my $buffer = shift ;
my $new_text = shift ;

$buffer->ExpandedWithOrLoad('SelectAll', 'Text::Editor::Vip::Buffer::Plugins::Selection') ;

$buffer->SelectAll() ;
$buffer->DeleteSelection() ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->Insert($new_text) ;
}

#-----------------------------------------------------------------------

sub InsertNewLineBeforeCurrent
{

=head2 InsertNewLineBeforeCurrent

Inserts a blank new line before the current line. Modification position is not changed.
 
=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('MoveUp', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->{SELECTION}->Clear() ;

my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

$buffer->SetModificationCharacter(0) ;
$buffer->InsertNewLine() ;
$buffer->SetModificationCharacter($modification_character) ;
}

#-----------------------------------------------------------------------

sub DeleteToBeginingOfWord
{

=head2 DeleteToBeginingOfWord

Deletes from the current position to the begining of the word.

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('ExtendSelectionToBeginingOfWord', 'Text::Editor::Vip::Buffer::Plugins::Selection') ;

$buffer->ExtendSelectionToBeginingOfWord() ;
$buffer->DeleteSelection() ;
}

#-----------------------------------------------------------------------

sub DeleteToEndOfWord
{

=head2 DeleteToEndOfWord

Deletes from the current position to the end of the word.

=cut

my $buffer = shift ;

$buffer->ExtendSelectionToNextWord() ;
$buffer->DeleteSelection() ;
}

#-----------------------------------------------------------------------

sub InsertTab
{

=head2 InsertTab

Inserts a tab at the current position. If there is a aselection, the whole selection is indented.

=cut

my $buffer = shift ;

if($buffer->GetSelection()->IsEmpty())
	{
	$buffer->Insert("\t") ;
	}
else
	{
	my ($modification_line, $modification_character) = $buffer->GetModificationPosition() ;
	
	$buffer->RunSubOnSelection
				(
				sub
					{
					my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_ ;
					
					if($selection_line_index == $original_selection->GetEndLine() && 0 == $original_selection->GetEndCharacter())
						{
						return($text) ;
						}
					else
						{
						return("\t$text") ;
						}
					}
				, sub { print "Please select text to shift" ;}
				) ;
				
	$buffer->SetModificationPosition($modification_line, $modification_character) ;
	}
}

#-----------------------------------------------------------------------

sub RemoveTabFromSelection
{

=head2 RemoveTabFromSelection

If there is a selection, it is outdented.

=cut

my $buffer = shift ;

unless($buffer->{SELECTION}->IsEmpty())
	{
	$buffer->RunSubOnSelection
				(
				sub
					{
					my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_ ;
					
					if($selection_line_index == $original_selection->GetEndLine() && 0 == $original_selection->GetEndCharacter())
						{
						return($text) ;
						}
					else
						{
						if($text =~ /^[\t ]/o)
							{
							return(substr($text, 1)) ;
							}
						else
							{
							return($text) ;
							}
						}
					}
					
				, sub { print "Please select text to un-shift" ;}
				) ;
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
