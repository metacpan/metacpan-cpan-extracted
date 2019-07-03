# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Schema;
use vars '$VERSION';
$VERSION = '1.63';

use base 'XML::Compile';

use warnings;
use strict;

use Log::Report    'xml-compile';

use List::Util     qw/first/;
use XML::LibXML    ();
use File::Spec     ();
use File::Basename qw/basename/;
use Digest::MD5    qw/md5_hex/;

use XML::Compile::Schema::Specs;
use XML::Compile::Schema::Instance;
use XML::Compile::Schema::NameSpaces;
use XML::Compile::Util       qw/SCHEMA2001 SCHEMA2001i unpack_type/;

use XML::Compile::Translate  ();


sub init($)
{   my ($self, $args) = @_;
    $self->{namespaces} = XML::Compile::Schema::NameSpaces->new;
    $self->SUPER::init($args);

    $self->importDefinitions($args->{top}, %$args)
        if $args->{top};

    $self->{hooks} = [];
    if(my $h1 = $args->{hook})
    {   $self->addHook(ref $h1 eq 'ARRAY' ? @$h1 : $h1);
    }
    if(my $h2 = $args->{hooks})
    {   $self->addHook($_) for ref $h2 eq 'ARRAY' ? @$h2 : $h2;
    }
 
    $self->{key_rewrite} = [];
    if(my $kr = $args->{key_rewrite})
    {   $self->addKeyRewrite(ref $kr eq 'ARRAY' ? @$kr : $kr);
    }

    $self->{block_nss}   = [];
    $self->blockNamespace($args->{block_namespace});

    $self->{typemap}     = $args->{typemap} || {};
    $self->{unused_tags} = $args->{ignore_unused_tags};

    $self;
}

#--------------------------------------


sub addHook(@)
{   my $self = shift;
    push @{$self->{hooks}}, @_>1 ? {@_} : defined $_[0] ? shift : ();
    $self;
}


sub addHooks(@)
{   my $self = shift;
    $self->addHook($_) for @_;
    $self;
}


sub hooks(;$)
{   my $hooks = shift->{hooks};
    my $dir   = shift or return @$hooks;
    grep +(!$_->{action} || $_->{action} eq $dir), @$hooks;
}


sub addTypemaps(@)
{   my $map = shift->{typemap};
    while(@_ > 1)
    {   my $k = shift;
        $map->{$k} = shift;
    }
    $map;
}
*addTypemap = \&addTypemaps;


sub addSchemas($@)
{   my ($self, $node, %opts) = @_;
    defined $node or return ();

    my @nsopts;
    foreach my $o (qw/source filename target_namespace
        element_form_default attribute_form_default/)
    {   push @nsopts, $o => delete $opts{$o} if exists $opts{$o};
    }

    UNIVERSAL::isa($node, __PACKAGE__)
        and error __x"use useSchema(), not addSchemas() for a {got} object"
             , got => ref $node;

    UNIVERSAL::isa($node, 'XML::LibXML::Node')
        or error __x"addSchema() requires an XML::LibXML::Node";

    $node = $node->documentElement
        if $node->isa('XML::LibXML::Document');

    my $nss = $self->namespaces;
    my @schemas;

    $self->walkTree
    ( $node,
      sub { my $this = shift;
            return 1 unless $this->isa('XML::LibXML::Element')
                         && $this->localName eq 'schema';

            my $schema = XML::Compile::Schema::Instance->new($this, @nsopts)
                or next;

            $nss->add($schema);
            push @schemas, $schema;
            return 0;
          }
    );
    @schemas;
}


sub useSchema(@)
{   my $self = shift;
    foreach my $schema (@_)
    {   error __x"useSchema() accepts only {pkg} extensions, not {got}"
          , pkg => __PACKAGE__, got => (ref $schema || $schema);
        $self->namespaces->use($schema);
    }
    $self;
}


sub addKeyRewrite(@)
{   my $self = shift;
    unshift @{$self->{key_rewrite}}, @_;
    defined wantarray ? $self->_key_rewrite(undef) : ();
}

