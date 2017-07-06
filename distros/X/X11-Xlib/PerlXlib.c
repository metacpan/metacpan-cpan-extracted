#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XTest.h>
#ifdef HAVE_XRENDER
#include <X11/extensions/Xrender.h>
#endif

#include "PerlXlib.h"

static MGVTBL PerlXlib_dpy_mg_vtbl;
static MGVTBL PerlXlib_dpy_innerptr_mg_vtbl;

extern Display * PerlXlib_get_magic_dpy(SV *sv, Bool not_null) {
    MAGIC *mg= NULL;
    if (sv_isobject(sv)) {
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &PerlXlib_dpy_mg_vtbl) {
                if (!mg->mg_ptr && not_null) break;
                return (Display*) mg->mg_ptr;
            }
        }
    }
    if (not_null) {
        if (SvTRUE(get_sv("X11::Xlib::_error_fatal_trapped", GV_ADD)))
            croak("Cannot call further Xlib functions after fatal Xlib error");
        if (mg) /* has magic, but NULL pointer */
            croak("X11 connection was closed");
        if (!sv_derived_from(sv, "X11::Xlib"))
            croak("Invalid X11 connection; must be instance of X11::Xlib");
        croak("Invalid X11 connection; missing 'magic' Display* reference");
    }
    return NULL;    
}

extern SV * PerlXlib_set_magic_dpy(SV *sv, Display *dpy) {
    MAGIC *mg= NULL;
    Display *old_dpy= NULL;
    SV **fp;
    HV *cache;
    
    if (!sv_isobject(sv))
        croak("Can't add magic Display* to non-object");
    
    /* Search for existing Magic that would hold this pointer */
    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &PerlXlib_dpy_mg_vtbl) {
            old_dpy= (Display*) mg->mg_ptr;
            mg->mg_ptr= (void*) dpy;
            break;
        }
    }
    
    /* If value remains unchanged, nothing to do */
    if (dpy == old_dpy) return sv;
    /* If magic doesn't exist, add it */
    if (!mg)
        sv_magicext(SvRV(sv), NULL, PERL_MAGIC_ext, &PerlXlib_dpy_mg_vtbl, (const char *) dpy, 0);
    
    cache= get_hv("X11::Xlib::_connections", GV_ADD);
    /* Object might be cached under old dpy key.  Remove the cache reference. */
    if (old_dpy)
        hv_delete(cache, (void*) &old_dpy, sizeof(old_dpy), G_DISCARD);
    
    /* Cache a weak ref to this object keyed by the new Display* value */
    if (dpy) {
        fp= hv_fetch(cache, (void*) &dpy, sizeof(dpy), 1);
        if (!fp) croak("failed to add item to hash (tied?)");
        if (*fp && SvROK(*fp) && SvRV(*fp) != SvRV(sv))
            warn("Replacing cached connection object for Display* 0x%p!", dpy);
        /* New weak-ref to this object
          * Docs warn that sv_setsv might de-allocate mortal sources, so inc ref count temporarily
          */
        SvREFCNT_inc(sv);
        if (!*fp) *fp= newSVsv(sv); else sv_setsv(*fp, sv);
        sv_2mortal(sv);
        sv_rvweaken(*fp);
    }
    return sv;
}

/* Converting a Display* to a \X11::Xlib is difficult because we want
 * to re-use the existing object.  We cache them in %X11::Xlib::_connections.
 * This function returns a mortal strong-reference to an instance of X11::Xlib (or subclass)
 */
extern SV * PerlXlib_obj_for_display(Display *dpy, int create) {
    SV **fp, *self;
    if (!dpy) {
        /* Translate NULL to undef */
        return &PL_sv_undef;
    }
    else {
        fp= hv_fetch(get_hv("X11::Xlib::_connections", GV_ADD), (void*) &dpy, sizeof(dpy), 0);
        /* Return existing object if we have one for this Display* already */
        if (fp && *fp && SvROK(*fp)) {
            /* create strong-ref from weakref */
            return sv_mortalcopy(*fp);
        }
        else if (create) {
            /* Always create instance of X11::Xlib.  X11::Xlib::Display can re-bless as needed. */
            self= sv_2mortal(newRV_noinc((SV*) newHV()));
            sv_bless(self, gv_stashpv("X11::Xlib", GV_ADD));
            PerlXlib_set_magic_dpy(self, dpy); /* This also adds it to the _connections cache */
            return self;
        }
        else {
            return sv_2mortal(newSVuv(PTR2UV(dpy)));
        }
    }
}

extern void * PerlXlib_get_magic_dpy_innerptr(SV *sv, Bool not_null) {
    MAGIC *mg= NULL;
    if (sv_isobject(sv)) {
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &PerlXlib_dpy_innerptr_mg_vtbl) {
                if (!mg->mg_ptr && not_null) break;
                return mg->mg_ptr;
            }
        }
    }
    if (not_null)
        croak("Object lacks Xlib magic pointer");
    return NULL;
}

extern SV * PerlXlib_set_magic_dpy_innerptr(SV *sv, void *innerptr) {
    MAGIC *mg= NULL;
    SV **fp;
    HV *cache;
    
    if (!sv_isobject(sv))
        croak("Can't add magic Xlib pointer to non-object");
    
    /* Search for existing Magic that would hold this pointer */
    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &PerlXlib_dpy_innerptr_mg_vtbl) {
            mg->mg_ptr= innerptr;
            return sv;
        }
    }
    
    /* If magic doesn't exist, add it */
    sv_magicext(SvRV(sv), NULL, PERL_MAGIC_ext, &PerlXlib_dpy_innerptr_mg_vtbl, (const char *) innerptr, 0);
    return sv;
}

extern SV * PerlXlib_get_displayobj_of_opaque(void *opaque) {
    SV **elem= hv_fetch(get_hv("X11::Xlib::_display_attr", GV_ADD),
        (void*)&opaque, sizeof(void*), 0);
    return (elem && *elem && sv_isobject(*elem))? *elem : &PL_sv_undef;
}

extern void PerlXlib_set_displayobj_of_opaque(void *opaque, SV *dpy_sv) {
    SV **elem;
    if (dpy_sv && SvOK(dpy_sv)) {
        elem= hv_fetch(get_hv("X11::Xlib::_display_attr", GV_ADD),
            (void*)&opaque, sizeof(void*), 1);
        if (!elem) croak("Can't write X11::Xlib::_display_attr");
        if (*elem && SvROK(*elem)) {
            if (SvRV(dpy_sv) == SvRV(*elem))
                return; /* redundant.  ignore it. */
            croak("Can't modify display attribute once it is initialized");
        }
        if (!*elem) *elem= newSV(0);
        sv_setsv(*elem, dpy_sv);
    }
    else {
        hv_delete(get_hv("X11::Xlib::_display_attr", GV_ADD),
            (void*)&opaque, sizeof(void*), G_DISCARD);
    }
}

/* Most other opaque pointers related to a Display* connection need paired with
 * the Display* they represent, and should hold a strong reference to the Display*
 * else the user might still be holding one after the display is closed.
 */
extern SV * PerlXlib_obj_for_display_innerptr(Display *dpy, void *thing, const char *thing_class, int objsvtype, bool create) {
    SV **elem= NULL, *ret= NULL, *dpy_obj= NULL;
    HV *obj_cache= NULL;
    
    if (!thing)
        return &PL_sv_undef;

    if (dpy) {
        dpy_obj= PerlXlib_obj_for_display(dpy, 1);
        /* record which display it came from, in a strong-ref global */
        PerlXlib_set_displayobj_of_opaque(thing, dpy_obj);
    } else {
        dpy_obj= PerlXlib_get_displayobj_of_opaque(thing);
    }
    
    /* If we have the display object, check its cache to see if this thing
      * already has a cached wrapper object. */
    if (dpy_obj && SvOK(dpy_obj)) {
        /* first get the cache hashref */
        elem= hv_fetch((HV*)SvRV(dpy_obj), "_obj_cache", 10, 1);
        if (!elem) croak("Can't create $display->{_obj_cache}");
        if (*elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV)
            obj_cache= (HV*) SvRV(*elem);
        else {
            obj_cache= newHV();
            if (*elem) sv_setsv(*elem, sv_2mortal(newRV_noinc((SV*) obj_cache)));
            else *elem= newRV_noinc((SV*) newHV());
        }
        /* then check the obj_cache for a match */
        elem= hv_fetch(obj_cache, (void*) &thing, sizeof(thing), 1);
        if (elem && *elem && SvOK(*elem))
            return *elem;
    }
    /* No object, unless we're allowed to create one */
    if (!create)
        return &PL_sv_undef;
    
    /* if no display was given, we don't have an object cache. */
    if (obj_cache) {
        if (!elem) croak("Can't write to $display->{obj_cache}");
        if (!*elem) *elem= newSV(0);
    }
    /* Now, if obj_cache is not null, then we can assign to *elem. */
    
    if (objsvtype == SVt_PVMG) {
        ret= sv_setref_pv(sv_newmortal(), thing_class, thing);
    }
    else if (objsvtype == SVt_PVHV) {
        ret= sv_2mortal(newRV_noinc((SV*) newHV()));
        sv_bless(ret, gv_stashpv(thing_class, GV_ADD));
        PerlXlib_set_magic_dpy_innerptr(ret, thing);
    }
    else if (objsvtype == SVt_PVAV) {
        ret= sv_2mortal(newRV_noinc((SV*) newAV()));
        sv_bless(ret, gv_stashpv(thing_class, GV_ADD));
        PerlXlib_set_magic_dpy_innerptr(ret, thing);
    }
    else
        croak("Unsupported svtype in PerlXlib_obj_for_display_innerptr");
    
    /* store a weak reference in the object cache */
    if (obj_cache) {
        /* ret is mortal, and sv_setsv warns that mortals might get freed... so do this silly dance */
        SvREFCNT_inc(ret);
        sv_setsv(*elem, ret);
        sv_rvweaken(*elem);
        sv_2mortal(ret);
    }
    
    return ret;
}

extern void * PerlXlib_sv_to_display_innerptr(SV *sv, bool not_null) {
    void *ptr;
    if (sv && sv_isobject(sv)) {
        if (SvTYPE(SvRV(sv)) < SVt_PVAV)
            ptr= INT2PTR(void*, SvIV((SV*)SvRV(sv)));
        else
            ptr= PerlXlib_get_magic_dpy_innerptr(sv, not_null);
        if (ptr) return ptr;
    }
    if (not_null)
        croak("Not an Xlib opaque pointer");
    return NULL;
}

extern Screen * PerlXlib_sv_to_screen(SV *sv, bool not_null) {
    HV *hv;
    SV **elem;
    Display *dpy;
    int screennum;
    
    if (!sv || !SvROK(sv) || !SvTYPE(SvRV(sv)) == SVt_PVHV) {
        if (not_null || (sv && SvOK(sv)))
            croak("expected X11::Xlib::Screen object");
        return NULL;
    }
    
    hv= (HV*) SvRV(sv);
    elem= hv_fetch(hv, "display", 7, 0);
    if (!elem || !*elem || !(dpy= PerlXlib_get_magic_dpy(*elem, 1)))
        croak("missing $screen->{display}");
    elem= hv_fetch(hv, "screen_number", 13, 0);
    if (!elem || !*elem || !SvIOK(*elem))
        croak("missing $screen->{screen_number}");
    screennum= SvIV(*elem);
    if (screennum >= ScreenCount(dpy) || screennum < 0)
        croak("Screen number %d out of bounds for this display (0..%d)",
            screennum, ScreenCount(dpy)-1);
    return ScreenOfDisplay(dpy, screennum);
}

extern SV * PerlXlib_obj_for_screen(Screen *screen) {
    Display *dpy;
    SV *dpy_sv, *ret= NULL;
    int i;
    
    if (!screen)
        return &PL_sv_undef;
    dpy= DisplayOfScreen(screen);
    /* There's actually no way to get the screen number from the pointer,
      * other than subtraction on private pointers...  so just iterate.
      * There's probably only one anyway. */
    for (i= 0; i < ScreenCount(dpy); i++) {
        if (screen == ScreenOfDisplay(dpy, i)) {
            /* Need a X11::Xlib::Display object */
            dpy_sv= PerlXlib_obj_for_display(dpy, 1);
            /* Then call $display->screen(i) method */
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(sv_mortalcopy(dpy_sv));
            PUSHs(sv_2mortal(newSViv(i)));
            PUTBACK;
            if (call_method("screen", G_SCALAR) != 1)
                croak("stack assertion failed");
            SPAGAIN;
            ret= POPs;
            SvREFCNT_inc(ret); /* make sure it lives a little longer */
            PUTBACK;
            FREETMPS;
            LEAVE;
            sv_2mortal(ret);
            sv_2mortal(dpy_sv);
            break;
        }
    }
    if (!ret) croak("Corrupt Xlib screen/display structures!");
    return ret;
}

