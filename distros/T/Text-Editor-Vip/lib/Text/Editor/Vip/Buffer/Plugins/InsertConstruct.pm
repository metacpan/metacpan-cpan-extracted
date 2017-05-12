
package Text::Editor::Vip::Buffer::Plugins::InsertConstruct ;

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

use Text::Editor::Vip::Buffer::Constants ;

=head1 NAME

Text::Editor::Vip::Buffer::Plugins::InsertConstruct- Vip::Buffer plugin

=head1 SYNOPSIS

  $buffer->InsertAlignedWithTab("XXXXX") ;

  $buffer->Insert($text) ;
  $buffer->SetModificationPosition(0, 4) ;
  $buffer->SetSelectionBoundaries(1, 0, 3, 0) ;
  $buffer->InsertConstruct($text_to_insert) ;

=head1 DESCRIPTION

Text::Editor::Vip::Buffer::Plugins::InsertConstruct- Vip::Buffer plugin

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub InsertAlignedWithTab
{

=head2 InsertAlignedWithTab

InsertAligned takes a string as argument

=cut

my $buffer = shift ;
my $text_to_insert = shift || return ;

die unless '' eq ref $text_to_insert ;

$buffer->ExpandedWithOrLoad('GetTabSize', 'Text::Editor::Vip::Buffer::Plugins::Display') ;

my $modification_character = $buffer->GetModificationCharacter() ;

my $tab_size     = $buffer->GetTabSize() ;
my $line_text    = substr($buffer->GetLineText(), 0, $modification_character) ;
my $tabs_in_line = $line_text =~ tr/\t/\t/ ;

my $raw_indent = "\t" x ((($modification_character - $tabs_in_line)/ $tab_size) + $tabs_in_line) ;
$raw_indent   .= ' ' x (($modification_character - $tabs_in_line) % $tab_size) ;

my @text_to_insert = split(qr"(\n)", $text_to_insert) ;
@text_to_insert = map {$_ eq "\n" ? "\n$raw_indent" : $_} @text_to_insert ;

$buffer->Insert(\@text_to_insert , NO_SMART_INDENTATION) ;
}

#-------------------------------------------------------------------------------

sub InsertConstruct
{

=head2  InsertConstruct

Inserts a construct at the cursor position or around the selection if any  if a selection is present
the  construct is aligned on the block and the  selection is indented.

  $if_construct= <<EOT ;
  if()
  \t{
  \t}
  else
  \t{
  \tSELECTION
  \t}
  EOT

  $buffer->Insert(<<EOT) ;
  line 1 - 1
  line 2 - 2 2
  line 3 - 3 3 3
  EOT
  
  $buffer->SetModificationPosition(3, 4) ;
  $buffer->SetSelectionBoundaries(1, 0, 2, 0) ; # select the second line
  $buffer->InsertConstruct($if_construct) ;

Buffer content is now

  line 1 - 1
  if()
  \t{
  \t}
  else
  \t{
  \tline 2 - 2 2 # this line was moved in the construct and aligned
  \t}
  line 3 - 3 3 3

=cut

my $buffer    = shift ;
my $construct = shift || return ;

$buffer->ExpandedWithOrLoad('InsertTab', 'Text::Editor::Vip::Buffer::Plugins::InsertDelete') ;

my ($head, $selection_indentation, $foot) ;

if($construct =~ /(.*)(^\t*)SELECTION[^\n]*\n(.*)/ms)
	{
	($head, $selection_indentation, $foot) = ($1, $2, $3) ;
	}
	
unless($buffer->GetSelection()->IsEmpty()) 
	{
	my (
	$selection_start_line, $selection_start_character
	, $selection_end_line, $selection_end_character
	) = $buffer->GetSelectionBoundaries() ;
	
	if($selection_start_character != 0 && $selection_end_character != 0)
		{
		$buffer->PrintError("Please Select entire lines") ;
		last ;
		}
		
	# compute new construct indentation base on the first non empty selection line
	for
		(
		my $selection_line_index = $selection_start_line
		; $selection_line_index <  $selection_end_line
		; $selection_line_index++
		)
		{
		my $line = $buffer->GetLineText($selection_line_index) ;
		
		if($line =~ /^(\t|\s*)[^\n]/)
			{
			my $construct_indentation = $1 ;
			
			$head =~ s/^/$construct_indentation/mg ;
			$foot =~ s/^/$construct_indentation/mg ;
			
			last ;
			}
		}
		
	# indent the selection
	$buffer->InsertTab() ;
	$buffer->GetSelection()->Clear() ;
	
	$buffer->SetModificationPosition($selection_end_line, 0) ;
	$buffer->Insert($foot, NO_SMART_INDENTATION) ;
	
	$buffer->SetModificationPosition($selection_start_line, 0) ;
	$buffer->Insert($head, NO_SMART_INDENTATION) ;
	}
else
	{
	$buffer->GetSelection()->Clear() ;
	
	$buffer->SetModificationPosition($buffer->GetModificationLine(), 0) ;
	$buffer->Insert($head . $foot) ;
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
