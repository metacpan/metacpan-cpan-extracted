package Wasm::Trap;

use strict;
use warnings;
use Wasm::Wasmtime::Trap;
use 5.008004;

# ABSTRACT: Wasm trap class
our $VERSION = '0.19'; # VERSION


sub new
{
  my(undef, $message) = @_;
  require Wasm;
  my $linker = Wasm::_linker();
  Wasm::Wasmtime::Trap->new($linker->store, $message);
}

push @Wasm::Wasmtime::Trap::ISA, __PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Trap - Wasm trap class

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 use Wasm::Trap;
 
 my $trap = Wasm::Trap->new(
   "something went bump in the night\0",
 );

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

This class represents a trap thrown into or out of WebAssembly. It
can be thrown back to WebAssembly via die in a Perl function called
from WebAssembly.  It can be caught in Perl via eval around WebAssembly.

The actual implementation may be a super or subclass.  As of this
writing it is a simple wrapper around L<Wasm::Wasmtime::Trap>, but
relying on that is undefined behavior.  In order to catch a trap from
WebAssembly, use this class name like so:

 use Ref::Util qw( is_blessed_ref );

 local $@ = '';
 eval {
   web_assembly_func();
 };
 if(my $error = $@)
 {
   if(is_blessed_ref $error && $error->isa('Wasm::Trap'))
   {
     my $message = $error->message;
     my $exit_value = $error->exit_value;
     print "message    = $message\n";
     print "exit_value = $exit_value\n";
   }
 }

To throw from Perl:

 use Wasm::Trap;

 sub perl_from_wasm
 {
   die Wasm::Trap->new("diagnostic\0");
 }

=head1 CONSTRUCTORS

=head2 new

 my $trap = Wasm::Trap->new($message);

This creates a new trap object.

=head1 METHODS

=head2 message

 my $message = $trap->message;

Returns the trap message as a string.

=head2 exit_status

 my $status = $trap->exit_status;

If the trap was triggered by an C<exit> call, this will return the exist status code.
If it wasn't triggered by an C<exit> call it will return C<undef>.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
