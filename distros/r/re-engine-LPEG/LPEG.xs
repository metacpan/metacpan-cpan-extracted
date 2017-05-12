#include "lauxlib.h"
#include "lualib.h"

extern int luaopen_lpeg (lua_State *L);

static const luaL_Reg lualibs[] = {
    {"", luaopen_base},
    {LUA_LOADLIBNAME, luaopen_package},
    {LUA_STRLIBNAME, luaopen_string},
#if 0
    {LUA_TABLIBNAME, luaopen_table},
    {LUA_IOLIBNAME, luaopen_io},
    {LUA_OSLIBNAME, luaopen_os},
    {LUA_MATHLIBNAME, luaopen_math},
    {LUA_DBLIBNAME, luaopen_debug},
#endif
    {"lpeg", luaopen_lpeg},
    {NULL, NULL}
};

static lua_State *L; /* Lua interpreter instance */

/* definitions from lpeg.c */

/* initial size for capture's list */
#define IMAXCAPTURES	600

typedef unsigned char byte;

/* kinds of captures */
typedef enum CapKind {
  Cclose, Cposition, Cconst, Cbackref, Carg, Csimple, Ctable, Cfunction,
  Cquery, Cstring, Csubst, Cfold, Cruntime, Cgroup
} CapKind;

typedef struct Capture {
  const char *s;  /* position */
  short idx;
  byte kind;
  byte siz;
} Capture;

#define captype(cap)	((cap)->kind)

#define isclosecap(cap)	(captype(cap) == Cclose)

extern const char *match (lua_State *L,
                          const char *o, const char *s, const char *e,
                          void *op, Capture *capture, int ptop);

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "LPEG.h"        /* re::engine glue */

/* lpeg_engine methods */

REGEXP *
LPEG_comp(pTHX_ const SV * const pattern, const U32 flags)
{
    REGEXP *rx;

    STRLEN plen;
    char *exp = SvPV((SV*)pattern, plen);
    U32 extflags = flags;
    int err;

    if (flags & ~(RXf_SPLIT)) {
        warn("flags not supported by re::engine::LPEG\n");
#ifdef DEBUG
        warn("\t0x%08x\n", flags);
#endif
    }

#ifdef DEBUG
    warn("LPEG_comp |%s|\n", exp);
#endif

    /* C<split " ">, bypass the engine alltogether and act as perl does */
    if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ')
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);

    /* RXf_NULL - Have C<split //> split by characters */
    if (plen == 0)
        extflags |= RXf_NULL;

    Newxz(rx, 1, REGEXP);

    rx->refcnt   = 1;
    rx->extflags = extflags;
    rx->engine   = &lpeg_engine;

    /* Preserve a copy of the original pattern */
    rx->prelen = (I32)plen;
    rx->precomp = SAVEPVN(exp, plen);

    /* qr// stringification */
    rx->wraplen = rx->prelen;
    rx->wrapped = (char *)rx->precomp;

    /* Compile and save the pattern */
    lua_getglobal(L, "re");
    lua_pushstring(L, "compile");
    lua_gettable(L, -2); /* get re['compile'] */
    lua_remove(L, -2); /* remove 're' from the stack */
    lua_pushstring(L, exp);
    err = lua_pcall(L, 1, 1, 0); /* call re.compile with 1 argument and 1 result */
    if (err) {
        size_t len;
        croak("re::engine::LPEG_comp (%s)", lua_tolstring(L, -1, &len));
        return NULL;
    }
    rx->pprivate = lua_touserdata(L, -1);
    /* don't pop the compiled pattern. lua_pop(L, 1); */

    /* return the regexp */
    return rx;
}

