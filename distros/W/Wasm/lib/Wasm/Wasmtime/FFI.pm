package Wasm::Wasmtime::FFI;

use strict;
use warnings;
use 5.008004;
use FFI::C 0.05;
use FFI::C::Util ();
use FFI::Platypus 1.26;
use FFI::Platypus::Buffer ();
use FFI::CheckLib 0.26 qw( find_lib );
use Sub::Install;
use Devel::GlobalDestruction ();
use constant ();
use base qw( Exporter );

# ABSTRACT: Private class for Wasm::Wasmtime
our $VERSION = '0.23'; # VERSION


our @EXPORT = qw( $ffi $ffi_prefix _generate_vec_class _generate_destroy );

sub _lib
{
  return $ENV{WASM_WASMTIME_FFI} if defined $ENV{WASM_WASMTIME_FFI};
  my @symbols = (
    # 0.19.0
    'wasmtime_func_as_funcref',
    # 0.20.0 / 0.21.0
    'wasmtime_module_serialize',
    'wasmtime_module_deserialize',
    'wasmtime_store_gc',
    ## 0.23.0
    'wasmtime_config_consume_fuel_set',
    #'wasmtime_config_max_instances_set',  # removed in 0.27.0
  );
  my $lib = find_lib lib => 'wasmtime', symbol => \@symbols;
  return $lib if $lib;
  $lib = find_lib lib => 'wasmtime', alien => 'Alien::wasmtime', symbol => \@symbols;
  return $lib if $lib;
  die 'unable to find wasmtime 0.19.0 or better';
}

our $ffi_prefix = 'wasm_';
our $ffi = FFI::Platypus->new( api => 1 );
FFI::C->ffi($ffi);
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

{ package Wasm::Wasmtime::Error;

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

{ package Wasm::Wasmtime::Val::Of;
  FFI::C->union(of_t => [
    i32     => 'sint32',
    i64     => 'sint64',
    f32     => 'float',
    f64     => 'double',
    anyref  => 'opaque',
    funcref => 'opaque',
  ]);
}

my %kind = (
  0   => 'i32',
  1   => 'i64',
  2   => 'f32',
  3   => 'f64',
  128 => 'anyref',
  129 => 'funcref',
);

{ package Wasm::Wasmtime::Val;
  FFI::C->struct(wasm_val_t => [
    kind => 'uint8',
    of   => 'of_t',
  ]);

  sub to_perl
  {
    my $self = shift;
    my $kind = $kind{$self->kind};
    $self->of->$kind;
  }
}

{ package Wasm::Wasmtime::ValVec;
  FFI::C->array(wasm_val_vec_t => [
    'wasm_val_t',
  ], { nullable => 1 });

  sub to_perl
  {
    my $self = shift;
    map { $_->to_perl } @$self
  }

  {
    package Wasm::Wasmtime::ValVecWrapper;
    FFI::C->struct(wasm_val_vec_wrapper_t => [
      size => 'size_t',
      data => 'opaque',
    ]);

  }

  $ffi->attach_cast('from_c', 'opaque', 'wasm_val_vec_wrapper_t', sub {
    my($xsub, undef, $ptr) = @_;
    my $wrapper = $xsub->($ptr);
    my $inner = $ffi->cast('opaque', 'wasm_val_vec_t', $wrapper->data);
    FFI::C::Util::set_array_count($inner, $wrapper->size);
    return $inner;
  });

  sub from_perl
  {
    my($class, $vals, $types) = @_;
    @$vals ? $class->new([map { { kind => $_->kind_num, of => { $_->kind => shift @$vals } } } @$types]) : undef;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::FFI - Private class for Wasm::Wasmtime

=head1 VERSION

version 0.23

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
