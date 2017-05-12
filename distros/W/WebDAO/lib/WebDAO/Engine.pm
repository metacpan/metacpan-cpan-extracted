package WebDAO::Engine;

#$Id$

=head1 NAME

=head1 DESCRIPTION

WebDAO::Engine - Class for root object of application model

=cut

our $VERSION = '0.01';

use Data::Dumper;
use WebDAO::Container;
use WebDAO::Lib::MethodByPath;
use WebDAO::Lib::RawHTML;
use base qw(WebDAO::Container);
use Carp;
use strict;
use warnings;
__PACKAGE__->mk_attr( _session=>undef, __obj=>undef, __events=>undef);

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    return ( $stat = $self->_init(@_) ) ? $self : $stat;
}

sub _sysinit {
    my ( $self, $ref ) = @_;
    my %hash = @$ref;

    # Setup $init_hash;
    my $my_name = $hash{id} || '';
    unshift(
        @{$ref},
        {
            ref_engine => $self,       #! Setup _engine refernce for childs!
            name_obj   => "$my_name"
        }
    );                                 #! Setup _my_name
                                       #Save session
    _session $self $hash{session};

    #	name_obj=>"applic"});	#! Setup _my_name
    $self->SUPER::_sysinit($ref);

    #!init _runtime variables;
    $self->_set_parent($self);

    #hash "function" -"package"
    $self->__obj( {} );

    #init hash of evens names  -> @Array of pointers of sub in objects
    $self->__events( {} );

}

sub init {
    my ( $self, %opt ) = @_;

    #register default clasess
    $self->register_class(
        'WebDAO::Lib::RawHTML'      => '_rawhtml_element',
        'WebDAO::Lib::MethodByPath' => '_method_call'
    );

    #Register by init classes
    if ( ref( my $classes = $opt{register} ) ) {
        $self->register_class(%$classes);
    }
    if ( my $lexer = $opt{lexer} ) {
        map { $_->value($self) } @{ $lexer->auto };
        my @objs = map { $_->value($self) } @{ $lexer->tree };
        $self->_add_childs_(@objs);
    }
    elsif ( my $lex = $opt{lex} ) {
        my ( $pre, $fetch, $post ) = @{ $lex->value($self) || [] };
        $self->__add_childs__( 0,  @$pre );
        $self->_add_childs_(  @$fetch );
        $self->__add_childs__( 2, @$post );
    }

}

sub response {
    my $self = shift;
    return $self->_session->response_obj;
}


=head2  __handle_out__ ($sess, @output)

Process output by fetch methods

=cut

sub __handle_out__ {
    my $self = shift;
    my $sess = shift;
    for (@_) {
        if ( UNIVERSAL::isa( $_, 'WebDAO::Element' ) ) {
            $self->__handle_out__( $sess, $_->pre_fetch($sess) )
              if UNIVERSAL::can( $_, 'pre_fetch' );

            $self->__handle_out__( $sess, $_->fetch($sess) );
            $self->__handle_out__( $sess, $_->post_fetch($sess) )
              if UNIVERSAL::can( $_, 'post_fetch' );

        }
        elsif ( ref($_) eq 'CODE' ) {
            return $self->__handle_out__( $sess, $_->($sess) );
        }
        elsif ( UNIVERSAL::isa( $_, 'WebDAO::Response' ) ) {
            $_->_is_headers_printed(1);
            $_->_print_dep_on_context($sess) unless $_->_is_file_send;
            $_->flush;
            $_->_destroy;

        }
        else {
            $sess->print($_);
        }
    }
}

sub __events__ {
    my $self         = shift;
    my $root         = shift;
    my $inject_fetch = shift;
    my $path         = $root->__path2me;
    my @childs       = ();

    #make inject event for objects
    if ( my $res = $inject_fetch->{$path} ) {
        @childs = (
            {
                fetch => $root->__path2me,
                pme   => $path,
                ,
                event => 'inject',
                obj   => $root,
                res   => $res
            }
        );

    }
    else {

        if ( UNIVERSAL::isa( $root, 'WebDAO::Container' ) ) {

            #skip modal
            for ( @{ $root->__childs() } ) {
                push @childs, $self->__events__( $_, $inject_fetch )
                  unless UNIVERSAL::isa( $_, 'WebDAO::Modal' );
            }
        }
        else {
            @childs = (
                {
                    fetch => $root->__path2me,
                    pme   => $path,
                    ,
                    event => 'fetch',
                    obj   => $root
                }
            );
        }
    }
    my @res = (
        {
            st_ev => $root->__path2me,
            pme   => $path,
            event => 'start',
            obj   => $root
        },
        @childs,
        {
            end_ev => $root->__path2me,
            pme    => $path,
            event  => 'end',
            obj    => $root
        }
    );
}

sub _execute {
    my $self =shift;
    return $self->execute2(@_)
}

