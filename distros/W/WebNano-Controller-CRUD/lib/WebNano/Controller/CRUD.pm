package WebNano::Controller::CRUD;
{
  $WebNano::Controller::CRUD::VERSION = '0.007';
}
use Moose;
use MooseX::NonMoose;
use Class::MOP;
use File::Spec::Functions 'catdir';

extends 'WebNano::Controller';

has form_class => ( is => 'ro', isa => 'Str', required => 1 );
has rs_name => ( is => 'ro', isa => 'Str', lazy_build => 1, );
sub _build_rs_name {
    my $self = shift;
    my $my_name = ref $self;
    $my_name =~ /::(\w+)$/;
    return $1;
}

has record_actions => ( 
    is => 'ro', 
    isa => 'HashRef', 
    default => sub { { view => 1, 'delete' => 1, edit => 1 } }
);

has primary_columns => (
    is => 'ro',
    lazy_build => 1,
);
sub _build_primary_columns {
    my $self = shift;
    my $source = $self->app->schema->source( $self->rs_name );
    return [ $source->primary_columns ];
}

my $FULLPATH;
BEGIN { use Cwd (); $FULLPATH = Cwd::abs_path(__FILE__) }

sub template_search_path {
    my $self = shift;
    my $mydir = $FULLPATH;
    $mydir =~ s/.pm$//;
    return [ catdir( $mydir, 'templates' ) ];
}

sub columns {
    my $self = shift;
    my $source = $self->app->schema->source( $self->rs_name );
    return [ $source->columns ];
}


sub _get_parts {
    my $self = shift;
    my @args = @{ $self->path };
    my @pks = @{ $self->primary_columns };
    my @ids;
    for my $i ( 0 .. $#pks ){
        if( defined $args[$i] && $args[$i] =~ /^\d+$/ ){
            push @ids, $args[$i];
        }
        else{
            return;
        }
    }
    my $method = $args[ $#pks + 1 ] || 'view';
    my $method_reg = join '|', keys %{ $self->record_actions };
    return if $method !~ /$method_reg/;
    return {
        ids => \@ids,
        method => $args[ $#pks + 1 ] || 'view',
        args => [ @args[ $#pks + 2, $#args ] ],
    };
}

around 'local_dispatch' => sub {
    my( $orig, $self ) = @_;
    if( my $parsed = $self->_get_parts() ){
        my $rs = $self->app->schema->resultset( $self->rs_name );
        my $record = $rs->find( @{ $parsed->{ids} } );
        if( ! $record ) {
            my $res = $self->req->new_response(404);
            $res->content_type('text/plain');
            $res->body( 'No record with ids: ' . join ' ', @{ $parsed->{ids} } );
            return $res;
        }
        my $method = $parsed->{method};
        return $self->$method( $record, @{ $parsed->{args} } );
    }
    return $self->$orig();
};

sub index_action { shift->list_action( @_ ) }

sub list_action {
    my( $self ) = @_;
    my $rs = $self->app->schema->resultset( $self->rs_name );
    return $self->render( template => 'list.tt', items => [ $rs->search ] );
}

sub after_POST {
    my( $self, @ids ) = @_;
    return $self->self_url . join( '/', @ids ) . '/view';
}

sub create_action {
    my ( $self ) = @_;
    my $req = $self->req;

    my $form_class = $self->form_class;
    Class::MOP::load_class( $form_class );
    my $item = $self->app->schema->resultset( $self->rs_name )->new_result( {} );
    my $params = $req->parameters->as_hashref_mixed;
    my $form = $form_class->new( 
        params => $params, 
        schema => $self->app->schema,
        item   => $item,
    );
    if( $req->method eq 'POST' && $form->process() ){
        my $record = $form->item;
        my $res = $req->new_response();
        $res->redirect( $self->after_POST( $record->id ) );
        return $res;
    }
    $form->field( 'submit' )->value( 'Create' );
    return $self->render( template => 'edit.tt', form => $form->render );
}


sub view {
    my ( $self, $record ) = @_;

    return $self->render( template => 'record.tt', record => $record );
}

sub delete {
    my ( $self, $record ) = @_;
    if( $self->req->method eq 'GET' ){
        return $self->render( template => 'delete.tt', record => $record );
    }
    else{
        $record->delete;
        my $res = $self->req->new_response();
        $res->redirect( $self->self_url );
        return $res;
    }
}

sub edit {
    my ( $self, $record ) = @_;
    my $req = $self->req;
    my $form_class = $self->form_class;
    Class::MOP::load_class( $form_class );
    my $params = $req->parameters->as_hashref_mixed;
    my $form = $form_class->new( 
        item   => $record,
        params => $params,
    );
    if( $req->method eq 'POST' && $form->process() ){
        my $res = $req->new_response();
        $res->redirect( $self->after_POST( $record->id ) );
        return $res;
    }
    $form->field( 'submit' )->value( 'Update' );
    return $self->render( template => 'edit.tt', form => $form->render );
}

1;



=pod

=head1 NAME

WebNano::Controller::CRUD

=head1 VERSION

version 0.007

=head1 SYNOPSIS

use base 'WebNano::Controller::CRUD';

=head1 DESCRIPTION

This is experimental Template Tookit and DBIx::Class based CRUD controller for L<WebNano>

=head1 ATTRIBUTES

=head2 form_class

=head2 rs_name

=head2 record_actions

=head1 METHODS

=head2 create_action

=head2 delete

=head2 edit

=head2 index_action

=head2 list_action

=head2 parse_path

=head2 view

=head2 columns

=head2 after_POST

=head1 AUTHOR

Zbigniew Lukasiak <zby@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Zbigniew Lukasiak <zby@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

# ABSTRACT:  A base controller implementing CRUD operations (EXPERIMENTAL!)

