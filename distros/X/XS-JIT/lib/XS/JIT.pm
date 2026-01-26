package XS::JIT;

use 5.008003;
use strict;
use warnings;
use File::Spec;
use Config;

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('XS::JIT', $VERSION);

# Find the XS::JIT installation directory (where headers and libs are)
sub _find_xs_jit_dir {
    my @search_paths = (
        # Standard installation locations
        File::Spec->catdir($Config{installsitearch}, 'auto', 'XS', 'JIT'),
        File::Spec->catdir($Config{installvendorarch} || '', 'auto', 'XS', 'JIT'),
        File::Spec->catdir($Config{installarchlib}, 'auto', 'XS', 'JIT'),
        # Local lib (for local::lib users)
        (exists $ENV{PERL_LOCAL_LIB_ROOT}
            ? File::Spec->catdir($ENV{PERL_LOCAL_LIB_ROOT}, 'lib', 'perl5', $Config{archname}, 'auto', 'XS', 'JIT')
            : ()),
        # Relative to this module (for uninstalled/development use)
        File::Spec->catdir(File::Spec->rel2abs(__FILE__), '..', '..', '..', '..', 'lib', 'XS', 'JIT'),
    );

    for my $dir (@search_paths) {
        next unless defined $dir && length $dir;
        my $header = File::Spec->catfile($dir, 'xs_jit.h');
        return $dir if -f $header;
    }
    return undef;
}

sub inc_dir {
    my $dir = _find_xs_jit_dir();
    die "Cannot find XS::JIT installation directory with xs_jit.h" unless $dir;
    return $dir;
}

sub cflags {
    my $dir = inc_dir();
    return "-I$dir";
}

sub libs {
    my $dir = inc_dir();
    # LIBS expects -L and -l format
    return "-L$dir -lxs_jit";
}

sub static_libs {
    my $dir = inc_dir();
    my $lib = File::Spec->catfile($dir, 'libxs_jit.a');
    return $lib if -f $lib;
    return undef;
}

=head1 NAME

XS::JIT - Lightweight JIT compiler for XS code

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use XS::JIT;

    # Compile C code and install functions
    XS::JIT->compile(
        code      => $c_code,
        name      => 'MyModule::JIT::Foo',
        functions => {
            # Simple form - XS::JIT generates a wrapper
            'Foo::get' => 'jit_get',

            # Hashref form - for XS-native functions (no wrapper)
            'Foo::new'  => { source => 'jit_new',  is_xs_native => 1 },
            'Foo::name' => { source => 'jit_name', is_xs_native => 1 },
        },
        cache_dir => '_CACHED_XS',  # optional, defaults to _CACHED_XS
        force     => 0,             # optional, force recompile
    );

=head1 DESCRIPTION

XS::JIT is a lightweight alternative to Inline::C for runtime JIT compilation
of XS code. It's specifically optimized for use cases where you're generating
C code dynamically and need to compile and load it at runtime.

Unlike Inline::C, XS::JIT:

=over 4

=item * Skips C code parsing (no Parse::RecDescent dependency)

=item * Skips xsubpp (generates C code directly)

=item * Uses direct compiler invocation (no make/Makefile.PL)

=item * Provides a C API for use from other XS modules

=back

=head1 METHODS

=head2 compile

    my $ok = XS::JIT->compile(%options);

Compiles C code and installs the specified functions into Perl namespaces.

Options:

=over 4

=item code (required)

The C source code to compile. This should be valid C code that uses the
Perl C API (EXTERN.h, perl.h, XSUB.h are included automatically).

=item name (required)

A unique module name for caching purposes (e.g., "MyApp::JIT::Class_0").
This is used to generate the boot function name and cache path.

=item functions (required)

A hashref mapping target Perl function names to source C function names.
Values can be either a simple string (the C function name) or a hashref
with options:

    # Simple string form
    functions => {
        'Package::method' => 'c_function_name',
    }

    # Hashref form with options
    functions => {
        'Package::method' => {
            source       => 'c_function_name',
            is_xs_native => 1,  # function handles XS stack itself
        },
    }

