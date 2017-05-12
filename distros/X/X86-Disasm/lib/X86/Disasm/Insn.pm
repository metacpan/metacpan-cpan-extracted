package X86::Disasm::Insn;

use 5.008000;
use strict;
use warnings;

use X86::Disasm::Op ':all';

require Exporter;

our @ISA = qw(Exporter);

our $x86_insn_group = {
	0 => "insn_none",	 # invalid instruction
	1 => "insn_controlflow",
	2 => "insn_arithmetic",
	3 => "insn_logic",
	4 => "insn_stack",
	5 => "insn_comparison",
	6 => "insn_move",
	7 => "insn_string",
	8 => "insn_bit_manip",
	9 => "insn_flag_manip",
	10 => "insn_fpu",
	13 => "insn_interrupt",
	14 => "insn_system",
	15 => "insn_other",
};

our $x86_insn_type = {
	0 => "insn_invalid",	 # invalid instruction
	0x1001 => "insn_jmp",
	0x1002 => "insn_jcc",
	0x1003 => "insn_call",
	0x1004 => "insn_callcc",
	0x1005 => "insn_return",
	0x2001 => "insn_add",
	0x2002 => "insn_sub",
	0x2003 => "insn_mul",
	0x2004 => "insn_div",
	0x2005 => "insn_inc",
	0x2006 => "insn_dec",
	0x2007 => "insn_shl",
	0x2008 => "insn_shr",
	0x2009 => "insn_rol",
	0x200A => "insn_ror",
	0x3001 => "insn_and",
	0x3002 => "insn_or",
	0x3003 => "insn_xor",
	0x3004 => "insn_not",
	0x3005 => "insn_neg",
	0x4001 => "insn_push",
	0x4002 => "insn_pop",
	0x4003 => "insn_pushregs",
	0x4004 => "insn_popregs",
	0x4005 => "insn_pushflags",
	0x4006 => "insn_popflags",
	0x4007 => "insn_enter",
	0x4008 => "insn_leave",
	0x5001 => "insn_test",
	0x5002 => "insn_cmp",
	0x6001 => "insn_mov",	 # move
	0x6002 => "insn_movcc",	 # conditional move
	0x6003 => "insn_xchg",	 # exchange
	0x6004 => "insn_xchgcc",	 # conditional exchange
	0x7001 => "insn_strcmp",
	0x7002 => "insn_strload",
	0x7003 => "insn_strmov",
	0x7004 => "insn_strstore",
	0x7005 => "insn_translate",	 # xlat
	0x8001 => "insn_bittest",
	0x8002 => "insn_bitset",
	0x8003 => "insn_bitclear",
	0x9001 => "insn_clear_carry",
	0x9002 => "insn_clear_zero",
	0x9003 => "insn_clear_oflow",
	0x9004 => "insn_clear_dir",
	0x9005 => "insn_clear_sign",
	0x9006 => "insn_clear_parity",
	0x9007 => "insn_set_carry",
	0x9008 => "insn_set_zero",
	0x9009 => "insn_set_oflow",
	0x900A => "insn_set_dir",
	0x900B => "insn_set_sign",
	0x900C => "insn_set_parity",
	0x9010 => "insn_tog_carry",
	0x9020 => "insn_tog_zero",
	0x9030 => "insn_tog_oflow",
	0x9040 => "insn_tog_dir",
	0x9050 => "insn_tog_sign",
	0x9060 => "insn_tog_parity",
	0xA001 => "insn_fmov",
	0xA002 => "insn_fmovcc",
	0xA003 => "insn_fneg",
	0xA004 => "insn_fabs",
	0xA005 => "insn_fadd",
	0xA006 => "insn_fsub",
	0xA007 => "insn_fmul",
	0xA008 => "insn_fdiv",
	0xA009 => "insn_fsqrt",
	0xA00A => "insn_fcmp",
	0xA00C => "insn_fcos",
	0xA00D => "insn_fldpi",
	0xA00E => "insn_fldz",
	0xA00F => "insn_ftan",
	0xA010 => "insn_fsine",
	0xA020 => "insn_fsys",
	0xD001 => "insn_int",
	0xD002 => "insn_intcc",	 # not present in x86 ISA
	0xD003 => "insn_iret",
	0xD004 => "insn_bound",
	0xD005 => "insn_debug",
	0xD006 => "insn_trace",
	0xD007 => "insn_invalid_op",
	0xD008 => "insn_oflow",
	0xE001 => "insn_halt",
	0xE002 => "insn_in",	 # input from port/bus
	0xE003 => "insn_out",	 # output to port/bus
	0xE004 => "insn_cpuid",
	0xF001 => "insn_nop",
	0xF002 => "insn_bcdconv",	 # convert to or from BCD
	0xF003 => "insn_szconv",	 # change size of operand
};

our $x86_insn_note = {
	1 => "insn_note_ring0",	 # Only available in ring 0
	2 => "insn_note_smm",	 # "" in System Management Mode
	4 => "insn_note_serial",	 # Serializing instruction
	8 => "insn_note_nonswap",	 # Does not swap arguments in att-style formatting
	16 => "insn_note_nosuffix",	 # Does not have size suffix in att-style formatting
};

