
package Text::Editor::Vip::Selection;
use strict;
use warnings ;

BEGIN 
{
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01_1;
@ISA         = qw (Exporter);
@EXPORT      = qw ();
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

=head1 NAME

Text::Editor::Vip::Selection - Selection Range

=head1 SYNOPSIS

  use Text::Editor::Vip::Selection
  $selection = new Text::Editor::Vip::Selection()
  
  $selection->IsEmpty() ;
  ...
  
=head1 DESCRIPTION

This class handles the boundaries of a selection and provides helper sub to manipulate the selection.

=head1 MEMBER FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub new
{
=head2 new

Crete a selection object .

=cut

my $invocant = shift ;
my $class = ref($invocant) || $invocant ;

my $object_reference = bless {}, $class ;
$object_reference->Setup(@_) ;

return($object_reference) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 Setup

Setup a newly created object. This sub is private and shouldn't be used directely.

=cut

my $this = shift ;

%$this = 
	(
	START_LINE       => -1
	, START_CHARACTER => -1
	, END_LINE       => -1
	, END_CHARACTER   => -1
	, @_
	) ;
}

#-------------------------------------------------------------------------------

use Clone ;

sub Clone
{

=head2 Clone

Returns a copy of the object.

=cut

my $this = shift ;

return(Clone::clone($this)) ;
}

#-------------------------------------------------------------------------------

sub IsEmpty
{

=head2 IsEmpty

Returns 1 (one) if the selection boundaries are the same. 

Retuns 0 (zero) if the object defined a non empty selection.

=cut

my $this = shift ;
if
	(
	$this->{START_LINE} == $this->{END_LINE}
	&& $this->{START_CHARACTER} == $this->{END_CHARACTER}
	)
	{
	return(1) ;
	}
else
	{
	return(0) ;
	}
}

#-------------------------------------------------------------------------------

sub Clear
{
=head2 Clear

Resets, the selection boundaries. The selection will be empty after calling this sub.

=cut

my $this = shift ;
$this->Setup() ;
}

#-------------------------------------------------------------------------------

sub Set($$$$) # Expects line and character
{

=head2 Set

Sets the selection boundaries. Four arguments are expected:

=over 2

=item * A start line

=item * A start character

=item * An end line

=item * An end character

=back

=cut

my $this = shift ;
$this->Setup() ;

$this->{START_LINE}      = shift ;
$this->{START_CHARACTER} = shift ;
$this->{END_LINE}        = shift ;
$this->{END_CHARACTER} = shift ;
}

#-------------------------------------------------------------------------------

sub SetAnchor($$) # Expects line and character
{

=head2 SetAnchor

Sets the selection anchor. Two arguments are expected:

=over 2

=item * An anchor line

=item * An anchor character

=back

=cut

my $this = shift ;
$this->Setup() ;

$this->{START_LINE}      = shift ;
$this->{START_CHARACTER} = shift ;
}

sub GetAnchor
{

=head2 GetAnchor

Returns the anchor position.

=cut

my $this = shift ;

return($this->{START_LINE}, $this->{START_CHARACTER} ) ;
}

#-------------------------------------------------------------------------------

sub SetLine($$) # Expects line and character
{

=head2 SetLine

This sub set the other boundary of a selection. The other booundary being set by B<SetAnchor>.

Two arguments are expected:

=over 2

=item * A line

=item * A character

=back

=cut

my $this = shift ;

$this->{END_LINE}      = shift ;
$this->{END_CHARACTER} = shift ;
}

sub GetLine
{

=head2 GetLine

Returns the other boundarie of a  selection.

=cut

my $this = shift ;

return($this->{END_LINE}, $this->{END_CHARACTER} ) ;
}

#-------------------------------------------------------------------------------

sub GetBoundaries
{

=head2 GetBoundaries

Returns the boundaries of a  selection as a list consisting of

=over 2

=item * selection start  line

=item * selection start  character

=item * selection end  line

=item * selection end character

=back

the selection start line will always be lower or equal to the selection end line. The selection
anchoring is handled automatically.

=cut

my $this = shift ;
if($this->{START_LINE} < $this->{END_LINE})
	{
	return
		(
		$this->{START_LINE}, $this->{START_CHARACTER}
		, $this->{END_LINE}, $this->{END_CHARACTER}
		) ;
	}
else
	{
	if($this->{START_LINE} == $this->{END_LINE})
		{
		if($this->{START_CHARACTER} < $this->{END_CHARACTER})
			{
			return
				(
				$this->{START_LINE}, $this->{START_CHARACTER}
				, $this->{END_LINE}, $this->{END_CHARACTER}
				) ;
			}
		else
			{
			return
				(
				$this->{START_LINE}, $this->{END_CHARACTER}
				, $this->{END_LINE}, $this->{START_CHARACTER}
				) ;
			}
		}
	else
		{
		return
			(
			$this->{END_LINE}, $this->{END_CHARACTER}
			, $this->{START_LINE}, $this->{START_CHARACTER}
			) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub GetStartLine
{

=head2 GetStartLine

Gets the selection start line.

=cut

my $this = shift ;
return(($this->GetBoundaries())[0]) ;
}

#-------------------------------------------------------------------------------

sub GetStartCharacter
{

=head2 GetStartCharacter

Gets the selection start character.

=cut

my $this = shift ;
return(($this->GetBoundaries())[1]) ;
}

#-------------------------------------------------------------------------------

sub GetEndLine
{

=head2 GetEndLine

Gets the selection end line.

=cut

my $this = shift ;
return(($this->GetBoundaries())[2]) ;
}

#-------------------------------------------------------------------------------

sub GetEndCharacter
{

=head2 GetEndCharacter

Gets the selection end character.

=cut

my $this = shift ;
return(($this->GetBoundaries())[3]) ;
}

#-------------------------------------------------------------------------------

sub IsCharacterSelected($$) # Expects a line and a character index
{

=head2 IsCharacterSelected

Given a line and character indexes, this sub returns 'true' if the given character is within
the selection boundaries. It otherwise returns 'false'.

=cut

my $this              = shift ;
my $a_line_index      = shift ;
my $a_character_index = shift ;

my ($start_line, $start_character, $end_line, $end_character) = $this->GetBoundaries() ;


if($start_line == $end_line && $start_line == $a_line_index)
	{
	return($start_character <= $a_character_index && $a_character_index < $end_character) ;
	}
if($start_line == $a_line_index)
	{
	return($start_character <= $a_character_index) ;
	}
if($end_line == $a_line_index)
	{
	return($a_character_index < $end_character) ;
	}
else
	{
	return($this->IsLineSelected($a_line_index)) ;
	}
}

#-------------------------------------------------------------------------------

sub IsLineSelected($)
{
=head2 IsLineSelected

Given a line index, this sub returns 'true' if the given line is completely selected.
It otherwise returns 'false'.

=cut

my $this         = shift ;
my $a_line_index = shift ;

my ($start_line, undef, $end_line, $end_character) = $this->GetBoundaries() ;

if($end_character == 0)
	{
	return($start_line <= $a_line_index && $a_line_index < $end_line) ;
	}
else
	{
	return($start_line <= $a_line_index && $a_line_index <= $end_line) ;
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
