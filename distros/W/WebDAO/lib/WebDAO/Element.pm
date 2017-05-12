package WebDAO::Element;

=head1 NAME

WebDAO::Element - Base class for simple object

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Element - Base class for simple object

=cut

our $VERSION = '0.01';

use Data::Dumper;
use WebDAO::Base;
use base qw/ WebDAO::Base/;
use warnings;
use strict 'vars';

__PACKAGE__->mk_attr(
    __my_name => undef,
    __parent => undef,
    __path2me => undef,
    __engine => undef,
    __extra_path => undef
);

=head1 NAME

WebDAO::Element - WebDAO::Element.

=head1 SYNOPSIS


=cut

sub _init {
    my $self = shift;
    $self->_sysinit( \@_ );    #For system internal inherites
    $self->init(@_);           # if (@_);
    return 1;
}


######## EVENTS ######

sub __register_event__ {
    my $self    = shift;
    my $ref_eng = $self->_root_;
    $ref_eng->__register_event__( $self, @_ );
}

sub __send_event__ {
    my $self   = shift;
    my $parent = $self->__parent || $self->_root_;
    $self->_log1( "Not def parent $self name:"
          . ( $self->__my_name )
          . Dumper( \@_ )
          . Dumper( [ map { [ caller($_) ] } ( 1 .. 10 ) ] ) )
      unless $parent;
    $parent->__send_event__(@_);
}

#
sub _sysinit {
    my $self = shift;

    #get init hash reference
    my $ref_init_hash = shift( @{ $_[0] } );

    #_engine - reference to engine
    $self->__engine( $ref_init_hash->{ref_engine} );

    #_my_name - name of this object
    $self->__my_name( $ref_init_hash->{name_obj} );
}

sub init {

    #Public Init metod for modules;
}


=head2 _get_childs_()

Return ref to childs array

=cut
sub _get_childs_ {
    return [];
}

=head2  __any_path ($session, @path)

Call for unresolved path.

Return:

    ($resuilt, \@rest_of_the_path)

=cut

sub __any_path {
    my $self = shift;
    my $sess = shift;
    my ( $method, @path ) = @_;
    #first check if Method
    #Check upper case First letter for method
    if ( ucfirst($method) ne $method ) {

        #warn  "Deny method : $method";
        return undef;    #not found
    }

    #check if $self have method
    if ( UNIVERSAL::can( $self, $method ) ) {

        #now try call method
        #Ok have method
        #check if path have more elements
        my %args = %{ $sess->Params };
        if (@path) {

            #add  special variable
            $args{__extra_path__} = \@path;
        }

        #call method (only one param may be return)
        my ($res, @path1) = $self->$method(%args);
        if ( scalar(@path1) ) {
            #method may return extra path
            return $res, \@path1;
        }
        return $res, \@path;
    }
    undef;

}

#return
#  undef  = not found
#  [ array of object]
#   <$self|| WebDAO::Element> ( ? for isert to parent container ?)
#  "STRING"
#   <WebDAO::Response>
sub _traverse_ {
    my $self = shift;
    my $sess = shift;

    #if empty path return $self
    unless ( scalar(@_) ) { return ( $self, $self ) }
    my ( $next_name, @path ) = @_;

    #try get objects by special methods
    my ( $res, $last_path ) = $self->__any_path( $sess, $next_name, @path );
    return ( $self, undef ) unless defined $res;    #break search
    return ( $self, $res );
}

sub __get_self_refs {
    return $_[0];
}

sub _set_parent {
    my ( $self, $parent ) = @_;
    $self->__parent($parent);
    $self->_set_path2me();
}

sub _set_path2me {
    my $self   = shift;
    my $parent = $self->__parent;
    if ( $self != $parent ) {
        ( my $parents_path = $parent->__path2me ) ||= "";
        my $extr = $parent->__extra_path;
        $extr = [] unless defined $extr;
        $extr = [$extr] unless ( ref($extr) eq 'ARRAY' );
        my $my_path = join "/", $parents_path, @$extr, $self->__my_name;
        $self->__path2me($my_path);
    }
    else {
        $self->__path2me('');
    }
}

#deprecated -> $obj->__my_name
sub _obj_name {
    return $_[0]->__my_name;
}


#deprecated  -> self->_root_
sub getEngine {
    my $self = shift;
    return $self->__engine;
}

sub _root_ { return $_[0]->__engine }

sub fetch { undef } #return undef

sub _destroy {
    my $self = shift;
    $self->__parent(undef);
    $self->__engine(undef);
}

sub url_method {
    my $self   = shift;
    my $method = shift;
    my @upath  = ();
    push @upath, $self->__path2me if $self->__path2me;
    push @upath, $method if defined $method;
    my $sess = $self->_root_->_session;
    if ( $sess->set_absolute_url() ) {
        my $root = $sess->Cgi_env->{base_url};
        unshift @upath, $sess->Cgi_env->{base_url};
    }
    #hack !!! clear / on begin
    #s{^/}{} for @upath;
    my $path = join '/' => @upath;
    my $str = '';
    if (@_) {
        my %args = @_;
        my @pars;
        while ( my ( $key, $val ) = each %args ) {
            push @pars, "$key=$val";
        }
        $str .= "?" . join "&" => @pars;
    }
    return $path . $str;
}

=head2 response

Return response object

    return $self->response->error404('Bad name')

=cut

sub response {
    my $self = shift;
    return $self->_root_->response;
}

=head2 request

Return request object

    $self->request->param('id')

=cut

sub request {
    return $_[0]->response->get_request();
}


1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