/* Allow unsigned integer, or hashref with field ->{xid} */
XID PerlXlib_sv_to_xid(SV *sv) {
    SV **xid_field;

    if (SvUOK(sv) || SvIOK(sv))
        return (XID) SvUV(sv);

    if (!SvROK(sv) || !(SvTYPE(SvRV(sv)) == SVt_PVHV)
        || !(xid_field= hv_fetch((HV*)SvRV(sv), "xid", 3, 0))
        || !*xid_field || !(SvIOK(*xid_field) || SvUOK(*xid_field)))
        croak("Invalid XID (Window, etc); must be an unsigned int, or an instance of X11::Xlib::XID");

    return (XID) SvUV(*xid_field);
}

/* Inspect each of the perl data structures that are directly manipulated by XS.
 * This is only for debugging.
 */
void PerlXlib_sanity_check_data_structures() {
    HV *dpys, *obj_cache, *display_attr;
    HE *dpy_he, *obj_he;
    SV *dpy_sv, *obj_sv, **elem;
    Display *dpy;
    void *opaque;
    
    dpys= get_hv("X11::Xlib::_connections", GV_ADD);
    /*hv_assert(dpys);*/
    
    display_attr= get_hv("X11::Xlib::_display_attr", GV_ADD);
    /*hv_assert(display_attr);*/
    
    /* for each display */
    for (hv_iterinit(dpys); (dpy_he= hv_iternext(dpys)); ) {
        dpy_sv= hv_iterval(dpys, dpy_he);
        /* SV refcnt should be exactly 1, and should be weakref.  Ref'd object should have >1 refcnt */
        if (SvREFCNT(dpy_sv) != 1) croak("Refcnt of %_connections member is %d", SvREFCNT(dpy_sv));
        if (!SvROK(dpy_sv) || !SvWEAKREF(dpy_sv)) croak("%_connections member is not a weakref");
        if (!sv_derived_from(dpy_sv, "X11::Xlib")) croak("%_connections contains non-X11::Xlib object");
        dpy= PerlXlib_get_magic_dpy(dpy_sv, 1 /* assert non-null */);
        /* Check each of the objects in the $dpy->{_obj_cache} */
        elem= hv_fetch((HV*)SvRV(dpy_sv), "_obj_cache", 10, 0);
        if (elem) {
            if (!*elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
                croak("Display contains invalid _obj_cache");
            if (SvREFCNT(*elem) != 1 || SvREFCNT(SvRV(*elem)) != 1)
                croak("_obj_cache has wrong refcnt");
            obj_cache= (HV*) SvRV(*elem);
            /*hv_assert(obj_cache);*/
            for (hv_iterinit(obj_cache); (obj_he= hv_iternext(dpys)); ) {
                obj_sv= hv_iterval(obj_cache, obj_he);
                if (SvREFCNT(obj_sv) != 1) croak("Refcnt of _obj_cache member is %d", SvREFCNT(obj_sv));
                if (!SvROK(obj_sv) || !SvWEAKREF(obj_sv)) croak("_obj_cache member is not a weakref");
                if (!sv_derived_from(obj_sv, "X11::Xlib::Opaque")) croak("_obj_cache member is not a X11::Xlib::Opaque");
                opaque= (SvTYPE(SvRV(obj_sv)) <= SVt_PVMG)? INT2PTR(void*, SvIV(SvRV(obj_sv)))
                    : PerlXlib_get_magic_dpy_innerptr(obj_sv, 1 /* not null */);
                /* the pointer should have a ->display attribute attached */
                elem= hv_fetch(display_attr, (void*) &opaque, sizeof(void*), 0);
                if (!elem || !*elem || !SvROK(*elem))
                    croak("Missing or invalid _display_attr{} reference");
                if (SvREFCNT(*elem) != 1 || SvWEAKREF(*elem))
                    croak("_display_attr ref is not strongref with refcnt==1");
                if (SvRV(dpy_sv) != SvRV(*elem))
                    croak("_display_attr points to wrong dpy_sv");
            }
        }
    }
}

/* Xlib warns that some structs might change size, and provide "XAllocFoo"
 *   functions.  However, this only solves the case of Xlib access violations
 *   from an old perl module on a new Xlib.  New perl modules on old Xlib would
 *   still write beyond the buffer (on the perl side) and corrupt memory.
 *   Annoyingly, Xlib doesn't seem to have any way to query the size of the struct,
 *   only allocate it.
 * Instead of using XAllocFoo sillyness (and the memory management hassle it
 *   would cause), just pad the struct with some extra bytes.
 * Perl modules will probably always be compiled fresh anyway.
 */
#ifndef X11_Xlib_Struct_Padding
#define X11_Xlib_Struct_Padding 64
#endif
/* Coercions allowed for RValue:
 *   foo( "buffer_of_the_correct_length_or_more" );
 *   foo( \"ref_to_buffer_of_the_correct_length_or_more" );
 *   foo( \%hashref_of_fields );
 *   foo( bless(\"buffer_of_correct_length_or_more", "pkg_or_subclass") )
 * Coercions allowed for LValue:
 *   foo( my $x= undef );
 *   foo( "buffer_of_correct_length_or_more" );
 *   foo( \(my $x= undef) );
 *   foo( \"buffer_of_correct_length_or_more" );
 *   foo( bless(\"buffer_of_correct_length_or_more", "any_struct_class") )
 */
void* PerlXlib_get_struct_ptr(SV *sv, int lvalue, const char* pkg, int struct_size, PerlXlib_struct_pack_fn *packer) {
    SV *tmp, *refsv= NULL;
    void* buf;
    size_t n;

    if (SvROK(sv)) {
        refsv= sv;
        sv= SvRV(sv);
        /* Follow scalar refs, to get to the buffer of a blessed object */
        if (SvTYPE(sv) == SVt_PVMG) {
            /* If it is a blessed object, ensure the type matches */
            if (sv_isobject(refsv) && !sv_isa(refsv, pkg)) {
                if (!sv_derived_from(refsv, lvalue? "X11::Xlib::Struct" : pkg)) {
                    buf= SvPV(refsv, n);
                    croak("Can't coerce %.*s to %s %s", n, buf, pkg, lvalue? "lvalue":"rvalue");
                }
            }
        }
        /* Also accept a hashref, which we pass to "pack" */
        else if (SvTYPE(sv) == SVt_PVHV) {
            if (lvalue) croak("Can't coerce hashref to %s lvalue", pkg);
            /* Need a buffer that lasts for the rest of our XS call stack.
             * Cheat by using a mortal SV :-)
             */
            tmp= sv_2mortal(newSV(struct_size + X11_Xlib_Struct_Padding));
            buf= SvPVX(tmp);
            memset(buf, 0, struct_size);
            packer(buf, (HV*) sv, 0);
            return buf;
        }
        else if (SvTYPE(sv) >= SVt_PVAV) { /* not a scalar */
            buf= SvPV(refsv, n);
            croak("Can't coerce %.*s to %s %s", n, buf, pkg, lvalue? "lvalue":"rvalue");
        }
    }
    
    /* If uninitialized, initialize to a blessed struct object,
     *  unless we're looking at \undef in which case just initialize to a string
     */
    if (!SvOK(sv)) {
        if (!lvalue) croak("Can't coerce %sundef to %s rvalue", refsv? "\\" : "", pkg);
        if (!refsv) {
            refsv= sv, sv= newSVrv(sv, pkg);
            /* sv is now the referenced scalar, which is undef, and gets inflated next */
        }
        sv_setpvn(sv, "", 0);
        SvGROW(sv, struct_size+X11_Xlib_Struct_Padding);
        SvCUR_set(sv, struct_size);
        memset(SvPVX(sv), 0, struct_size+1);
    }
    else if (!SvPOK(sv))
        croak("Paramters requiring %s can only be coerced from string, string ref, hashref, or undef", pkg);
    else if (SvCUR(sv) < struct_size)
        croak("Scalars used as %s must be at least length %d (got %d)", pkg, struct_size, SvCUR(sv));
    /* Make sure we have the padding even if the user tinkered with the buffer */
    SvPV_force(sv, n);
    SvGROW(sv, struct_size+X11_Xlib_Struct_Padding);
    return SvPVX(sv);
}

#include "keysym_to_codepoint.c"

KeySym PerlXlib_codepoint_to_keysym(int uc) {
    /* Latin-1 is identical */
    if ((uc >= 0x0020 && uc <= 0x007E) || (uc >= 0x00A0 && uc <= 0x00FF))
        return uc;
    /* Unicode in range 0..0xFFFFFF can be stored directly */
    if ((uc & 0xFFFFFF) == uc)
        return 0x1000000 | uc;

    return NoSymbol;
}

SV * PerlXlib_keysym_to_sv(KeySym sym, int symbolic) {
    int sym_codepoint;
    const char *symname;
    if (sym == NoSymbol)
        return &PL_sv_undef;
    /* Only convert to unicode character if reverse mapping matches forward mapping */
    if (symbolic >= 2
        && (sym_codepoint= PerlXlib_keysym_to_codepoint(sym)) >= 0
        && (PerlXlib_codepoint_to_keysym(sym_codepoint) == sym))
        return newSVpvf("%c", sym_codepoint);
    /* Fall back to symbol name, but ensure reverse mapping here, as well */
    else if (symbolic >= 1
        && sym > 0
        && (symname= XKeysymToString(sym))
        && (XStringToKeysym(symname) == sym))
        return newSVpv(symname, 0);
    /* Else just use the symbol ID */
    else if (!symbolic || sym > 9)
        return newSViv(sym);
    /* Else it's ambiguous!  Can't be loaded symbolicly. */
    else
        return NULL;
}

KeySym PerlXlib_sv_to_keysym(SV *sv) {
    size_t len;
    long ival, codepoint;
    KeySym sym;
    char *name, *endp;
    
    if (!sv || !SvOK(sv))
        return NoSymbol;
    /* First try to process it as an X11 symbol name */
    name= SvPV(sv, len);
    sym= XStringToKeysym(name);
    /* Else, use multi-digit numbers directly, and single-digit as a char lookup */
    if (sym == NoSymbol) {
        if (SvIOK(sv) && SvIV(sv) > 9)
            sym= SvIV(sv);
        else if ((ival= strtol(name, &endp, 0)) && (endp - name > 1) && *endp == 0)
            sym= ival;
        /* If it is a single character, try looking up a keysym for it */
        else if ((DO_UTF8(sv)? sv_len_utf8(sv) : len) == 1) {
            codepoint= NATIVE_TO_UNI(DO_UTF8(sv)? utf8n_to_uvchr(name, len, &len, 0) : (name[0] & 0xFF));
            sym= PerlXlib_codepoint_to_keysym(codepoint);
        }
    }
    return sym;
}

int PerlXlib_X_error_handler(Display *d, XErrorEvent *e) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(sv_setref_pvn(newSV(0), "X11::Xlib::XErrorEvent", (void*) e, sizeof(XEvent))));
    PUTBACK;
    call_pv("X11::Xlib::_error_nonfatal", G_VOID|G_DISCARD|G_EVAL|G_KEEPERR);
    FREETMPS;
    LEAVE;
    return 0;
}

/*

What a mess.   So Xlib has a stupid design where they forcibly abort the
program when an I/O error occurs and the X server is lost.  Even if you
install the error handler, they expect you to abort the program and they
do it for you if you return.  Furthermore, they tell you that you may not
call any more Xlib functions at all.

Luckily we can cheat with croak (longjmp) back out of the callback and
avoid the forced program exit.  However now we can't officially use Xlib
again for the duration of the program, and there could be lost resources
from our longjmp.  So, set a global flag to prevent any re-entry into XLib.

*/
int PerlXlib_X_IO_error_handler(Display *d) {
    sv_setiv(get_sv("X11::Xlib::_error_fatal_trapped", GV_ADD), 1);
    warn("Xlib fatal error.  Further calls to Xlib are forbidden.");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(PerlXlib_obj_for_display(d, 1));
    PUTBACK;
    call_pv("X11::Xlib::_error_fatal", G_VOID|G_DISCARD|G_EVAL|G_KEEPERR);
    FREETMPS;
    LEAVE;
    croak("Fatal X11 I/O Error"); /* longjmp past Xlib, which wants to kill us */
    return 0; /* never reached.  Make compiler happy. */
}

/* Install the Xlib error handlers, only if they have not already been installed.
 * Use perl scalars to store this status, to avoid threading issues and to
 * give users potential to inspect.
 */
void PerlXlib_install_error_handlers(Bool nonfatal, Bool fatal) {
    SV *nonfatal_installed= get_sv("X11::Xlib::_error_nonfatal_installed", GV_ADD);
    SV *fatal_installed= get_sv("X11::Xlib::_error_fatal_installed", GV_ADD);
    if (nonfatal && !SvTRUE(nonfatal_installed)) {
        XSetErrorHandler(&PerlXlib_X_error_handler);
        sv_setiv(nonfatal_installed, 1);
    }
    if (fatal && !SvTRUE(fatal_installed)) {
        XSetIOErrorHandler(&PerlXlib_X_IO_error_handler);
        sv_setiv(fatal_installed, 1);
    }
}

