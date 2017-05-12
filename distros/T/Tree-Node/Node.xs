#if USE_MALLOC
#include <malloc.h>
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#include "ppport.h"

#include "TreeNode.h"

/*

   Since an IV is large enough to hold a pointer (see <perlguts>), we
   use that to store the new node information.

*/

MODULE = Tree::Node PACKAGE = Tree::Node

PROTOTYPES: ENABLE

SV*
new(package, child_count)
    char *package
    int  child_count
  PROTOTYPE: $$
  CODE:
    Node* self = new(child_count);
    SV*   n    = newSViv((IV) self);
    RETVAL     = newRV_noinc(n);
    sv_bless(RETVAL, gv_stashpv(package, 0));
    SvREADONLY_on(n);
    while (child_count--)
      self->next[child_count] = &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
to_p_node(n)
    SV* n
  PROTOTYPE: $
  CODE:
    RETVAL = (IV) SV2NODE(n);
  OUTPUT:
    RETVAL

IV
p_new(child_count)
    int  child_count
  PROTOTYPE: $$
  CODE:
    Node* self = new(child_count);
    while (child_count--)
      self->next[child_count] = NULL;
    RETVAL = (IV) self;
  OUTPUT:
    RETVAL

void
DESTROY(n)
    SV* n
  PROTOTYPE: $
  CODE:
    Node* self = SV2NODE(n);
    int child_count = self->child_count;
    while (child_count--)
      SvREFCNT_dec(self->next[child_count]);
    DESTROY(self);

void
p_destroy(self)
    IV self
  PROTOTYPE: $
  CODE:
    if (self) DESTROY(IV2NODE(self));

int
MAX_LEVEL()
  PROTOTYPE:
  CODE:
    RETVAL = MAX_LEVEL;
  OUTPUT:
    RETVAL

int
_allocated_by_child_count(count)
    int count
  PROTOTYPE: $
  CODE:
    RETVAL = NODESIZE(count);
  OUTPUT:
    RETVAL

int
_allocated(n)
    SV* n
  PROTOTYPE: $
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = _allocated(self);
  OUTPUT:
    RETVAL

int
p_allocated(n)
    IV n
  PROTOTYPE: $
  CODE:
    RETVAL = _allocated(IV2NODE(n));
  OUTPUT:
    RETVAL


void
add_children(n, ...)
    SV* n
  ALIAS:
    add_children_left = 1
  PROTOTYPE: $;@
  PREINIT:
    int num = 1;
  CODE:
    Node* back;
    Node* self = SV2NODE(n);
    int   count = self->child_count;
    int   i;

    num = items-1;

    if (num<1)
      croak("number of children to add must be >= 1");
    if ((count+num) > MAX_LEVEL)
      croak("cannot %d children: we already have %d children", num, count);

    back = self;
#if USE_MALLOC
    self = realloc(self, (size_t) NODESIZE(count+num));
    if (self==NULL)
      croak("unable to allocate additional memory");
#else
    Renewc(self, NODESIZE(count+num), char, Node);
#endif

    if (self != back) {
      SvREADONLY_off((SV*)SvRV(n));
      sv_setiv((SV*) SvRV(n), (IV) self);
      SvREADONLY_on((SV*)SvRV(n));
    }

    self->child_count += num;

    if (ix==0) {
      for(i=0; i<num; i++)
        self->next[count+i] = newSVsv(ST(i+1));
    }
    else if (ix==1) {
      for(i=(count-1); i>=0; i--)
        self->next[i+num] = self->next[i];
      for(i=0; i<num; i++)
        self->next[i] = newSVsv(ST(i+1));
    }

int
child_count(n)
    SV* n
  PROTOTYPE: $
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = child_count(self);
  OUTPUT:
    RETVAL

int
p_child_count(self)
    IV self;
  PROTOTYPE: $
  CODE:
    RETVAL = child_count(IV2NODE(self));
  OUTPUT:
    RETVAL

