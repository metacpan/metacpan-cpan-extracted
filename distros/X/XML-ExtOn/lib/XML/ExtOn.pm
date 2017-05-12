package XML::ExtOn;

#$Id: ExtOn.pm 966 2011-08-07 18:07:19Z zag $

=pod

=head1 NAME

XML::ExtOn - The handler for expansion of Perl SAX by objects.

=head1 SYNOPSYS

    use XML::ExtOn;

For write XML:

    use XML::ExtOn;
    my $buf;
    my $wrt = XML::ExtOn::Writer->new( Output => \$buf );
    my $ex_parser = new XML::ExtOn:: Handler => $wrt;
    $ex_parser->start_document;
    my $root = $ex_parser->mk_element("Root");
    $root->add_namespace(
        "myns" => 'http://example.com/myns',
        "myns_test", 'http://example.com/myns_test'
    );
    $ex_parser->start_element( $root );
    my $el = $root->mk_element('vars');
    %{ $el->attrs_by_prefix("myns") }      = ( v1 => 1, v2 => 3 );
    %{ $el->attrs_by_prefix("myns_test") } = 
    ( var1 => "test ns", var2 => "2333" );
    $root->add_content($el);
    $ex_parser->end_element;
    $ex_parser->end_document;
    print $buf;

Result:

    <?xml version="1.0"?>
    <Root xmlns:myns="http://example.com/myns" 
            xmlns:myns_test="http://example.com/myns_test">
    <vars myns_test:var2="2333" 
        myns_test:var1="test ns" 
        myns:v1="1" myns:v2="3"/>
    </Root>

For handle events

    use base 'XML::ExtOn';

Begin method for handle SAX event start_element:

    sub on_start_element {
        my ( $self, $elem ) = @_;

        ...

Check localname  for element and  add tag C<image>:

        if ( $elem->local_name eq 'gallery' ) {
            $elem->add_content( 
                      $self->mk_element('image')->add_content(
                        $self->mk_characters( "Image number: $_" )
                        )
                  ) for 1..2 ;
        }

XML Before:

    <?xml version="1.0"?>
    <Document>
      <gallery/>
    </Document>

After:

    <?xml version="1.0"?>
    <Document>
      <gallery>
        <image>Image number: 1</image>
        <image>Image number: 2</image>
      </gallery>
    </Document>

Register namespace and set variables

        $elem->add_namespace('demons','http://example.org/demo_namespace');
        $elem->add_namespace('ns2','http://example.org/ns2');
        #set attributes for name space
        my $demo_attrs = $elem->attrs_by_prefix('demons');
        %{$demo_attrs} = ( variable1=>1, 'variable2'=>2);
        #set attributes for namespace URI
        my $ns2_attrs = $elem->attrs_by_ns_uri('http://example.org/ns2');
        %{$ns2_attrs} = ( var=> 'ns1', 'raw'=>2);

Result:

        <sub xmlns:demons="http://example.org/demo_namespace" 
        xmlns:ns2="http://example.org/ns2" 
            demons:variable2="2" ns2:var="ns1" 
            demons:variable1="1" ns2:raw="2"/>

Delete content of element

    if ( $elem->local_name eq 'demo_delete') {
            $elem->skip_content
    }

XML before:

    <?xml version="1.0"?>
    <Document>
        <demo_delete>
          <p>text</p>
        </demo_delete>
    </Document>

After:

    <?xml version="1.0"?>
     <Document>
        <demo_delete/>
     </Document>

Add XML:

        $elem->add_content ( 
             $self->mk_from_xml('<custom><p>text</p></custom>')
        )
Can add element after current

        ...
        return [ $elem, $self->mk_element("after") ];
    }

=head1 DESCRIPTION

XML::ExtOn -  SAX Handler designed for funny work with XML. It
provides an easy-to-use interface for XML applications by adding objects.

