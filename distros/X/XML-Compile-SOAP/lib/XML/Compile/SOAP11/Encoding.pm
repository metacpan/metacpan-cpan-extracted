# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP11;
use vars '$VERSION';
$VERSION = '3.22';
  #!!!

use Log::Report 'xml-compile-soap';
use List::Util         qw/first/;
use XML::Compile::Util
   qw/odd_elements SCHEMA2001 SCHEMA2001i unpack_type type_of_node/;
use XML::Compile::SOAP::Util qw/:soap11 WSDL11/;

my $simplify;

sub XML::Compile::SOAP11::Encoding::import(@) #!!!
{   my ($class, %args) = @_;
    $simplify = $args{simplify};
}


sub _initRpcEnc11($$)
{   my ($self, $schemas, $xsddir) = @_;

    $schemas->addPrefixes('SOAP-ENC' => SOAP11ENC);
    $schemas->importDefinitions("$xsddir/soap-encoding.xsd");

    $schemas->addCompileOptions( 'READERS'
      , anyElement   => 'TAKE_ALL'
      , anyAttribute => 'TAKE_ALL'
      , permit_href  => 1
      );

    # this will keep the soap11 compile object alive after compilation
    $schemas->addHook
      ( action  => 'READER'
      , extends => 'SOAP-ENC:Array'
      , replace => sub { $self->_dec_array_hook(@_) }
      );

    $schemas->addHook
      ( action  => 'WRITER'
      , extends => 'SOAP-ENC:Array'
      , replace => sub { $self->_enc_array_hook(@_) }
      );

    $self;
}

sub _reader_body_rpcenc_wrapper($$)
{   my ($self, $procedure, $body) = @_;
    my %trans = map +($_->[1] => [ $_->[0], $_->[2] ]), @$body;

    # this should use key_rewrite, but there is no $wsdl here
    # my $label = $wsdl->prefixed($procedure);
    my $label = (unpack_type $procedure)[1];

    my $code  = sub
      { my $opnode = shift or return {};
        my @nodes  = $opnode->childNodes;
        my $parent = $opnode->parentNode;  # href'd sometimes a level up
        push @nodes, grep $_ ne $opnode, $parent->childNodes
            if $parent;

        $self->rpcDecode(@nodes);
      };

    [ [ $label => $procedure => $code ] ];
}

sub _writer_body_rpcenc_hook($$$$$)
{   my ($self, $type, $procedure, $params, $faults) = @_;
    $self->_writer_body_rpclit_hook($type, $procedure, $params, $faults);
}

#------------------


sub startEncoding(%)
{   my ($self, %args) = @_;
    my $doc = $args{doc} || XML::LibXML::Document->new('1.0', 'UTF-8');
    $self->{enc} = {doc => $doc};
    $self;
}

# Currently only support 1-dim arrays

