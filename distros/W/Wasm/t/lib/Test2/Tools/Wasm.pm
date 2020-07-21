package Test2::Tools::Wasm;

use strict;
use warnings;
use 5.008004;
use Ref::Util qw( is_plain_arrayref );
use Test2::API qw( context );
use base qw( Exporter );

our @EXPORT = qw( wasm_store wasm_module_ok wasm_instance_ok wasm_func_ok );

sub _module
{
  my $name = shift;
  my $wat = shift;

  require Wasm::Wasmtime::Module;

  my $ctx = context();

  local $@ = '';
  my $store = eval { wasm_store() };
  return $ctx->fail_and_release($name, "error creating store object", "$@") if $@;

  my $module = eval { Wasm::Wasmtime::Module->new($store, wat => $wat) };
  return $ctx->fail_and_release($name, "error loading module", "$@") if $@;

  $ctx->release;
  $module;
}

sub _instance
{
  my $module = _module(@_);
  my $name = shift;
  my $imports = is_plain_arrayref($_[-1]) ? pop : undef;

  return 0 unless $module;

  require Wasm::Wasmtime::Instance;

  my $ctx = context();

  my $instance = eval { Wasm::Wasmtime::Instance->new($module, wasm_store(), $imports) };
  return $ctx->fail_and_release($name, "error creating instance", "$@") if $@;

  $ctx->release;
  $instance;
}

sub wasm_module_ok ($;$)
{
  my($wat,$name) = @_;

  $name ||= "module ok";

  my $ctx = context();
  my $module = _module($name, $wat);

  if($module)
  {
    $ctx->pass_and_release($name);
    return $module;
  }
  else
  {
    $ctx->release;
    return 0;
  }
}

sub wasm_instance_ok ($$;$)
{
  my($imports, $wat, $name) = @_;

  $name ||= "instance ok";

  my $ctx = context();
  my $instance = _instance($name, $wat, $imports);

  if($instance)
  {
    $ctx->pass_and_release($name);
    return $instance;
  }
  else
  {
    $ctx->release;
  }
}

sub wasm_func_ok ($$;$)
{
  my $f = shift;
  my $wat = shift;
  my $name = shift;

  require Wasm::Wasmtime::Func;

  my $ctx = context();
  $name ||= "function $f";
  my $instance = _instance($name, $wat);

  unless($instance)
  {
    $ctx->release;
    return 0;
  }

  my $extern = eval { $instance->exports->{$f} };
  return $ctx->fail_and_release($name, "no export $f") unless $extern;

  my $kind = $extern->kind;
  return $ctx->fail_and_release($name, "$f is a $kind, expected a func") unless $kind eq 'func';

  $ctx->pass_and_release($name);

  return $extern;
}

my $store;

sub wasm_store
{
  $store ||= do {
    my $config = Wasm::Wasmtime::Config->new;
    $config->wasm_multi_value(1);
    my $engine = Wasm::Wasmtime::Engine->new($config);
    Wasm::Wasmtime::Store->new($engine);
  };
}

1;