The C<is_xs_native> option is important for performance. Set it to 1 when
your C function is already written as a proper XS function using C<XS_EUPXS()>,
C<dXSARGS>, C<ST()>, and C<XSRETURN()>. This tells XS::JIT to create a simple
alias instead of generating a wrapper function, avoiding any overhead.

=item cache_dir

Optional. Directory for caching compiled modules. Defaults to "_CACHED_XS".

=item force

Optional. If true, forces recompilation even if a cached version exists.

=back

Returns 1 on success, 0 on failure.

=head2 is_cached

    my $cached = XS::JIT->is_cached($code, $name, $cache_dir);

Checks if a compiled module exists in the cache.

Arguments:

=over 4

=item $code

The C source code.

=item $name

The module name.

=item $cache_dir

Optional. Cache directory. Defaults to "_CACHED_XS".

=back

Returns 1 if cached, 0 otherwise.

=head2 generate_code

    my $c_code = XS::JIT->generate_code($user_code, $name, \%functions);

Generates the complete C source code with XS wrappers and boot function,
without compiling it. Useful for debugging or custom build processes.

Arguments:

=over 4

=item $user_code

The user's C source code.

=item $name

The module name (used for boot function naming).

=item \%functions

A hashref mapping Perl function names to C function names.

=back

Returns the complete generated C code as a string.

=head2 inc_dir

    my $dir = XS::JIT->inc_dir();

Returns the directory containing the XS::JIT header file (xs_jit.h).
This is useful for modules that want to use the XS::JIT C API.

Dies if the installation directory cannot be found.

=head2 cflags

    my $cflags = XS::JIT->cflags();

Returns compiler flags needed to compile code that uses the XS::JIT C API.
Currently returns C<-I/path/to/xs_jit.h>.

=head2 libs

    my $libs = XS::JIT->libs();

Returns linker flags needed for XS::JIT in the format C<-L/path -lxs_jit>.

=head2 static_libs

    my $lib_path = XS::JIT->static_libs();

Returns the full path to the static library C<libxs_jit.a>, or C<undef> if
not found. Useful for build systems that prefer explicit static linking.

Use both C<cflags> and C<libs> in your Makefile.PL:

    use XS::JIT;
    WriteMakefile(
        ...
        INC  => XS::JIT->cflags(),
        LIBS => [XS::JIT->libs()],
    );

=head1 WRITING C FUNCTIONS

XS::JIT supports two styles of C functions: wrapper-style functions that
return an SV*, and XS-native functions that handle the stack directly.

=head2 Wrapper-Style Functions (default)

These functions take C<SV* self> as the first argument and return an C<SV*>.
XS::JIT generates a wrapper that handles the Perl stack:

    SV* my_getter(SV* self) {
        dTHX;
        /* self is the invocant (class or object) */
        return newSVpv("hello", 0);
    }

=head2 XS-Native Functions (recommended for performance)

For best performance, write functions using the XS conventions directly
and set C<is_xs_native =E<gt> 1> in the function mapping. This avoids
wrapper overhead entirely:

    XS_EUPXS(my_getter) {
        dVAR; dXSARGS;
        PERL_UNUSED_VAR(cv);
        SV* self = ST(0);
        HV* hv = (HV*)SvRV(self);
        SV** valp = hv_fetch(hv, "value", 5, 0);
        ST(0) = (valp && *valp) ? *valp : &PL_sv_undef;
        XSRETURN(1);
    }

Register with:

    functions => {
        'Package::getter' => { source => 'my_getter', is_xs_native => 1 },
    }

=head2 Functions with Variable Arguments

Use C<JIT_ARGS> or C<dTHX; dXSARGS> to access additional arguments:

    SV* my_setter(SV* self, ...) {
        JIT_ARGS;

        if (items < 2) {
            croak("Value required");
        }

        SV* value = ST(1);  /* First argument after self */
        /* ... do something with value ... */
        return newSVsv(value);
    }

=head2 Returning Self for Method Chaining

