
package Text::Editor::Vip::Buffer::List;

use strict;
use warnings ;
use Carp qw(cluck) ;

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

Text::Editor::Vip::Buffer::List - lines container

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer::List

=head1 DESCRIPTION

Container class used by B<Text::Editor::Vip::Buffer> to hold the buffers text. Elements aer accessed by index.

=head1 MEMBER FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub new
{

=head2 new

Create an empty container. Takes no arguments.

=cut

my $invocant = shift ;
my $class = ref($invocant) || $invocant ;

return( bless [], $class );
}

#-------------------------------------------------------------------------------

sub GetNumberOfNodes
{

=head2 GetNumberOfNodes

Returns the number of contained elements.

=cut

return(scalar(@{$_[0]})) ;
}

#-------------------------------------------------------------------------------

sub Push
{

=head2 Push

Adds an element at the end of the the container. Returns it's index.

=cut

push @{$_[0]}, $_[1] ;
return($#{$_[0]}) ;
}

#-------------------------------------------------------------------------------

sub GetNodeData
{

=head2 GetNodeData

Returns an element or undef if the element doesn't exist.

  $list = new Text::Editor::Vip::Buffer::List() ;
  $list->Push(['some_element']) ;
  my $element = $list->GetNodeData(0) ;

=cut

my $this         = shift ;
my $a_node_index = shift ;

if(0 <= $a_node_index && $a_node_index < $this->GetNumberOfNodes())
	{
	return($this->[$a_node_index]) ;
	}
else
	{
	cluck("$a_node_index is an invalide node index") ;
	return(undef) ;
	}
}

#-------------------------------------------------------------------------------

sub SetNodeData
{

=head2 SetNodeData

Sets the element at the given index. The element must exist.

  my $index = 0 ;
  my $element = [] ;
  $list->SetNodeData($index, $element) ;

=cut

my $this         = shift ;
my $a_node_index = shift ;
my $a_node_data  = shift ;

if(0 <= $a_node_index && $a_node_index < $this->GetNumberOfNodes())
	{
	$this->[$a_node_index] = $a_node_data ;
	}
else
	{
	cluck("$a_node_index is an invalide node index") ;
	return(undef) ;
	}

}

#-------------------------------------------------------------------------------

sub DeleteNode
{

=head2 DeleteNode

Removes the lement at the given index. all elements after the given index are shifted up in the list. The element
must exist.

  $list->DeleteNode($index) ;

=cut

my $this         = shift ;
my $a_node_index = shift ;

if(0 != $this->GetNumberOfNodes())
	{
	if(0 <= $a_node_index && $a_node_index < $this->GetNumberOfNodes())
		{
		splice 
			(
			@{$this}
			, $a_node_index
			, 1
			) ;
		}
	else
		{
		cluck("$a_node_index is an invalide node index") ;
		}
	}
else
	{
	cluck('List is empty, nothing to delete !!') ;
	}
}

#-------------------------------------------------------------------------------

sub InsertAfter
{

=head2 InsertAfter

Creates and inserts an element in the list after the given index. The element at the given index must exist.

  $list->InsertAfter($index, $element_data) ;

=cut

my $this         = shift ;
my $a_node_index = shift ;
my $a_node_data  = shift ;

if(0 != $this->GetNumberOfNodes())
	{
	if(0 <= $a_node_index && $a_node_index < $this->GetNumberOfNodes())
		{
		splice 
			(
			@{$this}
			, $a_node_index + 1
			, 0
			, $a_node_data
			) ;
			
		return($a_node_index + 1) ;
		}
	else
		{
		cluck("$a_node_index is an invalide node index") ;
		}
	}
else
	{
	cluck('List is empty !!') ;
	}
}

#-------------------------------------------------------------------------------

sub InsertBefore
{

=head2 InsertBefore

Creates and inserts an element in the list before the given index. The element at the given index must exist.

  $list->InsertBefore($index, $element_data) ;

=cut

my ($this, $a_node_index, $a_node_data) = @_ ;

if(0 != $this->GetNumberOfNodes())
	{
	if(0 <= $a_node_index && $a_node_index < $this->GetNumberOfNodes())
		{
		if(0 == $a_node_index)
			{
			unshift @{$this}, $a_node_data ;
			}
		else
			{
			splice 
				(
				@{$this}
				, $a_node_index
				, 0
				, $a_node_data
				) ;
				
			return($a_node_index) ;
			}
		}
	else
		{
		cluck("$a_node_index is an invalide node index") ;
		}
	}
else
	{
	cluck('List is empty !!') ;
	}
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
