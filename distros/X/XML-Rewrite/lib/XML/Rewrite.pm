# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package XML::Rewrite;
use vars '$VERSION';
$VERSION = '0.10';

use base 'XML::Compile::Cache';

use Log::Report 'xml-rewrite', syntax => 'SHORT';

use XML::Compile::Util qw/pack_type type_of_node unpack_type SCHEMA2001/;
use XML::LibXML        ();


sub init($)
{   my ($self, $args) = @_;

    $args->{any_element}   = 'ATTEMPT';
    $args->{any_attribute} = 'ATTEMPT';

    my $mode = $self->{XR_change} = $args->{change} || 'TRANSFORM';
    $mode eq 'REPAIR' || $mode eq 'TRANSFORM'
        or error __x"change mode must be either REPAIR or TRANSFORM, not `{got}'"
             , got => $mode;
    my $blanks = $self->{XR_blanks} = $args->{blanks_before} || 'NONE';
    $blanks eq 'ALL' || $blanks eq 'CONTAINERS' || $blanks eq 'ALL'
        or error __x"blanks_before must be ALL, CONTAINERS or ALL, not `{got}'"
             , got => $blanks;
 
    push @{$args->{opts_rw}}
      , mixed_elements     => 'STRUCTURAL'
      , use_default_namespace => $args->{use_default_namespace}
      , key_rewrite        => 'PREFIXED';

    my @read_hooks = ( {after => 'XML_NODE'} );
    foreach ( @{$args->{remove_elems}} )
    {   my $type = $self->findName($_) or next;
warn "REMOVE TYPE=$type not yet implemented";
    }

    my $comments = $args->{comments} || 'KEEP';
    if($comments eq 'KEEP')
    {   push @read_hooks, {after => \&take_comments_hook};
    }
    elsif($comments ne 'REMOVE')
    {   error __x"comment option either KEEP or REMOVE, not `{got}'"
           , got => $comments;
    }

    push @{$args->{opts_readers}}
      , hooks              => \@read_hooks
      , any_element        => ($args->{any_element} || 'CONVERT')
      , default_values     => 'IGNORE';

    my @write_hooks = +{after => sub {$self->nodeDataRelation(@_)}};

    push @{$args->{opts_writers}}
      , hooks              => \@write_hooks
      , include_namespaces => 1
      , ignore_unused_tags => qr/^_[A-Z_]*$/
      , default_values     => $args->{defaults_writer};

    defined $args->{allow_undeclared}
        or $args->{allow_undeclared} = 1;

    $self->SUPER::init($args);

    $self->{XR_encoding}   = $args->{output_encoding};
    $self->{XR_version}    = $args->{output_version};
    $self->{XR_alone}      = $args->{output_standalone};
    if(my $compr = $self->{XR_compress} = $args->{output_compression})
    {   $compr >= -1 && $compr <= 8
           or error __x"compression between -1 (off) and 8";
    }

    $self->{XR_prefixes}
     = [ map { $_->{prefix} => $_->{uri} } values %{$self->{XCC_prefix}} ];

    $self;
}


sub process($@)
{   my ($self, $xmldata, %args) = @_;

    # avoid the schema cache!
    my ($xml, %details) = XML::Compile->dataToXML($xmldata);
    my $type = $args{type} || type_of_node $xml;

    my $mode = $self->{XR_change};
    $self->repairXML($type, $xml, \%details)
        if $mode eq 'REPAIR';

    my $data = $self->reader($type)->($xml);

    $self->collectDocInfo($data, $xml);

    $self->transformData($type, $data, \%details)
        if $mode eq 'TRANSFORM';

    ($type, $data);
}


sub repairXML($$$)
{   my ($self, $type, $xml, $details) = @_;
    trace "repairing XML";

    $self->repairNamespaces($xml);
    $self;
}

