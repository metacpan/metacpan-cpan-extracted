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

#define OR_NULL    PerlXlib_OR_NULL
#define OR_UNDEF   PerlXlib_OR_UNDEF
#define OR_DIE     PerlXlib_OR_DIE
#define AUTOCREATE PerlXlib_AUTOCREATE

static const char* T_DISPLAY= "Display";
static const char* OBJ_CACHE_NAME= "X11::Xlib::_obj_cache";

static struct PerlXlib_fields* PerlXlib_get_magic_fields(SV *sv, int create_flag);

/*-----------------------------------------------------------------------------------
 * This struct is attached to each of the X11::Xlib objects that reference C structs.
 */
struct PerlXlib_fields {
    SV *self;              /* reference to the SV this struct is attached to */
	SV *display_sv;        /* optional reference to Display, no lifespan tracking */
    void *ptr;             /* struct/opaque pointer to something in xlib */
    const char *ptr_type;  /* static string identifying the type of the object */
    int xfree_cleanup: 1;  /* whether to call XFree(ptr) during destructor */
    struct PerlXlib_fields *parent; /* Object whose ->ptr owns the lifespan of this ->ptr */
    AV *dependents;        /* weak references to X11::Xlib objects whose ptr depends on this object */
};

static void PerlXlib_fields_init(struct PerlXlib_fields *fields, SV *self) {
    Zero(fields, 1, struct PerlXlib_fields);
    fields->self= self;
}

/* Set the ->ptr field, but also update the cache of pointers-to-objects.
 * type is optional, but useful for debugging.
 * obj is the *inner* SV/HV/AV of the object not a RV pointing to it.
 */
static void PerlXlib_fields_set_ptr(struct PerlXlib_fields *fields, void *ptr, const char *type) {
    HV *cache= NULL;
    SV **ent, *sv;
    if (fields->ptr == ptr)
        return; /* nothing to do */
    if (fields->ptr) { /* remove any previous object from cache */
        cache= get_hv(OBJ_CACHE_NAME, GV_ADD);
        hv_delete(cache, (void*) &fields->ptr, sizeof(void*), G_DISCARD);
    }
    fields->ptr= ptr;
    fields->ptr_type= ptr? type : NULL;
    fields->xfree_cleanup= 0;
    if (fields->self && fields->ptr) {
        if (!cache) cache= get_hv(OBJ_CACHE_NAME, GV_ADD);
        sv= newRV_inc(fields->self); /* create new weak-ref to the object */
        sv_rvweaken(sv);
        ent= hv_store(cache, (void*) &fields->ptr, sizeof(void*), sv, 0);
        if (!ent) {
            sv_2mortal(sv);
            croak("Can't cache X11 wrapper object into %s", OBJ_CACHE_NAME);
        }
    }
}

/* Set 'fields' as the parent of 'dep', adding a weak-ref to 'dep' in the dependents list.
 * dep is the *inner* SV/AV/HV of the object, not a RV pointing to it.
 */
static void PerlXlib_fields_add_dependent(struct PerlXlib_fields *fields, SV *dep) {
    int i;
    SV **ent, *sv;
    AV *deps= fields->dependents? fields->dependents : (fields->dependents= newAV());
    struct PerlXlib_fields *dep_fields= PerlXlib_get_magic_fields(dep, AUTOCREATE);

    if (dep_fields->parent)
        croak("Dependent object already has a parent");
    /* sanity check to avoid pointless refcnt management below */
    if (SvMAGICAL(deps))
        croak("bug");
    /* The list contains weak references, and every now and then we should clean up any
     * that got un-set.  Do this every time the list reaches a multiple of 8. */
    if (!(av_len(deps) & 7)) {
        for (i= av_len(deps); i >= 0; --i) {
            ent= av_fetch(deps, i, 0);
            if (ent && !SvROK(*ent)) {
                sv= av_pop(deps);
                if (i <= av_len(deps)) av_store(deps, i, sv);
                else SvREFCNT_dec(sv);
            }
        }
    }
    av_push(deps, sv_rvweaken(newRV_inc(dep)));
    dep_fields->parent= fields;
}

/* When the C-level object responsible for this object's C-level data gets freed,
 * Set the pointers to NULL.  This chains through all dependents.
 * At the end, there are no more dependents.
 */
