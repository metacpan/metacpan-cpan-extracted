/* ternary.c

This code is heavily based on code described in "Ternary Search Trees"
by Jon Bentley and Robert Sedgewick in the April, 1998, Dr. Dobb's
Journal.

It has been adapted to fit into an OO-like frameword by Leon Brocard (2000)
leon@astray.com
*/

#include "ternary.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>



Tobj t_new(void) {
  Tobj *pTernary = (Tobj *) malloc(sizeof (Tobj));

  pTernary->root = 0;
  pTernary->terminals = 0;
  pTernary->nodes = 0;
  pTernary->searchchar = 0;
  pTernary->searchn = 0;
  pTernary->searchcharn = 0;

  return *pTernary;
}

void t_DESTROY(Tobj *pTernary) {
  _cleanup(pTernary->root);

  if (pTernary->searchcharn > 0)
    free(pTernary->searchchar);
}

void t_insert(Tobj *pTernary, char *s) {
  char* t = strdup(s);
  pTernary->root = _insert(pTernary, pTernary->root, t, t);
}

void t_pmsearch(Tobj *pTernary, char *w, char *s) {
  _malloc(pTernary);
  pTernary->searchn = 0;
  _pmsearch(pTernary, pTernary->root, w, s);
  /* now look at pTernary->searchn and pTernary->searchchar */
}

void t_nearsearch(Tobj *pTernary, char *s, int i) {
  _malloc(pTernary);
  pTernary->searchn = 0;
  _nearsearch(pTernary, pTernary->root, s, i);
  /* now look at pTernary->searchn and pTernary->searchchar */
}

int t_search(Tobj *pTernary, char *s) {
  return _search(pTernary->root, s);
}

void t_traverse(Tobj *pTernary) {
  _malloc(pTernary);
  pTernary->searchn = 0;
  _traverse(pTernary, pTernary->root);
  /* now look at pTernary->searchn and pTernary->searchchar */
}

int t_nodes(Tobj *pTernary) {
  return pTernary->nodes - pTernary->terminals;
}

int t_terminals(Tobj *pTernary) {
  return pTernary->terminals;
}

_malloc(Tobj *pTernary) {
  if (pTernary->searchcharn != pTernary->terminals) {
    if (pTernary->searchcharn > 0) {
      free(pTernary->searchchar);
    }
    pTernary->searchchar = (char **) malloc(sizeof(char*) * (pTernary->terminals + 1));
    pTernary->searchcharn = pTernary->terminals;
  }
}




Tptr _insert(Tobj *pTernary, Tptr p, char *s, char *insertstr) {
  if (p == 0) {
    p = (Tptr) malloc(sizeof(Tnode));
    p->splitchar = *s;
    p->lokid = p->eqkid = p->hikid = 0;
    pTernary->nodes++;
  }
  if (*s < p->splitchar)
    p->lokid = _insert(pTernary, p->lokid, s, insertstr);
  else if (*s == p->splitchar) {
    if (*s == 0) {
      if (p->eqkid) {
	free(p->eqkid);
	p->eqkid = (Tptr) insertstr;
      } else {
	p->eqkid = (Tptr) insertstr;
	pTernary->terminals++;
      }
    }
    else
      p->eqkid = _insert(pTernary, p->eqkid, ++s, insertstr);
  } else
    p->hikid = _insert(pTernary, p->hikid, s, insertstr);
  return p;
}


void _cleanup(Tptr p) {
  if (p) {
    _cleanup(p->lokid);
    if (p->splitchar) {
      _cleanup(p->eqkid);
    } else {
      free(p->eqkid); /* It's just a string, free the memory */
    }
    _cleanup(p->hikid);
    free(p);  
  }
}


int _search(Tptr root, char *s) {
  Tptr p;
  p = root;
  while (p) {
    if (*s < p->splitchar)
      p = p->lokid;
    else if (*s == p->splitchar)  {
      if (*s++ == 0) 
	return 1;
      p = p->eqkid;
    } else
      p = p->hikid;
  }
  return 0;
}



void _pmsearch(Tobj *pTernary, Tptr p, char *w, char *s) {

  char** foo;

  if (!p) return;

  if (*s == *w || *s < p->splitchar)
    _pmsearch(pTernary, p->lokid, w, s);
  if (*s == *w || *s == p->splitchar)
    if (p->splitchar && *s)
      _pmsearch(pTernary, p->eqkid, w, s+1);
  if (*s == 0 && p->splitchar == 0) {
    foo = pTernary->searchchar;
    foo[pTernary->searchn] = (char *) p->eqkid;
    pTernary->searchn++;
  }
  if (*s == *w || *s > p->splitchar)
    _pmsearch(pTernary, p->hikid, w, s);
}


void _nearsearch(Tobj *pTernary, Tptr p, char *s, int d) {

  char** foo;

  if (!p || d < 0) return;
  if (d > 0 || *s < p->splitchar)
    _nearsearch(pTernary, p->lokid, s, d);
  if (p->splitchar == 0) {
    if ((int) strlen(s) <= d) {
      foo = pTernary->searchchar;
      foo[pTernary->searchn] = (char *) p->eqkid;
      pTernary->searchn++;
    }
  } else
    _nearsearch(pTernary, p->eqkid, *s ? s+1:s,
	       (*s == p->splitchar) ? d:d-1);
  if (d > 0 || *s > p->splitchar)
    _nearsearch(pTernary, p->hikid, s, d);
}

void _traverse(Tobj *pTernary, Tptr p) {
  
  char** foo;

  if (!p) return;
  _traverse(pTernary, p->lokid);
  if (p->splitchar)
    _traverse(pTernary, p->eqkid);
  else {
    foo = pTernary->searchchar;
    foo[pTernary->searchn] = (char *) p->eqkid;
    pTernary->searchn++;
  }
  _traverse(pTernary, p->hikid);
}






