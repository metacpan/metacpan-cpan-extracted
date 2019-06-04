# NAME

Z3::FFI - Low level FFI interfaces to the Z3 solver/prover

# VERSION

This is built for Z3 version 4.8.4

# DESCRIPTION

This is a direct translation of the Z3 C API to a Perl API.  It's most likely not the level for working with Z3 from perl.

This is a mostly functional implementation right now.  A few functions are not implemented, Z3\_set\_error\_handler in particular.
This early release is also missing support for any Z3\_...\[\] array types and the few pointer types that get used.  These will be implemented
in future versions

# USE

You're going to want to refer to the C API documentation for Z3, [http://z3prover.github.io/api/html/group\_\_capi.html](http://z3prover.github.io/api/html/group__capi.html).  
All functions have the Z3\_ stripped from their name and are declared as part of this module.

    use Z3::FFI;

    my $config = Z3::FFI::mk_config(); # Create a Z3 config object
    my $context = Z3::FFI::mk_context($config); # Create the Z3 Context object
    ... # work with the Z3 context

# TODO

- Finish the array types to allow more functions to be called.
- Finish the pointer types to allow the rest of the functions to be called.
- Figure out if there's a way to handle the Z3\_set\_error\_handler function

# SEE ALSO

[Alien::Z3](https://metacpan.org/pod/Alien::Z3)

# AUTHOR

Ryan Voots <simcop@cpan.org>