static void PerlXlib_fields_invalidate_dependents(struct PerlXlib_fields *fields) {
    struct PerlXlib_fields *peer_fields;
    int i;
    SV **ent;
    /* If other C-level objects depended on this one, their wrappers also need ->ptr set to NULL. */
    if (fields->dependents) {
        for (i= av_len(fields->dependents); i >= 0; --i) {
            ent= av_fetch(fields->dependents, i, 0);
            if (ent && SvROK(*ent)) {
                if (peer_fields= PerlXlib_get_magic_fields(SvRV(*ent), 0)) {
                    if (peer_fields->xfree_cleanup)
                        warn("An object using XFree was incorrectly listed as a dependent on another object");
                    else {
                        peer_fields->parent= NULL;
                        if (peer_fields->ptr)
                            PerlXlib_fields_set_ptr(peer_fields, NULL, NULL);
                        if (peer_fields->dependents)
                            PerlXlib_fields_invalidate_dependents(peer_fields);
                    }
                }
            }
        }
        /* no more dependents */
        av_clear(fields->dependents);
        sv_2mortal((SV*)fields->dependents);
        fields->dependents= NULL;
    }
}

/* Called automatically when the magic-bearing object is freed */
static void PerlXlib_fields_free(struct PerlXlib_fields *fields) {
    /* un-set the ->ptr, which by extension removes the containing object from the object cache */
    if (fields->ptr) {
        if (fields->xfree_cleanup)
            XFree(fields->ptr);
        PerlXlib_fields_set_ptr(fields, NULL, NULL);
    }
    /* release the reference to the X11::Xlib instance if this object was holding one */
    if (fields->display_sv) {
        sv_2mortal(fields->display_sv);
        fields->display_sv= NULL;
    }
    /* No need to tell the parent we're gone because the parent holds a weak-ref */
    fields->parent= NULL;
    /* tell dependent objects that they are no longer valid */
    PerlXlib_fields_invalidate_dependents(fields);
    fields->self= NULL;
    Safefree(fields);
}

/*------------------------------------------------------------------------------------
 * This defines the "Magic" that perl attaches to a scalar.
 */
static int PerlXlib_magic_free(pTHX_ SV* sv, MAGIC* mg) {
    if (mg->mg_ptr)
        PerlXlib_fields_free((struct PerlXlib_fields*) mg->mg_ptr);
    return 0; // ignored anyway
}
#ifdef USE_ITHREADS
static int PerlXlib_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    croak("This object cannot be shared between threads");
    return 0;
};
#else
#define PerlXlib_magic_dup 0
#endif
static MGVTBL PerlXlib_magic_vt= {
	0, /* get */
	0, /* write */
	0, /* length */
	0, /* clear */
	PerlXlib_magic_free,
	0, /* copy */
	PerlXlib_magic_dup
#ifdef MGf_LOCAL
	,0
#endif
};

/* Get existing magic fields or attach magic fields to the object.
 * The sv should be the inner SV/HV/AV of the object, not an RV pointing to it.
 * Use AUTOCREATE to attach magic if it wasn't present.
 * Use NOTNULL for a built-in croak() if the return value would be NULL.
 */
static struct PerlXlib_fields* PerlXlib_get_magic_fields(SV *sv, int create_flag) {
	MAGIC* magic;
    struct PerlXlib_fields *fields;
	if (SvMAGICAL(sv)) {
        /* Iterate magic attached to this scalar, looking for one with our vtable */
        for (magic= SvMAGIC(sv); magic; magic = magic->mg_moremagic)
            if (magic->mg_type == PERL_MAGIC_ext && magic->mg_virtual == &PerlXlib_magic_vt)
                /* If found, the mg_ptr points to the fields structure. */
                return (struct PerlXlib_fields*) magic->mg_ptr;
    }
    if (create_flag == OR_DIE)
        croak("Object lacks X11 magic");
    if (create_flag == AUTOCREATE) {
        Newx(fields, 1, struct PerlXlib_fields);
        PerlXlib_fields_init(fields, sv);
        magic= sv_magicext(sv, NULL, PERL_MAGIC_ext, &PerlXlib_magic_vt, (const char*) fields, 0);
#ifdef USE_ITHREADS
        magic->mg_flags |= MGf_DUP;
#endif
        return fields;
    }
	return NULL;
}


