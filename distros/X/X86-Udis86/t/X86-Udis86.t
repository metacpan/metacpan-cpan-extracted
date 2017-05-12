# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl X86-Udis86.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 71;
BEGIN { 
  use_ok('X86::Udis86');
  use_ok('X86::Udis86::Operand', qw(:all));
};

#########################

my $bytes = "\x8d\x4c\x24\x04\x83\xe4\xf0\xff\x71\xfc\x55\x89\xe5\x51";
my $ud_obj = X86::Udis86->new;
ok($ud_obj, "Pointer set");
isa_ok($ud_obj, "X86::Udis86", "Class is correct");

$ud_obj->set_input_buffer($bytes, length($bytes));
$ud_obj->set_mode(32);
$ud_obj->set_syntax("intel");
$ud_obj->set_vendor("intel");

my (@offset, @hex, @asm, @mnemonic, @pc, @len, $ops);
while($ud_obj->disassemble) {
  my $op_list;
  push @offset, sprintf("%016x", $ud_obj->insn_off);
  push @hex, sprintf("%-16x", hex($ud_obj->insn_hex));
  push @asm, $ud_obj->insn_asm;
  push @mnemonic, $ud_obj->lookup_mnemonic;
  push @len, $ud_obj->insn_len;
  push @pc, $ud_obj->pc;
  my $max = $ud_obj->insn_len < 3 ? $ud_obj->insn_len : 3;
  for (my $i=0; $i<$max; $i++) {
    my $operand = $ud_obj->insn_opr($i);
    if (defined $operand) {
      push @$op_list, test_info($operand);
    }
  }
  push @$ops, $op_list;
}

#0000000000000000 8d4c2404         lea ecx, [esp+0x4] 
ok($offset[0] eq '0000000000000000', "0 offset good");
ok($hex[0] eq "8d4c2404        ", "0 hex good");
ok($asm[0] eq "lea ecx, [esp+0x4]", "0 asm good");
ok($mnemonic[0] eq "lea", "0 mnemonic good");
ok($len[0] == 4, "0 len good");
ok($pc[0] == 4, "0 pc good");
ok($ops->[0]->[0]->{type_as_string} eq "UD_OP_REG", "Operand[0][0] type good");
ok($ops->[0]->[0]->{size} == 32, "Operand[0][0] size good");
ok($ops->[0]->[0]->{base} eq "UD_R_ECX", "Operand[0][0] base good");
ok($ops->[0]->[1]->{type_as_string} eq "UD_OP_MEM", "Operand[0][1] type good");
ok($ops->[0]->[1]->{size} == 0, "Operand[0][1] size good");
ok($ops->[0]->[1]->{base} eq "UD_R_ESP", "Operand[0][1] base good");
ok($ops->[0]->[1]->{offset} == 8, "Operand[0][1] offset good");
ok($ops->[0]->[1]->{lval} eq "0x4", "Operand[0][1] lval good");

#0000000000000004 83e4f0           and esp, 0xfffffff0 
ok($offset[1] eq '0000000000000004', "1 offset good");
ok($hex[1] eq "83e4f0          ", "1 hex good");
ok($asm[1] eq "and esp, 0xfffffff0", "1 asm good");
ok($mnemonic[1] eq "and", "1 mnemonic good");
ok($len[1] == 3, "1 len good");
ok($pc[1] == 7, "1 pc good");
ok($ops->[1]->[0]->{type_as_string} eq "UD_OP_REG", "Operand[1][0] type good");
ok($ops->[1]->[0]->{size} == 32, "Operand[1][0] size good");
ok($ops->[1]->[0]->{base} eq "UD_R_ESP", "Operand[1][0] base good");
ok($ops->[1]->[1]->{type_as_string} eq "UD_OP_IMM", "Operand[1][1] type good");
ok($ops->[1]->[1]->{size} == 8, "Operand[1][1] size good");
ok($ops->[1]->[1]->{lval} eq "0xf0", "Operand[1][1] lval good");

