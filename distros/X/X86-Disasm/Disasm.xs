#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libdis.h>

typedef x86_absolute_t *X86__Disasm__Absolute;
typedef x86_ea_t *X86__Disasm__Ea;
typedef x86_insn_t *X86__Disasm__Insn;
typedef x86_op_t *X86__Disasm__Op;
typedef x86_oplist_t *X86__Disasm__Oplist;
typedef x86_reg_t *X86__Disasm__Reg;
typedef x86_invariant_t *X86__Disasm__Invariant;
typedef x86_invariant_op_t *X86__Disasm__InvariantOp;

/* Static memory for init reporter */
static SV * init_reporter_sv = (SV*)NULL;

/* Static memory for range callback */
/* static SV * range_callback_sv = (SV*)NULL; */

/* Static memory for forward callback */
/* static SV * forward_callback_sv = (SV*)NULL; */

/* Static memory for forward resolver */
/* static SV * forward_resolver_sv = (SV*)NULL; */

/* The init reporter callback */
void reporter_callback(enum x86_report_codes code, void * arg, void * reporter_arg ) 
{
  dSP;

  IV arg_iv;
  SV *arg_rv = NULL;

  IV reporter_arg_iv;
  SV *reporter_arg_rv = NULL;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSViv(code)));

  arg_iv = PTR2IV(arg);
  arg_rv = newRV_inc(newSViv(arg_iv));
  XPUSHs(sv_2mortal(arg_rv));

  reporter_arg_iv = PTR2IV(reporter_arg);
  reporter_arg_rv = newRV_inc(newSViv(reporter_arg_iv));
  XPUSHs(sv_2mortal(reporter_arg_rv));

  PUTBACK;

  call_sv(init_reporter_sv, G_VOID );

  SPAGAIN;

  FREETMPS;
  LEAVE;
}

/* The range callback */
/*
void range_callback( x86_insn_t *insn, void * arg ) 
{
  dSP;

  const char* classname = "X86::Disasm::Insn";
  IV insn_iv;
  SV *insn_sv = NULL;
  SV *insn_rv = NULL;
  SV *insn_blessed = NULL;

  IV arg_iv;
  SV *arg_rv = NULL;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

// Convert insn from a pointer to an IV
  insn_iv = PTR2IV(insn); 
// Make a new SV from that IV
  insn_sv = newSViv(insn_iv); 
// Make a reference to the SV and increment the ref count 
  insn_rv = newRV_inc(insn_sv); 
// Bless the reference into the X86::Disasm::Insn namespace
  insn_blessed = sv_bless(insn_rv, gv_stashpv(classname, 1)); 
// Make the SV mortal and push the SV onto the stack for Perl
  XPUSHs(sv_2mortal(insn_blessed)); 
// Perl code can then call the methods defined in Perl space because
// an X86::Disasm::Insn object is a x86_insn_t * essentially

  arg_iv = PTR2IV(arg);
// Here we just typecast rather than make a new object because
// we want to just pass through the hashref which came from Perl
  arg_rv = newRV_inc(newSViv(arg_iv));
  XPUSHs(sv_2mortal(arg_rv));

  PUTBACK;

  call_sv(range_callback_sv, G_VOID );

  SPAGAIN;

  FREETMPS;
  LEAVE;
}
*/

/* The forward callback */
/*
void forward_callback( x86_insn_t *insn, void * arg ) 
{
  dSP;

  const char* classname = "X86::Disasm::Insn";
  IV insn_iv;
  SV *insn_sv = NULL;
  SV *insn_rv = NULL;
  SV *insn_blessed = NULL;

  IV arg_iv;
  SV *arg_rv = NULL;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

// Convert insn from a pointer to an IV
  insn_iv = PTR2IV(insn); 
// Make a new SV from that IV
  insn_sv = newSViv(insn_iv); 
// Make a reference to the SV and increment the ref count 
  insn_rv = newRV_inc(insn_sv); 
// Bless the reference into the X86::Disasm::Insn namespace
  insn_blessed = sv_bless(insn_rv, gv_stashpv(classname, 1)); 
// Make the SV mortal and push the SV onto the stack for Perl
  XPUSHs(sv_2mortal(insn_blessed)); 
// Perl code can then call the methods defined in Perl space because
// an X86::Disasm::Insn object is a x86_insn_t * essentially

  arg_iv = PTR2IV(arg);
// Here we just typecast rather than make a new object because
// we want to just pass through the hashref which came from Perl
  arg_rv = newRV_inc(newSViv(arg_iv));
  XPUSHs(sv_2mortal(arg_rv));

  PUTBACK;

  call_sv(forward_callback_sv, G_VOID );

  SPAGAIN;

  FREETMPS;
  LEAVE;
}
*/

