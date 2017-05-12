package WebDAO::Container;

#$Id$

=head1 NAME

WebDAO::Container - Group of objects

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Container - Group of objects

=cut

our $VERSION = '0.02';

use WebDAO::Element;
use base qw(WebDAO::Element);
use strict 'vars';
use warnings;

__PACKAGE__->mk_attr( __post_childs => '', __pre_childs => '', __childs => '' );

sub _sysinit {
    my $self = shift;

    #First invoke parent _init;
    $self->SUPER::_sysinit(@_);

    #init childs
    $self->_clear_childs_();
}

=head1 METHODS (chidls)

=head2 _get_childs_()

Return ref to childs array

=cut

sub _get_childs_ {
    my $self = shift;
    return [
        @{ $self->__pre_childs() },
        @{ $self->__childs() },
        @{ $self->__post_childs() }
    ];
}

=head3 _add_childs_($object1[, $object2])

Insert set of objects into container

=cut

sub _add_childs_ {
    my $self = shift;
    $self->__add_childs__( 1, @_ );
}

=head2 _clear_childs_

Clear all childs (pre, post also)

=cut

sub _clear_childs_ {
    my $self = shift;
    $self->__post_childs( [] );
    $self->__childs(      [] );
    $self->__pre_childs(  [] );
}

=head2 _set_childs_ @childs_set

Clear all childs (except "pre" and "post" objects), and set  to C<@childs_set>

=cut

# 0 - pre, 1 - fetch , 2 - post
sub __set_childs__ {
    my $self = shift;
    my $type = shift;
    my $dst  = $type == 0
      ? $self->__pre_childs    #0
      : $type == 1 ? $self->__childs()        #1
      :              $self->__post_childs;    #2
    for ( @{$dst} ) {
        $_->_destroy;
    }
    $self->__add_childs__( $type, @_ );
}

# 0 - pre, 1 - fetch , 2 - post
sub __add_childs__ {
    my $self = shift;
    my $type = shift;
    my $dst  = $type == 0
      ? $self->__pre_childs                   #0
      : $type == 1 ? $self->__childs()        #1
      :              $self->__post_childs;    #2
    my @childs =
      grep { ref $_ }
      map { ref($_) eq 'ARRAY' ? @$_ : $_ }
      map { $_->__get_self_refs }
      grep { ref($_) && $_->can('__get_self_refs') }
      map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
    return unless @childs;
    if ( $self->__parent ) {
        $_->_set_parent($self) for @childs;
    }
    push( @{$dst}, @childs );
}

sub _set_childs_ {
    my $self = shift;

    #first destoroy
    for ( @{ $self->__childs() } ) {
        $_->_destroy;
    }
    $self->__childs( [] );
    $self->_add_childs_(@_);
}

=head1 OUTPUT_METHODS

=head2 pre_fetch ($session)

Output data precede to fetch method. By default output "pre" objects;

=cut

sub pre_fetch {
    my $self = shift;
    @{ $self->__pre_childs };
}

=head2 post_fetch ($session)

Output data follow to fetch method. By default output "post" objects;

=cut

sub post_fetch {
    my $self = shift;
    @{ $self->__post_childs };
}

=head1 OTHER
=cut

#it for container
sub _set_parent {
    my ( $self, $par ) = @_;
    $self->SUPER::_set_parent($par);
    foreach my $ref ( @{ $self->_get_childs_ } ) {
        $ref->_set_parent($self);
    }
}

sub __any_path {
    my $self     = shift;
    my $sess     = shift;
    my ($method) = @_;
    my ( $res, $path ) = $self->SUPER::__any_path( $sess, @_ );

    #process routes
    unless ( defined($res) ) {
        no strict 'refs';
        my $pkg    = ref($self);
        my %routes = %{"${pkg}::_WEBDAO_ROUTE_"};
        if ( exists $routes{$method} and my $class = $routes{$method} ) {
            unless ( UNIVERSAL::isa( $class, 'WebDAO::Container' ) ) {
                my $isa = \@{"${class}::ISA"};
                push @$isa, 'WebDAO::Container';
            }
            my $obj = $self->_root_->_create_( $method, $class );
            $self->_add_childs_($obj);
            $path = \@_;
            $res  = $self;
        }
        use strict 'refs';
    }
    return undef unless defined($res);
    if ( ref($res) eq 'ARRAY' ) {

        #make container
        my $cont = $self->__engine->_create_( $method, __PACKAGE__ );
        $cont->_set_childs_(@$res);
        $res = [$cont];
        unshift( @$path, $method );
    }
    return ( $res, $path );
}

#Return (  object witch handle req and result )
sub _traverse_ {
    my $self = shift;
    my $sess = shift;

    #if empty path return $self
    unless ( scalar(@_) ) { return ( $self, $self ) }

    my ( $next_name, @path ) = @_;

    #$src - object wich handle answer, $res - answer
    my ( $src, $res ) = ( $self, undef );

    #check if exist object with some name
    if ( my $obj = $self->_get_obj_by_name($next_name) ) {

        #if last in path return him
        ( $src, $res ) = $obj->_traverse_( $sess, @path );

    }
    else {    #try get other ways

        #try get objects by special methods
        my $last_path;
        ( $res, $last_path ) = $self->__any_path( $sess, $next_name, @path );
        return ( $self, undef ) unless defined $res;    #break search
        if ( UNIVERSAL::isa( $res, 'WebDAO::Response' ) ) {
            return ( $self, $res );
        }
        elsif ( ref($res) eq 'ARRAY' ) {

            #for objects array attach them into collection
            $self->_set_childs_(@$res);

            #return ref to container if array to self
            $res = $self;
        }

        #analyze $last_path
        my @rest_path = ();
        if ($last_path) {
            if ( ref($last_path) eq 'ARRAY' ) {
                @rest_path = @$last_path;
            }
        }
        if (@rest_path) {
            ( $src, $res ) = $self->_traverse_( $sess, @rest_path );
        }
    }
    #
    if ( $res && $src && ( $src eq $res )  && !UNIVERSAL::isa( $src, 'WebDAO::Modal' ) ) {

        #force set root object for Modal
        $src = $res = $self if UNIVERSAL::isa( $self, 'WebDAO::Modal' );
    }
    return ( $src, $res );
}

sub _get_obj_by_name {
    my $self = shift;
    my $name = shift;
    return unless defined $name;
    my $res;
    foreach my $obj ( $self, @{ $self->_get_childs_ } ) {
        if ( $obj->_obj_name eq $name ) {
            return $obj;
        }
    }
    return;
}

sub _destroy {
    my $self = shift;
    my @res;
    for my $a ( @{ $self->_get_childs_ } ) {
        $a->_destroy;
    }
    $self->_clear_childs_();
    $self->SUPER::_destroy;
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

