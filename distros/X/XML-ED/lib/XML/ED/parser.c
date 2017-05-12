
#include "parser.h"
#include<stdio.h>
#include "stdlib.h"
#ifdef NOSTRING
void memset(char *s, int c, int n)
{
    char *se = s + n;
    while (s < se)
	*s++ = c;
}
#else
#include <string.h>
#endif

int dh_memcmp(char *a, char *b, int n)
{
    int c = 0;
    while (c < n) {
	if (*a != *b)
	    return c + 1;
	a++;
	b++;
	c++;
    }
    return 0;
}

struct nodec *new_nodecp(struct nodec *newparent)
{
    static int pos = 0;
    int size = sizeof(struct nodec);
    struct nodec *self = (struct nodec *) malloc(size);
    memset((char *) self, 0, size);
    self->parent = newparent;
    self->pos = ++pos;
    return self;
}

struct nodec *new_nodec()
{
    struct nodec *node = (struct nodec *)calloc(sizeof(struct nodec), 1);

    return node;
}

void del_nodec(struct nodec *node)
{
    struct nodec *curnode;
    struct attc *curatt;
    struct nodec *next;
    struct attc *nexta;
    curnode = node->firstchild;
    while (curnode) {
	next = curnode->next;
	del_nodec(curnode);
	if (!next)
	    break;
	curnode = next;
    }
    curatt = node->firstatt;
    while (curatt) {
	nexta = curatt->next;
	free(curatt);
	curatt = nexta;
    }
    free(node);
}

struct attc *new_attc(struct nodec *newparent)
{
    int size = sizeof(struct attc);
    struct attc *self = (struct attc *) malloc(size);
    memset((char *) self, 0, size);
    self->parent = newparent;
    return self;
}

//#define DEBUG

struct nodec *parserc_parse(struct parserc *self, char *xmlin)
{
    char *tagname, *attname, *attval, *val;
    struct nodec *root = new_nodec();
    int tagname_len = 0;
    int tagname_type = 0;
    int attname_len = 0;
    int attval_len = 0;
    struct nodec *curnode = root;
    struct nodec *temp;
    struct attc *curatt = NULL;
    char *cpos = &xmlin[0];
    int pos = 0;
    int res = 0;
    int dent;
    register int let;

#ifdef DEBUG
    printf("Entry to C Parser\n");
#endif

  val_1:
#ifdef DEBUG
    printf("val_1: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case '\0':
	goto done;
    case '<':
	goto val_x;
    }

    {
	static int x = 0;
	char buffer[1023];
	int len;
	curnode = nodec_addchildr(curnode, "contents", 8, 5);
	curnode->value = cpos;
	curnode->vallen = 1;
	cpos++;
    }

  val_x:
#ifdef DEBUG
    printf("val_x: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case '\0':
	if (curnode->type == 5) {
	    curnode->vallen = cpos - curnode->value;
	    curnode->z = cpos - xmlin;
	    curnode = curnode->parent;	// jump up
	}
	goto done;
    case '<':
	if (curnode->type == 5) {
	    curnode->vallen = cpos - curnode->value;
	    curnode->z = cpos - xmlin;
	    curnode = curnode->parent;	// jump up
	}
	tagname_type = 1;
	switch (*(cpos + 1)) {
	case '!':
	    curnode = nodec_addchildr(curnode, "comment", 7, 8);
	    curnode->value = cpos;
	    if (*(cpos + 2) == '-' &&	// <!--
		*(cpos + 3) == '-') {
		cpos += 4;
		curnode->type |= 4;
		curnode->value = cpos;
		goto comment;
	    } else {
		cpos++;
		curnode->type |= 2;
		curnode->value = cpos;
		goto bang;
	    }
	case '?':
	    tagname_type = 2;
	    cpos++;
	    cpos++;
	    goto name_1;
	}
	tagname_len = 0;	// for safety
	cpos++;
	goto name_1;
    }
    cpos++;
    goto val_x;

  comment_1dash:
    cpos++;
    let = *cpos;
    if (let == '-')
	goto comment_2dash;
    goto comment_x;

  comment_2dash:
    cpos++;
    let = *cpos;
    if (let == '>') {
        curnode->vallen = cpos - curnode->value - 2;
	cpos++;
	curnode = curnode->parent;
	goto val_1;
    }
    goto comment_x;

  comment:
    let = *cpos;
    switch (let) {
    case '\0':
	goto done;
    case '-':
	goto comment_1dash;
    }
    cpos++;

