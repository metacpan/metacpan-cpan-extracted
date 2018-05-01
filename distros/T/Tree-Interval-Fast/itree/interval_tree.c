/*
 * Libitree: an interval tree library in C 
 *
 * Copyright (C) 2018 Alessandro Vullo 
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
*/


/*
  Interval Tree library

  This is an adaptation of the AVL balanced tree C library
  created by Julienne Walker which can be found here:

  http://www.eternallyconfuzzled.com/Libraries.aspx

*/
#include "interval_tree.h"

#ifdef __cplusplus
#include <cstdlib>

using std::malloc;
using std::free;
using std::size_t;
#else
#include <stdlib.h>
#include <stdio.h>
#endif

#ifndef HEIGHT_LIMIT
#define HEIGHT_LIMIT 64 /* Tallest allowable tree */
#endif

typedef struct itreenode {
  int               balance;   /* Balance factor */
  float             max;       /* Maximum high value in the subtree rooted at this node */
  interval_t       *interval;  /* The interval the node represents */
  struct itreenode *link[2];   /* Left (0) and right (1) links */
} itreenode_t;

struct itree {
  itreenode_t *root; /* Top of the tree */
  dup_f        dup;    /* Clone an interval data item (user-defined) */
  rel_f        rel;    /* Destroy an interval data item (user-defined) */
  size_t       size;   /* Number of items (user-defined) */
};

struct itreetrav {
  itree_t     *tree;               /* Paired tree */
  itreenode_t *it;                 /* Current node */
  itreenode_t *path[HEIGHT_LIMIT]; /* Traversal path */
  size_t       top;                /* Top of stack */
};
  
/* Two way single rotation */
#define single(root,dir) do {         \
  itreenode_t *save = root->link[!dir]; \
  root->link[!dir] = save->link[dir];     \
  save->link[dir] = root;                 \
  root = save;                            \
} while (0)

/* Two way double rotation */
#define double(root,dir) do {                    \
  itreenode_t *save = root->link[!dir]->link[dir]; \
  root->link[!dir]->link[dir] = save->link[!dir];    \
  save->link[!dir] = root->link[!dir];               \
  root->link[!dir] = save;                           \
  save = root->link[!dir];                           \
  root->link[!dir] = save->link[dir];                \
  save->link[dir] = root;                            \
  root = save;                                       \
} while (0)

/* Adjust balance before double rotation */
#define adjust_balance(root,dir,bal) do { \
  itreenode_t *n = root->link[dir];         \
  itreenode_t *nn = n->link[!dir];          \
  if ( nn->balance == 0 )                     \
    root->balance = n->balance = 0;           \
  else if ( nn->balance == bal ) {            \
    root->balance = -bal;                     \
    n->balance = 0;                           \
  }                                           \
  else { /* nn->balance == -bal */            \
    root->balance = 0;                        \
    n->balance = bal;                         \
  }                                           \
  nn->balance = 0;                            \
} while (0)

/* Rebalance after insertion */
#define insert_balance(root,dir) do {  \
  itreenode_t *n = root->link[dir];      \
  int bal = dir == 0 ? -1 : +1;            \
  if ( n->balance == bal ) {               \
    root->balance = n->balance = 0;        \
    single ( root, !dir );             \
  }                                        \
  else { /* n->balance == -bal */          \
    adjust_balance ( root, dir, bal ); \
    double ( root, !dir );             \
  }                                        \
} while (0)

/* Rebalance after deletion */
#define remove_balance(root,dir,done) do { \
  itreenode_t *n = root->link[!dir];         \
  int bal = dir == 0 ? -1 : +1;                \
  if ( n->balance == -bal ) {                  \
    root->balance = n->balance = 0;            \
    single ( root, dir );                  \
  }                                            \
  else if ( n->balance == bal ) {              \
    adjust_balance ( root, !dir, -bal );   \
    double ( root, dir );                  \
  }                                            \
  else { /* n->balance == 0 */                 \
    root->balance = -bal;                      \
    n->balance = bal;                          \
    single ( root, dir );                  \
    done = 1;                                  \
  }                                            \
} while (0)

static itreenode_t *new_node ( itree_t *tree, interval_t *i )
{
  itreenode_t *rn = (itreenode_t *)malloc ( sizeof *rn );

  if ( rn == NULL )
    return NULL;

  rn->interval = (interval_t *)malloc ( sizeof(interval_t) );
  
  if ( rn->interval == NULL )
    return NULL;
  
  rn->interval->low = i->low;
  rn->interval->high = i->high;
  rn->interval->data = tree->dup ( i->data );

  rn->balance = 0;
  rn->max = i->high;
  rn->link[0] = rn->link[1] = NULL;

  return rn;
}

itree_t *itree_new ( dup_f dup, rel_f rel )
{
  itree_t *rt = (itree_t *)malloc ( sizeof *rt );

  if ( rt == NULL )
    return NULL;

  rt->root = NULL;
  rt->dup = dup;
  rt->rel = rel;
  rt->size = 0;

  return rt;
}

