 
package Text::Editor::Vip::Buffer::Plugins::PageUpDown;

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

die "Not yet ported to Vip!\n" :

=head1 NAME

Text::Editor::Vip::Buffer::Plugins::Movements- Add movement commands to Vip::Buffer

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer
  
=head1 DESCRIPTION

Add page movement commands to Vip::Buffer.

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub SetPageSize
{

=head2  SetPageSize

Sets the page size used.

=cut 

$_[0]->{'Text::Editor::Vip::Buffer::Plugins::PageUpDown::Page_SIZE'} = $_[1] || 40;
}

#-------------------------------------------------------------------------------

sub GetPageSize
{

=head2 GetPageSize

Return the page size

=cut 

return ($_[0]->{'Text::Editor::Vip::Buffer::Plugins::PageUpDown::PAGE_SIZE'} || 40) ;
}

#-------------------------------------------------------------------------------

sub PageUp
{

=head2 PageUp

=cut

$_[0]->ClearSelection() ;
$_[0]->PageUpNoSelectionClear() ;
}

#-------------------------------------------------------------------------------

sub PageUpNoSelectionClear
{

=head2 PageUpNoSelectionClear

=cut

my $buffer = shift ;

my $display_position = $buffer->GetCharacterDisplayPosition
					(
					$buffer->GetModificationLine()
					, $buffer->GetModificationCharacter()
					) ;
					
my $display_line_index = $buffer->GetDisplayLineIndex($buffer->GetModificationLine()) ;

#~ my $top_line_index = $buffer->GetTopLineIndex() ;

my $top_line_index = $buffer->GetTopLineIndex() ;
$top_line_index   -= $buffer->GetPageSize()
$top_line_index    = 0 unless $top_line_index >= 0 ;

#~ $buffer->SetTopLineIndex($top_line_index) ;

$buffer->SetModificationLine($top_line_index + $display_line_index) ;
$buffer->SetModificationCharacter
	(
	$buffer->GetCharacterPositionInText($buffer->GetModificationLine(), $display_position)
	) ;
}

#-------------------------------------------------------------------------------

sub PageDown
{

=head2 PageDown

=cut

$_[0]->ClearSelection() ;
$_[0]->PageDownNoSelectionClear() ;
}

sub PageDownNoSelectionClear
{

=head2 PageDownNoSelectionClear

=cut

my $buffer = shift ;
my $display_line_index = $buffer->GetDisplayLineIndex($buffer->GetModificationLine()) ;
my $display_position   = $buffer->GetCharacterDisplayPosition
					(
					$buffer->GetModificationLine()
					, $buffer->GetModificationCharacter()
					) ;
									
my $top_line_index = $buffer->GetTopLineIndex() ;
$top_line_index   += $buffer->GetNumberOfLinesInDisplay() - 1 ;
$top_line_index    = ($buffer->GetNumberOfLines() - 1) if $top_line_index >= $buffer->GetNumberOfLines() ;
 
$buffer->SetTopLineIndex($top_line_index) ;
$buffer->SetModificationLine($top_line_index + $display_line_index) ;
$buffer->SetModificationCharacter
	(
	$buffer->GetCharacterPositionInText($buffer->GetModificationLine(), $display_position)
	) ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionPageUp
{

=head2 ExtendSelectionPageUp

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('PageUpNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->PageUpNoSelectionClear() ;
$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

sub ExtendSelectionPageDown
{

=head2 ExtendSelectionPageDown

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('PageDownNoSelectionClear', 'Text::Editor::Vip::Buffer::Plugins::Movements') ;

$buffer->SetSelectionAnchorAtCurrentPosition() if $buffer->IsSelectionEmpty() ;
$buffer->PageDownNoSelectionClear() ;
$buffer->ExtendSelection() ;
}

#-------------------------------------------------------------------------------

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