void
get_children(n)
    SV* n
  PROTOTYPE: $
  PREINIT:
    int i;
  PPCODE:
    Node* self = SV2NODE(n);
    EXTEND(SP, self->child_count);
    for (i = 0; i < self->child_count; i++)
      PUSHs(get_child(self, i));

SV*
get_child(n, index)
    SV* n
    int index
  PROTOTYPE: $$
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = get_child(self, index);
  OUTPUT:
    RETVAL

IV
p_get_child(n, index);
    IV n;
    int index
  PROTOTYPE: $$
  CODE:
    Node* self = IV2NODE(n);
    if ((index >= self->child_count) || (index < 0))
      croak("index out of bounds: must be between [0..%d]", self->child_count-1);
    RETVAL = (IV) self->next[index];
  OUTPUT:
    RETVAL

IV
p_get_child_or_null(n, index);
    IV n;
    int index
  PROTOTYPE: $$
  CODE:
    Node* self = IV2NODE(n);
    if ((index >= self->child_count) || (index < 0))
      RETVAL = (IV) NULL;
    else
      RETVAL = (IV) self->next[index];
  OUTPUT:
    RETVAL


SV*
get_child_or_undef(n, index)
    SV* n
    int index
  PROTOTYPE: $$
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = get_child_or_undef(self, index);
  OUTPUT:
    RETVAL

void
set_child(n, index, t)
    SV* n
    int index
    SV* t
  PROTOTYPE: $$$
  CODE:
    Node* self = SV2NODE(n);
    set_child(self, index, t);

void
p_set_child(n, index, t)
    IV n
    int index
    IV t
  PROTOTYPE: $$$
  CODE:
    Node* self = IV2NODE(n);
    if ((index >= self->child_count) || (index < 0))
      croak("index out of bounds: must be between [0..%d]", self->child_count-1);
    self->next[index] = (SV*) t;

void
set_key(n, k)
    SV* n
    SV* k
  PROTOTYPE: $$
  CODE:
    Node* self = SV2NODE(n);
    set_key(self, k);

void
force_set_key(n, k)
    SV* n
    SV* k
  PROTOTYPE: $$
  CODE:
    Node* self = SV2NODE(n);
    force_set_key(self, k);

void
p_set_key(n, k)
    IV n
    SV* k
  PROTOTYPE: $$
  CODE:
    set_key(IV2NODE(n), k);

void
p_force_set_key(n, k)
    IV n
    SV* k
  PROTOTYPE: $$
  CODE:
    force_set_key(IV2NODE(n), k);

SV*
key(n)
    SV* n
  PROTOTYPE: $
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = get_key(self);
  OUTPUT:
    RETVAL

SV*
p_get_key(n)
    IV n
  PROTOTYPE: $
  CODE:
    RETVAL = get_key(IV2NODE(n));
  OUTPUT:
    RETVAL

I32
p_key_cmp(n, k)
    IV n
    SV* k
  PROTOTYPE: $$
  CODE:
    RETVAL = key_cmp(IV2NODE(n), k);
  OUTPUT:
    RETVAL

I32
key_cmp(n, k)
    SV* n
    SV* k
  PROTOTYPE: $$
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = key_cmp(self, k);
  OUTPUT:
    RETVAL

void
set_value(n, v)
    SV* n
    SV* v
  PROTOTYPE: $$
  CODE:
    Node* self = SV2NODE(n);
    set_value(self, v);

void
p_set_value(n, v)
    IV n
    SV* v
  PROTOTYPE: $$
  CODE:
    set_value(IV2NODE(n), v);

SV*
value(n)
    SV* n
  PROTOTYPE: $
  CODE:
    Node* self = SV2NODE(n);
    RETVAL = get_value(self);
  OUTPUT:
    RETVAL

SV*
p_get_value(n)
    IV n
  PROTOTYPE: $
  CODE:
    RETVAL = get_value(IV2NODE(n));
  OUTPUT:
    RETVAL
