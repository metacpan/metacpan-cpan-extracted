# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP;
use vars '$VERSION';
$VERSION = '3.21';


use Log::Report          'xml-compile-soap';
use XML::Compile         ();
use XML::Compile::Util   qw(SCHEMA2001 SCHEMA2001i pack_type
   unpack_type type_of_node);
use XML::Compile::Cache  ();
use XML::Compile::SOAP::Util qw/:xop10 SOAP11ENC/;

use Time::HiRes          qw/time/;
use MIME::Base64         qw/decode_base64/;

# XML::Compile::WSA::Util often not installed
use constant WSA10 => 'http://www.w3.org/2005/08/addressing';

sub _xop_enabled() { exists $INC{'XML/Compile/XOP.pm'} }


sub new($@)
{   my $class = shift;

    error __x"you can only instantiate sub-classes of {class}"
        if $class eq __PACKAGE__;

    (bless {}, $class)->init( {@_} );
}

sub init($)
{   my ($self, $args) = @_;
    $self->{XCS_mime}   = $args->{media_type} || 'application/soap+xml';

    my $schemas = $self->{XCS_schemas} = $args->{schemas}
     || XML::Compile::Cache->new(allow_undeclared => 1
          , any_element => 'ATTEMPT', any_attribute => 'ATTEMPT');

    UNIVERSAL::isa($schemas, 'XML::Compile::Cache')
        or panic "schemas must be a Cache object";

    $self;
}

sub _initSOAP($)
{   my ($thing, $schemas) = @_;
    return $thing
        if $schemas->{did_init_SOAP}++;   # ugly

    $schemas->addPrefixes(xsd => SCHEMA2001, xsi => SCHEMA2001i);

    $thing;
}


{   my (%registered, %envelope);
    sub register($)
    { my ($class, $uri, $env, $opclass) = @_;
      $registered{$uri} = $class;
      $envelope{$env}   = $opclass if $env;
    }
    sub plugin($)       { $registered{$_[1]} }
    sub fromEnvelope($) { $envelope{$_[1]} }
    sub registered($)   { values %registered }
}

#--------------------

sub version()   {panic "not implemented"}
sub mediaType() {shift->{XCS_mime}}


sub schemas() {
use Carp 'cluck';
ref $_[0] or cluck;
shift->{XCS_schemas}}

#--------------------

sub compileMessage($@)
{   my ($self, $direction, %args) = @_;
    $args{style} ||= 'document';

      $direction eq 'SENDER'   ? $self->_sender(%args)
    : $direction eq 'RECEIVER' ? $self->_receiver(%args)
    : error __x"message direction is 'SENDER' or 'RECEIVER', not `{dir}'"
         , dir => $direction;
}