I32
LPEG_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, I32 minend, SV * sv,
          void *data, U32 flags)
{
    int err;
    Capture capture[IMAXCAPTURES];
    const char *r;
    size_t l = strlen(stringarg);
    int ptop = lua_gettop(L);

#ifdef DEBUG
    warn("LPEG_exec |%s|%s|\n", stringarg, rx->precomp);
#endif

    memset(capture, 0, sizeof capture);
    lua_pushnil(L);  /* subscache */
    lua_pushlightuserdata(L, capture);  /* caplistidx */
    lua_getfenv(L, 1);  /* penvidx */
    r = match(L, stringarg, stringarg, stringarg + l,
              rx->pprivate, capture, ptop);
    if (NULL == r) {
        /* Matching failed */
#ifdef DEBUG
        warn("not match\n");
#endif
        return 0;
    }
    else {
        unsigned n = 0;

        rx->subbeg = strbeg;
        rx->sublen = strend - strbeg;

        if (!isclosecap(&capture[0])) {
            Capture *c;
            for (c = &capture[0]; !isclosecap(c); c++) {
               switch (captype(c)) {
               case Csimple:
                   n++;
                   break;
               }
            }
        }

        rx->nparens = rx->lastparen = rx->lastcloseparen = n;
        Newxz(rx->offs, n + 1, regexp_paren_pair);

        rx->offs[0].start = 0;
        rx->offs[0].end   = r - stringarg;

#ifdef DEBUG
        warn("match (%d) [%d-%d]\n", n, rx->offs[0].start, rx->offs[0].end);
#endif

        if (n) {
            Capture *c;
            unsigned i = 1;
            for (c = &capture[0]; !isclosecap(c); c++) {
               switch (captype(c)) {
               case Csimple:
                   rx->offs[i].start = c->s - stringarg;
                   rx->offs[i].end   = rx->offs[i].start + c->siz - 1;
#ifdef DEBUG
                   warn("capt %d [%d-%d]\n", i, rx->offs[i].start, rx->offs[i].end);
#endif
                   i++;
                   break;
               }
            }
        }

        return 1;
    }
}

char *
LPEG_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos,
             char *strend, U32 flags, re_scream_pos_data *data)
{
    PERL_UNUSED_ARG(rx);
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(strpos);
    PERL_UNUSED_ARG(strend);
    PERL_UNUSED_ARG(flags);
    PERL_UNUSED_ARG(data);
    return NULL;
}

SV *
LPEG_checkstr(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return NULL;
}

void
LPEG_free(pTHX_ REGEXP * const rx)
{
 /*
  * rx->pprivate is handled by the Lua Garbage Collector,
  * compiled regexes (userdata) stay referenced in the stack.
  */
}

void *
LPEG_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    return rx->pprivate;
}

SV *
LPEG_package(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return newSVpvs("re::engine::LPEG");
}

/* end of lpeg_engine methods */

static void *l_alloc (void *ud, void *ptr, size_t osize, size_t nsize) {
    PERL_UNUSED_ARG(ud);
    PERL_UNUSED_ARG(osize);
    if (nsize == 0) {
        PerlMem_free(ptr);
        return NULL;
    }
    else
        return PerlMem_realloc(ptr, nsize);
}


static int panic (lua_State *L) {
    PERL_UNUSED_ARG(L);
    croak("PANIC: unprotected error in call to Lua API (%s)",
          lua_tostring(L, -1));
    return 0;
}

/* XS glue */

MODULE = re::engine::LPEG    PACKAGE = re::engine::LPEG
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(PTR2IV(&lpeg_engine))));

BOOT:
{
    STRLEN n_a;
    int err;
    const luaL_Reg *lib = lualibs;
    /* first, create a Lua interpreter */
    L = lua_newstate(l_alloc, NULL);
    if (NULL == L)
        croak("re::engine::LPEG (can't allocate Lua state)");
    lua_atpanic(L, &panic);
    /* now, register some standard libraries and lpeg */
    for (; lib->func; lib++) {
        lua_pushcfunction(L, lib->func);
        lua_pushstring(L, lib->name);
        lua_call(L, 1, 0);
    }

    /* find 're.lua' path */
    eval_pv("$path = $INC{'re/engine/LPEG.pm'}; "
            "$path =~ s/\\.pm$//; "
            "$path .= '/re.lua'; ", TRUE);
    /* finally, load 're.lua' */
    err = luaL_loadfile(L, SvPV(get_sv("path", FALSE), n_a));
    if (!err) {
        err = lua_pcall(L, 0, LUA_MULTRET, 0);
    }
    if (err) {
        size_t len;
        switch (err) {
        case LUA_ERRMEM:
            croak("re::engine::LPEG (not enough memory)");
            break;
        case LUA_ERRSYNTAX:
        case LUA_ERRRUN:
            croak("re::engine::LPEG (%s)", lua_tolstring(L, -1, &len));
            break;
        case LUA_ERRFILE:
            croak("re::engine::LPEG (can't open/read the file 're.lua')");
            break;
        default:
            croak("re::engine::LPEG (BOOT %d)", err);
        }
    }
}

