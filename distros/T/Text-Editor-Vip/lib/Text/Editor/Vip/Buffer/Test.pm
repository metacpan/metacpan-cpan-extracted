
package Text::Editor::Vip::Buffer::Test;

use strict;
use warnings ;

use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use Test::More ;

BEGIN 
{
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01;
@ISA         = qw (Exporter);
@EXPORT      = qw (DiagBuffers TestSerialisation TestDoUndo CompareBuffers);
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

=head1 NAME

Text::Editor::Vip::Buffer::Test - Support functions for testing

=head1 SYNOPSIS

  use Test::More qw(no_plan);
  
  use Text::Editor::Vip::Buffer ;
  use Text::Editor::Vip::Buffer::Test ;
  
  my $buffer = new Text::Editor::Vip::Buffer() ;
  
  is(TestDoUndo('$buffer->DeleteLine(3) ;', '$buffer->Insert("Line 1\nLine 2\nLine 3\nLine 4") ;'), 1, 'test undo after DeleteLine') ;

=head1 DESCRIPTION

Support functions for testing

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub DiagBuffers
{

=head2 DiagBuffers

Displays the content of the buffer via the diag function.

=cut

my ($package, $file_name, $line) = caller() ;

my $buffer  = shift ;
my $comment = shift || '' ;

diag("\n$comment\n>>>>>\n" . $buffer->GetText() . "<<<<<\n") ;
}

#------------------------------------------------------------------------------------------------- 

sub TestSerialisation
{

=head2 TestSerialisation

Extract the do buffer from the buffer, applies it to another buffer and compares the buffers for equality

=cut


my $buffer = shift ;
my $new_buffer = $buffer->new() ;

my $do_buffer = $buffer->GetDoScript() ;
if($new_buffer->Do($do_buffer))
	{
	unless(CompareBuffers("Doing (original, new)", $buffer, $new_buffer))
		{
		#~ print "Do buffer:\n" . join("\n", grep{$_ !~ /\s+#/} split("\n",$do_buffer)) . "\n" ;
		#~ print "Do buffer:\n" . $do_buffer ;
		return(0) ;
		}
		
	}
else
	{
	diag("\nFailed Do!\n") ;
	return(0) ;
	}
	
return(1) ;
}

#------------------------------------------------------------------------------------------------- 

sub TestDoUndo
{

=head2 TestDoUndo

Given a script, obtained from a do buffer for example, this function checks the do and undo buffer creation.

An optional setup script can be passed. It is executed first.

=cut

my $script = shift ;

my $buffer_original = new Text::Editor::Vip::Buffer();
my $buffer_done     = new Text::Editor::Vip::Buffer();
my $buffer_undone   = new Text::Editor::Vip::Buffer();

my $setup_script = shift ;
my ($result, $message)  ;

for($buffer_original, $buffer_done, $buffer_undone)
	{
	($result, $message) = $_->Do($setup_script) ;
	die "TestDoUndo: Invalid setup script!\n$message" unless $result ;
	}

my $pos = $buffer_done->GetDoPosition() ;
($result, $message) = $buffer_done->Do($script) ;

my $error = 0 ;

if($result)
	{
	my $do_buffer = $buffer_done->GetDoScript($pos) ;
	my $undo_buffer = $buffer_done->GetUndoScript($pos) ;
	
	# test "do" perl script
	($result, $message) = $buffer_undone->Do($do_buffer) ;
	
	if($result)
		{
		ok(1, 'Valid perl do script') ;
		if(CompareBuffers("Doing (done, undone)", $buffer_done, $buffer_undone))
			{
			ok(1, 'perl do script OK')
			}
		else
			{
			$error++ ;
			diag("\nWould you like a do buffer dump?") ;
			my $answer = <STDIN> ;
			$answer = 'y' unless defined $answer ;
			
			if($answer ne "\n")
				{
				diag("do buffer:\n$do_buffer\n<<<<<\n") ;
				}
				
			}
		}
	else
		{
		$error++ ;
		diag($message) ;
		}
	
	# test "undo" perl script
	($result, $message) = $buffer_undone->Do($undo_buffer) ;
	
	if($result)
		{
		ok(1, 'Valid perl undo script') ;
		
		if(CompareBuffers("Undoing (original, undone)", $buffer_original, $buffer_undone))
			{
			ok(1, 'perl undo script OK')
			}
		else
			{
			$error++ ;
			diag("\nWould you like a do and an undo buffer dump?") ;
			my $answer = <STDIN> ;
			$answer = 'y' unless defined $answer ;
			
			if($answer ne "\n")
				{
				diag("do buffer:\n$do_buffer\n<<<<<\n") ;
				diag("Undo buffer:\n$undo_buffer\n<<<<<\n") ;
				}
				
			}
		}
	else
		{
		$error++ ;
		diag($message) ;
		}
		
	if($error)
		{
		diag("\nBuffer original:\n" . $buffer_original->GetText() . "\n<<<<<\n") ;
		diag("\nBuffer done:\n" . $buffer_done->GetText() . "\n<<<<<\n") ;
		diag("\nBuffer undone:\n" . $buffer_undone->GetText() . "\n<<<<<\n") ;
		}
	}
else
	{
	diag("\n Couldn't run TestDoUndo test:\n" . $message) ;
	$error++ ;
	}

return(!$error) ;
}

#------------------------------------------------------------------------------------------------- 

sub CompareBuffers
{

=head2 CompareBuffers

Compares two buffers for equality. debugging information is displayed if the buffers aren't equal.

=cut

# help functin to compare two buffers

my ($message, $lhb, $rhb) = @_ ;

my ($lhb_line, $lhb_character, $lhb_text) = ($lhb->GetModificationPosition(), $lhb->GetText()) ;
my ($rhb_line, $rhb_character, $rhb_text) = ($rhb->GetModificationPosition(), $rhb->GetText()) ;

# position
if ($lhb_line != $rhb_line || $lhb_character != $rhb_character)
	{
	diag("\n$message: Positon is different! ($lhb_line, $lhb_character) != ($rhb_line, $rhb_character).\n") ;
	
	diag("\nBuffer 1:\n" . hexdump(data => $lhb_text, start_position => 0, end_position => 100)) ;
	diag("\nBuffer 2:\n" . hexdump(data => $rhb_text, start_position => 0, end_position => 100)) ;
	
	return(0) ;
	}

# content
if($lhb_text ne $rhb_text)
	{
	diag("$message\n" . diff(\$lhb_text, \$rhb_text, {STYLE => 'Table'})) ;
	
	diag("\nBuffer 1:\n" . hexdump(data => $lhb_text, start_position => 0, end_position => 100)) ;
	diag("\nBuffer 2:\n" . hexdump(data => $rhb_text, start_position => 0, end_position => 100)) ;
	
	return(0) ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub CompareText
{

=head2 CompareText

Compares the passed text with the content of the buffer. Returns '' if the text is equal to the buffer
content. Returns a b<diff > if the texts won't match.

=cut

my $buffer = shift ;
my $text = shift ;

my $diff =  diff
		(
		  \($buffer->GetText())
		, \$text
		, {STYLE => 'Table', FILENAME_A => "Buffer", FILENAME_B => "Expected", INDEX_LABEL => "Ln"}
		) ;

$diff = "\n" . $diff unless $diff eq '' ;

return($diff) ;
}

#-------------------------------------------------------------------------------

sub PrintPositionData
{

=head2 PrintPositionData

Displays the modification and selection information.

=cut

my $buffer = shift ;
my $message = shift || '' ;

my ($package, $file_name, $line) = caller() ;
$message .= " @ '$file_name:$line'" ;

print "\n$message\n\tPosition: " .join(", ", $buffer->GetModificationPosition()) ;
print "\n\tSelection: " . join(", ", $buffer->GetSelectionBoundaries()) . "\n" ;
}

#-------------------------------------------------------------------------------

1;

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
