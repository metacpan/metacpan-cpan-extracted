package XML::Toolkit::Loader::Filter;
{
  $XML::Toolkit::Loader::Filter::VERSION = '0.15';
}
use Moose;
use namespace::autoclean;

extends qw(XML::Filter::Moose);

with qw(XML::Toolkit::Builder::ClassRegistry);

has objects => (
    isa     => 'ArrayRef',
    is      => 'ro',
    traits  => ['Array'],
    lazy    => 1,
    builder => '_build_objects',
    clearer => 'reset_state',
    handles => {
        pop_object     => ['pop'],
        add_object     => ['push'],
        objects_count  => ['count'],
        current_object => [ 'get', -1 ],
        root_object    => [ 'get', 0 ],
      }

);

sub _build_objects { [] }

sub parent_object {
    my ($self) = @_;
    if ( $self->objects_count >= 2 ) {
        return $self->objects->[-2];
    }
    return undef if $self->objects_count == 1;
    return $self->objects->[-1];
}

sub at_root_object { $_[0]->current_object == $_[0]->root_object }

sub load_class {
    my ( $self, $name ) = @_;
    Class::MOP::load_class($name);
    return $name;
}

sub create_and_add_object {
    my ( $self, $class, $el ) = @_;
    my %params =
      map { $_->{LocalName} => $_->{Value} } values %{ $el->{Attributes} };
    my $obj = $class->new(%params);
    $self->add_object($obj);

}

sub start_element {
    my ( $self, $el ) = @_;

    my $classname = $self->get_class_name($el);
    $el->{classname} = $classname;

    if ( my $class = $self->load_class($classname) ) {
        $self->create_and_add_object( $class => $el );
    }
    $self->add_element($el);
    return;
}

sub append_to_parent {
    my ( $self, $parent, $el ) = @_;
    if ( my $method = $parent->can("add_$el->{LocalName}") ) {
        $parent->$method( $self->current_object );
    }
}

sub set_object_text {
    my ($self) = @_;
    $self->current_object->text( $self->text )
      if $self->current_object->can('text');
}

sub end_element {
    my ( $self, $el ) = @_;
    $self->set_object_text if $self->has_text;
    if ( my $parent = $self->parent_object ) {
        $self->append_to_parent( $parent => $el );
    }
    $self->pop_object unless $self->at_root_object;
    $self->pop_element;
    $self->reset_text;
}

sub render {
    warn shift->root_object->dump;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::Loader::Filter - A class to ...

=head1 VERSION

version 0.15

=head1 SYNOPSIS

use XML::Toolkit::Loader::Filter;

=head1 DESCRIPTION

The XML::Toolkit::Loader::Filter class implements ...

=head1 SUBROUTINES / METHODS

=head2 parent_object (method)

Parameters:
    none

Insert description of method here...

=head2 current_object (method)

Parameters:
    none

Insert description of method here...

=head2 root_object (method)

Parameters:
    none

Insert description of method here...

=head2 load_class (method)

Parameters:
    name

Insert description of method here...

=head2 get_class_name (method)

Parameters:
    name
    self
    el
    self
    el

Insert description of method here...

=head2 render

Parameters:
    none

Insert description of subroutine here...

=head1 DEPENDENCIES

Moose

=head1 NOTES

...

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (perigrin@domain.tld)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