/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XEvent */

const char* PerlXlib_xevent_pkg_for_type(int type) {
  switch (type) {
  case 0: return "X11::Xlib::XErrorEvent";
  case ButtonPress: return "X11::Xlib::XButtonEvent";
  case ButtonRelease: return "X11::Xlib::XButtonEvent";
  case CirculateNotify: return "X11::Xlib::XCirculateEvent";
  case CirculateRequest: return "X11::Xlib::XCirculateRequestEvent";
  case ClientMessage: return "X11::Xlib::XClientMessageEvent";
  case ColormapNotify: return "X11::Xlib::XColormapEvent";
  case ConfigureNotify: return "X11::Xlib::XConfigureEvent";
  case ConfigureRequest: return "X11::Xlib::XConfigureRequestEvent";
  case CreateNotify: return "X11::Xlib::XCreateWindowEvent";
  case DestroyNotify: return "X11::Xlib::XDestroyWindowEvent";
  case EnterNotify: return "X11::Xlib::XCrossingEvent";
  case Expose: return "X11::Xlib::XExposeEvent";
  case FocusIn: return "X11::Xlib::XFocusChangeEvent";
  case FocusOut: return "X11::Xlib::XFocusChangeEvent";
  case GenericEvent: return "X11::Xlib::XGenericEvent";
  case GraphicsExpose: return "X11::Xlib::XGraphicsExposeEvent";
  case GravityNotify: return "X11::Xlib::XGravityEvent";
  case KeyPress: return "X11::Xlib::XKeyEvent";
  case KeyRelease: return "X11::Xlib::XKeyEvent";
  case KeymapNotify: return "X11::Xlib::XKeymapEvent";
  case LeaveNotify: return "X11::Xlib::XCrossingEvent";
  case MapNotify: return "X11::Xlib::XMapEvent";
  case MapRequest: return "X11::Xlib::XMapRequestEvent";
  case MappingNotify: return "X11::Xlib::XMappingEvent";
  case MotionNotify: return "X11::Xlib::XMotionEvent";
  case NoExpose: return "X11::Xlib::XNoExposeEvent";
  case PropertyNotify: return "X11::Xlib::XPropertyEvent";
  case ReparentNotify: return "X11::Xlib::XReparentEvent";
  case ResizeRequest: return "X11::Xlib::XResizeRequestEvent";
  case SelectionClear: return "X11::Xlib::XSelectionClearEvent";
  case SelectionNotify: return "X11::Xlib::XSelectionEvent";
  case SelectionRequest: return "X11::Xlib::XSelectionRequestEvent";
  case UnmapNotify: return "X11::Xlib::XUnmapEvent";
  case VisibilityNotify: return "X11::Xlib::XVisibilityEvent";
  default: return "X11::Xlib::XEvent";
  }
}