sub execute2 {
    my $self = shift;
    my $sess = shift;
    my $url  = shift;
    my @path = @{ $sess->call_path($url) };
    my ( $src, $res ) = $self->_traverse_( $sess, @path );
    my $response = $self->response;
    #now analyze answers
    # undef -> not Found
    unless ( defined($res) ) {
        $response->error404( "Url not found:" . join "/", @path );
        $response->flush;
        $response->_destroy;
        return;    #end
    }

    #convert string and ref(scalar) to resonse with html
    #special handle strings
    if ( !ref($res) or ( ref($res) eq 'SCALAR' ) ) {
        $res = $response->set_html( ref($res) ? $$res : $res );
    }
    #special handle HASH refs ( interpret as json)
    if ( ( ref($res) eq 'HASH' ) and $response->wantformat('json') ) {
        $res = $response->set_json( $res );
    }
    #check if  response modal
    if ( UNIVERSAL::isa( $res, 'WebDAO::Response' ) ) {
        #check empty response( $r->set_empty)
        return if $res->is_empty;
        if ( $res->_is_modal() ) {

        #handle response
        $res->_print_dep_on_context($sess, $res) unless $res->_is_file_send;
        $res->flush;
        $res->_destroy;
        return;
     }
    }

    #extract all objects to evenets
    my $root = $self;

    #if object modal ?
    if ( UNIVERSAL::isa( $src, 'WebDAO::Modal' ) ) {

        #set him as root of putput
        $root = $src;
    }
    my $need_inject_result = 1;

    #special handle strings
    if ( !ref($res) or ( ref($res) eq 'SCALAR' ) ) {

        #now walk
    }
    elsif

      #if result ref to object and it eq $src run flow
      ( $res == $src ) {
        $need_inject_result = 0;
    }
    if ( UNIVERSAL::isa( $res, 'WebDAO::Element' ) ) {

        #nothing  to do
    }
    my %injects = ();

    #if need inject check flow by path
    if ($need_inject_result) {
        $injects{ $src->__path2me } = $res;
    }
    #start out
    $response->print_header;

    my @ev_flow = $self->__events__( $root, \%injects );
    foreach my $ev (@ev_flow) {
        my $obj = $ev->{obj};

        #_log1 $self "DO " . $ev->{event}. " for $obj";
        if ( $ev->{event} eq 'start' ) {
            $self->__handle_out__( $sess, $obj->pre_fetch($sess) )
              if UNIVERSAL::can( $obj, 'pre_fetch' );
        }
        elsif ( $ev->{event} eq 'inject' ) {
            $self->__handle_out__( $sess, $ev->{res} )

        }
        elsif ( $ev->{event} eq 'fetch' ) {

            #skip fetch method for container

            $self->__handle_out__( $sess, $obj->fetch($sess) )
              if UNIVERSAL::can( $obj, 'fetch' );

        }
        elsif ( $ev->{event} eq 'end' ) {

            $self->__handle_out__( $sess, $obj->post_fetch($sess) )
              if UNIVERSAL::can( $obj, 'post_fetch' );
        }

    }
    $response->flush;
    $response->_destroy;
}


#fill $self->__events hash event - method
sub __register_event__ {
    my ( $self, $ref_obj, $event_name, $ref_sub ) = @_;
    my $ev_hash = $self->__events;
    $ev_hash->{$event_name}->{ scalar($ref_obj) } = {
        ref_obj => $ref_obj,
        ref_sub => $ref_sub
      }
      if ( ref($ref_sub) );
    return 1;
}

sub __send_event__ {
    my ( $self, $event_name, @Par ) = @_;
    my $ev_hash = $self->__events;
    unless ( exists( $ev_hash->{$event_name} ) ) {
        _log2 $self "WARN: Event $event_name not exists.";
        return 0;
    }
    foreach my $ref_rec ( keys %{ $ev_hash->{$event_name} } ) {
        my $ref_sub = $ev_hash->{$event_name}->{$ref_rec}->{ref_sub};
        my $ref_obj = $ev_hash->{$event_name}->{$ref_rec}->{ref_obj};
        $ref_obj->$ref_sub( $event_name, @Par );
    }
}

=head3 _create_(<name>,<class or alias>,@parameters)

create object by <class or alias>.

=cut

sub _create_ {
    my ( $self, $name_obj, $name_func, @par ) = @_;
    my $pack = $self->_pack4name($name_func) || $name_func;
    my $ref_init_hash = {
        ref_engine => $self->_root_,  #! Setup _engine refernce for childs!
        name_obj   => $name_obj
    };    #! Setup _my_name
    my $obj_ref =
      $pack->isa('WebDAO::Element')
      ? eval "'$pack'\-\>new(\@par)"
      : eval "'$pack'\-\>new(\@par)";
#      ? eval "'$pack'\-\>new(\$ref_init_hash,\@par)"
#      : eval "'$pack'\-\>new(\@par)";
    if ($pack->isa('WebDAO::Element') ) {
        $obj_ref->{_engine} = $self->_root_ ;
        $obj_ref->{__my_name} =  $name_obj ;
        $obj_ref->_init($ref_init_hash,@par) 
    }
    $self->_log1("Error in eval:  _create_ $@") if $@;
    return $obj_ref;
}

sub _createObj {
    my $self = shift;

    #    _deprecated $self "_create_";
    return $self->_create_(@_);
}

#Get package for functions name
sub _pack4name {
    my ( $self, $name ) = @_;
    my $ref = $self->__obj;
    return $$ref{$name} if ( exists $$ref{$name} );
}

sub register_class {
    my ( $self, %register ) = @_;
    my $_obj = $self->__obj;
    while ( my ( $class, $alias ) = each %register ) {

        #check non loaded mods
        my ( $main, $module ) = $class =~ m/(.*\:\:)?(\S+)$/;
        $main ||= 'main::';
        $module .= '::';
        no strict 'refs';
        unless ( exists $$main{$module} ) {
            _log1 $self "Try use $class";
            eval "use $class";
            if ($@) {
                _log1 $self "Error register class :$class with $@ ";
                return "Error register class :$class with $@ ";
                next;
            }
        }
        use strict 'refs';

        #check if register_class used for eval ( see Lobject )
        $$_obj{$alias} = $class if defined $alias;
    }
    return;
}

=head3  _commit

Method witch called after HTTP request

=cut

sub _commit {
    #nothing by default
}

sub _destroy {
    my $self = shift;
    $self->SUPER::_destroy;
    $self->_session(undef);
    $self->__obj(undef);
    $self->__events(undef);
}
1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