  comment_x:
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case '-':
	goto comment_1dash;
    }
    cpos++;
    goto comment_x;

  pi:
    let = *cpos;
    if (!let)
	goto done;
    if (let == '?' && *(cpos + 1) == '>') {
	cpos += 2;
	goto val_1;
    }
    cpos++;
    goto pi;

  bang:
    let = *cpos;
    if (!let)
	goto done;
    if (let == '>') {
	curnode->vallen = cpos - curnode->value;
	cpos++;
	curnode = curnode->parent;

	goto val_1;
    }
    cpos++;
    goto bang;

  cdata:
    let = *cpos;
    if (!let)
	goto done;
    if (let == ']' && *(cpos + 1) == ']' && *(cpos + 2) == '>') {
	cpos += 3;
	goto val_1;
    }
    cpos++;
    goto cdata;

// looking for name after <

  name_1:
#ifdef DEBUG
    printf("name_1: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case '\0':
	goto done;
    case ' ':
    case '\r':
    case '\n':
	cpos++;
	goto name_1;
    case '/':			// regular closing tag
	tagname_len = 0;	// needed to reset
	cpos++;
	goto ename_1;
    }
    tagname = cpos;
    tagname_len = 1;
    cpos++;
    goto name_x;

// have a name 

  name_x:
#ifdef DEBUG
    printf("name_x: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case '\0':
	goto done;
    case '/':			// self closing
    case '?':			// self closing

    case ' ':
    case '\n':
    case '\r':
    case '>':
	curnode =
	    nodec_addchildr(curnode, tagname, tagname_len, tagname_type);
	attname_len = 0;
	goto name_gap;
    }

    tagname_len++;
    cpos++;
    goto name_x;

// look for attributes

  name_gap:
    let = *cpos;
    switch (*cpos) {
    case '\0':
	goto done;
    case ' ':
    case '\n':
    case '\r':
	cpos++;
	goto name_gap;
    case '>':
	cpos++;
	goto val_1;
    case '?':			// self closing
    case '/':			// self closing
	curnode->z = cpos + 1 - xmlin;
	curnode = curnode->parent;
	if (!curnode)
	    goto done;
	cpos += 2;		// am assuming next char is >
	goto val_1;
    }

  att_name1:
#ifdef DEBUG
    printf("attname1: %c\n", *cpos);
#endif
    let = *cpos;
    switch (*cpos) {
    case 0:
	goto done;
    case 0x27:
	cpos++;
	attname = cpos;
	attname_len = 0;
	goto att_nameqs;
    }
    attname = cpos;
    attname_len = 1;
    cpos++;
    goto att_name;

  att_space:
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case ' ':
    case 0x0d:
    case 0x0a:
	cpos++;
	goto att_space;
    case '=':
	cpos++;
	goto att_eq1;
    }
    // we have another attribute name, so continue

  att_name:
#ifdef DEBUG
    printf("attname: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case '/':			// self closing     !! /> is assumed !!
	curatt = nodec_addattr(curnode, attname, attname_len);
	attname_len = 0;

	curnode->z = cpos + 1 - xmlin;
	curnode = curnode->parent;
	if (!curnode)
	    goto done;
	cpos += 2;
	goto val_1;
    case ' ':
	if (*(cpos + 1) == '=') {
	    cpos++;
	    goto att_name;
	}
	curatt = nodec_addattr(curnode, attname, attname_len);
	attname_len = 0;
	cpos++;
	goto att_space;
    case '>':
	curatt = nodec_addattr(curnode, attname, attname_len);
	attname_len = 0;
	cpos++;
	goto val_1;
    case '=':
	attval_len = 0;
	curatt = nodec_addattr(curnode, attname, attname_len);
	attname_len = 0;
	cpos++;
	goto att_eq1;
    }

    if (!attname_len)
	attname = cpos;
    attname_len++;
    cpos++;
    goto att_name;

  att_nameqs:
#ifdef DEBUG
    printf("nameqs: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case 0x27: // APOSTROPHE
	cpos++;
	goto att_nameqsdone;
    }
    attname_len++;
    cpos++;
    goto att_nameqs;

  att_nameqsdone:
#ifdef DEBUG
    printf("nameqsdone: %c\n", *cpos);