/* First, pack type, then pack fields for XAnyEvent, then any fields known for that type */
void PerlXlib_XEvent_pack(XEvent *s, HV *fields, Bool consume) {
    SV **fp;
    int newtype;
    const char *oldpkg, *newpkg;

    /* Type gets special handling */
    fp= hv_fetch(fields, "type", 4, 0);
    if (fp && *fp) {
      newtype= SvIV(*fp);
      if (s->type != newtype) {
        oldpkg= PerlXlib_xevent_pkg_for_type(s->type);
        newpkg= PerlXlib_xevent_pkg_for_type(newtype);
        s->type= newtype;
        if (oldpkg != newpkg) {
          /* re-initialize all fields in the area that changed */
          memset( ((char*)(void*)s) + sizeof(XAnyEvent), 0, sizeof(XEvent)-sizeof(XAnyEvent) );
        }
      }
      if (consume) hv_delete(fields, "type", 4, G_DISCARD);
    }
    if (s->type) {
      fp= hv_fetch(fields, "display", 7, 0);
      if (fp && *fp) { s->xany.display= PerlXlib_get_magic_dpy(*fp, 0);; if (consume) hv_delete(fields, "display", 7, G_DISCARD); }
      fp= hv_fetch(fields, "send_event", 10, 0);
      if (fp && *fp) { s->xany.send_event= SvIV(*fp);; if (consume) hv_delete(fields, "send_event", 10, G_DISCARD); }
      fp= hv_fetch(fields, "serial", 6, 0);
      if (fp && *fp) { s->xany.serial= SvUV(*fp);; if (consume) hv_delete(fields, "serial", 6, G_DISCARD); }
      fp= hv_fetch(fields, "type", 4, 0);
      if (fp && *fp) { s->xany.type= SvIV(*fp);; if (consume) hv_delete(fields, "type", 4, G_DISCARD); }
    }
    else {
      fp= hv_fetch(fields, "serial", 6, 0);
      if (fp && *fp) { s->xerror.serial= SvUV(*fp);; if (consume) hv_delete(fields, "serial", 6, G_DISCARD); }
      fp= hv_fetch(fields, "display", 7, 0);
      if (fp && *fp) { s->xerror.display= PerlXlib_get_magic_dpy(*fp, 0);; if (consume) hv_delete(fields, "display", 7, G_DISCARD); }
    }
    switch( s->type ) {
    case ButtonPress:
    case ButtonRelease:
      fp= hv_fetch(fields, "button", 6, 0);
      if (fp && *fp) { s->xbutton.button= SvUV(*fp);; if (consume) hv_delete(fields, "button", 6, G_DISCARD); }
      fp= hv_fetch(fields, "root", 4, 0);
      if (fp && *fp) { s->xbutton.root= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "root", 4, G_DISCARD); }
      fp= hv_fetch(fields, "same_screen", 11, 0);
      if (fp && *fp) { s->xbutton.same_screen= SvIV(*fp);; if (consume) hv_delete(fields, "same_screen", 11, G_DISCARD); }
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xbutton.state= SvUV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "subwindow", 9, 0);
      if (fp && *fp) { s->xbutton.subwindow= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "subwindow", 9, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xbutton.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xbutton.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xbutton.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "x_root", 6, 0);
      if (fp && *fp) { s->xbutton.x_root= SvIV(*fp);; if (consume) hv_delete(fields, "x_root", 6, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xbutton.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y_root", 6, 0);
      if (fp && *fp) { s->xbutton.y_root= SvIV(*fp);; if (consume) hv_delete(fields, "y_root", 6, G_DISCARD); }
      break;
    case CirculateNotify:
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xcirculate.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "place", 5, 0);
      if (fp && *fp) { s->xcirculate.place= SvIV(*fp);; if (consume) hv_delete(fields, "place", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xcirculate.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case CirculateRequest:
      fp= hv_fetch(fields, "parent", 6, 0);
      if (fp && *fp) { s->xcirculaterequest.parent= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "parent", 6, G_DISCARD); }
      fp= hv_fetch(fields, "place", 5, 0);
      if (fp && *fp) { s->xcirculaterequest.place= SvIV(*fp);; if (consume) hv_delete(fields, "place", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xcirculaterequest.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case ClientMessage:
      fp= hv_fetch(fields, "b", 1, 0);
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(char)*20)  croak("Expected scalar of length %d but got %d", sizeof(char)*20, SvCUR(*fp)); memcpy(s->xclient.data.b, SvPVX(*fp), sizeof(char)*20);}; if (consume) hv_delete(fields, "b", 1, G_DISCARD); }
      fp= hv_fetch(fields, "l", 1, 0);
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(long)*5)  croak("Expected scalar of length %d but got %d", sizeof(long)*5, SvCUR(*fp)); memcpy(s->xclient.data.l, SvPVX(*fp), sizeof(long)*5);}; if (consume) hv_delete(fields, "l", 1, G_DISCARD); }
      fp= hv_fetch(fields, "s", 1, 0);
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(short)*10)  croak("Expected scalar of length %d but got %d", sizeof(short)*10, SvCUR(*fp)); memcpy(s->xclient.data.s, SvPVX(*fp), sizeof(short)*10);}; if (consume) hv_delete(fields, "s", 1, G_DISCARD); }
      fp= hv_fetch(fields, "format", 6, 0);
      if (fp && *fp) { s->xclient.format= SvIV(*fp);; if (consume) hv_delete(fields, "format", 6, G_DISCARD); }
      fp= hv_fetch(fields, "message_type", 12, 0);
      if (fp && *fp) { s->xclient.message_type= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "message_type", 12, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xclient.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case ColormapNotify:
      fp= hv_fetch(fields, "colormap", 8, 0);
      if (fp && *fp) { s->xcolormap.colormap= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "colormap", 8, G_DISCARD); }
      fp= hv_fetch(fields, "new", 3, 0);
      if (fp && *fp) { s->xcolormap.new= SvIV(*fp);; if (consume) hv_delete(fields, "new", 3, G_DISCARD); }
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xcolormap.state= SvIV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xcolormap.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case ConfigureNotify:
      fp= hv_fetch(fields, "above", 5, 0);
      if (fp && *fp) { s->xconfigure.above= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "above", 5, G_DISCARD); }
      fp= hv_fetch(fields, "border_width", 12, 0);
      if (fp && *fp) { s->xconfigure.border_width= SvIV(*fp);; if (consume) hv_delete(fields, "border_width", 12, G_DISCARD); }
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xconfigure.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "height", 6, 0);
      if (fp && *fp) { s->xconfigure.height= SvIV(*fp);; if (consume) hv_delete(fields, "height", 6, G_DISCARD); }
      fp= hv_fetch(fields, "override_redirect", 17, 0);
      if (fp && *fp) { s->xconfigure.override_redirect= SvIV(*fp);; if (consume) hv_delete(fields, "override_redirect", 17, G_DISCARD); }
      fp= hv_fetch(fields, "width", 5, 0);
      if (fp && *fp) { s->xconfigure.width= SvIV(*fp);; if (consume) hv_delete(fields, "width", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xconfigure.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xconfigure.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xconfigure.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case ConfigureRequest:
      fp= hv_fetch(fields, "above", 5, 0);
      if (fp && *fp) { s->xconfigurerequest.above= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "above", 5, G_DISCARD); }
      fp= hv_fetch(fields, "border_width", 12, 0);
      if (fp && *fp) { s->xconfigurerequest.border_width= SvIV(*fp);; if (consume) hv_delete(fields, "border_width", 12, G_DISCARD); }
      fp= hv_fetch(fields, "detail", 6, 0);
      if (fp && *fp) { s->xconfigurerequest.detail= SvIV(*fp);; if (consume) hv_delete(fields, "detail", 6, G_DISCARD); }
      fp= hv_fetch(fields, "height", 6, 0);
      if (fp && *fp) { s->xconfigurerequest.height= SvIV(*fp);; if (consume) hv_delete(fields, "height", 6, G_DISCARD); }
      fp= hv_fetch(fields, "parent", 6, 0);
      if (fp && *fp) { s->xconfigurerequest.parent= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "parent", 6, G_DISCARD); }
      fp= hv_fetch(fields, "value_mask", 10, 0);
      if (fp && *fp) { s->xconfigurerequest.value_mask= SvUV(*fp);; if (consume) hv_delete(fields, "value_mask", 10, G_DISCARD); }
      fp= hv_fetch(fields, "width", 5, 0);
      if (fp && *fp) { s->xconfigurerequest.width= SvIV(*fp);; if (consume) hv_delete(fields, "width", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xconfigurerequest.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xconfigurerequest.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xconfigurerequest.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case CreateNotify:
      fp= hv_fetch(fields, "border_width", 12, 0);
      if (fp && *fp) { s->xcreatewindow.border_width= SvIV(*fp);; if (consume) hv_delete(fields, "border_width", 12, G_DISCARD); }
      fp= hv_fetch(fields, "height", 6, 0);
      if (fp && *fp) { s->xcreatewindow.height= SvIV(*fp);; if (consume) hv_delete(fields, "height", 6, G_DISCARD); }
      fp= hv_fetch(fields, "override_redirect", 17, 0);
      if (fp && *fp) { s->xcreatewindow.override_redirect= SvIV(*fp);; if (consume) hv_delete(fields, "override_redirect", 17, G_DISCARD); }
      fp= hv_fetch(fields, "parent", 6, 0);
      if (fp && *fp) { s->xcreatewindow.parent= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "parent", 6, G_DISCARD); }
      fp= hv_fetch(fields, "width", 5, 0);
      if (fp && *fp) { s->xcreatewindow.width= SvIV(*fp);; if (consume) hv_delete(fields, "width", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xcreatewindow.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xcreatewindow.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xcreatewindow.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case EnterNotify:
    case LeaveNotify:
      fp= hv_fetch(fields, "detail", 6, 0);
      if (fp && *fp) { s->xcrossing.detail= SvIV(*fp);; if (consume) hv_delete(fields, "detail", 6, G_DISCARD); }
      fp= hv_fetch(fields, "focus", 5, 0);
      if (fp && *fp) { s->xcrossing.focus= SvIV(*fp);; if (consume) hv_delete(fields, "focus", 5, G_DISCARD); }
      fp= hv_fetch(fields, "mode", 4, 0);
      if (fp && *fp) { s->xcrossing.mode= SvIV(*fp);; if (consume) hv_delete(fields, "mode", 4, G_DISCARD); }
      fp= hv_fetch(fields, "root", 4, 0);
      if (fp && *fp) { s->xcrossing.root= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "root", 4, G_DISCARD); }
      fp= hv_fetch(fields, "same_screen", 11, 0);
      if (fp && *fp) { s->xcrossing.same_screen= SvIV(*fp);; if (consume) hv_delete(fields, "same_screen", 11, G_DISCARD); }
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xcrossing.state= SvUV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "subwindow", 9, 0);
      if (fp && *fp) { s->xcrossing.subwindow= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "subwindow", 9, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xcrossing.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xcrossing.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xcrossing.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "x_root", 6, 0);
      if (fp && *fp) { s->xcrossing.x_root= SvIV(*fp);; if (consume) hv_delete(fields, "x_root", 6, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xcrossing.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y_root", 6, 0);
      if (fp && *fp) { s->xcrossing.y_root= SvIV(*fp);; if (consume) hv_delete(fields, "y_root", 6, G_DISCARD); }
      break;
    case DestroyNotify:
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xdestroywindow.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xdestroywindow.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case 0:
      fp= hv_fetch(fields, "error_code", 10, 0);
      if (fp && *fp) { s->xerror.error_code= SvUV(*fp);; if (consume) hv_delete(fields, "error_code", 10, G_DISCARD); }
      fp= hv_fetch(fields, "minor_code", 10, 0);
      if (fp && *fp) { s->xerror.minor_code= SvUV(*fp);; if (consume) hv_delete(fields, "minor_code", 10, G_DISCARD); }
      fp= hv_fetch(fields, "request_code", 12, 0);
      if (fp && *fp) { s->xerror.request_code= SvUV(*fp);; if (consume) hv_delete(fields, "request_code", 12, G_DISCARD); }
      fp= hv_fetch(fields, "resourceid", 10, 0);
      if (fp && *fp) { s->xerror.resourceid= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "resourceid", 10, G_DISCARD); }
      break;
    case Expose:
      fp= hv_fetch(fields, "count", 5, 0);
      if (fp && *fp) { s->xexpose.count= SvIV(*fp);; if (consume) hv_delete(fields, "count", 5, G_DISCARD); }
      fp= hv_fetch(fields, "height", 6, 0);
      if (fp && *fp) { s->xexpose.height= SvIV(*fp);; if (consume) hv_delete(fields, "height", 6, G_DISCARD); }
      fp= hv_fetch(fields, "width", 5, 0);
      if (fp && *fp) { s->xexpose.width= SvIV(*fp);; if (consume) hv_delete(fields, "width", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xexpose.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xexpose.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xexpose.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case FocusIn:
    case FocusOut:
      fp= hv_fetch(fields, "detail", 6, 0);
      if (fp && *fp) { s->xfocus.detail= SvIV(*fp);; if (consume) hv_delete(fields, "detail", 6, G_DISCARD); }
      fp= hv_fetch(fields, "mode", 4, 0);
      if (fp && *fp) { s->xfocus.mode= SvIV(*fp);; if (consume) hv_delete(fields, "mode", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xfocus.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case GenericEvent:
      fp= hv_fetch(fields, "evtype", 6, 0);
      if (fp && *fp) { s->xgeneric.evtype= SvIV(*fp);; if (consume) hv_delete(fields, "evtype", 6, G_DISCARD); }
      fp= hv_fetch(fields, "extension", 9, 0);
      if (fp && *fp) { s->xgeneric.extension= SvIV(*fp);; if (consume) hv_delete(fields, "extension", 9, G_DISCARD); }
      break;
    case GraphicsExpose:
      fp= hv_fetch(fields, "count", 5, 0);
      if (fp && *fp) { s->xgraphicsexpose.count= SvIV(*fp);; if (consume) hv_delete(fields, "count", 5, G_DISCARD); }
      fp= hv_fetch(fields, "drawable", 8, 0);
      if (fp && *fp) { s->xgraphicsexpose.drawable= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "drawable", 8, G_DISCARD); }
      fp= hv_fetch(fields, "height", 6, 0);
      if (fp && *fp) { s->xgraphicsexpose.height= SvIV(*fp);; if (consume) hv_delete(fields, "height", 6, G_DISCARD); }
      fp= hv_fetch(fields, "major_code", 10, 0);
      if (fp && *fp) { s->xgraphicsexpose.major_code= SvIV(*fp);; if (consume) hv_delete(fields, "major_code", 10, G_DISCARD); }
      fp= hv_fetch(fields, "minor_code", 10, 0);
      if (fp && *fp) { s->xgraphicsexpose.minor_code= SvIV(*fp);; if (consume) hv_delete(fields, "minor_code", 10, G_DISCARD); }
      fp= hv_fetch(fields, "width", 5, 0);
      if (fp && *fp) { s->xgraphicsexpose.width= SvIV(*fp);; if (consume) hv_delete(fields, "width", 5, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xgraphicsexpose.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xgraphicsexpose.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case GravityNotify:
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xgravity.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xgravity.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xgravity.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xgravity.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case KeyPress:
    case KeyRelease:
      fp= hv_fetch(fields, "keycode", 7, 0);
      if (fp && *fp) { s->xkey.keycode= SvUV(*fp);; if (consume) hv_delete(fields, "keycode", 7, G_DISCARD); }
      fp= hv_fetch(fields, "root", 4, 0);
      if (fp && *fp) { s->xkey.root= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "root", 4, G_DISCARD); }
      fp= hv_fetch(fields, "same_screen", 11, 0);
      if (fp && *fp) { s->xkey.same_screen= SvIV(*fp);; if (consume) hv_delete(fields, "same_screen", 11, G_DISCARD); }
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xkey.state= SvUV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "subwindow", 9, 0);
      if (fp && *fp) { s->xkey.subwindow= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "subwindow", 9, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xkey.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xkey.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xkey.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "x_root", 6, 0);
      if (fp && *fp) { s->xkey.x_root= SvIV(*fp);; if (consume) hv_delete(fields, "x_root", 6, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xkey.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y_root", 6, 0);
      if (fp && *fp) { s->xkey.y_root= SvIV(*fp);; if (consume) hv_delete(fields, "y_root", 6, G_DISCARD); }
      break;
    case KeymapNotify:
      fp= hv_fetch(fields, "key_vector", 10, 0);
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(char)*32)  croak("Expected scalar of length %d but got %d", sizeof(char)*32, SvCUR(*fp)); memcpy(s->xkeymap.key_vector, SvPVX(*fp), sizeof(char)*32);}; if (consume) hv_delete(fields, "key_vector", 10, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xkeymap.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case MapNotify:
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xmap.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "override_redirect", 17, 0);
      if (fp && *fp) { s->xmap.override_redirect= SvIV(*fp);; if (consume) hv_delete(fields, "override_redirect", 17, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xmap.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case MappingNotify:
      fp= hv_fetch(fields, "count", 5, 0);
      if (fp && *fp) { s->xmapping.count= SvIV(*fp);; if (consume) hv_delete(fields, "count", 5, G_DISCARD); }
      fp= hv_fetch(fields, "first_keycode", 13, 0);
      if (fp && *fp) { s->xmapping.first_keycode= SvIV(*fp);; if (consume) hv_delete(fields, "first_keycode", 13, G_DISCARD); }
      fp= hv_fetch(fields, "request", 7, 0);
      if (fp && *fp) { s->xmapping.request= SvIV(*fp);; if (consume) hv_delete(fields, "request", 7, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xmapping.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case MapRequest:
      fp= hv_fetch(fields, "parent", 6, 0);
      if (fp && *fp) { s->xmaprequest.parent= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "parent", 6, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xmaprequest.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case MotionNotify:
      fp= hv_fetch(fields, "is_hint", 7, 0);
      if (fp && *fp) { s->xmotion.is_hint= SvIV(*fp);; if (consume) hv_delete(fields, "is_hint", 7, G_DISCARD); }
      fp= hv_fetch(fields, "root", 4, 0);
      if (fp && *fp) { s->xmotion.root= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "root", 4, G_DISCARD); }
      fp= hv_fetch(fields, "same_screen", 11, 0);
      if (fp && *fp) { s->xmotion.same_screen= SvIV(*fp);; if (consume) hv_delete(fields, "same_screen", 11, G_DISCARD); }
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xmotion.state= SvUV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "subwindow", 9, 0);
      if (fp && *fp) { s->xmotion.subwindow= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "subwindow", 9, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xmotion.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xmotion.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xmotion.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "x_root", 6, 0);
      if (fp && *fp) { s->xmotion.x_root= SvIV(*fp);; if (consume) hv_delete(fields, "x_root", 6, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xmotion.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y_root", 6, 0);
      if (fp && *fp) { s->xmotion.y_root= SvIV(*fp);; if (consume) hv_delete(fields, "y_root", 6, G_DISCARD); }
      break;
    case NoExpose:
      fp= hv_fetch(fields, "drawable", 8, 0);
      if (fp && *fp) { s->xnoexpose.drawable= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "drawable", 8, G_DISCARD); }
      fp= hv_fetch(fields, "major_code", 10, 0);
      if (fp && *fp) { s->xnoexpose.major_code= SvIV(*fp);; if (consume) hv_delete(fields, "major_code", 10, G_DISCARD); }
      fp= hv_fetch(fields, "minor_code", 10, 0);
      if (fp && *fp) { s->xnoexpose.minor_code= SvIV(*fp);; if (consume) hv_delete(fields, "minor_code", 10, G_DISCARD); }
      break;
    case PropertyNotify:
      fp= hv_fetch(fields, "atom", 4, 0);
      if (fp && *fp) { s->xproperty.atom= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "atom", 4, G_DISCARD); }
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xproperty.state= SvIV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xproperty.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xproperty.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case ReparentNotify:
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xreparent.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "override_redirect", 17, 0);
      if (fp && *fp) { s->xreparent.override_redirect= SvIV(*fp);; if (consume) hv_delete(fields, "override_redirect", 17, G_DISCARD); }
      fp= hv_fetch(fields, "parent", 6, 0);
      if (fp && *fp) { s->xreparent.parent= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "parent", 6, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xreparent.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      fp= hv_fetch(fields, "x", 1, 0);
      if (fp && *fp) { s->xreparent.x= SvIV(*fp);; if (consume) hv_delete(fields, "x", 1, G_DISCARD); }
      fp= hv_fetch(fields, "y", 1, 0);
      if (fp && *fp) { s->xreparent.y= SvIV(*fp);; if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
      break;
    case ResizeRequest:
      fp= hv_fetch(fields, "height", 6, 0);
      if (fp && *fp) { s->xresizerequest.height= SvIV(*fp);; if (consume) hv_delete(fields, "height", 6, G_DISCARD); }
      fp= hv_fetch(fields, "width", 5, 0);
      if (fp && *fp) { s->xresizerequest.width= SvIV(*fp);; if (consume) hv_delete(fields, "width", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xresizerequest.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case SelectionNotify:
      fp= hv_fetch(fields, "property", 8, 0);
      if (fp && *fp) { s->xselection.property= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "property", 8, G_DISCARD); }
      fp= hv_fetch(fields, "requestor", 9, 0);
      if (fp && *fp) { s->xselection.requestor= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "requestor", 9, G_DISCARD); }
      fp= hv_fetch(fields, "selection", 9, 0);
      if (fp && *fp) { s->xselection.selection= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "selection", 9, G_DISCARD); }
      fp= hv_fetch(fields, "target", 6, 0);
      if (fp && *fp) { s->xselection.target= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "target", 6, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xselection.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      break;
    case SelectionClear:
      fp= hv_fetch(fields, "selection", 9, 0);
      if (fp && *fp) { s->xselectionclear.selection= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "selection", 9, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xselectionclear.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xselectionclear.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case SelectionRequest:
      fp= hv_fetch(fields, "owner", 5, 0);
      if (fp && *fp) { s->xselectionrequest.owner= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "owner", 5, G_DISCARD); }
      fp= hv_fetch(fields, "property", 8, 0);
      if (fp && *fp) { s->xselectionrequest.property= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "property", 8, G_DISCARD); }
      fp= hv_fetch(fields, "requestor", 9, 0);
      if (fp && *fp) { s->xselectionrequest.requestor= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "requestor", 9, G_DISCARD); }
      fp= hv_fetch(fields, "selection", 9, 0);
      if (fp && *fp) { s->xselectionrequest.selection= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "selection", 9, G_DISCARD); }
      fp= hv_fetch(fields, "target", 6, 0);
      if (fp && *fp) { s->xselectionrequest.target= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "target", 6, G_DISCARD); }
      fp= hv_fetch(fields, "time", 4, 0);
      if (fp && *fp) { s->xselectionrequest.time= SvUV(*fp);; if (consume) hv_delete(fields, "time", 4, G_DISCARD); }
      break;
    case UnmapNotify:
      fp= hv_fetch(fields, "event", 5, 0);
      if (fp && *fp) { s->xunmap.event= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "event", 5, G_DISCARD); }
      fp= hv_fetch(fields, "from_configure", 14, 0);
      if (fp && *fp) { s->xunmap.from_configure= SvIV(*fp);; if (consume) hv_delete(fields, "from_configure", 14, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xunmap.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    case VisibilityNotify:
      fp= hv_fetch(fields, "state", 5, 0);
      if (fp && *fp) { s->xvisibility.state= SvIV(*fp);; if (consume) hv_delete(fields, "state", 5, G_DISCARD); }
      fp= hv_fetch(fields, "window", 6, 0);
      if (fp && *fp) { s->xvisibility.window= PerlXlib_sv_to_xid(*fp);; if (consume) hv_delete(fields, "window", 6, G_DISCARD); }
      break;
    default:
      warn("Unknown XEvent type %d", s->type);
    }
}

void PerlXlib_XEvent_unpack(XEvent *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value!
     */
    SV *sv= NULL;
    if (!hv_store(fields, "type", 4, (sv= newSViv(s->type)), 0)) goto store_fail;
    if (s->type) {
      if (!hv_store(fields, "display"   ,  7, (sv=newSVsv(s->xany.display? PerlXlib_obj_for_display(s->xany.display, 0) : &PL_sv_undef)), 0)) goto store_fail;
      if (!hv_store(fields, "send_event", 10, (sv=newSViv(s->xany.send_event)), 0)) goto store_fail;
      if (!hv_store(fields, "serial"    ,  6, (sv=newSVuv(s->xany.serial)), 0)) goto store_fail;
      if (!hv_store(fields, "type"      ,  4, (sv=newSViv(s->xany.type)), 0)) goto store_fail;
    }
    else {
      if (!hv_store(fields, "display"   ,  7, (sv=newSVsv(s->xerror.display? PerlXlib_obj_for_display(s->xerror.display, 0) : &PL_sv_undef)), 0)) goto store_fail;
      if (!hv_store(fields, "serial"    ,  6, (sv=newSVuv(s->xerror.serial)), 0)) goto store_fail;
    }
    switch( s->type ) {
    case ButtonPress:
    case ButtonRelease:
      if (!hv_store(fields, "button"     ,  6, (sv=newSVuv(s->xbutton.button)), 0)) goto store_fail;
      if (!hv_store(fields, "root"       ,  4, (sv=newSVuv(s->xbutton.root)), 0)) goto store_fail;
      if (!hv_store(fields, "same_screen", 11, (sv=newSViv(s->xbutton.same_screen)), 0)) goto store_fail;
      if (!hv_store(fields, "state"      ,  5, (sv=newSVuv(s->xbutton.state)), 0)) goto store_fail;
      if (!hv_store(fields, "subwindow"  ,  9, (sv=newSVuv(s->xbutton.subwindow)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xbutton.time)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xbutton.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xbutton.x)), 0)) goto store_fail;
      if (!hv_store(fields, "x_root"     ,  6, (sv=newSViv(s->xbutton.x_root)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xbutton.y)), 0)) goto store_fail;
      if (!hv_store(fields, "y_root"     ,  6, (sv=newSViv(s->xbutton.y_root)), 0)) goto store_fail;
      break;
    case CirculateNotify:
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xcirculate.event)), 0)) goto store_fail;
      if (!hv_store(fields, "place"      ,  5, (sv=newSViv(s->xcirculate.place)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xcirculate.window)), 0)) goto store_fail;
      break;
    case CirculateRequest:
      if (!hv_store(fields, "parent"     ,  6, (sv=newSVuv(s->xcirculaterequest.parent)), 0)) goto store_fail;
      if (!hv_store(fields, "place"      ,  5, (sv=newSViv(s->xcirculaterequest.place)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xcirculaterequest.window)), 0)) goto store_fail;
      break;
    case ClientMessage:
      if (!hv_store(fields, "b"          ,  1, (sv=newSVpvn((void*)s->xclient.data.b, sizeof(char)*20)), 0)) goto store_fail;
      if (!hv_store(fields, "l"          ,  1, (sv=newSVpvn((void*)s->xclient.data.l, sizeof(long)*5)), 0)) goto store_fail;
      if (!hv_store(fields, "s"          ,  1, (sv=newSVpvn((void*)s->xclient.data.s, sizeof(short)*10)), 0)) goto store_fail;
      if (!hv_store(fields, "format"     ,  6, (sv=newSViv(s->xclient.format)), 0)) goto store_fail;
      if (!hv_store(fields, "message_type", 12, (sv=newSVuv(s->xclient.message_type)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xclient.window)), 0)) goto store_fail;
      break;
    case ColormapNotify:
      if (!hv_store(fields, "colormap"   ,  8, (sv=newSVuv(s->xcolormap.colormap)), 0)) goto store_fail;
      if (!hv_store(fields, "new"        ,  3, (sv=newSViv(s->xcolormap.new)), 0)) goto store_fail;
      if (!hv_store(fields, "state"      ,  5, (sv=newSViv(s->xcolormap.state)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xcolormap.window)), 0)) goto store_fail;
      break;
    case ConfigureNotify:
      if (!hv_store(fields, "above"      ,  5, (sv=newSVuv(s->xconfigure.above)), 0)) goto store_fail;
      if (!hv_store(fields, "border_width", 12, (sv=newSViv(s->xconfigure.border_width)), 0)) goto store_fail;
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xconfigure.event)), 0)) goto store_fail;
      if (!hv_store(fields, "height"     ,  6, (sv=newSViv(s->xconfigure.height)), 0)) goto store_fail;
      if (!hv_store(fields, "override_redirect", 17, (sv=newSViv(s->xconfigure.override_redirect)), 0)) goto store_fail;
      if (!hv_store(fields, "width"      ,  5, (sv=newSViv(s->xconfigure.width)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xconfigure.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xconfigure.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xconfigure.y)), 0)) goto store_fail;
      break;
    case ConfigureRequest:
      if (!hv_store(fields, "above"      ,  5, (sv=newSVuv(s->xconfigurerequest.above)), 0)) goto store_fail;
      if (!hv_store(fields, "border_width", 12, (sv=newSViv(s->xconfigurerequest.border_width)), 0)) goto store_fail;
      if (!hv_store(fields, "detail"     ,  6, (sv=newSViv(s->xconfigurerequest.detail)), 0)) goto store_fail;
      if (!hv_store(fields, "height"     ,  6, (sv=newSViv(s->xconfigurerequest.height)), 0)) goto store_fail;
      if (!hv_store(fields, "parent"     ,  6, (sv=newSVuv(s->xconfigurerequest.parent)), 0)) goto store_fail;
      if (!hv_store(fields, "value_mask" , 10, (sv=newSVuv(s->xconfigurerequest.value_mask)), 0)) goto store_fail;
      if (!hv_store(fields, "width"      ,  5, (sv=newSViv(s->xconfigurerequest.width)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xconfigurerequest.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xconfigurerequest.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xconfigurerequest.y)), 0)) goto store_fail;
      break;
    case CreateNotify:
      if (!hv_store(fields, "border_width", 12, (sv=newSViv(s->xcreatewindow.border_width)), 0)) goto store_fail;
      if (!hv_store(fields, "height"     ,  6, (sv=newSViv(s->xcreatewindow.height)), 0)) goto store_fail;
      if (!hv_store(fields, "override_redirect", 17, (sv=newSViv(s->xcreatewindow.override_redirect)), 0)) goto store_fail;
      if (!hv_store(fields, "parent"     ,  6, (sv=newSVuv(s->xcreatewindow.parent)), 0)) goto store_fail;
      if (!hv_store(fields, "width"      ,  5, (sv=newSViv(s->xcreatewindow.width)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xcreatewindow.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xcreatewindow.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xcreatewindow.y)), 0)) goto store_fail;
      break;
    case EnterNotify:
    case LeaveNotify:
      if (!hv_store(fields, "detail"     ,  6, (sv=newSViv(s->xcrossing.detail)), 0)) goto store_fail;
      if (!hv_store(fields, "focus"      ,  5, (sv=newSViv(s->xcrossing.focus)), 0)) goto store_fail;
      if (!hv_store(fields, "mode"       ,  4, (sv=newSViv(s->xcrossing.mode)), 0)) goto store_fail;
      if (!hv_store(fields, "root"       ,  4, (sv=newSVuv(s->xcrossing.root)), 0)) goto store_fail;
      if (!hv_store(fields, "same_screen", 11, (sv=newSViv(s->xcrossing.same_screen)), 0)) goto store_fail;
      if (!hv_store(fields, "state"      ,  5, (sv=newSVuv(s->xcrossing.state)), 0)) goto store_fail;
      if (!hv_store(fields, "subwindow"  ,  9, (sv=newSVuv(s->xcrossing.subwindow)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xcrossing.time)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xcrossing.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xcrossing.x)), 0)) goto store_fail;
      if (!hv_store(fields, "x_root"     ,  6, (sv=newSViv(s->xcrossing.x_root)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xcrossing.y)), 0)) goto store_fail;
      if (!hv_store(fields, "y_root"     ,  6, (sv=newSViv(s->xcrossing.y_root)), 0)) goto store_fail;
      break;
    case DestroyNotify:
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xdestroywindow.event)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xdestroywindow.window)), 0)) goto store_fail;
      break;
    case 0:
      if (!hv_store(fields, "error_code" , 10, (sv=newSVuv(s->xerror.error_code)), 0)) goto store_fail;
      if (!hv_store(fields, "minor_code" , 10, (sv=newSVuv(s->xerror.minor_code)), 0)) goto store_fail;
      if (!hv_store(fields, "request_code", 12, (sv=newSVuv(s->xerror.request_code)), 0)) goto store_fail;
      if (!hv_store(fields, "resourceid" , 10, (sv=newSVuv(s->xerror.resourceid)), 0)) goto store_fail;
      break;
    case Expose:
      if (!hv_store(fields, "count"      ,  5, (sv=newSViv(s->xexpose.count)), 0)) goto store_fail;
      if (!hv_store(fields, "height"     ,  6, (sv=newSViv(s->xexpose.height)), 0)) goto store_fail;
      if (!hv_store(fields, "width"      ,  5, (sv=newSViv(s->xexpose.width)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xexpose.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xexpose.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xexpose.y)), 0)) goto store_fail;
      break;
    case FocusIn:
    case FocusOut:
      if (!hv_store(fields, "detail"     ,  6, (sv=newSViv(s->xfocus.detail)), 0)) goto store_fail;
      if (!hv_store(fields, "mode"       ,  4, (sv=newSViv(s->xfocus.mode)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xfocus.window)), 0)) goto store_fail;
      break;
    case GenericEvent:
      if (!hv_store(fields, "evtype"     ,  6, (sv=newSViv(s->xgeneric.evtype)), 0)) goto store_fail;
      if (!hv_store(fields, "extension"  ,  9, (sv=newSViv(s->xgeneric.extension)), 0)) goto store_fail;
      break;
    case GraphicsExpose:
      if (!hv_store(fields, "count"      ,  5, (sv=newSViv(s->xgraphicsexpose.count)), 0)) goto store_fail;
      if (!hv_store(fields, "drawable"   ,  8, (sv=newSVuv(s->xgraphicsexpose.drawable)), 0)) goto store_fail;
      if (!hv_store(fields, "height"     ,  6, (sv=newSViv(s->xgraphicsexpose.height)), 0)) goto store_fail;
      if (!hv_store(fields, "major_code" , 10, (sv=newSViv(s->xgraphicsexpose.major_code)), 0)) goto store_fail;
      if (!hv_store(fields, "minor_code" , 10, (sv=newSViv(s->xgraphicsexpose.minor_code)), 0)) goto store_fail;
      if (!hv_store(fields, "width"      ,  5, (sv=newSViv(s->xgraphicsexpose.width)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xgraphicsexpose.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xgraphicsexpose.y)), 0)) goto store_fail;
      break;
    case GravityNotify:
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xgravity.event)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xgravity.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xgravity.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xgravity.y)), 0)) goto store_fail;
      break;
    case KeyPress:
    case KeyRelease:
      if (!hv_store(fields, "keycode"    ,  7, (sv=newSVuv(s->xkey.keycode)), 0)) goto store_fail;
      if (!hv_store(fields, "root"       ,  4, (sv=newSVuv(s->xkey.root)), 0)) goto store_fail;
      if (!hv_store(fields, "same_screen", 11, (sv=newSViv(s->xkey.same_screen)), 0)) goto store_fail;
      if (!hv_store(fields, "state"      ,  5, (sv=newSVuv(s->xkey.state)), 0)) goto store_fail;
      if (!hv_store(fields, "subwindow"  ,  9, (sv=newSVuv(s->xkey.subwindow)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xkey.time)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xkey.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xkey.x)), 0)) goto store_fail;
      if (!hv_store(fields, "x_root"     ,  6, (sv=newSViv(s->xkey.x_root)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xkey.y)), 0)) goto store_fail;
      if (!hv_store(fields, "y_root"     ,  6, (sv=newSViv(s->xkey.y_root)), 0)) goto store_fail;
      break;
    case KeymapNotify:
      if (!hv_store(fields, "key_vector" , 10, (sv=newSVpvn((void*)s->xkeymap.key_vector, sizeof(char)*32)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xkeymap.window)), 0)) goto store_fail;
      break;
    case MapNotify:
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xmap.event)), 0)) goto store_fail;
      if (!hv_store(fields, "override_redirect", 17, (sv=newSViv(s->xmap.override_redirect)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xmap.window)), 0)) goto store_fail;
      break;
    case MappingNotify:
      if (!hv_store(fields, "count"      ,  5, (sv=newSViv(s->xmapping.count)), 0)) goto store_fail;
      if (!hv_store(fields, "first_keycode", 13, (sv=newSViv(s->xmapping.first_keycode)), 0)) goto store_fail;
      if (!hv_store(fields, "request"    ,  7, (sv=newSViv(s->xmapping.request)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xmapping.window)), 0)) goto store_fail;
      break;
    case MapRequest:
      if (!hv_store(fields, "parent"     ,  6, (sv=newSVuv(s->xmaprequest.parent)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xmaprequest.window)), 0)) goto store_fail;
      break;
    case MotionNotify:
      if (!hv_store(fields, "is_hint"    ,  7, (sv=newSViv(s->xmotion.is_hint)), 0)) goto store_fail;
      if (!hv_store(fields, "root"       ,  4, (sv=newSVuv(s->xmotion.root)), 0)) goto store_fail;
      if (!hv_store(fields, "same_screen", 11, (sv=newSViv(s->xmotion.same_screen)), 0)) goto store_fail;
      if (!hv_store(fields, "state"      ,  5, (sv=newSVuv(s->xmotion.state)), 0)) goto store_fail;
      if (!hv_store(fields, "subwindow"  ,  9, (sv=newSVuv(s->xmotion.subwindow)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xmotion.time)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xmotion.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xmotion.x)), 0)) goto store_fail;
      if (!hv_store(fields, "x_root"     ,  6, (sv=newSViv(s->xmotion.x_root)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xmotion.y)), 0)) goto store_fail;
      if (!hv_store(fields, "y_root"     ,  6, (sv=newSViv(s->xmotion.y_root)), 0)) goto store_fail;
      break;
    case NoExpose:
      if (!hv_store(fields, "drawable"   ,  8, (sv=newSVuv(s->xnoexpose.drawable)), 0)) goto store_fail;
      if (!hv_store(fields, "major_code" , 10, (sv=newSViv(s->xnoexpose.major_code)), 0)) goto store_fail;
      if (!hv_store(fields, "minor_code" , 10, (sv=newSViv(s->xnoexpose.minor_code)), 0)) goto store_fail;
      break;
    case PropertyNotify:
      if (!hv_store(fields, "atom"       ,  4, (sv=newSVuv(s->xproperty.atom)), 0)) goto store_fail;
      if (!hv_store(fields, "state"      ,  5, (sv=newSViv(s->xproperty.state)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xproperty.time)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xproperty.window)), 0)) goto store_fail;
      break;
    case ReparentNotify:
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xreparent.event)), 0)) goto store_fail;
      if (!hv_store(fields, "override_redirect", 17, (sv=newSViv(s->xreparent.override_redirect)), 0)) goto store_fail;
      if (!hv_store(fields, "parent"     ,  6, (sv=newSVuv(s->xreparent.parent)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xreparent.window)), 0)) goto store_fail;
      if (!hv_store(fields, "x"          ,  1, (sv=newSViv(s->xreparent.x)), 0)) goto store_fail;
      if (!hv_store(fields, "y"          ,  1, (sv=newSViv(s->xreparent.y)), 0)) goto store_fail;
      break;
    case ResizeRequest:
      if (!hv_store(fields, "height"     ,  6, (sv=newSViv(s->xresizerequest.height)), 0)) goto store_fail;
      if (!hv_store(fields, "width"      ,  5, (sv=newSViv(s->xresizerequest.width)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xresizerequest.window)), 0)) goto store_fail;
      break;
    case SelectionNotify:
      if (!hv_store(fields, "property"   ,  8, (sv=newSVuv(s->xselection.property)), 0)) goto store_fail;
      if (!hv_store(fields, "requestor"  ,  9, (sv=newSVuv(s->xselection.requestor)), 0)) goto store_fail;
      if (!hv_store(fields, "selection"  ,  9, (sv=newSVuv(s->xselection.selection)), 0)) goto store_fail;
      if (!hv_store(fields, "target"     ,  6, (sv=newSVuv(s->xselection.target)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xselection.time)), 0)) goto store_fail;
      break;
    case SelectionClear:
      if (!hv_store(fields, "selection"  ,  9, (sv=newSVuv(s->xselectionclear.selection)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xselectionclear.time)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xselectionclear.window)), 0)) goto store_fail;
      break;
    case SelectionRequest:
      if (!hv_store(fields, "owner"      ,  5, (sv=newSVuv(s->xselectionrequest.owner)), 0)) goto store_fail;
      if (!hv_store(fields, "property"   ,  8, (sv=newSVuv(s->xselectionrequest.property)), 0)) goto store_fail;
      if (!hv_store(fields, "requestor"  ,  9, (sv=newSVuv(s->xselectionrequest.requestor)), 0)) goto store_fail;
      if (!hv_store(fields, "selection"  ,  9, (sv=newSVuv(s->xselectionrequest.selection)), 0)) goto store_fail;
      if (!hv_store(fields, "target"     ,  6, (sv=newSVuv(s->xselectionrequest.target)), 0)) goto store_fail;
      if (!hv_store(fields, "time"       ,  4, (sv=newSVuv(s->xselectionrequest.time)), 0)) goto store_fail;
      break;
    case UnmapNotify:
      if (!hv_store(fields, "event"      ,  5, (sv=newSVuv(s->xunmap.event)), 0)) goto store_fail;
      if (!hv_store(fields, "from_configure", 14, (sv=newSViv(s->xunmap.from_configure)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xunmap.window)), 0)) goto store_fail;
      break;
    case VisibilityNotify:
      if (!hv_store(fields, "state"      ,  5, (sv=newSViv(s->xvisibility.state)), 0)) goto store_fail;
      if (!hv_store(fields, "window"     ,  6, (sv=newSVuv(s->xvisibility.window)), 0)) goto store_fail;
      break;
    default:
      warn("Unknown XEvent type %d", s->type);
    }
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XEvent */
/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XVisualInfo */

