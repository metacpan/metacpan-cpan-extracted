#include "parser_engine.h"
#ifdef DARWIN
  #include "stdlib.h"
#endif
#ifdef NOSTRING
  void memset(char *s, int c, int n) {
    char *se = s + n;
    while(s < se)	*s++ = c;
	}
#else
  #include <string.h>
#endif

struct nodec *new_nodecp( struct nodec *newparent ) {
  int size = sizeof( struct nodec );
  struct nodec *self = (struct nodec *) malloc( size );
  memset( (char *) self, 0, size );
  self->parent      = newparent;
  return self;
}

struct nodec *new_nodec() {
  int size = sizeof( struct nodec );
  struct nodec *self = (struct nodec *) malloc( size );
  memset( (char *) self, 0, size );
  return self;
}

void del_nodec( struct nodec *node ) {
  struct nodec *curnode;
  struct attc *curatt;
  struct nodec *next;
  struct attc *nexta;
  curnode = node->firstchild;
  while( curnode ) {
    next = curnode->next;
    del_nodec( curnode );
    if( !next ) break;
    curnode = next;
  }
  curatt = node->firstatt;
  while( curatt ) {
    nexta = curatt->next;
    free( curatt );
    curatt = nexta;
  }
  free( node );
}

struct attc* new_attc( struct nodec *newparent ) {
  int size = sizeof( struct attc );
  struct attc *self = (struct attc *) malloc( size );
  memset( (char *) self, 0, size );
  self->parent  = newparent;
  return self;
}

struct nodec* parserc_parse( struct parserc *self, char *xmlin ) {
    char  *tagname, *attname, *attval, *val;
    struct nodec *root    = new_nodec();
    int    tagname_len    = 0;
    int    attname_len    = 0;
    int    attval_len     = 0;
    struct nodec *curnode = root;
    struct attc  *curatt  = NULL;
    char   *cpos          = &xmlin[0];
    int    pos            = 0;
    register int let;
    
    val_1:
      let = *cpos;
      switch( let ) {
        case 0:   goto done;
        case '<': goto val_x;
      }
      if( !curnode->numvals ) {
        curnode->value = cpos;
        curnode->vallen = 1;
      }
      curnode->numvals++;
      cpos++;
      
    val_x:
      let = *cpos;
      switch( let ) {
        case 0:
          goto done;
        case '<':
          switch( *(cpos+1) ) {
            case '!':
              if( *(cpos+2) == '[' ) { // <![
                //if( !strncmp( cpos+3, "CDATA", 5 ) ) {
                if( *(cpos+3) == 'C' &&
                    *(cpos+4) == 'D' &&
                    *(cpos+5) == 'A' &&
                    *(cpos+6) == 'T' &&
                    *(cpos+7) == 'A'    ) {
                  cpos += 9;
                  goto cdata;
                }
                else {
                  cpos++; cpos++;
                  goto val_x;//actually goto error...
                }
              }
              else if( *(cpos+2) == '-' && // <!--
                *(cpos+3) == '-' ) {
                  cpos += 4;
                  goto comment;
                }
              else {
                cpos++;
                goto bang;
              }
            case '?':
              cpos+=2;
              goto pi;
          }
          tagname_len = 0; // for safety
          cpos++;
          goto name_1;
      }
      if( curnode->numvals == 1 ) curnode->vallen++;
      cpos++;
      goto val_x;
      
    outside:
      if( *cpos == '<' ) {
        tagname_len = 0; // for safety
        cpos++;
        goto name_1;
      }
      cpos++;
      goto outside;
      
    comment_1dash:
      cpos++;
      let = *cpos;
      if( let == '-' ) goto comment_2dash;
      goto comment_x;
      
    comment_2dash:
      cpos++;
      let = *cpos;
      if( let == '>' ) goto outside;
      goto comment_x;
      
    comment:
      let = *cpos;
      switch( let ) {
        case 0:   goto done;
        case '-': goto comment_1dash;
      }
      if( !curnode->numcoms ) {
        curnode->comment = cpos;
        curnode->comlen = 1;
      }
      curnode->numcoms++;
      cpos++;
    
    comment_x:
      let = *cpos;
      switch( let ) {
        case 0: goto done;
        case '-': goto comment_1dash;
      }
      if( curnode->numcoms == 1 ) curnode->comlen++;
      cpos++;
      goto comment_x;
      
    pi:
      let = *cpos;
      if( !let ) goto done;
      if( let == '?' && *(cpos+1) == '>' ) {
        cpos += 2;
        goto val_1;
      }
      cpos++;
      goto pi;

    bang:
      let = *cpos;
      if( !let ) goto done;
      if( let == '>' ) {
        cpos++;
        goto val_1;
      }
      cpos++;
      goto bang;
    
    cdata:
      let = *cpos;
      if( !let ) goto done;
      if( let == ']' && *(cpos+1) == ']' && *(cpos+2) == '>' ) {
        cpos += 3;
        goto val_1;
      }
      if( !curnode->numvals ) {
        curnode->value = cpos;
        curnode->vallen = 0;
        curnode->numvals = 1;
      }
      if( curnode->numvals == 1 ) curnode->vallen++;
      cpos++;
      goto cdata;
      
    name_1:
      let = *cpos;
      if( !let ) goto done;
      switch( let ) {
        case 0:
          goto done;
        case ' ':
        case 0x0d:
        case 0x0a:
          cpos++;
          goto name_1;
        case '/':
          tagname_len = 0; // needed to reset
          cpos++;
          goto ename_x;
      }
      tagname       = cpos;
      tagname_len   = 1;
      cpos++;
      goto name_x;
      
