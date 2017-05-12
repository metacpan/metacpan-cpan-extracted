#include "perl.h"

#ifndef MAX_LEVEL
#include <limits.h>
#define MAX_LEVEL UCHAR_MAX
#endif

#define NODESIZE(N) sizeof(Node) + (sizeof(SV*) * (N+1))

#define SV2NODE(S) INT2PTR(Node*, SvIV(SvRV(S)))

#define IV2NODE(S) INT2PTR(Node*, S)

typedef struct {
  SV*   key;
  SV*   value;
  int   child_count;
  SV*   next[]; 
} Node;

Node * new(int child_count);
void DESTROY(Node * n);

int child_count(Node * n);

SV* get_child(Node * n, int index);
SV* get_child_or_undef(Node * n, int index);
void set_child(Node* n, int index, SV* t);

void set_key(Node *n, SV* k);
void force_set_key(Node *n, SV* k);
SV* get_key(Node *n);
I32 key_cmp(Node* n, SV* k);

void set_value(Node *n, SV* v);
SV* get_value(Node *n);

int _allocated(Node* n);

