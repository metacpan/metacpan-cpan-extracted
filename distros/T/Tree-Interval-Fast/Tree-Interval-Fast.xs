#ifdef __cplusplus
extern "C" {
#endif

/* 
   From http://blogs.perl.org/users/nick_wellnhofer/2015/03/writing-xs-like-a-pro---perl-no-get-context-and-static-functions.html
   The perlxs man page recommends to define the PERL_NO_GET_CONTEXT macro before including EXTERN.h, perl.h, and XSUB.h. 
   If this macro is defined, it is assumed that the interpreter context is passed as a parameter to every function. 
   If it's undefined, the context will typically be fetched from thread-local storage when calling the Perl API, which 
   incurs a performance overhead.
   
   WARNING:
   
    setting this macro involves additional changes to the XS code. For example, if the XS file has static functions that 
    call into the Perl API, you'll get somewhat cryptic error messages like the following:

    /usr/lib/i386-linux-gnu/perl/5.20/CORE/perl.h:155:16: error: ‘my_perl’ undeclared (first use in this function)
    #  define aTHX my_perl

   See http://perldoc.perl.org/perlguts.html#How-do-I-use-all-this-in-extensions? for ways in which to avoid these
   errors when using the macro.

   One way is to begin each static function that invoke the perl API with the dTHX macro to fetch context. This is
   used in the following static functions.
   Another more efficient approach is to prepend pTHX_ to the argument list in the declaration of each static
   function and aTHX_ when each of these functions are invoked. This is used directly in the AVL tree library
   source code.
*/
#define PERL_NO_GET_CONTEXT
  
#ifdef ENABLE_DEBUG
#define TRACEME(x) do {						\
    if (SvTRUE(perl_get_sv("Tree::Interval::Fast::ENABLE_DEBUG", TRUE)))	\
      { PerlIO_stdoutf (x); PerlIO_stdoutf ("\n"); }		\
  } while (0)
#else
#define TRACEME(x)
#endif
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
  
#include "ppport.h"
  
#include "interval.h"
#include "interval_list.h"
#include "interval_tree.h"

#ifdef __cplusplus
}
#endif

typedef interval_t* Tree__Interval__Fast__Interval;
typedef itree_t* Tree__Interval__Fast;

/* C-level callbacks required by the interval tree library */

static SV* svclone(SV* p) {
  dTHX;       /* fetch context */

  return SvREFCNT_inc(p);
}

void svdestroy(SV* p) {
  dTHX;       /* fetch context */

  SvREFCNT_dec(p);
}

/*====================================================================
 * XS SECTION                                                     
 *====================================================================*/

MODULE = Tree::Interval::Fast 	PACKAGE = Tree::Interval::Fast::Interval

Tree::Interval::Fast::Interval
new(packname, low, high, data)
    char* packname
    float low
    float high
    SV*   data
  PROTOTYPE: $$$
  CODE:
    RETVAL = interval_new(low, high, data, svclone, svdestroy);
  OUTPUT:
    RETVAL

Tree::Interval::Fast::Interval
copy(interval)
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $
  CODE:
    RETVAL = interval_copy(interval);
  OUTPUT:
    RETVAL

int
overlap(i1, i2)
    Tree::Interval::Fast::Interval i1
    Tree::Interval::Fast::Interval i2
  PROTOTYPE: $$ 
  CODE:
    RETVAL = interval_overlap(i1, i2);
  OUTPUT:
    RETVAL

int
equal(i1, i2)
    Tree::Interval::Fast::Interval i1
    Tree::Interval::Fast::Interval i2
  PROTOTYPE: $$ 
  CODE:
    RETVAL = interval_equal(i1, i2);
  OUTPUT:
    RETVAL

float
low(interval)
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $
  CODE:
    RETVAL = interval->low;
  OUTPUT:
    RETVAL

float
high(interval)
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $
  CODE:
    RETVAL = interval->high;
  OUTPUT:
    RETVAL

SV*
data(interval)
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $
  CODE:
    RETVAL = newSVsv(interval->data);
  OUTPUT:
    RETVAL

void
DESTROY(interval)
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $
  CODE:
    interval_delete(interval);
  
MODULE = Tree::Interval::Fast 	PACKAGE = Tree::Interval::Fast

Tree::Interval::Fast
new( class )
    char* class
  PROTOTYPE: $
  CODE:

    TRACEME("Allocating interval tree");
    RETVAL = itree_new(svclone, svdestroy);

    if(RETVAL == NULL) {
      warn("Unable to allocate interval tree");
      XSRETURN_UNDEF;
    }

  OUTPUT:
    RETVAL

Tree::Interval::Fast::Interval
find( tree, low, high )
    Tree::Interval::Fast tree
    int low
    int high
  PROTOTYPE: $$$
  PREINIT:
    interval_t *i, *result;
    
  CODE:
    i = interval_new( low, high, &PL_sv_undef, svclone, svdestroy);

    result = itree_find( tree, i );
    interval_delete(i);

    if(result == NULL)
      XSRETURN_UNDEF;

    /*
     * Return a copy of the result as this belongs to the tree
     *
     * WARNING
     *
     * Invoking interval_copy on the result generates segfault.
     * Couldn't figure out why so far.
     *
     */
    RETVAL = interval_new( result->low, result->high, result->data, svclone, svdestroy);

  OUTPUT:
    RETVAL

SV*
findall( tree, low, high )
    Tree::Interval::Fast tree
    int low
    int high
  PROTOTYPE: $$$
  PREINIT:
    AV* av_ref;
    interval_t *i;
    const interval_t *item;
    ilist_t* results;
    ilisttrav_t* trav;
    
  CODE:
    i = interval_new ( low, high, &PL_sv_undef, svclone, svdestroy );

    results = itree_findall ( tree, i );
    interval_delete ( i );

    /* empty results set, return undef */
    if ( results == NULL || !ilist_size ( results ) ) {
      ilist_delete ( results );
      XSRETURN_UNDEF;
    }

    /* return a reference to an array of intervals */
    av_ref = (AV*) sv_2mortal( (SV*) newAV() );

    trav = ilisttrav_new( results );
    if ( trav == NULL ) {
      ilist_delete ( results );
      croak("Cannot traverse results set");
    }

    for(item = ilisttrav_first(trav); item!=NULL; item=ilisttrav_next(trav)) {
      SV* ref = newSV(0);
      sv_setref_pv( ref, "Tree::Interval::Fast::Interval", (void*)interval_new(item->low, item->high, item->data, svclone, svdestroy) );
      av_push(av_ref, ref);
    }

    RETVAL = newRV( (SV*) av_ref );
    ilist_delete ( results );

  OUTPUT:
    RETVAL


int
insert( tree, interval )
    Tree::Interval::Fast tree
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $$
  CODE:
    RETVAL = itree_insert( tree, interval );

  OUTPUT:
    RETVAL

int
remove( tree, interval )
    Tree::Interval::Fast tree
    Tree::Interval::Fast::Interval interval
  PROTOTYPE: $$
  CODE:
    RETVAL = itree_remove( tree, interval );

  OUTPUT:
    RETVAL
	 
int
size( tree )
    Tree::Interval::Fast tree
  PROTOTYPE: $
  CODE:
    RETVAL = itree_size( tree );

  OUTPUT:
    RETVAL

void
DESTROY( tree )
    Tree::Interval::Fast tree
  PROTOTYPE: $
  CODE:
      TRACEME("Deleting interval tree");
      itree_delete( tree );