our $x86_flag_status = {
	0x1 => "insn_carry_set",	 # CF
	0x2 => "insn_zero_set",	 # ZF
	0x4 => "insn_oflow_set",	 # OF
	0x8 => "insn_dir_set",	 # DF
	0x10 => "insn_sign_set",	 # SF
	0x20 => "insn_parity_set",	 # PF
	0x40 => "insn_carry_or_zero_set",
	0x80 => "insn_zero_set_or_sign_ne_oflow",
	0x100 => "insn_carry_clear",
	0x200 => "insn_zero_clear",
	0x400 => "insn_oflow_clear",
	0x800 => "insn_dir_clear",
	0x1000 => "insn_sign_clear",
	0x2000 => "insn_parity_clear",
	0x4000 => "insn_sign_eq_oflow",
	0x8000 => "insn_sign_ne_oflow",
};

our $x86_insn_cpu = {
	1 => "cpu_8086",	 # Intel
	2 => "cpu_80286",
	3 => "cpu_80386",
	4 => "cpu_80387",
	5 => "cpu_80486",
	6 => "cpu_pentium",
	7 => "cpu_pentiumpro",
	8 => "cpu_pentium2",
	9 => "cpu_pentium3",
	10 => "cpu_pentium4",
	16 => "cpu_k6",	 # AMD
	32 => "cpu_k7",
	48 => "cpu_athlon",
};

our $x86_insn_isa = {
	1 => "isa_gp",	 # general purpose
	2 => "isa_fp",	 # floating point
	3 => "isa_fpumgt",	 # FPU/SIMD management
	4 => "isa_mmx",	 # Intel MMX
	5 => "isa_sse1",	 # Intel SSE SIMD
	6 => "isa_sse2",	 # Intel SSE2 SIMD
	7 => "isa_sse3",	 # Intel SSE3 SIMD
	8 => "isa_3dnow",	 # AMD 3DNow! SIMD
	9 => "isa_sys",	 # system instructions
};

our $x86_insn_prefix = {
	0 => "insn_no_prefix",
	1 => "insn_rep_zero",	 # REPZ and REPE
	2 => "insn_rep_notzero",	 # REPNZ and REPNZ
	4 => "insn_lock",	 # LOCK:
};

sub set_flags {
  my $flags = shift;

  return X86::Disasm::set_generic($flags, $x86_flag_status);
}

sub set_note {
  my $note = shift;

  return X86::Disasm::set_generic($note, $x86_insn_note);
}

sub set_prefix {
  my $prefix = shift;

  return X86::Disasm::set_generic($prefix, $x86_insn_prefix);
}

sub set_scalars {
  my $insn = shift;

  my $insn_hash;
  $insn_hash->{addr} = $insn->addr;
  $insn_hash->{offset} = $insn->offset;
  $insn_hash->{group} = $x86_insn_group->{$insn->group};
  $insn_hash->{type} = $x86_insn_type->{$insn->type};
  $insn_hash->{note} = set_note($insn->note);
  $insn_hash->{bytes} = $insn->bytes;
  $insn_hash->{size} = $insn->size;
  $insn_hash->{addr_size} = $insn->addr_size;
  $insn_hash->{op_size} = $insn->op_size;
  $insn_hash->{cpu} = $x86_insn_cpu->{$insn->cpu};
  $insn_hash->{isa} = $x86_insn_isa->{$insn->isa};
  $insn_hash->{flags_set} = set_flags($insn->flags_set);
  $insn_hash->{flags_tested} = set_flags($insn->flags_tested);
  $insn_hash->{stack_mod} = $insn->stack_mod;
  $insn_hash->{stack_mod_val} = $insn->stack_mod_val;
  $insn_hash->{prefix} = set_prefix($insn->prefix);
  $insn_hash->{prefix_string} = $insn->prefix_string;
  $insn_hash->{mnemonic} = $insn->mnemonic;
  $insn_hash->{operand_count} = $insn->operand_count;
  $insn_hash->{explicit_count} = $insn->explicit_count;

  return $insn_hash;
}

sub hash {
  my $insn = shift;

  my $insn_hash = $insn->set_scalars;
  my $operands = $insn->operands;
  for (my $i=0; $i < $insn_hash->{explicit_count}; $i++) {
    my $operand = $operands->op;
    my $op_hash = X86::Disasm::Op::set($operand);
    push @{$insn_hash->{ops}}, $op_hash;
    $operands = $operands->next;    
  }
  return $insn_hash;
}

sub list {
  my $insn = shift;
  my $format = shift;

  return $insn->format_insn($format);
}

sub lol {
  my $insn = shift;
  my $format = shift;

  my $list;
  push @$list, $insn->format_mnemonic($format);
  my $operands = $insn->operands;
  for (my $i=0; $i < $insn->explicit_count; $i++) {
    my $operand = $operands->op;
    push @$list, $operand->format($format);
    $operands = $operands->next;    
  }
  return $list;
}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use X86::Disasm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
$x86_flag_status
$x86_insn_cpu
$x86_insn_group
$x86_insn_isa
$x86_insn_note
$x86_insn_type
$x86_insn_prefix
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

1;

__END__

=head1 NAME

X86::Disasm::Insn - Perl extension to wrap instructions in libdisasm - an X86 Disassembler

=head1 SYNOPSIS

  use X86::Disasm::Insn ':all';

=head1 DESCRIPTION

X86::Disasm::Insn provides a Perl interface to the instructions in the C X86 disassembler library, libdisasm. See http://bastard.sourceforge.net/libdisasm.html

=head2 EXPORT

None by default.

  our %EXPORT_TAGS = ( 'all' => [ qw(
  $x86_flag_status
  $x86_insn_cpu
  $x86_insn_group
  $x86_insn_isa
  $x86_insn_note
  $x86_insn_type
  $x86_insn_prefix
  ) ] );

=head1 SEE ALSO

  X86::Disasm
  X86::Disasm::Op
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