When returning C<self> for method chaining, you must increment the
reference count:

    SV* my_chainable(SV* self, ...) {
        JIT_ARGS;
        /* ... modify object ... */
        SvREFCNT_inc(self);
        return self;
    }

=head2 Creating Objects

    SV* my_constructor(SV* class_sv, ...) {
        dTHX;
        const char* classname = SvPV_nolen(class_sv);
        HV* self_hv = newHV();

        /* Store attributes */
        hv_store(self_hv, "attr", 4, newSViv(0), 0);

        /* Bless and return */
        return sv_bless(newRV_noinc((SV*)self_hv),
                        gv_stashpv(classname, GV_ADD));
    }

=head1 C API

XS::JIT provides a C API that can be used directly from other XS modules
without Perl stack overhead. Include the header file:

    #include "xs_jit.h"

The function mapping structure:

    typedef struct {
        const char *target;   /* "Package::funcname" - where to install */
        const char *source;   /* "c_func_name" - function in user's C code */
        int has_varargs;      /* 1 if function takes variable arguments */
        int is_xs_native;     /* 1 if function is already XS-native */
    } XS_JIT_Func;

Example usage:

    XS_JIT_Func funcs[] = {
        { "Foo::new",  "jit_new",  0, 1 },  /* XS-native, no wrapper */
        { "Foo::name", "jit_name", 0, 1 },  /* XS-native, no wrapper */
        { NULL, NULL, 0, 0 }
    };

    xs_jit_compile(aTHX_ c_code, "MyModule::JIT::Foo",
                   funcs, 2, NULL, 0);

Set C<is_xs_native> to 1 when your functions use C<XS_EUPXS()>, C<dXSARGS>,
and C<XSRETURN()> directly. This creates simple aliases instead of wrappers.

The header file location can be found programmatically:

    use XS::JIT;
    print XS::JIT->inc_dir(), "\n";

Or use the C<cflags> method in your Makefile.PL:

    use XS::JIT;
    WriteMakefile(
        ...
        INC => XS::JIT->cflags(),
    );

=head1 CONVENIENCE MACROS

=head2 JIT_ARGS

The C<JIT_ARGS> macro initializes both the thread context and the XS argument
stack in a single statement. Use this at the start of functions that need to
access variable arguments:

    SV* my_function(SV* self, ...) {
        JIT_ARGS;  /* expands to: dTHX; dXSARGS */

        if (items < 2) croak("Need at least one argument");
        SV* arg = ST(1);
        return newSVsv(arg);
    }

This is equivalent to:

    SV* my_function(SV* self, ...) {
        dTHX;
        dXSARGS;
        ...
    }

=head1 INLINE::C COMPATIBILITY

XS::JIT provides the following macros for compatibility with code written
for Inline::C:

    Inline_Stack_Vars     - equivalent to dXSARGS
    Inline_Stack_Items    - number of arguments (items)
    Inline_Stack_Item(x)  - get argument x (ST(x))
    Inline_Stack_Reset    - reset stack pointer (sp = mark)
    Inline_Stack_Push(x)  - push value onto stack (XPUSHs(x))
    Inline_Stack_Done     - finalize stack (PUTBACK)
    Inline_Stack_Return(x) - return x values (XSRETURN(x))
    Inline_Stack_Void     - return no values (XSRETURN(0))


=head1 BENCHMARK

	============================================================
	XS::JIT vs Inline::C Benchmark
	============================================================

	Testing XS::JIT...
	----------------------------------------
	  First compile:  0.3311 seconds
	  Already loaded: 0.000026 seconds
	  Runtime (10k iterations): 0.0094 seconds

	Testing Inline::C...
	----------------------------------------
	  First compile:  0.7568 seconds
	  Runtime (10k iterations): 0.0127 seconds

	============================================================
	Summary
	============================================================
	First compile speedup: 2.3x faster
	Runtime performance:   1.36x faster (XS::JIT)

=head1 SEE ALSO

L<Inline::C> - The original runtime C compiler for Perl (which has more features)

L<perlxs> - XS language reference

L<perlguts> - Perl internal functions for XS programming

L<perlapi> - Perl API listing

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
