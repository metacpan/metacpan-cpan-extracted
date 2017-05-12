package X86::Disasm;

use 5.008000;
use strict;
use warnings;

use X86::Disasm::Insn ':all';

require Exporter;

our @ISA = qw(Exporter);

# automagically read these from /usr/include/libdis.h
# with a parser - all hashes but first

our $x86_report_codes = {
        'report_disasm_bounds',   #  RVA OUT OF BOUNDS : The disassembler could
                                  #  not disassemble the supplied RVA as it is
                                  #  out of the range of the buffer. The
                                  #  application should store the address and
                                  #  attempt to determine what section of the
                                  #  binary it is in, then disassemble the
                                  #  address from the bytes in that section.
                                  #       data: uint32_t rva
        'report_insn_bounds',     #  INSTRUCTION OUT OF BOUNDS: The disassembler
                                  #  could not disassemble the instruction as
                                  #  the instruction would require bytes beyond
                                  #  the end of the current buffer. This usually
                                  #  indicated garbage bytes at the end of a
                                  #  buffer, or an incorrectly-sized buffer.
                                  #       data: uint32_t rva
        'report_invalid_insn',    #* INVALID INSTRUCTION: The disassembler could
                                  #  not disassemble the instruction as it has an
                                  #  invalid combination of opcodes and operands.
                                  #  This will stop automated disassembly; the
                                  #  application can restart the disassembly
                                  #  after the invalid instruction.
                                  #       data: uint32_t rva
        'report_unknown'
};

our $x86_options = {	# these can be ORed together 
	0 => "opt_none",
	1 => "opt_ignore_nulls",	 # ignore sequences of > 4 NULL bytes
	2 => "opt_16_bit",	 # 16-bit/DOS disassembly
	4 => "opt_att_mnemonics",	 # use AT&T syntax names for alternate opcode mnemonics
};

our $x86_op_foreach_type = {
	0 => "op_any",	 # ALL operands (explicit, implicit, rwx)
	1 => "op_dest",	 # operands with Write access
	2 => "op_src",	 # operands with Read access
	3 => "op_ro",	 # operands with Read but not Write access
	4 => "op_wo",	 # operands with Write but not Read access
	5 => "op_xo",	 # operands with Execute access
	6 => "op_rw",	 # operands with Read AND Write access
	0x10 => "op_implicit",	 # operands that are implied by the opcode
	0x20 => "op_explicit",	 # operands that are not side-effects
};

our $x86_asm_format_enum = {
	"unknown_syntax" => 0,	 # never use!
        "native_syntax"  => 1,   # header: 35 bytes 
        "intel_syntax"   => 2,   # header: 23 bytes
        "att_syntax"     => 3,   # header: 23 bytes
        "xml_syntax"     => 4,   # header: 679 bytes
        "raw_syntax"     => 5    # header: 172 bytes
};

our $x86_asm_format = {
	0 => "unknown_syntax",	 # never use!
        1 => "native_syntax",    # header: 35 bytes
        2 => "intel_syntax",     # header: 23 bytes
        3 => "att_syntax",       # header: 23 bytes
        4 => "xml_syntax",       # header: 679 bytes
        5 => "raw_syntax"        # header: 172 bytes
};

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self, $class;

#The first argument to x86_init() represents disassembler options; these are 
#defined as our $x86_options above

  my $options = @_ ? shift : 0;
  my $reporter = @_ ? shift : 0;
#use Devel::Peek; Dump($reporter);
  my $reporter_args = @_ ? shift : 0;
#use Devel::Peek; Dump($reporter_args);

  X86::Disasm::init($options, $reporter, $reporter_args);
  $self;
}

sub DESTROY {
  X86::Disasm::x86_cleanup();
}

# a utility function used to set a list from a scalar and a hash where
# the scalar is an index to the set keys - esentially we unpack a boolean
sub set_generic {
  my $value = shift;
  my $hash = shift;

  my $list = [];
  return $list unless (defined $value and defined $hash);

  foreach my $key (sort keys %$hash) {
    if ($key) {
      push @$list, $hash->{$key} if ($value & $key);
    } else {
      push @$list, $hash->{$key} if not $value;
    }
  }
  return $list;
}

sub disassemble {
# returns a list of instructions with sub-lists of operands
  my $self = shift;
  my $buffer = shift;
  my $buf_rva = shift;
  my $offset = shift;
  my $format = shift;

  if (ref $buffer and ref $buffer eq 'SCALAR') {
    $buffer = $$buffer;
  }
  my $buf_len = length $buffer;

  my $data;
  my $insn = X86::Disasm::Insn->new;

  while ($offset < $buf_len) {
    my $retval = X86::Disasm::x86_disasm($buffer, $buf_len, $buf_rva, $offset, $insn);

    if ($retval) {
      my $insn_lol = $insn->lol($format);
      push @$data, $insn_lol;
      $offset += $retval;
    } else {
      push @$data, $offset;
      $offset++;
    }
  }
  return $data;
}

sub disassemble_list {
# returns a list of instructions and operands
  my $self = shift;
  my $buffer = shift;
  my $buf_rva = shift;
  my $offset = shift;
  my $format = shift;

  if (ref $buffer and ref $buffer eq 'SCALAR') {
    $buffer = $$buffer;
  }
  my $buf_len = length $buffer;

  my $data;
  my $insn = X86::Disasm::Insn->new;

  while ($offset < $buf_len) {
    my $retval = X86::Disasm::x86_disasm($buffer, $buf_len, $buf_rva, $offset, $insn);

    if ($retval) {
      my $insn_list = $insn->list($format);
      push @$data, $insn_list;
      $offset += $retval;
    } else {
      push @$data, $offset;
      $offset++;
    }
  }
  return $data;
}

