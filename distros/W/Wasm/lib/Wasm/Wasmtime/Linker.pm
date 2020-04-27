package Wasm::Wasmtime::Linker;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Instance;
use Wasm::Wasmtime::WasiInstance;
use Wasm::Wasmtime::Trap;
use Ref::Util qw( is_blessed_ref );
use Carp ();

# ABSTRACT: Wasmtime linker class
our $VERSION = '0.06'; # VERSION


$ffi_prefix = 'wasmtime_linker_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_linker_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_store_t'] => 'wasmtime_linker_t' => sub {
  my($xsub, $class, $store) = @_;
  my $self = $xsub->($store);
  $self->{store} = $store;
  $self;
});


$ffi->attach( allow_shadowing => [ 'wasmtime_linker_t', 'bool' ] => sub {
  my($xsub, $self, $value) = @_;
  $xsub->($self, $value);
  $self;
});


if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( define => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'wasm_extern_t'] => 'wasmtime_error_t' => sub {
    my $xsub   = shift;
    my $self   = shift;
    my $module = Wasm::Wasmtime::ByteVec->new(shift);
    my $name   = Wasm::Wasmtime::ByteVec->new(shift);
    my $extern = shift;

    if(ref($extern) eq 'Wasm::Wasmtime::Extern')
    {
      # nothing, okay.
    }
    elsif(is_blessed_ref($extern) && $extern->can('as_extern'))
    {
      $extern = $extern->as_extern;
    }
    else
    {
      Carp::croak("not an extern: $extern");
    }

    my $error = $xsub->($self, $module, $name, $extern);
    Carp::croak($error->message) if $error;
    $self;
  });
}
else
{
  $ffi->attach( define => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'wasm_extern_t'] => 'bool' => sub {
    my $xsub   = shift;
    my $self   = shift;
    my $module = Wasm::Wasmtime::ByteVec->new(shift);
    my $name   = Wasm::Wasmtime::ByteVec->new(shift);
    my $extern = shift;

    if(ref($extern) eq 'Wasm::Wasmtime::Extern')
    {
      # nothing, okay.
    }
    elsif(is_blessed_ref($extern) && $extern->can('as_extern'))
    {
      $extern = $extern->as_extern;
    }
    else
    {
      Carp::croak("not an extern: $extern");
    }

    my $ret = $xsub->($self, $module, $name, $extern);
    unless($ret)
    {
      Carp::croak("Unknown error in define");
    }

    $self;
  });
}


if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( define_wasi => ['wasmtime_linker_t', 'wasi_instance_t'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $wasi) = @_;
    my $error = $xsub->($self, $wasi);
    Carp::croak($error->message) if $error;
    $self;
  });
}
else
{
  $ffi->attach( define_wasi => ['wasmtime_linker_t', 'wasi_instance_t'] => 'bool' => sub {
    my($xsub, $self, $wasi) = @_;
    my $ret = $xsub->($self, $wasi);
    Carp::croak("Unknown error in define_wasi") unless $ret;
    $self;
  });
}


if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( define_instance => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_instance_t'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $name, $instance) = @_;
    my $vname = Wasm::Wasmtime::ByteVec->new($name);
    my $error = $xsub->($self, $vname, $instance);
    Carp::croak($error->message) if $error;
    $self;
  });
}
else
{
  $ffi->attach( define_instance => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_instance_t'] => 'bool' => sub {
    my($xsub, $self, $name, $instance) = @_;
    my $vname = Wasm::Wasmtime::ByteVec->new($name);
    my $ret = $xsub->($self, $vname, $instance);
    Carp::croak("Unknown error in define_instance") unless $ret;
    $self;
  });
}