    name_x:
      let = *cpos;
      switch( let ) {
        case 0:
          goto done;
        case ' ':
        case 0x0d:
        case 0x0a:
          curnode     = nodec_addchildr( curnode, tagname, tagname_len );
          attname_len = 0;
          cpos++;
          goto name_gap;
        case '>':
          curnode     = nodec_addchildr( curnode, tagname, tagname_len );
          cpos++;
          goto val_1;
        case '/':
          nodec_addchildr( curnode, tagname, tagname_len );
          tagname_len            = 0;
          cpos+=2;
          goto val_1;
      }
      
      tagname_len++;
      cpos++;
      goto name_x;
          
    name_gap:
      let = *cpos;
      switch( *cpos ) {
        case 0:
          goto done;
        case ' ':
        case 0x0d:
        case 0x0a:
          cpos++;
          goto name_gap;
        case '>':
          cpos++;
          goto val_1;
        case '/':
          curnode = curnode->parent;
          if( !curnode ) goto done;
          cpos+=2; // am assuming next char is >
          goto val_1;
        case '=':
          cpos++;
          goto name_gap;//actually goto error
      }
        
      attname = cpos;
      attname_len = 1; // this really is needed... don't remove it
      cpos++;
      goto att_name;
      
    att_space:
      let = *cpos;
      switch( let ) {
        case 0: goto done;
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
      
      let = *cpos;
      switch( let ) {
        case 0: goto done;
        case '/':
          curnode = curnode->parent;
          if( !curnode ) goto done;
          cpos += 2;
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len            = 0;
          goto val_1;
        case ' ':
          if( *(cpos+1) == '=' ) {
            cpos++;
            goto att_name;
          }
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto att_space;
        case '>':
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto val_1;
        case '=':
          attval_len = 0;
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto att_eq1;
      }
      
      if( !attname_len ) attname = cpos;
      attname_len++;
      cpos++;
      goto att_name;
      
    att_eq1:
      let = *cpos;
      switch( let ) {
        case 0:
          goto done;
        case '/':
          if( *(cpos+1) == '>' ) {
            curnode = curnode->parent;
            if( !curnode ) goto done;
            cpos+=2;
            goto att_eq1;
          }
          break;
        case '"':
          cpos++;
          goto att_quot;
        case 0x27: // '
          cpos++;
          goto att_quots;
        case '>':
          cpos++;
          goto val_1;
        case ' ':
          cpos++;
          goto att_eq1;
      }  
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_eqx;
      
    att_eqx:
      let = *cpos;
      switch( let ) {
        case 0:
          goto done;
        case '/':
          if( *(cpos+1) == '>' ) {
            curnode = curnode->parent;
            if( !curnode ) goto done;
            curatt->value = attval;
            curatt->vallen = attval_len;
            attval_len    = 0;
            cpos += 2;
            goto val_1;
          }
          break;
        case '>':
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len    = 0;
          cpos++;
          goto val_1;
        case ' ':
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len    = 0;
          cpos++;
          goto name_gap;
      }
      
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_eqx;
      
    att_quot:
      let = *cpos;
      if( !let ) goto done;
      if( let == '"' ) {
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto name_gap;
      }
      else {
        if( !attval_len ) attval = cpos;
        attval_len++;
        cpos++;
        goto att_quot;
      }
      
    att_quots:
      let = *cpos;
      if( !let ) goto done;
      if( let == 0x27 ) {
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto name_gap;
      }
      else {
        if( !attval_len ) attval = cpos;
        attval_len++;
        cpos++;
        goto att_quots;
      }
          
    ename_x:
      let = *cpos;
      if( !let ) goto done;
      if( let == '>' ) {
        curnode->namelen = tagname_len;
        curnode = curnode->parent;
        if( !curnode ) goto done;
        tagname_len++;
        cpos++;
        goto val_1;
      }
      tagname_len++;
      cpos++;
      goto ename_x;
            
    done:
    self->pcurnode = root;
    self->pcurnode->curchild = self->pcurnode->firstchild;
    return root;
}

struct nodec *nodec_addchildr(  struct nodec *self, char *newname, int newnamelen ) {//, char *newval, int newvallen, int newtype ) {
  struct nodec *newnode = new_nodecp( self );
  newnode->name    = newname;
  newnode->namelen = newnamelen;
  //newnode->value   = newval;
  //newnode->vallen  = newvallen;
  //newnode->type    = newtype;
  if( self->numchildren == 0 ) {
    self->firstchild = newnode;
    self->lastchild  = newnode;
    self->numchildren++;
    return newnode;
  }
  else {
    self->lastchild->next = newnode;
    self->lastchild = newnode;
    self->numchildren++;
    return newnode;
  }
}

struct attc *nodec_addattr( struct nodec *self, char *newname, int newnamelen ) {//, char *newval, int newvallen ) {
  struct attc *newatt = new_attc( self );
  newatt->name    = newname;
  newatt->namelen = newnamelen;
  //newatt->value   = newval;
  //newatt->vallen  = newvallen;
  
  if( !self->numatt ) {
    self->firstatt = newatt;
    self->lastatt  = newatt;
    self->numatt++;
    return newatt;
  }
  else {
    self->lastatt->next = newatt;
    self->lastatt = newatt;
    self->numatt++;
    return newatt;
  }
}