/*----------------------------------------------------------------------------------------
 * Public API
 */

/* This gets a cached object known to wrap the C-level pointer 'thing'.
 * If 'thing' is NULL, this always returns NULL regardless of create_flag.
 * If one does not exist and 'create' is requested, this will create a new wrapper
 * object of the given svtype blessed as thing_class, and optionally listing it as
 * a dependency of 'parent'.
 * Returns a mortal reference to the object.
 */
extern SV * PerlXlib_get_objref(void *thing, int create_flag,
    const char *thing_type, int svtype, const char *thing_class, void *parent
) {
    HV *cache, *pkg;
    GV *build_method;
    AV *isa;
    SV **ent, *ret, *parent_objref;
    struct PerlXlib_fields *f, *parent_fields;

    if (thing) {
        ent= hv_fetch(get_hv(OBJ_CACHE_NAME, GV_ADD), (void*) &thing, sizeof(thing), 0);
        /* Return existing object?  It's a weak-ref, so check that it still points to something. */
        if (ent && SvROK(*ent))
            /* create strong-ref from weakref */
            return sv_mortalcopy(*ent);
    }

    if (create_flag == OR_NULL)
        return NULL;
    if (create_flag == OR_UNDEF || (create_flag == AUTOCREATE && !thing))
        return &PL_sv_undef;
    if (create_flag != AUTOCREATE)
        croak("No such reference");
    
    /* Doesn't exist.  Create a new one. */
    pkg= gv_stashpv(thing_class, GV_ADD);
    if (svtype == SVt_PVMG) {
        /* return value is a new mortal RV pointing to a PV blessed as thing_class,
          * and the PV points to thing.
          */
        ret= sv_setref_pv(sv_newmortal(), thing_class, thing);
    }
    else if (svtype == SVt_PVHV) {
        /* return value is a new mortal RV pointing to a HV blessed as thing_class,
          * and with "dpy_innerptr" magic attached holding the pointer to thing.
          */
        ret= sv_2mortal(newRV_noinc((SV*) newHV()));
        sv_bless(ret, pkg);
    }
    else if (svtype == SVt_PVAV) {
        /* return value is a new mortal RV pointing to a AV blessed as thing_class,
          * and with "dpy_innerptr" magic attached holding the pointer to thing.
          */
        ret= sv_2mortal(newRV_noinc((SV*) newAV()));
        sv_bless(ret, pkg);
    }
    else
        croak("Unsupported svtype in PerlXlib_get_obj_for_ptr");

    f= PerlXlib_get_magic_fields(SvRV(ret), AUTOCREATE);
    PerlXlib_fields_set_ptr(f, thing, thing_type); /* adds weak-ref to cache */
    /* If there is an owner, add this object to the owner's list */
    if (parent) {
        parent_objref= PerlXlib_get_objref(parent, OR_NULL, NULL, 0, NULL, NULL);
        if (!parent_objref || !SvROK(parent_objref))
            croak("No containing object for parent pointer %p", parent);
        parent_fields= PerlXlib_get_magic_fields(SvRV(parent_objref), AUTOCREATE);
        PerlXlib_fields_add_dependent(parent_fields, SvRV(ret));
        /* If the parent is a Display, also reference it as the ->display attribute */
        if (parent_fields->ptr_type == T_DISPLAY)
            f->display_sv= newRV_inc(parent_fields->self);
    }
    /* Call the 'BUILD' method of the package, if any */
    if ((build_method= gv_fetchmeth(pkg, "BUILD", 5, 0)) && GvCV(build_method)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_mortalcopy(ret));
        PUTBACK;
        call_sv((SV*) GvCV(build_method), G_DISCARD);
        FREETMPS;
        LEAVE;
    }
    return ret;
}

/* If objref is an object with X11 magic attached, this retrieves the ->ptr from its fields.
 */
