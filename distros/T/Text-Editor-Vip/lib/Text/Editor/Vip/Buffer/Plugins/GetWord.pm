
package Text::Editor::Vip::Buffer::Plugins::GetWord ;

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

Text::Editor::Vip::Buffer::Plugins::GetWord- Vip::Buffer pluggin

=head1 SYNOPSIS
 
  $buffer->Insert(' word1 word_2 3 word4') ;
  $buffer->SetModificationCharacter(1) ;
  is($buffer->GetCurrentWord() , 'word1', 'GetCurrentWord') ;
  
=head1 DESCRIPTION

Plugin for Vip::Buffer.

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub GetAlphanumericFilter
{

=head2 GetAlphanumericFilter

Returns the regex set with L<SetAlphanumericFilter> or the default regex B<qr![a-zA-Z_0-9]+!>.

=cut

my $buffer = shift ;

return
	(
	   $buffer->{'Text::Editor::Vip::Buffer::Plugins::GetWord::ALPHANUMERIC_FILTER'}
	|| qr![a-zA-Z_0-9]+!
	) ;
}

#-------------------------------------------------------------------------------

sub SetAlphanumericFilter
{

=head2 SetAlphanumericFilter

Sets the regex used by this plugin.

=cut

my $buffer = shift ;
$buffer->{'Text::Editor::Vip::Buffer::Plugins::GetWord::ALPHANUMERIC_FILTER'} = shift ;
}

#-------------------------------------------------------------------------------

sub GetFirstWord
{

=head2 GetFirstWord

Returns the first word matching the word regex in the B<line> passed as argument or the current
modification line if none.

  $buffer->GetFirstWord(125) ; 
  $buffer->GetFirstWord() ; #in the current line

Returns the word( or undef if none found) and its position in the line.

=cut

my $buffer = shift ;
my $line_index = shift ;

$line_index = $buffer->GetModificationLine() unless defined $line_index ;

my $current_line_text = $buffer->GetLineText($line_index) ;
my $character_regex   = $buffer->GetAlphanumericFilter() ;

$current_line_text =~ /^(\W*)($character_regex)/ ;

my $length = defined $1 ? length($1) : defined($2) ? 0 : undef ;

return($2, $length) ;
}

#-------------------------------------------------------------------------------

sub GetPreviousWord
{

=head2 GetPreviousWord

Returns the previous word matching the word regex in the the current modification line if none.
Returns the word( or undef if none found) and its position in the line.

=cut

my $buffer = shift ;

my $text = $buffer->GetLineText($buffer->GetModificationLine()) ; 

#what if current character is outside the text length?
#my $corrected_selection_start_character = $selection_start_character < $line_length ? $selection_start_character : $line_length ;

my $current_character_index = $buffer->GetModificationCharacter() ;
$current_character_index = length($text) if $current_character_index > length($text) ;

my $character_regex         = $buffer->GetAlphanumericFilter() ;

my $left_side  = reverse substr($text, 0, $current_character_index) ;

$left_side =~ /^(\W*)($character_regex)/ ;

my $previous_word = reverse $2 if defined $2 ;

my $position ;
if(defined $previous_word)
	{
	my $non_word_length = defined $1 ? length($1) : 0 ;
	
	$position = $current_character_index - ($non_word_length + length($previous_word)) ;
	}



return($previous_word, $position) ;
}

#-------------------------------------------------------------------------------

sub GetCurrentWord
{

=head2 GetCurrentWord

Returns the word at the modification position or undef if no word is found.

=cut

my $buffer = shift ;

my $modification_character = $buffer->GetModificationCharacter() ;

my $current_line_text = $buffer->GetLineText($buffer->GetModificationLine()) ;
my $current_line_length = length($current_line_text) ;

return if $modification_character > $current_line_length ;

my $character_regex = $buffer->GetAlphanumericFilter() ;
my $current_character = substr($current_line_text, $modification_character, 1) ;

my $current_word ;
my $cursor_is_at_the_end_of_the_word = 1 ;

if($current_character =~ /$character_regex/)
	{
	$current_word = $current_character ;
	
	for(my $character_index = $modification_character - 1 ; $character_index >= 0 ; $character_index--)
		{
		$current_character = substr($current_line_text, $character_index, 1) ;
		
		if($current_character =~ /$character_regex/)
			{
			$current_word = $current_character . $current_word ;
			}
		else
			{
			# not character
			last ;
			}
		}
		
	for(my $character_index = $modification_character + 1 ; $character_index < $current_line_length ; $character_index++)
		{
		$current_character = substr($current_line_text, $character_index, 1) ;
		
		if($current_character =~ /$character_regex/)
			{
			$current_word .= $current_character ;
			$cursor_is_at_the_end_of_the_word = 0 ;
			}
		else
			{
			# not character
			last ;
			}
		}
	}
#else
	# not on a character
	
return($current_word) ;
}

#-------------------------------------------------------------------------------

sub GetPreviousAlphanumeric
{

=head2 GetPreviousAlphanumeric

Get all the characters matching the aphanumeric regex from the current position and backwards.

=cut

my $buffer = shift ;

# Get all string contents from 0  to the cursor position and flip it round
my $line = reverse substr
			(
			$buffer->GetLineText($buffer->GetModificationLine())
			, 0
			, $buffer->GetModificationCharacter()
			) ;
			
my $alphanumeric_filter = $buffer->GetAlphanumericFilter() ;
my ($prefix) = $line =~ /($alphanumeric_filter)/ ;

# !! reverse of undef is defined.
if(defined $prefix)
	{
	return(reverse $prefix) ;
	}
else
	{
	return(undef) ;
	}
}

#-------------------------------------------------------------------------------

sub GetNextAlphanumeric
{

=head2 GetNextAlphanumeric

Get all the characters matching the aphanumeric regex from the current position.

=cut

my $buffer = shift ;

my $modification_character = $buffer->GetModificationCharacter() ;

my $current_line_text = $buffer->GetLineText($buffer->GetModificationLine()) ;
my $current_line_length = length($current_line_text) ;

return if $modification_character > $current_line_length ;

my $line = substr
		(
		$buffer->GetLineText($buffer->GetModificationLine())
		, $modification_character 
		) ;
		
my $alphanumeric_filter = $buffer->GetAlphanumericFilter() ;
my ($postfix) = $line =~ /($alphanumeric_filter)/ ;

return($postfix) ;
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