sub _key_rewrite($)
{   my $self = shift;
    my @more = map { ref $_ eq 'ARRAY' ? @$_ : defined $_ ? $_ : () } @_;

    my ($pref_all, %pref, @other);
    foreach my $rule (@more, @{$self->{key_rewrite}})
    {   if($rule eq 'PREFIXED') { $pref_all++ }
        elsif($rule =~ m/^PREFIXED\((.*)\)/) { $pref{$_}++ for split /\,/, $1 }
        else { push @other, $rule }
    }

    ( ( $pref_all  ? 'PREFIXED'
      : keys %pref ? 'PREFIXED('.join(',', sort keys %pref).')'
      : ()), @other );
}


sub blockNamespace(@)
{   my $self = shift;
    push @{$self->{block_nss}}, @_;
}

sub _block_nss(@)
{   my $self = shift;
    grep defined, map {ref $_ eq 'ARRAY' ? @$_ : $_}
        @_, @{$self->{block_nss}};
}

#--------------------------------------


sub compile($$@)
{   my ($self, $action, $type, %args) = @_;
    defined $type or return ();

    if(exists $args{validation})
    {   $args{check_values}  =   $args{validation};
        $args{check_occurs}  =   $args{validation};
        $args{ignore_facets} = ! $args{validation};
    }
    else
    {   exists $args{check_values} or $args{check_values} = 1;
        exists $args{check_occurs} or $args{check_occurs} = 1;
    }

    my $iut = exists $args{ignore_unused_tags}
      ? $args{ignore_unused_tags} : $self->{unused_tags};

    $args{ignore_unused_tags}
      = !defined $iut ? undef : ref $iut eq 'Regexp' ? $iut : qr/^/;

    exists $args{include_namespaces}
        or $args{include_namespaces} = 1;

    if($args{sloppy_integers} ||= 0)
    {   eval "require Math::BigInt";
        panic "require Math::BigInt or sloppy_integers:\n$@"
            if $@;
    }

    if($args{sloppy_floats} ||= 0)
    {   eval "require Math::BigFloat";
        panic "require Math::BigFloat by sloppy_floats:\n$@" if $@;
    }

    if($args{json_friendly} ||= 0)
    {   eval "require Types::Serialiser";
        panic "require Types::Serialiser by json_friendly:\n$@" if $@;
    }

    $args{prefixes} = $self->_namespaceTable
      (($args{prefixes} || $args{output_namespaces})
      , $args{namespace_reset}
      , !($args{use_default_namespace} || $args{use_default_prefix})
        # use_default_prefix renamed in 0.90
      );

    my $nss   = $self->namespaces;

    my ($h1, $h2) = (delete $args{hook}, delete $args{hooks});
    my @hooks = $self->hooks($action);
    push @hooks, ref $h1 eq 'ARRAY' ? @$h1 : $h1 if $h1;
    push @hooks, ref $h2 eq 'ARRAY' ? @$h2 : $h2 if $h2;

    my %map = ( %{$self->{typemap}}, %{$args{typemap} || {}} );
    trace "schema compile $action for $type";

    my @rewrite = $self->_key_rewrite(delete $args{key_rewrite});
    my @blocked = $self->_block_nss(delete $args{block_namespace});

    $args{abstract_types} ||= 'ERROR';
    $args{mixed_elements} ||= 'ATTRIBUTES';
    $args{default_values} ||= $action eq 'READER' ? 'EXTEND' : 'IGNORE';

    # Option rename in 0.88
    $args{any_element}    ||= delete $args{anyElement};
    $args{any_attribute}  ||= delete $args{anyAttribute};

    if(my $xi = $args{xsi_type})
    {   my $nss = $self->namespaces;
        foreach (keys %$xi)
        {   $xi->{$_} = $nss->autoexpand_xsi_type($_) if $xi->{$_} eq 'AUTO';
        }
    }

    my $transl = XML::Compile::Translate->new
     ( $action
     , nss     => $self->namespaces
     );

    $transl->compile
     ( $type, %args
     , hooks    => \@hooks
     , typemap  => \%map
     , rewrite  => \@rewrite
     , block_namespace => \@blocked
     );
}