sub _enc_array_hook(@)
{   my ($client, $doc, $val, $path, $tag, $r, $fulltype) = @_;
    my $schema = $client->schemas;
    my $nss    = $schema->namespaces;

    my $elem   = $doc->createElement($tag);
    my $encns  = $schema->prefixFor(SOAP11ENC);
    $elem->setAttribute('xsi:type' => "$encns:Array");

    my ($label, $items) = %$val;
    my @items  = ref $items eq 'ARRAY' ? @$items : $items;

    my $def    = $nss->find(complexType => $fulltype)
        or error __x"cannot find {type} in rpc array writer hook"
          , type => $fulltype;
    my $defnode= $def->{node};
    my $xpc    = XML::LibXML::XPathContext->new;
    $xpc->registerNs(wsdl => WSDL11);
    my ($atattr) = $xpc->findnodes('.//@wsdl:arrayType', $def->{node});

    my $qname  = $atattr->value;
    $qname     =~ s/\[.*//;    # strip array notation

    my ($pref,$local) = $qname =~ /\:/ ? (split /\:/,$qname,2) : ('',$qname);
    my $ns     = $atattr->lookupNamespaceURI($pref);
    my $eltype = pack_type $ns, $local;

    my @nodes;
    if($nss->find(element => $eltype))
    {   my $w  = $schema->writer($eltype);
        @nodes = map $w->($doc, $_), @items;
    }
    else  # type
    {   my $w  = $schema->writer($eltype, is_type => 1, element => $label);
        @nodes = map $w->($doc, $_), @items;
    }

    $elem->appendChild($_) for @nodes;
    $elem->setAttribute("$encns:arrayType" => $qname.'['.@nodes.']');
    $elem;
}


sub prefixed($;$)
{   my $self = shift;
    $self->schemas->prefixed(@_);
}


sub enc($$$)
{   my ($self, $local, $value, $id) = @_;
    my $type = pack_type SOAP11ENC, $local;
    $self->schemas->writer($type, include_namespaces => 0)
         ->($self->{enc}{doc}, {_ => $value, id => $id} );
}


sub typed($$$)
{   my ($self, $type, $name, $value) = @_;

    my $showtype;
    if($type =~ s/^\{\}//)
    {   $showtype = $type;
    }
    else
    {   my ($tns, $tlocal) = unpack_type $type;
        unless(length $tns)
        {   $tns  = SCHEMA2001;
            $type = pack_type $tns, $tlocal;
        }
        $showtype = $self->prefixed($tns, $tlocal);
    }

    my $el = $self->element($type, $name, $value);
    my $typedef = $self->prefixed(SCHEMA2001i, 'type');
    $el->setAttribute($typedef, $showtype);
    $el;
}


sub struct($@)
{   my ($self, $type, @childs) = @_;
    my $typedef = $self->prefixed($type);
    my $doc     = $self->{enc}{doc};
    my $struct  = $doc->createElement($typedef);
    $struct->addChild($_) for @childs;
    $struct;
}


sub element($$$)
{   my ($self, $type, $name, $value) = @_;

    return $value
        if UNIVERSAL::isa($value, 'XML::LibXML::Element');

    $type     = $self->prefixed(SCHEMA2001, $type)
        if $type !~ m/^\{|\:/;

    my $doc   = $self->{enc}{doc};
    my $el    = $doc->createElement($name);
    my $child = $self->schemas->writer($type, include_namespaces => 0)
         ->($doc, $value);
    $el->addChild($child) if $child;
    $el;
}


my $id_count = 0;
sub href($$$)
{   my ($self, $name, $to, $prefid) = @_;
    my $id  = $to->getAttribute('id');
    unless(defined $id)
    {   $id = defined $prefid ? $prefid : 'id-'.++$id_count;
        $to->setAttribute(id => $id);
    }

    my $ename = $self->prefixed($name);
    my $el  = $self->{enc}{doc}->createElement($ename);
    $el->setAttribute(href => "#$id");
    $el;
}


sub nil($;$)
{   my $self = shift;
    my ($type, $name) = @_==2 ? @_ : (undef, $_[0]);
    my ($ns, $local)  = unpack_type $name;

    my $doc  = $self->{enc}{doc};
    my $el   = $ns
      ? $doc->createElementNS($ns, $local)
      : $doc->createElement($local);

    $el->setAttribute($self->prefixed(SCHEMA2001i, 'nil'), 'true');
    $el->setAttribute($self->prefixed(SCHEMA2001i, 'type')
      , $self->prefixed($type)) if $type;

    $el;
}


sub array($$$@)
{   my ($self, $name, $itemtype, $array, %opts) = @_;

    my $enc     = $self->{enc};
    my $doc     = $enc->{doc};

    my $offset  = $opts{offset} || 0;
    my $slice   = $opts{slice};

    my ($min, $size) = ($offset, scalar @$array);
    $min++ while $min <= $size && !defined $array->[$min];

    my $max = defined $slice && $min+$slice-1 < $size ? $min+$slice-1 : $size;
    $max-- while $min <= $max && !defined $array->[$max];

    my $sparse = 0;
    for(my $i = $min; $i < $max; $i++)
    {   next if defined $array->[$i];
        $sparse = 1;
        last;
    }

    my $elname = $self->prefixed(defined $name ? $name : (SOAP11ENC, 'Array'));
    my $el     = $doc->createElement($elname);
    my $nested = $opts{nested_array} || '';
    my $type   = $self->prefixed($itemtype)."$nested\[$size]";

    $el->setAttribute(id => $opts{id}) if defined $opts{id};
    my $at     = $opts{array_type} ? $opts{arrayType} 
               : $self->prefixed(SOAP11ENC, 'arrayType');
    $el->setAttribute($at, $type) if defined $at;

    if($sparse)
    {   my $placeition = $self->prefixed(SOAP11ENC, 'position');
        for(my $r = $min; $r <= $max; $r++)
        {   my $row  = $array->[$r] or next;
            my $node = $row->cloneNode(1);
            $node->setAttribute($placeition, "[$r]");
            $el->addChild($node);
        }
    }
    else
    {   $el->setAttribute($self->prefixed(SOAP11ENC, 'offset'), "[$min]")
            if $min > 0;
        $el->addChild($array->[$_]) for $min..$max;
    }

    $el;
}


sub multidim($$$@)
{   my ($self, $name, $itemtype, $array, %opts) = @_;
    my $enc     = $self->{enc};
    my $doc     = $enc->{doc};

    # determine dimensions
    my @dims;
    for(my $dim = $array; ref $dim eq 'ARRAY'; $dim = $dim->[0])
    {   push @dims, scalar @$dim;
    }

    my $sparse = $self->_check_multidim($array, \@dims, '');
    my $elname = $self->prefixed(defined $name ? $name : (SOAP11ENC, 'Array'));
    my $el     = $doc->createElement($elname);
    my $type   = $self->prefixed($itemtype) . '['.join(',', @dims).']';

    $el->setAttribute(id => $opts{id}) if defined $opts{id};
    $el->setAttribute($self->prefixed(SOAP11ENC, 'arrayType'), $type);

    my @data   = $self->_flatten_multidim($array, \@dims, '');
    if($sparse)
    {   my $placeition = $self->prefixed(SOAP11ENC, 'position');
        while(@data)
        {   my ($place, $field) = (shift @data, shift @data);
            my $node = $field->cloneNode(1);
            $node->setAttribute($placeition, "[$place]");
            $el->addChild($node);
        }
    }
    else
    {   $el->addChild($_) for odd_elements @data;
    }

    $el;
}

sub _check_multidim($$$)
{   my ($self, $array, $dims, $loc) = @_;
    my @dims = @$dims;

    my $expected = shift @dims;
    @$array <= $expected
       or error __x"dimension at ({location}) is {size}, larger than size {expect} of first row"
           , location => $loc, size => scalar(@$array), expect => $expected;

    my $sparse = 0;
    foreach (my $x = 0; $x < $expected; $x++)
    {   my $el   = $array->[$x];
        my $cell = length $loc ? "$loc,$x" : $x;

        if(!defined $el) { $sparse++ }
        elsif(@dims==0)   # bottom level
        {   UNIVERSAL::isa($el, 'XML::LibXML::Element')
               or error __x"array element at ({location}) shall be a XML element or undef, is {value}"
                    , location => $cell, value => $el;
        }
        elsif(ref $el eq 'ARRAY')
        {   $sparse += $self->_check_multidim($el, \@dims, $cell);
        }
        else
        {   error __x"array at ({location}) expects ARRAY reference, is {value}"
               , location => $cell, value => $el;
        }
    }

    $sparse;
}

sub _flatten_multidim($$$)
{   my ($self, $array, $dims, $loc) = @_;
    my @dims = @$dims;

    my $expected = shift @dims;
    my @data;
    foreach (my $x = 0; $x < $expected; $x++)
    {   my $el = $array->[$x];
        defined $el or next;

        my $cell = length $loc ? "$loc,$x" : $x;
        push @data, @dims==0 ? ($cell, $el)  # deepest dim
         : $self->_flatten_multidim($el, \@dims, $cell);
    }

    @data;
}

#--------------------------------------------------

sub rpcDecode(@)
{   my $self  = shift;
    my @nodes = grep $_->isa('XML::LibXML::Element'), @_;
    my $data  = $self->_dec(\@nodes);

#XXX MO: no idea why this is needed:
foreach my $d (@$data)
{   next unless $d->{_NAME};
    $d = { $d->{_NAME} => $d };
}
 
    my ($index, $hrefs) = ({}, []);
    $self->_dec_find_ids_hrefs($index, $hrefs, \$data);
    $self->_dec_resolve_hrefs($index, $hrefs);

    $data = $self->_dec_simplify_tree($data)
        if $simplify;

    ref $data eq 'ARRAY'
        or return $data;

    @$data > 1
        or return $data->[0];

    # find the root element(s)
    my @roots;
    for(my $i = 0; $i < @_ && $i < @$data; $i++)
    {   my $root = $nodes[$i]->getAttributeNS(SOAP11ENC, 'root');
        next if defined $root && $root==0;
        push @roots, $data->[$i];
    }

    my $root_type = @roots ? $roots[0]->{_TYPE} : undef;

    # address parameters by name
    # On the top-level, we can strip on level.  Some elements may appear
    # more than once.
    my %h;
    foreach my $param (@roots ? @roots : @$data)
    {   delete $param->{_TYPE};
        my ($k, $v) = %$param;
           if(!$h{$k})    { $h{$k} = $v }
        elsif(ref $h{$k}) { push @{$h{$k}}, $v }
        else              { $h{$k} = [ $h{$k}, $v ] }
    }

    $h{_TYPE} = $root_type
        if $root_type;

    \%h;
}

sub _dec_reader($$@)
{   my ($self, $node, $type) = splice @_, 0, 3;

    # We must decode the prefix from the $node context
    if(substr($type, 0, 1) ne '{')
    {   my ($prefix, $local) = $type =~ m/^(.*?)\:(.*)/ ? ($1, $2) : ('',$type);
        $type = pack_type $node->lookupNamespaceURI($prefix) // '', $local;
    }

    my $r = try {
       $self->schemas->reader($type
         , element => type_of_node($node), is_type => 1, @_);
    };
    $r || sub { shift };
}

sub _dec($;$$$)
{   my ($self, $nodes, $basetype, $offset, $dims) = @_;
    my $schemas = $self->schemas;
    my $nss     = $schemas->namespaces;

    my @res;
    $#res = $offset-1 if defined $offset;

    foreach my $node (@$nodes)
    {   my $ns    = $node->namespaceURI || '';

        my $label = type_of_node $node;
        my $place;
        if($dims)
        {   my $pos = $node->getAttributeNS(SOAP11ENC, 'position');
            if($pos && $pos =~ m/^\[([\d,]+)\]/ )
            {   my @pos = split /\,/, $1;
                $place  = \$res[shift @pos];
                $place  = \(($$place ||= [])->[shift @pos]) while @pos;
            }
        }

        unless($place)
        {   push @res, undef;
            $place = \$res[-1];
        }

        if(my $href = $node->getAttribute('href') || '')
        {   $$place = { $label => { href => $href } };
            next;
        }

        if($ns ne SOAP11ENC)
        {   my $typedef = $node->getAttributeNS(SCHEMA2001i, 'type');
            if($typedef)
            {   $$place = $self->_dec_typed($node, $typedef);
                next;
            }

            $$place = $self->_dec_other($node, $basetype);
            next;
        }

        my $local = $node->localName;
        if($local eq 'Array')
        {   $$place = $self->_dec_other($node, $basetype);
            next;
        }

        $$place = $self->_dec_soapenc($node, pack_type($ns, $local));
    }

    \@res;
}

sub _dec_typed($$$)
{   my ($self, $node, $type, $index) = @_;

    my $full  = type_of_node $node;
    my $read  = $self->_dec_reader($node, $type);
    my $child = $read->($node);
    my $data  = ref $child eq 'HASH' ? $child : { _ => $child };
    $data->{_TYPE} = $type;
    $data->{_NAME} = type_of_node $node;

    my $id = $node->getAttribute('id');
    $data->{id} = $id if defined $id;

    $data;
}

sub _dec_other($$)
{   my ($self, $node, $basetype) = @_;
    my $local = $node->localName;

    my $data;
    my $type  = $basetype || type_of_node $node;
    my $read  = try { $self->_dec_reader($node, $type) };
    if($@)
    {   # warn $@->wasFatal->message;  #--> element not found
        # Element not known, so we must autodetect the type
        my @childs = grep $_->isa('XML::LibXML::Element'), $node->childNodes;
        if(@childs)
        {   my ($childbase, $dims);
            if($type =~ m/(.+?)\s*\[([\d,]+)\]$/)
            {   $childbase = $1;
                $dims = ($2 =~ tr/,//) + 1;
            }
            my $dec_childs =  $self->_dec(\@childs, $childbase, 0, $dims);

            my $key   = $local;
            $key      = '_' if $key eq 'Array';  # simplifies better
            $data     = { $key => $dec_childs } if $dec_childs;
        }
        else
        {   $data->{_} = $node->textContent;
            $data->{_TYPE} = $basetype if $basetype;
        }
    }
    else
    {   my @x = $read->($node);
        $data = $x[0];
        $data = { _ => $data } if ref $data ne 'HASH';
        $data->{_TYPE} = $basetype if $basetype;
    }

    $data->{_NAME} = type_of_node $node;

    my $id = $node->getAttribute('id');
    $data->{id} = $id if defined $id;

    ($local => $data);
}

sub _dec_soapenc($$)
{   my ($self, $node, $type) = @_;
    my $reader = $self->_dec_reader($node, $type)
       or return $node;
    my $data = $reader->($node);
    $data = { _ => $data } if ref $data ne 'HASH';
    $data->{_TYPE} = $type;
    $data;
}

sub _dec_find_ids_hrefs($$$)
{   my ($self, $index, $hrefs, $node) = @_;
    ref $$node or return;

    if(ref $$node eq 'ARRAY')
    {   foreach my $child (@$$node)
        {   $self->_dec_find_ids_hrefs($index, $hrefs, \$child);
        }
    }
    elsif(ref $$node eq 'HASH')
    {   $index->{$$node->{id}} = $$node
            if defined $$node->{id};

        if(my $href = $$node->{href})
        {   push @$hrefs, $href => $node if $href =~ s/^#//;
        }

        foreach my $k (keys %$$node)
        {   $self->_dec_find_ids_hrefs($index, $hrefs, \( $$node->{$k} ));
        }
    }
    elsif(UNIVERSAL::isa($$node, 'XML::LibXML::Element'))
    {   my $search = XML::LibXML::XPathContext->new($$node);
        $index->{$_->value} = $_->getOwnerElement
            for $search->findnodes('.//@id');

        # we cannot restore deep hrefs, so only top level
        if(my $href = $$node->getAttribute('href'))
        {   push @$hrefs, $href => $node if $href =~ s/^#//;
        }
    }
}

sub _dec_resolve_hrefs($$)
{   my ($self, $index, $hrefs) = @_;

    while(@$hrefs)
    {   my ($to, $where) = (shift @$hrefs, shift @$hrefs);
        my $dest = $index->{$to};
        unless($dest)
        {   warning __x"cannot find id for href {name}", name => $to;
            next;
        }
        $$where = $dest;
    }
}

sub _dec_array_hook($$$$$)
{   my ($self, $node, $args, $where, $local, $r, $fulltype) = @_;

    my $at = $node->getAttributeNS(SOAP11ENC, 'arrayType')
        or return $node;

    $at =~ m/^(.*) \s* \[ ([\d,]+) \] $/x
        or return $node;

    my ($preftype, $dims) = ($1, $2);
    my @dims = split /\,/, $dims;
   
    my $basetype;
    if(index($preftype, ':') >= 0)
    {   my ($prefix, $local) = split /\:/, $preftype, 2;
        $basetype = pack_type $node->lookupNamespaceURI($prefix), $local;
    }
    else
    {   $basetype = pack_type '', $preftype;
    }

    my $table;
    if(@dims==1)
    {   $table = $self->_dec_array_one($node, $basetype, $dims[0]);
    }
    else
    {   my $first = first {$_->isa('XML::LibXML::Element')} $node->childNodes;
        $table    = $first && $first->getAttributeNS(SOAP11ENC, 'position')
          ? $self->_dec_array_multisparse($node, $basetype, \@dims)
          : $self->_dec_array_multi($node, $basetype, \@dims);
    }

    (type_of_node($node) => $table);
}

sub _dec_array_one($$$)
{   my ($self, $node, $basetype, $size) = @_;

    my $off    = $node->getAttributeNS(SOAP11ENC, 'offset') || '[0]';
    $off =~ m/^\[(\d+)\]$/ or return $node;

    my $offset = $1;
    my @childs = grep $_->isa('XML::LibXML::Element'), $node->childNodes;
    my $array  = $self->_dec(\@childs, $basetype, $offset, 1);
    $#$array   = $size -1;   # resize array to specified size
    $array;
}

sub _dec_array_multisparse($$$)
{   my ($self, $node, $basetype, $dims) = @_;

    my @childs = grep $_->isa('XML::LibXML::Element'), $node->childNodes;
    my $array  = $self->_dec(\@childs, $basetype, 0, scalar(@$dims));
    $array;
}

sub _dec_array_multi($$$)
{   my ($self, $node, $basetype, $dims) = @_;

    my @childs = grep $_->isa('XML::LibXML::Element'), $node->childNodes;
    $self->_dec_array_multi_slice(\@childs, $basetype, $dims);
}

sub _dec_array_multi_slice($$$)
{   my ($self, $childs, $basetype, $dims) = @_;
    if(@$dims==1)
    {   my @col = splice @$childs, 0, $dims->[0];
        return $self->_dec(\@col, $basetype);
    }
    my ($rows, @dims) = @$dims;

    [map $self->_dec_array_multi_slice($childs, $basetype, \@dims), 1..$rows];
}

sub _dec_simplify_tree($@)
{   my ($self, $tree, %opts) = @_;
    defined $tree or return ();
    $self->{dec}{_simple_recurse} = {};
    $self->_dec_simple($tree, \%opts);
}

sub _dec_simple($$)
{   my ($self, $tree, $opts) = @_;

    ref $tree
        or return $tree;

    return $tree
        if $self->{dec}{_simple_recurse}{$tree};

    $self->{dec}{_simple_recurse}{$tree}++;

    if(ref $tree eq 'ARRAY')
    {   my @a = map $self->_dec_simple($_, $opts), @$tree;
        return $a[0] if @a==1;

        # array of hash with each one element becomes hash
        my %out;
        foreach my $hash (@a)
        {   ref $hash eq 'HASH' && keys %$hash==1
                or return \@a;

            my ($name, $value) = each %$hash;
            if(!exists $out{$name}) { $out{$name} = $value }
            elsif(ref $out{$name} eq 'ARRAY')
            {   $out{$name} = [ $out{$name} ]   # array of array: keep []
                    if ref $out{$name}[0] ne 'ARRAY' && ref $value eq 'ARRAY';
                push @{$out{$name}}, $value;
            }
            else { $out{$name} = [ $out{$name}, $value ] }
        }
        return \%out;
    }

    ref $tree eq 'HASH'
        or return $tree;

    foreach my $k (keys %$tree)
    {   if($k =~ m/^(?:_NAME$|_TYPE$|id$)/) { delete $tree->{$k} }
        elsif(ref $tree->{$k})
        {   $tree->{$k} = $self->_dec_simple($tree->{$k}, $opts);
        }
    }

    delete $self->{dec}{_simple_recurse}{$tree};

    keys(%$tree)==1 && exists $tree->{_} ? $tree->{_} : $tree;
}

1;
