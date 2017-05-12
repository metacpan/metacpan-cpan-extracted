package Visio::Line;



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


$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

my $log = get_logger('visio.line');

# Preloaded methods go here.

sub new {
    my $class = shift;
    my $parentN = shift;
    my $self = {};
    $self->{parentN} = $parentN;
    $self->{xmldoc} = $parentN->ownerDocument;
    $self->{xmlroot} = $self->{xmldoc}->documentElement;
    bless($self,$class);
    my $lnNL = $self->{parentN}->findnodes('Line');
    if ($lnNL->size() > 0) {
	$self->{lineNode} = $lnNL->pop();
	$log->debug("visio line object already exists");
    } else {
	$self->{lineNode} = $self->{xmldoc}->createElement('Line');
	$self->{parentN}->appendChild($self->{lineNode});
	#lets create the page
	$log->debug("visio line object created");
    }
    return $self;
}

sub get_node {
    my $self = shift;
    return $self->{lineNode};
}

sub set_LineProperty {
    my $self = shift;
    my $property = shift;
    my $value = shift;
    my $format = shift;
    my $node = Visio::generic_create_node($self->{lineNode},
					  $property,
					  );
    Visio::generic_settext($node,$value);
    if (defined $format) {
	$node->setAttribute('F',$format);
    }
    $self->{property}{$property}=$property;
    return $node;
}


1;
__END__

=head1 NAME

Visio::Line - Perl extension for manipulation of visio lines

=head1 SYNOPSIS

  to be used with Viso module

=cut
