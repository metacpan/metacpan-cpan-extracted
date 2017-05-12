
package Text::Editor::Vip::Buffer::Plugins::Tags ;

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

Text::Editor::Vip::Buffer::Plugins::Tags- Tagging functionality plugin for Vip::Buffer

=head1 SYNOPSIS

  use 'Text::Editor::Vip::Buffer'; 

  my $buffer = new Text::Editor::Vip::Buffer() ;
  $buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Tags') ;

  $buffer->SetTagAtLine('debug', 10) ;
   ...
  $buffer->GotoNextTag('debug', 0) ;
  
=head1 DESCRIPTION

Tagging functionality plugin for Vip::Buffer

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub SetTagAtLine
{

=head2 SetTagAtLine

  $buffer->SetTagAtLine($class, $line) ;

Sets a tag of class '$class' (a string) at the passed line.

Multiple tags of different classes can be set at the same line. The tags are deleted is the line is deleted.

=cut

my $buffer     = shift ;
my $tag_class  = shift ;
my $line_index = shift ;
$line_index = $buffer->GetModificationLine() unless defined $line_index;

if(defined $tag_class && $tag_class ne '' && $line_index < $buffer->GetNumberOfLines())
	{
	my $line = $buffer->GetLine($line_index) ;
	$line->{TAGS}{$tag_class} = 1 ;
	} ;
}

#-------------------------------------------------------------------------------

sub ClearTagAtLine
{

=head2 ClearTagAtLine

  $buffer->ClearTagAtLine($class, $line) ;

=cut

my $buffer     = shift ;
my $tag_class  = shift ;
my $line_index = shift ;
$line_index = $buffer->GetModificationLine() unless defined $line_index;

if(defined $tag_class && $tag_class ne '' && $line_index < $buffer->GetNumberOfLines())
	{
	my $line = $buffer->GetLine($line_index) ;

	delete $line->{TAGS}{$tag_class} ;
	} ;
}

#-------------------------------------------------------------------------------

sub GotoNextTag
{

=head2 GotoNextTag

  $buffer->GotoNextTag($class, $start_line) ;

=cut

my $buffer           = shift ;
my $tag_class        = shift ;
my $start_line_index = shift ;

$start_line_index = $buffer->GetModificationLine() unless defined $start_line_index;

my $number_of_lines = $buffer->GetNumberOfLines() ;

if(defined $tag_class && $tag_class ne '' && $start_line_index < $number_of_lines)
	{
	for(my $line_index = $start_line_index + 1 ; $line_index < $number_of_lines ; $line_index++)
		{
		my $line = $buffer->GetLine($line_index) ;
		
		if(defined $line->{TAGS}{$tag_class} && 1 == $line->{TAGS}{$tag_class})	
			{
			$buffer->SetModificationLine($line_index) ;
			return($line_index) ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub GotoPreviousTag
{

=head2 GotoPreviousTag

  $buffer->GotoPreviousTag($class, $start_line) ;

=cut

my $buffer           = shift ;
my $tag_class        = shift ;
my $start_line_index = shift ;
$start_line_index = $buffer->GetModificationLine() unless defined $start_line_index;

if(defined $tag_class && $tag_class ne '')
	{
	for(my $line_index = $start_line_index - 1 ; $line_index >= 0 ; $line_index--)
		{
		my $line = $buffer->GetLine($line_index) ;
		
		if(defined $line->{TAGS}{$tag_class} && 1 == $line->{TAGS}{$tag_class})
			{
			$buffer->SetModificationLine($line_index) ;
			return($line_index) ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub FlipTagAtLine
{

=head2 FlipTagAtLine

  $buffer->FlipTagAtLine($class, $line) ;

Sets a tag at the given line if not already set; in that case the tag is removed.

=cut

my $buffer     = shift ;
my $tag_class  = shift ;
my $line_index = shift ;
$line_index = $buffer->GetModificationLine() unless defined $line_index;

if(defined $tag_class && $tag_class ne '' && $line_index < $buffer->GetNumberOfLines())
	{
	my $line = $buffer->GetLine($line_index) ;
	
	if(defined $line->{TAGS}{$tag_class} && 1 == $line->{TAGS}{$tag_class})
		{
		$line->{TAGS}{$tag_class} = 0 ;
		}
	else
		{
		$line->{TAGS}{$tag_class} = 1 ;
		}
	}
}

#-------------------------------------------------------------------------------

sub ClearAllTags
{

=head2 ClearAllTags

=cut

my $buffer     = shift ;
my $tag_class = shift ;

if(defined $tag_class && $tag_class ne '')
	{
	my $number_of_lines = $buffer->GetNumberOfLines() ;
	
	for(my $line_index = 0 ; $line_index < $number_of_lines ; $line_index++)
		{
		my $line = $buffer->GetLine($line_index) ;
		delete $line->{TAGS}{$tag_class} ;
		}
	}
}

#-------------------------------------------------------------------------------

sub AddNamedTag
{

=head2 AddNamedTag

  $buffer->AddNamedTag($class, $line, $name) ;

Multiple named tags, with different classes, can be set at the same line. The same named tag can
be set at multiple line.

=cut

my $buffer     = shift ;
my $tag_class  = shift ;

my $line_index = shift ;
$line_index = $buffer->GetModificationLine() unless defined $line_index;

my $tag_identifier = shift ;

if(defined $tag_class && $tag_class ne '' && defined $tag_identifier && $tag_identifier ne ''&& $line_index < $buffer->GetNumberOfLines())
	{
	my $line = $buffer->GetLine($line_index) ;
	$line->{TAGS}{$tag_class} = $tag_identifier ;
	} ;
}

#-------------------------------------------------------------------------------

sub GetNamedTags
{

=head2 GetNamedTags

  $buffer->GetNamedTags($class) ;

Returns a list of array references containing:

=over 2

=item * the tag name

=item * the tag's line

=back

=cut

my $buffer    = shift ;
my $tag_class = shift ;
my @tags ;

if(defined $tag_class && $tag_class ne '')
	{
	my $number_of_lines = $buffer->GetNumberOfLines() ;
	
	for(my $line_index = 0 ; $line_index < $number_of_lines ; $line_index++)
		{
		my $line = $buffer->GetLine($line_index) ;
		
		if(defined $line->{TAGS}{$tag_class})
			{
			push @tags, [$line->{TAGS}{$tag_class}, $line_index] ;
			}
		}
	
	return(\@tags) ;
	}
}

#-------------------------------------------------------------------------------

sub GotoNamedTag
{

=head2 GotoNamedTag

  $buffer->GotoNamedTag($class, $name) ;

Sets the modification line at the tags location.

=cut

my $buffer         = shift ;
my $tag_class      = shift ;
my $tag_identifier = shift ;

# should we wrap around and allow multiple instance of the same named tag?

if(defined $tag_class && $tag_class ne '' && defined $tag_identifier && $tag_identifier ne '')
	{
	my $number_of_lines = $buffer->GetNumberOfLines() ;
	
	for(my $line_index = 0 ; $line_index < $number_of_lines ; $line_index++)
		{
		my $line = $buffer->GetLine($line_index) ;
		
		if(exists $line->{TAGS}{$tag_class} && $line->{TAGS}{$tag_class} eq $tag_identifier)
			{
			$buffer->SetModificationLine($line_index) ;
			return($line_index) ;
			}
		}
	}
	
return() ;
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
