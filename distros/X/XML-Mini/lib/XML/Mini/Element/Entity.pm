package XML::Mini::Element::Entity;
use strict;
$^W = 1;

use XML::Mini;
use XML::Mini::Element;

use vars qw ( $VERSION @ISA );
$VERSION = '1.24';
push @ISA, qw ( XML::Mini::Element );

sub new
{
    my $class = shift;
    my $name = shift;
    my $value = shift;
    
    my $self = {};
    bless $self, ref $class || $class;
    
    $self->{'_attributes'} = {};
    $self->{'_numChildren'} = 0;
    $self->{'_numElementChildren'} = 0;
    $self->{'_children'} = [];
    $self->{'_avoidLoops'} = $XML::Mini::AvoidLoops;
    
    $self->name($name);
    
    my $oldAutoEscape = $XML::Mini::AutoEscapeEntities;
    $XML::Mini::AutoEscapeEntities = 0;
    $self->createNode($value) if (defined $value);
    $XML::Mini::AutoEscapeEntities = $oldAutoEscape;
    
    return $self;
}

sub toString
{
    my $self = shift;
    my $depth = shift;
    
    my $spaces;
    if ($depth == $XML::Mini::NoWhiteSpaces)
    {
	$spaces = '';
    } else {
	$spaces = $self->_spaceStr($depth);
    }
    
    my $retString = "$spaces<!ENTITY " . $self->name();
    
    if (! $self->{'_numChildren'})
    {
	$retString .= ">\n";
	return $retString;
    }
    
    my $nextDepth = ($depth == $XML::Mini::NoWhiteSpaces) ? $XML::Mini::NoWhiteSpaces
	: $depth + 1;
    $retString .= '"';
    for (my $i=0; $i < $self->{'_numChildren'}; $i++)
    {
	$retString .= $self->{'_children'}->[$i]->toString($XML::Mini::NoWhiteSpaces);
    }
    $retString .= '"';
    #$retString =~ s/\n//g;
    
    $retString .= " >\n";
    
    return $retString;
}


sub toStringNoWhiteSpaces
{
    my $self = shift;
    my $depth = shift;
    return $self->toString($depth);
}

1;

__END__

=head1 NAME

XML::Mini::Element::Entity

=head1 DESCRIPTION

The XML::Mini::Element::Entity is used internally to represent <!ENTITY name "stuff">.

You shouldn't need to use it directly, see XML::Mini::Element's entity() method.


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

    XML::Mini::Element module, part of the XML::Mini XML parser/generator package.
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




=head1 SEE ALSO


XML::Mini, XML::Mini::Document, XML::Mini::Element

http://minixml.psychogenic.com

=cut