XML::ExtOn  override some SAX events. Each time an SAX event starts,
a method by that name prefixed with `on_' is called with the B<"blessed"> 
Element object to be processed.

XML::ExtOn implement the following methods:

=over

=item * on_start_document

=item * on_start_prefix_mapping

=item * on_start_element

=item * on_end_element

=item * on_characters

=item * on_cdata

=back

XML::ExtOn  put all B<cdata> characters into a single event C<on_cdata>.

It compliant XML namespaces (http://www.w3.org/TR/REC-xml-names/), by support 
I<default namespace> and I<namespace scoping>.

XML::ExtOn provide methods for create XML, such as C<mk_element>, C<mk_cdata> ...

=head1 FUNCTIONS

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;

use XML::SAX::Base;
use XML::ExtOn::Element;
use XML::ExtOn::Context;
use XML::ExtOn::IncXML;
use XML::Filter::SAX1toSAX2;
use XML::ExtOn::SAX12ExtOn;
use XML::Parser::PerlSAX;
use Test::More;

require Exporter;
*import                = \&Exporter::import;
@XML::ExtOn::EXPORT_OK = qw( create_pipe split_pipe);

sub _get_end_handler {
    my $flt     = shift;
    my $handler = $flt->get_handler();

    return $handler if UNIVERSAL::isa( $handler, 'XML::ExtOn::Writer' );
    return $handler if UNIVERSAL::isa( $handler, 'XML::SAX::Writer::XML' );
    return $flt unless UNIVERSAL::isa( $handler, 'XML::SAX::Base' );
    return &_get_end_handler($handler);
}

=head1 create_pipe "flt_n1",$some_handler, $out_handler

use last arg as handler for out.

return parser ref.

    my $h1     = new MyHandler1::;
    my $filter = create_pipe( 'MyHandler1', $h1 );
    $filter->parse('<root><p>TEST</p></root>');
    #also create pipe of pipes
    my $filter1 = create_pipe( 'MyHandler1', 'MyHandler2' );
    my $h1     = new MyHandler3::;
    my $filter2 = create_pipe(  $filter1, $h1);

=cut

sub create_pipe {

    my @args = reverse @_;

    my $out_handler;
    foreach my $f (@args) {
        unless ( ref($f) ) {
            unless ($out_handler) {
                $out_handler = $f->new();
            }
            else {
                $out_handler = $f->new( Handler => $out_handler );
            }
        }
        elsif ( UNIVERSAL::isa( $f, 'XML::SAX::Base' ) ) {
            unless ($out_handler) {
                $out_handler = $f;
            }
            else {
                my $end_handler = &_get_end_handler($f);
                $end_handler->set_handler($out_handler);
                $out_handler = $f;
            }
        }
        else {
            die "$f not SAX Drv";
        }
    }
    return $out_handler;
}

=head1  split_pipe $filter

return ref to array  of filters in pipe


    use XML::ExtOn qw(split_pipe create_pipe);
    my $filter = create_pipe( 'MyHandler1', 'MyHandler2','MyHandler3');
    my $ref = @{ split_pipe( $filter) } [-1];
    isa_ok $ref,  'MyHandler3', 'check last element';

=cut

sub split_pipe {
    my $filter = shift || return [];
    my @res = ($filter);

    # use SAXed variable see XML::SAX::Base::get_handler()
    if ( my $next = $filter->{Handler} ) {
        #skip special SAX handlers
        unless ( UNIVERSAL::isa( $next, 'XML::SAX::Base::NoHandler' ) ) {
            push @res, @{ split_pipe($next) };
        }
    }
    return \@res;
}

use base 'XML::SAX::Base';
use vars qw( $AUTOLOAD);
$XML::ExtOn::VERSION = '0.17';
### install get/set accessors for this object.
for my $key (
    qw/ context _objects_stack _cdata_mode _cdata_characters _root_stack /)
{
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{___EXT_on_attrs}->{$key} = $_[0] if @_;
        return $self->{___EXT_on_attrs}->{$key};
      }
}

=head1 METHODS

=cut

sub new {
    my $class = shift;
    my $self = &XML::SAX::Base::new( $class, @_, );
    $self->_objects_stack( [] );
    $self->_root_stack( [] );    #init incoming stack of start end
    $self->_cdata_mode(0);
    my $buf;
    $self->_cdata_characters( \$buf );    #setup cdata buffer
    my $doc_context = new XML::ExtOn::Context::;
    $self->context($doc_context);
    return $self;
}

=head2 on_start_document $document

Method handle C<start_document> event. Usually override for initialaize default
variables.

    sub on_start_document {
        my $self = shift;
        $self->{_LINKS_ARRAY} = [];
        $self->SUPER::on_start_document(@_);
    }

=cut

sub on_start_document {
    my ( $self, $document ) = @_;
    $self->SUPER::start_document($document);
}

sub start_document {
    my ( $self, $document ) = @_;
    return if $self->{___EXT_on_attrs}->{_skip_start_docs}++;
    $self->on_start_document($document);
}

sub end_document {
    my $self = shift;
    my $var  = --$self->{___EXT_on_attrs}->{_skip_start_docs};
    return if $var;
    $self->SUPER::end_document(@_);
}

=head2 on_start_prefix_mapping prefix1=>ns_uri1[, prefix2=>ns_uri2]

Called on C<start_prefix_mapping> event.

    sub on_start_prefix_mapping {
        my $self = shift;
        my %map  = @_;
        $self->SUPER::start_prefix_mapping(@_)
    }

=cut

sub on_start_prefix_mapping {
    my $self = shift;
    my %map  = @_;
    while ( my ( $pref, $ns_uri ) = each %map ) {
        $self->add_namespace( $pref, $ns_uri );
        $self->SUPER::start_prefix_mapping(
            {
                Prefix       => $pref,
                NamespaceURI => $ns_uri
            }
        );
    }
}

#
#    { Prefix => 'xlink', NamespaceURI => 'http://www.w3.org/1999/xlink' }
#

sub start_prefix_mapping {
    my $self = shift;

    #declare namespace for current context
    my %map = ();
    foreach my $ref (@_) {
        my ( $prefix, $ns_uri ) = @{$ref}{qw/Prefix NamespaceURI/};
        $map{$prefix} = $ns_uri;
    }
    $self->on_start_prefix_mapping(%map);
}

=head2 on_start_element $elem

Method handle C<on_start_element> event whith XML::ExtOn::Element object.

Method must return C<$elem> or ref to array of objects.

For example:

    sub on_start_element {
        my $self = shift;
        my $elem = shift;
        $elem->add_content( $self->mk_cdata("test"));
        return $elem
    }
    ...
    
    return [ $elem, ,$self->mk_element("after_start_elem") ]
    
    return [ $self->mk_element("before_start_elem"), $elem ]
    ...

=cut

sub on_start_element {
    shift;
    return [@_];
}

sub __expand_on_start {
    my $self = shift;
    my $obj  = shift || return [];
#    warn "before _expand $obj".Dumper($obj) if $obj->local_name eq 'feed';
    my $res  = $self->on_start_element($obj);
#    warn "_expand $obj".Dumper($res , $obj) if $obj->local_name eq 'feed';
    my @stack =
        $res
      ? ref($res) eq 'ARRAY'
          ? @{$res}
          : ($res)
      : ();

    #add self object
    push @stack, $obj;

    #expand wrap_around and insert_to
    # also remove dups for $obj
    my %uniq = ();
    my @res  = ();
    foreach my $o (@stack) {

        # also remove dups for $obj
        next if $uniq{$o}++;
        unless ( UNIVERSAL::isa( $o, 'XML::ExtOn::Element' ) ) {

            #don'n touch any events
            push @res, $o;
        }
        else {

            #convert any object to events (exept $obj)
            unless ( $o eq $obj ) {
                push @res, $self->mk_start_element($o),
                  $self->mk_process_stack($o), $self->mk_end_element($o);
            }
            else {

                #expand $insert_to
                my $insert_to = $o->_wrap_begin || [];
                if ( scalar @{$insert_to} ) {
                    for ( @{$insert_to} ) {
                        push @res, $self->mk_start_element($_);
                    }
                }

                #                $o->_wrap_begin([]);
                #insert result event to write tag
                push @res, $self->_mk_event_start_element($o);

                #process elemet's stack (add_content)
                push @res, $self->mk_process_stack($o);

                #ad  wrap_around started
                my $waround = $o->_wrap_around_start || [];
                if ( scalar @{$waround} ) {
                    for ( @{$waround} ) {
                        push @res, $self->mk_start_element($_);
                    }
                }

                #                $o->_wrap_around_start([]);
            }
        }
    }

    #now expand
    return \@res;
}

sub start_element {
    my $self        = shift;
    my $current_obj = shift;

    die "empty" . Dumper( [ map { [ caller($_) ] } ( 0 .. 4 ) ] )
      unless defined $current_obj;

    unless ( UNIVERSAL::isa( $current_obj, 'XML::ExtOn::Element' ) ) {
        my $context;
        if ( my $current_root_element = $self->current_root_element ) {
            $context = $current_root_element->ns->sub_context();
        }
        $current_obj =
          $self->__mk_element_from_sax2( $current_obj, context => $context );
    }
    else {

        #set new context
        my $new_context;
        if ( my $current_root_element = $self->current_root_element ) {
            $new_context = $current_root_element->ns->sub_context();
        }
        $new_context ||= $self->context->sub_context();
        #save changes (for namespaces)
        my $changes = $current_obj->ns->get_changes();
        while (my ($prefix, $val) = each %$changes) {
            $new_context->declare_prefix($prefix, $val);
        }
        $current_obj->_context($new_context);
    }

    my $current_root_element = $self->current_root_element;

    #push to stack of incoming objects
    push @{ $self->_root_stack() }, $current_obj;

    #=comment check skip
    #check current root element for skip_content
    if ($current_root_element) {
        my $skip_content = $current_root_element->is_skip_content;
        if ($skip_content) {
            $current_root_element->is_skip_content( ++$skip_content );
            return;
        }
    }

    #=cut
    #warn ref($self).":START for " . $current_obj->local_name;
    return $self->__start_element($current_obj);
}

sub __start_element {
    my $self        = shift;
    my $current_obj = shift;

    #check current element for skip_content
    if ( my $current_element = $self->current_element ) {
        my $skip_content = $current_element->is_skip_content;
        if ( $skip_content > 1 ) {
            $current_element->is_skip_content( --$skip_content );
            return;
        }
    }

    #call __start_element
    my $res = $self->__expand_on_start($current_obj);
    $current_obj->{_expanded_on_start} = scalar(@$res);
#    warn ref($self) . "start_exp: " . $current_obj->local_name . ": " . Dumper(
#        [
#            map {
#                ref($_) eq 'HASH'
#                  ? $_->{type} . ":" . $_->{data}->local_name
#                  : $_->local_name
#              } @$res
#        ]
#    );

    #walk via array
    foreach my $elem (@$res) {

        unless ( UNIVERSAL::isa( $elem, 'XML::ExtOn::Element' ) ) {

            #run event
            #warn $elem->{type};
            $self->_process_comm($elem);
        }
        else {

            #register new namespaces
            my $changes    = $current_obj->ns->get_changes;
            my $parent_map = $current_obj->ns->parent->get_map;

            for ( keys %$changes ) {
                $self->end_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $parent_map->{$_},
                    }
                ) if exists $parent_map->{$_};
                $self->start_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $changes->{$_},
                    }
                );
            }

            #save element in stack
            push @{ $self->_objects_stack() }, $current_obj;
            my @object_stack = @{ $current_obj->_stack };
            $current_obj->_stack( [] );

            #skip deleted elements from xml stream
            unless ( $current_obj->is_delete_element ) {

         #                warn "$self: process start ".$current_obj->local_name;
                if ( UNIVERSAL::isa( $self->{Handler}, 'XML::ExtOn' ) ) {
                    my $cloned = $current_obj->__clone;
                    unless ( $self->{__make_self_events} ) {
                        $self->{Handler}->start_element($cloned);
                    }
                    else {
                        $self->{Handler}->__start_element($cloned);

                    }
                }
                else {
                    my $res_data = $self->__exp_element_to_sax2($current_obj);
                    $self->SUPER::start_element($res_data);
                }
            }
            unless ( $current_obj->is_skip_content ) {
                $self->_process_comm($_) for @object_stack;
            }
        }

    }
}

=head2 on_end_element $elem

Method handle C<on_end_element> event whith XML::ExtOn::Element object.
It call before end if element.

Method must return C<$elem> or ref to array of objects.

For example:

    sub on_end_element {
        my $self = shift;
        my $elem = shift;
        if ( $elem->is_delete_element ) {
            warn $elem->local_name . " deleted";
            return [ $elem, $self->mk_element("after_deleted_elem") ]
        };
        return $elem
    }
    ...
    
    return [ $elem, ,$self->mk_element("after_close_tag_of_elem") ]
    
    return [ $self->mk_element("before_close_tag_of_elem"), $elem ]
    ...

=cut

sub on_end_element {
    shift;
    return [@_];
}

sub __expand_on_end {
    my $self = shift;
    my $obj = shift || return [];

    #
    my $res = $self->on_end_element($obj);
    my @stack =
        $res
      ? ref($res) eq 'ARRAY'
          ? @{$res}
          : ($res)
      : ();

    #add self object
    push @stack, $obj;

    #expand wrap_around and insert_to
    # also remove dups for $obj
    my %uniq = ();
    my @res  = ();
    foreach my $o (@stack) {

        # also remove dups for $obj
        next if $uniq{$o}++;
        unless ( UNIVERSAL::isa( $o, 'XML::ExtOn::Element' ) ) {

            #don'n touch any events
            push @res, $o;
        }
        else {

            #convert any object to events (exept $obj)
            unless ( $o eq $obj ) {
                push @res, $self->mk_start_element($o),
                  $self->mk_process_stack($o), $self->mk_end_element($o);
            }
            else {

                #ad  wrap_around started
                my $waround = $o->_wrap_around_end || [];
                if ( scalar @{$waround} ) {
                    for ( reverse @{$waround} ) {
                        push @res, $self->mk_end_element($_);
                    }
                }

                #                push @res, $o;    #add object
                #process elemet's stack (add_content)
                push @res, $self->mk_process_stack($o);

                #expand $insert_to
                push @res, $self->_mk_event_end_element($o);

                my $insert_to = $o->_wrap_end || [];
                if ( scalar @{$insert_to} ) {
                    for ( reverse @{$insert_to} ) {
                        push @res, $self->mk_end_element($_);
                    }
                }
            }
        }
    }

    #now expand
    return \@res;
}

sub end_element {
    my $self = shift;
    my $data = shift;

    #get current element
    #pop from stack of incoming objects
    $data = pop @{ $self->_root_stack() };
    die " $self empty stack" . Dumper( [ map { [ caller($_) ] } ( 0 .. 4 ) ] )
      unless defined $data;

    #    warn "do __end; for "
    #      . $data->local_name
    #      . " {_expanded_on_start}"
    #      . $data->{_expanded_on_start};

    #check current element for skip_content
    if ( my $current_root_element = $self->current_root_element ) {
        my $skip_content = $current_root_element->is_skip_content;
        if ( $skip_content > 1 ) {
            $current_root_element->is_skip_content( --$skip_content );
            return;
        }
    }

    #    warn ref($self).":END for " . $data->local_name;
    #    if ( my $started = $data->{_expanded_on_start} )  {
    #        for ( 1..$started-1 ) {
    #            $self->__end_element($data);
    #        }
    #    }
    return $self->__end_element($data);
}

sub __end_element {
    my $self = shift;

    my $current_obj = shift;    #may be use for control stack
                                #pop element from stack

    #    my $current_obj1 = pop @{ $self->_objects_stack() };

    my $res = $self->__expand_on_end($current_obj);

#   warn ref($self)."end_exp: "
#      . $current_obj->local_name . ": "
#      . Dumper(
#        [
#            map { ref($_) eq 'HASH' ? $_->{type}.":".$_->{data}->local_name : $_->local_name }
#              @$res
#        ]
#      );

    foreach my $elem (@$res) {
        unless ( UNIVERSAL::isa( $elem, 'XML::ExtOn::Element' ) ) {

            #run event
            $self->_process_comm($elem);
        }
        else {
            die "END!!";

            #setup default ns
            my $data = $current_obj->to_sax2;
            delete $data->{Attributes};
            $data->{NamespaceURI} = $current_obj->default_uri;

            # if skip
            #check current element for skip_content
            if ( my $current_element = $self->current_element ) {
                my $skip_content = $current_element->is_skip_content;
                if ( $skip_content > 1 ) {
                    $current_element->is_skip_content( --$skip_content );
                    return;
                }
            }

            unless ( $current_obj->is_skip_content ) {
                $self->_process_comm($_) for @{ $current_obj->_stack };
                $current_obj->_stack( [] );
            }

            unless ( $current_obj->is_delete_element ) {

           #                warn "$self: process end ".$current_obj->local_name;
                unless ( $self->{__make_self_events} ) {
                    $self->SUPER::end_element($data);
                }
                else {
                    $self->{Handler}->__end_element($data);
                }
            }

            my $changes    = $current_obj->ns->get_changes;
            my $parent_map = $current_obj->ns->parent->get_map;
            for ( keys %$changes ) {
                $self->end_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $changes->{$_},
                    }
                );
                if ( exists( $parent_map->{$_} ) ) {
                    $self->start_prefix_mapping(
                        {
                            Prefix       => $_,
                            NamespaceURI => $parent_map->{$_},
                        }
                    );
                }
            }
        }
    }
}

=head2 on_characters( $self->current_element, $data->{Data} )

Must return string for write to stream.

    sub on_characters {
        my ( $self, $elem, $str ) = @_;
        #lowercase all characters
        return lc $str;
    }


=cut

sub on_characters {
    my ( $self, $elem, $str ) = @_;
    return $str;
}

=head2 on_cdata ( $current_element, $data )

Must return string for write to stream

    sub on_cdata {
        my ( $self, $elem, $str ) = @_;
        return lc $str;
    }

=cut

sub on_cdata {
    my ( $self, $elem, $str ) = @_;
    return $str;
}

#set flag for cdata content

sub start_cdata {
    my $self = shift;
    $self->_cdata_mode(1);
    return;
}

#set flag to end cdata

sub end_cdata {
    my $self = shift;
    if ( my $elem = $self->current_element
        and defined( my $cdata_buf = ${ $self->_cdata_characters } ) )
    {

        if ( defined( my $data = $self->on_cdata( $elem, $cdata_buf ) ) ) {
            $self->SUPER::start_cdata;
            $self->SUPER::characters( { Data => $data } );
            $self->SUPER::end_cdata;
        }
    }

    #after all clear cd_data_buffer and reset cd_data mode flag
    my $new_buf;
    $self->_cdata_characters( \$new_buf );
    $self->_cdata_mode(0);
    return;
}

sub characters {
    my $self = shift;
    my ($data) = @_;

    #    warn "$self do chars" . $data->{Data};

    #skip childs elements characters ( > 1 ) and self text ( > 0)
    if ( $self->current_element ) {
        return if $self->current_element->is_skip_content;
    }
    else {

        #skip characters without element
        return;
    }

    #for cdata section collect characters in buffer
    if ( $self->_cdata_mode ) {

#        warn "$self do CDATA" . $data->{Data};
#        warn  " $self CDTATA" . Dumper( [ map { [ caller($_) ] } ( 0 .. 10 ) ] );
#      unless defined $data;

        ${ $self->_cdata_characters } .= $data->{Data};
        return;
    }

    #collect chars fo current element
    if (
        defined(
            my $str =
              $self->on_characters( $self->current_element, $data->{Data} )
        )
       )
    {
        return $self->SUPER::characters( { Data => $str } );
    }
}

=head2 mk_element <tag name>

Return object of element item  for include to stream.

=cut

sub mk_element {
    my $self = shift;
    my $name = shift;
    my %args = @_;
    if ( my $current_element = $self->current_element ) {
        $args{context} = $current_element->ns->sub_context();
    }
    $args{context} ||= $self->context->sub_context();
    my $elem = new XML::ExtOn::Element::
      name => $name,
      %args;
    return $elem;
}

=head2 mk_from_xml <xml string>

Return command  for include to stream.

=cut

sub mk_from_xml {
    my $self   = shift;
    my $string = shift;
    my $skip_tmp_root =
      XML::ExtOn::IncXML->new( Handler => $self, __make_self_events => 1 );
    my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $skip_tmp_root );
    my $parser = XML::Parser::PerlSAX->new(
        {
            Handler => $sax2_filter,
            Source  => { String => "<tmp>$string</tmp>" },
        }
    );
    return $parser;
}

=head2 mk_cdata $string | \$string

return command for insert cdata to stream

=cut

sub mk_cdata {
    my $self   = shift;
    my $string = shift;
    return { type => 'CDATA', data => ref($string) ? $string : \$string };
}

=head2 mk_characters $string | \$string

return command for insert characters to stream

=cut

sub mk_characters {
    my $self   = shift;
    my $string = shift;
    return { type => 'CHARACTERS', data => ref($string) ? $string : \$string };
}

=head2 mk_start_element <element object>

return command for start element event

=cut

sub mk_start_element {
    my $self = shift;
    my $elem = shift;
    return { type => 'START_ELEMENT', data => $elem };
}

=head2 mk_event_element <element object>

return command for expand stack for element

=cut

sub mk_process_stack {
    my $self    = shift;
    my $elem    = shift;
    my @objects = @{ $elem->_stack };
    $elem->_stack( [] );
    return { type => 'STACK', data => $elem, objects => \@objects };
}

=head2 _mk_event_start_element <element object>

return start tag command. (internal)

=cut

sub _mk_event_start_element {
    my $self = shift;
    my $elem = shift;
    return { type => 'EV_START_ELEMENT', data => $elem };
}

=head2 _mk_event_end_element <element object>

return end tag command. (internal)

=cut

sub _mk_event_end_element {
    my $self = shift;
    my $elem = shift;
    return { type => 'EV_END_ELEMENT', data => $elem };
}

=head2 mk_end_element <element object>

return command for end element event

=cut

sub mk_end_element {
    my $self = shift;
    my $elem = shift;
    return { type => 'END_ELEMENT', data => $elem };
}

sub __mk_element_from_sax2 {
    my $self = shift;
    my $data = shift;
    my $elem = $self->mk_element( $data->{LocalName}, sax2 => $data, @_ );
    return $elem;
}

sub __exp_element_to_sax2 {
    my $self = shift;
    my $elem = shift;
    return $elem->to_sax2;
}

=head2 current_element 

Return link to current processing element.

=cut

sub current_element {
    my $self = shift;
    if ( my $stack = $self->_objects_stack() ) {
        return $stack->[-1];
    }
    return;
}

=head2 current_root_element 

Return link to current root element  in incoming stack.
Used in start_element and end_element methods

=cut

sub current_root_element {
    my $self = shift;
    if ( my $stack = $self->_root_stack() ) {
        return $stack->[-1];
    }
    return;
}

# Private method for process commands

sub _process_comm {
    my $self = shift;
    my $comm = shift || return;
    if ( UNIVERSAL::isa( $comm, 'XML::Parser::PerlSAX' ) ) {
        $comm->parse();
    }
    elsif ( UNIVERSAL::isa( $comm, 'XML::Parser' ) ) {
        warn "parser!";
        $comm->parse();
    }
    elsif ( UNIVERSAL::isa( $comm, 'XML::ExtOn::Element' ) ) {

        #        warn ref($self)."start ELEMENT " . $comm->local_name;
        $self->__start_element($comm);

        #        while ( my $obj = shift @{ $comm->_stack } ) {
        #            $self->_process_comm($obj);
        #        }
        $self->__end_element($comm);

        #        warn ref($self)."end ELEMENT " . $comm->local_name;
        ;    # unless shift; #if exists extra param not end elem
    }
    elsif ( ref($comm) eq 'HASH' and exists $comm->{type} ) {
        if ( $comm->{type} eq 'CDATA' ) {

            #warn "$self : DO CDATA!!!";
            $self->start_cdata;
            $self->characters( { Data => ${ $comm->{data} } } );
            $self->end_cdata;
        }
        elsif ( $comm->{type} eq 'CHARACTERS' ) {
            unless ( ref( $comm->{data} ) eq 'SCALAR' ) {
                warn "NOT REF" . Dumper $comm;
                warn "empty" . Dumper( [ map { [ caller($_) ] } ( 0 .. 16 ) ] );
                exit;

            }
            $self->characters( { Data => ${ $comm->{data} } } );
        }
        elsif ( $comm->{type} eq 'START_ELEMENT' ) {
            my $current_obj = $comm->{data};
            $self->__start_element( $comm->{data} );
        }
        elsif ( $comm->{type} eq 'END_ELEMENT' ) {
            my $current_obj = $comm->{data};
            $self->__end_element( $comm->{data} );
        }
        elsif ( $comm->{type} eq 'STACK' ) {
            my $stack = $comm->{objects};
            my $comm  = $comm->{data};

   #            warn "$self: ",
   #              $comm->local_name . " stack: " . scalar( @{$stack} ) . Dumper(
   #                [
   #                    map {
   #                        ref($_) eq 'HASH'
   #                          ? $_->{type} . ":" . '$_->{data}->local_name'
   #                          : $_->local_name
   #                      } @$stack
   #                ]
   #              );
   #            warn ref($self)."START PROCESS STACK ".$comm->local_name;
            while ( my $obj = shift @{$stack} ) {

                #                warn "$self start STACK: ".$obj;
                $self->_process_comm($obj);

                #                warn "$self end STACK: ".$obj;
            }

            #            warn ref($self)."END PROCESS STACK ".$comm->local_name;

        }
        elsif ( $comm->{type} eq 'EV_START_ELEMENT' ) {
            my $current_obj = $comm->{data};

            #            warn "$self: ev_START".$current_obj->local_name;
            #register new namespaces
            my $changes    = $current_obj->ns->get_changes;
            my $parent_map = $current_obj->ns->parent->get_map;

            for ( keys %$changes ) {
                $self->end_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $parent_map->{$_},
                    }
                ) if exists $parent_map->{$_};

                $self->start_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $changes->{$_},
                    }
                );
            }

            #save element in stack
            push @{ $self->_objects_stack() }, $current_obj;

            #warn ref($self) . ": <" . $comm->{data}->local_name . ">";

            #skip deleted elements from xml stream
            unless ( $current_obj->is_delete_element ) {
                if ( UNIVERSAL::isa( $self->{Handler}, 'XML::ExtOn' ) ) {
                    my $cloned = $current_obj->__clone;
                    unless ( $self->{__make_self_events} ) {
                        $self->{Handler}->start_element($cloned);
                    }
                    else {
                        $self->{Handler}->__start_element($cloned);

                    }
                }
                else {
                    my $res_data = $self->__exp_element_to_sax2($current_obj);
                    $self->SUPER::start_element($res_data);
                }
            }
        }
        elsif ( $comm->{type} eq 'EV_END_ELEMENT' ) {
            my $current_obj  = $comm->{data};
            my $current_obj1 = pop @{ $self->_objects_stack() };

      #warn "END_E: ".$current_obj->local_name;
      # if skip
      #check current element for skip_content
      #            if ( my $current_element = $self->current_element ) {
      #                my $skip_content = $current_element->is_skip_content;
      #                if ( $skip_content > 1 ) {
      #                    $current_element->is_skip_content( --$skip_content );
      #                    return;
      #                }
      #            }

            unless ( $current_obj->is_delete_element ) {
                unless ( $self->{__make_self_events} ) {

                    #convert to SAX2
                    my $data = $current_obj->to_sax2;
                    delete $data->{Attributes};
                    $data->{NamespaceURI} = $current_obj->default_uri;
                    $self->SUPER::end_element($data);
                }
                else {

                    #call with object
                    $self->{Handler}->__end_element($current_obj1);
                }
            }

            my $changes    = $current_obj->ns->get_changes;
            my $parent_map = $current_obj->ns->parent->get_map;
            for ( keys %$changes ) {
                $self->end_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $changes->{$_},
                    }
                );
                if ( exists( $parent_map->{$_} ) ) {
                    $self->start_prefix_mapping(
                        {
                            Prefix       => $_,
                            NamespaceURI => $parent_map->{$_},
                        }
                    );
                }
            }

            #warn ref($self) . ": </" . $comm->{data}->local_name . ">";

        }
    }
    else {
        warn " Unknown DATA $comm";
    }
}

=head2 add_namespace <Prefix> => <Namespace_URI>, [ <Prefix1> => <Namespace_URI1>, ... ]

Add Namespace mapping. return C<$self>

If C<Prefix> eq '', this namespace will then apply to all elements 
that have no prefix.

    $elem->add_namespace(
        "myns" => 'http://example.com/myns',
        "myns_test", 'http://example.com/myns_test',
        ''=>'http://example.com/new_default_namespace'
    );

=cut

sub add_namespace {
    my $self    = shift;
    my $context = $self->context;
    if ( my $current = $self->current_element ) {
        $context = $current->ns;
    }
    my %map = @_;
    while ( my ( $prefix, $ns_uri ) = each %map ) {
        $context->declare_prefix( $prefix, $ns_uri );
    }
}

#overload sub parse

=head2 parse <file_handler>| <\*GLOB> | <xml string> | <ref to xml string>


=cut

sub parse {
    my ( $self, $in ) = @_;
    my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $self );
    my $parser = XML::Parser::PerlSAX->new( { Handler => $sax2_filter } );
    unless ( ref($in) ) {

        #        $self->_process_comm( $self->mk_from_xml($in) );
        $parser->parse( Source => { String => $in } );
    }
    elsif (UNIVERSAL::isa( $in, 'IO::Handle' )
        or ( ( ref $in ) eq 'GLOB' )
        or UNIVERSAL::isa( $in, 'Tie::Handle' ) )
    {
        $parser->parse( Source => { ByteStream => $in } )

    }
    else {
        die "unknown params";
    }
}

1;
__END__


=head1 SEE ALSO

XML::ExtOn::Element, XML::SAX::Base

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

