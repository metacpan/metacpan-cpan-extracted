sub DuplicateAndCommentOut
{
my $position = Smed::GetModificationPosition() ;
my @lines ;

my ($selection_start_line, $selection_end_line) = (0, 0) ;

if(0 == Smed::IsSelectionEmpty())
	{
	# save selection limits
	$selection_start_line = Smed::GetSelectionStartLine() ;
	$selection_end_line   = Smed::GetSelectionEndLine() ;
	
	if( 0 == Smed::GetSelectionEndCharacter())
		{
		$selection_end_line = $selection_end_line - 1 ;
		}

	# deselect
	Smed::ClearSelection() ;
	}
else
	{
	$selection_start_line = Smed::GetModificationLine() ;
	$selection_end_line = $selection_start_line ;
	}	

for(my $line_index = $selection_start_line ; $line_index <= $selection_end_line  ; $line_index++)
	{
	Smed::SetModificationLine($line_index) ;
	
	my $current_line_text = Smed::GetLineText($line_index) ;
	push @lines, $current_line_text ;
	
	next if $current_line_text =~ /^\s*$/ ; #ignore blank lines
   
	if($current_line_text =~ /^(\s*)\#~ /)
		{
		# uncomment
		Smed::SetModificationPosition(length($1)) ;
		Smed::Delete(3) ;
		}
	else
		{
		$current_line_text =~ /^(\s*)/ ;
		
		Smed::SetModificationPosition(length($1)) ; 
		Smed::Insert('#~ ') ;
		}
	}
	
Smed::SetModificationLine($selection_end_line) ;
Smed::MoveToEndOfLine() ;
Smed::Insert("\n" . join("\n", @lines)) ;
Smed::SetModificationPosition($position) ;
}
