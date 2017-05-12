
package Text::Editor::Vip::Buffer::Plugins::Clipboard ;

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

Text::Editor::Vip::Buffer::Plugins::Clipboard - Internal clipboard handling

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer ;
  $buffer = new Text::Editor::Vip::Buffer() ;
  
 $buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Clipboard') ;
 
=head1 DESCRIPTION

Access Text::Editor::Vip::Buffer internal buffers.

=head1 Functions

=cut

#-------------------------------------------------------------------------------------------------------------

sub SetClipboardContents
{

=head2 SetClipboardContents

Sets the content of the named clipboard.

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=item * text, a scalar, or an array ref (elements are joined to a single string)

=back

  $buffer->SetClipboardContents(4, 'something') ;
  $buffer->SetClipboardContents(4, ['something', "\n", 'hi']) ;

=cut

my ($buffer, $clipboard_name, $text_to_insert) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("SetClipboardContents: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 3)
	{
	$buffer->PrintError("SetClipboardContents: wrong number of arguments!") ;
	return(0) ;
	}

$text_to_insert ='' unless defined $text_to_insert ;
my @text_to_insert ;

if(ref($text_to_insert) eq 'ARRAY')
	{
	@text_to_insert = @$text_to_insert ;
	}
else
	{
	@text_to_insert = ($text_to_insert) ;
	}

#~ $buffer->{CLIPBOARDS}{$clipboard_name} = join('', @text_to_insert) ;

$buffer->{CLIPBOARDS}{$clipboard_name} = [@text_to_insert] ;
}

#-------------------------------------------------------------------------------------------------------------

sub GetClipboardContents
{

=head2 GetClipboardContents

Returns the contents of the named clipboard.

B<Arguments:>

=over 2

=item * clipboard name

=back

  $buffer->GetClipboardContents(4) ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name  || '' eq $clipboard_name)
	{
	$buffer->PrintError("GetClipboardContents: Invalid clipboard name!") ;
	return('') ;
	}

if(@_ != 2)
	{
	$buffer->PrintError("GetClipboardContents: wrong number of arguments!") ;
	return('') ;
	}

#~ exists $buffer->{CLIPBOARDS}{$clipboard_name} ? $buffer->{CLIPBOARDS}{$clipboard_name}	: '' ;
if(exists $buffer->{CLIPBOARDS}{$clipboard_name})
	{
	return
		(
		join('', @{$buffer->{CLIPBOARDS}{$clipboard_name}})
		)
	}
else
	{
	return('') ;
	}
}

#-------------------------------------------------------------------------------------------------------------

sub CopySelectionToClipboard
{

=head2 CopySelectionToClipboard

Makes a copy of the selected text and copies it to the named clipboard.

B<Arguments:>

=over 2

=item * clipboard name

=back

  $buffer->CopySelectionToClipboard('some_clipboard_name') ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("CopySelectionToClipboard: Invalid clipboard name!") ;
	return(0) ;
	}

if(@_ != 2)
	{
	$buffer->PrintError("CopySelectionToClipboard: wrong number of arguments!") ;
	return(0) ;
	}

if($buffer->IsSelectionEmpty)
	{
	# do nothing
	return(0) ;
	}
else
	{
	$buffer->RunSubOnSelection
				(
				sub
					{
					my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_;
					
					my $add_newline = $selection_line_index != $original_selection->GetEndLine()
											? "\n" 
											: '' ;
											
					$buffer->AppendToClipboardContents($clipboard_name, $text . $add_newline) ;
					
					# remember to not modify the line
					$text ;
					}
				, sub
					{
					$buffer->PrintError("Please select text to copy to clipboard '$clipboard_name'.\n") ;
					}
				) ;
				
	return(1) ;
	}
}

#-------------------------------------------------------------------------------------------------------------

sub InsertClipboardContents
{

=head2 InsertClipboardContents

Inserts the Contents of the named clipboard into the buffer.

B<Arguments:>

=over 2

=item * clipboard name

=back

  $buffer->InsertClipboardContents('my_clipboard') ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("InsertClipboardContents: Invalid clipboard name!") ;
	return(0) ;
	}

if(@_ != 2)
	{
	$buffer->PrintError("InsertClipboardContents: wrong number of arguments!") ;
	return(0) ;
	}

#~ $buffer->Insert($buffer->{CLIPBOARDS}{$clipboard_name}) ;
$buffer->Insert($buffer->GetClipboardContents($clipboard_name)) ;

return(1) ;
}

#---------------------------------------------------------------------------------------------

sub ClearClipboardContents
{

=head2 ClearClipboardContents


B<Arguments:>

=over 2

=item * clipboard name

=back

  $buffer->ClearClipboardContents('clipboard_1') ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("ClearClipboardContents: Invalid clipboard name!") ;
	return(0) ;
	}

if(@_ != 2)
	{
	$buffer->PrintError("ClearClipboardContents: wrong number of arguments!") ;
	return(0) ;
	}

delete $buffer->{CLIPBOARDS}{$clipboard_name} ;

return(1) ;
}

#---------------------------------------------------------------------------------------------

sub AppendToClipboardContents
{

=head2 AppendToClipboardContents

Adds the text argument to the end of the clipboard.

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=item * text, a scalar, or an array ref (elements are joined to a single string)

=back

  $buffer->AppendToClipboardContents('clipboard_2', "some string and a newline\n") ;

=cut

my ($buffer, $clipboard_name, $text_to_insert) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("AppendToClipboardContents: Invalid clipboard name!") ;
	return(0) ;
	}

if(@_ != 3)
	{
	$buffer->PrintError("AppendToClipboardContents: wrong number of arguments!") ;
	return(0) ;
	}