void PerlXlib_XVisualInfo_pack(XVisualInfo *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "bits_per_rgb", 12, 0);
    if (fp && *fp) { s->bits_per_rgb= SvIV(*fp); if (consume) hv_delete(fields, "bits_per_rgb", 12, G_DISCARD); }

    fp= hv_fetch(fields, "blue_mask", 9, 0);
    if (fp && *fp) { s->blue_mask= SvUV(*fp); if (consume) hv_delete(fields, "blue_mask", 9, G_DISCARD); }

    fp= hv_fetch(fields, "class", 5, 0);
    if (fp && *fp) { s->class= SvIV(*fp); if (consume) hv_delete(fields, "class", 5, G_DISCARD); }

    fp= hv_fetch(fields, "colormap_size", 13, 0);
    if (fp && *fp) { s->colormap_size= SvIV(*fp); if (consume) hv_delete(fields, "colormap_size", 13, G_DISCARD); }

    fp= hv_fetch(fields, "depth", 5, 0);
    if (fp && *fp) { s->depth= SvIV(*fp); if (consume) hv_delete(fields, "depth", 5, G_DISCARD); }

    fp= hv_fetch(fields, "green_mask", 10, 0);
    if (fp && *fp) { s->green_mask= SvUV(*fp); if (consume) hv_delete(fields, "green_mask", 10, G_DISCARD); }

    fp= hv_fetch(fields, "red_mask", 8, 0);
    if (fp && *fp) { s->red_mask= SvUV(*fp); if (consume) hv_delete(fields, "red_mask", 8, G_DISCARD); }

    fp= hv_fetch(fields, "screen", 6, 0);
    if (fp && *fp) { s->screen= SvIV(*fp); if (consume) hv_delete(fields, "screen", 6, G_DISCARD); }

    fp= hv_fetch(fields, "visual", 6, 0);
    if (fp && *fp) { s->visual= (Visual *) PerlXlib_sv_to_display_innerptr(*fp, 0); if (consume) hv_delete(fields, "visual", 6, G_DISCARD); }

    fp= hv_fetch(fields, "visualid", 8, 0);
    if (fp && *fp) { s->visualid= SvUV(*fp); if (consume) hv_delete(fields, "visualid", 8, G_DISCARD); }
}