#0000000000000007 ff71fc           push dword [ecx-0x4] 
ok($offset[2] eq '0000000000000007', "2 offset good");
ok($hex[2] eq "ff71fc          ", "2 hex good");
ok($asm[2] eq "push dword [ecx-0x4]", "2 asm good");
ok($mnemonic[2] eq "push", "2 mnemonic good");
ok($len[2] == 3, "2 len good");
ok($pc[2] == 10, "2 pc good");
ok($ops->[2]->[0]->{type_as_string} eq "UD_OP_MEM", "Operand[2][0] type good");
ok($ops->[2]->[0]->{size} == 32, "Operand[2][0] size good");
ok($ops->[2]->[0]->{base} eq "UD_R_ECX", "Operand[2][0] base good");
ok($ops->[2]->[0]->{offset} == 8, "Operand[2][0] offset good");
ok($ops->[2]->[0]->{lval} eq "0xfc", "Operand[2][0] lval good");

#000000000000000a 55               push ebp 
ok($offset[3] eq '000000000000000a', "3 offset good");
ok($hex[3] eq "55              ", "3 hex good");
ok($asm[3] eq "push ebp", "3 asm good");
ok($mnemonic[3] eq "push", "3 mnemonic good");
ok($len[3] == 1, "3 len good");
ok($pc[3] == 11, "3 pc good");
ok($ops->[3]->[0]->{type_as_string} eq "UD_OP_REG", "Operand[3][0] type good");
ok($ops->[3]->[0]->{size} == 32, "Operand[3][0] size good");
ok($ops->[3]->[0]->{base} eq "UD_R_EBP", "Operand[3][0] base good");

#000000000000000b 89e5             mov ebp, esp 
ok($offset[4] eq '000000000000000b', "4 offset good");
ok($hex[4] eq "89e5            ", "4 hex good");
ok($asm[4] eq "mov ebp, esp", "4 asm good");
ok($mnemonic[4] eq "mov", "4 mnemonic good");
ok($len[4] == 2, "4 len good");
ok($pc[4] == 13, "4 pc good");
ok($ops->[4]->[0]->{type_as_string} eq "UD_OP_REG", "Operand[4][0] type good");
ok($ops->[4]->[0]->{size} == 32, "Operand[4][0] size good");
ok($ops->[4]->[0]->{base} eq "UD_R_EBP", "Operand[4][0] base good");
ok($ops->[4]->[1]->{type_as_string} eq "UD_OP_REG", "Operand[4][1] type good");
ok($ops->[4]->[1]->{size} == 32, "Operand[4][1] size good");
ok($ops->[4]->[1]->{base} eq "UD_R_ESP", "Operand[4][1] base good");

#000000000000000d 51               push ecx 
ok($offset[5] eq '000000000000000d', "5 offset good");
ok($hex[5] eq "51              ", "5 hex good");
ok($asm[5] eq "push ecx", "5 asm good");
ok($mnemonic[5] eq "push", "5 mnemonic good");
ok($len[5] == 1, "5 len good");
ok($pc[5] == 14, "5 pc good");
ok($ops->[5]->[0]->{type_as_string} eq "UD_OP_REG", "Operand[5][0] type good");
ok($ops->[5]->[0]->{size} == 32, "Operand[5][0] size good");
ok($ops->[5]->[0]->{base} eq "UD_R_ECX", "Operand[5][0] base good");

sub test_info {
  my $self = shift;
  my $data;

  $data->{type_as_string} = $self->type_as_string;
  if ($self->type_as_string ne "UD_NONE") {
    $data->{size} = $self->size;
    if ($self->type_as_string eq "UD_OP_REG") {
      $data->{base} = $self->base_as_string;
    }
    if ($self->type_as_string eq "UD_OP_MEM") {
      $data->{base} = $self->base_as_string;
      if ($self->index_as_string ne "UD_NONE") {
        $data->{index} = $self->index_as_string;
      }
      if ($self->scale) {
        $data->{scale} = $self->scale;
      }
      if ($self->offset) {
        $data->{offset} = $self->offset;
      }
      $data->{lval} = sprintf("%#x", ord($self->lval_sbyte));
    }
    if ($self->type_as_string eq "UD_OP_PTR") {
    }
    if (($self->type_as_string eq "UD_OP_IMM") 
     or ($self->type_as_string eq "UD_OP_JIMM") 
     or ($self->type_as_string eq "UD_OP_CONST")) {
       $data->{lval} = sprintf("%#x", ord($self->lval_sbyte));
    }
  }
  return $data;
}

