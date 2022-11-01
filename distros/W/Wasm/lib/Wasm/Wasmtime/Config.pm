package Wasm::Wasmtime::Config;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Global configuration for Wasm::Wasmtime::Engine
our $VERSION = '0.22'; # VERSION


$ffi_prefix = 'wasm_config_';
$ffi->load_custom_type('::PtrObject' => 'wasm_config_t' => __PACKAGE__);


$ffi->attach( new => [] => 'wasm_config_t' );

_generate_destroy();


foreach my $prop (qw(
  cranelift_debug_verifier
  debug_info
  interruptable
  wasm_bulk_memory
  wasm_reference_types
  wasm_multi_value
  wasm_simd
  wasm_threads
))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'wasm_config_t', 'bool' ] => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}

foreach my $prop (qw(
  max_wasm_stack
))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'wasm_config_t', 'size_t' ] => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}


outer:
foreach my $prop (qw( static_memory_maximum_size static_memory_guard_size dynamic_memory_guard_size ))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'wasm_config_t', 'uint64' ] => 'void' => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}


my %strategy = (
  auto      => 0,
  cranelift => 1,
  lightbeam => 2,
);

$ffi->attach( [ 'wasmtime_config_strategy_set' => 'strategy' ] => [ 'wasm_config_t', 'uint8' ] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $value) = @_;
  if(defined $strategy{$value})
  {
    if(my $error = $xsub->($self, $strategy{$value}))
    {
      Carp::croak($error->message);
    }
  }
  else
  {
    Carp::croak("unknown strategy: $value");
  }
  $self;
});


my %cranelift_opt_level = (
  none => 0,
  speed => 1,
  speed_and_size => 2,
);

$ffi->attach( ['wasmtime_config_cranelift_opt_level_set' => 'cranelift_opt_level' ] => ['wasm_config_t', 'uint8' ] => sub {
  my($xsub, $self, $value) = @_;
  if(defined $cranelift_opt_level{$value})
  {
    $xsub->($self, $cranelift_opt_level{$value});
  }
  else
  {
    Carp::croak("unknown cranelift_opt_level: $value");
  }
  $self;
});


my %profiler = (
  none    => 0,
  jitdump => 1,
  vtune   => 2,
);

$ffi->attach( ['wasmtime_config_profiler_set' => 'profiler' ] => ['wasm_config_t', 'uint8'] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $value) = @_;
  if(defined $profiler{$value})
  {
    if(my $error = $xsub->($self, $profiler{$value}))
    {
      Carp::croak($error->message);
    }
  }
  else
  {
    Carp::croak("unknown profiler: $value");
  }
  $self;
});


$ffi->attach( [ 'wasmtime_config_cache_config_load' => 'cache_config_load' ] => [ 'wasm_config_t', 'string' ] => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("undef passed in as cache config") unless defined $value;
  $xsub->($self, $value);
  $self;
});

$ffi->attach( [ 'wasmtime_config_cache_config_load' => 'cache_config_default' ] => [ 'wasm_config_t', 'string' ] => sub {
  my($xsub, $self) = @_;
  $xsub->($self, undef);
  $self;
});


if(_v0_23_0())
{
  $ffi->attach( ['wasmtime_config_consume_fuel_set' => 'consume_fuel' ] => [ 'wasm_config_t', 'bool' ] => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
  $ffi->attach( ['wasmtime_config_max_instances_set' => 'max_instances' ] => [ 'wasm_config_t', 'size_t' ] => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}
else
{
  *consume_fuel = sub {
    Carp::croak("unimplemented, upgrade wasmtime to 0.23.0");
  };
  *max_instances = sub {
    Carp::croak("unimplemented, upgrade wasmtime to 0.23.0");
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Config - Global configuration for Wasm::Wasmtime::Engine

=head1 VERSION

version 0.22

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $config = Wasm::Wasmtime::Config->new;
 $config->wasm_multi_value(1);
 my $engine = Wasm::Wasmtime::Engine->new($config);

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class contains the configuration for L<Wasm::Wasmtime::Engine>
class.  Each instance of the config class should only be used once.

=head1 CONSTRUCTOR

=head2 new

 my $config = Wasm::Wasmtime::Config->new;

Create a new instance of the config class.

=head1 METHODS

=head2 debug_info

 $config->debug_info($bool);

Configures whether DWARF debug information is emitted for the generated
code. This can improve profiling and the debugging experience.

=head2 interruptable

 $config->interruptable($bool);

Configures whether functions and loops will be interruptable.

=head2 max_wasm_stack

 $config->max_wasm_stack($size);

Configures the maximum amount of native stack space available to executing WebAssembly code

=head2 wasm_threads

 $config->wasm_threads($bool);

Configures whether the wasm threads proposal is enabled

L<https://github.com/webassembly/threads>

=head2 wasm_reference_types

 $config->wasm_reference_types($bool);

Configures whether the wasm reference types proposal is enabled.

L<https://github.com/webassembly/reference-types>

=head2 wasm_simd

 $config->wasm_simd($bool);

Configures whether the wasm SIMD proposal is enabled.

L<https://github.com/webassembly/simd>

=head2 wasm_bulk_memory

 $config->wasm_bulk_memory($bool);

Configures whether the wasm bulk memory proposal is enabled.

L<https://github.com/webassembly/bulk-memory>

=head2 wasm_multi_value

 $config->wasm_multi_value($bool)

Configures whether the wasm multi value proposal is enabled.

L<https://github.com/webassembly/multi-value>

=head2 static_memory_maximum_size

 $config->static_memory_maximum_size($size);

Configure the static memory maximum size.

=head2 static_memory_guard_size

 $config->static_memory_guard_size($size);

Configure the static memory guard size.

=head2 dynamic_memory_guard_size

 $config->dynamic_memory_guard_size($size);

Configure the dynamic memory guard size.

=head2 strategy

 $config->strategy($strategy);

Configures the compilation strategy used for wasm code.

Will throw an exception if the selected strategy is not supported on your platform.

Acceptable values for C<$strategy> are:

=over 4

=item C<auto>

=item C<cranelift>

=item C<lightbeam>

=back

=head2 cranelift_opt_level

 $config->cranelift_opt_level($level);

Configure the cranelift optimization level:

Acceptable values for C<$level> are:

=over 4

=item C<none>

=item C<speed>

=item C<speed_and_size>

=back

=head2 profiler

 $config->profiler($profiler);

Configure the profiler.

Will throw an exception if the selected profiler is not supported on your platform.

Acceptable values for C<$profiler> are:

=over 4

=item C<none>

=item C<jitdump>

=item C<vtune>

=back

=head2 cache_config_load

 $config->cache_config_load($toml_config);

Path to the cache configuration TOML file.

=head2 cache_config_default

 $config->cache_config_default;

Enable the default caching configuration.

=head2 consume_fuel

 $config->consume_fuel($bool);

Whether or not fuel is enabled for generated code.

=head2 max_instances

 $confog->max_instances($size);

Configures the maximum number of instances that can be created.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
