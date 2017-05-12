/* this is generated from call_asm_x86_msvc.asm and
   objdump -d --no-show-raw-insn  call_asm_x86_msvc.obj
   and some regexps and hand tweaking */
.globl @Call_asm@16
@Call_asm@16:

 _0:   push   %ebp
 _1:   mov    %esp,%ebp
 _3:   push   %esi
 _4:   push   %edi
 _5:   mov    0x8(%ebp),%esi
 _8:   jmp    _19
 _a:   sub    $0x10,%ecx
 _d:   mov    0x8(%ecx),%al
 _10:   cmp    $0xa,%al
 _12:   jb     _17
 _14:   pushl  0x4(%ecx)
 _17:   pushl  (%ecx)
 _19:   cmp    %edx,%ecx
 _1b:   ja     _a
 _1d:   mov    0xc(%ebp),%edi
 _20:   call   *0x8(%esi)
 _23:   movzbl 0x3(%esi),%ecx
 _27:   sub    $0xa,%ecx
 _2a:   je     _3a
 _2c:   dec    %ecx
 _2d:   je     _36
 _2f:   mov    %eax,(%edi)
 _31:   mov    %edx,0x4(%edi)
 _34:   jmp    _3c
 _36:   fstpl  (%edi)
 _38:   jmp    _3c
 _3a:   fstps  (%edi)
 _3c:   mov    (%esi),%eax
 _3e:   shr    $0x6,%eax
 _41:   and    $0x3fffc,%eax
 _46:   add    %eax,%esp
 _48:   pop    %edi
  49:   pop    %esi
 _4a:   cmp    %esp,%ebp
 _4c:   jne    _52
 _4e:   pop    %ebp
 _4f:   ret    $0x8
 _52:   call   *__imp__IsDebuggerPresent@0
 _58:   test   %eax,%eax
 _5a:   jne    _69
 _5c:   push   %esp
 _5d:   push   %ebp
 _5e:   push   $_bad_esp_msg
 .ifdef PERL_IMPLICIT_CONTEXT
 _63:   call   *__imp__Perl_croak_nocontext
 .else
 _63:   call   *__imp__Perl_croak
 .endif
 _69:   ud2
