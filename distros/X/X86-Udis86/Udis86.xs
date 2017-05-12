#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <src/udis86.h>

#include "const-c.inc"

typedef ud_t *X86__Udis86;
typedef const ud_operand_t *X86__Udis86__Operand;

static ud_t my_ud_obj;

ud_t* _new()
{
	ud_init(&my_ud_obj);

	return(&my_ud_obj);
}

MODULE = X86::Udis86		PACKAGE = X86::Udis86::Operand

 #X86::Udis86::Operand
 #new(CLASS)
 #        char *CLASS
 #        CODE:
 #        ud_operand_t *operand = (ud_operand_t *)safemalloc( sizeof(ud_operand_t) );
 #        if (operand == NULL)
 #        {
 #                fprintf(stderr, "out of memory\n");
 #                exit(1);
 #        }
 #        RETVAL = operand;
 #
 #        OUTPUT:
 #        RETVAL

#        /* operand size */
unsigned int
size(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->size;
        OUTPUT:
        RETVAL

#        /* operand type */
enum ud_type 
type(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->type;
        OUTPUT:
        RETVAL

#        /* operand base */
enum ud_type
base(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->base;
        OUTPUT:
        RETVAL

#        /* operand index */
enum ud_type
index(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->index;
        OUTPUT:
        RETVAL

#        /* operand scale */
unsigned int
scale(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->scale;
        OUTPUT:
        RETVAL

#        /* operand offset */
unsigned int
offset(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->offset;
        OUTPUT:
        RETVAL

#        /* operand lval_sbyte */
char
lval_sbyte(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.sbyte;
        OUTPUT:
        RETVAL

#        /* operand lval_ubyte */
unsigned char
lval_ubyte(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.ubyte;
        OUTPUT:
        RETVAL

#        /* operand lval_sword */
int
lval_sword(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.sword;
        OUTPUT:
        RETVAL

#        /* operand lval_uword */
unsigned int
lval_uword(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.uword;
        OUTPUT:
        RETVAL

#        /* operand lval_sdword */
int
lval_sdword(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.sdword;
        OUTPUT:
        RETVAL

#        /* operand lval_udword */
unsigned int
lval_udword(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.udword;
        OUTPUT:
        RETVAL

#        /* operand lval_sqword */
int
lval_sqword(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.sqword;
        OUTPUT:
        RETVAL

#        /* operand lval_uqword */
unsigned int
lval_uqword(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.uqword;
        OUTPUT:
        RETVAL

#        /* operand lval_ptr_seg */
unsigned int
lval_ptr_seg(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.ptr.seg;
        OUTPUT:
        RETVAL

#        /* operand lval_ptr_off */
unsigned int
lval_ptr_off(self)
        X86::Udis86::Operand self
        CODE:
        RETVAL = self->lval.ptr.off;
        OUTPUT:
        RETVAL

MODULE = X86::Udis86		PACKAGE = X86::Udis86

INCLUDE: const-xs.inc

X86::Udis86
new(CLASS)
        char *CLASS
        CODE:
        RETVAL = _new();

        OUTPUT:
        RETVAL

void 
set_input_buffer(self, buffer, size);
        X86::Udis86 self
        unsigned char *buffer
        size_t size
        CODE:
	ud_set_input_buffer(self, buffer, size);

void
set_input_file(self, file)
        X86::Udis86 self
        FILE *file
        CODE:
	ud_set_input_file(self, file);

 #void
 #set_input_hook(self, hook)
 #        X86::Udis86 self
 #        int (*hook)(struct ud*));
 #        CODE:
 #	ud_set_input_hook(self, hook);

void
input_skip(self, n)
        X86::Udis86 self
	size_t n
        CODE:
	ud_input_skip(self, n);

int
input_end(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_input_end(self);

        OUTPUT:
        RETVAL

void 
set_user_opaque_data(self, opaque)
        X86::Udis86 self
        void *opaque
	CODE:
	ud_set_user_opaque_data(self, opaque);

void *
get_user_opaque_data(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_get_user_opaque_data(self);

        OUTPUT:
        RETVAL

void
set_mode(self, mode)
        X86::Udis86 self
        int mode
        CODE:
	ud_set_mode(self, mode);

void 
set_pc(self, pc)
        X86::Udis86 self
        unsigned int pc
	CODE:
	ud_set_pc(self, pc);

void
set_syntax(self, syntax)
        X86::Udis86 self
        char *syntax
	char *intel = "intel";
	char *att = "att";
        CODE:
        if (strncmp(syntax, intel, strlen(intel)) == 0)
		ud_set_syntax(self, UD_SYN_INTEL);
        if (strncmp(syntax, att, strlen(att)) == 0)
		ud_set_syntax(self, UD_SYN_ATT);

void
set_vendor(self, vendor)
        X86::Udis86 self
        char *vendor
	char *intel = "intel";
	char *amd = "amd";
        CODE:
        if (strncmp(vendor, intel, strlen(intel)) == 0)
		ud_set_vendor(self, UD_VENDOR_INTEL);
        if (strncmp(vendor, amd, strlen(amd)) == 0)
		ud_set_vendor(self, UD_VENDOR_AMD);

unsigned int 
disassemble(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_disassemble(self);

        OUTPUT:
        RETVAL

unsigned int 
insn_len(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_insn_len(self);

        OUTPUT:
        RETVAL

unsigned int 
insn_off(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_insn_off(self);

        OUTPUT:
        RETVAL

const char* 
insn_hex(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_insn_hex(self);

        OUTPUT:
        RETVAL

unsigned long* 
insn_ptr(self)
        X86::Udis86 self
        CODE:
        RETVAL = (unsigned long *) ud_insn_ptr(self);

        OUTPUT:
        RETVAL

const char* 
insn_asm(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_insn_asm(self);

        OUTPUT:
        RETVAL

X86::Udis86::Operand
#const X86::Udis86::Operand
#const ud_operand_t*
#const X86::Udis86::Operand*
insn_opr(self, n)
        X86::Udis86 self
        int n
        CODE:
#        RETVAL = (ud_operand_t *) ud_insn_opr(self, n);
        RETVAL = (const ud_operand_t *) ud_insn_opr(self, n);
#        RETVAL = ud_insn_opr(self, n);

        OUTPUT:
        RETVAL

enum ud_mnemonic_code
insn_mnemonic(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_insn_mnemonic(self);

        OUTPUT:
        RETVAL


#ud_mnemonic_code_t ud_obj->mnemonic

const char*
lookup_mnemonic(self)
        X86::Udis86 self
        CODE:
        RETVAL = ud_lookup_mnemonic(ud_insn_mnemonic(self));

        OUTPUT:
        RETVAL

#ud_obj->pfx_rex

int
pfx_rex(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_rex;

        OUTPUT:
        RETVAL

#ud_obj->pfx_seg

int
pfx_seg(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_seg;

        OUTPUT:
        RETVAL

#ud_obj->pfx_opr

int
pfx_opr(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_opr;

        OUTPUT:
        RETVAL

#ud_obj->pfx_adr

int
pfx_adr(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_adr;

        OUTPUT:
        RETVAL

#ud_obj->pfx_lock

int
pfx_lock(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_lock;

        OUTPUT:
        RETVAL

#ud_obj->pfx_rep

int
pfx_rep(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_rep;

        OUTPUT:
        RETVAL

#ud_obj->pfx_repe

int
pfx_repe(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_repe;

        OUTPUT:
        RETVAL

#ud_obj->pfx_repne

int
pfx_repne(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pfx_repne;

        OUTPUT:
        RETVAL

#uint64_t ud_obj->pc

uint64_t
pc(self)
        X86::Udis86 self
        CODE:
        RETVAL = self->pc;

        OUTPUT:
        RETVAL
