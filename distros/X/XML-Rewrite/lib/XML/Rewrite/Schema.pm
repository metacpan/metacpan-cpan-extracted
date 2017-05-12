# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package XML::Rewrite::Schema;
use vars '$VERSION';
$VERSION = '0.10';

use base 'XML::Rewrite';

use Log::Report 'xml-rewrite', syntax => 'SHORT';

use XML::Compile::Util    qw/pack_type type_of_node :constants/;
use XML::LibXML           ();
use File::Spec::Functions qw/catfile/;
use File::Basename        qw/dirname/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{XRS_elemform} = $args->{element_form};
    $self->{XRS_attrform} = $args->{attribute_form};
    $self->{XRS_target}   = $args->{target_namespace};
    $self->{XRS_include}  = $args->{expand_includes};

    $self->importDefinitions( [SCHEMA2001, XMLNS] );

    # Something must be produced for an annotation: it's required
    $self->addHook( id => 'annotation'
                  , replace => sub { ($_[3] => XML::LibXML::Text->new('')) } )
        if $args->{remove_annotations};

    $self->addHook( id => [ qw/key keyref unique/ ]
                  , replace => sub { ($_[3] => XML::LibXML::Text->new('')) } )
        if $args->{remove_identity_constraints};

    $self;
}


sub repairXML($$$)
{   my ($self, $type, $schema, $details) = @_;

    $self->SUPER::repairXML($type, $schema, $details);
    $self->repairSchemaHeader($schema);
    $self;
}

sub repairSchemaHeader($)
{   my ($self, $schema) = @_;
    # we cannot interfere with the parser directly, so will need
    # modify the XML tree.
    if(my $elemform = $self->{XRS_elemform})
    {   $schema->removeAttribute('elementFormDefault');
        $schema->setAttribute(elementFormDefault => $elemform);
    }

    if(my $attrform = $self->{XRS_attrform})
    {   $schema->removeAttribute('attributeFormDefault');
        $schema->setAttribute(elementFormDefault => $attrform);
    }

    if(my $target = $self->{XRS_target})
    {   $schema->removeAttribute('targetNamespace');
        $schema->setAttribute(targetNamespace => $target);
    }
}

sub transformData($$$)
{   my ($self, $type, $data, $details) = @_;
    $self->SUPER::transformData($type, $data, $details);
    $self->transformForm($data);
    $self->expandIncludes($data, $details) if $self->{XRS_include};
    $self;
}

sub transformForm($)
{   my ($self, $data) = @_;

    if(my $elemform = $self->{XRS_elemform})
    {    $elemform eq 'unqualified' || $elemform eq 'qualified'
         or error __x"element for must be qualied or unqualified, not {form}"
              , form => $elemform;
         $data->{elementFormDefault} = $elemform;
    }

    if(my $attrform = $self->{XRS_attrform})
    {    $attrform eq 'unqualified' || $attrform eq 'qualified'
         or error __x"attribute for must be qualied or unqualified, not {form}"
              , form => $attrform;
         $data->{attributeFormDefault} = $attrform;
    }

    if(my $target = $self->{XRS_target})
    {   $data->{targetNamespace} = $target;
    }

    $self;
}

sub expandIncludes($$$)
{   my ($self, $data, $details) = @_;
    my $prefixes = $self->prefixes;
    my $xsd      = $prefixes->{&SCHEMA2001}{prefix};
    $xsd        .= '_' if length $xsd;

    my %included;
    my $cho_in = $data->{"cho_${xsd}include"} or return;
    my @cho_in = @$cho_in;
    my @cho_out;
    my @toplevel = @{$data->{"seq_${xsd}schemaTop"} || []};
    foreach my $incl (@cho_in)
    {   my ($kind, $def) = %$incl;
        if($kind ne "${xsd}include")
        {   push @cho_out, $incl;
            next;
        }

        my $basefn = $details->{filename};
        defined $basefn
            or error __x"includes need base filename";

        my $relfn  = $def->{schemaLocation} or next;
        my $inclfn = catfile dirname($basefn), $relfn;

        if($included{$inclfn}++)
        {   trace "include file $inclfn already seen";
            next;
        }

        my $doc    = eval { XML::LibXML->new->parse_file($inclfn) };
        if($@)
        {   notice __x"include file {fn} cannot be used", fn => $inclfn;
            push @cho_out, $incl;
            next;
        }
        trace "including {$inclfn}";

        my $xml     = $doc->documentElement;
        my $type    = type_of_node $xml;
        $type eq pack_type(SCHEMA2001, 'schema')
            or error __x"file {fn} does not contain a schema", fn => $type;

        # gladly, the reader will use the same prefix table!
        my $include = $self->reader($type)->($xml);

        # include location should be rewritten, but usually ok
        unshift @cho_in,   @{$include->{"cho_${xsd}include"}   || []};
        unshift @toplevel, @{$include->{"seq_${xsd}schemaTop"} || []};
    }
    $data->{"cho_${xsd}include"}   = \@cho_out;
    $data->{"seq_${xsd}schemaTop"} = \@toplevel;
}

1;
