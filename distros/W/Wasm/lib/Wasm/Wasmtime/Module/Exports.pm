package Wasm::Wasmtime::Module::Exports;

use strict;
use warnings;
use 5.008004;
use Carp ();
use Hash::Util ();
use overload
  '%{}' => sub {
    my $self   = shift;
    my $module = $$self;
    $module->{exports};
  },
  '@{}' => sub {
    my $self = shift;
    my $module = $$self;
    my @exports = $module->_exports;
    Internals::SvREADONLY @exports, 1;
    Internals::SvREADONLY $exports[$_], 1 for 0..$#exports;
    \@exports;
  },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Wasmtime module exports class
our $VERSION = '0.21'; # VERSION


sub new
{
  my($class, $module) = @_;

  $module->{exports} ||= do {
    my @exports = $module->_exports;
    my %exports;
    foreach my $export (@exports)
    {
      $exports{$export->name} = $export->type;
    }
    Hash::Util::lock_hash(%exports);
    \%exports;
  };

  bless \$module, $class;
}

sub can
{
  my($self, $name) = @_;
  my $module = $$self;
  exists $module->{exports}->{$name}
    ? sub { $self->$name }
    : $self->SUPER::can($name);
}

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;

  my $name = $AUTOLOAD;
  $name=~ s/^.*:://;

  my $module = $$self;
  Carp::croak("no export $name") unless exists $module->{exports}->{$name};
  $module->{exports}->{$name};
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

Wasm::Wasmtime::Module::Exports - Wasmtime module exports class

=head1 VERSION

version 0.21

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $module = Wasm::Wasmtime::Module->new( wat => q{
   (module
    (func (export "add") (param i32 i32) (result i32)
      local.get 0
      local.get 1
      i32.add)
   )
 });
 
 my $exports = $module->exports;   # Wasm::Wasmtime::Module::Exports
 
 my $type1      = $exports->add;   # this is the Wasm::Wasmtime::FuncType for add
 my $type2      = $exports->{add}; # this is also the Wasm::Wasmtime::FuncType for add
 my $exporttype = $exports->[0];   # this is the Wasm::Wasmtime::ExportType for add

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the exports from a module.  It can be used in a number of different ways.

=over 4

=item autoload methods

 my $foo = $module->exports->foo;

Calling the name of an export as a method returns the L<Wasm::Wasmtime::ExternType> for the
export.

=item As a hash reference

 my $foo = $module->exports->{foo};

Using the Exports class as a hash reference allows you to get exports that might clash with
common Perl methods like C<new>, C<can>, C<DESTROY>, etc.  The L<Wasm::Wasmtime::ExternType>
will be returned.

=item An array reference

 my $foo = $module->exports->[0];

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

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