sub disassemble_hash {
# returns a hash representing the full disassembly
  my $self = shift;
  my $buffer = shift;
  my $buf_rva = shift;
  my $offset = shift;

  if (ref $buffer and ref $buffer eq 'SCALAR') {
    $buffer = $$buffer;
  }
  my $buf_len = length $buffer;

  my $data;
  my $insn = X86::Disasm::Insn->new;

  while ($offset < $buf_len) {
    my $retval = X86::Disasm::x86_disasm($buffer, $buf_len, $buf_rva, $offset, $insn);

    if ($retval) {
      my $insn_hash = $insn->hash;
      push @$data, $insn_hash;
      $offset += $retval;
    } else {
      push @$data, $offset;
      $offset++;
    }
  }
  return $data;
}

#sub disassemble_range {
#  my $self = shift;
#  my $buffer = shift;
#  my $buf_rva = shift;
#  my $offset = shift;
#  my $len = shift;
#  my $callback = shift;
#  my $callback_data = shift;
#
#  if (ref $buffer and ref $buffer eq 'SCALAR') {
#    $buffer = $$buffer;
#  }
#  my $retval = X86::Disasm::disasm_range($buffer, $buf_rva, $offset, $len, $callback, $callback_data);
#  return $retval;
#}
#
#sub disassemble_forward {
#  my $self = shift;
#  my $buffer = shift;
#  my $buf_rva = shift;
#  my $offset = shift;
#  my $callback = shift;
#  my $callback_data = shift;
#  my $resolver = shift;
#  my $resolver_data = shift;
#
#  if (ref $buffer and ref $buffer eq 'SCALAR') {
#    $buffer = $$buffer;
#  }
#  my $buf_len = length($buffer);
#
#  my $retval = X86::Disasm::disasm_forward($buffer, $buf_len, $buf_rva, $offset, $callback, $callback_data, $resolver, $resolver_data);
#  return $retval;
#}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use X86::Disasm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
$x86_asm_format
$x86_asm_format_enum
$x86_options
$x86_op_foreach_type
$x86_report_codes
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.23.1';

require XSLoader;
XSLoader::load('X86::Disasm', $VERSION);

# Preloaded methods go here.

1;

__END__

=pod

=head1 NAME

X86::Disasm - Perl extension to wrap libdisasm - an X86 Disassembler

=head1 SYNOPSIS

  use X86::Disasm ':all';

  my $buffer = "\x8d\x4c\x24\x04\x83\xe4\xf0\xff\x71\xfc\x55\x89\xe5\x51";
  my $buf_rva = 0;
  my $offset = 0;

  my $disasm = X86::Disasm->new;

  my $data = $disasm->disassemble($buffer, $buf_rva, $offset, $x86_asm_format_enum->{$syntax});

=head1 DESCRIPTION

X86::Disasm provides a Perl interface to the C X86 disassembler library, libdisasm. See http://bastard.sourceforge.net/libdisasm.html

=head1 EXPORT

None by default.

  our %EXPORT_TAGS = ( 'all' => [ qw(
  $x86_asm_format
  $x86_asm_format_enum
  $x86_options
  $x86_op_foreach_type
  $x86_report_codes
  ) ] );

=head1 METHODS

=head2 new

  my $disasm = X86::Disasm->new($options, $reporter, $reporter_args);

All arguments are optional. 

C<$options> is defined by the hash

  our $x86_options = {	# these can be ORed together 
	0 => "opt_none",
	1 => "opt_ignore_nulls",  # ignore sequences of > 4 NULL bytes
	2 => "opt_16_bit",	  # 16-bit/DOS disassembly
	4 => "opt_att_mnemonics", # use AT&T syntax names for alternate opcode mnemonics
  };

If supplied, C<$reporter> must be a code reference.

If supplied, C<$reporter_args> must be a hash reference.

=head2 disassemble

  my $data = $disasm->disassemble($buffer, $buf_rva, $offset, $x86_asm_format_enum->{$syntax});

This method presents the instructions as a list of lists. Each instruction
is the first element of the sub-list; subsequent elements are the associated
operands.

=head2 disassemble_list

  my $data = $disasm->disassemble_list($buffer, $buf_rva, $offset, $x86_asm_format_enum->{$syntax});

This method presents the instructions as a list. Each instruction is presented
as a string.

=head2 disassemble_hash

  my $data = $disasm->disassemble_hash($buffer, $buf_rva, $offset);

This method presents the instructions as a a list of hashes. Each instruction
is totally deconstructed in to the hash - and provides a full representation
of the information.

=head2 disassemble_range

No longer implemented.

 #  $disasm->disassemble_range($buffer, $buf_rva, $offset, $length, $callback_ref, $callback_data);
 #
 #This method disassembles the range of instructions from $offset for $length 
 #bytes. The supplied calback can be used to do *something* with the 
 #instructions.

=head2 disassemble_forward

No longer implemented.

 #  my $retval = $disasm->disassemble_forward($buffer, $buf_rva, $offset, $callback_ref, $callback_data, $resolver_ref, $resolver_data);
 #
 #The disassembly in this case starts at 'offset', and proceeds forward following
 #the flow of execution for the disassembled code. This means that when a jump,
 #call, or conditional jump is encountered, disassemble_forward recurses, using
 #the offset of the target of the jump or call as the 'offset' argument. When
 #a jump or return is encountered, disassemble_forward returns, allowing its
 #caller [either the application, or an outer invocation of disassemble_forward]
 #to continue.

=head1 SEE ALSO

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