# also used in ::Cache init()
sub _namespaceTable($;$$)
{   my ($self, $table, $reset_count, $block_default) = @_;
    $table = { reverse @$table }
        if ref $table eq 'ARRAY';

    $table->{$_}    = { uri => $_, prefix => $table->{$_} }
        for grep ref $table->{$_} ne 'HASH', keys %$table;

    if($reset_count)
    {   $_->{used} = 0 for values %$table;
    }

    $table->{''}    = {uri => '', prefix => '', used => 0}
        if $block_default && !grep $_->{prefix} eq '', values %$table;

    # very strong preference for 'xsi'
    $table->{&SCHEMA2001i} = {uri => SCHEMA2001i, prefix => 'xsi', used => 0};

    $table;
}


sub compileType($$@)
{   my ($self, $action, $type, %args) = @_;

    # translator can only create elements, not types.
    my $elem           = delete $args{element} || $type;
    my ($ens, $elocal) = unpack_type $elem;
    my ($ns, $local)   = unpack_type $type;

    my $SchemaNS = SCHEMA2001;

    my $defs     = $ns ? <<_DIRTY_TRICK1 : <<_DIRTY_TRICK2;
<schema xmlns="$SchemaNS"
   targetNamespace="$ens"
   xmlns:tns="$ns">
  <element name="$elocal" type="tns:$local" />
</schema>
_DIRTY_TRICK1
<schema xmlns="$SchemaNS"
   targetNamespace="$ens"
   elementFormDefault="unqualified"
   >
  <element name="$elocal" type="$local" />
</schema>
_DIRTY_TRICK2

    $self->importDefinitions($defs);
    $self->compile($action, $elem, %args);
}


sub template($@)
{   my ($self, $action, $type, %args) = @_;

    my ($to_perl, $to_xml)
      = $action eq 'PERL' ? (1, 0)
      : $action eq 'XML'  ? (0, 1)
      : $action eq 'TREE' ? (0, 0)
      : error __x"template output is either in XML or PERL layout, not '{action}'"
        , action => $action;

    my $show
      = exists $args{show_comments} ? $args{show_comments}
      : exists $args{show} ? $args{show} # pre-0.79 option name 
      : 'ALL';

    $show    = 'struct,type,occur,facets' if $show eq 'ALL';
    $show    = '' if $show eq 'NONE';
    my %show = map {("show_$_" => 1)} split m/\,/, $show;
    my $nss  = $self->namespaces;

    my $indent                  = $args{indent} || "  ";
    $args{check_occurs}         = 1;
    $args{mixed_elements}     ||= 'ATTRIBUTES';
    $args{default_values}     ||= 'EXTEND';
    $args{abstract_types}     ||= 'ERROR';

    exists $args{include_namespaces}
        or $args{include_namespaces} = 1;

    # it could be used to add extra comment lines
    error __x"typemaps not implemented for XML template examples"
        if $to_xml && defined $args{typemap} && keys %{$args{typemap}};

    my @rewrite = $self->_key_rewrite(delete $args{key_rewrite});
    my @blocked = $self->_block_nss(delete $args{block_namespace});

    my $table   = $args{prefixes} = $self->_namespaceTable
      (($args{prefixes} || $args{output_namespaces})
      , $args{namespace_reset}
      , !$args{use_default_namespace}
      );

    my $used = $to_xml && $show{show_type};
    $table->{&SCHEMA2001}
       ||= +{prefix => 'xs',  uri => SCHEMA2001,  used => $used};
    $table->{&SCHEMA2001i}
       ||= +{prefix => 'xsi', uri => SCHEMA2001i, used => $used};

    my $transl  = XML::Compile::Translate->new
     ( 'TEMPLATE'
     , nss         => $self->namespaces
     );

    my $compiled = $transl->compile
     ( $type
     , %args
     , rewrite         => \@rewrite
     , block_namespace => \@blocked   # not yet supported
     , output          => $action
     );
    $compiled or return;

    my $ast = $compiled->();
#use Data::Dumper; $Data::Dumper::Indent = 1; warn Dumper $ast;

    if($to_perl)
    {   return $transl->toPerl($ast, %show, indent => $indent
          , skip_header => $args{skip_header})
    }

    if($to_xml)
    {   my $doc  = XML::LibXML::Document->new('1.1', 'UTF-8');
        my $node = $transl->toXML($doc, $ast, %show
          , indent => $indent, skip_header => $args{skip_header});
        return $node->toString(1);
    }

    # return tree
    $ast;
}

