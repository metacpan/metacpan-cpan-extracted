package Wasm::Wasmer::Store;

use Wasm::Wasmer;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Store

=head1 SYNOPSIS

    my $store = Wasm::Wasmer::Store->new();

For more fine-grained control over compilation and performance
you can pass options like, e.g.:

    my $store = Wasm::Wasmer::Store->new(
        compiler => 'llvm',
    );

    my $func = $store->create_function(
        code    => sub { ... },
        params  => [ Wasm::Wasmer::WASM_I32, Wasm::Wasmer::WASM_I32 ],
        results => [ Wasm::Wasmer::WASM_F64 ],
    );

See L<Wasm::Wasmer::Module> for what you can do with $store.

=cut

=head1 DESCRIPTION

This class represents a WASM “store” and “engine” pair.
See Wasmer’s
L<store|https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/store>
and
L<engine|https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/engine>
modules for a bit more context.

=cut

=head1 METHODS

=head2 $obj = I<CLASS>->new( %OPTS )

Instantiates this class, which wraps Wasmer C<wasm_engine_t> and
C<wasm_store_t> instances.

This accepts the arguments that in C would go into the C<wasm_config_t>.
Currently that includes:

=over

=item * C<compiler> - C<cranelift>, C<llvm>, or C<singlepass>

=back

NB: Your Wasmer may not support all of the above.

=head2 $wasi = I<CLASS>->create_wasi( %OPTS )

Creates a L<Wasm::Wasmer::WASI> instance. Give $wasi to the appropriate
method of L<Wasm::Wasmer::Module>.

The %OPTS correspond to L<Wasmer’s corresponding interface|https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/wasi/index.html>. All are optional:

=over

=item * C<name> - defaults to empty-string

=item * C<args> - arrayref

=item * C<env> - arrayref of key-value pairs

=item * C<stdin> - either undef (default) or C<inherit>

=item * C<stdout> - either C<capture> (default) or C<inherit>

=item * C<stderr> - either C<capture> (default) or C<inherit>

=item * C<preopen_dirs> - arrayref of real paths

=item * C<map_dirs> - hashref of WASI-alias to real-path

=back

=cut

my %WASI_EXPECT_OPT = map { ($_ => 1) } (
    'name',
    'args',
    'stdin', 'stdout', 'stderr',
    'env',
    'preopen_dirs',
    'map_dirs',
);

my %WASI_STDIN_OPTS = map { $_ => 1 } ('inherit');
my %WASI_STDOUT_STDERR_OPTS = map { $_ => 1 } ('inherit', 'capture');

sub create_wasi {
    my ($self, %opts) = @_;

    my $name = $opts{'name'};
    if (defined $name) {
        if (-1 != index($name, "\0")) {
            Carp::croak "Name ($name) must not include NUL bytes!";
        }
    }
    else {
        $name = q<>;
    }

    my @extra = sort grep { !$WASI_EXPECT_OPT{$_} } keys %opts;
    die "Unknown: @extra" if @extra;

    if (my $args_ar = $opts{'args'}) {
        my @bad = grep { -1 != index($_, "\0") } @$args_ar;
        Carp::croak "Arguments (@bad) must not include NUL bytes!" if @bad;
    }

    my $v;

    $v = $opts{'stdin'};
    if (defined $v && !$WASI_STDIN_OPTS{$v}) {
        Carp::croak "Bad stdin: $v";
    }

    for my $opt ('stdout', 'stderr') {
        $v = $opts{$opt};

        if (defined $v && !$WASI_STDOUT_STDERR_OPTS{$v}) {
            Carp::croak "Bad $opt: $v";
        }
    }

    if (my $env_ar = $opts{'env'}) {
        Carp::croak "Uneven environment list!" if @$env_ar % 2;

        my @bad = grep { -1 != index($_, "\0") } @$env_ar;
        Carp::croak "Environment (@bad) must not include NUL bytes!" if @bad;
    }

    my $preopen_dirs_ar = $opts{'preopen_dirs'};
    my $map_dirs_hr = $opts{'map_dirs'};

    my @all_paths = (
        ($preopen_dirs_ar ? @$preopen_dirs_ar : ()),
        ($map_dirs_hr ? %$map_dirs_hr : ()),
    );

    my @bad_paths = grep { -1 != index($_, "\0") } @all_paths;
    if (@bad_paths) {
        require List::Util;
        @bad_paths = sort( List::Util::uniq(@bad_paths) );

        Carp::croak "Paths (@bad_paths) must not include NUL bytes!";
    }

    return $self->_create_wasi($name, \%opts);
}

#----------------------------------------------------------------------

=head2 IMPORTS

To import a global or memory into WebAssembly you first need to create
a Perl object to represent that WebAssembly object.

The following create WebAssembly objects in the store and return Perl objects
that interact with those WebAssembly objects.

(NB: The Perl objects do I<not> trigger destruction of the WebAssembly objects
when they go away. Only destroying the store achieves that.)

=head3 $obj = I<OBJ>->create_memory( %OPTS )

Creates a WebAssembly memory and a Perl L<Wasm::Wasmer::Memory> instance
to interface with it. %OPTS are:

=over

=item * C<initial> (required)

=item * C<maximum>

=back

The equivalent JavaScript interface is C<WebAssembly.Memory()>; see L<its documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Memory/Memory> for more details.

=head3 Globals

Rather than a single method, this class exposes separate methods to create
globals of different types:

=over

=item * I<OBJ>->create_i32_const($VALUE)

=item * I<OBJ>->create_i32_mut($VALUE)

=item * I<OBJ>->create_i64_const($VALUE)

=item * I<OBJ>->create_i64_mut($VALUE)

=item * I<OBJ>->create_f32_const($VALUE)

=item * I<OBJ>->create_f32_mut($VALUE)

=item * I<OBJ>->create_f64_const($VALUE)

=item * I<OBJ>->create_f64_mut($VALUE)

=back

Each of the above creates a WebAssembly global and a Perl
L<Wasm::Wasmer::Global> instance to interface with it.

=head3 $obj = I<OBJ>->create_function( %OPTS )

Creates a L<Wasm::Wasmer::Function> instance. %OPTS are:

=over

=item * C<code> - (required) A Perl code reference.

=item * C<params> - An array reference of Perl constants (e.g.,
Wasm::Wasmer::WASM_I32) that indicates the function inputs. Defaults
to empty.

=item * C<results> - Like C<params> but for the outputs.

=back

=head3 Tables

(Unsupported for now.)

=cut

use Wasm::Wasmer;

1;
