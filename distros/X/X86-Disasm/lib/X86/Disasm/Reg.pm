package X86::Disasm::Reg;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $x86_reg_type = {	# NOTE: these may be ORed together 
	0x00001 => "reg_gen",	 # general purpose
	0x00002 => "reg_in",	 # incoming args, ala RISC
	0x00004 => "reg_out",	 # args to calls, ala RISC
	0x00008 => "reg_local",	 # local vars, ala RISC
	0x00010 => "reg_fpu",	 # FPU data register
	0x00020 => "reg_seg",	 # segment register
	0x00040 => "reg_simd",	 # SIMD/MMX reg
	0x00080 => "reg_sys",	 # restricted/system register
	0x00100 => "reg_sp",	 # stack pointer
	0x00200 => "reg_fp",	 # frame pointer
	0x00400 => "reg_pc",	 # program counter
	0x00800 => "reg_retaddr",	 # return addr for func
	0x01000 => "reg_cond",	 # condition code / flags
	0x02000 => "reg_zero",	 # zero register, ala RISC
	0x04000 => "reg_ret",	 # return value
	0x10000 => "reg_src",	 # array/rep source
	0x20000 => "reg_dest",	 # array/rep destination
	0x40000 => "reg_count",	 # array/rep/loop counter
};

sub set {
  my $src_ptr = shift;

  my $dest_ptr = {};
  $dest_ptr->{name}  = $src_ptr->name;
  $dest_ptr->{type}  = set_types($src_ptr->type);
  $dest_ptr->{size}  = $src_ptr->size;
  $dest_ptr->{id}    = $src_ptr->id;
  $dest_ptr->{alias} = $src_ptr->alias;
  $dest_ptr->{shift} = $src_ptr->shift;

  return $dest_ptr;
}

sub set_types {
  my $type = shift;

  return X86::Disasm::set_generic($type, $x86_reg_type);
}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use X86::Disasm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
$x86_reg_type
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

X86::Disasm::Reg - Perl extension to wrap registers in libdisasm - an X86 Disassembler

=head1 SYNOPSIS

  use X86::Disasm::Reg ':all';

=head1 DESCRIPTION

X86::Disasm::Reg provides a Perl interface to the registers in the C X86 disassembler library, libdisasm. See http://bastard.sourceforge.net/libdisasm.html

=head2 EXPORT

None by default.

  our %EXPORT_TAGS = ( 'all' => [ qw(
  $x86_reg_type
  ) ] );

=head1 SEE ALSO

  X86::Disasm
  X86::Disasm::Insn
  X86::Disasm::Op

If you use Debian and install libdisasm0 and libdisasm-dev
then the following are a useful supplement to this documentation.

/usr/include/libdis.h

/usr/share/doc/libdisasm-dev/libdisasm.txt.gz

The latest version of this Perl module is available from https://sourceforge.net/projects/x86disasm/

=head1 AUTHOR

Bob Wilkinson, E<lt>bob@fourtheye.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Bob Wilkinson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
