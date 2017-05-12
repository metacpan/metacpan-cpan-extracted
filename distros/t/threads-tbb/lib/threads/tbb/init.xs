#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}
#endif

/* include your class headers here */
#include "tbb.h"
#include "interpreter_pool.h"

/* We need one MODULE... line to start the actual XS section of the file.
 * The XS++ preprocessor will output its own MODULE and PACKAGE lines */
MODULE = threads::tbb::init		PACKAGE = threads::tbb::init

PROTOTYPES: DISABLE

perl_tbb_init*
perl_tbb_init::new( thr )
	int thr;

void
perl_tbb_init::initialize( )

void
set_boot_lib( init, boot_lib )
	perl_tbb_init* init;
	AV* boot_lib;
  PREINIT:
	int i;
	STRLEN libname_len;
	const char* libname;
  CODE:
	for (i = 0; i <= av_len(boot_lib); i++) {
		SV** slot = av_fetch(boot_lib, i, 0);
		if (!slot || !SvPOK(*slot))
			continue;
		libname = SvPV( *slot, libname_len );
		IF_DEBUG_INIT("INC includes %s", libname);
		init->boot_lib.push_back( std::string( libname, libname_len ));
	}

void
set_boot_use( init, boot_use )
	perl_tbb_init* init;
	AV* boot_use;
  PREINIT:
	int i;
	STRLEN libname_len;
	const char* libname;
  CODE:
	for (i = 0; i <= av_len(boot_use); i++) {
		SV** slot = av_fetch(boot_use, i, 0);
		if (!slot || !SvPOK(*slot))
			continue;
		libname = SvPV( *slot, libname_len );
		IF_DEBUG_INIT("use list includes %s", libname);
		init->boot_use.push_back( std::string( libname, libname_len ));
	}

void
perl_tbb_init::DESTROY()
CODE:
	IF_DEBUG_LEAK("init::DESTROY; %x", THIS);
	if (THIS != NULL)
		delete THIS;

void
perl_tbb_init::terminate()