if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( instantiate => ['wasmtime_linker_t','wasm_module_t','opaque*','opaque*'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $module) = @_;
    my $trap;
    my $ptr;
    my $error = $xsub->($self, $module, \$ptr, \$trap);
    Carp::croak($error->message) if $error;
    if($trap)
    {
      $trap = Wasm::Wasmtime::Trap->new($trap);
      Carp::croak($trap->message);
    }
    elsif($ptr)
    {
      return Wasm::Wasmtime::Instance->new(
        $module, $ptr,
      );
    }
    else
    {
      Carp::croak("unknown instantiate error");
    }
  });
}
else
{
  $ffi->attach( instantiate => ['wasmtime_linker_t','wasm_module_t','opaque*' ] => 'opaque' => sub {
    my($xsub, $self, $module) = @_;
    my $trap;
    my $ptr = $xsub->($self, $module, \$trap);
    if($trap)
    {
      $trap = Wasm::Wasmtime::Trap->new($trap);
      Carp::croak($trap->message);
    }
    elsif($ptr)
    {
      return Wasm::Wasmtime::Instance->new(
        $module, $ptr,
      );
    }
    else
    {
      Carp::croak("unknown instantiate error");
    }
  });
}

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Linker - Wasmtime linker class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store  = Wasm::Wasmtime::Store->new;
 my $linker = Wasm::Wasmtime::Linker->new($store);
 
 # Instanciate and define a WASI instance
 my $wasi = Wasm::Wasmtime::WasiInstance->new(
   $store,
   "wasi_snapshot_preview1",
   Wasm::Wasmtime::WasiConfig
     ->new
     ->inherit_stdout
 );
 $linker->define_wasi($wasi);
 
 # Create a logger module + instance
 my $logger = $linker->instantiate(
   Wasm::Wasmtime::Module->new(
     $store,
     wat => q{
       (module
         (type $fd_write_ty (func (param i32 i32 i32 i32) (result i32)))
         (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (type $fd_write_ty)))
 
         (func (export "log") (param i32 i32)
           ;; store the pointer in the first iovec field
           i32.const 4
           local.get 0
           i32.store
 
           ;; store the length in the first iovec field
           i32.const 4
           local.get 1
           i32.store offset=4
 
           ;; call the `fd_write` import
           i32.const 1     ;; stdout fd
           i32.const 4     ;; iovs start
           i32.const 1     ;; number of iovs
           i32.const 0     ;; where to write nwritten bytes
           call $fd_write
           drop
         )
 
         (memory (export "memory") 2)
         (global (export "memory_offset") i32 (i32.const 65536))
       )
     },
   )
 );
 $linker->define_instance("logger", $logger);
 
 # Create a caller module + instance
 my $caller = $linker->instantiate(
   Wasm::Wasmtime::Module->new(
     $store,
     wat => q{
       (module
         (import "logger" "log" (func $log (param i32 i32)))
         (import "logger" "memory" (memory 1))
         (import "logger" "memory_offset" (global $offset i32))
 
         (func (export "run")
           ;; Our `data` segment initialized our imported memory, so let's print the
           ;; string there now.
           global.get $offset
           i32.const 14
           call $log
         )
 
         (data (global.get $offset) "Hello, world!\n")
       )
     },
   ),
 );
 $caller->get_export('run')->as_func->();

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly linker.

=head1 CONSTRUCTOR

=head2 new

 my $linker = Wasm::Wasmtime::Linker->new(
   $store,        # Wasm::Wasmtime::Store
 );

Create a new WebAssembly linker object.

=head1 METHODS

=head2 allow_shadowing

 $linker->allow_shadowing($bool);

Sets the allow shadowing property.

=head2 define

 $linker->define(
   $module,
   $name,
   $extern,    # Wasm::Wasmtime::Extern
 );

Define the given extern.  You can use a func, global, table or memory object in its place
and this method will get the extern for you.

=head2 define_wasi

 $linker->define_wasi(
   $wasi,   # Wasm::Wasmtime::WasiInstance
 );

Define WASI instance.

=head2 define_instance

 $linker->define_instance(
   $instance,   # Wasm::Wasmtime::Instance
 );

Define WebAssembly instance.

=head2 instantiate

 my $instance = $linker->instantiate(
   $module,
 );

Instantiate the module using the linker.  Returns the new L<Wasm::Wasmtime::Instance> object.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
