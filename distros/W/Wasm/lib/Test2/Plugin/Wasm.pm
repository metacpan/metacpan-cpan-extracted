package Test2::Plugin::Wasm;

use strict;
use warnings;
use 5.008004;
use Test2::API qw( context );
use Test2::Mock;
use Data::Dumper ();
use FFI::C::Util qw( c_to_perl );

# ABSTRACT: Test2 plugin for WebAssembly extensions
our $VERSION = '0.17'; # VERSION


sub get_virtual_memory_limit
{
  my $ctx = context();
  if($^O eq 'linux')
  {
    require FFI::Platypus;
    require FFI::C::StructDef;
    my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
    my $rlimit;
    if($ffi->find_symbol('getrlimit'))
    {
      $ctx->note("linux : found getrlimit") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
      $rlimit = FFI::C::StructDef->new(
        $ffi,
        name => 'rlimit',
        members => [
          rlim_cur => 'uint32',
          rlim_max => 'uint32',
        ],
      )->create;
      my $ret = $ffi->function( getrlimit => [ 'int', 'rlimit' ] => 'int' )->call(9,$rlimit);
      if($ret == -1)
      {
        $ctx->note("getrlimit failed: $!") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
        undef $rlimit;
      }
    }
    if(defined $rlimit)
    {
      my $cur = $rlimit->rlim_cur;
      $ctx->note("rlimit = " . Data::Dumper->new(
        [c_to_perl($rlimit)])->Terse(1)->Indent(0)->Dump
      ) if $ENV{TEST2_PLUGIN_WASM_DEBUG};
      $ctx->release;
      $cur = 0 if $cur == 0xffffffff;
      return $cur;
    }
  }
  $ctx->release;
  return undef;
}

our $config_mock;

sub import
{
  my $ctx = context();
  my $vm_limit = get_virtual_memory_limit();
  if($vm_limit)
  {
    require Wasm::Wasmtime::Config;
    $config_mock = Test2::Mock->new(
      class => 'Wasm::Wasmtime::Config',
      around => [
        new => sub {
          my $orig = shift;
          my $self = shift->$orig(@_);
          my $ctx = context();
          $ctx->note("virtual memory address limit detected, try to set limits to zero");
          $self->static_memory_maximum_size(0);
          $self->static_memory_guard_size(0);
          $self->dynamic_memory_guard_size(0);
          $ctx->release;
          $self;
        },
      ],
    );
  }
  $ctx->release;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::Wasm - Test2 plugin for WebAssembly extensions

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 use Test2::Plugin::Wasm;

=head1 DESCRIPTION

This L<Test2> plugin is for testing L<Wasm> extensions.  Right now, it sets C<wasmtime> resource
limits to work on systems with a low virtual memory address limit.  It may do other thing that
make sense for all L<Wasm> extensions running in a testing context in the future.

=head1 SEE ALSO

=over 4

=item L<Wasm>

Write Perl extensions using WebAssembly.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