void itree_delete ( itree_t *tree )
{
  itreenode_t *it = tree->root;
  itreenode_t *save;

  /* Destruction by rotation */
  while ( it != NULL ) {
    if ( it->link[0] == NULL ) {
      /* Remove node */
      save = it->link[1];
      tree->rel ( it->interval->data );
      free ( it->interval );
      free ( it );
    }
    else {
      /* Rotate right */
      save = it->link[0];
      it->link[0] = save->link[1];
      save->link[1] = it;
    }

    it = save;
  }

  free ( tree );
}

interval_t *itree_find ( itree_t *tree, interval_t *interval )
{
  itreenode_t *it = tree->root;

  while ( it != NULL ) {
    /* int cmp = tree->cmp ( it->data, data ); */

    /* if ( cmp == 0 ) */
    /*   break; */

    /* it = it->link[cmp < 0]; */

    if ( interval_overlap( it->interval, interval ) )
      break;

    it = it->link[it->link[0] == NULL || it->link[0]->max < interval->low];
  }

  return it == NULL ? NULL : it->interval;
}

void search ( itreenode_t *node, interval_t *interval, ilist_t *results )
{

  /*
   * If interval is to the right of the rightmost point of any interval 
   * in this node and all its children, there won't be any matches
   */
  if ( node == NULL || interval->low > node->max ) 
    return;

  /* search the left subtree */
  if ( node->link[0] != NULL && node->link[0]->max >= interval->low )
    search ( node->link[0], interval, results );

  /* search this node */
  if ( interval_overlap ( node->interval, interval ) )
    ilist_append ( results, node->interval );

  /*
   * if interval is to the left of the start of this interval
   * it can't be in any child to the right
   */
  if ( interval->high < node->interval->low )
    return;

  /* search the right subtree */
  search ( node->link[1], interval, results );
}

ilist_t *itree_findall( itree_t *tree, interval_t *interval )
{

  ilist_t* results = ilist_new();
  
  if ( results != NULL ) {
    /* empty tree case */
    if ( tree->root == NULL )
      return results;

    search ( tree->root, interval, results );
  }

  return results;
}

int itree_insert ( itree_t *tree, interval_t *interval )
{
  /* Empty tree case */
  if ( tree->root == NULL ) {
    tree->root = new_node ( tree, interval );
    if ( tree->root == NULL )
      return 0;
  }
  else {
    itreenode_t head = {0}; /* Temporary tree root */
    itreenode_t *s, *t;     /* Place to rebalance and parent */
    itreenode_t *p, *q;     /* Iterator and save pointer to the newly inserted node */
    int dir;

    /* Set up false root to ease maintenance */
    t = &head;
    t->link[1] = tree->root;

    /* Search down the tree, saving rebalance points */
    for ( s = p = t->link[1]; ; p = q ) {
      /* Duplicates admitted, placed in the right subtree */
      dir = p->interval->low <= interval->low; /* tree->cmp ( p->data, data ) < 0; */
      q = p->link[dir];

      p->max = p->max < interval->high ? interval->high : p->max; /* Update ancestor's max if needed */

      if ( q == NULL )
        break;
      
      if ( q->balance != 0 ) {
        t = p;
        s = q;
      }
      
    }

    p->link[dir] = q = new_node ( tree, interval );
    if ( q == NULL )
      return 0; /* TODO: should rollback to previous ancestors' max values */

    /* Update balance factors */
    for ( p = s; p != q; p = p->link[dir] ) {
      dir = p->interval->low <= interval->low; /* tree->cmp ( p->data, data ) < 0; */
      p->balance += dir == 0 ? -1 : +1;
    }

    q = s; /* Save rebalance point for parent fix */

    /* Rebalance if necessary */
    if ( abs ( s->balance ) > 1 ) {
      dir = s->interval->low <= interval->low; /* tree->cmp ( s->data, data ) < 0; */
      insert_balance ( s, dir );
    }

    /* Fix parent */
    if ( q == head.link[1] )
      tree->root = s;
    else
      t->link[q == t->link[1]] = s;
  }

  ++tree->size;

  return 1;
}

