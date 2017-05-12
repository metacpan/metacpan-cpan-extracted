
package Text::Editor::Vip::Buffer::Plugins::FindReplace ;

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

use constant CASE_SENSITIVE => 0 ;
use constant IGNORE_CASE    => 1 ;

=head1 NAME

Text::Editor::Vip::Buffer::Plugins::FindReplace- Find and replace functionality plugin for Vip::Buffer

=head1 SYNOPSIS

  is_deeply([$buffer->FindOccurence('1', 0, 0)], [0, 5, '1'], 'Found occurence 1') ;
  is($buffer->GetText(), $text, 'Text still the same') ;
  is($buffer->GetSelectionText(), '', 'GetSelectionText empty') ;
  
  #FindNextOccurence
  $buffer->SetModificationPosition(0, 0) ;
  is_deeply([$buffer->FindNextOccurence()], [0, 5, '1'], 'FindNextOccurence') ;
  
  $buffer->SetModificationPosition(0, 5) ;
  is_deeply([$buffer->FindNextOccurence()], [0, 9, '1'], 'FindNextOccurence') ;
  
  # FindNextOccurenceForCurrentWord
  $buffer->SetModificationPosition(0, 0) ;
  is_deeply([$buffer->FindNextOccurenceForCurrentWord()], [1, 0, 'line'], 'FindNextOccurenceForCurrentWord') ;
  
  $buffer->SetModificationPosition(1, 0) ;
  is_deeply([$buffer->FindNextOccurenceForCurrentWord()], [2, 0, 'line'], 'FindNextOccurenceForCurrentWord') ;
  
  $buffer->SetModificationPosition(4, 0) ;
  
  is_deeply([$buffer->FindNextOccurenceForCurrentWord()], [undef, undef, undef], 'FindNextOccurenceForCurrentWord') ;
  
  # Regex search
  is_deeply([$buffer->FindOccurence(qr/..n[a-z]/, 0, 0)], [0, 0, 'line'], 'Found occurence with regex') ;

=head1 DESCRIPTION

Find and replace functionality plugin for Vip::Buffer

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub FindOccurence
{

=head2 FindOccurence

Finds the text matching the B<regex> argument starting at the B<line> and B<character> arguments.
If no B<line> argument is passed, the modification position is used.

This sub returns an array containing: ($match_line, $match_position, $match_word)

The Selection is not modified by this sub. To set the modification at the match position:

  my ($match_line, $match_position, $match_word) = $buffer->FindOccurence($regex, $line, $character) ;
  
  if(defined $match_line)
	{
	  $buffer->SetModificationPosition($match_line, $match_position + length($match_word)) ;
	  $buffer->{SELECTION}->Set($match_line, $match_position,$match_line, $match_position + length($match_word)) ;
	}

=cut

my $buffer       = shift ;
my $search_regex = shift ;

my $line   = shift ;
$line = $buffer->GetModificationLine() unless defined $line ;

# weird return to make comparison function on the calling side happy
return(undef, undef, undef) if($line > ($buffer->GetNumberOfLines() - 1)) ;

my $character = shift ;
$character = $buffer->GetModificationCharacter() unless defined $character ;

$character = $character < 0 ? 0 : $character ;

my $line_length = $buffer->GetLineLength($line) ;
$character = $character > $line_length ? $line_length : $character ;

my ($match_line, $match_position, $match_word) ;

my $start_line = $line ;

if(defined $search_regex && '' ne $search_regex)
	{
	$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'} = $search_regex ;

	my $text = substr($buffer->GetLineText($line), $character) ;
	
	eval
	{
	if($text =~ /($search_regex)/)
		{
		$match_line     = $line ;
		$match_position = index($text, $1) + $character ;
		$match_word     = $1 ;
		}
	else
		{
		my $number_of_lines_in_document = $buffer->GetNumberOfLines() ;
		
		for(my $current_line = $line + 1 ; $current_line < $number_of_lines_in_document; $current_line++)
			{
			$text = $buffer->GetLineText($current_line) ;
			
			if($text =~ /($search_regex)/)
				{
				$match_line     = $current_line ;
				$match_position = index($text, $1) ;
				$match_word     = $1 ;
				last ;
				}
			}
		}
	} ;
	
	if($@)
		{
		$buffer->PrintError("Error in FindOccurence: $@") ;
		return(undef, undef, undef) ;
		}
	}
	
return($match_line, $match_position, $match_word) ;
}

#-------------------------------------------------------------------------------

