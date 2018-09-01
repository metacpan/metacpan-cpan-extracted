package # hide from PAUSE
    DB::Binder::Trait::Provider;
use strict;
use warnings;

use decorators ':for_providers';

sub PrimaryKey : Decorator : CreateMethod {
    my ($meta, $method, $column_name) = @_;
    Col($meta, $method, $column_name);
}

sub Col : Decorator : CreateMethod {
    my ($meta, $method, $column_name) = @_;

    my $method_name = $method->name;

    $column_name ||= $method_name;

    die 'A slot already exists for ('.$column_name.')'
        if $meta->has_slot( $column_name )
        || $meta->has_slot_alias( $column_name );

    $meta->add_slot( $column_name, MOP::Slot::Initializer->new( within_package => $meta->name ) );
    $meta->add_method( $method_name, sub { $_[0]->{ $column_name } } );
}

sub HasOne : Decorator : CreateMethod  {
    my ($meta, $method, $related_class, $column_name) = @_;

    my $method_name = $method->name;

    $column_name ||= $method_name;

    die 'A slot already exists for ('.$column_name.')'
        if $meta->has_slot( $column_name )
        || $meta->has_slot_alias( $column_name );

    $meta->add_slot( $column_name, MOP::Slot::Initializer->new( within_package => $meta->name, default => sub { $related_class->new } ) );
    $meta->add_method( $method_name, sub { $_[0]->{ $column_name } } );
}

sub HasMany : Decorator : CreateMethod {
    my ($meta, $method, $related_class, $related_column_name) = @_;

    my $method_name = $method->name;
    my $column_name = $method_name;

    die 'A slot already exists for ('.$column_name.')'
        if $meta->has_slot( $column_name )
        || $meta->has_slot_alias( $column_name );

    $meta->add_slot( $column_name, MOP::Slot::Initializer->new( within_package => $meta->name, default => sub { [] } ) );
    $meta->add_method( $method_name, sub { @{ $_[0]->{ $column_name } } } );
}

1;
