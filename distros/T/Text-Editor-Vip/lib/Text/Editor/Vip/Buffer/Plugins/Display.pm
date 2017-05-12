
package Text::Editor::Vip::Buffer::Plugins::Display;
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

Text::Editor::Vip::Buffer::Plugins::Display - Text position to display position utilities

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer::Dispaly
  
=head1 DESCRIPTION

This module let's you define a tab size and convert text and display positions.

Tab size is set to 8 by default.

=head1 FUNCTIONS

=cut

#------------------------------------------------------------------------------

sub SetTabSize
{

=head2  SetTabSize

Sets the tab size used.

=cut 

$_[0]->{'Text::Editor::Vip::Buffer::Plugins::Display::TAB_SIZE'} = $_[1] ;
}

#-------------------------------------------------------------------------------

sub GetTabSize
{

=head2 GetTabSize

Return the tab size

=cut 

return ($_[0]->{'Text::Editor::Vip::Buffer::Plugins::Display::TAB_SIZE'} || 8) ;
}

#-------------------------------------------------------------------------------

sub GetCharacterPositionInText
{

=head2 GetCharacterPositionInText

Given a display position, returns the the position in text

=cut 

my ($buffer, $line_index, $position, $line_text) = @_ ;

$line_text = $buffer->GetLineText($line_index) unless defined $line_text ;

my ($character_position, $display_position) = (0, 0) ;

my $tab_size = $buffer->GetTabSize() ;

for (split //, $line_text)
	{
	if($_ eq "\t")
		{
		$display_position += $tab_size ;
		}
	else
		{
		$display_position++ ;
		}
		
	last if $display_position > $position ;
	$character_position++ ;
	}

if($display_position < $position)
	{
	return(length($line_text) + ($position - $display_position)) ;
	}
else
	{
	return($character_position) ;
	}
}

#-------------------------------------------------------------------------------

sub GetCharacterDisplayPosition
{

=head2 GetCharacterDisplayPosition

Given a position in the text, returns the the display position

=cut 

my ($buffer, $line_index, $position, $line_text) = @_ ;

$line_text = $buffer->GetLineText($line_index) ;
substr($line_text, $position) = '' if $position < length($line_text) ;

my $tab_size = $buffer->GetTabSize() ;

return(($line_text =~ tr/\t/\t/ * ($tab_size - 1)) + $position) ;
}

#-------------------------------------------------------------------------------

sub GetTabifiedText
{

# missing doc and tests

my ($buffer, $line_index, $line_text, $tab_size) = @_ ;

$line_text = $buffer->GetLineText($line_index) unless defined $line_text ;

$tab_size = $buffer->GetTabSize() unless defined $tab_size ;

my $tabified_text = '' ;
my $distance_to_tab = 0 ;

for(0 .. length($line_text) - 1)
	{
	$distance_to_tab = $tab_size if  $distance_to_tab  == 0 ;
	
	my $char = substr($line_text, $_, 1) ;
	
	if("\t" eq $char)
		{
		$tabified_text .= ' ' x $distance_to_tab ;
		$distance_to_tab = $tab_size ;
		}
	else
		{
		$tabified_text .= $char ;
		$distance_to_tab-- ;
		}
	}
	
return($tabified_text) ;
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
