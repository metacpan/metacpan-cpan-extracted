# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl disassemble_list.t'

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
my $list_data = $disasm->disassemble_list($buffer, $buf_rva, $offset, $x86_asm_format_enum->{$syntax});
ok($list_data->[0] eq 'lea	ecx, [esp+0x4]', "first ok");
ok($list_data->[1] eq 'and	esp, 0xF0', 'second ok');
ok($list_data->[2] eq 'push	[ecx-0x4]', 'third ok');
ok($list_data->[3] eq 'push	ebp', 'fourth ok');
ok($list_data->[4] eq 'mov	ebp, esp', 'fifth ok');
ok($list_data->[5] eq 'push	ecx', 'sixth ok');
