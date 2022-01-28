package Test::Mock::Object::Chain;

# ABSTRACT: Create mocked method chains.

use strict;
use warnings;
use Carp;
use Scalar::Util 'blessed';
use Exporter 'import';
our @EXPORT_OK = qw(create_method_chain);

our $VERSION = '0.2';

sub create_method_chain {
    my ($chain) = @_;
    my $class = __PACKAGE__;

    if ( @$chain < 1 ) {
        carp::confess(
            "must have at least one method name to call on chain for $class");
    }

    my $last = pop @$chain;
    while ( my $method = pop @$chain ) {
        $last = _add_link( $method => $last );
    }
    return blessed $last ? $last : bless $last => $class;
}

sub _add_link {
    my ( $method, $value ) = @_;
    my $class = __PACKAGE__;
    my $instance;
    if ( 'ARRAY' eq ref $method ) {
        ( $instance, $method ) = @$method;
        if ( $instance->isa($class) ) {
            $instance->{$method} = $value;
            return $instance;
        }
        else {
            croak("Aref components in method chains must be [\$link, $value]");
        }
    }
    else {
        return bless { $method => $value } => $class;
    }
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.+:://;
    if ( !exists $self->{$AUTOLOAD} ) {
        my $class = ref $self;
        croak(
"Unknown method '$AUTOLOAD' called in method chain defined in $class"
        );
    }
    return $self->{$AUTOLOAD};
}

sub DESTROY { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mock::Object::Chain - Create mocked method chains.

=head1 VERSION

version 0.2

=head1 SYNOPSIS

   my $chain = create_method_chain([@list_of_methods, $final_value]);

=head1 DESCRIPTION

For internal use only.

=head1 SUBROUTINES

=head2 C<create_method_chain([@list_of_methods, $final_response]>

   my $chain = create_method_chain([qw/foo bar baz/, 42]);
   say $chain->foo->bar->baz; # 42

If any method can be an array reference containing a
C<Test::Mock::Object::Chain> object and a method name. That will
add the method name to the chain. Using the above chain:

   $chain = create_method_chain([[$chain, 'bar'], 'this', 23]);
   say $chain->bar->this; # 23

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
