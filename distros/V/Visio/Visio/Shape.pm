package Visio::Shape;





#PLEASE SEE MSPATENTLICENSE
# "This product may incorporate intellectual property owned by 
# Microsoft Corporation. The terms and conditions upon which Microsoft 
# is licensing such intellectual property may be found at 
# http://msdn.microsoft.com/library/en-us/odcXMLRef/html/odcXMLRefLegalNotice.asp"

# Copyright 2005 Aamer Akhter. All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE LICENSOR(S) ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE LICENSOR(S) OR OTHER CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation
# are those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of the Licensor(s).

# The software may be subject to additional license restrictions
# provided by the Licensor(s).


use 5.008;
use strict;
use warnings;
use Log::Log4perl  qw(get_logger);
use XML::LibXML;
use Carp;
use Data::Dumper;
use vars qw($VERSION);

use Visio::Line;
use Visio::Layout;
use Visio::Hyperlink;

$VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

my $log = get_logger('visio.Shape');

# Preloaded methods go here.

sub new {
    my $class = shift;
    my $ShapesN = shift;
    my $id = shift;
    my $opts = shift;
    my $fromMaster = $$opts{fromMaster};
    my $self = {};
    $self->{pageSelf} = $$opts{pageSelf};
    $self->{ShapesN} = $ShapesN;
    $self->{xmldoc} = $ShapesN->ownerDocument;
    $self->{xmlroot} = $self->{xmldoc}->documentElement;
    $self->{shapeid} = $id;
    bless($self,$class);
    $self->{shapeNode} = $self->{xmldoc}->createElement('Shape');
    $self->{ShapesN}->appendChild($self->{shapeNode});
    if (defined $fromMaster) {
	$self->{shapeNode}->setAttribute('Master',
					 $fromMaster->get_id()
					 );
    }
    $self->set_id;
    $log->debug("visio Shape object ($id) created");
    return $self;
}

sub set_id {
    my $self = shift;
    $self->{shapeNode}->setAttribute('ID',$self->{shapeid});
}

sub get_id {
    my $self = shift;
    return $self->{shapeid};
}



sub set_name {
    my $self = shift;
    my $name = shift;
    $self->{shapeNode}->setAttribute('Name',$name);
}

sub get_node {
    my $self = shift;
    return $self->{shapeNode};
}


sub set_text {
    my $self = shift;
    my $text = shift;
    my $opts = shift;
    my $textN = Visio::generic_create_node($self->{shapeNode},
					      'Text'
					      );
    my $textNode = $self->{xmldoc}->createTextNode($text);
    $textN->removeChildNodes();
    $textN->appendChild($textNode);
}


sub get_line {
    my $self = shift;
    if (defined $self->{Line}) {
    } else {
	$self->{Line} =
	    new Visio::Line($self->{shapeNode});
    }
    return $self->{Line};
}

sub get_hyperlink {
    my $self = shift;
    my $opts = shift;
    my $hlink;
    if (defined $self->{maxhyperlinkid}) {
	$self->{maxhyperlinkid} = $self->{maxhyperlinkid} + 1;	
    } else {
	$self->{maxhyperlinkid} = 1;	
    }

    $hlink = new Visio::Hyperlink(
				  $self->{shapeNode},
				  $self->{maxhyperlinkid}
				  );
    foreach my $key (keys %$opts) {
	if ($key =~ /^-(.+)/) {
	    my $prop = $1;
	    $hlink->set_property($prop,$$opts{$key});
	} else {

	}
    }
    return $hlink;
}


sub set_LineProperty {
    my $self = shift;
    my $property = shift;
    my $value = shift;
    my $format = shift;
    $self->get_line()->set_LineProperty($property,$value,$format)
}

sub get_layout {
    my $self = shift;
    if (defined $self->{Layout}) {
    } else {
	$self->{Layout} =
	    new Visio::Layout($self->{shapeNode});
    }
    return $self->{Layout};
}

sub set_LayoutProperty {
    my $self = shift;
    my $property = shift;
    my $value = shift;
    my $format = shift;
    $self->get_layout()->set_LayoutProperty($property,$value,$format)
}

sub connect {
    my $self = shift;
    my $begin = shift;
    my $end = shift;
    if (!defined $begin) {
	$log->error('$begin not defined in connect');
	return -1;
    }
    if ($begin->isa('Visio::Shape')) {
	$begin = $begin->get_id;
    }
    if (!defined $end) {
	$log->error('$end not defined in connect');
	return -1
    }
    if ($end->isa('Visio::Shape')) {
	$end = $end->get_id;
    }

    my $connectN1 = $self->{pageSelf}->create_connect();
    $connectN1->setAttribute('FromSheet',$self->{shapeid});
    $connectN1->setAttribute('FromCell','BeginX');
    $connectN1->setAttribute('ToSheet',$begin);
    $connectN1->setAttribute('ToCell','PinX');

    my $connectN2 = $self->{pageSelf}->create_connect();
    $connectN2->setAttribute('FromSheet',$self->{shapeid});
    $connectN2->setAttribute('FromCell','EndX');
    $connectN2->setAttribute('ToSheet',$end);
    $connectN2->setAttribute('ToCell','PinX');
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Visio::Shape - Perl extension for manipulation of visio shapes

=head1 SYNOPSIS

 to be used with Visio module

=cut