sub messageStructure($)
{   my ($thing, $xml) = @_;
    my $env = $xml->isa('XML::LibXML::Document') ? $xml->documentElement :$xml;

    my (@header, @body, $wsa_action);
    if(my ($header) = $env->getChildrenByLocalName('Header'))
    {   @header = map { $_->isa('XML::LibXML::Element') ? type_of_node($_) : ()}
           $header->childNodes;

        if(my $wsa = ($header->getChildrenByTagNameNS(WSA10, 'Action'))[0])
        {   $wsa_action = $wsa->textContent;
            for($wsa_action) { s/^\s+//; s/\s+$//; s/\s{2,}/ /g }
        }
    }

    if(my ($body) = $env->getChildrenByLocalName('Body'))
    {   @body = map { $_->isa('XML::LibXML::Element') ? type_of_node($_) : () }
           $body->childNodes;
    }

    +{ header     => \@header
     , body       => \@body
     , wsa_action => $wsa_action
     };
}

#------------------------------------------------
# Sender

sub _sender(@)
{   my ($self, %args) = @_;

    error __"option 'role' only for readers"  if $args{role};
    error __"option 'roles' only for readers" if $args{roles};

    my $hooks = $args{hooks}   # make copy of calling hook-list
      = $args{hooks} ? [ @{$args{hooks}} ] : [];

    my @mtom;
    push @$hooks, $self->_writer_xop_hook(\@mtom)
		if _xop_enabled;

    my ($body,  $blabels) = $args{create_body}
       ? $args{create_body}->($self, %args)
       : $self->_writer_body(\%args);
    my ($faults, $flabels) = $self->_writer_faults(\%args, $args{faults});

    my ($header, $hlabels) = $self->_writer_header(\%args);
    push @$hooks, $self->_writer_hook($self->envType('Header'), @$header);

    my $style = $args{style} || 'none';
    if($style eq 'document')
    {   push @$hooks, $self->_writer_hook($self->envType('Body')
          , @$body, @$faults);
    }
    elsif($style eq 'rpc')
    {   my $procedure = $args{procedure} || $args{body}{procedure}
            or error __x"sending operation requires procedure name with RPC";

        my $use = $args{use} || $args{body}{use} || 'literal';
        my $bt  = $self->envType('Body');
        push @$hooks, $use eq 'literal'
           ? $self->_writer_body_rpclit_hook($bt, $procedure, $body, $faults)
           : $self->_writer_body_rpcenc_hook($bt, $procedure, $body, $faults);
    }
    else
    {   error __x"unknown style `{style}'", style => $style;
    }

    #
    # Pack everything together in one procedure
    #

    my $envelope = $self->_writer($self->envType('Envelope'), %args);

    sub
    {   my ($values, $charset) = ref $_[0] eq 'HASH' ? @_ : ( {@_}, undef);
        my %copy  = %$values;  # do not destroy the calling hash
        my $doc   = delete $copy{_doc}
          || XML::LibXML::Document->new('1.0', $charset || 'UTF-8');

        my %data;
        $data{$_}  = delete $copy{$_} for qw/Header Body/;
        $data{Body} ||= {};

        foreach my $label (@$hlabels)
        {   exists $copy{$label} or next;
            $data{Header}{$label} ||= delete $copy{$label};
        }

        foreach my $label (@$blabels, @$flabels)
        {   exists $copy{$label} or next;
            $data{Body}{$label} ||= delete $copy{$label};
        }

        if(@$blabels==2 && !keys %{$data{Body}} ) # ignore 'Fault'
        {  # even when no params, we fill at least one body element
            $data{Body}{$blabels->[0]} = \%copy;
        }
        elsif(keys %copy)
        {   trace __x"available blocks: {blocks}",
                 blocks => [ sort @$hlabels, @$blabels, @$flabels ];
            error __x"call data not used: {blocks}", blocks => [keys %copy];
        }

        @mtom = ();   # filled via hook

#use Data::Dumper;
#warn Dumper \%data;
        my $root = $envelope->($doc, \%data)
            or return;

        $doc->setDocumentElement($root);

        return ($doc, \@mtom)
            if wantarray;

        @mtom == 0
            or error __x"{nr} XOP objects lost in sender"
                 , nr => scalar @mtom;
        $doc;
    };
}

sub _writer_hook($$@)
{   my ($self, $type, @do) = @_;

    my $code = sub
     {  my ($doc, $data, $path, $tag) = @_;
        UNIVERSAL::isa($data, 'XML::LibXML::Element')
            and return $data;

        my %data = %$data;
        my @h = @do;
        my @childs;
        while(@h)
        {   my ($k, $c) = (shift @h, shift @h);
            if(my $v = delete $data{$k})
            {   push @childs, $c->($doc, $v);
            }
        }

        warning __x"unused values {names}", names => [keys %data]
            if keys %data;

        my $node = $doc->createElement($tag);
        $node->appendChild($_) for @childs;
        $node;
      };

   +{ type => $type, replace => $code };
}

sub _writer_body_rpclit_hook($$$$$)
{   my ($self, $type, $procedure, $params, $faults) = @_;
    my @params   = @$params;
    my @faults   = @$faults;
    my $schemas  = $self->schemas;

    my $proc     = $schemas->prefixed($procedure);
    my ($prefix) = split /\:/, $proc;
    my $prefdef  = $schemas->prefix($prefix);
    my $proc_ns  = $prefdef->{uri};
    $prefdef->{used} = 0;

    my $code   = sub
     {  my ($doc, $data, $path, $tag) = @_;
        UNIVERSAL::isa($data, 'XML::LibXML::Element')
            and return $data;

        my %data = %$data;
        my @f = @faults;
        my (@fchilds, @pchilds);
        while(@f)
        {   my ($k, $c) = (shift @f, shift @f);
            my $v = delete $data{$k};
            push @fchilds, $c->($doc, $v) if defined $v;
        }
        my @p = @params;
        while(@p)
        {   my ($k, $c) = (shift @p, shift @p);
            my $v = delete $data{$k};
            push @pchilds, $c->($doc, $v) if defined $v;
        }
        warning __x"unused values {names}", names => [keys %data]
            if keys %data;

        my $proc = $doc->createElement($proc);
        $proc->setNamespace($proc_ns, $prefix, 0);
        $proc->setAttribute("SOAP-ENV:encodingStyle", SOAP11ENC);

        $proc->appendChild($_) for @pchilds;

        my $node = $doc->createElement($tag);
        $node->appendChild($proc);
        $node->appendChild($_) for @fchilds;
        $node;
     };

   +{ type => $type, replace => $code };
}

sub _writer_header($)
{   my ($self, $args) = @_;
    my (@rules, @hlabels);

    my $header  = $args->{header} || [];
    my $soapenv = $self->envelopeNS;

    foreach my $h (ref $header eq 'ARRAY' ? @$header : $header)
    {   my $part    = $h->{parts}[0];
        my $label   = $part->{name};
        my $element = $part->{element};
        my $code    = $part->{writer}
         || $self->_writer($element, %$args
              , include_namespaces => sub {$_[0] ne $soapenv && $_[2]});

        push @rules, $label => $code;
        push @hlabels, $label;
    }

    (\@rules, \@hlabels);
}

sub _writer_body($)
{   my ($self, $args) = @_;
    my (@rules, @blabels);

    my $body  = $args->{body} || $args->{fault};
    my $use   = $body->{use}  || 'literal';
#   $use eq 'literal'
#       or error __x"RPC encoded not supported by this version";

    my $parts = $body->{parts} || [];
    my $style = $args->{style};
    local $args->{is_rpc_enc} = $style eq 'rpc' && $use eq 'encoded';

    foreach my $part (@$parts)
    {   my $label  = $part->{name};
        my $code;
        if($part->{element})
        {   $code  = $self->_writer_body_element($args, $part);
        }
        elsif(my $type = $part->{type})
        {   $code  = $self->_writer_body_type($args, $part);
            $label = (unpack_type $part->{name})[1];
        }
        else
        {   error __x"part {name} has neither `element' nor `type' specified"
              , name => $label;
        }

        push @rules, $label => $code;
        push @blabels, $label;
    }

    (\@rules, \@blabels);
}

sub _writer_body_element($$)
{   my ($self, $args, $part) = @_;
    my $element = $part->{element};
    my $soapenv = $self->envelopeNS;

    $part->{writer} ||= $self->_writer
      ( $element, %$args
      , include_namespaces  => sub {$_[0] ne $soapenv && $_[2]}
      , xsi_type_everywhere => $args->{is_rpc_enc}
      );
}

sub _writer_body_type($$)
{   my ($self, $args, $part) = @_;

    $args->{style} eq 'rpc'
        or error __x"part {name} uses `type', only for rpc not {style}"
             , name => $part->{name}, style => $args->{style};

    return $part->{writer}
        if $part->{writer};

    my $soapenv = $self->envelopeNS;

    $part->{writer} = $self->schemas->compileType
      ( WRITER  => $part->{type}, %$args, element => $part->{name}
      , include_namespaces => sub {$_[0] ne $soapenv && $_[2]}
      , xsi_type_everywhere => $args->{is_rpc_enc}
      );
}

sub _writer_faults($) { ([], []) }

sub _writer_xop_hook($)
{   my ($self, $xop_objects) = @_;

    my $collect_objects = sub {
        my ($doc, $val, $path, $tag, $r) = @_;
        return $r->($doc, $val)
            unless UNIVERSAL::isa($val, 'XML::Compile::XOP::Include');

        my $node = $val->xmlNode($doc, $path, $tag); 
        push @$xop_objects, $val;
        $node;
      };

   +{ extends => 'xsd:base64Binary', replace => $collect_objects };
}

#------------------------------------------------
# Receiver

sub _receiver(@)
{   my ($self, %args) = @_;

    error __"option 'destination' only for writers"
        if $args{destination};

    error __"option 'mustUnderstand' only for writers"
        if $args{understand};

# roles are not checked (yet)
#   my $roles  = $args{roles} || $args{role} || 'ULTIMATE';
#   my @roles  = ref $roles eq 'ARRAY' ? @$roles : $roles;

    my $header = $self->_reader_header(\%args);

    my $xops;  # forward backwards pass-on
    my $body   = $self->_reader_body(\%args, \$xops);

    my $style  = $args{style} || 'document';
    my $kind   = $args{kind}  || 'request-response';
    if($style eq 'rpc')
    {   my $procedure = $args{procedure} || $args{body}{procedure};
        keys %{$args{body}}==0 || $procedure
            or error __x"receiving operation requires procedure name with RPC";

        my $use = $args{use} || $args{body}{use} || 'literal';
#warn "RPC READER BODY $use";
        $body = $use eq 'literal'
           ? $self->_reader_body_rpclit_wrapper($procedure, $body)
           : $self->_reader_body_rpcenc_wrapper($procedure, $body);
    }
    elsif($style ne 'document')
    {   error __x"unknown style `{style}'", style => $style;
    }

    # faults are always possible
    push @$body, $self->_reader_fault_reader;

    my @hooks  = @{$self->{hooks} || []};
    push @hooks
      , $self->_reader_hook($self->envType('Header'), $header)
      , $self->_reader_hook($self->envType('Body'),   $body  );

    #
    # Pack everything together in one procedure
    #

    my $envelope = $self->_reader($self->envType('Envelope')
      , %args, hooks => \@hooks);

    # add simplified fault information
    my $faultdec = $self->_reader_faults(\%args, $args{faults});

    sub
    {   (my $xml, $xops) = @_;
        my $data  = $envelope->($xml);
        my @pairs = ( %{delete $data->{Header} || {}}
                    , %{delete $data->{Body}   || {}});
        while(@pairs)
        {  my $k       = shift @pairs;
           $data->{$k} = shift @pairs;
        }

        $faultdec->($data);
        $data;
    };
}

sub _reader_hook($$)
{   my ($self, $type, $do) = @_;
    my %trans = map +($_->[1] => [ $_->[0], $_->[2] ]), @$do; # we need copies
    my $envns = $self->envelopeNS;

    my $code  = sub
     {  my ($xml, $trans, $path, $label) = @_;
        my %h;
        foreach my $child ($xml->childNodes)
        {   next unless $child->isa('XML::LibXML::Element');
            my $type = type_of_node $child;
            if(my $t = $trans{$type})
            {   my ($label, $code) = @$t;
                my $v = $code->($child) or next;
                   if(!defined $v)        { }
                elsif(!exists $h{$label}) { $h{$label} = $v }
                elsif(ref $h{$label} eq 'ARRAY') { push @{$h{$label}}, $v }
                else { $h{$label} = [ $h{$label}, $v ] }
                next;
            }
            else
            {   $h{$type} = $child;
                trace __x"node {type} not understood, expected are {has}",
                    type => $type, has => [sort keys %trans];
            }

            return ($label => $self->replyMustUnderstandFault($type))
                if $child->getAttributeNS($envns, 'mustUnderstand') || 0;
        }
        ($label => \%h);
     };

   +{ type    => $type
    , replace => $code
    };
 
}

sub _reader_body_rpclit_wrapper($$)
{   my ($self, $procedure, $body) = @_;
    my %trans = map +($_->[1] => [ $_->[0], $_->[2] ]), @$body;

    # this should use key_rewrite, but there is no $wsdl here
    # my $label = $wsdl->prefixed($procedure);
    my $label = (unpack_type $procedure)[1];

    my $code = sub
      { my $xml = shift or return {};
        my %h;
        foreach my $child ($xml->childNodes)
        {   $child->isa('XML::LibXML::Element') or next;
            my $type = type_of_node $child;
            if(my $t = $trans{$type})
                 { $h{$t->[0]} = $t->[1]->($child) }
            else { $h{$type} = $child }
        }
        \%h;
      };

    [ [ $label => $procedure => $code ] ];
}

sub _reader_header($)
{   my ($self, $args) = @_;
    my $header = $args->{header} || [];
    my @rules;

    foreach my $h (@$header)
    {   my $part    = $h->{parts}[0];
        my $label   = $part->{name};
        my $element = $part->{element};
        my $code    = $part->{reader} ||= $self->_reader($element, %$args);
        push @rules, [$label, $element, $code];
    }

    \@rules;
}

sub _reader_body($$)
{   my ($self, $args, $refxops) = @_;
    my $body  = $args->{body};
    my $parts = $body->{parts} || [];
    my @hooks = @{$args->{hooks} || []};
    push @hooks, $self->_reader_xop_hook($refxops)
		if _xop_enabled;

    local $args->{hooks} = \@hooks;

    my @rules;
    foreach my $part (@$parts)
    {   my $label = $part->{name};

        my ($t, $code);
        if($part->{element})
        {   ($t, $code) = $self->_reader_body_element($args, $part) }
        elsif($part->{type})
        {   ($t, $code) = $self->_reader_body_type($args, $part) }
        else
        {   error __x"part {name} has neither element nor type specified"
              , name => $label;
        }
        push @rules, [ $label, $t, $code ];
    }

#use Data::Dumper;
#warn "RULES=", Dumper \@rules, $parts;
    \@rules;
}

sub _reader_body_element($$)
{   my ($self, $args, $part) = @_;

    my $element = $part->{element};
    my $code    = $part->{reader} || $self->_reader($element, %$args);

    ($element, $code);
}

sub _reader_body_type($$)
{   my ($self, $args, $part) = @_;
    my $name = $part->{name};

    $args->{style} eq 'rpc'
        or error __x"only rpc style messages can use 'type' as used by {part}"
              , part => $name;

    return $part->{reader}
        if $part->{reader};

    my $type = $part->{type};
    my ($ns, $local) = unpack_type $type;

    my $r = $part->{reader} =
        $self->schemas->compileType
          ( READER => $type, %$args
          , element => $name # $args->{body}{procedure}
          );

    ($name, $r);
}

sub _reader_faults($)
{   my ($self, $args) = @_;
    sub { shift };
}

sub _reader_xop_hook($)
{   my ($self, $refxops) = @_;

    my $xop_merge = sub
      { my ($xml, $args, $path, $type, $r) = @_;
        if(my $incls = $xml->getElementsByTagNameNS(XOP10, 'Include'))
        {   my $href = $incls->shift->getAttribute('href') || ''
                or return ($type => $xml);

            $href =~ s/^cid://;
            my $xop  = $$refxops->{$href}
                or return ($type => $xml);

            return ($type => $xop);
        }

        ($type => decode_base64 $xml->textContent);
      };

   +{ type => 'xsd:base64Binary', replace => $xop_merge };
}

sub _reader(@) { shift->schemas->reader(@_) }
sub _writer(@) { shift->schemas->writer(@_) }

#------------------------------------------------


sub roleURI($) { panic "not implemented" }


sub roleAbbreviation($) { panic "not implemented" }


sub replyMustUnderstandFault($) { panic "not implemented" }

#----------------------


1;
