// JEdit mode Line -> :folding=indent:mode=c++:indentSize=2:noTabs=true:tabSize=2:
#include "EXTERN.h"
#define PERL_IN_HV_C
#define PERL_HASH_INTERNAL_ACCESS

#include "perl.h"
#include "XSUB.h"
#include "parser.h"

struct nodec *root;

U32 Vhash;
U32 vhash;
U32 chash;
U32 phash;
U32 ihash;
U32 cdhash;
U32 typehash;
U32 zhash;
U32 nhash;
U32 ahash;

struct nodec *curnode;
char *rootpos;
  
SV *cxml2obj() {
  HV *output = newHV();
  int i;
  struct attc *curatt;
  int numatts = curnode->numatt;
  SV *attval;
  SV *attatt;
  HV *package = gv_stashpv("XML::ED::Node", GV_ADD);
  SV *outputref = (SV *)sv_bless(newRV_noinc((SV*)output), package);

  int length = curnode->numchildren;
  
  hv_store( output, "_pos", 4, newSViv( curnode->pos ), phash );
  hv_store( output, "_i", 2,   newSViv( curnode->name - rootpos ), ihash );
  hv_store( output, "_z", 2,   newSViv( curnode->z ), zhash );
  hv_store( output, "_n", 2,   newSViv( length ), nhash );
  hv_store( output, "_name", 5, newSVpvn( curnode->name, curnode->namelen ), 0 );

  hv_store( output, "_type", 5, newSViv( curnode->type ), typehash);

  if( curnode->vallen ) {
    SV * sv = newSVpvn( curnode->value, curnode->vallen );
    SvUTF8_on(sv);
    hv_store( output, "_value", 6, sv, Vhash );
  }
  if ( length ) {
    curnode = curnode->firstchild;
    AV *newarray = newAV();
    HV *package = gv_stashpv("XML::ED::NodeSet", GV_ADD);
    SV *newarrayref = (SV *)sv_bless(newRV_noinc((SV*)newarray), package);
    hv_store( output, "_data", 5, newarrayref, 0);

    for ( i = 0; i < length; i++ ) {
      SV **cur = hv_fetch( output, curnode->name, curnode->namelen, 0 );
      SV *ob = cxml2obj();
      av_push( newarray, ob );

      if ( i != ( length - 1 ) ) curnode = curnode->next;
    }
    
    curnode = curnode->parent;
  }
  
  if ( numatts ) {
    curatt = curnode->firstatt;
    for ( i = 0; i < numatts; i++ ) {
      HV *atth = newHV();
      SV *atthref = newRV_noinc( (SV *) atth );
      hv_store( output, curatt->name, curatt->namelen, atthref, 0 );
      
      attval = newSVpvn( curatt->value, curatt->vallen );
      SvUTF8_on(attval);
      hv_store( atth, "value", 5, attval, vhash );
      attatt = newSViv( 1 );
      hv_store( atth, "_att", 4, attatt, ahash );
      if( i != ( numatts - 1 ) ) curatt = curatt->next;
    }
  }

  return outputref;
}

struct parserc *parser = 0;

MODULE = XML::ED::Bare         PACKAGE = XML::ED::Bare

SV *
xml2obj()
  CODE:
    curnode = parser->pcurnode;
    if ( curnode->err ) RETVAL = newSViv( curnode->err );
    else RETVAL = cxml2obj();
  OUTPUT:
    RETVAL
    
void
c_parse(text)
  char * text
  CODE:
    rootpos = text;
    PERL_HASH(vhash, "value", 5);
    PERL_HASH(Vhash, "_value", 6);
    PERL_HASH(ahash, "_att", 4);
    PERL_HASH(chash, "comment", 7);
    PERL_HASH(phash, "_pos", 4);
    PERL_HASH(ihash, "_i", 2 );
    PERL_HASH(zhash, "_z", 2 );
    PERL_HASH(nhash, "_n", 2 );
    PERL_HASH(cdhash, "_cdata", 6 );
    PERL_HASH(typehash, "_type", 5 );
    parser = (struct parserc *) malloc( sizeof( struct parserc ) );
    root = parserc_parse( parser, text );

SV *
get_root()
  CODE:
    RETVAL = newSVuv( PTR2UV( root ) );
  OUTPUT:
    RETVAL

void
free_tree_c( rootsv )
  SV *rootsv
  CODE:
    struct nodec *rootnode;
    rootnode = INT2PTR( struct nodec *, SvUV( rootsv ) );
    del_nodec( rootnode );

