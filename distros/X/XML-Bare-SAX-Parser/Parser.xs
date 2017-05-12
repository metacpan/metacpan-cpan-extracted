// JEdit mode Line -> :folding=indent:mode=c++:indentSize=2:noTabs=true:tabSize=2:
#include "EXTERN.h"
#define PERL_IN_HV_C
#define PERL_HASH_INTERNAL_ACCESS
#include "perl.h"
#include "XSUB.h"
#include "parser_engine.h"

struct parserc parser;
struct nodec *root;

U32 nhash;
U32 dhash;
U32 vhash;

SV *ghandler;

struct nodec *curnode;

SV *startel;
SV *endel;
SV *chars;

HV *anode;
SV *anoderef;

HV *attnode;
SV *attnoderef;
HV *atthash;

HV *dnode;
SV *dnoderef;
  
void cxml2obj() {// pTHX_ int a ) {
  dSP;
  
  int i;
  int j;
  struct attc *curatt;
  int numatts = curnode->numatt;
    
  int length = curnode->numchildren;
  //printf("func %i\n", length);
  
  SV *attval;
  SV *attname;
  HV *oneatt;
  AV *attarr;
  SV *name;
  SV * atthashref;
  
  if( !length ) {
    if( curnode->vallen ) {
      SV * val = newSVpvn( curnode->value, curnode->vallen );
      
      dnode = newHV();
      dnoderef = newRV( (SV *) dnode );
      
      hv_store( dnode, "Data", 4, val, dhash );
      //SvREFCNT_dec( val );  
      
      PUSHMARK(SP);
      XPUSHs(ghandler);
      XPUSHs(dnoderef);
      PUTBACK;
      call_sv(chars, G_DISCARD);
    }
    return;
  }
  else {
    curnode = curnode->firstchild;
    for( i = 0; i < length; i++ ) {
      curnode->name[ curnode->namelen ] = 0x00;
      //printf("pre node: %s %i\n", curnode->name, i );
      name = newSVpvn( curnode->name, curnode->namelen );
      
      numatts = curnode->numatt;
      if( numatts ) {
        atthash = newHV();
        atthashref = newRV( (SV *) atthash );
        
        attnode = newHV();
        attnoderef = newRV( (SV *) attnode );
        
        hv_store( attnode, "Attributes", 10, atthashref, 0x00 );
        
        
        curatt = curnode->firstatt;
        attarr = newAV();
        hv_clear( atthash );
        for( j = 0; j < numatts; j++ ) {
          attval = newSVpvn( curatt->value, curatt->vallen );
          attname = newSVpvn( curatt->name, curatt->namelen );
          
          oneatt = newHV();
          hv_store( oneatt, "Name", 4, attname, nhash);
          hv_store( oneatt, "Value", 5, attval, vhash);
          
          // allow deletion when hash reference goes away
          //SvREFCNT_dec( attval );
          //SvREFCNT_dec( attname );
          
          hv_store( atthash, curatt->name, curatt->namelen, newRV_noinc( (SV *) oneatt ), 0 );
          //SvREFCNT_dec( (SV *) oneatt );
          
          if( j != ( numatts - 1 ) ) curatt = curatt->next;
        }
        hv_store( attnode, "Name", 4, name, nhash );
        
        PUSHMARK(SP);
        XPUSHs(ghandler);
        XPUSHs(attnoderef);
      }
      else {
        anode = newHV();
        anoderef = newRV( (SV *) anode );
        
        hv_store( anode, "Name", 4, name, nhash );
        PUSHMARK(SP);
        XPUSHs(ghandler);
        XPUSHs(anoderef);
      }
      PUTBACK;
      call_sv(startel, G_DISCARD);
      
      //printf("start node: %s\n", curnode->name );
      cxml2obj();// aTHX_ 0 );
      
      PUSHMARK(SP);
      XPUSHs(ghandler);
      XPUSHs(anoderef);
      PUTBACK;
      //printf("end node: %s\n", curnode->name );
      call_sv(endel, G_DISCARD);
      //printf("ended node: %s %i %i\n", curnode->name, length, i );
      
      SvREFCNT_dec( name );
      
      if( i != ( length - 1 ) ) curnode = curnode->next;
    }
    curnode = curnode->parent;
  }
  
  return;
}

void init_c( SV *ob) {
  //SV *svi = newSViv( 5 );
  HV * stash = SvSTASH( SvRV( ob ) );
  //char *name = HvNAME( stash );
  //if( !stash ) {
  //  printf("cannot retrieve stash");
  //  return;
  //}
  int len;
  startel = *hv_fetch( stash, "start_element", 13, 0 );
  endel   = *hv_fetch( stash, "end_element"  , 11, 0 );
  chars   = *hv_fetch( stash, "characters"   , 10, 0 );
  
  //len = strlen( name );
  //SV *ref = newRV( SvTYPE( ob ) );
  return;// newSVpvn( name, len );
  //return ref;
  
  //call_sv
  // ( see perlcall )
}

MODULE = XML::Bare::SAX::Parser   PACKAGE = XML::Bare::SAX::Parser

void
parse(handler,text)
  SV *handler
  char *text
  CODE:
    ghandler = handler;
    PERL_HASH(nhash, "Name", 4);
    PERL_HASH(dhash, "Data", 4);
    PERL_HASH(vhash, "Value", 5);
    
    init_c( handler );
    //RETVAL = ST(0);
    parserc_parse( &parser, text );
    root = parser.pcurnode; 
    curnode = parser.pcurnode;
    cxml2obj();//aTHX_ 0);
    //RETVAL = "done";
  //OUTPUT:
  //  RETVAL

void
free_tree()
  CODE:
    del_nodec( root );