extern void* PerlXlib_objref_get_pointer(SV *objref, const char *ptr_type, int fail_flag) {
    struct PerlXlib_fields *f= NULL;
    if (sv_isobject(objref)) {
        f= PerlXlib_get_magic_fields(SvRV(objref), OR_NULL);
        if (f && f->ptr) {
            if (ptr_type && !(f->ptr_type && 0 == strcmp(f->ptr_type, ptr_type)))
                croak("Object pointer is %s (need %s)", f->ptr_type? f->ptr_type : "(unknown)", ptr_type);
            return f->ptr;
        }
        if (fail_flag == OR_DIE)
            croak("No Xlib pointer attached to this object");
    }
    /* OR_NULL permits things like an SV set to zero, or undef, but still rejects nonsense arguments */
    else if ((fail_flag == OR_DIE) || !(!SvOK(objref) || looks_like_number(objref) && SvIV(objref) == 0))
        croak("Not a reference to a %s", ptr_type);
    return NULL;
}

extern void PerlXlib_objref_set_pointer(SV *objref, void *pointer, const char *ptr_type) {
    struct PerlXlib_fields *f= NULL;
    if (!sv_isobject(objref))
        croak("Not an object");
    f= PerlXlib_get_magic_fields(SvRV(objref), AUTOCREATE);
    if (f->ptr_type && pointer) {
        if (!ptr_type || 0 != strcmp(ptr_type, f->ptr_type))
            croak("Cannot replace pointer with different type (%s != %s)", ptr_type? ptr_type : "NULL", f->ptr_type);
        ptr_type= f->ptr_type; /* preserve T_DISPLAY special case */
    } else if (ptr_type && 0 == strcmp(ptr_type, T_DISPLAY)) {
        ptr_type= T_DISPLAY; /* T_DISPLAY special case, used as a flag */
    }
    PerlXlib_fields_set_ptr(f, pointer, ptr_type);
}

/* Same as PerlXlib_get_objref, but with a few special cases.
 * When given a pointer and the create flag is false, this returns the pointer as an integer.
 * This handles cases like returning the event->display field which might have been corrupted with
 * any value, and prevents creating new X11::Xlib connections for those.
 */
extern SV * PerlXlib_get_display_objref(Display *dpy, int create_flag) {
    SV *objref= PerlXlib_get_objref(dpy, create_flag == OR_UNDEF? OR_NULL : create_flag,
        T_DISPLAY, SVt_PVHV, "X11::Xlib", NULL);
    /* objref is either a strong&mortal reference to X11::Xlib, or NULL, or undef.
     * For the NULL/undef case, just return the pointer as an integer. */
    if (objref && SvOK(objref))
        return objref;
    if (create_flag == OR_DIE)
        croak("No such display %p", dpy);
    return dpy? sv_2mortal(newSVuv(PTR2UV(dpy)))
        : create_flag == OR_NULL? NULL
        : &PL_sv_undef;
}

/* Get the Display* pointer from an instance of X11::Xlib.
 * This is the same as PerlXlib_objref_get_pointer but with improved diagnostics.
 */
extern Display* PerlXlib_display_objref_get_pointer(SV *displayref, int fail_flag) {
    void *pointer= PerlXlib_objref_get_pointer(displayref, T_DISPLAY, 0);
    if (!pointer && fail_flag == OR_DIE) {
        if (SvTRUE(get_sv("X11::Xlib::_error_fatal_trapped", GV_ADD)))
            croak("Cannot call further Xlib functions after fatal Xlib error");
        if (!sv_derived_from(displayref, "X11::Xlib"))
            croak("Invalid X11 connection parameter; must be instance of X11::Xlib");
        /* has magic, but NULL pointer */
        croak("X11 connection was closed");
    }
    return pointer;
}

/* Return the X11 Screen* pointer from a Perl X11::Xlib::Screen object.
 * The ::Screen objects are a hashref with a normal reference to the ->{display},
 * and a second field of ->{screen_number}.  Use thes two values to call
 * ScreenOfDisplay to get the Screen* pointer.
 */
