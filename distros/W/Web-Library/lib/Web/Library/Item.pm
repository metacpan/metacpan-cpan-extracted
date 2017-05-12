package Web::Library::Item;
use Moose;
use Class::Load qw(load_class);
has name    => (is => 'ro', isa => 'Str', required => 1);
has version => (is => 'ro', isa => 'Str', default  => 'latest');

sub BUILD {
    my $self = shift;
    load_class($self->get_package);
}

sub get_package {
    my $self = shift;
    'Web::Library::' . $self->name;
}

sub get_distribution_object {
    my $self = shift;
    $self->get_package->new;
}

sub include_path {
    my $self = shift;
    $self->get_distribution_object->get_dir_for($self->version);
}

sub css_assets {
    my $self = shift;
    $self->get_distribution_object->css_assets_for($self->version);
}

sub javascript_assets {
    my $self = shift;
    $self->get_distribution_object->javascript_assets_for($self->version);
}
1;

=pod

=head1 NAME

Web::Library::Item - A library item being managed by Web::Library

=head1 SYNOPSIS

    # none; this class is internal

=head1 DESCRIPTION

This class represents a specific version of a specific library that is
managed by L<Web::Library>. It is internal; you should never need to
use it.
