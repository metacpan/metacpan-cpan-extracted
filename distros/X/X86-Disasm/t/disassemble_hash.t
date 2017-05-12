# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl disassemble_hash.t'

#########################

use Test::More tests => 7;

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
my $offset = 0;
my $syntax = "intel_syntax";

my $disasm = X86::Disasm->new;
my $hash_data = $disasm->disassemble_hash($buffer, $buf_rva, $offset);
#use Data::Dumper;warn "HASH DATA is ",Data::Dumper->Dump([$hash_data]);
ok($hash_data->[0]->{mnemonic} eq 'lea', "first ok");
ok($hash_data->[1]->{mnemonic} eq 'and', 'second ok');
ok($hash_data->[2]->{mnemonic} eq 'push', 'third ok');
ok($hash_data->[3]->{mnemonic} eq 'push', 'fourth ok');
ok($hash_data->[4]->{mnemonic} eq 'mov', 'fifth ok');
ok($hash_data->[5]->{mnemonic} eq 'push', 'sixth ok');