extern Screen * PerlXlib_screen_objref_get_pointer(SV *sv, int fail_flag) {
    HV *hv;
    SV **elem;
    Display *dpy;
    int screennum;
    
    if (!sv || !SvROK(sv) || !SvTYPE(SvRV(sv)) == SVt_PVHV) {
        if (fail_flag == OR_DIE || (sv && SvOK(sv)))
            croak("expected X11::Xlib::Screen object");
        return NULL;
    }
    
    hv= (HV*) SvRV(sv);
    elem= hv_fetch(hv, "display", 7, 0);
    if (!elem || !(dpy= PerlXlib_display_objref_get_pointer(*elem, OR_NULL)))
        croak("missing $screen->{display}");
    elem= hv_fetch(hv, "screen_number", 13, 0);
    if (!elem || !SvIOK(*elem))
        croak("missing $screen->{screen_number}");
    screennum= SvIV(*elem);
    if (screennum >= ScreenCount(dpy) || screennum < 0)
        croak("Screen number %d out of bounds for this display (0..%d)",
            screennum, ScreenCount(dpy)-1);
    return ScreenOfDisplay(dpy, screennum);
}

/* Given a Xlib Screen* pointer, find the X11::Xlib::Screen object for it.
 * This is done by getting the X11::Xlib instance for the screen's Display pointer,
 * and then getting the screen object from the X11::Xlib object.
 */
extern SV * PerlXlib_get_screen_objref(Screen *screen, int create_flag) {
    Display *dpy= NULL;
    SV *dpy_sv= NULL, *ret= NULL;
    int i;
    
    if (!screen) {
        if (create_flag == OR_DIE) croak("NULL Screen pointer");
        if (create_flag == OR_UNDEF || create_flag == AUTOCREATE) return &PL_sv_undef;
        return NULL;
    }
    /* from here on, it's basically AUTOCREATE because screen objects aren't cached by pointer */

    dpy= DisplayOfScreen(screen);
    dpy_sv= PerlXlib_get_display_objref(dpy, OR_DIE);

    /* There's actually no way to get the screen number from the pointer,
      * other than subtraction on private pointers...  so just iterate.
      * There's probably only one anyway. */
    for (i= ScreenCount(dpy) - 1; i >= 0; --i)
        if (screen == ScreenOfDisplay(dpy, i))
            break;
    if (i < 0)
        croak("Corrupt Xlib screen/display structures!");
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
    return ret;
}

/* Read-accessor for the $obj->display attribute */
extern SV * PerlXlib_objref_get_display(SV *objref) {
    struct PerlXlib_fields *f;
    if (!sv_isobject(objref))
        croak("Not an object - can't read attribute of %s", SvPV_nolen(objref));
    f= PerlXlib_get_magic_fields(SvRV(objref), OR_NULL);
    return (f && f->ptr_type == T_DISPLAY)? objref  /* X11::Xlib is its own ->display attribute */
        : (f && f->display_sv && sv_isobject(f->display_sv))? f->display_sv
        : &PL_sv_undef;
}

