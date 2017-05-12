
.globl Call_x64_real
Call_x64_real:

	pushq	%rbp
	movq	%rsp,%rbp
	subq	$32,%rsp	# keep space for 4 64bit params

	# Store register parameters 
	movq    %rcx,16(%rbp)	# ApiFunction
	movq    %rdx,24(%rbp)	# int_registers
	movq    %r8,32(%rbp)	# float_registers
	movq    %r9,40(%rbp)	# stack


	# Load up integer registers first... 
	movq    24(%rbp),%rax	# rax = int_registers
	movq    (%rax),%rcx
	movq    8(%rax),%rdx
	movq    16(%rax),%r8
	movq    24(%rax),%r9

	# Now floating-point registers 
	movq	32(%rbp),%rax	# rax = float_registers
	movsd	(%rax),%xmm0
	movsd	8(%rax),%xmm1
	movsd	16(%rax),%xmm2
	movsd	24(%rax),%xmm3

	# Now the stack 
	movq	40(%rbp),%r11	# r11 = stack
	mov	48(%rbp),%eax	# eax = nstack

	#align stack so *after* the copystack loop it will be 16 bytes
	#do 32 bits, GBs of stack params is impossible
	mov	%eax, %r10d
	#if odd set al to 1
	and	$1,%eax
	#boost 1 to 8 if its 1, if its 0 it will remain 0
	shl	$3,%eax
	#rax might be zero or not, all eax ops zero extend upper 32 bits
	sub	%rax, %rsp
	mov	%r10d, %eax


	# Except not if there isn't any 
	test	%eax,%eax
	je	docall

copystack:
	sub	$1,%eax
	movq	(%r11,%rax,8),%r10
	pushq	%r10
	test	%eax,%eax
	jne	copystack

docall:
	# And call
	movq	16(%rbp),%r10   # r10 = ApiFunction
	subq	$32,%rsp	# Microsoft x64 calling convention - allocate 32 bytes of "shadow space" on the stack
	callq	*%r10

	#pass through rax and xmm0 to caller
	movq	%rbp,%rsp
	popq	%rbp
	retq