sub FindOccurenceWithinBoundaries
{

=head2 FindOccurenceWithinBoundaries

Finds the text matching the B<regex> argument within tha passed boundaries starting at the B<line> and B<character> arguments.
If no B<line> argument is passed, the modification position is used.

B<Arguments:>

=over 2

=item * search regex, a perl qr or a string

=item * start_line (boundary)

=item * start_character (boundary)

=item * end_line (boundary)

=item * end_character (boundary)

=item * line, where to start looking

=item * character, where to start looking

=back


This sub returns an array containing: ($match_line, $match_character, $match_word)

The Selection an the current modification position are not modified by this sub.

  $buffer->FindOccurenceWithinBoundaries('line', @boundaries) ;

=cut

my 
	(
	  $buffer, $search_regex
	, $start_line, $start_character, $end_line, $end_character
	, $line, $character
	) = @_ ;

unless
	(
	(defined $start_line && defined $start_character && defined $end_line && defined $end_character)
	&& ($start_line > 0 && $start_line < $end_line && $start_character > 0)
	&& $end_line < $buffer->GetNumberOfLines()
	)
	{
	$buffer->PrintError("Invalid boundaries passed to ReplaceOccurenceWithinBoundaries") ;
	return(undef) ;
	}

my $selection = new Text::Editor::Vip::Selection() ;
$selection->Set($start_line, $start_character, $end_line, $end_character) ;

unless(defined $line)
	{
	$line = $buffer->GetModificationLine() ;
	$character = 0 ;
	}
	
$character = $buffer->GetModificationCharacter() unless defined $character ;

unless($selection->IsCharacterSelected($line, $character))
	{
	($line, $character) = ($start_line, $start_character) ;
	}
	
$character = $character < 0 ? 0 : $character ;

my $line_length = $buffer->GetLineLength($line) ;
$character = $character > $line_length ? $line_length : $character ;

my ($match_line, $match_character, $match_word) = $buffer->FindOccurence($search_regex, $line, $character) ;

if(defined $match_line)
	{
	if($selection->IsCharacterSelected($match_line, $match_character))
		{
		return($match_line, $match_character, $match_word) ;
		}
	else	
		{
		return(undef) ;
		}
	}
else
	{
	return(undef) ;
	}
}

#----------------------------------------------------------------------------------------------------

sub FindNextOccurence
{

=head2 FindNextOccurence

Find the next occurence matching the search regex.

=cut

my $buffer = shift ;
my $line = $buffer->GetModificationLine();

# weird return to make comparison function on the calling side happy
return(undef, undef, undef) if($line > ($buffer->GetNumberOfLines() - 1)) ;

my $character = $buffer->GetModificationCharacter() ;

$buffer->FindOccurence
	(
	  $buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'}
	, $line
	, $character + 1
	) ;
}

#-------------------------------------------------------------------------------

sub FindNextOccurenceForCurrentWord
{

=head2 FindNextOccurenceForCurrentWord

Finds the next occurence for the word at the modification position.

=cut

my $buffer = shift ;
$buffer->ExpandedWithOrLoad('GetCurrentWord', 'Text::Editor::Vip::Buffer::Plugins::GetWord') ;

$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'} = $buffer->GetCurrentWord() ;

$buffer->FindNextOccurence() ;
}

#-------------------------------------------------------------------------------

sub FindOccurenceBackwards
{

=head2 FindOccurenceBackwards

Searches for the B<regex> going backwards in the buffer. Intricate regexes might not work.

=cut

my $buffer       = shift ;
my $search_regex = shift ;

my $line   = shift ;
$line = $buffer->GetModificationLine() unless defined $line ;

# allow search backwards from after the buffer
if($line > ($buffer->GetNumberOfLines() - 1))
	{
	$line = $buffer->GetNumberOfLines() - 1 ;
	}

my $character = shift ;
$character = $buffer->GetModificationCharacter() unless defined $character ;

$character = $character < 0 ? 0 : $character ;

my $line_length = $buffer->GetLineLength($line) ;
$character = $character > $line_length ? $line_length : $character ;

my($match_line, $match_position, $match_word) ;
my $start_line = $line ;

if(defined $search_regex && '' ne $search_regex)
	{
	$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'} = $search_regex ;
	
	my ($extended_pattern) = $search_regex =~ /^(\(\?[^)]*\))/ ;
	$extended_pattern ||= '' ;
	
	$search_regex =~ s/^(\(\?[^)]*\))// ;
	
	$search_regex = $extended_pattern . reverse $search_regex ;
	
	my $text = reverse substr($buffer->GetLineText($line), 0, $character) ;
	
	if($text =~ /($search_regex)/)
		{
		$match_line     = $line ;
		$match_position = $character - (length($1) +index($text, $1)) ;
		$match_word     = reverse($1) ;
		}
	else
		{
		for(my $current_line = $line - 1 ; $current_line >= 0; $current_line--)
			{
			$text = reverse $buffer->GetLineText($current_line) ;
			
			if($text =~ /($search_regex)/)
				{
				$match_line     = $current_line ;
				$match_position = length($text) - (length($1) + index($text, $1)) ;
				$match_word     = reverse($1) ;
				last ;
				}
			}
		}
	}

