package Wasm::Wasmtime::Instance::Exports;

use strict;
use warnings;
use 5.008004;
use Carp ();
use Hash::Util ();
use overload
  '%{}' => sub {
    my $self   = shift;
    my $instance = $$self;
    $instance->{exports};
  },
  '@{}' => sub {
    my $self = shift;
    my $instance = $$self;
    my @exports = $instance->_exports;
    Internals::SvREADONLY @exports, 1;
    Internals::SvREADONLY $exports[$_], 1 for 0..$#exports;
    \@exports;
  },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Wasmtime instance exports class
our $VERSION = '0.23'; # VERSION


sub new
{
  my($class, $instance) = @_;

  $instance->{exports} ||= do {
    my @exports = $instance->_exports;
    my @module_exports   = @{ $instance->module->exports };
    my %exports;
    foreach my $i (0..$#exports)
    {
      $exports{$module_exports[$i]->name} = $exports[$i];
    }
    Hash::Util::lock_hash(%exports);
    \%exports;
  };

  bless \$instance, $class;
}

sub can
{
  my($self, $name) = @_;
  my $instance = $$self;
  exists $instance->{exports}->{$name}
    ? sub { $self->$name }
    : $self->SUPER::can($name);
}

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;

  my $name = $AUTOLOAD;
  $name=~ s/^.*:://;

  my $instance = $$self;
  Carp::croak("no export $name") unless exists $instance->{exports}->{$name};
  $instance->{exports}->{$name};
}

sub DESTROY
{
  # needed because of AUTOLOAD
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Instance::Exports - Wasmtime instance exports class

=head1 VERSION

version 0.23

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $module = Wasm::Wasmtime::Module->new( $store->engine, wat => q{
   (module
    (func (export "add") (param i32 i32) (result i32)
      local.get 0
      local.get 1
      i32.add)
   )
 });
 
 my $instance = Wasm::Wasmtime::Instance->new($module, $store);
 
 my $exports = $instance->exports;
 
 print $exports->add->call(1,2),   "\n";  # 3
 print $exports->{add}->call(1,2), "\n";  # 3
 print $exports->[0]->call(1,2),   "\n";  # 3

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the exports from an instance.  It can be used in a number of different ways.

=over 4

=item autoload methods

 my $foo = $instance->exports->foo;

Calling the name of an export as a method returns the L<Wasm::Wasmtime::ExternType> for the
export.

=item As a hash reference

 my $foo = $instance->exports->{foo};

Using the Exports class as a hash reference allows you to get exports that might clash with
common Perl methods like C<new>, C<can>, C<DESTROY>, etc.  The L<Wasm::Wasmtime::ExternType>
will be returned.

=item An array reference

 my $foo = $instance->exports->[0];

This will give you the list of exports in the order that they are defined in your WebAssembly.
The object returned is a L<Wasm::Wasmtime::ExportType>, which is essentially a name and a
L<Wasm::Wasmtime::ExternType>.

=back

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
