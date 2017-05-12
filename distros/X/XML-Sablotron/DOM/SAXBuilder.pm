# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron::SAXBuilder module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2001 Ginger Alliance.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package XML::Sablotron::SAXBuilder;

use XML::Sablotron;
use XML::Sablotron::DOM;
use strict;

sub new {
    my $class = shift;
    my $self = {
		Doc => undef,
		Parent => undef
	       };

    return bless $self, $class;
}

sub start_document {
    my ($self) = @_;

    $self->{Doc} = new XML::Sablotron::DOM::Document;
    $self->{Parent} = $self->{Doc};
}

sub end_document {
    my ($self) = @_;

    my $doc = $self->{Doc};
    $self->{Parent} = undef;
    $self->{Doc} = undef;
    return $doc;
}

sub start_element {
    my ($self, $element) = @_;

    my $e = $self->{Doc}->createElement($element->{Name});
    $self->{Parent}->appendChild($e);
    $self->{Parent} = $e;

    # attributes
    my @keys = keys %{$element->{Attributes}};
    if (ref($element->{Attributes}->{$keys[0]})) {
	#SAX2 style
	foreach (keys %{$element->{Attributes}}) {
	$e->setAttribute($element->{Attributes}->{$_}->{Name},
			 $element->{Attributes}->{$_}->{Value});
	}
    } else {
	#SAX1 style
	$e->setAttributes($element->{Attributes});
    }
}

sub end_element {
    my ($self, $element) = @_;

    unless ($self->{Parent} == $self->{Doc}) {    
	$self->{Parent} = $self->{Parent}->getParentNode();
    }
}

sub characters {
    my ($self, $data) = @_;
    
    if ($self->{CDATA}) {
	$self->{Parent}->appendChild(
		$self->{Doc}->createCDATASection($data->{Data})
	);
    } else {
	$self->{Parent}->appendChild(
		$self->{Doc}->createTextNode($data->{Data})
	);
    }
}

sub ignorable_whitespace{
    my ($self, $data) = @_;
}

sub processing_instruction {
    my ($self, $pi) = @_;

    $self->{Parent}->appendChild(
	$self->{Doc}->createProcessingInstruction($pi->{Target},$pi->{Data})
    );
}

sub start_cdata {
    my ($self) = @_;
    
    $self->{CDATA} = 1;
}

sub end_cdata {
    my ($self) = @_;

    delete $self->{CDATA};
}

sub comment {
    my ($self, $comment) = @_;
    
    $self->{Parent}->appendChild(
	$self->{Doc}->createComment($comment->{Data})
    );
}

1;

__END__
# Below is a documentation.

=head1 NAME

XML::Sablotron::SAXBuilder -  builds a Sablotron DOM document from SAX events

=head1 SYNOPSIS

 use XML::Sablotron;
 use XML::Sablotron::DOM;
 use XML::Sablotron::SAXBuilder;
 use XML::Directory;

 $dir = new XML::Directory($path);
 $builder = new XML::Sablotron::SAXBuilder;
 $doc = $dir->parse_SAX($builder);

=head1 DESCRIPTION

This is a SAX handler generating a Sablotron DOM tree from SAX events.
Input should be accepted from any SAX1 or SAX2 event generator. This
handler implements all methods required for basic Perl SAX 2.0 handler
and some of the advanced methods (that make sense for Sablotron DOM tree).

In particular, the following methods are available:

=over

=item start_document

=item end_document

=item start_element

=item end_element

=item characters

=item ignorable_whitespace

=item processing_instruction

=item start_cdata

=item end_cdata

=item comment

=back

Namespaces are not supported by XML::Sablotron::DOM yet, therefore SAX2
events are accepted but NS information is ignored.

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

XML::Sablotron, XML::Sablotron::DOM, perl(1).

=cut