sub repairNamespaces($)
{   my ($self, $top) = @_;

    my @kv = @{$self->{XR_prefixes}};
    while(@kv)
    {   my ($prefix, $uri) = (shift @kv, shift @kv);
           $top->setNamespaceDeclURI($prefix, $uri)
        or $top->setNamespace($uri, $prefix, 0);
        $self->{XCC_prefix}{$uri}{used}++;
    }
    $self;
}

sub collectDocInfo($$)
{   my ($self, $data, $xml) = @_;

    if(my $doc  = $xml->ownerDocument)
    {   my $info = $data->{_DOC_INFO} ||= {};
        $info->{encoding}   = $doc->encoding;
        $info->{version}    = $doc->version;
        $info->{standalone} = $doc->standalone;
        $info->{compress}   = $doc->compression;
    }
    $data;
}


sub transformData($$$)
{   my ($self, $type, $data, $details) = @_;
    trace "transforming data structure";

    $self->transformDoc($data);
    $data;
}

sub transformDoc($)
{   my ($self, $data) = @_;

    my $di = $data->{_DOC_INFO} || {};

    $di->{version}   = $self->{XR_version}   if $self->{XR_version};
    $di->{version} ||= '1.0';

    $di->{encoding}   = $self->{XR_encoding} if $self->{XR_encoding};
    $di->{encoding} ||= 'UTF-8';

    $di->{compress}  = $self->{XR_compress}  if $self->{XR_compress};

    my $a = defined $self->{XR_alone} ? $self->{XR_alone} : $self->{XR_alone};
    if(defined $a)
    {   $di->{standalone} = $a eq 'no' || $a eq '0' ? 0 : 1;
    }

    $self;
}


sub buildDOM($$@)
{   my ($self, $type, $data, %args) = @_;

    my $di   = $data->{_DOC_INFO} or panic "no doc-info";
    my $doc  = XML::LibXML::Document->new($di->{version}, $di->{encoding});

    $self->{XR_node_data} = [];
    my $out  = $self->writer($type)->($doc, $data);
    $doc->setDocumentElement($out) if $out;
    $self->postProcess($doc, $self->{XR_node_data});

    $doc->setCompression($di->{compress});
    $doc->setStandalone($di->{alone}) if defined $di->{alone};
    $doc;
}

sub take_comments_hook($$$)
{   my ($xml, $data, $path) = @_;
    my $previous = $xml;
    while($previous = $previous->previousSibling)
    {   last if $previous->isa('XML::LibXML::Element');
        unshift @{$data->{_COMMENT}}, $previous->textContent
             if $previous->isa('XML::LibXML::Comment');
    }
    $data;
}

sub nodeDataRelation($$$$)
{   my ($self, $doc, $node, $path, $data) = @_;
    push @{$self->{XR_node_data}}, [ $node, $data ];
    $node;
}

sub postProcess($$)
{   my ($self, $doc, $r) = @_;
    my $blanks = $self->{XR_blanks};

    while(@$r)
    {   my ($node, $data) = @{shift @$r};
        my $parent = $node->parentNode;
        next if $parent->isa('XML::LibXML::DocumentFragment'); # unattached

        my $b = $data->{_COMMENT} || [];
        my @b = map {$doc->createComment($_)} ref $b eq 'ARRAY' ? @$b : $b;

        my $grannie = $parent->parentNode;

        my $add_blank
          = @b                          ? 1  # before comments
          : exists $data->{_BLANK_LINE} ? $data->{_BLANK_LINE}
          : $blanks eq 'NONE'           ? 0
          : !($grannie && $grannie->isa('XML::LibXML::Document')) ? 0
          : $node->hasChildNodes        ? 1
          :                               ($blanks eq 'ALL');

        unshift @b, $doc->createTextNode('')
            if $add_blank;

        $parent->insertBefore($_, $node) for @b;

        my $a = $data->{_COMMENT_AFTER} || [];
        my @a = map {$doc->createComment($_)} ref $a eq 'ARRAY' ? @$a : $a;
        $parent->insertAfter($_, $node) for @a;
    }
}

1;
