package X86::Disasm::Op;

use 5.008000;
use strict;
use warnings;

use X86::Disasm::Reg ':all';

require Exporter;

our @ISA = qw(Exporter);

our $x86_op_type = {	# mutually exclusive 
	0 => "op_unused",	 # empty/unused operand: should never occur
	1 => "op_register",	 # CPU register
	2 => "op_immediate",	 # Immediate Value
	3 => "op_relative_near",	 # Relative offset from IP
	4 => "op_relative_far",	 # Relative offset from IP
	5 => "op_absolute",	 # Absolute address (ptr16:32)
	6 => "op_expression",	 # Address expression (scale/index/base/disp)
	7 => "op_offset",	 # Offset from start of segment (m32)
};

our $x86_op_datatype = {	# these use Intel's lame terminology 
	1 => "op_byte",	 # 1 byte integer
	2 => "op_word",	 # 2 byte integer
	3 => "op_dword",	 # 4 byte integer
	4 => "op_qword",	 # 8 byte integer
	5 => "op_dqword",	 # 16 byte integer
	6 => "op_sreal",	 # 4 byte real (single real)
	7 => "op_dreal",	 # 8 byte real (double real)
	8 => "op_extreal",	 # 10 byte real (extended real)
	9 => "op_bcd",	 # 10 byte binary-coded decimal
	10 => "op_ssimd",	 # 16 byte : 4 packed single FP (SIMD, MMX)
	11 => "op_dsimd",	 # 16 byte : 2 packed double FP (SIMD, MMX)
	12 => "op_sssimd",	 # 4 byte : scalar single FP (SIMD, MMX)
	13 => "op_sdsimd",	 # 8 byte : scalar double FP (SIMD, MMX)
	14 => "op_descr32",	 # 6 byte Intel descriptor 2:4
	15 => "op_descr16",	 # 4 byte Intel descriptor 2:2
	16 => "op_pdescr32",	 # 6 byte Intel pseudo-descriptor 32:16
	17 => "op_pdescr16",	 # 6 byte Intel pseudo-descriptor 8:24:16
	18 => "op_bounds16",	 # signed 16:16 lower:upper bounds
	19 => "op_bounds32",	 # signed 32:32 lower:upper bounds
	20 => "op_fpuenv16",	 # 14 byte FPU control/environment data
	21 => "op_fpuenv32",	 # 28 byte FPU control/environment data
	22 => "op_fpustate16",	 # 94 byte FPU state (env & reg stack)
	23 => "op_fpustate32",	 # 108 byte FPU state (env & reg stack)
	24 => "op_fpregset",	 # 512 bytes: register set
	25 => "op_fpreg",	 # FPU register
	0xFF => "op_none",	 # operand without a datatype (INVLPG)
};

our $x86_op_access = {	# ORed together 
	1 => "op_read",
	2 => "op_write",
	4 => "op_execute",
};

our $x86_op_flags = {	# ORed together, but segs are mutually exclusive 
	1 => "op_signed",	 # signed integer
	2 => "op_string",	 # possible string or array
	4 => "op_constant",	 # symbolic constant
	8 => "op_pointer",	 # operand points to a memory address
	0x010 => "op_sysref",	 # operand is a syscall number
	0x020 => "op_implied",	 # operand is implicit in the insn
	0x40 => "op_hardcode",	 # operand is hardcoded in insn definition
	0x100 => "op_es_seg",	 # ES segment override
	0x200 => "op_cs_seg",	 # CS segment override
	0x300 => "op_ss_seg",	 # SS segment override
	0x400 => "op_ds_seg",	 # DS segment override
	0x500 => "op_fs_seg",	 # FS segment override
	0x600 => "op_gs_seg",	 # GS segment override
};

