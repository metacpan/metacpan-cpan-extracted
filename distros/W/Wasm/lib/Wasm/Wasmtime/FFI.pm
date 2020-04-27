package Wasm::Wasmtime::FFI;

use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::Platypus::Buffer ();
use FFI::CheckLib 0.26 qw( find_lib );
use Sub::Install;
use Devel::GlobalDestruction ();
use base qw( Exporter );

# ABSTRACT: Private class for Wasm::Wasmtime
our $VERSION = '0.06'; # VERSION


our @EXPORT = qw( $ffi $ffi_prefix _generate_vec_class _generate_destroy );

sub _lib
{
  find_lib lib => 'wasmtime', alien => 'Alien::wasmtime';
}

our $ffi_prefix = 'wasm_';
our $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(__PACKAGE__->_lib);
$ffi->mangler(sub {
  my $name = shift;
  return $name if $name =~ /^(wasm|wasmtime|wasi)_/;
  return $ffi_prefix . $name;
});

{ package Wasm::Wasmtime::Vec;
  use FFI::Platypus::Record;
  record_layout_1(
    $ffi,
    size_t => 'size',
    opaque => 'data',
  );
}

{ package Wasm::Wasmtime::ByteVec;
  use base qw( Wasm::Wasmtime::Vec );

  $ffi->type('record(Wasm::Wasmtime::ByteVec)' => 'wasm_byte_vec_t');
  $ffi_prefix = 'wasm_byte_vec_';

  sub new
  {
    my $class = shift;
    if(@_ == 1)
    {
      my($data, $size) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
      return $class->SUPER::new(
        size => $size,
        data => $data,
      );
    }
    else
    {
      return $class->SUPER::new(@_);
    }
  }

  sub get
  {
    my($self) = @_;
    FFI::Platypus::Buffer::buffer_to_scalar($self->data, $self->size);
  }

  $ffi->attach( delete => ['wasm_byte_vec_t*'] => 'void' );
}

sub _generic_vec_delete
{
  my($xsub, $self) = @_;
  $xsub->($self);
  # cannot use SUPER::DELETE because we aren't
  # in the right package.
  Wasm::Wasmtime::Vec::DESTROY($self);
}

sub _generate_vec_class
{
  my %opts = @_;
  my($class) = caller;
  my $type = $class;
  $type =~ s/^.*:://;
  my $v_type = "wasm_@{[ lc $type ]}_vec_t";
  my $vclass  = "Wasm::Wasmtime::${type}Vec";
  my $prefix = "wasm_@{[ lc $type ]}_vec";

  Sub::Install::install_sub({
    code => sub {
      my($self) = @_;
      my $size = $self->size;
      return () if $size == 0;
      my $ptrs = $ffi->cast('opaque', "opaque[$size]", $self->data);
      map { $class->new($_, $self) } @$ptrs;
    },
    into => $vclass,
    as   => 'to_list',
  });

  {
    no strict 'refs';
    @{join '::', $vclass, 'ISA'} = ('Wasm::Wasmtime::Vec');
  }
  $ffi_prefix = "${prefix}_";
  $ffi->type("record($vclass)" => $v_type);
  $ffi->attach( [ delete => join('::', $vclass, 'DESTROY') ] => ["$v_type*"] => \&_generic_vec_delete)
    if !defined($opts{delete}) || $opts{delete};

}

sub _wrapper_destroy
{
  my($xsub, $self) = @_;
  return if Devel::GlobalDestruction::in_global_destruction();
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self);
    delete $self->{ptr};
  }
}

sub _generate_destroy
{
  my $caller = caller;
  my $type = lc $caller;
  if($type =~ /::linker$/)
  {
    $type = 'wasmtime_linker_t';
  }
  elsif($type =~ /::wasi/)
  {
    $type =~ s/^.*::wasi(.*)$/wasi_${1}_t/g;
  }
  else
  {
    $type =~ s/^.*:://;
    $type = "wasm_${type}_t";
  }
  $ffi->attach( [ delete => join('::', $caller, 'DESTROY') ] => [ $type ] => \&_wrapper_destroy);
}

if($ffi->find_symbol('wasmtime_error_message'))
{
  package Wasm::Wasmtime::Error;

  $ffi_prefix = 'wasmtime_error_';
  $ffi->custom_type(
    wasmtime_error_t => {
      native_type => 'opaque',
      native_to_perl => sub {
        defined $_[0] ? __PACKAGE__->new($_[0]) : undef
      },
    },
  );

  Sub::Install::install_sub({
    code => sub {
      my($class, $ptr, $owner) = @_;
      bless {
        ptr   => $ptr,
        owner => $owner,
      }, $class;
    },
    into => __PACKAGE__,
    as   => 'new',
  });

  $ffi->attach( message => ['wasmtime_error_t','wasm_byte_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $message = Wasm::Wasmtime::ByteVec->new;
    $xsub->($self->{ptr}, $message);
    my $ret = $message->get;
    $message->delete;
    $ret;
  });

  $ffi->attach( [ delete => "DESTROY" ] => ['wasmtime_error_t'] => sub {
    my($xsub, $self) = @_;
    if(defined $self->{ptr} && !defined $self->{owner})
    {
      $xsub->($self->{ptr});
    }
  });
}

{ package Wasm::Wasmtime::CBC;

  use Convert::Binary::C;
  use base qw( Exporter );

  our @EXPORT_OK = qw( perl_to_wasm wasm_to_perl wasm_allocate wasm_type wasm_memcpy );

  $INC{'Wasm/Wasmtime/CBC.pm'} = __FILE__;

  # CBC is probably not how we want to do this long term, but atm
  # Platypus does not support Unions or arrays of records so.
  our $cbc = Convert::Binary::C->new(
    Alignment => 8,
    LongSize => 8, # CBC does not apparently use the native alignment by default *sigh*
  );
  $cbc->parse(q{
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
  });

  sub perl_to_wasm
  {
    my $vals = shift;
    my $types = shift;
    $cbc->pack('wasm_val_vec_t', [map {
      {
        kind => $_->kind_num,
        of => {
          $_->kind => shift @$vals,
        }
      }
    } @$types]);
  }

  my %kind = (
    0   => 'i32',
    1   => 'i64',
    2   => 'f32',
    3   => 'f64',
    128 => 'anyref',
    129 => 'funcref',
  );

  sub wasm_to_perl
  {
    my $vals = shift;
    map {
      $_->{of}->{$kind{$_->{kind}}};
    } @{ $cbc->unpack('wasm_val_vec_t', $vals) };
  }

  my $size = $cbc->sizeof('wasm_val_t');

  sub wasm_allocate
  {
    my $count = shift;
    $count ? "\0" x ($count * $size) : undef;
  }

  sub wasm_type
  {
    my $count = shift || 0;
    my $name = "x_wasm_" . $count;
    eval { $ffi->type($name) };
    if($@)
    {
      $ffi->type(
        $count > 0 ? 'string(' . ($count * $size) . ')*' : 'opaque',
        $name,
      );
    }
    $name;
  }

  my $ffi2 = FFI::Platypus->new( api => 1, lib => [undef] );
  $ffi2->attach( [ memcpy => 'wasm_memcpy' ] => ['opaque','string','size_t'] => 'opaque' => sub {
    my $xsub = shift;
    $xsub->($_[0], $_[1], length $_[1]);
  });

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::FFI - Private class for Wasm::Wasmtime

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 $ perldoc Wasm

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This is a private class used internally by L<Wasm::Wasmtime> classes.

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
