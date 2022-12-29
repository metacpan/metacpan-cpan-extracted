package Wasm::Wasmer::Instance;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Instance

=head1 SYNOPSIS

    my $instance = $module->create_instance(
        {
            env => {
                alert => sub { .. },
            },
        }
    );

    $instance->call( 'dothething', 23, 34 );

=head1 DESCRIPTION

This class represents an active instance of a given module.

=head1 METHODS

Instances of this class are created via L<Wasm::Wasmer::Module>
instances. They expose the following methods:

=head2 $obj = I<OBJ>->export( $NAME_TXT )

Returns an instance of a L<Wasm::Wasmer::Extern> subclass that I<OBJ>
associates with the given $NAME_TXT (text string).

If I<OBJ> contains no such object then undef is returned.

=head2 $names_ar = I<OBJ>->export_names_ar()

Returns a reference to an array of the names (text strings)
of all of I<OBJ>’s exports.

=head2 @ret = I<OBJ>->call( $FUNCNAME_TXT, @INPUTS )

A convenience around:

    $obj->export($FUNCNAME)->call(@INPUTS);

=cut

1;