/* The forward resolver */
/*
int32_t 
forward_resolver(x86_op_t *op, x86_insn_t * insn, void *arg)
{
  dSP;

  const char* opclass = "X86::Disasm::Op";
  IV op_iv;
  SV *op_sv = NULL;
  SV *op_rv = NULL;
  SV *op_blessed = NULL;

  const char* insnclass = "X86::Disasm::Insn";
  IV insn_iv;
  SV *insn_sv = NULL;
  SV *insn_rv = NULL;
  SV *insn_blessed = NULL;

  IV arg_iv;
  SV *arg_rv = NULL;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

// Convert op from a pointer to an IV
  op_iv = PTR2IV(op); 
// Make a new SV from that IV
  op_sv = newSViv(op_iv); 
// Make a reference to the SV and increment the ref count 
  op_rv = newRV_inc(op_sv); 
// Bless the reference into the X86::Disasm::Insn namespace
  op_blessed = sv_bless(op_rv, gv_stashpv(opclass, 1)); 
// Make the SV mortal and push the SV onto the stack for Perl
  XPUSHs(sv_2mortal(op_blessed)); 
// Perl code can then call the methods defined in Perl space because
// an X86::Disasm::Op object is a x86_op_t * essentially

// Convert insn from a pointer to an IV
  insn_iv = PTR2IV(insn); 
// Make a new SV from that IV
  insn_sv = newSViv(insn_iv); 
// Make a reference to the SV and increment the ref count 
  insn_rv = newRV_inc(insn_sv); 
// Bless the reference into the X86::Disasm::Insn namespace
  insn_blessed = sv_bless(insn_rv, gv_stashpv(insnclass, 1)); 
// Make the SV mortal and push the SV onto the stack for Perl
  XPUSHs(sv_2mortal(insn_blessed)); 
// Perl code can then call the methods defined in Perl space because
// an X86::Disasm::Insn object is a x86_insn_t * essentially

  arg_iv = PTR2IV(arg);
// Here we just typecast rather than make a new object because
// we want to just pass through the hashref which came from Perl
  arg_rv = newRV_inc(newSViv(arg_iv));
  XPUSHs(sv_2mortal(arg_rv));

  PUTBACK;

  call_sv(forward_resolver_sv, G_VOID );

  SPAGAIN;

  FREETMPS;
  LEAVE;
}
*/

MODULE = X86::Disasm		PACKAGE = X86::Disasm::InvariantOp

