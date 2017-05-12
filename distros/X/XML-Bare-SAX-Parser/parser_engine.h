#ifdef WIN32
#include<stdlib.h>
#endif

#ifndef NULL
  #define NULL 0x00
#endif

struct nodec {
  struct nodec *curchild;
  struct nodec *parent;
  struct nodec *next;
  struct nodec *firstchild;
  struct nodec *lastchild;
  struct attc  *firstatt;
  struct attc  *lastatt;
  int   numchildren;
  int   numatt;
  char  *name;
  int   namelen;
  char  *value;
  char  *comment;
  int   vallen;
  int   comlen;
  int   type;// cdata or normal
  int   numvals;
  int   numcoms;
};

struct nodec *nodec_addchildr( struct nodec *self, char *newname, int newnamelen );//, char *newval, int newvallen, int newtype );
//struct nodec *nodec_addchild( struct nodec *self, char *newname, int newnamelen );
struct attc *nodec_addattr  ( struct nodec *self, char *newname, int newnamelen );//, char *newval, int newvallen );
//struct attc *nodec_addatt  ( struct nodec *self, char *newname, int newnamelen );

struct nodec *new_nodecp( struct nodec *newparent );
struct nodec *new_nodec();
void del_nodec( struct nodec *node );

struct attc {
  struct nodec *parent;
  struct attc  *next;
  char  *name;
  int   namelen;
  char  *value;
  int   vallen;
};

struct attc* new_attc( struct nodec *newparent );

struct parserc {
  struct nodec *pcurnode;
  struct attc  *curatt;
};

struct nodec* parserc_parse( struct parserc *self, char *newbuf );
