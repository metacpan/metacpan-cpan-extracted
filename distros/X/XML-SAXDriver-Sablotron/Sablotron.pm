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
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
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

package XML::SAXDriver::Sablotron;

use strict;
use warnings;

use XML::Sablotron;
use XML::Sablotron::DOM;
use XML::SAX::Base;

use vars qw($VERSION @ISA);

$VERSION = '0.30';
@ISA = qw(XML::SAX::Base);


sub new {
    my ($class, %opt) = @_;
    $class = ref $class || $class;
    my $self = { Stylesheet => $opt{Stylesheet},
		 Handler => $opt{Handler},
		 _sab_handlers => $opt{SablotHandlers},
		 ret => 0,
	       };
    bless $self, $class;
    return $self;
}

sub parse_uri {
    my ($self, $uri) = @_;
    my $sit = new XML::Sablotron::Situation;
    my $sab = new XML::Sablotron;
    
    $self->setSablotHandlers($sab);
    $sab->regHandler(2, $self);
    $sab->process($sit, $self->{Stylesheet}, $uri, "arg:/null");

    return $self->{ret};
}

sub parse_string {
    my ($self, $str) = @_;
    my $sit = new XML::Sablotron::Situation;
    my $sab = new XML::Sablotron;

    $self->setSablotHandlers($sab);
    $sab->regHandler(2, $self);
    $sab->addArg($sit, "_data", $str);
    $sab->process($sit, $self->{Stylesheet}, "arg:/_data", "arg:/null");

    return $self->{ret};
}

sub parse_dom {
    my ($self, $dom) = @_;
    my $sit = new XML::Sablotron::Situation;
    my $sab = new XML::Sablotron;
    my $templ = XML::Sablotron::DOM::parseStylesheet($sit,$self->{Stylesheet});

    $self->setSablotHandlers($sab);
    $sab->regHandler(2, $self);
    $sab->addArgTree($sit, 'data', $dom);
    $sab->addArgTree($sit, 'template', $templ);
    $sab->process($sit, 'arg:/template', 'arg:/data', 'arg:/null');

    return $self->{ret};
}

sub setSablotHandlers {
    my $self = shift;
    my $sab = shift;
    my $h;

    $h = $self->{_sab_handlers}{SchemeHandler};
    $sab->regHandler(1, $h) if $h;

    $h = $self->{_sab_handlers}{MessageHandler};
    $sab->regHandler(0, $h) if $h;

    $h = $self->{_sab_handlers}{MiscHandler};
    $sab->regHandler(3, $h) if $h;
}

############################################################
# SAX-like handler for Sablotron
############################################################

sub SAXStartDocument {
    my ($self, $proc) = @_;
    $self->SUPER::start_document;
    $self->{_pending_ns} = {};
    $self->{_ns_stack} = [{}]; #one empty slot
    $self->{_ele_stack} = [];
}

sub SAXStartNamespace {
    my ($self, $proc, $prefix, $uri) = @_;
    #print "---> SAXStartNamespace: $prefix, $uri\n";

    $self->{_pending_ns}{$prefix} = $uri;
    $self->SUPER::start_prefix_mapping({Prefix => $prefix, 
					NamespaceURI => $uri});
}

sub SAXEndNamespace {
    my ($self, $proc, $prefix) = @_;
    #print "---> SAXEndNamespace: $prefix\n";
    $self->SUPER::end_prefix_mapping({Prefix => $prefix});
}

sub SAXStartElement {
    my ($self, $proc, $name, %atts) = @_;
    #print "---> SAXStartElement: $name ";
    #print join " ", map {"$_=$atts{$_}"} keys %atts;
    #print "\n";

    #update namespace mappings
    my $ns = ${$self->{_ns_stack}}[-1];
    while (my($a, $b) = each %{$self->{_pending_ns}}) {
	$$ns{$a} = $b;
    }
    push @{$self->{_ns_stack}}, $ns;
    $self->{_pending_ns} = {};

    #create element for the SAX call
    my $ele = {Name => $name};

    #ns stuff
    my ($le, $pe);
    if (1) {
	if ($name =~ /(.*?):(.*)/) {
	    $pe = $1; $le = $2;
	} else {
	    $pe = ""; $le = $name;
	}
	$$ele{NamespaceURI} = $$ns{$pe};
	$$ele{Prefix} = $pe;
	$$ele{LocalName} = $le;
    }

    #attributes
    my $saxatts = {};
    foreach my $att (keys %atts) {
	my ($la, $pa);
	if ($att =~ /(.*?):(.*)/) {
	    $pa = $1; $la = $2;
	} else {
	    $pa = ""; $la = $att;
	}	
	my $uri = $$ns{$pa ? $pa : $pe};
	my $key = "$la";
	$key = "{$uri}" . $key if $uri;
	$$saxatts{$key} = {Name => "$att",
			   Value => $atts{$att},
			   NamespaceURI => $uri,
			   Prefix => $pa,
			   LocalName => $la,
			  };
    }
    $$ele{Attributes} = $saxatts;

    $self->SUPER::start_element($ele);
    delete $$ele{Attributes}; #save element for later use
    push @{$self->{_ele_stack}}, $ele;
}

sub SAXEndElement {
    my ($self, $proc, $name) = @_;
    #print "---> SAXEndElement: $name\n";

    $self->SUPER::end_element(pop @{$self->{_ele_stack}});
    pop @{$self->{_ns_stack}};
}

sub SAXCharacters {
    my ($self, $proc, $data) = @_;
    #print "---> SAXCharacters: $data\n";
    $self->SUPER::characters({Data => $data});
}

sub SAXComment {
    my ($self, $proc, $data) = @_;
    #print "---> SAXComment: $data\n";
    $self->SUPER::comment({Data => $data});
}

sub SAXPI {
    my ($self, $proc, $target, $data) = @_;
    #print "---> SAXPI: $target, $data\n";
    $self->SUPER::processing_instruction({Target => $target, Data => $data});
}

sub SAXEndDocument {
    my ($self, $proc) = @_;
    #print "---> SAXEndDocument\n";
    $self->{ret} = $self->SUPER::end_document;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::SAXDriver::Sablotron - Perl SAX driver for the Sablotron XSLT
processor

=head1 SYNOPSIS

  use XML::SAXDriver::Sablotron;
  use XML::Handler::SomeHandler;

  $handler = new XML::Handler::SomeHandler;
  $sab = new XML::SAXDriver::Sablotron(Stylesheet => "style.xsl",
                                    Handler => $handler);
  $sab->parse_uri("data.xml");

=head1 DESCRIPTION

This extension allows to run the Sablotron XSLT processor as a SAX
driver. A stylesheet passed to the constructor is applied to a
document passed in as the parse_uri method argument.

=head1 METHODS

=over

=item new(%params)

Constructs the driver. In addition to the standard L<XML::SAXDriver>
params you may add

B<Stylesheet> - the stylesheet URI

B<SablotHandlers> - the hash containing L<XML::Sablotron>
handlers. Available keys are B<SchemeHandler>, B<MessageHandler> and B<MiscHandler>

=item parse_uri($uri)

  Applies the stylesheet to an XML data specified by $uri. 

=item parse_string($string)

  Applies the stylesheet to an XML data serialized to the $string.

=item parse_dom($dom)

  Applies the stylesheet to a DOM object (by XML::Sablotron::DOM).

=back

=head1 AUTHOR

Pavel Hlavnicka; pavel@gingerall.cz

=head1 SEE ALSO

perl(1), XML::Sablotron(3)

=cut
