
package Text::Editor::Vip::Buffer::Plugins::Case;
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

#-------------------------------------------------------------------------------

sub MakeSelectionUpperCase
{

=head2 MakeSelectionUpperCase

Makes the current selection upper case.

=cut

my $buffer = shift ;

$buffer->RunSubOnSelection
			(
			sub
				{
				#my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_;
				return(uc(shift)) ;
				}
			, sub
				{
				$buffer->PrintError("Please select text for upper case operation.\n")
				}
			) ;
}

#-------------------------------------------------------------------------------

sub MakeSelectionLowerCase
{

=head2 MakeSelectionLowerCase

Makes the current selection lower case.

=cut

my $buffer = shift ;

$buffer->RunSubOnSelection
			(
			sub
				{
				#my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_;
				return(lc(shift)) ;
				}
			, sub
				{
				$buffer->PrintError("Please select text for lower case operation.\n")
				}
			) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 NAME

Text::Editor::Vip::Buffer::Plugins::Case - Plugin to make selection upper or lower case.

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer ;
  
  my $buffer = new Text::Editor::Vip::Buffer() ;
  $buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;
  
  $buffer->Insert("this is upper case") ;
  $buffer->GetSelection()->Set(0, 8, 0, 13) ;
  $buffer->MakeSelectionUpperCase() ;
  
  is($buffer->GetText(), 'this is UPPER case', 'Upper casing selection') ;

=head1 DESCRIPTION

Plugin to make selection upper or lower case

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
