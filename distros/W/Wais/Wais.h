#ifndef _WAIS_H_
#define _WAIS_H_

#ifndef _AP
#define _AP(A) _(A)
#endif
#ifdef WORD
#undef WORD			/* defined in the perl parser */
#endif
#ifdef _config_h_
#undef _config_h_		/* load the freeWAIS-sf config.h also */
#endif
#ifdef warn
#undef warn
#endif
#ifdef alloca
#undef alloca
#endif
#ifdef Strerror
#undef Strerror
#endif
#include <wais.h>
#endif /* _WAIS_H_ */
