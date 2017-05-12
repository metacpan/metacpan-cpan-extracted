package WSST::Schema::Node;

use strict;
use base qw(WSST::Schema::Base);
__PACKAGE__->mk_accessors(qw(name title desc examples type children multiple
                             nullable));
__PACKAGE__->mk_ro_accessors(qw(parent depth));

use constant BOOL_FIELDS => qw(multiple nullable);

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{depth} = ($self->parent ? $self->parent->depth + 1 : 1);
    if ($self->{children}) {
        foreach my $node (@{$self->{children}}) {
            $node->{parent} = $self;
            $node = $class->new($node);
        }
    }
    return $self;
}

sub path {
    my $self = shift;
    my $min = shift || 0;
    my $path = [];
    for (my $p = $self; $p && $p->depth >= $min; $p = $p->parent) {
        unshift(@$path, $p);
    }
    return $path;
}

sub path_names {
    my $self = shift;
    my $min = shift || 0;
    return [map {$_->name} @{$self->path($min)}];
}

sub to_array {
    my $self = shift;

    my $array = [$self];
    my $stack = [[$self, 0]];
    while (my $val = pop(@$stack)) {
        my ($node, $i) = @$val;
        for (; $i < @{$node->{children}}; $i++) {
            my $child = $node->{children}->[$i];
            push(@$array, $child);
            if ($child->{children}) {
                push(@$stack, [$node, $i+1]);
                push(@$stack, [$child, 0]);
                last;
            }
        }
    }

    return $array;
}

=head1 NAME

WSST::Schema::Node - Schema::Node class of WSST

=head1 DESCRIPTION

This is a base class for tree structure of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 name

Accessor for the name.

=head2 title

Accessor for the title.

=head2 desc

Accessor for the desc.

=head2 examples

Accessor for the examples.

=head2 type

Accessor for the type.

=head2 children

Accessor for the children.

=head2 multiple

Accessor for the multiple.

=head2 nullable

Accessor for the nullable.

=head2 path

Returns Node objects of path.

=head2 path_names

Returns names of path

=head2 to_array

Returns arrayref which contains all child nodes.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