sub _union {
  my $operand = shift;

  my $datatype = $operand->datatype;
  my $flags = $operand->flags;

  my $union;
  if (defined $x86_op_datatype->{$datatype}) {
    if (defined $x86_op_flags->{$flags}) {
      if ($x86_op_flags->{$flags} && 1) { # signed
        if ($x86_op_datatype->{$datatype} eq 'op_byte') {
          $union = $operand->sbyte;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_word') {
          $union = $operand->sword;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_dword') {
          $union = $operand->sdword;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_qword') {
          $union = $operand->sqword;
        }
      } else {
        if ($x86_op_datatype->{$datatype} eq 'op_byte') {
          $union = $operand->byte;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_word') {
          $union = $operand->word;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_dword') {
          $union = $operand->dword;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_qword') {
          $union = $operand->qword;
        } elsif ($x86_op_datatype->{$datatype} eq 'op_dqword') {
          $union = $operand->dqword;
        }
      }
    }
    if ($x86_op_datatype->{$datatype} eq 'op_sreal') {
      $union = $operand->sreal;
    } elsif ($x86_op_datatype->{$datatype} eq 'op_double') {
      $union = $operand->dreal;
    } elsif ($x86_op_datatype->{$datatype} eq 'op_extreal') {
      $union = $operand->extreal;
    } elsif ($x86_op_datatype->{$datatype} eq 'op_bcd') {
      $union = $operand->bcd;
    } elsif ($x86_op_datatype->{$datatype} eq 'op_simd') {
      $union = $operand->simd;
    } elsif ($x86_op_datatype->{$datatype} eq 'op_fpuenv') {
      $union = $operand->fpuenv;
    }
  }
  return $union;
}

sub set_access {
  my $access = shift;

  return X86::Disasm::set_generic($access, $x86_op_access);
}

sub set_flags {
  my $flags = shift;

  return X86::Disasm::set_generic($flags, $x86_op_flags);
}

sub set {
  my $operand = shift;

  my $op_hash;
  my $type = $operand->type;
  $op_hash->{type} = $x86_op_type->{$operand->type};
  $op_hash->{datatype} = $x86_op_datatype->{$operand->datatype};
  $op_hash->{access} = set_access($operand->access);
  $op_hash->{flags} = set_flags($operand->flags);
  $op_hash->{union} = X86::Disasm::Op::_union($operand);
  $op_hash->{offset} = sprintf("0x%x", $operand->offset);
  if ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_register')) {
    $op_hash->{reg} = X86::Disasm::Reg::set($operand->reg);
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_expression')) {
    my $expression = $operand->expression;
    $op_hash->{expression} = {};
    $op_hash->{expression}->{scale} = $expression->scale;
    $op_hash->{expression}->{index} = X86::Disasm::Reg::set($expression->index);
    $op_hash->{expression}->{base} = X86::Disasm::Reg::set($expression->base);
    $op_hash->{expression}->{disp} = sprintf("0x%x", $expression->disp);
    $op_hash->{expression}->{disp_sign} = ord($expression->disp_sign);
    $op_hash->{expression}->{disp_size} = ord($expression->disp_size);
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_immediate')) {
#warn "IMMEDIATE";
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_relative_near')) {
    $op_hash->{relative_near} = ord($operand->relative_near);
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_relative_far')) {
    $op_hash->{relative_farg} = ord($operand->relative_near);
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_absolute')) {
    my $absolute = $operand->absolute;
    $op_hash->{absolute} = {};
    $op_hash->{absolute}->{segment} = $absolute->segment;
    $op_hash->{absolute}->{off16} = $absolute->off16;
    $op_hash->{absolute}->{off32} = $absolute->off32;
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_expression')) {
#warn "EXPRESSION";
  } elsif ((defined $x86_op_type->{$type}) and ($x86_op_type->{$type} eq 'op_offset')) {
#warn "OFFSET";
  } elsif (defined $x86_op_type->{$type}) {
warn "TYPE is ",$x86_op_type->{$type};
  }
  return $op_hash;
}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use X86::Disasm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
$x86_op_type
$x86_op_datatype
$x86_op_access
$x86_op_flags
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

X86::Disasm::Op - Perl extension to wrap operands from libdisasm

=head1 SYNOPSIS

  use X86::Disasm::Op ':all';

=head1 DESCRIPTION

X86::Disasm::Op provides a Perl interface to the operands in the C X86 disassembler library, libdisasm. See http://bastard.sourceforge.net/libdisasm.html

=head2 EXPORT

None by default.

  our %EXPORT_TAGS = ( 'all' => [ qw(
  $x86_op_type
  $x86_op_datatype
  $x86_op_access
  $x86_op_flags
  ) ] );

=head1 SEE ALSO

  X86::Disasm
  X86::Disasm::Insn
  X86::Disasm::Reg

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
