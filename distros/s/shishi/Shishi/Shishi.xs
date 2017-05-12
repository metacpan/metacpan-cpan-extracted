#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <shishi.h>

#include "const-c.inc"

int Shishi_perl_comparison(ShishiDecision* d, char* text, Shishi* parser, ShishiMatch* match, SV* callback) {
    dSP;
    int count;
    int rc;
    SV* parser_sv = NEWSV(0,0);
    SV* match_sv = NEWSV(0,0);
    SV* d_sv = NEWSV(0,0);
    SV* text_sv = sv_2mortal(newSVpv(text,0));
    sv_2mortal(sv_setref_pv(match_sv, "ShishiMatchPtr", (void*)match));
    sv_2mortal(sv_setref_pv(parser_sv, "ShishiPtr", (void*)parser));
    sv_2mortal(sv_setref_pv(d_sv, "ShishiDecisionPtr", (void*)d));

    ENTER;
    SAVETMPS;
    PUSHMARK(sp);

    XPUSHs(d_sv);
    XPUSHs(text_sv);
    XPUSHs(parser_sv);
    XPUSHs(match_sv);

    PUTBACK;

    count = Perl_call_sv(callback, G_SCALAR);
    SPAGAIN;
    if (count == 1)
        rc = POPi;
    else
        rc = 0;

    PUTBACK;

    /* Curse destroyable SVs */
    SvOBJECT_off(SvRV(parser_sv));
    SvOBJECT_off(SvRV(match_sv));

    FREETMPS;
    LEAVE;

    return rc;
}

MODULE = Shishi		PACKAGE = Shishi		PREFIX = Shishi_

void
constant(sv)
    PREINIT:
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
        /* Change this to constant(aTHX_ s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(aTHX_ s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid Shishi macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Shishi macro %s, used",
               type, s));
          PUSHs(sv);
        }

Shishi* 
Shishi_new( class, owner )
    char* class
    char* owner
  CODE:
    RETVAL = Shishi_new(owner);
  OUTPUT:
    RETVAL

ShishiMatch*
Shishi_new_match( class, text )
    char* class
    char* text
  CODE:
    RETVAL = Shishi_match_new(text);
  OUTPUT:
    RETVAL

MODULE = Shishi             PACKAGE = ShishiMatchPtr

void*
DESTROY(match)
    ShishiMatch* match
    CODE:
        Shishi_match_destroy(match);


MODULE = Shishi             PACKAGE = ShishiPtr   PREFIX = Shishi_

void*
DESTROY( shishi )
    Shishi* shishi
    CODE:
        Shishi_destroy(shishi);

void*
Shishi_add_node( shishi, node)
    Shishi* shishi
    ShishiNode* node

int 
Shishi_execute(parser, match)
    Shishi* parser
    ShishiMatch* match

ShishiNode*
start_node(parser)
    Shishi* parser
    CODE:
    RETVAL = parser->nodes[0];
    OUTPUT:
    RETVAL


MODULE = Shishi             PACKAGE = Shishi::Node PREFIX = Shishi_node_

ShishiNode*
new( class, owner )
    char* class
    char* owner
    CODE:
    RETVAL = Shishi_node_create(owner);
    OUTPUT: 
    RETVAL

MODULE = Shishi             PACKAGE = ShishiNodePtr PREFIX = Shishi_node_

int
Shishi_node_execute(node, parser, match)
    ShishiNode* node
    Shishi* parser
    ShishiMatch* match

ShishiNode* 
Shishi_node_add_decision(node, d)
    ShishiNode* node
    ShishiDecision* d

MODULE = Shishi            PACKAGE = Shishi::Decision PREFIX = Shishi_decision_

ShishiDecision*
Shishi_decision_create()

MODULE = Shishi           PACKAGE = ShishiDecisionPtr

shishi_match_t
target_type(d, ...)
    ShishiDecision* d
    CODE:
        if (items>1) {
            shishi_match_t new = SvIV(ST(1));
            if (d->target_type == SHISHI_MATCH_TEXT && new != SHISHI_MATCH_TEXT) {
                if (d->target.string.buffer)
                    free(d->target.string.buffer);
                d->target.string.buffer = 0;
                d->target.string.length = 0;
            }
            d->target_type = new;
        }
        RETVAL = d->target_type;
    OUTPUT:
        RETVAL

shishi_action_t
_action(d, ...)
    ShishiDecision* d
    CODE:
        if (items>1) {
            d->action = SvIV(ST(1));
        }
        RETVAL = d->action;
    OUTPUT:
        RETVAL

#ifdef SHISHI_DEBUG
#define bad_set(x,d) croak("Tried to set the %s for a non-%s decision (%s)!", x,x,Shishi_debug_matchtypes[d->target_type])
#else
#define bad_set(x,d) croak("Tried to set the %s for a non-%s decision!", x,x)
#endif


token_t
_token(d, ...)
    ShishiDecision* d
    CODE:
{
    if (d->target_type != SHISHI_MATCH_TOKEN && d->target_type != SHISHI_MATCH_CHAR)
	bad_set("token",d);
    if (items>1) {
	d->target.token = (token_t)SvIV(ST(1));
    }
    RETVAL = d->target.token;
}
    OUTPUT:
        RETVAL

SV*
code(d, ...)
    ShishiDecision* d
    CODE:

    BREAKPOINT;
    if (d->target_type != SHISHI_MATCH_CODE) 
        bad_set("code",d);
    if (items>1) {
        d->target.comparison.function = (shishi_comparison_t*)Shishi_perl_comparison;
        d->target.comparison.data = SvREFCNT_inc(ST(1));
    }
    RETVAL = newSVsv(d->target.comparison.data);

    OUTPUT:
    RETVAL

SV*
text(d, ...)
     ShishiDecision* d
     CODE:
{
    if (d->target_type != SHISHI_MATCH_TEXT)
	bad_set("string",d);
    if (items>1) {
	STRLEN len;
        if (!SvOK(ST(1)))
            croak("Bad argument!");
	if (d->target.string.buffer) {
	    free(d->target.string.buffer);
        }
	d->target.string.buffer = savepv(SvPV(ST(1),len));
        d->target.string.length = len;
    }
    if (!d->target.string.buffer) {
        RETVAL = newSV(0);
    } else 
    RETVAL = newSVpv(d->target.string.buffer, d->target.string.length);
}
    OUTPUT:
       RETVAL

void
next_node(d, node)
    ShishiDecision* d
    ShishiNode* node
    CODE:
        d->next_node = node;