$text_to_insert = '' unless defined $text_to_insert ;
my @text_to_insert ;

if(ref($text_to_insert) eq 'ARRAY')
	{
	@text_to_insert = @$text_to_insert ;
	}
else
	{
	@text_to_insert = ($text_to_insert) ;
	}

#~ $buffer->{CLIPBOARDS}{$clipboard_name} .= join('', @text_to_insert) ;

push @{$buffer->{CLIPBOARDS}{$clipboard_name}}, @text_to_insert ;

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------

sub PopClipboard
{

=head2 PopClipboard

Removes the last entry of a clipboard and returnes it. An error is displayed if the clipboard is empty.

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=back

  $buffer->PopClipboard(4) ;

=cut

my ($buffer, $clipboard_name, $text_to_insert) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("PopClipboard: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 2)
	{
	$buffer->PrintError("PopClipboard: wrong number of arguments!") ;
	return(0) ;
	}

if(@{$buffer->{CLIPBOARDS}{$clipboard_name}})
	{
	return( pop @{$buffer->{CLIPBOARDS}{$clipboard_name}} ) ;
	}
else
	{
	$buffer->PrintError("PopClipboard: clipboard '$clipboard_name' is empty!") ;
	return('') ;
	}
}

#-------------------------------------------------------------------------------------------------------------

sub GetNumberOfClipboardElements
{

=head2 GetNumberOfClipboardElements

Returns the number of elements in the clipboard, zero if the clipboard doesn't exist.

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=back

  $buffer->GetNumberOfClipboardElements(4) ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("PopClipboard: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 2)
	{
	$buffer->PrintError("PopClipboard: wrong number of arguments!") ;
	return(0) ;
	}

if(exists $buffer->{CLIPBOARDS}{$clipboard_name})
	{
	return(scalar (@{$buffer->{CLIPBOARDS}{$clipboard_name}})) ;
	}
else
	{
	return(0) ;
	}
}

#-------------------------------------------------------------------------------------------------------------

sub YankLineToClipboard
{

=head2 YankLineToClipboard

Removes a line from the buffer and adds it to a clipboard

B<Arguments:>

=over 2

=item * line number

=item * clipboard name, a scalar

=back

  $buffer->YankLineToClipboard(4, 'clipboard') ;

=cut

my ($buffer, $line, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("YankLineToClipboard: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 3)
	{
	$buffer->PrintError("YankLineToClipboard: wrong number of arguments!") ;
	return(0) ;
	}

if(! defined $line || $line < 0 || $line > $buffer->GetLastLineIndex())
	{
	$buffer->PrintError("SetClipboardContents: Invalid line arguments!") ;
	return(0) ;
	}
	
$buffer->AppendToClipboardContents($clipboard_name, $buffer->GetLineTextWithNewline($line));
$buffer->DeleteLine($line) ;

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------

sub YankSelectionToClipboard
{

=head2 YankSelectionToClipboard

Removes the current selection from the buffer and adds it to a clipboard

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=item * text, a scalar, or an array ref (elements are joined to a single string)

=back

  $buffer->YankSelectionToClipboard('clipboard') ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("YankSelectionToClipboard: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 2)
	{
	$buffer->PrintError("YankSelectionToClipboard: wrong number of arguments!") ;
	return(0) ;
	}

$buffer->RunSubOnSelection
			(
			sub
				{
				my ($text, $selection_line_index, $modification_character, $original_selection, $buffer) = @_;
				
				#~ $buffer->AppendToClipboardContents($clipboard_name, $buffer->GetSelectionText($selection_line_index)) ;
				
				my $add_newline = $selection_line_index != $original_selection->GetEndLine()
										? "\n"
										: '' ;
										
				$buffer->AppendToClipboardContents($clipboard_name, $text . $add_newline) ;
				
				# remove selection content  from buffer
				return(undef) ;
				}
			, sub
				{
				$buffer->PrintError("Please select text to yank to clipboard '$clipboard_name'.\n") ;
				}
			) ;
			
return(1) ;

}

#-------------------------------------------------------------------------------------------------------------

sub AppendCurrentLineToClipboardContents
{

=head2 AppendCurrentLineToClipboardContents

Adds the current line  to a clipboars

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=back

  $buffer->AppendCurrentLineToClipboardContents(4) ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("AppendCurrentLineToClipboardContents: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 2)
	{
	$buffer->PrintError("AppendCurrentLineToClipboardContents: wrong number of arguments!") ;
	return(0) ;
	}

$buffer->AppendToClipboardContents($clipboard_name, $buffer->GetLineTextWithNewline()) ;

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------

sub AppendSelectionToClipboardContents
{

=head2 AppendSelectionToClipboardContents

Adds the current selection to a clipboars

B<Arguments:>

=over 2

=item * clipboard name, a scalar

=back

  $buffer->AppendSelectionToClipboardContents(4, 'clipboard') ;

=cut

my ($buffer, $clipboard_name) = @_ ;

if('' ne ref $clipboard_name || ! defined $clipboard_name || '' eq $clipboard_name)
	{
	$buffer->PrintError("AppendSelectionToClipboardContents: Invalid clipboard name!") ;
	return(0) ;
	}
	
if(@_ != 2)
	{
	$buffer->PrintError("AppendSelectionToClipboardContents: wrong number of arguments!") ;
	return(0) ;
	}

unless($buffer->IsSelectionEmpty())
	{
	$buffer->AppendToClipboardContents($clipboard_name, $buffer->GetSelectionText()) ;
	}
else
	{
	$buffer->PrintError("AppendSelectionToClipboardContents: no selection!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------
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
