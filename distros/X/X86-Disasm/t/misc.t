# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl disassemble_hash.t'

#########################

use Test::More tests => 21;

our (@range_data, $count);

BEGIN { use_ok('X86::Disasm', qw(
$x86_asm_format
$x86_asm_format_enum
$x86_options
$x86_op_foreach_type
$x86_report_codes
)) };

#8d 4c 24 04            lea    0x4(%esp),%ecx
#83 e4 f0               and    $0xfffffff0,%esp
#ff 71 fc               pushl  -0x4(%ecx)
#55                     push   %ebp
#89 e5                  mov    %esp,%ebp
#51                     push   %ecx

my $buffer = "\x8d\x4c\x24\x04\x83\xe4\xf0\xff\x71\xfc\x55\x89\xe5\x51";
my $buf_rva = 0;
my $syntax = "intel_syntax";
my $offset = 0;
my $buf_len = 4;

my $reporter_ref = sub {
  my $code = shift;
  my $data =  shift;
  my $reporter_data =  shift;

  warn "CODE is $code\n";
  use Data::Dumper;
  warn "DATA is ",Dumper($data),"\n";
  warn "CODE is ",Dumper($reporter_data),"\n";
};

my $reporter_data = {colour => "purple"};
my $disasm = X86::Disasm->new(0, $reporter_ref, $reporter_data);

my $insn = X86::Disasm::Insn->new;
my $op = X86::Disasm::Op->new;

my $retval = X86::Disasm::x86_disasm($buffer, $buf_len, $buf_rva, $offset, $insn);

ok($retval == 4, 'instruction size ok');
ok(X86::Disasm::x86_get_options == 0, 'options ok');
ok($insn->is_valid == 1, 'instruction is valid ok');
ok($insn->x86_operand_count(0) == 2, 'operand count ok');
ok($insn->x86_operand_1st->type == 1, 'first operand ok');
ok($insn->x86_operand_2nd->type == 6, 'second operand ok');
ok($insn->x86_get_address == 0, 'address ok');
ok($insn->x86_get_rel_offset == 0, 'relative offset ok');
ok($insn->x86_insn_is_tagged == 0, 'tagged 1 is ok');
$insn->x86_tag_insn;
ok($insn->x86_insn_is_tagged == 1, 'tagged 2 is ok');
$insn->x86_untag_insn;
ok($insn->x86_insn_is_tagged == 0, 'tagged 1 is ok');
$insn->x86_tag_insn;
ok(X86::Disasm::x86_endian == 1, 'endian is ok');
ok(X86::Disasm::x86_addr_size == 4, 'addr size ok');
ok(X86::Disasm::x86_op_size == 4, 'op size ok');
ok(X86::Disasm::x86_word_size == 4, 'word size ok');
ok(X86::Disasm::x86_max_insn_size == 20, 'max insn size ok');
ok(X86::Disasm::x86_sp_reg == 5, 'sp ok');
ok(X86::Disasm::x86_fp_reg == 6, 'fp ok');
ok(X86::Disasm::x86_ip_reg == 85, 'ip ok');
ok(X86::Disasm::x86_flag_reg == 81, 'flag ok');
