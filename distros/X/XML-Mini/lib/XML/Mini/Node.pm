package XML::Mini::Node;
use strict;
$^W = 1;
use XML::Mini;
use XML::Mini::TreeComponent;

use vars qw ( $VERSION @ISA );

push @ISA, qw ( XML::Mini::TreeComponent );
$VERSION = '1.36';

sub new
{
    my $class = shift;
    my $value = shift;
    
    my $self = {};
    bless $self, ref $class || $class;
    
    if (defined ($value))
    {
	if ($XML::Mini::IgnoreWhitespaces)
	{
	    $value =~ s/^\s*(.*?)\s*$/$1/;
	}
	
	if ($XML::Mini::AutoEscapeEntities)
	{
	    $value = XML::Mini->escapeEntities($value);
	}
	
	if ($XML::Mini::Debug)
	{
	    XML::Mini->Log("Setting value of node to '$value'");
	  }
	
	$self->{'_contents'} = $value;
    }
    return $self;
}

sub getValue
{
    my $self = shift;
    if ($XML::Mini::Debug)
    {
	XML::Mini->Log("Returning value of node as '" . $self->{'_contents'} . "'");
    }
    return $self->{'_contents'};
}

sub text
{
    my $self = shift;
    my $setToPrim = shift;
    my $setToAlt = shift;
    
    my $setTo = defined ($setToPrim) ? $setToPrim : $setToAlt;
    
    if (defined ($setTo))
    {
	if ($XML::Mini::IgnoreWhitespaces)
	{
	    $setTo =~ s/^\s*(.*?)\s*$/$1/;
	}
	
	if ($XML::Mini::AutoEscapeEntities)
	{
	    $setTo = XML::Mini->escapeEntities($setTo);
	}
	
	if ($XML::Mini::Debug)
	{
	    XML::Mini->Log("Setting text of node to '$setTo'");
	  }
	
	$self->{'_contents'} = $setTo;
    }
    return $self->{'_contents'};
}

sub numeric
{
    my $self = shift;
    my $setToPrim = shift;
    my $setToAlt = shift;
    
    my $setTo = defined ($setToPrim) ? $setToPrim : $setToAlt;
    
    if (defined $setTo)
    {
	if ($setTo =~ m/^\s*[Ee\d\.\+-]+\s*$/)
	{
	    return $self->text($setTo);
	} else {
	    XML::Mini->Error("Node::numeric() Must pass a NUMERIC value to set ($setTo)");
	  }
    }
    
    return $self->{'_contents'};
}

sub toString
{
    my $self = shift;
    my $depth = shift;
    
    if ($XML::Mini::Debug)
    {
	XML::Mini->Log("Node::toString() call with depth $depth");
      }

    if ($depth == $XML::Mini::NoWhiteSpaces)
    {
	return $self->toStringNoWhiteSpaces();
	
    }
    
    #my $spaces = $self->_spaceStr($depth);

    #my $retStr; = $spaces;
    my $retStr = $self->{'_contents'};
    #$retStr =~ s/\n\s*/\n$spaces/smg;

    return $retStr;
}

sub toStringNoWhiteSpaces
{
    my $self = shift;
    my $retStr = "$self->{'_contents'}";
    return $retStr;
}

1;

__END__

=head1 class XML::Mini::Node

Nodes are used as atomic containers for numerical and text data
and act as leaves in the XML tree.

They have no name or children.

They always exist as children of XML::MiniElements.
For example, 
<B>this text is bold</B>
Would be represented as a XML::MiniElement named 'B' with a single
child, a Node object which contains the string 'this text 
is bold'.

a Node has
 

 - a parent
 - data (text OR numeric)


=head2 getValue

Returns the text or numeric value of this Node.
	

=head2 text [SETTO [SETTOALT]]

The text() method is used to get or set text data for this node.
If SETTO is passed, the node's content is set to the SETTO string.

If the optional SETTOALT is passed and SETTO is false, the 
node's value is set to SETTOALT.  

Returns this node's text, if set or NULL 

=head2 	numeric [SETTO [SETTOALT]]

The numeric() method is used to get or set numerical data for this node.

If SETTO is passed, the node's content is set to the SETTO string.

If the optional SETTOALT is passed and SETTO is NULL, the 
node's value is set to SETTOALT.  

Returns this node's text, if set or NULL 

=head2 toString [DEPTH]

Returns this node's contents as a string.
If the special DEPTH $XML::Mini::NoWhiteSpaces is passed,
no whitespaces will be inserted.



=head1 AUTHOR


Copyright (C) 2002-2008 Patrick Deegan, Psychogenic Inc.

Programs that use this code are bound to the terms and conditions of the GNU GPL (see the LICENSE file). 
If you wish to include these modules in non-GPL code, you need prior written authorisation 
from the authors.


This library is released under the terms of the GNU GPL version 3, making it available only for 
free programs ("free" here being used in the sense of the GPL, see http://www.gnu.org for more details). 
Anyone wishing to use this library within a proprietary or otherwise non-GPLed program MUST contact psychogenic.com to 
acquire a distinct license for their application.  This approach encourages the use of free software 
while allowing for proprietary solutions that support further development.


=head2 LICENSE

    XML::Mini::Node module, part of the XML::Mini XML parser/generator package.
    Copyright (C) 2002-2008 Patrick Deegan
    All rights reserved
    
    XML::Mini is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    XML::Mini is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with XML::Mini.  If not, see <http://www.gnu.org/licenses/>.


Official XML::Mini site: http://minixml.psychogenic.com

Contact page for author available on http://www.psychogenic.com/




=cut

