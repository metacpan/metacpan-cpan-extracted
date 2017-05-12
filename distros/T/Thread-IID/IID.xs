#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifdef PERL_IMPLICIT_CONTEXT
/*
 *   LOG2(a) == floor(log_2(a))
 */
#  define LOG2(a) M(((S16(S8(S4(S2(S1(a))))))>>1)+1)
#    define S1(a)  (a)|((a)>>1)
#    define S2(a)  (a)|((a)>>2)
#    define S4(a)  (a)|((a)>>4)
#    define S8(a)  (a)|((a)>>8)
#    define S16(a) (a)|((a)>>16)
#    define M(a) \
     (((a)&0xffff0000 ? 16 : 0) +\
      ((a)&0xff00ff00 ?  8 : 0) +\
      ((a)&0xf0f0f0f0 ?  4 : 0) +\
      ((a)&0xcccccccc ?  2 : 0) +\
      ((a)&0xaaaaaaaa ?  1 : 0))

#  define rvalue() ((UV)aTHX)>>LOG2(sizeof *(aTHX))

#else // !PERL_IMPLICIT_CONTEXT
#  define rvalue() 0
#endif

MODULE = Thread::IID		PACKAGE = Thread::IID		

UV
interpreter_id()
   PROTOTYPE: 
   CODE:
      RETVAL = rvalue();

   OUTPUT:
      RETVAL
