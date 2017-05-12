#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <rpc/rpc.h>

typedef struct netconfig Netconfig;

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB1

REQUIRE: 1.931

bool_t
rpcb_gettime(host,timep)
          char *host
          time_t &timep
          OUTPUT:
          timep

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB2

bool_t
rpcb_gettime(host,timep)
          char *host
          time_t &timep
          OUTPUT:
          timep sv_setnv(ST(1), (double)timep);

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB3

bool_t
rpcb_gettime(host,timep)
          char *host
          time_t timep
          CODE:
               RETVAL = rpcb_gettime( host, &timep );
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB4

bool_t
rpcb_gettime(host,timep)
          char *host
          time_t &timep = NO_INIT
          OUTPUT:
          timep

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB5

bool_t
rpcb_gettime(host,timep)
          char *host = (char *)SvPV(ST(0),na);
          time_t &timep = 0;
          OUTPUT:
          timep

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB6

bool_t
rpcb_gettime(timep,host="localhost")
          char *host
          time_t timep = NO_INIT
          CODE:
               RETVAL = rpcb_gettime( host, &timep );
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB11

bool_t
rpcb_gettime(timep, ...)
          time_t timep = NO_INIT
	  PREINIT:
          char *host = "localhost";
          CODE:
		  if( items > 1 )
		       host = (char *)SvPV(ST(1), na);
		  RETVAL = rpcb_gettime( host, &timep );
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB12

bool_t
rpcb_gettime(timep)
          time_t timep = NO_INIT
	  PREINIT:
          char *host = "localhost";
          CODE:
	  RETVAL = rpcb_gettime( host, &timep );
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB13

bool_t
rpcb_gettime(timep)
          time_t timep = NO_INIT
          CODE:
          char *host = "localhost";
	  RETVAL = rpcb_gettime( host, &timep );
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB14

void
rpcb_gettime(host)
          char *host
          PPCODE:
          {
          time_t  timep;
          bool_t  status;
          status = rpcb_gettime( host, &timep );
          EXTEND(sp, 2);
          PUSHs(sv_2mortal(newSViv(status)));
          PUSHs(sv_2mortal(newSViv(timep)));
          }

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB15

void
rpcb_gettime(host)
          char *host
	  PREINIT:
          time_t  timep;
          bool_t  status;
          PPCODE:
          status = rpcb_gettime( host, &timep );
          EXTEND(sp, 2);
          PUSHs(sv_2mortal(newSViv(status)));
          PUSHs(sv_2mortal(newSViv(timep)));

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB16

void
rpcb_gettime(host)
          char *  host
	  PREINIT:
          time_t  timep;
          bool_t x;
          CODE:
          ST(0) = sv_newmortal();
          if( rpcb_gettime( host, &timep ) )
               sv_setnv( ST(0), (double)timep);

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB17

void
rpcb_gettime(host)
          char *  host
	  PREINIT:
          time_t  timep;
          bool_t x;
          CODE:
          ST(0) = sv_newmortal();
          if( rpcb_gettime( host, &timep ) ){
               sv_setnv( ST(0), (double)timep);
          }
          else{
               ST(0) = &sv_undef;
          }

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB18

void
rpcb_gettime(host)
          char *host
	  PREINIT:
          time_t  timep;
          PPCODE:
          if( rpcb_gettime( host, &timep ) )
               PUSHs(sv_2mortal(newSViv(timep)));
          else{
          /* Nothing pushed on stack, so an empty */
          /* list is implicitly returned. */
          }

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB19

bool_t
rpcb_gettime(host,timep)
          char *host
	  PREINIT:
	  time_t tt;
	  INPUT:
          time_t timep
          CODE:
               RETVAL = rpcb_gettime( host, &tt );
	       timep = tt;
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB20

bool_t
rpcb_gettime(host,timep)
	  PREINIT:
	  time_t tt;
	  INPUT:
          char *host
	  PREINIT:
	  char *h;
	  INPUT:
          time_t timep
          CODE:
	       h = host;
	       RETVAL = rpcb_gettime( h, &tt );
	       timep = tt;
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB21

bool_t
rpcb_gettime(host,timep)
          char *host
          time_t &timep
	  INIT:
	  printf("# Host is %s\n", host );
          OUTPUT:
          timep

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB22

bool_t
rpcb_gettime(timep, ...)
          time_t timep = NO_INIT
	  PROTOTYPE: $;$
	  PREINIT:
          char *host = "localhost";
          CODE:
		  if( items > 1 )
		       host = (char *)SvPV(ST(1), na);
		  RETVAL = rpcb_gettime( host, &timep );
          OUTPUT:
          timep
          RETVAL

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB23

bool_t
rpcb_gettime(host,timep)
          char *host
          time_t &timep
	  ALIAS:
	    FOO::gettime = 1
	    BAR::getit = 2
	  INIT:
	  printf("# ix = %d\n", ix );
          OUTPUT:
          timep

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB24

INCLUDE: Rpcb1.xsh

MODULE = XSTEST::RPCB1		PACKAGE = RPC

void
rpcb_gettime(host="localhost")
          char *host
	  PREINIT:
          time_t  timep;
          CODE:
          ST(0) = sv_newmortal();
          if( rpcb_gettime( host, &timep ) )
               sv_setnv( ST(0), (double)timep );

Netconfig *
getnetconfigent(netid="udp")
          char *netid

MODULE = XSTEST::RPCB1		PACKAGE = NetconfigPtr  PREFIX = rpcb_

void
rpcb_DESTROY(netconf)
          Netconfig *netconf
          CODE:
          printf("# Now in NetconfigPtr::DESTROY\n");
          free( netconf );

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB25

INCLUDE: cat Rpcb1.xsh |

MODULE = XSTEST::RPCB1		PACKAGE = XSTEST::RPCB26

long
rpcb_gettime(a,b)
  CASE: ix == 1
	  ALIAS:
	  x_gettime = 1
	  INPUT:
	  # 'a' is timep, 'b' is host
          char *b
          time_t a = NO_INIT
          CODE:
               RETVAL = rpcb_gettime( b, &a );
          OUTPUT:
          a
          RETVAL
  CASE:
	  # 'a' is host, 'b' is timep
          char *a
          time_t &b = NO_INIT
          OUTPUT:
          b
          RETVAL