X86::Disasm::InvariantOp
new(CLASS)
        char *CLASS
        CODE:
        x86_invariant_op_t *invariant_op = (x86_invariant_op_t *)safemalloc( sizeof(x86_invariant_op_t) );
        if (invariant_op == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = invariant_op;

        OUTPUT:
        RETVAL

#typedef struct {
#        enum x86_op_type        type;           /* operand type */
enum x86_op_type
type(self)
	X86::Disasm::InvariantOp self
        CODE:
        RETVAL = self->type;
        OUTPUT:
        RETVAL

#        enum x86_op_datatype    datatype;       /* operand size */
enum x86_op_datatype
datatype(self)
	X86::Disasm::InvariantOp self
        CODE:
        RETVAL = self->datatype;
        OUTPUT:
        RETVAL

#        enum x86_op_access      access;         /* operand access [RWX] */
enum x86_op_access
access(self)
	X86::Disasm::InvariantOp self
        CODE:
        RETVAL = self->access;
        OUTPUT:
        RETVAL

#        enum x86_op_flags       flags;          /* misc flags */
#} x86_invariant_op_t;
enum x86_op_flags
flags(self)
	X86::Disasm::InvariantOp self
        CODE:
        RETVAL = self->flags;
        OUTPUT:
        RETVAL

MODULE = X86::Disasm		PACKAGE = X86::Disasm::Invariant

X86::Disasm::Invariant
new(CLASS)
        char *CLASS
        CODE:
        x86_invariant_t *invariant = (x86_invariant_t *)safemalloc( sizeof(x86_invariant_t) );
        if (invariant == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = invariant;
        OUTPUT:
        RETVAL

#typedef struct {
#        unsigned char bytes[64];        /* invariant representation */
void
bytes(self)
	X86::Disasm::Invariant self
	PREINIT:
	int i;
	int char_as_int;
	UV byte_uv;
	SV *byte_sv;
	SV *byte_rv;
	PPCODE:
# we want to return all 64 bytes as an array to perl
	EXTEND(SP, 64);
	for (i=0; i<64; i++) {
# convert the char to an int
		char_as_int = (int) self->bytes[i];
# typecast the int to a UV
		byte_uv = (UV) char_as_int;
# typecase the UV to an SV*
		byte_sv = newSVuv(byte_uv);
#		byte_sv = (SV *) byte_uv;
# take a reference to the SV*
		byte_rv = newRV_inc(byte_sv);
# and push a mortal copy on to the stack for Perl
		PUSHs(sv_2mortal(byte_rv));
	}

#        unsigned int  size;             /* number of bytes in insn */
unsigned int
size(self)
	X86::Disasm::Invariant self
        CODE:
        RETVAL = self->size;
        OUTPUT:
        RETVAL

#        enum x86_insn_group group;      /* meta-type, e.g. INS_EXEC */
enum x86_insn_group
group(self)
	X86::Disasm::Invariant self
        CODE:
        RETVAL = self->group;
        OUTPUT:
        RETVAL

#        enum x86_insn_type type;        /* type, e.g. INS_BRANCH */
enum x86_insn_type
type(self)
	X86::Disasm::Invariant self
        CODE:
        RETVAL = self->type;
        OUTPUT:
        RETVAL

#        x86_invariant_op_t operands[3]; /* operands: dest, src, imm */
#} x86_invariant_t;
#x86_invariant_op_t
void
operands(self)
	X86::Disasm::Invariant self
	PREINIT:
	int i;
	x86_invariant_op_t *op;
	const char *class = "X86::Disasm::InvariantOp";
	IV op_iv;
	SV *op_sv;
	SV *op_rv;
	SV *op_blessed;
        PPCODE:
# We return a list of 3 objects of appropriate class
	EXTEND(SP, 3);
	for (i=0; i<3; i++) {
		op = &(self->operands[i]);
		op_iv = PTR2IV(op);
		op_sv = newSViv(op_iv);
		op_rv = newRV_inc(op_sv);
		op_blessed = sv_bless(op_rv, gv_stashpv(class, 1));
		PUSHs(sv_2mortal(op_blessed));
	}
		
MODULE = X86::Disasm		PACKAGE = X86::Disasm::Absolute

X86::Disasm::Absolute
new(CLASS)
        char *CLASS
        CODE:
        x86_absolute_t *absolute = (x86_absolute_t *)safemalloc( sizeof(x86_absolute_t) );
        if (absolute == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = absolute;

        OUTPUT:
        RETVAL

#/* x86_absolute_t : an X86 segment:offset address (descriptor) */
#typedef struct {

#        unsigned short  segment;        /* loaded directly into CS */
unsigned short
segment(self)
	X86::Disasm::Absolute self
        CODE:
        RETVAL = self->segment;
        OUTPUT:
        RETVAL

#        union {
#                unsigned short  off16;  /* loaded directly into IP */
#                uint32_t                off32;  /* loaded directly into EIP */
#        } offset;

unsigned short
off16(self)
	X86::Disasm::Absolute self
        CODE:
        RETVAL = self->offset.off16;
        OUTPUT:
        RETVAL

uint32_t
off32(self)
	X86::Disasm::Absolute self
        CODE:
        RETVAL = self->offset.off32;
        OUTPUT:
        RETVAL

#} x86_absolute_t;
 #void
 #DESTROY(self)
 #	X86::Disasm::Absolute self
 #        CODE:
 #        safefree(self);

MODULE = X86::Disasm		PACKAGE = X86::Disasm::Reg

#/* x86_reg_t : an X86 CPU register */

X86::Disasm::Reg
new(CLASS)
        char *CLASS
        CODE:
        x86_reg_t *reg = (x86_reg_t *)safemalloc( sizeof(x86_reg_t) );
        if (reg == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = reg;
        OUTPUT:
        RETVAL

#typedef struct {
#        char name[MAX_REGNAME];
char *
name(self)
	X86::Disasm::Reg self
        CODE:
        RETVAL = self->name;
        OUTPUT:
        RETVAL

#        enum x86_reg_type type;         /* what register is used for */
enum x86_reg_type
type(self)
	X86::Disasm::Reg self
        CODE:
        RETVAL = self->type;
        OUTPUT:
        RETVAL

#        unsigned int size;              /* size of register in bytes */
unsigned int
size(self)
	X86::Disasm::Reg self
        CODE:
        RETVAL = self->size;
        OUTPUT:
        RETVAL

#        unsigned int id;                /* register ID #, for quick compares */
unsigned int
id(self)
	X86::Disasm::Reg self
        CODE:
        RETVAL = self->id;
        OUTPUT:
        RETVAL

#        unsigned int alias;             /* ID of reg this is an alias for */
unsigned int
alias(self)
	X86::Disasm::Reg self
        CODE:
        RETVAL = self->alias;
        OUTPUT:
        RETVAL

#        unsigned int shift;             /* amount to shift aliased reg by */
unsigned int
shift(self)
	X86::Disasm::Reg self
        CODE:
        RETVAL = self->shift;
        OUTPUT:
        RETVAL

#} x86_reg_t;
 #void
 #DESTROY(self)
 #	X86::Disasm::Reg self
 #        CODE:
 #        safefree(self);

MODULE = X86::Disasm		PACKAGE = X86::Disasm::Ea

#/* x86_ea_t : an X86 effective address (address expression) */

X86::Disasm::Ea
new(CLASS)
        char *CLASS
        CODE:
        x86_ea_t *ea = (x86_ea_t *)safemalloc( sizeof(x86_ea_t) );
        if (ea == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = ea;
        OUTPUT:
        RETVAL

#typedef struct {
#        unsigned int     scale;         /* scale factor */
unsigned int
scale(self)
	X86::Disasm::Ea self
        CODE:
        RETVAL = self->scale;
        OUTPUT:
        RETVAL

#        x86_reg_t        index, base;   /* index, base registers */
X86::Disasm::Reg
index(self)
	X86::Disasm::Ea self
        CODE:
        RETVAL = &(self->index);
        OUTPUT:
        RETVAL

X86::Disasm::Reg
base(self)
	X86::Disasm::Ea self
        CODE:
        RETVAL = &(self->base);
        OUTPUT:
        RETVAL

#        int32_t          disp;          /* displacement */
int32_t
disp(self)
	X86::Disasm::Ea self
        CODE:
        RETVAL = self->disp;
        OUTPUT:
        RETVAL

#        char             disp_sign;     /* is negative? 1/0 */
char
disp_sign(self)
	X86::Disasm::Ea self
        CODE:
        RETVAL = self->disp_sign;
        OUTPUT:
        RETVAL

#        char             disp_size;     /* 0, 1, 2, 4 */
char
disp_size(self)
	X86::Disasm::Ea self
        CODE:
        RETVAL = self->disp_size;
        OUTPUT:
        RETVAL

#} x86_ea_t;
 #void
 #DESTROY(self)
 #	X86::Disasm::Ea self
 #        CODE:
 #        safefree(self);


MODULE = X86::Disasm		PACKAGE = X86::Disasm::Op

#/* x86_op_t : an X86 instruction operand */

X86::Disasm::Op
new(CLASS)
        char *CLASS
        CODE:
        x86_op_t *op = (x86_op_t *)safemalloc( sizeof(x86_op_t) );
        if (op == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = op;
        OUTPUT:
        RETVAL

#typedef struct {
#        enum x86_op_type        type;           /* operand type */
enum x86_op_type        
type(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->type;
        OUTPUT:
        RETVAL

#        enum x86_op_datatype    datatype;       /* operand size */
enum x86_op_datatype        
datatype(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->datatype;
        OUTPUT:
        RETVAL

#        enum x86_op_access      access;         /* operand access [RWX] */
enum x86_op_access        
access(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->access;
        OUTPUT:
        RETVAL

#        enum x86_op_flags       flags;          /* misc flags */
enum x86_op_flags        
flags(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->flags;
        OUTPUT:
        RETVAL

#        union {
#                /* sizeof will have to work on these union members! */
#                /* immediate values */
#                char            sbyte;
char
sbyte(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.sbyte;
        OUTPUT:
        RETVAL

#                short           sword;
short
sword(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.sword;
        OUTPUT:
        RETVAL

#                int32_t         sdword;
int32_t
sdword(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.sdword;
        OUTPUT:
        RETVAL

#                qword_t         sqword;
qword_t
sqword(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.sqword;
        OUTPUT:
        RETVAL

#                unsigned char   byte;
unsigned char
byte(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.byte;
        OUTPUT:
        RETVAL

#                unsigned short  word;
unsigned short
word(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.word;
        OUTPUT:
        RETVAL

#                uint32_t        dword;
uint32_t
dword(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.dword;
        OUTPUT:
        RETVAL

#                qword_t         qword;
qword_t
qword(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.qword;
        OUTPUT:
        RETVAL

#                float           sreal;
float
sreal(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.sreal;
        OUTPUT:
        RETVAL

#                double          dreal;
double
dreal(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.dreal;
        OUTPUT:
        RETVAL

#                /* misc large/non-native types */
#                unsigned char   extreal[10];
unsigned char*
extreal(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.extreal;
        OUTPUT:
        RETVAL

#                unsigned char   bcd[10];
unsigned char*
bcd(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.bcd;
        OUTPUT:
        RETVAL

#                qword_t         dqword[2];
# or qword_t *
qword_t
dqword(self)
	X86::Disasm::Op self
        CODE:
	qword_t result;
        RETVAL = (qword_t) *(self->data.dqword);
        OUTPUT:
        RETVAL

#                unsigned char   simd[16];
unsigned char*
simd(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.simd;
        OUTPUT:
        RETVAL

#                unsigned char   fpuenv[28];
unsigned char*
fpuenv(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.fpuenv;
        OUTPUT:
        RETVAL

#                /* offset from segment */
#                uint32_t        offset;
uint32_t
offset(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.offset;
        OUTPUT:
        RETVAL

#                /* ID of CPU register */
#                x86_reg_t       reg;
#x86_reg_t
X86::Disasm::Reg
reg(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = &(self->data.reg);
        OUTPUT:
        RETVAL

#                /* offsets from current insn */
#                char            relative_near;
char
relative_near(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.relative_near;
        OUTPUT:
        RETVAL

#                int32_t         relative_far;
int32_t
relative_far(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->data.relative_far;
        OUTPUT:
        RETVAL

#                /* segment:offset */
#                x86_absolute_t  absolute;
#x86_absolute_t
X86::Disasm::Absolute
absolute(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = &(self->data.absolute);
        OUTPUT:
        RETVAL

#                /* effective address [expression] */
#                x86_ea_t        expression;
#x86_ea_t
X86::Disasm::Ea
expression(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = &(self->data.expression);
        OUTPUT:
        RETVAL

#        } data;
#        /* this is needed to make formatting operands more sane */
#        void * insn;            /* pointer to x86_insn_t owning operand */
void *
insn(self)
	X86::Disasm::Op self
        CODE:
        RETVAL = self->insn;
        OUTPUT:
        RETVAL

#} x86_op_t;
 #void
 #DESTROY(self)
 #	X86::Disasm::Op self
 #        CODE:
 #	printf("IN DESTROY of X86::Disasm::Op\n");
 #	if (self != NULL)
 #	        safefree(self);

int 
x86_format_operand(op, buf, len, format)
	X86::Disasm::Op op
	char *buf
	int len
	enum x86_asm_format format

# SWIG wrote this better than I did - so I borrowed it
char * 
format(op, format)
	X86::Disasm::Op op
	enum x86_asm_format format
	CODE:
        char *buf, *str;
        size_t len;

        switch ( format ) {
          case xml_syntax:
            len = MAX_OP_XML_STRING;
            break;
          case raw_syntax:
            len = MAX_OP_RAW_STRING;
            break;
          case native_syntax:
          case intel_syntax:
          case att_syntax:
          case unknown_syntax:
          default:
            len = MAX_OP_STRING;
            break;
        }

        buf = (char * ) calloc( len + 1, 1 );
        x86_format_operand( op, buf, len, format );

        /* drop buffer down to a reasonable size */
        str = strdup( buf );
        free(buf);
        RETVAL = str;
	OUTPUT:
	RETVAL

MODULE = X86::Disasm		PACKAGE = X86::Disasm::Oplist

#/* Linked list of x86_op_t; provided for manual traversal of the operand
# * list in an insn. Users wishing to add operands to this list, e.g. to add
# * implicit operands, should use x86_operand_new in x86_operand_list.h */

X86::Disasm::Oplist
new(CLASS)
        char *CLASS
        CODE:
	x86_oplist_t *oplist = (x86_oplist_t *)safemalloc( sizeof(x86_oplist_t) );
	if (oplist == NULL)
	{
		fprintf(stderr, "out of memory\n");
		exit(1);
	}

	x86_op_t *op = (x86_op_t *)safemalloc( sizeof(x86_op_t) );
	if (op == NULL)
	{
		fprintf(stderr, "out of memory\n");
		exit(1);
	}

	
 	oplist->op = *op;
	oplist->next = NULL;

	RETVAL = oplist;

        OUTPUT:
        RETVAL

#typedef struct x86_operand_list {
#        x86_op_t op;
#x86_op_t
X86::Disasm::Op
op(self)
	X86::Disasm::Oplist self
        CODE:
        RETVAL = &(self->op);
        OUTPUT:
        RETVAL

#        struct x86_operand_list *next;
X86::Disasm::Oplist
next(self)
	X86::Disasm::Oplist self
        CODE:
        RETVAL = self->next;
        OUTPUT:
        RETVAL

#} x86_oplist_t;

 #void
 #DESTROY(self)
 #	X86::Disasm::Oplist self
 #        CODE:
 #	printf("IN DESTROY of X86::Disasm::Oplist\n");
 #	if (self != NULL)
 #	        safefree(self);

MODULE = X86::Disasm		PACKAGE = X86::Disasm::Insn

PROTOTYPES: ENABLE

X86::Disasm::Insn
new(CLASS)
        char *CLASS
        CODE:
        x86_insn_t *insn = (x86_insn_t *)safemalloc( sizeof(x86_insn_t) );
        if (insn == NULL)
        {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }
        RETVAL = insn;
        OUTPUT:
        RETVAL

void
DESTROY(self)
	X86::Disasm::Insn self
        CODE:
        safefree(self);

#typedef struct {
#        /* information about the instruction */
#        uint32_t addr;             /* load address */
uint32_t
addr(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->addr;
        OUTPUT:
        RETVAL

#        uint32_t offset;           /* offset into file/buffer */
uint32_t
offset(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->offset;
        OUTPUT:
        RETVAL

#        enum x86_insn_group group;      /* meta-type, e.g. INS_EXEC */
enum x86_insn_group
group(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->group;
        OUTPUT:
        RETVAL

#        enum X86::Disasm::Insnype type;        /* type, e.g. INS_BRANCH */
enum x86_insn_type
type(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->type;
        OUTPUT:
        RETVAL

#        enum x86_insn_note note;        /* note, e.g. RING0 */
enum x86_insn_note
note(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->note;
        OUTPUT:
        RETVAL

#        unsigned char bytes[MAX_INSN_SIZE];
unsigned char *
bytes(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->bytes;
        OUTPUT:
        RETVAL

#        unsigned char size;             /* size of insn in bytes */
unsigned char 
size(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->size;
        OUTPUT:
        RETVAL

#        /* 16/32-bit mode settings */
#        unsigned char addr_size;        /* default address size : 2 or 4 */
unsigned char 
addr_size(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->addr_size;
        OUTPUT:
        RETVAL

#        unsigned char op_size;          /* default operand size : 2 or 4 */
unsigned char 
op_size(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->op_size;
        OUTPUT:
        RETVAL

#        /* CPU/instruction set */
#        enum x86_insn_cpu cpu;
enum x86_insn_cpu
cpu(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->cpu;
        OUTPUT:
        RETVAL

#        enum x86_insn_isa isa;
enum x86_insn_isa
isa(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->isa;
        OUTPUT:
        RETVAL

#        /* flags */
#        enum x86_flag_status flags_set; /* flags set or tested by insn */
enum x86_flag_status
flags_set(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->flags_set;
        OUTPUT:
        RETVAL

#        enum x86_flag_status flags_tested;
enum x86_flag_status
flags_tested(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->flags_tested;
        OUTPUT:
        RETVAL

#        /* stack */
#        unsigned char stack_mod;        /* 0 or 1 : is the stack modified? */
unsigned char 
stack_mod(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->stack_mod;
        OUTPUT:
        RETVAL

#        int32_t stack_mod_val;          /* val stack is modified by if known */
int32_t
stack_mod_val(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->stack_mod_val;
        OUTPUT:
        RETVAL

#        /* the instruction proper */
#        enum x86_insn_prefix prefix;    /* prefixes ORed together */
enum x86_insn_prefix 
prefix(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->prefix;
        OUTPUT:
        RETVAL

#        char prefix_string[MAX_PREFIX_STR]; /* prefixes [might be truncated] */
char *
prefix_string(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->prefix_string;
        OUTPUT:
        RETVAL

#        char mnemonic[MAX_MNEM_STR];
char *
mnemonic(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->mnemonic;
        OUTPUT:
        RETVAL

#        x86_oplist_t *operands;         /* list of explicit/implicit operands */
X86::Disasm::Oplist
operands(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->operands;
        OUTPUT:
        RETVAL

#        size_t operand_count;           /* total number of operands */
size_t 
operand_count(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->operand_count;
        OUTPUT:
        RETVAL

#        size_t explicit_count;          /* number of explicit operands */
size_t 
explicit_count(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->explicit_count;
        OUTPUT:
        RETVAL

#        /* convenience fields for user */
#        void *block;                    /* code block containing this insn */
void *
block(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->block;
        OUTPUT:
        RETVAL

#        void *function;                 /* function containing this insn */
void *
function(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->function;
        OUTPUT:
        RETVAL

#        int tag;                        /* tag the insn as seen/processed */
int
tag(self)
        X86::Disasm::Insn self
        CODE:
	RETVAL = self->tag;
        OUTPUT:
        RETVAL

#} x86_insn_t;

int 
x86_format_mnemonic(insn, buf, len, format)
	x86_insn_t *insn
	char *buf
	int len
	enum x86_asm_format format


char * 
format_mnemonic(self, format)
	X86::Disasm::Insn self
	enum x86_asm_format format
	CODE:
        char *buf, *str;
        size_t len = MAX_MNEM_STR + MAX_PREFIX_STR + 4;

        buf = (char * ) calloc( len, 1 );
        x86_format_mnemonic( self, buf, len, format );

        /* drop buffer down to a reasonable size */
        str = strdup( buf );
        free(buf);

        RETVAL = str;
	OUTPUT:
	RETVAL

int 
x86_format_insn(insn, buf, len, format)
	x86_insn_t *insn
	char *buf
	int len
	enum x86_asm_format format

char * 
format_insn(self, format)
	X86::Disasm::Insn self
	enum x86_asm_format format
	CODE:
        char *buf, *str;
        size_t len;

        switch ( format ) {
          case xml_syntax:
            len = MAX_INSN_XML_STRING;
            break;
          case raw_syntax:
            len = MAX_INSN_RAW_STRING;
            break;
          case native_syntax:
          case intel_syntax:
          case att_syntax:
          case unknown_syntax:
          default:
            len = MAX_INSN_STRING;
            break;
        }

        buf = (char * ) calloc( len + 1, 1 );
        x86_format_insn( self, buf, len, format );

        /* drop buffer down to a reasonable size */
        str = strdup( buf );
        free(buf);
        RETVAL = str;
	OUTPUT:
	RETVAL

void 
x86_oplist_free(insn)
	X86::Disasm::Insn insn

int 
x86_operand_foreach(insn, func, arg, type)
	X86::Disasm::Insn insn
	x86_operand_fn func
	void *arg
	enum x86_op_foreach_type type

int 
x86_insn_is_valid(insn)
	X86::Disasm::Insn insn

int 
is_valid(self)
	X86::Disasm::Insn self
	CODE:
	RETVAL = x86_insn_is_valid(self);
	OUTPUT:
	RETVAL

size_t 
x86_operand_count(insn, type)
	X86::Disasm::Insn insn
	enum x86_op_foreach_type type

X86::Disasm::Op
x86_operand_1st(insn)
	X86::Disasm::Insn insn

X86::Disasm::Op
x86_operand_2nd(insn)
	X86::Disasm::Insn insn

X86::Disasm::Op
x86_operand_3rd(insn)
	X86::Disasm::Insn insn

uint32_t 
x86_get_address(insn)
	X86::Disasm::Insn insn

int32_t 
x86_get_rel_offset(insn)
	X86::Disasm::Insn insn

X86::Disasm::Op
x86_get_branch_target(insn)
	X86::Disasm::Insn insn

X86::Disasm::Op
x86_get_imm(insn)
	X86::Disasm::Insn insn

unsigned char * 
x86_get_raw_imm(insn)
	X86::Disasm::Insn insn

void 
x86_set_insn_addr(insn, addr)
	X86::Disasm::Insn insn
	uint32_t addr

void 
x86_set_insn_offset(insn, offset)
	X86::Disasm::Insn insn
	unsigned int offset

void 
x86_set_insn_function(insn, func)
	X86::Disasm::Insn insn
	void * func

void
x86_set_insn_block(insn, block)
	X86::Disasm::Insn insn
	void * block

void 
x86_tag_insn(insn)
	X86::Disasm::Insn insn

void 
x86_untag_insn(insn)
	X86::Disasm::Insn insn

int 
x86_insn_is_tagged(insn)
	X86::Disasm::Insn insn

MODULE = X86::Disasm		PACKAGE = X86::Disasm		

PROTOTYPES: ENABLE

int
x86_init( options, reporter, arg)
	enum x86_options options
	DISASM_REPORTER reporter
	void *arg

int
init(options, reporter, reporter_args)
        enum x86_options options
        SV * reporter
        void *reporter_args
        CODE:
 # fprintf(stderr, "REPORTER is %p, %lx, %d\n", reporter, reporter, SvIV(reporter));
        if (SvIV(reporter))
        {
          init_reporter_sv = (SV *)reporter;
          RETVAL = x86_init( options, reporter_callback, reporter_args);
          init_reporter_sv = NULL;
        }
        else
        {
          RETVAL = x86_init( options, NULL, NULL);
        }
	OUTPUT:
	RETVAL

void 
x86_set_reporter(reporter, arg)
	DISASM_REPORTER reporter
	void *arg

void 
x86_set_options(options)
	enum x86_options options

enum x86_options 
x86_get_options()

int 
x86_cleanup()

int 
x86_disasm(buf, buf_len, buf_rva, offset, insn)
	unsigned char *buf
	unsigned int buf_len
	unsigned long buf_rva
	unsigned int offset
	X86::Disasm::Insn insn

 # unsigned int 
 # x86_disasm_range(buf, buf_rva, offset, len, func, arg)
 # 	unsigned char *buf
 # 	uint32_t buf_rva
 # 	unsigned int offset
 # 	unsigned int len
 #  	DISASM_CALLBACK func
 # 	void *arg
 # 
 # unsigned int 
 # disasm_range(buf, buf_rva, offset, len, callback, callback_args)
 # 	unsigned char *buf
 # 	uint32_t buf_rva
 # 	unsigned int offset
 # 	unsigned int len
 #   	SV * callback
 # 	void *callback_args
 # 	CODE:
 # 	range_callback_sv = (SV *)callback;
 # 
 # 	RETVAL = x86_disasm_range(buf, buf_rva, offset, len, range_callback, callback_args);
 # 
 #   	range_callback_sv = NULL;
 # 	OUTPUT:
 #   	RETVAL
 # 
 # unsigned int 
 # x86_disasm_forward(buf, buf_len, buf_rva, offset, func, arg, resolver, r_arg)
 # 	unsigned char *buf
 # 	unsigned int buf_len
 # 	uint32_t buf_rva
 # 	unsigned int offset
 # 	DISASM_CALLBACK func
 # 	void *arg
 # 	DISASM_RESOLVER resolver
 # 	void *r_arg
 # 
 # unsigned int 
 # disasm_forward(buf, buf_len, buf_rva, offset, callback, callback_args, resolver, resolver_args)
 # 	unsigned char *buf
 # 	unsigned int buf_len
 # 	uint32_t buf_rva
 # 	unsigned int offset
 #   	SV * callback
 # 	void *callback_args
 #   	SV * resolver
 # 	void *resolver_args
 # 	CODE:
 # 	forward_callback_sv = (SV *)callback;
 # 	forward_resolver_sv = (SV *)resolver;
 # 
 # 	RETVAL = x86_disasm_forward(buf, buf_len, buf_rva, offset, forward_callback, callback_args, forward_resolver, resolver_args);
 # 
 #   	forward_callback_sv = NULL;
 # 	forward_resolver_sv = NULL;
 # 	OUTPUT:
 #   	RETVAL

unsigned int 
x86_operand_size(op)
	x86_op_t *op

int
x86_format_header(buf, len, format)
	char *buf
	int len
	enum x86_asm_format format

unsigned int 
x86_endian()

unsigned int 
x86_addr_size()

unsigned int 
x86_op_size()

unsigned int 
x86_word_size()

unsigned int 
x86_max_insn_size()

unsigned int 
x86_sp_reg()

unsigned int 
x86_fp_reg()

unsigned int 
x86_ip_reg()

unsigned int 
x86_flag_reg()

void 
x86_reg_from_id(id, reg)
	unsigned int id
	X86::Disasm::Reg reg

size_t 
x86_invariant_disasm(buf, buf_len, inv)
	unsigned char *buf
	int buf_len
	x86_invariant_t *inv

size_t 
x86_size_disasm(buf, buf_len)
	unsigned char *buf
	int buf_len