#endif
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case '=':
	attval_len = 0;
	curatt = nodec_addattr(curnode, attname, attname_len);
	attname_len = 0;
	cpos++;
	goto att_eq1;
    }
    goto att_nameqsdone;

  att_eq1:
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case '/':			// self closing
	if (*(cpos + 1) == '>') {
	    curnode->z = cpos + 1 - xmlin;
	    curnode = curnode->parent;
	    if (!curnode)
		goto done;
	    cpos += 2;
	    goto att_eq1;
	}
	break;
    case '"':
	cpos++;
	goto att_quot;
    case 0x27:			// '
	cpos++;
	goto att_quots;
    case '`':
	cpos++;
	goto att_tick;
    case '>':
	cpos++;
	goto val_1;
    case ' ':
	cpos++;
	goto att_eq1;
    }
    if (!attval_len)
	attval = cpos;
    attval_len++;
    cpos++;
    goto att_eqx;

  att_eqx:
    let = *cpos;
    switch (let) {
    case 0:
	goto done;
    case '?':			// self closing
    case '/':			// self closing
	if (*(cpos + 1) == '>') {
	    curnode->z = cpos + 1 - xmlin;
	    curnode = curnode->parent;
	    if (!curnode)
		goto done;
	    curatt->value = attval;
	    curatt->vallen = attval_len;
	    attval_len = 0;
	    cpos += 2;
	    goto val_1;
	}
	break;
    case '>':
	curatt->value = attval;
	curatt->vallen = attval_len;
	attval_len = 0;
	cpos++;
	goto val_1;
    case ' ':
	curatt->value = attval;
	curatt->vallen = attval_len;
	attval_len = 0;
	cpos++;
	goto name_gap;
    }

    if (!attval_len)
	attval = cpos;
    attval_len++;
    cpos++;
    goto att_eqx;

  att_quot:
    let = *cpos;
    if (!let)
	goto done;
    if (let == '"') {
	if (attval_len) {
	    curatt->value = attval;
	    curatt->vallen = attval_len;
	    attval_len = 0;
	}
	cpos++;
	goto name_gap;
    } else {
	if (!attval_len)
	    attval = cpos;
	attval_len++;
	cpos++;
	goto att_quot;
    }

  att_quots:
    let = *cpos;
    if (!let)
	goto done;
    if (let == 0x27) {
	if (attval_len) {
	    curatt->value = attval;
	    curatt->vallen = attval_len;
	    attval_len = 0;
	}
	cpos++;
	goto name_gap;
    } else {
	if (!attval_len)
	    attval = cpos;
	attval_len++;
	cpos++;
	goto att_quots;
    }

  att_tick:
    let = *cpos;
    if (!let)
	goto done;
    if (let == '`') {
	if (attval_len) {
	    curatt->value = attval;
	    curatt->vallen = attval_len;
	    attval_len = 0;
	}
	cpos++;
	goto name_gap;
    }
    if (!attval_len)
	attval = cpos;
    attval_len++;
    cpos++;
    goto att_tick;

  ename_1:
    let = *cpos;
    if (!let)
	goto done;

    if (let == '>') {
	curnode->namelen = tagname_len;
	curnode->z = cpos - xmlin;
	curnode = curnode->parent;	// jump up
	if (!curnode)
	    goto done;
	tagname_len++;
	cpos++;
	root->err = -1;
	goto error;
    }
    tagname = cpos;
    tagname_len = 1;
    cpos++;
    // continue

  ename_x:			// ending name
    let = *cpos;
    if (!let)
	goto done;
    if (let == '>') {
	if (curnode->namelen != tagname_len) {
	    goto error;
	}
	if (res = dh_memcmp(curnode->name, tagname, tagname_len)) {
	    cpos -= tagname_len;
	    cpos += res - 1;
	    goto error;
	}
	curnode->z = cpos - xmlin;
	curnode = curnode->parent;	// jump up
	if (!curnode)
	    goto done;
	tagname_len++;
	cpos++;

	goto val_1;
    }
    tagname_len++;
    cpos++;
    goto ename_x;
  error:
    root->err = -(int) (cpos - &xmlin[0]);
    self->pcurnode = root;
    //root->err = 1;
    return root;
  done:
#ifdef DEBUG
    printf("done\n", *cpos);
#endif
    self->pcurnode = root;
    self->pcurnode->curchild = self->pcurnode->firstchild;
#ifdef DEBUG
    printf("returning\n", *cpos);
#endif
    return root;
}

struct utfchar {
    char high;
    char low;
};

struct nodec *nodec_addchildr(struct nodec *self, char *newname,
			      int newnamelen, int newtype)
{
    struct nodec *newnode = new_nodecp(self);
    newnode->name = newname;
    newnode->namelen = newnamelen;
    //newnode->value   = newval;
    //newnode->vallen  = newvallen;
    newnode->type = newtype;
    if (self->numchildren == 0) {
	self->firstchild = newnode;
	self->lastchild = newnode;
	self->numchildren++;
	return newnode;
    } else {
	self->lastchild->next = newnode;
	self->lastchild = newnode;
	self->numchildren++;
	return newnode;
    }
}

struct attc *nodec_addattr(struct nodec *self, char *newname,
			   int newnamelen)
{
    struct attc *newatt = new_attc(self);
    newatt->name = newname;
    newatt->namelen = newnamelen;
    //newatt->value   = newval;
    //newatt->vallen  = newvallen;

    if (!self->numatt) {
	self->firstatt = newatt;
	self->lastatt = newatt;
	self->numatt++;
	return newatt;
    } else {
	self->lastatt->next = newatt;
	self->lastatt = newatt;
	self->numatt++;
	return newatt;
    }
}

/* eof */
