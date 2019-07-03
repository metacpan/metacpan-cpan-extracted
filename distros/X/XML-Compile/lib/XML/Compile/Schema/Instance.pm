# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Schema::Instance;
use vars '$VERSION';
$VERSION = '1.63';


use warnings;
use strict;

use Log::Report        'xml-compile';
use XML::Compile::Schema::Specs;
use XML::Compile::Util qw/pack_type unpack_type/;
use Scalar::Util       qw/weaken/;

my @defkinds = qw/element attribute simpleType complexType
                  attributeGroup group/;
my %defkinds = map +($_ => 1), @defkinds;


sub new($@)
{   my $class = shift;
    (bless {}, $class)->init( {top => @_} );
}

sub init($)
{   my ($self, $args) = @_;
    my $top = $args->{top};
    defined $top && $top->isa('XML::LibXML::Node')
        or panic "instance is based on XML node";

    $self->{filename} = $args->{filename};
    $self->{source}   = $args->{source};
    $self->{$_}       = {} for @defkinds, 'sgs', 'import';
    $self->{include}  = [];

    $self->_collectTypes($top, $args);
    $self;
}


sub targetNamespace { shift->{tns} }
sub schemaNamespace { shift->{xsd} }
sub schemaInstance  { shift->{xsi} }
sub source          { shift->{source} }
sub filename        { shift->{filename} }
sub schema          { shift->{schema} }


sub tnses() {keys %{shift->{tnses}}}


sub sgs() { shift->{sgs} }


sub type($) { $_[0]->{types}{$_[1]} }


sub element($) { $_[0]->{element}{$_[1]} }


sub elements()        { keys %{shift->{element}} }
sub attributes()      { keys %{shift->{attributes}} }
sub attributeGroups() { keys %{shift->{attributeGroup}} }
sub groups()          { keys %{shift->{group}} }
sub simpleTypes()     { keys %{shift->{simpleType}} }
sub complexTypes()    { keys %{shift->{complexType}} }


sub types()           { ($_[0]->simpleTypes, $_[0]->complexTypes) }


my %skip_toplevel = map +($_ => 1), qw/annotation notation redefine/;

sub _collectTypes($$)
{   my ($self, $schema, $args) = @_;

    $schema->localName eq 'schema'
        or panic "requires schema element";

    my $xsd = $self->{xsd} = $schema->namespaceURI || '<none>';
    if(length $xsd)
    {   my $def = $self->{def}
          = XML::Compile::Schema::Specs->predefinedSchema($xsd)
            or error __x"schema namespace `{namespace}' not (yet) supported"
                  , namespace => $xsd;

        $self->{xsi} = $def->{uri_xsi};
    }

    my $tns;
    if($tns = $args->{target_namespace})
    {   $schema->removeAttribute('targetNamespace');
        $schema->setAttribute(targetNamespace => $tns);
    }
    else
    {   $tns = $schema->getAttribute('targetNamespace') || '';
    }
    $self->{tns} = $tns;

    $self->{efd} = $args->{element_form_default}
      || $schema->getAttribute('elementFormDefault')
      || 'unqualified';

    $self->{afd} = $args->{attribute_form_default}
      || $schema->getAttribute('attributeFormDefault')
      || 'unqualified';

    $self->{tnses} = {}; # added when used
    $self->{types} = {};

    $self->{schema} = $schema;
    weaken($self->{schema});

  NODE:
    foreach my $node ($schema->childNodes)
    {   next unless $node->isa('XML::LibXML::Element');
        my $local = $node->localName;
        my $myns  = $node->namespaceURI || '';
        $myns eq $xsd
            or error __x"schema element `{name}' not in schema namespace {ns} but {other}"
                 , name => $local, ns => $xsd, other => ($myns || '<none>');

        next
            if $skip_toplevel{$local};

        if($local eq 'import')
        {   my $namespace = $node->getAttribute('namespace')      || $tns;
            my $location  = $node->getAttribute('schemaLocation') || '';
            push @{$self->{import}{$namespace}}, $location;
            next NODE;
        }

        if($local eq 'include')
        {   my $location  = $node->getAttribute('schemaLocation')
                or error __x"include requires schemaLocation attribute at line {linenr}"
                   , linenr => $node->line_number;

            push @{$self->{include}}, $location;
            next NODE;
        }

        unless($defkinds{$local})
        {   mistake __x"ignoring unknown definition class {class}"
              , class => $local;
            next;
        }

        my $name  = $node->getAttribute('name')
            or error __x"schema component {local} without name at line {linenr}"
                 , local => $local, linenr => $node->line_number;

        my $tns   = $node->getAttribute('targetNamespace') || $tns;
        my $type  = pack_type $tns, $name;
        $self->{tnses}{$tns}++;
        $self->{$local}{$type} = $node;

        if(my $sg = $node->getAttribute('substitutionGroup'))
        {   my ($prefix, $l) = $sg =~ m/:/ ? split(/:/, $sg, 2) : ('',$sg);
            my $base = pack_type $node->lookupNamespaceURI($prefix), $l;
            push @{$self->{sgs}{$base}}, $type;
        }
    }

    $self;
}


sub includeLocations() { @{shift->{include}} }


sub imports() { keys %{shift->{import}} }


sub importLocations($)
{   my $locs = $_[0]->{import}{$_[1]};
    $locs ? @$locs : ();
}


sub printIndex(;$)
{   my $self   = shift;
    my $fh     = @_ % 2 ? shift : select;
    my %args   = @_;

    $fh->print("namespace: ", $self->targetNamespace, "\n");
    if(defined(my $filename = $self->filename))
    {   $fh->print(" filename: $filename\n");
    }
    elsif(defined(my $source = $self->source))
    {   $fh->print("   source: $source\n");
    }

    my @kinds
      = ! defined $args{kinds}      ? @defkinds
      : ref $args{kinds} eq 'ARRAY' ? @{$args{kinds}}
      :                               $args{kinds};

    my $list_abstract
      = exists $args{list_abstract} ? $args{list_abstract} : 1;

    foreach my $kind (@kinds)
    {   my $table = $self->{$kind};
        keys %$table or next;
        $fh->print("  definitions of ${kind}s:\n") if @kinds > 1;

        foreach (sort keys %$table)
        {   my $info = $self->find($kind, $_);
            my ($ns, $name) = unpack_type $_;
            next if $info->{abstract} && ! $list_abstract;
            my $abstract = $info->{abstract} ? ' [abstract]' : '';
            my $final    = $info->{final}    ? ' [final]' : '';
            $fh->print("    $name$abstract$final\n");
        }
    }
}


sub find($$)
{    my ($self, $kind, $full) = @_;
     my $node = $self->{$kind}{$full}
         or return;

     return $node    # translation of XML node into info is cached
         if ref $node eq 'HASH';

     my %info = (type => $kind, node => $node, full => $full);
     @info{'ns', 'name'} = unpack_type $full;

     $self->{$kind}{$full} = \%info;

     my $abstract    = $node->getAttribute('abstract') || '';
     $info{abstract} = $abstract eq 'true' || $abstract eq '1';

     my $final       = $node->getAttribute('final') || '';
     $info{final}    = $final eq 'true' || $final eq '1';

     my $local = $node->localName;
        if($local eq 'element')  { $info{efd} = $node->getAttribute('form') }
     elsif($local eq 'attribute'){ $info{afd} = $node->getAttribute('form') }
     $info{efd} ||= $self->{efd};   # both needed for nsContext
     $info{afd} ||= $self->{afd};
     \%info;
}

1;
