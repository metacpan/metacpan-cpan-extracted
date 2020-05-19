package Wasm::Wasmtime::Func;

use strict;
use warnings;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_blessed_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Trap;
use FFI::C::Util qw( set_array_count );
use Sub::Install;
use Carp ();
use constant is_func => 1;
use constant kind => 'func';
use overload
  '&{}' => sub { my $self = shift; sub { $self->call(@_) } },
  bool => sub { 1 },
  fallback => 1;
  ;

# ABSTRACT: Wasmtime function class
our $VERSION = '0.10'; # VERSION


$ffi_prefix = 'wasm_func_';
$ffi->load_custom_type('::PtrObject' => 'wasm_func_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_store_t', 'wasm_functype_t', '(opaque,opaque)->opaque'] => 'wasm_func_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(is_blessed_ref $_[0] && $_[0]->isa('Wasm::Wasmtime::Store'))
  {
    my $store = shift;
    my($functype, $cb) = is_plain_arrayref($_[0])
       ? (Wasm::Wasmtime::FuncType->new($_[0], $_[1]), $_[2])
       : @_;

    my $param_arity  = scalar $functype->params;
    my $result_arity = scalar$functype->results;

    my $wrapper = $ffi->closure(sub {
      my($params, $results) = @_;

      my @args = $param_arity ? do {
        my $args = Wasm::Wasmtime::ValVec->from_c($params);
        set_array_count($args, $param_arity);
        $args->to_perl;
      } : ();

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
        if($result_arity)
        {
          $results = Wasm::Wasmtime::ValVec->from_c($results);
          my @types = $functype->results;
          foreach my $i (0..$#types)
          {
            my $kind = $types[$i]->kind;
            my $result = $results->get($i);
            $result->kind($types[$i]->kind_num);
            $result->of->$kind(shift @ret);
          }
        }
        return undef;
      }
    });
    my $self = $xsub->($store, $functype, $wrapper);
    $self->{store} = $store;
    $self->{wrapper} = $wrapper;
    return $self;
  }
  else
  {
    my ($ptr, $owner) = @_;
    bless {
      ptr     => $ptr,
      owner   => $owner,
    }, $class;
  }
});


$ffi->attach( call => ['wasm_func_t', 'wasm_val_vec_t', 'wasm_val_vec_t'] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $self = shift;
  my $args = Wasm::Wasmtime::ValVec->from_perl(\@_, [$self->type->params]);
  my $results = $self->result_arity ? Wasm::Wasmtime::ValVec->new($self->result_arity) : undef;

  my $trap = $xsub->($self, $args, $results);

  if($trap)
  {
    my $message = $trap->message;
    Carp::croak("trap in wasm function call: $message");
  }
  return unless defined $results;
  my @results = $results->to_perl;
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
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});


$ffi->attach( param_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});


$ffi->attach( result_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

__PACKAGE__->_cast(0);
_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Func - Wasmtime function class

=head1 VERSION

version 0.10

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
 my $add = $instance->exports->add;
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
 $instance->exports->run->call(); # hello world!

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
