# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl disassemble.t'

#########################

use Test::More tests => 16;

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
my $lol_data = $disasm->disassemble($buffer, $buf_rva, $offset, $x86_asm_format_enum->{$syntax});
ok($lol_data->[0]->[0] eq 'lea', "first first ok");
ok($lol_data->[0]->[1] eq 'ecx', "first second ok");
ok($lol_data->[0]->[2] eq '[esp+0x4]', "first third ok");
ok($lol_data->[1]->[0] eq 'and', 'second first ok');
ok($lol_data->[1]->[1] eq 'esp', 'second second ok');
ok($lol_data->[1]->[2] eq '0xF0', 'second third ok');
ok($lol_data->[2]->[0] eq 'push', 'third first ok');
ok($lol_data->[2]->[1] eq '[ecx-0x4]', 'third second ok');
ok($lol_data->[3]->[0] eq 'push', 'fourth first ok');
ok($lol_data->[3]->[1] eq 'ebp', 'fourth second ok');
ok($lol_data->[4]->[0] eq 'mov', 'fifth first ok');
ok($lol_data->[4]->[1] eq 'ebp', 'fifth second ok');
ok($lol_data->[4]->[2] eq 'esp', 'fifth third ok');
ok($lol_data->[5]->[0] eq 'push', 'sixth first ok');
ok($lol_data->[5]->[1] eq 'ecx', 'sixth second ok');