return($match_line, $match_position, $match_word) ;
}

#-------------------------------------------------------------------------------

sub FindPreviousOccurence
{

=head2 FindPreviousOccurence

Searches for the next occurence going backwards in the buffer

=cut

my $buffer = shift ;

my $line = $buffer->GetModificationLine();
my $character = $buffer->GetModificationCharacter() ;

$buffer->FindOccurenceBackwards
	(
	  $buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'}
	, $line
	, $character - 1
	) ;
}

#-------------------------------------------------------------------------------

sub FindPreviousOccurenceForCurrentWord
{

=head2 FindPreviousOccurenceForCurrentWord

Finds the previous occurence for the word at the modification position.

=cut

my $buffer = shift ;

$buffer->ExpandedWithOrLoad('GetCurrentWord', 'Text::Editor::Vip::Buffer::Plugins::GetWord') ;

$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'} = $buffer->GetCurrentWord() ;
$buffer->FindOccurenceBackwards($buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'}) ;
}

#-------------------------------------------------------------------------------

sub ReplaceOccurenceWithinBoundaries
{

=head2 ReplaceOccurenceWithinBoundaries

Finds a match for the B<search_regex> argument and replaces it with the B<replacement>. 

B<Arguments:>

=over 2

=item * search regex, a perl qr or a string

=item * replacement, a  regex, a string  or a sub reference (see bellow)

=item * start_line (boundary)

=item * start_character (boundary)

=item * end_line (boundary)

=item * end_character (boundary)

=item * line, where to start looking, optional

=item * character, where to start looking, optional

=back

If line or character are undefined or invalid, the current modification position is used.

Valid boudaries must be passed to this sub or it will return undef. No replacement is done if the searched regex doesn't match
within the boudaries.

This sub returns an array containing: ($match_line, $match_position, $match_word, $replacement)

=head3 String replacement

  $buffer->ReplaceOccurence(qr/..(n[a-z])/, 'replacement') ;

=head3 Regex replacement

if the replacement is a regex,  parenthesis can be be used to assign $1, $2, ..

  $buffer->ReplaceOccurence(qr/..(n[a-z])/, 'xx$1', @boundaries) ;
  
=head3 Sub replacement

B<Arguments:>

=over 2

=item * the buffer

=item * matching line

=item * matching character

=item * the match

=back

the sub returns a string which will be be inserted at the matching position.

  sub replacement_sub
  {
  my($buffer, $match_line, $match_character, $match_word) = @_ ;
  
  join(', ', ref($buffer), $match_line, $match_character, $match_word, "\n") ;
  }
  
  $buffer->ReplaceOccurenceWithinBoundaries('match_this', \&sub_reference, @boundaries)

=cut

my 
	(
	  $buffer
	, $search_regex, $replacement_regex
	, $start_line, $start_character, $end_line, $end_character
	, $line, $character
	) = @_ ;

unless
	(
	(defined $start_line && defined $start_character && defined $end_line && defined $end_character)
	&& ($start_line >= 0 && $start_line <= $end_line && $start_character >= 0)
	&& $end_line < $buffer->GetNumberOfLines()
	&& $end_character >= 0
	)
	{
	$buffer->PrintError("Invalid boundaries passed to ReplaceOccurenceWithinBoundaries") ;
	return(undef) ;
	}

my $selection = new Text::Editor::Vip::Selection() ;
$selection->Set($start_line, $start_character, $end_line, $end_character) ;

# verify the input data
$line = $buffer->GetModificationLine() unless defined $line ;

my $line_length ;
if($line > ($buffer->GetNumberOfLines() - 1))
	{
	$line_length = 0 ;
	}
else
	{
	$line_length = $buffer->GetLineLength($line) ;
	}
	
$character = $buffer->GetModificationCharacter() unless defined $character ;

$character = $character < 0 ? 0 : $character ;
$character = $character > $line_length ? $line_length : $character ;

unless($selection->IsCharacterSelected($line, $character))
	{
	($line, $character) = $selection->GetBoundaries()  ;
	}

if(defined $search_regex && '' ne $search_regex && defined $replacement_regex)
	{
	$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'} = $search_regex ;
	$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::REPLACEMENT_REGEX'} = $replacement_regex ;
	
	my ($match_line, $match_character, $match_word) = $buffer->FindOccurence($search_regex, $line, $character) ;
	
	if(defined $match_line)
		{
		if($selection->IsCharacterSelected($match_line, $match_character))
			{
			$buffer->SetModificationPosition($match_line, $match_character + length($match_word)) ;
			$buffer->SetSelectionBoundaries($match_line, $match_character, $match_line, $match_character + length($match_word)) ;
			
			# perl will display a warning if the replacement is undef
			# this can happend if '$2' is given as a replacement but nothing matches for it.
			
			my $replaced_by = $match_word ;
			
			if('CODE' eq ref $replacement_regex)
				{
				eval 
					{
					$replaced_by = $replacement_regex->($buffer, $match_line, $match_character, $match_word) ;
					} ;
				}
			else
				{
				eval "#line " . __LINE__ . "'" . __FILE__ . "'\n\$replaced_by =~ s/$search_regex/$replacement_regex/ ;" ;
				}
			
			if($@)
				{
				$buffer->PrintError("Error in ReplaceOccurenceWithinBoundaries: $@") ;
				return(undef, undef, undef) ;
				}
			else
				{
				$buffer->Delete() ;
				$buffer->Insert($replaced_by) ;
				return($match_line, $match_character, $match_word, $replaced_by) ;
				}
			}
		else
			{
			# found something but outside selection
			return(undef) ;
			}
		}
	else
		{
		return(undef) ;
		}
	}
else
	{
	return(undef) ;
	}
}

#-------------------------------------------------------------------------------------------------------------

sub ReplaceOccurence
{

=head2 ReplaceOccurence

Finds a match for the B<search_regex> argument and replaces it with the B<replacement>. 

B<Arguments:>

=over 2

=item * search regex, a perl qr or a string

=item * replacement,  a regex, string or sub reference

=item * line, where to start looking, optional

=item * character, where to start looking, optional

=back

If line or character are undefined or invalid, the current modification position is used.

This sub returns an array containing: ($match_line, $match_position, $match_word, $replacement)

=head3 String replacement

  $buffer->ReplaceOccurence(qr/..(n[a-z])/, 'replacement') ;

=head3 Regex replacement

  $buffer->ReplaceOccurence(qr/..(n[a-z])/, 'xx$1') ;
  
if the replacement is a regex,  parenthesis can be be used to assign $1, $2, ..

  $buffer->ReplaceOccurence(qr/..(n[a-z])/, 'xx$1') ;
  
=head3 Sub replacement

B<Arguments:>

=over 2

=item * the buffer

=item * matching line

=item * matching character

=item * the match

=back

the sub returns a string which will be be inserted at the matching position.

  sub replacement_sub
  {
  my($buffer, $match_line, $match_character, $match_word) = @_ ;
  
  join(', ', ref($buffer), $match_line, $match_character, $match_word, "\n") ;
  }
  
  $buffer->ReplaceOccurenceWithinBoundaries('match_this', \&sub_reference)

=cut

my ($buffer, $search_regex, $replacement_regex, $line, $character) = @_;

# verify input
$line = $buffer->GetModificationLine() unless defined $line ;

if($line > ($buffer->GetNumberOfLines() - 1))
	{
	$line = $buffer->GetNumberOfLines() - 1 ;
	}

$character = $buffer->GetModificationCharacter() unless defined $character ;

$character = $character < 0 ? 0 : $character ;

my $line_length = $buffer->GetLineLength($line) ;
$character = $character > $line_length ? $line_length : $character ;

my ($match_line, $match_character, $match_word, $replaced_by) ;

if(defined $search_regex && '' ne $search_regex && defined $replacement_regex)
	{
	$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::SEARCH_REGEX'} = $search_regex ;
	$buffer->{'Text::Editor::Vip::Buffer::Plugins::FindReplace::REPLACEMENT_REGEX'} = $replacement_regex ;
	
	($match_line, $match_character, $match_word) = $buffer->FindOccurence($search_regex, $line, $character) ;
	
	if(defined $match_line)
		{
		$buffer->SetModificationPosition($match_line, $match_character + length($match_word)) ;
		$buffer->SetSelectionBoundaries($match_line, $match_character, $match_line, $match_character + length($match_word)) ;
		
		# perl will display a warning if the replacement is undef
		# this can happend if '$2' is given as a replacement but nothing matches for it.
		
		$replaced_by = $match_word ;
		
		if('CODE' eq ref $replacement_regex)
			{
			eval 
				{
				$replaced_by = $replacement_regex->($buffer, $match_line, $match_character, $match_word) ;
				} ;
			}
		else
			{
			eval "#line " . __LINE__ . "'" . __FILE__ . "'\n\$replaced_by =~ s/$search_regex/$replacement_regex/ ;" ;
			}
		
		if($@)
			{
			$buffer->PrintError("Error in ReplaceOccurence: $@") ;
			return(undef, undef, undef) ;
			}
		else
			{
			$buffer->Delete() ;
			$buffer->Insert($replaced_by) ;
			}
		}
	}

return($match_line, $match_character, $match_word, $replaced_by) ;
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
