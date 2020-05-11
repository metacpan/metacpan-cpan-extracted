package Wasm::Wasmtime::WasiConfig;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: WASI Configuration
our $VERSION = '0.09'; # VERSION


$ffi_prefix = 'wasi_config_';
$ffi->load_custom_type('::PtrObject' => 'wasi_config_t' => __PACKAGE__);


sub _wrapper
{
  my $xsub = shift;
  my $self = shift;
  $xsub->($self, @_);
  $self;
}

$ffi->attach( new             => []                                  => 'wasi_config_t' );
$ffi->attach( set_stdin_file  => ['wasi_config_t','string']          => 'void', \&_wrapper );
$ffi->attach( set_stdout_file => ['wasi_config_t','string']          => 'void', \&_wrapper );
$ffi->attach( set_stderr_file => ['wasi_config_t','string']          => 'void', \&_wrapper );
$ffi->attach( preopen_dir     => ['wasi_config_t','string','string'] => 'void', \&_wrapper );

foreach my $name (qw( argv env stdin stdout stderr ))
{
  $ffi->attach( "inherit_$name" => ['wasi_config_t'], \&_wrapper );
}

$ffi->attach( set_argv => ['wasi_config_t', 'int', 'string[]'] => sub {
  my($xsub, $self, @argv) = @_;
  $xsub->($self, scalar(@argv), \@argv);
  $self;
});

$ffi->attach( set_env => ['wasi_config_t','int','string[]','string[]'] => sub {
  my($xsub, $self, %env) = @_;
  my @names;
  my @values;
  foreach my $name (keys %env)
  {
    push @names,  $name;
    push @values, $env{$name};
  }
  $xsub->($self, scalar(@names), \@names, \@values);
  $self;
});

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::WasiConfig - WASI Configuration

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $config = Wasm::Wasmtime::WasiConfig->new;
 
 # inherit everything, and provide access to the
 # host filesystem under /host (yikes!)
 $config->inherit_argv
        ->inherit_env
        ->inherit_stdin
        ->inherit_stdout
        ->inherit_stderr
        ->preopen_dir("/", "/host");
 
 my $wasi = Wasm::Wasmtime::WasiInstance->new(
   $store,
   "wasi_snapshot_preview1",
   $config,
 );

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the WebAssembly System Interface (WASI) configuration.  For WebAssembly WASI
is the equivalent to the part of libc that interfaces with the system.  As such it allows you to
configure if and how the WebAssembly program has access to program arguments, environment,
standard streams and file system directories.

=head1 CONSTRUCTOR

=head2 new

 my $config = Wasm::Wasmtime::WasiConfig->new;

Creates a new WASI config object.

=head1 METHODS

=head2 set_argv

 $config->set_argv(@argv);

Sets the program arguments.

=head2 inherit_argv

 $config->inherit_argv;

Configures WASI to use the host program's arguments.

=head2 set_env

 $config->set_env(\%env);

Sets the program environment variables.

=head2 inherit_env

 $config->inherit_env;

Configures WASI to use the host program's environment variables.

=head2 set_stdin_file

 $config->set_stdin_file($path);

Sets the program standard input to use the given file path.

=head2 inherit_stdin

 $config->inherit_stdin;

Configures WASI to use the host program's standard input.

=head2 set_stdout_file

 $config->set_stdout_file($path);

Sets the program standard output to use the given file path.

=head2 inherit_stdout

 $config->inherit_stdout;

Configures WASI to use the host program's standard output.

=head2 set_stderr_file

 $config->set_stderr_file($path);

Sets the program standard error to use the given file path.

=head2 inherit_stderr

 $config->inherit_stderr;

Configures WASI to use the host program's standard error.

=head2 preopen_dir

 $config->preopen_dir($host_path, $guest_path);

Pre-open the given directory from the host's C<$host_path> to the guest's C<$guest_path>.

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