#------------------------------------------


sub namespaces() { shift->{namespaces} }


# The cache will certainly avoid penalties by the average module user,
# which does not understand the sharing schema definitions between objects
# especially in SOAP implementations.
my (%schemaByFilestamp, %schemaByChecksum);

sub importDefinitions($@)
{   my ($self, $frags, %options) = @_;
    my @data = ref $frags eq 'ARRAY' ? @$frags : $frags;

    # this is a horrible hack, but by far the simpelest solution to
    # avoid dataToXML process the same info twice.
    local $self->{_use_cache} = 1;

    my @schemas;
    foreach my $data (@data)
    {   defined $data or next;
        my ($xml, %details) = $self->dataToXML($data);
        %details = %{delete $options{details}} if $options{details};

        if(defined $xml)
        {   my @added = $self->addSchemas($xml, %details, %options);
            if(my $checksum = $details{checksum})
            {   $self->{_cache_checksum}{$checksum} = \@added;
            }
            elsif(my $filestamp = $details{filestamp})
            {   $self->{_cache_file}{$filestamp} = \@added;
            }
            push @schemas, @added;
        }
        elsif(my $filestamp = $details{filestamp})
        {   my $cached = $self->{_cache_file}{$filestamp};
            $self->namespaces->add(@$cached);
        }
        elsif(my $checksum = $details{checksum})
        {   my $cached = $self->{_cache_checksum}{$checksum};
            $self->namespaces->add(@$cached);
        }
    }
    @schemas;
}

sub _parseScalar($)
{   my ($thing, $data) = @_;

    ref $thing && $thing->{_use_cache}
        or return $thing->SUPER::_parseScalar($data);

    my $self = $thing;
    my $checksum = md5_hex $$data;
    if($self->{_cache_checksum}{$checksum})
    {   trace "reusing string data with checksum $checksum";
        return (undef, checksum => $checksum);
    }

    trace "cache parsed scalar with checksum $checksum";

    ( $self->SUPER::_parseScalar($data)
    , checksum => $checksum
    );
}

sub _parseFile($)
{   my ($thing, $fn) = @_;

    ref $thing && $thing->{_use_cache}
        or return $thing->SUPER::_parseFile($fn);
    my $self = $thing;

    my ($mtime, $size) = (stat $fn)[9,7];
    my $filestamp = File::Spec->rel2abs($fn) . '-'. $mtime . '-' . $size;

    if($self->{_cache_file}{$filestamp})
    {   trace "reusing schemas from file $filestamp";
        return (undef, filestamp => $filestamp);
    }

    trace "cache parsed file $filestamp";

    ( $self->SUPER::_parseFile($fn)
    , filestamp => $filestamp
    );
}


sub types()
{   my $nss = shift->namespaces;
    sort map {$_->types}
         map {$nss->schemas($_)}
             $nss->list;
}


sub elements()
{   my $nss = shift->namespaces;
    sort map {$_->elements}
         map {$nss->schemas($_)}
             $nss->list;
}


sub printIndex(@)
{   my $self = shift;
    $self->namespaces->printIndex(@_);
}


sub doesExtend($$)
{   my $self = shift;
    $self->namespaces->doesExtend(@_);
}


1;
