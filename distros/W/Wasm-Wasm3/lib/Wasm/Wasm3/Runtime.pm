package Wasm::Wasm3::Runtime;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasm3::Runtime

=head1 SYNOPSIS

See L<Wasm::Wasm3>.

=head1 DESCRIPTION

This module exposes L<wasm3|https://github.com/wasm3/wasm3>’s
runtime object to Perl.

=cut

#----------------------------------------------------------------------

use Wasm::Wasm3;

#----------------------------------------------------------------------

=head1 METHODS

This class is not directly instantiated; see L<Wasm::Wasm3> for
details.

=head2 $obj = I<OBJ>->load_module( $MODULE_OBJ )

Loads a parsed module (i.e., L<Wasm::Wasm3::Module> instance).
Returns I<OBJ>.

=head2 @returns = I<OBJ>->call( $FUNCTION_NAME, @ARGUMENTS )

Calls the named function with the given arguments, returning the
returns from that function.

A scalar-context call to this method will produce an exception
if the WebAssembly function returns multiple values.

=head2 $exit_code = I<OBJ>->run_wasi( @ARGV )

A WASI-specific variant of C<call()>.  Calls WASI’s start function
(as of this writing, always C<_start>) with the given @ARGV list
(byte strings).

Returns the WASI exit code.

=head2 @types = I<OBJ>->get_function_arguments( $FUNCTION_NAME )

Returns a list of the named function’s argument types, as TYPE_* constants.
(cf. L<Wasm::Wasm3>)

=head2 @types = I<OBJ>->get_function_returns( $FUNCTION_NAME )

Like C<get_function_arguments()> but for return types.

=head2 $str = I<OBJ>->get_memory( [ $OFFSET [, $WANTLENGTH] ] )

Fetches all or part of I<OBJ>’s WebAssembly memory buffer as a byte string.
$OFFSET defaults to 0, and $WANTLENGTH defaults to the buffer’s length less
$OFFSET. If $WANTLENGTH + $OFFSET exceed the buffer’s size, the returned
string will contain just the content from $OFFSET to the buffer’s end.

Currently both values B<MUST> be nonnegative.

=head2 $count = I<OBJ>->get_memory_size()

Returns the size, in bytes of I<OBJ>’s WebAssembly memory buffer.

=head2 $obj = I<OBJ>->set_memory( $OFFSET, $NEW_BYTES )

Overwrites all or part of I<OBJ>’s WebAssembly memory buffer with
$NEW_BYTES. Returns I<OBJ>.

=cut

1;