void PerlXlib_XVisualInfo_unpack(XVisualInfo *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
    if (!hv_store(fields, "bits_per_rgb", 12, (sv=newSViv(s->bits_per_rgb)), 0)) goto store_fail;
    if (!hv_store(fields, "blue_mask" ,  9, (sv=newSVuv(s->blue_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "class"     ,  5, (sv=newSViv(s->class)), 0)) goto store_fail;
    if (!hv_store(fields, "colormap_size", 13, (sv=newSViv(s->colormap_size)), 0)) goto store_fail;
    if (!hv_store(fields, "depth"     ,  5, (sv=newSViv(s->depth)), 0)) goto store_fail;
    if (!hv_store(fields, "green_mask", 10, (sv=newSVuv(s->green_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "red_mask"  ,  8, (sv=newSVuv(s->red_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "screen"    ,  6, (sv=newSViv(s->screen)), 0)) goto store_fail;
    if (!hv_store(fields, "visual"    ,  6, (sv=newSVsv(s->visual? PerlXlib_obj_for_display_innerptr(dpy, s->visual, "X11::Xlib::Visual", SVt_PVMG, 1) : &PL_sv_undef)), 0)) goto store_fail;
    if (!hv_store(fields, "visualid"  ,  8, (sv=newSVuv(s->visualid)), 0)) goto store_fail;
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XVisualInfo
/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XWindowChanges */

void PerlXlib_XWindowChanges_pack(XWindowChanges *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "border_width", 12, 0);
    if (fp && *fp) { s->border_width= SvIV(*fp); if (consume) hv_delete(fields, "border_width", 12, G_DISCARD); }

    fp= hv_fetch(fields, "height", 6, 0);
    if (fp && *fp) { s->height= SvIV(*fp); if (consume) hv_delete(fields, "height", 6, G_DISCARD); }

    fp= hv_fetch(fields, "sibling", 7, 0);
    if (fp && *fp) { s->sibling= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "sibling", 7, G_DISCARD); }

    fp= hv_fetch(fields, "stack_mode", 10, 0);
    if (fp && *fp) { s->stack_mode= SvIV(*fp); if (consume) hv_delete(fields, "stack_mode", 10, G_DISCARD); }

    fp= hv_fetch(fields, "width", 5, 0);
    if (fp && *fp) { s->width= SvIV(*fp); if (consume) hv_delete(fields, "width", 5, G_DISCARD); }

    fp= hv_fetch(fields, "x", 1, 0);
    if (fp && *fp) { s->x= SvIV(*fp); if (consume) hv_delete(fields, "x", 1, G_DISCARD); }

    fp= hv_fetch(fields, "y", 1, 0);
    if (fp && *fp) { s->y= SvIV(*fp); if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
}

void PerlXlib_XWindowChanges_unpack(XWindowChanges *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
    if (!hv_store(fields, "border_width", 12, (sv=newSViv(s->border_width)), 0)) goto store_fail;
    if (!hv_store(fields, "height"    ,  6, (sv=newSViv(s->height)), 0)) goto store_fail;
    if (!hv_store(fields, "sibling"   ,  7, (sv=newSVuv(s->sibling)), 0)) goto store_fail;
    if (!hv_store(fields, "stack_mode", 10, (sv=newSViv(s->stack_mode)), 0)) goto store_fail;
    if (!hv_store(fields, "width"     ,  5, (sv=newSViv(s->width)), 0)) goto store_fail;
    if (!hv_store(fields, "x"         ,  1, (sv=newSViv(s->x)), 0)) goto store_fail;
    if (!hv_store(fields, "y"         ,  1, (sv=newSViv(s->y)), 0)) goto store_fail;
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XWindowChanges */
/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XWindowAttributes */

void PerlXlib_XWindowAttributes_pack(XWindowAttributes *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "all_event_masks", 15, 0);
    if (fp && *fp) { s->all_event_masks= SvIV(*fp); if (consume) hv_delete(fields, "all_event_masks", 15, G_DISCARD); }

    fp= hv_fetch(fields, "backing_pixel", 13, 0);
    if (fp && *fp) { s->backing_pixel= SvUV(*fp); if (consume) hv_delete(fields, "backing_pixel", 13, G_DISCARD); }

    fp= hv_fetch(fields, "backing_planes", 14, 0);
    if (fp && *fp) { s->backing_planes= SvUV(*fp); if (consume) hv_delete(fields, "backing_planes", 14, G_DISCARD); }

    fp= hv_fetch(fields, "backing_store", 13, 0);
    if (fp && *fp) { s->backing_store= SvIV(*fp); if (consume) hv_delete(fields, "backing_store", 13, G_DISCARD); }

    fp= hv_fetch(fields, "bit_gravity", 11, 0);
    if (fp && *fp) { s->bit_gravity= SvIV(*fp); if (consume) hv_delete(fields, "bit_gravity", 11, G_DISCARD); }

    fp= hv_fetch(fields, "border_width", 12, 0);
    if (fp && *fp) { s->border_width= SvIV(*fp); if (consume) hv_delete(fields, "border_width", 12, G_DISCARD); }

    fp= hv_fetch(fields, "class", 5, 0);
    if (fp && *fp) { s->class= SvIV(*fp); if (consume) hv_delete(fields, "class", 5, G_DISCARD); }

    fp= hv_fetch(fields, "colormap", 8, 0);
    if (fp && *fp) { s->colormap= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "colormap", 8, G_DISCARD); }

    fp= hv_fetch(fields, "depth", 5, 0);
    if (fp && *fp) { s->depth= SvIV(*fp); if (consume) hv_delete(fields, "depth", 5, G_DISCARD); }

    fp= hv_fetch(fields, "do_not_propagate_mask", 21, 0);
    if (fp && *fp) { s->do_not_propagate_mask= SvIV(*fp); if (consume) hv_delete(fields, "do_not_propagate_mask", 21, G_DISCARD); }

    fp= hv_fetch(fields, "height", 6, 0);
    if (fp && *fp) { s->height= SvIV(*fp); if (consume) hv_delete(fields, "height", 6, G_DISCARD); }

    fp= hv_fetch(fields, "map_installed", 13, 0);
    if (fp && *fp) { s->map_installed= SvIV(*fp); if (consume) hv_delete(fields, "map_installed", 13, G_DISCARD); }

    fp= hv_fetch(fields, "map_state", 9, 0);
    if (fp && *fp) { s->map_state= SvIV(*fp); if (consume) hv_delete(fields, "map_state", 9, G_DISCARD); }

    fp= hv_fetch(fields, "override_redirect", 17, 0);
    if (fp && *fp) { s->override_redirect= SvIV(*fp); if (consume) hv_delete(fields, "override_redirect", 17, G_DISCARD); }

    fp= hv_fetch(fields, "root", 4, 0);
    if (fp && *fp) { s->root= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "root", 4, G_DISCARD); }

    fp= hv_fetch(fields, "save_under", 10, 0);
    if (fp && *fp) { s->save_under= SvIV(*fp); if (consume) hv_delete(fields, "save_under", 10, G_DISCARD); }

    fp= hv_fetch(fields, "screen", 6, 0);
    if (fp && *fp) { s->screen= PerlXlib_sv_to_screen(*fp, 0); if (consume) hv_delete(fields, "screen", 6, G_DISCARD); }

    fp= hv_fetch(fields, "visual", 6, 0);
    if (fp && *fp) { s->visual= (Visual *) PerlXlib_sv_to_display_innerptr(*fp, 0); if (consume) hv_delete(fields, "visual", 6, G_DISCARD); }

    fp= hv_fetch(fields, "width", 5, 0);
    if (fp && *fp) { s->width= SvIV(*fp); if (consume) hv_delete(fields, "width", 5, G_DISCARD); }

    fp= hv_fetch(fields, "win_gravity", 11, 0);
    if (fp && *fp) { s->win_gravity= SvIV(*fp); if (consume) hv_delete(fields, "win_gravity", 11, G_DISCARD); }

    fp= hv_fetch(fields, "x", 1, 0);
    if (fp && *fp) { s->x= SvIV(*fp); if (consume) hv_delete(fields, "x", 1, G_DISCARD); }

    fp= hv_fetch(fields, "y", 1, 0);
    if (fp && *fp) { s->y= SvIV(*fp); if (consume) hv_delete(fields, "y", 1, G_DISCARD); }

    fp= hv_fetch(fields, "your_event_mask", 15, 0);
    if (fp && *fp) { s->your_event_mask= SvIV(*fp); if (consume) hv_delete(fields, "your_event_mask", 15, G_DISCARD); }
}

void PerlXlib_XWindowAttributes_unpack(XWindowAttributes *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
    if (!hv_store(fields, "all_event_masks", 15, (sv=newSViv(s->all_event_masks)), 0)) goto store_fail;
    if (!hv_store(fields, "backing_pixel", 13, (sv=newSVuv(s->backing_pixel)), 0)) goto store_fail;
    if (!hv_store(fields, "backing_planes", 14, (sv=newSVuv(s->backing_planes)), 0)) goto store_fail;
    if (!hv_store(fields, "backing_store", 13, (sv=newSViv(s->backing_store)), 0)) goto store_fail;
    if (!hv_store(fields, "bit_gravity", 11, (sv=newSViv(s->bit_gravity)), 0)) goto store_fail;
    if (!hv_store(fields, "border_width", 12, (sv=newSViv(s->border_width)), 0)) goto store_fail;
    if (!hv_store(fields, "class"     ,  5, (sv=newSViv(s->class)), 0)) goto store_fail;
    if (!hv_store(fields, "colormap"  ,  8, (sv=newSVuv(s->colormap)), 0)) goto store_fail;
    if (!hv_store(fields, "depth"     ,  5, (sv=newSViv(s->depth)), 0)) goto store_fail;
    if (!hv_store(fields, "do_not_propagate_mask", 21, (sv=newSViv(s->do_not_propagate_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "height"    ,  6, (sv=newSViv(s->height)), 0)) goto store_fail;
    if (!hv_store(fields, "map_installed", 13, (sv=newSViv(s->map_installed)), 0)) goto store_fail;
    if (!hv_store(fields, "map_state" ,  9, (sv=newSViv(s->map_state)), 0)) goto store_fail;
    if (!hv_store(fields, "override_redirect", 17, (sv=newSViv(s->override_redirect)), 0)) goto store_fail;
    if (!hv_store(fields, "root"      ,  4, (sv=newSVuv(s->root)), 0)) goto store_fail;
    if (!hv_store(fields, "save_under", 10, (sv=newSViv(s->save_under)), 0)) goto store_fail;
    if (!hv_store(fields, "screen"    ,  6, (sv=newSVsv(s->screen? PerlXlib_obj_for_screen(s->screen) : &PL_sv_undef)), 0)) goto store_fail;
    if (!hv_store(fields, "visual"    ,  6, (sv=newSVsv(s->visual? PerlXlib_obj_for_display_innerptr(dpy, s->visual, "X11::Xlib::Visual", SVt_PVMG, 1) : &PL_sv_undef)), 0)) goto store_fail;
    if (!hv_store(fields, "width"     ,  5, (sv=newSViv(s->width)), 0)) goto store_fail;
    if (!hv_store(fields, "win_gravity", 11, (sv=newSViv(s->win_gravity)), 0)) goto store_fail;
    if (!hv_store(fields, "x"         ,  1, (sv=newSViv(s->x)), 0)) goto store_fail;
    if (!hv_store(fields, "y"         ,  1, (sv=newSViv(s->y)), 0)) goto store_fail;
    if (!hv_store(fields, "your_event_mask", 15, (sv=newSViv(s->your_event_mask)), 0)) goto store_fail;
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XWindowAttributes */
/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XSetWindowAttributes */

void PerlXlib_XSetWindowAttributes_pack(XSetWindowAttributes *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "background_pixel", 16, 0);
    if (fp && *fp) { s->background_pixel= SvUV(*fp); if (consume) hv_delete(fields, "background_pixel", 16, G_DISCARD); }

    fp= hv_fetch(fields, "background_pixmap", 17, 0);
    if (fp && *fp) { s->background_pixmap= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "background_pixmap", 17, G_DISCARD); }

    fp= hv_fetch(fields, "backing_pixel", 13, 0);
    if (fp && *fp) { s->backing_pixel= SvUV(*fp); if (consume) hv_delete(fields, "backing_pixel", 13, G_DISCARD); }

    fp= hv_fetch(fields, "backing_planes", 14, 0);
    if (fp && *fp) { s->backing_planes= SvUV(*fp); if (consume) hv_delete(fields, "backing_planes", 14, G_DISCARD); }

    fp= hv_fetch(fields, "backing_store", 13, 0);
    if (fp && *fp) { s->backing_store= SvIV(*fp); if (consume) hv_delete(fields, "backing_store", 13, G_DISCARD); }

    fp= hv_fetch(fields, "bit_gravity", 11, 0);
    if (fp && *fp) { s->bit_gravity= SvIV(*fp); if (consume) hv_delete(fields, "bit_gravity", 11, G_DISCARD); }

    fp= hv_fetch(fields, "border_pixel", 12, 0);
    if (fp && *fp) { s->border_pixel= SvUV(*fp); if (consume) hv_delete(fields, "border_pixel", 12, G_DISCARD); }

    fp= hv_fetch(fields, "border_pixmap", 13, 0);
    if (fp && *fp) { s->border_pixmap= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "border_pixmap", 13, G_DISCARD); }

    fp= hv_fetch(fields, "colormap", 8, 0);
    if (fp && *fp) { s->colormap= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "colormap", 8, G_DISCARD); }

    fp= hv_fetch(fields, "cursor", 6, 0);
    if (fp && *fp) { s->cursor= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "cursor", 6, G_DISCARD); }

    fp= hv_fetch(fields, "do_not_propagate_mask", 21, 0);
    if (fp && *fp) { s->do_not_propagate_mask= SvIV(*fp); if (consume) hv_delete(fields, "do_not_propagate_mask", 21, G_DISCARD); }

    fp= hv_fetch(fields, "event_mask", 10, 0);
    if (fp && *fp) { s->event_mask= SvIV(*fp); if (consume) hv_delete(fields, "event_mask", 10, G_DISCARD); }

    fp= hv_fetch(fields, "override_redirect", 17, 0);
    if (fp && *fp) { s->override_redirect= SvIV(*fp); if (consume) hv_delete(fields, "override_redirect", 17, G_DISCARD); }

    fp= hv_fetch(fields, "save_under", 10, 0);
    if (fp && *fp) { s->save_under= SvIV(*fp); if (consume) hv_delete(fields, "save_under", 10, G_DISCARD); }

    fp= hv_fetch(fields, "win_gravity", 11, 0);
    if (fp && *fp) { s->win_gravity= SvIV(*fp); if (consume) hv_delete(fields, "win_gravity", 11, G_DISCARD); }
}

void PerlXlib_XSetWindowAttributes_unpack(XSetWindowAttributes *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
    if (!hv_store(fields, "background_pixel", 16, (sv=newSVuv(s->background_pixel)), 0)) goto store_fail;
    if (!hv_store(fields, "background_pixmap", 17, (sv=newSVuv(s->background_pixmap)), 0)) goto store_fail;
    if (!hv_store(fields, "backing_pixel", 13, (sv=newSVuv(s->backing_pixel)), 0)) goto store_fail;
    if (!hv_store(fields, "backing_planes", 14, (sv=newSVuv(s->backing_planes)), 0)) goto store_fail;
    if (!hv_store(fields, "backing_store", 13, (sv=newSViv(s->backing_store)), 0)) goto store_fail;
    if (!hv_store(fields, "bit_gravity", 11, (sv=newSViv(s->bit_gravity)), 0)) goto store_fail;
    if (!hv_store(fields, "border_pixel", 12, (sv=newSVuv(s->border_pixel)), 0)) goto store_fail;
    if (!hv_store(fields, "border_pixmap", 13, (sv=newSVuv(s->border_pixmap)), 0)) goto store_fail;
    if (!hv_store(fields, "colormap"  ,  8, (sv=newSVuv(s->colormap)), 0)) goto store_fail;
    if (!hv_store(fields, "cursor"    ,  6, (sv=newSVuv(s->cursor)), 0)) goto store_fail;
    if (!hv_store(fields, "do_not_propagate_mask", 21, (sv=newSViv(s->do_not_propagate_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "event_mask", 10, (sv=newSViv(s->event_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "override_redirect", 17, (sv=newSViv(s->override_redirect)), 0)) goto store_fail;
    if (!hv_store(fields, "save_under", 10, (sv=newSViv(s->save_under)), 0)) goto store_fail;
    if (!hv_store(fields, "win_gravity", 11, (sv=newSViv(s->win_gravity)), 0)) goto store_fail;
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XSetWindowAttributes */
/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XSizeHints */

void PerlXlib_XSizeHints_pack(XSizeHints *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "base_height", 11, 0);
    if (fp && *fp) { s->flags |= PBaseSize; s->base_height= SvIV(*fp); if (consume) hv_delete(fields, "base_height", 11, G_DISCARD); }

    fp= hv_fetch(fields, "base_width", 10, 0);
    if (fp && *fp) { s->flags |= PBaseSize; s->base_width= SvIV(*fp); if (consume) hv_delete(fields, "base_width", 10, G_DISCARD); }

    fp= hv_fetch(fields, "flags", 5, 0);
    if (fp && *fp) { s->flags= SvIV(*fp); if (consume) hv_delete(fields, "flags", 5, G_DISCARD); }

    fp= hv_fetch(fields, "height", 6, 0);
    if (fp && *fp) { s->flags |= PSize; s->height= SvIV(*fp); if (consume) hv_delete(fields, "height", 6, G_DISCARD); }

    fp= hv_fetch(fields, "height_inc", 10, 0);
    if (fp && *fp) { s->flags |= PResizeInc; s->height_inc= SvIV(*fp); if (consume) hv_delete(fields, "height_inc", 10, G_DISCARD); }

    fp= hv_fetch(fields, "max_aspect_x", 12, 0);
    if (fp && *fp) { s->flags |= PAspect; s->max_aspect.x= SvIV(*fp); if (consume) hv_delete(fields, "max_aspect_x", 12, G_DISCARD); }

    fp= hv_fetch(fields, "max_aspect_y", 12, 0);
    if (fp && *fp) { s->flags |= PAspect; s->max_aspect.y= SvIV(*fp); if (consume) hv_delete(fields, "max_aspect_y", 12, G_DISCARD); }

    fp= hv_fetch(fields, "max_height", 10, 0);
    if (fp && *fp) { s->flags |= PMaxSize; s->max_height= SvIV(*fp); if (consume) hv_delete(fields, "max_height", 10, G_DISCARD); }

    fp= hv_fetch(fields, "max_width", 9, 0);
    if (fp && *fp) { s->flags |= PMaxSize; s->max_width= SvIV(*fp); if (consume) hv_delete(fields, "max_width", 9, G_DISCARD); }

    fp= hv_fetch(fields, "min_aspect_x", 12, 0);
    if (fp && *fp) { s->flags |= PAspect; s->min_aspect.x= SvIV(*fp); if (consume) hv_delete(fields, "min_aspect_x", 12, G_DISCARD); }

    fp= hv_fetch(fields, "min_aspect_y", 12, 0);
    if (fp && *fp) { s->flags |= PAspect; s->min_aspect.y= SvIV(*fp); if (consume) hv_delete(fields, "min_aspect_y", 12, G_DISCARD); }

    fp= hv_fetch(fields, "min_height", 10, 0);
    if (fp && *fp) { s->flags |= PMinSize; s->min_height= SvIV(*fp); if (consume) hv_delete(fields, "min_height", 10, G_DISCARD); }

    fp= hv_fetch(fields, "min_width", 9, 0);
    if (fp && *fp) { s->flags |= PMinSize; s->min_width= SvIV(*fp); if (consume) hv_delete(fields, "min_width", 9, G_DISCARD); }

    fp= hv_fetch(fields, "width", 5, 0);
    if (fp && *fp) { s->flags |= PSize; s->width= SvIV(*fp); if (consume) hv_delete(fields, "width", 5, G_DISCARD); }

    fp= hv_fetch(fields, "width_inc", 9, 0);
    if (fp && *fp) { s->flags |= PResizeInc; s->width_inc= SvIV(*fp); if (consume) hv_delete(fields, "width_inc", 9, G_DISCARD); }

    fp= hv_fetch(fields, "win_gravity", 11, 0);
    if (fp && *fp) { s->flags |= PWinGravity; s->win_gravity= SvIV(*fp); if (consume) hv_delete(fields, "win_gravity", 11, G_DISCARD); }

    fp= hv_fetch(fields, "x", 1, 0);
    if (fp && *fp) { s->flags |= PPosition; s->x= SvIV(*fp); if (consume) hv_delete(fields, "x", 1, G_DISCARD); }

    fp= hv_fetch(fields, "y", 1, 0);
    if (fp && *fp) { s->flags |= PPosition; s->y= SvIV(*fp); if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
}

void PerlXlib_XSizeHints_unpack(XSizeHints *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
if (s->flags & PBaseSize) {     if (!hv_store(fields, "base_height", 11, (sv=newSViv(s->base_height)), 0)) goto store_fail;
 }if (s->flags & PBaseSize) {     if (!hv_store(fields, "base_width", 10, (sv=newSViv(s->base_width)), 0)) goto store_fail;
 }    if (!hv_store(fields, "flags"     ,  5, (sv=newSViv(s->flags)), 0)) goto store_fail;
if (s->flags & PSize) {     if (!hv_store(fields, "height"    ,  6, (sv=newSViv(s->height)), 0)) goto store_fail;
 }if (s->flags & PResizeInc) {     if (!hv_store(fields, "height_inc", 10, (sv=newSViv(s->height_inc)), 0)) goto store_fail;
 }if (s->flags & PAspect) {     if (!hv_store(fields, "max_aspect_x", 12, (sv=newSViv(s->max_aspect.x)), 0)) goto store_fail;
 }if (s->flags & PAspect) {     if (!hv_store(fields, "max_aspect_y", 12, (sv=newSViv(s->max_aspect.y)), 0)) goto store_fail;
 }if (s->flags & PMaxSize) {     if (!hv_store(fields, "max_height", 10, (sv=newSViv(s->max_height)), 0)) goto store_fail;
 }if (s->flags & PMaxSize) {     if (!hv_store(fields, "max_width" ,  9, (sv=newSViv(s->max_width)), 0)) goto store_fail;
 }if (s->flags & PAspect) {     if (!hv_store(fields, "min_aspect_x", 12, (sv=newSViv(s->min_aspect.x)), 0)) goto store_fail;
 }if (s->flags & PAspect) {     if (!hv_store(fields, "min_aspect_y", 12, (sv=newSViv(s->min_aspect.y)), 0)) goto store_fail;
 }if (s->flags & PMinSize) {     if (!hv_store(fields, "min_height", 10, (sv=newSViv(s->min_height)), 0)) goto store_fail;
 }if (s->flags & PMinSize) {     if (!hv_store(fields, "min_width" ,  9, (sv=newSViv(s->min_width)), 0)) goto store_fail;
 }if (s->flags & PSize) {     if (!hv_store(fields, "width"     ,  5, (sv=newSViv(s->width)), 0)) goto store_fail;
 }if (s->flags & PResizeInc) {     if (!hv_store(fields, "width_inc" ,  9, (sv=newSViv(s->width_inc)), 0)) goto store_fail;
 }if (s->flags & PWinGravity) {     if (!hv_store(fields, "win_gravity", 11, (sv=newSViv(s->win_gravity)), 0)) goto store_fail;
 }if (s->flags & PPosition) {     if (!hv_store(fields, "x"         ,  1, (sv=newSViv(s->x)), 0)) goto store_fail;
 }if (s->flags & PPosition) {     if (!hv_store(fields, "y"         ,  1, (sv=newSViv(s->y)), 0)) goto store_fail;
 }    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XSizeHints */
/*--------------------------------------------------------------------------*/
/* BEGIN GENERATED X11_Xlib_XRectangle */

void PerlXlib_XRectangle_pack(XRectangle *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "height", 6, 0);
    if (fp && *fp) { s->height= SvUV(*fp); if (consume) hv_delete(fields, "height", 6, G_DISCARD); }

    fp= hv_fetch(fields, "width", 5, 0);
    if (fp && *fp) { s->width= SvUV(*fp); if (consume) hv_delete(fields, "width", 5, G_DISCARD); }

    fp= hv_fetch(fields, "x", 1, 0);
    if (fp && *fp) { s->x= SvIV(*fp); if (consume) hv_delete(fields, "x", 1, G_DISCARD); }

    fp= hv_fetch(fields, "y", 1, 0);
    if (fp && *fp) { s->y= SvIV(*fp); if (consume) hv_delete(fields, "y", 1, G_DISCARD); }
}

void PerlXlib_XRectangle_unpack(XRectangle *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
    if (!hv_store(fields, "height"    ,  6, (sv=newSVuv(s->height)), 0)) goto store_fail;
    if (!hv_store(fields, "width"     ,  5, (sv=newSVuv(s->width)), 0)) goto store_fail;
    if (!hv_store(fields, "x"         ,  1, (sv=newSViv(s->x)), 0)) goto store_fail;
    if (!hv_store(fields, "y"         ,  1, (sv=newSViv(s->y)), 0)) goto store_fail;
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XRectangle */
/*--------------------------------------------------------------------------*/
#ifdef HAVE_XRENDER
/* BEGIN GENERATED X11_Xlib_XRenderPictFormat */

void PerlXlib_XRenderPictFormat_pack(XRenderPictFormat *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */

    fp= hv_fetch(fields, "colormap", 8, 0);
    if (fp && *fp) { s->colormap= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "colormap", 8, G_DISCARD); }

    fp= hv_fetch(fields, "depth", 5, 0);
    if (fp && *fp) { s->depth= SvIV(*fp); if (consume) hv_delete(fields, "depth", 5, G_DISCARD); }

    fp= hv_fetch(fields, "direct_alpha", 12, 0);
    if (fp && *fp) { s->direct.alpha= SvIV(*fp); if (consume) hv_delete(fields, "direct_alpha", 12, G_DISCARD); }

    fp= hv_fetch(fields, "direct_alphaMask", 16, 0);
    if (fp && *fp) { s->direct.alphaMask= SvIV(*fp); if (consume) hv_delete(fields, "direct_alphaMask", 16, G_DISCARD); }

    fp= hv_fetch(fields, "direct_blue", 11, 0);
    if (fp && *fp) { s->direct.blue= SvIV(*fp); if (consume) hv_delete(fields, "direct_blue", 11, G_DISCARD); }

    fp= hv_fetch(fields, "direct_blueMask", 15, 0);
    if (fp && *fp) { s->direct.blueMask= SvIV(*fp); if (consume) hv_delete(fields, "direct_blueMask", 15, G_DISCARD); }

    fp= hv_fetch(fields, "direct_green", 12, 0);
    if (fp && *fp) { s->direct.green= SvIV(*fp); if (consume) hv_delete(fields, "direct_green", 12, G_DISCARD); }

    fp= hv_fetch(fields, "direct_greenMask", 16, 0);
    if (fp && *fp) { s->direct.greenMask= SvIV(*fp); if (consume) hv_delete(fields, "direct_greenMask", 16, G_DISCARD); }

    fp= hv_fetch(fields, "direct_red", 10, 0);
    if (fp && *fp) { s->direct.red= SvIV(*fp); if (consume) hv_delete(fields, "direct_red", 10, G_DISCARD); }

    fp= hv_fetch(fields, "direct_redMask", 14, 0);
    if (fp && *fp) { s->direct.redMask= SvIV(*fp); if (consume) hv_delete(fields, "direct_redMask", 14, G_DISCARD); }

    fp= hv_fetch(fields, "id", 2, 0);
    if (fp && *fp) { s->id= PerlXlib_sv_to_xid(*fp); if (consume) hv_delete(fields, "id", 2, G_DISCARD); }

    fp= hv_fetch(fields, "type", 4, 0);
    if (fp && *fp) { s->type= SvIV(*fp); if (consume) hv_delete(fields, "type", 4, G_DISCARD); }
}

void PerlXlib_XRenderPictFormat_unpack(XRenderPictFormat *s, HV *fields) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to clean up the value.
     */
    SV *sv= NULL;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
    if (!hv_store(fields, "colormap"  ,  8, (sv=newSVuv(s->colormap)), 0)) goto store_fail;
    if (!hv_store(fields, "depth"     ,  5, (sv=newSViv(s->depth)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_alpha", 12, (sv=newSViv(s->direct.alpha)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_alphaMask", 16, (sv=newSViv(s->direct.alphaMask)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_blue", 11, (sv=newSViv(s->direct.blue)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_blueMask", 15, (sv=newSViv(s->direct.blueMask)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_green", 12, (sv=newSViv(s->direct.green)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_greenMask", 16, (sv=newSViv(s->direct.greenMask)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_red", 10, (sv=newSViv(s->direct.red)), 0)) goto store_fail;
    if (!hv_store(fields, "direct_redMask", 14, (sv=newSViv(s->direct.redMask)), 0)) goto store_fail;
    if (!hv_store(fields, "id"        ,  2, (sv=newSVuv(s->id)), 0)) goto store_fail;
    if (!hv_store(fields, "type"      ,  4, (sv=newSViv(s->type)), 0)) goto store_fail;
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}

/* END GENERATED X11_Xlib_XRenderPictFormat */
#endif
/*--------------------------------------------------------------------------*/
