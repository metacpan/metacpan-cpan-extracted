package Wasm::Wasmtime::Func;

use strict;
use warnings;
use Ref::Util qw( is_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Trap;
use Convert::Binary::C;
use Sub::Install;
use Carp ();
use overload
  '&{}' => sub { my $self = shift; sub { $self->call(@_) } },
  bool => sub { 1 },
  fallback => 1;
  ;

# ABSTRACT: Wasmtime function class
our $VERSION = '0.04'; # VERSION


$ffi_prefix = 'wasm_func_';
$ffi->type('opaque' => 'wasm_func_t');

# CBC is probably not how we want to do this long term, but atm
# Platypus does not support Unions or arrays of records so.
my $cbc = Convert::Binary::C->new(
  Alignment => 8,
  LongSize => 8, # CBC does not apparently use the native alignment by default *sigh*
);
$cbc->parse(<<'END');
typedef struct wasm_val_t {
  unsigned char kind;
  union {
    signed int i32;
    signed long i64;
    float f32;
    double f64;
    void *anyref;
    void *funcref;
  } of;
} wasm_val_t;
typedef wasm_val_t wasm_val_vec_t[];
END


$ffi->attach( new => ['wasm_store_t', 'wasm_functype_t', '(opaque,opaque)->opaque'] => 'wasm_func_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner, $wrapper, $store);
  if(is_ref $_[0])
  {
    $store = shift;
    my($functype, $cb) = is_plain_arrayref($_[0])
       ? (Wasm::Wasmtime::FuncType->new($_[0], $_[1]), $_[2])
       : @_;

    my @param_types = map { $_->kind } $functype->params;
    my $param_string = "record(@{[ $cbc->sizeof('wasm_val_t') * scalar(@param_types) ]})*";
    my @result_types = map { [ $_->kind, $_->kind_num ] } $functype->results;
    my $result_string = "string(@{[ $cbc->sizeof('wasm_val_t') * scalar(@result_types) ]})*";

    $wrapper = $ffi->closure(sub {
      my($params, $results) = @_;

      my @args = @param_types > 0 ? (do {
        my @copy = @param_types;
        map { $_->{of}->{shift @copy} } @{ $cbc->unpack('wasm_val_vec_t', $ffi->cast('opaque' => $param_string, $params)) };
      }) : ();

      local $@ = '';
      my @ret = eval {
        $cb->(@args);
      };
      if(my $error = $@)
      {
        my $trap = Wasm::Wasmtime::Trap->new($store, "$error\0");
        return delete $trap->{ptr};
      }
      else
      {
        if(@result_types > 0)
        {
          my @ret2 = map {
            {
              kind => $_->[1],
              of => {
                $_->[0] => shift @ret,
              }
            }
          } @result_types;
          my $packed = $cbc->pack('wasm_val_vec_t', \@ret2);
          my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
          $ffi->function( memcpy => ['opaque','string','size_t'] => 'opaque' )->call($results, $packed, length($packed));
        }
        return undef;
      }
    });
    $ptr = $xsub->($store->{ptr}, $functype->{ptr}, $wrapper);
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr     => $ptr,
    owner   => $owner,
    wrapper => $wrapper,
    store   => $store,
  }, $class;
});


$ffi->attach( call => ['wasm_func_t', 'string', 'string'] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $self = shift;
  my @args = @_;
  my $args = $cbc->pack('wasm_val_vec_t', [map {
    my $valtype = $_;
    {
      kind => $valtype->kind_num,
      of => {
        $valtype->kind => shift @args,
      },
    }
  } $self->type->params]);
  my $results = $cbc->pack('wasm_val_vec_t', [map { { } } $self->type->results]);
  my $trap = $xsub->($self->{ptr}, $args, $results);
  if($trap)
  {
    $trap = Wasm::Wasmtime::Trap->new($trap);
    my $message = $trap->message;
    Carp::croak("trap in wasm function call: $message");
  }
  my @valtypes = $self->type->results;
  return unless @valtypes;
  my @results = map {
    my $valtype = shift @valtypes;
    $_->{of}->{$valtype->kind};
  } @{ $cbc->unpack('wasm_val_vec_t', $results) };
  wantarray ? @results : $results[0]; ## no critic (Freenode::Wantarray)
});


sub attach
{
  my $self    = shift;
  my $package = @_ == 2 ? shift : caller;
  my $name    = shift;
  if($package->can($name))
  {
    Carp::carp("attaching ${package}::$name replaces existing subroutine");
  }
  Sub::Install::reinstall_sub({
    code => sub { $self->call(@_) },
    into => $package,
    as   => $name,
  });
}


$ffi->attach( type => ['wasm_func_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::FuncType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});


$ffi->attach( param_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});


$ffi->attach( result_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});


# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_func_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::Extern;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::Extern->new($ptr, $self->{owner} || $self);
});

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Func - Wasmtime function class

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 # Call a wasm function from Perl
 use Wasm::Wasmtime;
 
 my $module = Wasm::Wasmtime::Module->new( wat => q{
   (module
    (func (export "add") (param i32 i32) (result i32)
      local.get 0
      local.get 1
      i32.add)
   )
 });
 
 my $instance = Wasm::Wasmtime::Instance->new($module);
 my $add = $instance->get_export('add')->as_func;
 print $add->call(1,2), "\n";  # 3

 # Call Perl from Wasm
 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $module = Wasm::Wasmtime::Module->new( $store, wat => q{
   (module
     (func $hello (import "" "hello"))
     (func (export "run") (call $hello))
   )
 });
 
 my $hello = Wasm::Wasmtime::Func->new(
   $store,
   Wasm::Wasmtime::FuncType->new([],[]),
   sub { print "hello world!\n" },
 );
 
 my $instance = Wasm::Wasmtime::Instance->new($module, [$hello]);
 $instance->get_export("run")->as_func->call(); # hello world!

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a function, and can be used to either call a WebAssembly function from
Perl, or to create a callback for calling a Perl function from WebAssembly.

=head1 CONSTRUCTOR

=head2 new

 my $func = Wasm::Wasmtime::Func->new(
   $store,               # Wasm::Wasmtime::Store
   \@params, \@results,  # array reference for function signature
   \&callback,           # code reference
 );
 my $func = Wasm::Wasmtime::Func->new(
   $store,      # Wasm::Wasmtime::Store
   $functype,   # Wasm::Wasmtime::FuncType
   \&callback,  # code reference
 );

Creates a function instance, which can be used to call Perl from WebAssembly.
See L<Wasm::Wasmtime::FuncType> for details on how to specify the function
signature.

=head1 METHODS

=head2 call

 my @results = $func->call(@params);
 my @results = $func->(@params);

Calls the function instance.  This can be used to call either Perl functions created
with C<new> as above, or call WebAssembly functions from Perl.  As a convenience you
can call the function by using the function instance like a code reference.

If there is a trap during the call it will throw an exception.  In list context all
of the results are returned as a list.  In scalar context just the first result (if
any) is returned.

=head2 attach

 $func->attach($name);
 $func->attach($package, $name);

Attach the function as a Perl subroutine.  If C<$package> is not specified, then the
caller's package will be used.

=head2 type

 my $functype = $func->type;

Returns the L<Wasm::Wasmtime::FuncType> instance which includes the function signature.

=head2 param_arity

 my $num = $func->param_arity;

Returns the number of arguments the function takes.

=head2 result_arity

 my $num = $func->param_arity;

Returns the number of results the function returns.

=head2 as_extern

 my $extern = $func->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this function.

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
