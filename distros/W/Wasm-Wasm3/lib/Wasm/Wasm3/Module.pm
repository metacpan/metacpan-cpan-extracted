package Wasm::Wasm3::Module;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasm3::Module

=head1 SYNOPSIS

See L<Wasm::Wasm3>.

=head1 DESCRIPTION

This module exposes L<wasm3|https://github.com/wasm3/wasm3>’s
module object to Perl.

=cut

#----------------------------------------------------------------------

use Wasm::Wasm3;

#----------------------------------------------------------------------

=head1 METHODS

This class is not directly instantiated; see L<Wasm::Wasm3> for
details.

=head2 $value = I<OBJ>->get_global( $NAME )

Returns the value of the $NAMEd export global.

=head2 $type = I<OBJ>->get_global_type( $NAME )

Returns the type (e.g., Wasm::Wasm3::TYPE_I32) of the $NAMEd export global.

=head2 $obj = I<OBJ>->link_function( $MODULE_NAME, $FUNCTION_NAME, $SIGNATURE, $CODEREF )

Sets $CODEREF as $MODULE_NAME.$FUNCTION_NAME’s implementation inside the
WebAssembly module. See below for L</$SIGNATURE>.

$CODEREF will I<always> be called in list context. $CODEREF B<MUST> return
the number of arguments that $SIGNATURE indicates, or you’ll get an error
(possibly an unhelpful one).

If $CODEREF throws, the exception is C<warn()>ed, and a generic
callback-failed error is thrown to the C<link_function()> caller.

=head3 WASM Context in Callbacks

Your callback may need to reference either the wasm3 runtime or module.
When doing this, be sure to use a C<weaken()>ed copy (cf. L<Scalar::Util>)
of that object, or you’ll leak memory (and eventually get a C<warn()>ing
about it).

For example:

    my $weak_runtime = $runtime;
    Scalar::Util::weaken($weak_runtime);

    $module->link_function(
        mymodule => myfuncname => 'v(ii)',
        sub {
            my ($buf_p, $buflen) = @_;

            my $buf = $weak_runtime->get_memory($buf_p, $buflen);

            # Now do something cool with $buf.

            return;
        },
    );

The distribution’s F<t/wasi_pp.t> shows this technique in action.

(An alternative design would be to pass a special context object
to every callback, but the weak-reference approach is more efficient.)

=head3 $SIGNATURE

$SIGNATURE is wasm3’s own convention to describe a function’s inputs &
outputs. As of this writing wasm3’s documentation doesn’t describe it very
well, so we’ll describe it here.

The format is C<$RETURNS($ARGS)>, where $RETURNS and $ARGS are both either:

=over

=item * C<v>, to indicate empty (C<v> meaning “void”)

=item * … a sequence of one or more of: C<i> (i32), C<I> (i64), C<f> (f32),
C<F>, (f64)

=back

Space characters are ignored.

For example: C<v(if)> indicates a function that takes i32 and f32 as
arguments and returns nothing.

=head2 $obj = I<OBJ>->link_wasi_default()

A quick helper to link L<WASI|https://wasi.dev> includes via
wasm3’s L<uvwasi|https://github.com/nodejs/uvwasi> integration.

This uses wasm3’s built-in WASI defaults, e.g., STDIN becomes WASI file
descriptor 0.

=head2 $obj = I<OBJ>->link_wasi( %OPTS )

(NB: Only available if uvwasi is your WASI backend; see L<Wasm::Wasm3>
for details.)

Like C<link_wasi_default()> but takes a list of key/value pairs that
offer the following controls:

%OPTS are:

=over

=item * C<in>, C<out>, C<err> - File handles to the WASI input, output,
and error streams. Defaults are file descriptors 0, 1, and 2 respectively.

=item * C<env> - A reference to an array of key/value byte-string pairs
to pass as the WASI environment.

=item * C<preopen> - A reference to a hash of WASI paths to system/real
paths.

B<IMPORTANT:> WASI paths are character strings, while system paths are
B<byte> strings. The discrepancy arises because WASI paths are always
character strings, while Perl treats all system paths as byte strings
(even on OSes like Windows where paths are character strings).

So if, for example, you have directory F</tmp/føø> that you’ll access
in WASI as F</épée>, your code might look thus:

    preopen => {
        do { use utf8; '/épée' } => do { no utf8; '/tmp/føø' },
    },

=back

=cut

our $WASI_MODULE_STR;

sub link_wasi_default {
    my ($self) = @_;

    return $self->_perl_link_wasi('_link_wasi_default');
}

sub link_wasi {
    my ($self, @args) = @_;

    return $self->_perl_link_wasi('_link_wasi', @args);
}

sub _perl_link_wasi {
    my ($self, $fn, @args) = @_;

    if ($WASI_MODULE_STR) {
        if ($WASI_MODULE_STR ne "$self") {
            die "$self: WASI is already linked! ($WASI_MODULE_STR)";
        }
    }
    else {
        $self->$fn(@args);
        $WASI_MODULE_STR = "$self";
    }

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    $self->_destroy_xs();

    if ($WASI_MODULE_STR && ($WASI_MODULE_STR eq "$self")) {
        undef $WASI_MODULE_STR;
    }

    return;
}

1;