/* Write-accessor for the $obj->display attribute */
extern void PerlXlib_objref_set_display(SV *objref, SV *dpy_sv) {
    struct PerlXlib_fields *f;
    if (!sv_isobject(objref))
        croak("Not an object");
    f= PerlXlib_get_magic_fields(SvRV(objref), AUTOCREATE);
    if (dpy_sv && sv_isobject(dpy_sv)) { /* being assigned */
        if (f->display_sv) sv_setsv(f->display_sv, dpy_sv);
        else f->display_sv= newSVsv(dpy_sv);
    }
    else if (f->display_sv) { /* being unset */
        sv_2mortal(f->display_sv);
        f->display_sv= NULL;
    }
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
        if (SvREFCNT(dpy_sv) != 1) croak("Refcnt of %%_connections member is %d", SvREFCNT(dpy_sv));
        if (!SvROK(dpy_sv) || !SvWEAKREF(dpy_sv)) croak("%%_connections member is not a weakref");
        if (!sv_derived_from(dpy_sv, "X11::Xlib")) croak("%%_connections contains non-X11::Xlib object");
        dpy= PerlXlib_display_objref_get_pointer(dpy_sv, OR_DIE);
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
                    : PerlXlib_objref_get_pointer(obj_sv, NULL, OR_DIE);
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
    char* buf;
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
                    croak("Can't coerce %.*s to %s %s", (int) n, buf, pkg, lvalue? "lvalue":"rvalue");
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
            croak("Can't coerce %.*s to %s %s", (int) n, buf, pkg, lvalue? "lvalue":"rvalue");
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
        croak("Scalars used as %s must be at least length %d (got %d)", pkg, (int) struct_size, (int) SvCUR(sv));
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
    PUSHs(PerlXlib_get_display_objref(d, OR_UNDEF));
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
      if (fp && *fp) { s->xany.display= PerlXlib_display_objref_get_pointer(*fp, PerlXlib_OR_NULL);; if (consume) hv_delete(fields, "display", 7, G_DISCARD); }
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
      if (fp && *fp) { s->xerror.display= PerlXlib_display_objref_get_pointer(*fp, PerlXlib_OR_NULL);; if (consume) hv_delete(fields, "display", 7, G_DISCARD); }
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
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(char)*20)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(char)*20), (long) SvCUR(*fp)); memcpy(s->xclient.data.b, SvPVX(*fp), sizeof(char)*20);}; if (consume) hv_delete(fields, "b", 1, G_DISCARD); }
      fp= hv_fetch(fields, "l", 1, 0);
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(long)*5)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(long)*5), (long) SvCUR(*fp)); memcpy(s->xclient.data.l, SvPVX(*fp), sizeof(long)*5);}; if (consume) hv_delete(fields, "l", 1, G_DISCARD); }
      fp= hv_fetch(fields, "s", 1, 0);
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(short)*10)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(short)*10), (long) SvCUR(*fp)); memcpy(s->xclient.data.s, SvPVX(*fp), sizeof(short)*10);}; if (consume) hv_delete(fields, "s", 1, G_DISCARD); }
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
      if (fp && *fp) { { if (!SvPOK(*fp) || SvCUR(*fp) != sizeof(char)*32)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(char)*32), (long) SvCUR(*fp)); memcpy(s->xkeymap.key_vector, SvPVX(*fp), sizeof(char)*32);}; if (consume) hv_delete(fields, "key_vector", 10, G_DISCARD); }
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
      if (!hv_store(fields, "display"   ,  7, (sv=newSVsv(PerlXlib_get_display_objref(s->xany.display, PerlXlib_AUTOCREATE))), 0)) goto store_fail;
      if (!hv_store(fields, "send_event", 10, (sv=newSViv(s->xany.send_event)), 0)) goto store_fail;
      if (!hv_store(fields, "serial"    ,  6, (sv=newSVuv(s->xany.serial)), 0)) goto store_fail;
      if (!hv_store(fields, "type"      ,  4, (sv=newSViv(s->xany.type)), 0)) goto store_fail;
    }
    else {
      if (!hv_store(fields, "display"   ,  7, (sv=newSVsv(PerlXlib_get_display_objref(s->xerror.display, PerlXlib_AUTOCREATE))), 0)) goto store_fail;
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
    if (fp && *fp) { s->visual= (Visual *) PerlXlib_objref_get_pointer(*fp, "Visual", PerlXlib_OR_NULL); if (consume) hv_delete(fields, "visual", 6, G_DISCARD); }

    fp= hv_fetch(fields, "visualid", 8, 0);
    if (fp && *fp) { s->visualid= SvUV(*fp); if (consume) hv_delete(fields, "visualid", 8, G_DISCARD); }
}

