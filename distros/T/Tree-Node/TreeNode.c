
#include <stdlib.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "TreeNode.h"

Node * new(int child_count)
{
  Node * n;

  if ((child_count < 1) || (child_count > MAX_LEVEL))
    croak("child_count out of bounds: must be between [1..%d]", MAX_LEVEL);

#if USE_MALLOC
  n = malloc((size_t) NODESIZE(child_count));
  if (n == NULL)
    croak("unable to a allocate memory");
#else
  Newc(1, n, NODESIZE(child_count), char, Node);
#endif

  n->child_count  = child_count;

  n->key   = &PL_sv_undef;
  n->value = &PL_sv_undef;

  return n;
}

void DESTROY(Node* n)
{
  SvREFCNT_dec(n->key);
  SvREFCNT_dec(n->value);

#if USE_MALLOC
  free(n);
#else
  Safefree(n);
#endif
}

int child_count(Node * n)
{
  return n->child_count; 
}

SV* get_child(Node * n, int index)
{
  if ((index >= n->child_count) || (index < 0))
    croak("index out of bounds: must be between [0..%d]", n->child_count-1);

  return SvREFCNT_inc(n->next[index]);
}

SV* get_child_or_undef(Node * n, int index)
{
  if ((index >= n->child_count) || (index < 0))
    return &PL_sv_undef;
  else
    return SvREFCNT_inc(n->next[index]);
}

void set_child(Node* n, int index, SV* t)
{
  if ((index >= n->child_count) || (index < 0))
    croak("index out of bounds: must be between [0..%d]", n->child_count-1);

  if (SvOK(n->next[index]))
    sv_setsv(n->next[index], t);
  else
    n->next[index] = newSVsv(t);
}

void set_key(Node *n, SV* k)
{
  if (SvOK(n->key)) {
    croak("key is already set");
  }
  else {
    n->key = newRV_inc(k);
  }
}

void force_set_key(Node *n, SV* k)
{
  if (SvOK(n->key)) {
    warn("key is already set");
  }
  n->key = newRV_inc(k);
}

SV* get_key(Node *n)
{
  if (SvOK(n->key)) {
    return SvREFCNT_inc(SvRV(n->key));
  }
  else {
    return &PL_sv_undef;
  }
}

I32 key_cmp(Node* n, SV* k)
{
  if (SvOK(n->key)) {
    return sv_cmp(SvRV(n->key), k);
  }
  else {
    return -1;
  }
}

void set_value(Node *n, SV* v)
{
  n->value = newRV_inc(v);
}

SV* get_value(Node *n)
{
  if (SvOK(n->key)) {
    return SvREFCNT_inc(SvRV(n->value));
  }
  else {
    return &PL_sv_undef;
  }
}

int _allocated(Node* n)
{
  return NODESIZE(n->child_count);
}
