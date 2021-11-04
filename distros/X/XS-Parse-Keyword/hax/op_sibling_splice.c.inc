/* vi: set ft=c : */

#ifndef op_sibling_splice
#  define op_sibling_splice(parent, start, del_count, insert)  S_op_sibling_splice(aTHX_ parent, start, del_count, insert)
static OP *S_op_sibling_splice(pTHX_ OP *parent, OP *start, int del_count, OP *insert)
{
  OP *deleted = NULL;

  if(!insert && !del_count)
    return NULL;

  OP **prevp;
  if(start)
    prevp = &(start->op_sibling);
  else
    prevp = &(cLISTOPx(parent)->op_first);

  OP *after = *prevp;

  if(del_count) {
    croak("Back-compat op_sibling_splice with del_count != 0 not yet implemented");
    /* THIS IS AS YET UNTESTED
    deleted = *prevp;
    OP *o = deleted;
    while(del_count > 1)
      o = o->op_sibling, del_count--;
    after = o->op_sibling;
    o->op_sibling = NULL;
    */
  }

  if(insert) {
    *prevp = insert;
    OP *o = insert;
    while(o->op_sibling)
      o = o->op_sibling;
    o->op_sibling = after;
  }
  else
    *prevp = after;

  return deleted;
}
#endif