int itree_remove ( itree_t *tree, interval_t *interval )
{
  if ( tree->root != NULL ) {
    itreenode_t *it, *up[HEIGHT_LIMIT];
    int upd[HEIGHT_LIMIT], top = 0, top_max;
    int done = 0;

    it = tree->root;

    /* Search down tree and save path */
    for ( ; ; ) {
      if ( it == NULL )
        return 0;
      else if ( interval_equal ( it->interval, interval ) ) /* ( tree->cmp ( it->data, data ) == 0 ) */
        break;

      /* Push direction and node onto stack */
      upd[top] = it->interval->low <= interval->low; /* tree->cmp ( it->data, data ) < 0; */
      up[top++] = it;

      it = it->link[upd[top - 1]];
    }

    /* Remove the node */
    if ( it->link[0] == NULL || it->link[1] == NULL ) {
      /* Which child is not null? */
      int dir = it->link[0] == NULL;

      /* Fix parent */
      if ( top != 0 )
        up[top - 1]->link[upd[top - 1]] = it->link[dir];
      else
        tree->root = it->link[dir];

      tree->rel ( it->interval->data );
      free ( it->interval );
      free ( it );
    }
    else {
      /* Find the inorder successor */
      itreenode_t *heir = it->link[1];
      void *save;
      
      /* Save this path too */
      upd[top] = 1;
      up[top++] = it;

      while ( heir->link[0] != NULL ) {
        upd[top] = 0;
        up[top++] = heir;
        heir = heir->link[0];
      }

      /* Swap data */
      save = it->interval;
      it->interval = heir->interval;
      heir->interval = save;

      /* Unlink successor and fix parent */
      up[top - 1]->link[up[top - 1] == it] = heir->link[1];

      tree->rel ( heir->interval->data );
      free ( heir->interval );
      free ( heir );
    }

    /* Update max: walk back up the search path and bubbles up to root */
    top_max = top;
    
    while ( --top_max >= 0 ) {
      
      itreenode_t *left = up[top_max]->link[0], *right = up[top_max]->link[1];
      
      if ( left != NULL && right != NULL ) {
	float left_right_max = left->max < right->max ? right->max : left->max;
	up[top_max]->max = up[top_max]->interval->high < left_right_max ? left_right_max : up[top_max]->interval->high;
      } else if ( left != NULL && right == NULL ) {
	up[top_max]->max = up[top_max]->interval->high < left->max ? left->max : up[top_max]->interval->high;
      } else if ( left == NULL && right != NULL ) {
	up[top_max]->max = up[top_max]->interval->high < right->max ? right->max : up[top_max]->interval->high;
      } else
	up[top_max]->max = up[top_max]->interval->high;
    }
    
    /* Walk back up the search path */
    while ( --top >= 0 && !done ) {
      /* Update balance factors */
      up[top]->balance += upd[top] != 0 ? -1 : +1;

      /* Terminate or rebalance as necessary */
      if ( abs ( up[top]->balance ) == 1 )
        break;
      else if ( abs ( up[top]->balance ) > 1 ) {
        remove_balance ( up[top], upd[top], done );

        /* Fix parent */
        if ( top != 0 )
          up[top - 1]->link[upd[top - 1]] = up[top];
        else
          tree->root = up[0];
      }
    }

    --tree->size;
  }

  return 1;
}

size_t itree_size ( itree_t *tree )
{
  return tree->size;
}

itreetrav_t *itreetnew ( void )
{
  return (itreetrav_t*)malloc ( sizeof ( itreetrav_t ) );
}

void itreetdelete ( itreetrav_t *trav )
{
  free ( trav );
}

/*
  First step in traversal,
  handles min and max
*/
static interval_t *start (itreetrav_t *trav, itree_t *tree, int dir )
{
  trav->tree = tree;
  trav->it = tree->root;
  trav->top = 0;

  /* Build a path to work with */
  if ( trav->it != NULL ) {
    while ( trav->it->link[dir] != NULL ) {
      trav->path[trav->top++] = trav->it;
      trav->it = trav->it->link[dir];
    }
  }

#ifdef DEBUG
  if(trav->it)
    printf("[%.1f, %.1f] (%d) (%.1f)\n", trav->it->interval->low, trav->it->interval->high, *(int*)trav->it->interval->data, trav->it->max);
#endif
  
  return trav->it == NULL ? NULL : trav->it->interval;
}

/*
  Subsequent traversal steps,
  handles ascending and descending
*/
static interval_t *move (itreetrav_t *trav, int dir )
{
  if ( trav->it->link[dir] != NULL ) {
    /* Continue down this branch */
    trav->path[trav->top++] = trav->it;
    trav->it = trav->it->link[dir];

    while ( trav->it->link[!dir] != NULL ) {
      trav->path[trav->top++] = trav->it;
      trav->it = trav->it->link[!dir];
    }
  }
  else {
    /* Move to the next branch */
    itreenode_t *last;

    do {
      if ( trav->top == 0 ) {
        trav->it = NULL;
        break;
      }

      last = trav->it;
      trav->it = trav->path[--trav->top];
    } while ( last == trav->it->link[dir] );
  }

#ifdef DEBUG
  if(trav->it)
    printf("[%.1f, %.1f] (%d) (%.1f)\n", trav->it->interval->low, trav->it->interval->high, *(int*)trav->it->interval->data, trav->it->max);
#endif
  
  return trav->it == NULL ? NULL : trav->it->interval;
}

interval_t *itreetfirst (itreetrav_t *trav, itree_t *tree )
{
  return start (trav, tree, 0 ); /* Min value */
}

interval_t *itreetlast (itreetrav_t *trav, itree_t *tree )
{
  return start (trav, tree, 1 ); /* Max value */
}

interval_t *itreetnext (itreetrav_t *trav )
{
  return move (trav, 1 ); /* Toward larger items */
}

interval_t *itreetprev (itreetrav_t *trav )
{
  return move (trav, 0 ); /* Toward smaller items */
}
