#include "hunspell.hxx"
#include "assert.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif



using namespace std;
/*using namespace Hunspell;*/

static void * get_mortalspace ( size_t nbytes ) {
    SV * mortal;
    mortal = sv_2mortal( NEWSV(0, nbytes ) );
    return (void *)SvPVX(mortal);
}

MODULE = Text::Hunspell        PACKAGE = Text::Hunspell

PROTOTYPES: ENABLE

# Make sure that we have at least xsubpp version 1.922.
REQUIRE: 1.922

Hunspell *
Hunspell::new(aff,dic )
    char *aff;
    char *dic;
    CODE:
        RETVAL = new Hunspell(aff, dic);

    OUTPUT:
        RETVAL

int
Hunspell::delete(h)
    Hunspell *h;
    CODE:
        warn("Text::Hunspell::delete() is deprecated and no replacement is needed");
        RETVAL = 1;
    OUTPUT:
        RETVAL

void
Hunspell::DESTROY()

int
Hunspell::add_dic(dic)
    char *dic;
    CODE:
        RETVAL = THIS->add_dic(dic);

    OUTPUT:
        RETVAL

int
Hunspell::check(buf)
    char *buf;
    CODE:
        RETVAL = THIS->spell(buf);

    OUTPUT:
        RETVAL

void 
Hunspell::suggest(buf)
    char *buf;
    PREINIT:
        char **wlsti;
	int i, val;
    PPCODE:
        val = THIS->suggest(&wlsti, buf);
	for (int i = 0; i < val; i++) {
            PUSHs(sv_2mortal(newSVpv( wlsti[i] ,0 )));
	}
	THIS->free_list(&wlsti, val);

void 
Hunspell::analyze(buf)
    char *buf;
    PREINIT:
        char **wlsti;
        int i, val;
    PPCODE:
        val = THIS->analyze(&wlsti, buf);
        for (i = 0; i < val; i++) {
            PUSHs(sv_2mortal(newSVpv(wlsti[i], 0)));
        }
	THIS->free_list(&wlsti, val);


void 
Hunspell::stem( buf)
    char *buf;
    PREINIT:
        char **wlsti;
	int i, val;
    PPCODE:
        val = THIS->stem(&wlsti, buf);
	for (int i = 0; i < val; i++) {
            PUSHs(sv_2mortal(newSVpv( wlsti[i] ,0 )));
	}
	THIS->free_list(&wlsti, val);


void 
Hunspell::generate( buf, sample)
    char *buf;
    char *sample;
    PREINIT:
        char **wlsti;
	int i, val;
    PPCODE:
        val = THIS->generate(&wlsti, buf, sample);
	for (int i = 0; i < val; i++) {
            PUSHs(sv_2mortal(newSVpv( wlsti[i] ,0 )));
	}
	THIS->free_list(&wlsti, val);


void 
Hunspell::generate2( buf, avref)
    AV * avref;
    char *buf;
    PREINIT:
        char ** array;
        char **wlsti;
        int len;
        SV ** elem;
        int i, val;
    PPCODE:
        len = av_len(avref) + 1;

        /* First allocate some memory for the pointers */
        array = (char **) get_mortalspace( len * sizeof( *array ));

        /* Loop over each element copying pointers to the new array */
        for (i=0; i<len; i++) {
            elem = av_fetch( avref, i, 0 );
            array[i] = SvPV( *elem, PL_na );
        }

        val = THIS->generate(&wlsti, buf, array,  len);

        for (int i = 0; i < val; i++) {
            PUSHs(sv_2mortal(newSVpv( wlsti[i] ,0 )));
        }
	THIS->free_list(&wlsti, val);