void PerlXlib_XVisualInfo_unpack_obj(XVisualInfo *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
    SV *dpy_sv= PerlXlib_objref_get_display(obj_ref);
    Display *dpy= PerlXlib_display_objref_get_pointer(dpy_sv, PerlXlib_OR_NULL);
    if (!hv_store(fields, "bits_per_rgb", 12, (sv=newSViv(s->bits_per_rgb)), 0)) goto store_fail;
    if (!hv_store(fields, "blue_mask" ,  9, (sv=newSVuv(s->blue_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "class"     ,  5, (sv=newSViv(s->class)), 0)) goto store_fail;
    if (!hv_store(fields, "colormap_size", 13, (sv=newSViv(s->colormap_size)), 0)) goto store_fail;
    if (!hv_store(fields, "depth"     ,  5, (sv=newSViv(s->depth)), 0)) goto store_fail;
    if (!hv_store(fields, "green_mask", 10, (sv=newSVuv(s->green_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "red_mask"  ,  8, (sv=newSVuv(s->red_mask)), 0)) goto store_fail;
    if (!hv_store(fields, "screen"    ,  6, (sv=newSViv(s->screen)), 0)) goto store_fail;
    if (!hv_store(fields, "visual"    ,  6, (sv=newSVsv(PerlXlib_get_objref(s->visual, PerlXlib_AUTOCREATE, "Visual", SVt_PVMG, "X11::Xlib::Visual", dpy))), 0)) goto store_fail;
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

void PerlXlib_XWindowChanges_unpack_obj(XWindowChanges *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
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
    if (fp && *fp) { s->screen= PerlXlib_screen_objref_get_pointer(*fp, PerlXlib_OR_NULL); if (consume) hv_delete(fields, "screen", 6, G_DISCARD); }

    fp= hv_fetch(fields, "visual", 6, 0);
    if (fp && *fp) { s->visual= (Visual *) PerlXlib_objref_get_pointer(*fp, "Visual", PerlXlib_OR_NULL); if (consume) hv_delete(fields, "visual", 6, G_DISCARD); }

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

void PerlXlib_XWindowAttributes_unpack_obj(XWindowAttributes *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
    Display *dpy= s->screen? DisplayOfScreen(s->screen) : NULL;
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
    if (!hv_store(fields, "screen"    ,  6, (sv=newSVsv(PerlXlib_get_screen_objref(s->screen, PerlXlib_OR_UNDEF))), 0)) goto store_fail;
    if (!hv_store(fields, "visual"    ,  6, (sv=newSVsv(PerlXlib_get_objref(s->visual, PerlXlib_AUTOCREATE, "Visual", SVt_PVMG, "X11::Xlib::Visual", dpy))), 0)) goto store_fail;
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

void PerlXlib_XSetWindowAttributes_unpack_obj(XSetWindowAttributes *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
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

void PerlXlib_XSizeHints_unpack_obj(XSizeHints *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
    if (s->flags & PBaseSize) { if (!hv_store(fields, "base_height", 11, (sv=newSViv(s->base_height)), 0)) goto store_fail; }
    if (s->flags & PBaseSize) { if (!hv_store(fields, "base_width", 10, (sv=newSViv(s->base_width)), 0)) goto store_fail; }
    if (!hv_store(fields, "flags"     ,  5, (sv=newSViv(s->flags)), 0)) goto store_fail;
    if (s->flags & PSize) { if (!hv_store(fields, "height"    ,  6, (sv=newSViv(s->height)), 0)) goto store_fail; }
    if (s->flags & PResizeInc) { if (!hv_store(fields, "height_inc", 10, (sv=newSViv(s->height_inc)), 0)) goto store_fail; }
    if (s->flags & PAspect) { if (!hv_store(fields, "max_aspect_x", 12, (sv=newSViv(s->max_aspect.x)), 0)) goto store_fail; }
    if (s->flags & PAspect) { if (!hv_store(fields, "max_aspect_y", 12, (sv=newSViv(s->max_aspect.y)), 0)) goto store_fail; }
    if (s->flags & PMaxSize) { if (!hv_store(fields, "max_height", 10, (sv=newSViv(s->max_height)), 0)) goto store_fail; }
    if (s->flags & PMaxSize) { if (!hv_store(fields, "max_width" ,  9, (sv=newSViv(s->max_width)), 0)) goto store_fail; }
    if (s->flags & PAspect) { if (!hv_store(fields, "min_aspect_x", 12, (sv=newSViv(s->min_aspect.x)), 0)) goto store_fail; }
    if (s->flags & PAspect) { if (!hv_store(fields, "min_aspect_y", 12, (sv=newSViv(s->min_aspect.y)), 0)) goto store_fail; }
    if (s->flags & PMinSize) { if (!hv_store(fields, "min_height", 10, (sv=newSViv(s->min_height)), 0)) goto store_fail; }
    if (s->flags & PMinSize) { if (!hv_store(fields, "min_width" ,  9, (sv=newSViv(s->min_width)), 0)) goto store_fail; }
    if (s->flags & PSize) { if (!hv_store(fields, "width"     ,  5, (sv=newSViv(s->width)), 0)) goto store_fail; }
    if (s->flags & PResizeInc) { if (!hv_store(fields, "width_inc" ,  9, (sv=newSViv(s->width_inc)), 0)) goto store_fail; }
    if (s->flags & PWinGravity) { if (!hv_store(fields, "win_gravity", 11, (sv=newSViv(s->win_gravity)), 0)) goto store_fail; }
    if (s->flags & PPosition) { if (!hv_store(fields, "x"         ,  1, (sv=newSViv(s->x)), 0)) goto store_fail; }
    if (s->flags & PPosition) { if (!hv_store(fields, "y"         ,  1, (sv=newSViv(s->y)), 0)) goto store_fail; }
    return;
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

void PerlXlib_XRectangle_unpack_obj(XRectangle *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
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

void PerlXlib_XRenderPictFormat_unpack_obj(XRenderPictFormat *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
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
/*--------------------------------------------------------------------------*/

/* provide these exports for back-compat */
extern void PerlXlib_XVisualInfo_unpack(XVisualInfo *s, HV *fields) {
    PerlXlib_XVisualInfo_unpack_obj(s, fields, NULL);
}
extern void PerlXlib_XWindowChanges_unpack(XWindowChanges *s, HV *fields) {
    PerlXlib_XWindowChanges_unpack_obj(s, fields, NULL);
}
extern void PerlXlib_XWindowAttributes_unpack(XWindowAttributes *s, HV *fields) {
    PerlXlib_XWindowAttributes_unpack_obj(s, fields, NULL);
}
extern void PerlXlib_XSetWindowAttributes_unpack(XSetWindowAttributes *s, HV *fields) {
    PerlXlib_XSetWindowAttributes_unpack_obj(s, fields, NULL);
}
extern void PerlXlib_XSizeHints_unpack(XSizeHints *s, HV *fields) {
    PerlXlib_XSizeHints_unpack_obj(s, fields, NULL);
}
extern void PerlXlib_XRectangle_unpack(XRectangle *s, HV *fields) {
    PerlXlib_XRectangle_unpack_obj(s, fields, NULL);
}
extern void PerlXlib_XRenderPictFormat_unpack(XRenderPictFormat *s, HV *fields) {
    PerlXlib_XRenderPictFormat_unpack_obj(s, fields, NULL);
}
extern Display * PerlXlib_get_magic_dpy(SV *objref, Bool not_null) {
    return PerlXlib_display_objref_get_pointer(objref, not_null? OR_DIE : OR_NULL);
}
extern SV * PerlXlib_set_magic_dpy(SV *objref, Display *dpy) {
    PerlXlib_objref_set_pointer(objref, dpy, T_DISPLAY);
    return objref;
}
extern SV * PerlXlib_obj_for_display(Display *dpy, int create) {
    return PerlXlib_get_display_objref(dpy, create? AUTOCREATE : OR_NULL);
}
extern void * PerlXlib_get_magic_dpy_innerptr(SV *objref, Bool not_null) {
    return PerlXlib_objref_get_pointer(objref, NULL, not_null? OR_DIE : OR_NULL);
}
extern SV * PerlXlib_set_magic_dpy_innerptr(SV *objref, void *opaque) {
    PerlXlib_objref_set_pointer(objref, opaque, NULL);
    return objref;
}
extern void * PerlXlib_sv_to_display_innerptr(SV *sv, bool not_null) {
    return PerlXlib_objref_get_pointer(sv, NULL, not_null? OR_DIE : OR_NULL);
}
extern SV * PerlXlib_obj_for_display_innerptr(Display *dpy, void *thing, const char *thing_class, int objsvtype, bool create) {
    return PerlXlib_get_objref(thing, create? AUTOCREATE : OR_UNDEF, thing_class, objsvtype, thing_class, dpy);
}
extern SV * PerlXlib_get_displayobj_of_opaque(void *opaque) {
    SV *obj= PerlXlib_get_objref(opaque, OR_DIE, NULL, 0, NULL, NULL);
    return PerlXlib_objref_get_display(obj);
}
extern void PerlXlib_set_displayobj_of_opaque(void *opaque, SV *dpy_sv) {
    SV *obj= PerlXlib_get_objref(opaque, OR_DIE, NULL, 0, NULL, NULL);
    return PerlXlib_objref_set_pointer(obj, dpy_sv, T_DISPLAY);
}
extern SV * PerlXlib_obj_for_screen(Screen *screen) {
    return PerlXlib_get_screen_objref(screen, OR_UNDEF);
}
extern Screen * PerlXlib_sv_to_screen(SV *sv, bool not_null) {
    return PerlXlib_screen_objref_get_pointer(sv, not_null? OR_DIE : OR_NULL);
}
