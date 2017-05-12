/* -------------------------------------------------------------------
    nsapi_perl.h - header file for nsapi_perl

    Copyright (C) 1997, 1998 Benjamin Sugars

    This is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.
 
    This software is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with this software. If not, write to the Free Software
    Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
------------------------------------------------------------------- */

/* Some versions of Netscape servers need this defined.  */
#ifndef NSAPI_PUBLIC
#define NSAPI_PUBLIC
#endif

/* Function prototypes */
void xs_init _((void));
int nsapi_perl_bootstrap(Session *, Request *, char *);
SV *nsapi_perl_bless_request(Request *);
SV *nsapi_perl_bless_session(Session *);
NSAPI_PUBLIC SV *nsapi_perl_pblock2hash_ref(pblock *);
NSAPI_PUBLIC void traceLog(char *, ...);
int nsapi_perl_eval_ok(Session *, Request *);
int nsapi_perl_require_module(Session *, Request *, char *);

/* dlopen stuff */
#ifdef NP_BOOTSTRAP
#include <dlfcn.h>
#endif
#if defined(NP_BOOTSTRAP) && defined(RTLD_GLOBAL)
#define NP_USE_NP_BOOTSTRAP
#endif

/* nsapi_perl trace facility */
#ifdef PERL_TRACE
#define NP_TRACE(a) if(trace) a;
#else
#define NP_TRACE(a)
#endif
