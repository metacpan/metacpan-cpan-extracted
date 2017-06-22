/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2011-2017 -- leonerd@leonerd.org.uk
 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tickit.h>
#include <tickit-termdrv.h>
#include <tickit-mockterm.h>

#define streq(a,b) (strcmp(a,b)==0)

// UVs also have the IOK flag set
#define SvIsNumeric(sv) (SvFLAGS(sv) & (SVp_IOK|SVp_NOK))

// back-compat for 5.10.0 since it's easy
#ifndef mPUSHs
#  define mPUSHs(sv)  PUSHs(sv_2mortal(sv))
#endif

static SV *newSVivpv(int iv, const char *pv)
{
  SV *sv = newSViv(iv);
  if(pv) { sv_setpv(sv, pv); SvPOK_on(sv); }
  return sv;
}

static SV *tickit_ev2sv(TickitEventType ev)
{
  const char *name = NULL;
  switch(ev) {
    case TICKIT_EV_CHANGE:     name = "change";     break;
    case TICKIT_EV_EXPOSE:     name = "expose";     break;
    case TICKIT_EV_FOCUS:      name = "focus";      break;
    case TICKIT_EV_GEOMCHANGE: name = "geomchange"; break;
    case TICKIT_EV_KEY:        name = "key";        break;
    case TICKIT_EV_MOUSE:      name = "mouse";      break;
    case TICKIT_EV_RESIZE:     name = "resize";     break;
  }
  return newSVivpv(ev, name);
}

static TickitEventType tickit_name2ev(const char *name)
{
  switch(name[0]) {
    case 'c':
      return streq(name+1, "hange") ? TICKIT_EV_CHANGE
                                    : -1;
    case 'e':
      return streq(name+1, "xpose") ? TICKIT_EV_EXPOSE
                                    : -1;
    case 'f':
      return streq(name+1, "ocus") ? TICKIT_EV_FOCUS
                                   : -1;
    case 'g':
      return streq(name+1, "eomchange") ? TICKIT_EV_GEOMCHANGE
                                        : -1;
    case 'k':
      return streq(name+1, "ey") ? TICKIT_EV_KEY
                                 : -1;
    case 'm':
      return streq(name+1, "ouse") ? TICKIT_EV_MOUSE
                                   : -1;
    case 'r':
      return streq(name+1, "esize") ? TICKIT_EV_RESIZE
                                    : -1;
  }
  return -1;
}

static SV *tickit_focusevtype2sv(TickitFocusEventType type)
{
  const char *name = NULL;
  switch(type) {
    case TICKIT_FOCUSEV_IN:  name = "in";  break;
    case TICKIT_FOCUSEV_OUT: name = "out"; break;
  }
  return newSVivpv(type, name);
}

static TickitFocusEventType tickit_name2focusev(const char *name)
{
  switch(name[0]) {
    case 'i':
      return streq(name+1, "n") ? TICKIT_FOCUSEV_IN
                                : -1;
    case 'o':
      return streq(name+1, "ut") ? TICKIT_FOCUSEV_OUT
                                 : -1;
  }
  return -1;
}

static SV *tickit_keyevtype2sv(int type)
{
  const char *name = NULL;
  switch(type) {
    case TICKIT_KEYEV_KEY:  name = "key";  break;
    case TICKIT_KEYEV_TEXT: name = "text"; break;
  }
  return newSVivpv(type, name);
}

static TickitKeyEventType tickit_name2keyev(const char *name)
{
  switch(name[0]) {
    case 'k':
      return streq(name+1, "ey") ? TICKIT_KEYEV_KEY
                                 : -1;
    case 't':
      return streq(name+1, "ext") ? TICKIT_KEYEV_TEXT
                                  : -1;
  }
  return -1;
}

static SV *tickit_mouseevtype2sv(int type)
{
  const char *name = NULL;
  switch(type) {
    case TICKIT_MOUSEEV_PRESS:   name = "press";   break;
    case TICKIT_MOUSEEV_DRAG:    name = "drag";    break;
    case TICKIT_MOUSEEV_RELEASE: name = "release"; break;
    case TICKIT_MOUSEEV_WHEEL:   name = "wheel";   break;

    case TICKIT_MOUSEEV_DRAG_START:   name = "drag_start";   break;
    case TICKIT_MOUSEEV_DRAG_DROP:    name = "drag_drop";    break;
    case TICKIT_MOUSEEV_DRAG_STOP:    name = "drag_stop";    break;
    case TICKIT_MOUSEEV_DRAG_OUTSIDE: name = "drag_outside"; break;
  }
  return newSVivpv(type, name);
}

static TickitMouseEventType tickit_name2mouseev(const char *name)
{
  switch(name[0]) {
    case 'd':
      return streq(name+1, "rag")         ? TICKIT_MOUSEEV_DRAG
           : streq(name+1, "rag_start")   ? TICKIT_MOUSEEV_DRAG_START
           : streq(name+1, "rag_drop")    ? TICKIT_MOUSEEV_DRAG_DROP
           : streq(name+1, "rag_stop")    ? TICKIT_MOUSEEV_DRAG_STOP
           : streq(name+1, "rag_outside") ? TICKIT_MOUSEEV_DRAG_OUTSIDE
                                          : -1;
    case 'p':
      return streq(name+1, "ress") ? TICKIT_MOUSEEV_PRESS
                                   : -1;
    case 'r':
      return streq(name+1, "elease") ? TICKIT_MOUSEEV_RELEASE
                                     : -1;
    case 'w':
      return streq(name+1, "heel") ? TICKIT_MOUSEEV_WHEEL
                                   : -1;
  }
  return -1;
}

static SV *tickit_mouseevbutton2sv(int type, int button)
{
  const char *name = NULL;
  if(type == TICKIT_MOUSEEV_WHEEL)
    switch(button) {
      case TICKIT_MOUSEWHEEL_UP:   name = "up";   break;
      case TICKIT_MOUSEWHEEL_DOWN: name = "down"; break;
    }
  return newSVivpv(button, name);
}

static int tickit_name2mousewheel(const char *name)
{
  switch(name[0]) {
    case 'd':
      return streq(name+1, "own") ? TICKIT_MOUSEWHEEL_DOWN
                                  : -1;
    case 'u':
      return streq(name+1, "p") ? TICKIT_MOUSEWHEEL_UP
                                : -1;
  }
  return -1;
}

struct GenericEventData
{
  SV *self;
  CV *code;
  SV *data;
};

typedef TickitKeyEventInfo   *Tickit__Event__Key;
typedef TickitMouseEventInfo *Tickit__Event__Mouse;

/***************
 * Tickit::Pen *
 ***************/

typedef TickitPen *Tickit__Pen;

static SV *newSVpen_noinc(TickitPen *pen, char *package)
{
  SV *sv = newSV(0);
  sv_setref_pv(sv, package ? package : "Tickit::Pen::Immutable", pen);

  return sv;
}

static SV *newSVpen(TickitPen *pen, char *package)
{
  return newSVpen_noinc(tickit_pen_ref(pen), package);
}

static SV *pen_get_attr(TickitPen *pen, TickitPenAttr attr)
{
  switch(tickit_pen_attrtype(attr)) {
  case TICKIT_PENTYPE_BOOL:
    return tickit_pen_get_bool_attr(pen, attr) ? &PL_sv_yes : &PL_sv_no;
  case TICKIT_PENTYPE_INT:
    return newSViv(tickit_pen_get_int_attr(pen, attr));
  case TICKIT_PENTYPE_COLOUR:
    return newSViv(tickit_pen_get_colour_attr(pen, attr));
  }
}

static void pen_set_attr(TickitPen *pen, TickitPenAttr attr, SV *val)
{
  switch(tickit_pen_attrtype(attr)) {
  case TICKIT_PENTYPE_INT:
    tickit_pen_set_int_attr(pen, attr, SvOK(val) ? SvIV(val) : -1);
    break;
  case TICKIT_PENTYPE_BOOL:
    tickit_pen_set_bool_attr(pen, attr, SvOK(val) ? SvIV(val) : 0);
    break;
  case TICKIT_PENTYPE_COLOUR:
    if(!SvPOK(val) && SvIsNumeric(val))
      tickit_pen_set_colour_attr(pen, attr, SvIV(val));
    else if(SvPOK(val))
      tickit_pen_set_colour_attr_desc(pen, attr, SvPV_nolen(val));
    else
      tickit_pen_set_colour_attr(pen, attr, -1);
    break;
  }
}

static TickitPen *pen_from_args(SV **args, int argcount)
{
  int i;
  TickitPen *pen = tickit_pen_new();

  for(i = 0; i < argcount; i += 2) {
    const char *name  = SvPV_nolen(args[i]);
    SV         *value = args[i+1];

    TickitPenAttr attr = tickit_pen_lookup_attr(name);
    if(attr != -1)
      pen_set_attr(pen, attr, value);
  }

  return pen;
}

static void pen_set_attrs(TickitPen *pen, HV *attrs)
{
  TickitPenAttr a;
  for(a = 0; a < TICKIT_N_PEN_ATTRS; a++) {
    const char *name = tickit_pen_attrname(a);
    SV *val = hv_delete(attrs, name, strlen(name), 0);
    if(!val)
      continue;

    if(!SvOK(val))
      tickit_pen_clear_attr(pen, a);
    else
      pen_set_attr(pen, a, val);
  }
}

/****************
 * Tickit::Rect *
 ****************/

typedef TickitRect *Tickit__Rect, *Tickit__Rect_MAYBE;

/* Really cheating and treading on Perl's namespace but hopefully it will be OK */
static SV *newSVrect(TickitRect *rect)
{
  TickitRect *self;
  Newx(self, 1, TickitRect);
  *self = *rect;
  return sv_setref_pv(newSV(0), "Tickit::Rect", self);
}
#define mPUSHrect(rect) PUSHs(sv_2mortal(newSVrect(rect)))

/*******************
 * Tickit::RectSet *
 *******************/

typedef TickitRectSet *Tickit__RectSet;

/************************
 * Tickit::RenderBuffer *
 ************************/

typedef TickitRenderBuffer *Tickit__RenderBuffer;

static SV *newSVrb_noinc(TickitRenderBuffer *rb)
{
  SV *sv = newSV(0);
  sv_setref_pv(sv, "Tickit::RenderBuffer", rb);

  return sv;
}

static SV *newSVrb(TickitRenderBuffer *rb)
{
  return newSVrb_noinc(tickit_renderbuffer_ref(rb));
}

/****************
 * Tickit::Term *
 ****************/

typedef TickitTerm *Tickit__Term;

static TickitTermCtl term_name2ctl(const char *name)
{
  switch(name[0]) {
    case 'a':
      return streq(name+1, "ltscreen") ? TICKIT_TERMCTL_ALTSCREEN
                                       : -1;
    case 'c':
      return streq(name+1, "olors")      ? TICKIT_TERMCTL_COLORS
           : streq(name+1, "ursorblink") ? TICKIT_TERMCTL_CURSORBLINK
           : streq(name+1, "ursorshape") ? TICKIT_TERMCTL_CURSORSHAPE
           : streq(name+1, "ursorvis")   ? TICKIT_TERMCTL_CURSORVIS
                                         : -1;
    case 'i':
      return streq(name+1, "con_text")      ? TICKIT_TERMCTL_ICON_TEXT
           : streq(name+1, "contitle_text") ? TICKIT_TERMCTL_ICONTITLE_TEXT
                                            : -1;
    case 'k':
      return streq(name+1, "eypad_app") ? TICKIT_TERMCTL_KEYPAD_APP
                                        : -1;
    case 'm':
      return streq(name+1, "ouse") ? TICKIT_TERMCTL_MOUSE
                                       : -1;
    case 't':
      return streq(name+1, "itle_text") ? TICKIT_TERMCTL_TITLE_TEXT
                                        : -1;
  }
  return -1;
}

static int term_userevent_fn(TickitTerm *tt, TickitEventType ev, void *_info, void *user)
{
  struct GenericEventData *data = user;

  int ret = 0;

  if(ev & ~(TICKIT_EV_UNBIND|TICKIT_EV_DESTROY)) {
    SV *info_sv = newSV(0);

    switch(ev) {
      case TICKIT_EV_KEY: {
        TickitKeyEventInfo *info = _info, *self;
        Newx(self, 1, TickitKeyEventInfo);
        *self = *info;
        self->str = savepv(info->str);

        sv_setref_pv(info_sv, "Tickit::Event::Key", self);
        break;
      }

      case TICKIT_EV_MOUSE: {
        TickitMouseEventInfo *info = _info, *self;
        Newx(self, 1, TickitMouseEventInfo);
        *self = *info;

        sv_setref_pv(info_sv, "Tickit::Event::Mouse", self);
        break;
      }

      case TICKIT_EV_RESIZE: {
        TickitResizeEventInfo *info = _info, *self;
        Newx(self, 1, TickitResizeEventInfo);
        *self = *info;

        sv_setref_pv(info_sv, "Tickit::Event::Resize", self);
        break;
      }

      // These don't happen to terminal
      case TICKIT_EV_CHANGE:
        SvREFCNT_dec(info_sv);
        return 0;
    }

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 4);
    mPUSHs(newSVsv(data->self));
    mPUSHs(tickit_ev2sv(ev));
    mPUSHs(info_sv);
    mPUSHs(newSVsv(data->data));
    PUTBACK;

    call_sv((SV*)(data->code), G_SCALAR);

    SPAGAIN;

    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  if(ev & TICKIT_EV_UNBIND) {
    SvREFCNT_dec(data->self);
    SvREFCNT_dec(data->code);
    SvREFCNT_dec(data->data);
    Safefree(data);

    ret = 1;
  }

  return ret;
}

static void term_output_fn(TickitTerm *tt, const char *bytes, size_t len, void *user)
{
  CV *func = user;

  if(!len) {
    SvREFCNT_dec(func);
    return;
  }

  dSP;
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  mPUSHp(bytes, len);
  PUTBACK;

  call_sv((SV*)(func), G_VOID);

  FREETMPS;
  LEAVE;
}

static SV *newSVterm_noinc(TickitTerm *tt, char *package)
{
  SV *sv = newSV(0);
  sv_setref_pv(sv, package, tt);

  return sv;
}

static SV *newSVterm(TickitTerm *tt, char *package)
{
  return newSVterm_noinc(tickit_term_ref(tt), package);
}

/*********************
 * Tickit::StringPos *
 *********************/

typedef TickitStringPos *Tickit__StringPos;

static Tickit__StringPos new_stringpos(SV **svp)
{
  TickitStringPos *pos;

  Newx(pos, 1, TickitStringPos);
  *svp = newSV(0);
  sv_setref_pv(*svp, "Tickit::StringPos", pos);

  return pos;
}

/******************
 * Tickit::Window *
 ******************/

typedef struct Tickit__Window {
  TickitWindow *win;
  SV           *tickit;
} *Tickit__Window;

/*
 * We want to wrap every TickitWindow* instance in theabove structure. But we
 * can't necessarily always do that at construction time, because we don't
 * necessarily construct all windows. Plus how would we find the structure
 * wrapping related windows - t_w_root(), _parent(), etc...
 */
static HV *sv_for_window;

static int window_destroyed(TickitWindow *win, TickitEventType ev, void *info, void *user)
{
  SV *key = newSViv(PTR2UV(win));
  hv_delete_ent(sv_for_window, key, G_DISCARD, 0);
  SvREFCNT_dec(key);
}

static SV *newSVwin_noinc(TickitWindow *win)
{
  if(!sv_for_window)
    sv_for_window = newHV();

  SV *key = newSViv(PTR2UV(win));
  HE *he = hv_fetch_ent(sv_for_window, key, 1, 0);
  SvREFCNT_dec(key);

  if(SvOK(HeVAL(he)))
    return newSVsv(HeVAL(he));

  struct Tickit__Window *self;
  Newx(self, 1, struct Tickit__Window);
  sv_setref_pv(HeVAL(he), "Tickit::Window", self);

  self->win = win;
  self->tickit = NULL;

  tickit_window_bind_event(win, TICKIT_EV_DESTROY, 0, &window_destroyed, NULL);

  SV *ret = newSVsv(HeVAL(he));
  sv_rvweaken(HeVAL(he));

  return ret;
}

static SV *newSVwin(TickitWindow *win)
{
  return newSVwin_noinc(tickit_window_ref(win));
}

static int window_userevent_fn(TickitWindow *win, TickitEventType ev, void *_info, void *user)
{
  struct GenericEventData *data = user;

  int ret = 0;

  if(ev & ~(TICKIT_EV_UNBIND|TICKIT_EV_DESTROY)) {
    SV *info_sv = newSV(0);

    switch(ev) {
      case TICKIT_EV_EXPOSE: {
        TickitExposeEventInfo *info = _info, *self;
        Newx(self, 1, TickitExposeEventInfo);
        *self = *info;
        self->rb = tickit_renderbuffer_ref(info->rb);

        sv_setref_pv(info_sv, "Tickit::Event::Expose", self);
        break;
      }

      case TICKIT_EV_FOCUS: {
        TickitFocusEventInfo *info = _info, *self;
        Newx(self, 1, TickitFocusEventInfo);
        *self = *info;
        self->win = tickit_window_ref(info->win);

        sv_setref_pv(info_sv, "Tickit::Event::Focus", self);
        break;
      }

      case TICKIT_EV_KEY: {
        TickitKeyEventInfo *info = _info, *self;
        Newx(self, 1, TickitKeyEventInfo);
        *self = *info;
        self->str = savepv(info->str);

        sv_setref_pv(info_sv, "Tickit::Event::Key", self);
        break;
      }

      case TICKIT_EV_MOUSE: {
        TickitMouseEventInfo *info = _info, *self;
        Newx(self, 1, TickitMouseEventInfo);
        *self = *info;

        sv_setref_pv(info_sv, "Tickit::Event::Mouse", self);
        break;
      }

      // These don't happen to terminal
      case TICKIT_EV_CHANGE:
      case TICKIT_EV_RESIZE:
        SvREFCNT_dec(info_sv);
        return 0;
    }

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 4);
    mPUSHs(newSVsv(data->self));
    mPUSHs(tickit_ev2sv(ev));
    mPUSHs(info_sv);
    mPUSHs(newSVsv(data->data));
    PUTBACK;

    call_sv((SV*)(data->code), G_SCALAR);

    SPAGAIN;

    SV *retsv = POPs;
    ret = SvOK(retsv) ? SvIV(retsv) : 0;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  if(ev & TICKIT_EV_UNBIND) {
    SvREFCNT_dec(data->self);
    SvREFCNT_dec(data->code);
    SvREFCNT_dec(data->data);
    Safefree(data);

    ret = 1;
  }

  return ret;
}

static void setup_constants(void)
{
  HV *stash;
  AV *export;

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c+7, newSViv(c)); \
  av_push(export, newSVpv(#c+7, 0));

  stash = gv_stashpvn("Tickit::Term", 12, TRUE);
  export = get_av("Tickit::Term::EXPORT_OK", TRUE);

  DO_CONSTANT(TICKIT_TERMCTL_ALTSCREEN)
  DO_CONSTANT(TICKIT_TERMCTL_CURSORVIS)
  DO_CONSTANT(TICKIT_TERMCTL_CURSORBLINK)
  DO_CONSTANT(TICKIT_TERMCTL_CURSORSHAPE)
  DO_CONSTANT(TICKIT_TERMCTL_ICON_TEXT)
  DO_CONSTANT(TICKIT_TERMCTL_ICONTITLE_TEXT)
  DO_CONSTANT(TICKIT_TERMCTL_KEYPAD_APP)
  DO_CONSTANT(TICKIT_TERMCTL_MOUSE)
  DO_CONSTANT(TICKIT_TERMCTL_TITLE_TEXT)
  DO_CONSTANT(TICKIT_TERMCTL_COLORS)

  DO_CONSTANT(TICKIT_CURSORSHAPE_BLOCK)
  DO_CONSTANT(TICKIT_CURSORSHAPE_UNDER)
  DO_CONSTANT(TICKIT_CURSORSHAPE_LEFT_BAR)

  DO_CONSTANT(TICKIT_TERM_MOUSEMODE_OFF)
  DO_CONSTANT(TICKIT_TERM_MOUSEMODE_CLICK)
  DO_CONSTANT(TICKIT_TERM_MOUSEMODE_DRAG)
  DO_CONSTANT(TICKIT_TERM_MOUSEMODE_MOVE)

  DO_CONSTANT(TICKIT_MOD_SHIFT)
  DO_CONSTANT(TICKIT_MOD_ALT)
  DO_CONSTANT(TICKIT_MOD_CTRL)

  DO_CONSTANT(TICKIT_BIND_FIRST)

  stash = gv_stashpvn("Tickit::Window", 14, TRUE);
  export = get_av("Tickit::Window::EXPORT_OK", TRUE);

  DO_CONSTANT(TICKIT_WINDOW_HIDDEN);
  DO_CONSTANT(TICKIT_WINDOW_LOWEST);
  DO_CONSTANT(TICKIT_WINDOW_ROOT_PARENT);
  DO_CONSTANT(TICKIT_WINDOW_STEAL_INPUT);
  DO_CONSTANT(TICKIT_WINDOW_POPUP);
}

MODULE = Tickit             PACKAGE = Tickit::Debug

bool
_enabled()
  CODE:
    RETVAL = tickit_debug_enabled;
  OUTPUT:
    RETVAL

void
_log(flag, message)
  char *flag
  char *message
  CODE:
    tickit_debug_logf(flag, "%s", message);

MODULE = Tickit             PACKAGE = Tickit::Event::Expose

SV *
_new(package,rb,rect)
  char                 *package
  Tickit::RenderBuffer  rb
  Tickit::Rect          rect
  INIT:
    TickitExposeEventInfo *info;
  CODE:
    Newx(info, 1, TickitExposeEventInfo);
    info->rb   = tickit_renderbuffer_ref(rb);
    info->rect = *rect;

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, package, info);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  SV *self
  INIT:
    TickitExposeEventInfo *info = INT2PTR(TickitExposeEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    tickit_renderbuffer_unref(info->rb);
    Safefree(info);

SV *
rb(self)
  SV *self
  ALIAS:
    rb   = 0
    rect = 1
  INIT:
    TickitExposeEventInfo *info = INT2PTR(TickitExposeEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    switch(ix) {
      case 0: RETVAL = newSVrb(info->rb); break;
      case 1: RETVAL = newSVrect(&info->rect); break;
    }
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Event::Focus

SV *
_new(package,type,win)
  char *package
  SV   *type
  SV   *win
  INIT:
    TickitFocusEventInfo *info;
  CODE:
    Newx(info, 1, TickitFocusEventInfo);
    if(SvPOK(type)) {
      info->type = tickit_name2focusev(SvPV_nolen(type));
      if(info->type == -1)
        croak("Unrecognised focus event type '%s'", type);
    }
    else
      info->type = SvTRUE(type) ? TICKIT_FOCUSEV_IN : TICKIT_FOCUSEV_OUT;

    if(win && SvOK(win))
      info->win  = tickit_window_ref(
        (INT2PTR(Tickit__Window, SvIV((SV*)SvRV(win))))->win
      );
    else
      info->win = NULL;

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, package, info);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  SV *self
  INIT:
    TickitFocusEventInfo *info = INT2PTR(TickitFocusEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    if(info->win)
      tickit_window_unref(info->win);
    Safefree(info);

SV *
type(self,newapi=&PL_sv_undef)
  SV *self
  SV *newapi
  ALIAS:
    type = 0
    win  = 1
  INIT:
    TickitFocusEventInfo *info = INT2PTR(TickitFocusEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    // Deprecated API gave simple 0=out, 1=in
    if(ix == 0 && !SvTRUE(newapi)) {
      Perl_ck_warner(aTHX_ packWARN(WARN_DEPRECATED),
        "Old boolean-returning $info->type API is deprecated");
      ix = 2;
    }

    switch(ix) {
      case 0: RETVAL = tickit_focusevtype2sv(info->type); break;
      case 1: RETVAL = newSVwin(tickit_window_ref(info->win)); break;
      case 2: RETVAL = newSViv(info->type == TICKIT_FOCUSEV_IN); break;
    }
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Event::Key

SV *
_new(package,type,str,mod=0)
  char *package
  char *type
  char *str
  int   mod
  INIT:
    TickitKeyEventInfo *info;
  CODE:
    Newx(info, 1, TickitKeyEventInfo);

    info->type = tickit_name2keyev(type);
    if(info->type == -1)
      croak("Unrecognised key event type '%s'", type);

    info->str  = savepv(str);
    info->mod  = mod;

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, package, info);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  SV *self
  INIT:
    TickitKeyEventInfo *info = INT2PTR(TickitKeyEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    Safefree(info->str);
    Safefree(info);

SV *
type(self)
  SV *self
  ALIAS:
    type = 0
    str  = 1
    mod  = 2
  INIT:
    TickitKeyEventInfo *info = INT2PTR(TickitKeyEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    switch(ix) {
      case 0: RETVAL = tickit_keyevtype2sv(info->type); break;
      case 1: RETVAL = newSVpvn_utf8(info->str, strlen(info->str), 1); break;
      case 2: RETVAL = newSViv(info->mod); break;
    }
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Event::Mouse

SV *
_new(package,type,button,line,col,mod=0)
  char *package
  char *type
  SV   *button
  int   line
  int   col
  int   mod
  INIT:
    TickitMouseEventInfo *info;
  CODE:
    Newx(info, 1, TickitMouseEventInfo);

    info->type = tickit_name2mouseev(type);
    if(info->type == -1)
      croak("Unrecognised mouse event type '%s'", type);

    if(info->type == TICKIT_MOUSEEV_WHEEL) {
      info->button = tickit_name2mousewheel(SvPV_nolen(button));
      if(info->button == -1)
        croak("Unrecognised mouse wheel name '%s'", SvPV_nolen(button));
    }
    else
      info->button = SvIV(button);
    info->line = line;
    info->col  = col;
    info->mod  = mod;

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, package, info);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  SV *self
  CODE:
    Safefree(INT2PTR(void *, SvIV((SV*)SvRV(self))));

SV *
type(self)
  SV *self
  ALIAS:
    type   = 0
    button = 1
    line   = 2
    col    = 3
    mod    = 4
  INIT:
    TickitMouseEventInfo *info = INT2PTR(TickitMouseEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    switch(ix) {
      case 0: RETVAL = tickit_mouseevtype2sv(info->type); break;
      case 1: RETVAL = tickit_mouseevbutton2sv(info->type, info->button); break;
      case 2: RETVAL = newSViv(info->line); break;
      case 3: RETVAL = newSViv(info->col); break;
      case 4: RETVAL = newSViv(info->mod); break;
    }
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Event::Resize

void
DESTROY(self)
  SV *self
  CODE:
    Safefree(INT2PTR(void *, SvIV((SV*)SvRV(self))));

SV *
lines(self)
  SV *self
  ALIAS:
    lines = 0
    cols  = 1
  INIT:
    TickitResizeEventInfo *info = INT2PTR(TickitResizeEventInfo *, SvIV((SV*)SvRV(self)));
  CODE:
    switch(ix) {
      case 0: RETVAL = newSViv(info->lines); break;
      case 1: RETVAL = newSViv(info->cols);  break;
    }
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Pen

SV *
_new(package, attrs)
  char *package
  HV   *attrs
  INIT:
    Tickit__Pen  self;
    TickitPen   *pen;
  CODE:
    pen = tickit_pen_new();
    if(!pen)
      XSRETURN_UNDEF;

    pen_set_attrs(pen, attrs);

    RETVAL = newSVpen_noinc(pen, package);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::Pen self
  CODE:
    tickit_pen_unref(self);

bool
hasattr(self,attr)
  Tickit::Pen  self
  char        *attr
  INIT:
    TickitPenAttr a;
  CODE:
    if((a = tickit_pen_lookup_attr(attr)) == -1)
      XSRETURN_UNDEF;
    RETVAL = tickit_pen_has_attr(self, a);
  OUTPUT:
    RETVAL

SV *
getattr(self,attr)
  Tickit::Pen  self
  char        *attr
  INIT:
    TickitPenAttr a;
  CODE:
    if((a = tickit_pen_lookup_attr(attr)) == -1)
      XSRETURN_UNDEF;
    if(!tickit_pen_has_attr(self, a))
      XSRETURN_UNDEF;
    RETVAL = pen_get_attr(self, a);
  OUTPUT:
    RETVAL

void
getattrs(self)
  Tickit::Pen self
  INIT:
    TickitPenAttr a;
    int           count = 0;
  PPCODE:
    for(a = 0; a < TICKIT_N_PEN_ATTRS; a++) {
      if(!tickit_pen_has_attr(self, a))
        continue;

      EXTEND(SP, 2); count += 2;

      /* Because mPUSHp(str,0) creates a 0-length string */
      mPUSHs(newSVpv(tickit_pen_attrname(a), 0));
      mPUSHs(pen_get_attr(self, a));
    }
    XSRETURN(count);

bool
equiv_attr(self,other,attr)
  Tickit::Pen  self
  Tickit::Pen  other
  char        *attr
  INIT:
    TickitPenAttr a;
  CODE:
    if((a = tickit_pen_lookup_attr(attr)) == -1)
      XSRETURN_UNDEF;
    RETVAL = tickit_pen_equiv_attr(self, other, a);
  OUTPUT:
    RETVAL

bool
equiv(self,other)
  Tickit::Pen  self
  Tickit::Pen  other
  CODE:
    RETVAL = tickit_pen_equiv(self, other);
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Pen::Mutable

void
chattr(self,attr,value)
  Tickit::Pen  self
  char        *attr
  SV          *value
  INIT:
    TickitPenAttr a;
  CODE:
    if((a = tickit_pen_lookup_attr(attr)) == -1)
      XSRETURN_UNDEF;
    if(!SvOK(value)) {
      tickit_pen_clear_attr(self, a);
      XSRETURN_UNDEF;
    }
    pen_set_attr(self, a, value);

void
chattrs(self,attrs)
  Tickit::Pen  self
  HV          *attrs
  CODE:
    pen_set_attrs(self, attrs);

void
delattr(self,attr)
  Tickit::Pen  self
  char        *attr
  INIT:
    TickitPenAttr a;
  CODE:
    if((a = tickit_pen_lookup_attr(attr)) == -1)
      XSRETURN_UNDEF;
    tickit_pen_clear_attr(self, a);

void
copy(self,other,overwrite)
  Tickit::Pen self
  Tickit::Pen other
  int         overwrite
  CODE:
    tickit_pen_copy(self, other, overwrite);

MODULE = Tickit             PACKAGE = Tickit::Rect

Tickit::Rect
_new(package,top,left,lines,cols)
  char *package
  int top
  int left
  int lines
  int cols
  CODE:
    Newx(RETVAL, 1, TickitRect);
    tickit_rect_init_sized(RETVAL, top, left, lines, cols);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::Rect self
  CODE:
    Safefree(self);

Tickit::Rect
intersect(self,other)
  Tickit::Rect self
  Tickit::Rect other
  INIT:
    TickitRect ret;
  CODE:
    if(!tickit_rect_intersect(&ret, self, other))
      XSRETURN_UNDEF;

    Newx(RETVAL, 1, TickitRect);
    *RETVAL = ret;
  OUTPUT:
    RETVAL

Tickit::Rect
translate(self,downward,rightward)
  Tickit::Rect self
  int          downward
  int          rightward
  CODE:
    Newx(RETVAL, 1, TickitRect);
    tickit_rect_init_sized(RETVAL, self->top + downward, self->left + rightward,
      self->lines, self->cols);
  OUTPUT:
    RETVAL

int
top(self)
  Tickit::Rect self
  CODE:
    RETVAL = self->top;
  OUTPUT:
    RETVAL

int
left(self)
  Tickit::Rect self
  CODE:
    RETVAL = self->left;
  OUTPUT:
    RETVAL

int
lines(self)
  Tickit::Rect self
  CODE:
    RETVAL = self->lines;
  OUTPUT:
    RETVAL

int
cols(self)
  Tickit::Rect self
  CODE:
    RETVAL = self->cols;
  OUTPUT:
    RETVAL

int
bottom(self)
  Tickit::Rect self
  CODE:
    RETVAL = tickit_rect_bottom(self);
  OUTPUT:
    RETVAL

int
right(self)
  Tickit::Rect self
  CODE:
    RETVAL = tickit_rect_right(self);
  OUTPUT:
    RETVAL

bool
equals(self,other,swap=0)
  Tickit::Rect self
  Tickit::Rect other
  int          swap
  CODE:
    RETVAL = (self->top   == other->top) &&
             (self->lines == other->lines) &&
             (self->left  == other->left) &&
             (self->cols  == other->cols);
  OUTPUT:
    RETVAL

bool
intersects(self,other)
  Tickit::Rect self
  Tickit::Rect other
  CODE:
    RETVAL = tickit_rect_intersects(self, other);
  OUTPUT:
    RETVAL

bool
contains(large,small)
  Tickit::Rect large
  Tickit::Rect small
  CODE:
    RETVAL = tickit_rect_contains(large, small);
  OUTPUT:
    RETVAL

void
add(x,y)
  Tickit::Rect x
  Tickit::Rect y
  INIT:
    int n_rects, i;
    TickitRect rects[3];
  PPCODE:
    n_rects = tickit_rect_add(rects, x, y);

    for(i = 0; i < n_rects; i++)
      mPUSHrect(rects + i);

    XSRETURN(n_rects);

void
subtract(self,hole)
  Tickit::Rect self
  Tickit::Rect hole
  INIT:
    int n_rects, i;
    TickitRect rects[4];
  PPCODE:
    n_rects = tickit_rect_subtract(rects, self, hole);

    for(i = 0; i < n_rects; i++)
      mPUSHrect(rects + i);

    XSRETURN(n_rects);

MODULE = Tickit             PACKAGE = Tickit::RectSet

Tickit::RectSet
new(package)
  char *package
  CODE:
    RETVAL = tickit_rectset_new();
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::RectSet self
  CODE:
    tickit_rectset_destroy(self);

void
clear(self)
  Tickit::RectSet self
  CODE:
    tickit_rectset_clear(self);

void
rects(self)
  Tickit::RectSet self
  INIT:
    int n;
    TickitRect *rects;
    int i;
  PPCODE:
    n = tickit_rectset_rects(self);

    if(GIMME_V != G_ARRAY) {
      mPUSHi(n);
      XSRETURN(1);
    }

    Newx(rects, n, TickitRect);
    tickit_rectset_get_rects(self, rects, n);

    EXTEND(SP, n);
    for(i = 0; i < n; i++) {
      mPUSHrect(rects + i);
    }

    Safefree(rects);

    XSRETURN(n);

void
add(self,rect)
  Tickit::RectSet self
  Tickit::Rect rect
  CODE:
    tickit_rectset_add(self, rect);

void
subtract(self,rect)
  Tickit::RectSet self
  Tickit::Rect rect
  CODE:
    tickit_rectset_subtract(self, rect);

bool
intersects(self,r)
  Tickit::RectSet self
  Tickit::Rect r
  INIT:
    int i;
  CODE:
    RETVAL = tickit_rectset_intersects(self, r);
  OUTPUT:
    RETVAL

bool
contains(self,r)
  Tickit::RectSet self
  Tickit::Rect r
  INIT:
    int i;
  CODE:
    RETVAL = tickit_rectset_contains(self, r);
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::RenderBuffer

SV *
_xs_new(class,lines,cols)
  char *class
  int lines
  int cols
  CODE:
    RETVAL = newSVrb_noinc(tickit_renderbuffer_new(lines, cols));
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::RenderBuffer self
  CODE:
    tickit_renderbuffer_unref(self);

int
lines(self)
  Tickit::RenderBuffer self
  CODE:
    tickit_renderbuffer_get_size(self, &RETVAL, NULL);
  OUTPUT:
    RETVAL

int
cols(self)
  Tickit::RenderBuffer self
  CODE:
    tickit_renderbuffer_get_size(self, NULL, &RETVAL);
  OUTPUT:
    RETVAL

SV *
line(self)
  Tickit::RenderBuffer self
  INIT:
    TickitRenderBuffer *rb;
  CODE:
    rb = self;
    if(tickit_renderbuffer_has_cursorpos(rb)) {
      int line;
      tickit_renderbuffer_get_cursorpos(rb, &line, NULL);
      RETVAL = newSViv(line);
    }
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
col(self)
  Tickit::RenderBuffer self
  INIT:
    TickitRenderBuffer *rb;
  CODE:
    rb = self;
    if(tickit_renderbuffer_has_cursorpos(rb)) {
      int col;
      tickit_renderbuffer_get_cursorpos(rb, NULL, &col);
      RETVAL = newSViv(col);
    }
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
translate(self,downward,rightward)
  Tickit::RenderBuffer self
  int downward
  int rightward
  PPCODE:
    tickit_renderbuffer_translate(self, downward, rightward);

void
clip(self,rect)
  Tickit::RenderBuffer self
  Tickit::Rect rect
  CODE:
    tickit_renderbuffer_clip(self, rect);

void
mask(self,rect)
  Tickit::RenderBuffer self
  Tickit::Rect rect
  CODE:
    tickit_renderbuffer_mask(self, rect);

void
goto(self,line,col)
  Tickit::RenderBuffer self
  SV *line
  SV *col
  CODE:
    if(SvIsNumeric(line) && SvIsNumeric(col))
      tickit_renderbuffer_goto(self, SvIV(line), SvIV(col));
    else
      tickit_renderbuffer_ungoto(self);

void
setpen(self,pen)
  Tickit::RenderBuffer self
  Tickit::Pen pen
  CODE:
    tickit_renderbuffer_setpen(self, pen);

void
reset(self)
  Tickit::RenderBuffer self
  CODE:
    tickit_renderbuffer_reset(self);

void
clear(self,pen=NULL)
  Tickit::RenderBuffer self
  Tickit::Pen pen
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_clear(self);
    if(pen)
      tickit_renderbuffer_restore(self);

void
save(self)
  Tickit::RenderBuffer self
  CODE:
    tickit_renderbuffer_save(self);

void
savepen(self)
  Tickit::RenderBuffer self
  CODE:
    tickit_renderbuffer_savepen(self);

void
restore(self)
  Tickit::RenderBuffer self
  INIT:
    TickitRenderBuffer *rb;
  CODE:
    tickit_renderbuffer_restore(self);

void
_xs_get_cell(self,line,col)
  Tickit::RenderBuffer self
  int line
  int col
  INIT:
    TickitRenderBuffer *rb;
    STRLEN len;
    SV *text;
    TickitRenderBufferLineMask mask;
  PPCODE:
    rb = self;
    if(tickit_renderbuffer_get_cell_active(rb, line, col) != 1) {
      XPUSHs(&PL_sv_undef);
      XPUSHs(&PL_sv_undef);
      XSRETURN(2);
    }

    len = tickit_renderbuffer_get_cell_text(rb, line, col, NULL, 0);
    text = newSV(len + 1);
    tickit_renderbuffer_get_cell_text(rb, line, col, SvPVX(text), len + 1);
    SvPOK_on(text); SvUTF8_on(text); SvCUR_set(text, len);
    XPUSHs(sv_2mortal(text));

    mPUSHs(newSVpen_noinc(tickit_pen_clone(tickit_renderbuffer_get_cell_pen(rb, line, col)), NULL));

    mask = tickit_renderbuffer_get_cell_linemask(rb, line, col);
    if(!mask.north && !mask.south && !mask.east && !mask.west)
      XSRETURN(2);

    mPUSHi(mask.north);
    mPUSHi(mask.south);
    mPUSHi(mask.east);
    mPUSHi(mask.west);
    XSRETURN(6);

void
skip_at(self,line,col,len)
  Tickit::RenderBuffer self
  int line
  int col
  int len
  CODE:
    tickit_renderbuffer_skip_at(self, line, col, len);

void
skip(self,len)
  Tickit::RenderBuffer self
  int len
  CODE:
    if(!tickit_renderbuffer_has_cursorpos(self))
      croak("Cannot ->skip without a virtual cursor position");

    tickit_renderbuffer_skip(self, len);

void
skip_to(self,col)
  Tickit::RenderBuffer self
  int col
  CODE:
    if(!tickit_renderbuffer_has_cursorpos(self))
      croak("Cannot ->skip_to without a virtual cursor position");

    tickit_renderbuffer_skip_to(self, col);

int
text_at(self,line,col,text,pen=NULL)
  Tickit::RenderBuffer self
  int line
  int col
  SV *text
  Tickit::Pen pen
  INIT:
    char *bytes;
    STRLEN len;
  CODE:
    bytes = SvPVutf8(text, len);
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    RETVAL = tickit_renderbuffer_textn_at(self, line, col, bytes, len);
    if(pen)
      tickit_renderbuffer_restore(self);
  OUTPUT:
    RETVAL

int
text(self,text,pen=NULL)
  Tickit::RenderBuffer self
  SV *text
  Tickit::Pen pen
  INIT:
    char *bytes;
    STRLEN len;
  CODE:
    if(!tickit_renderbuffer_has_cursorpos(self))
      croak("Cannot ->text without a virtual cursor position");

    bytes = SvPVutf8(text, len);
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    RETVAL = tickit_renderbuffer_textn(self, bytes, len);
    if(pen)
      tickit_renderbuffer_restore(self);
  OUTPUT:
    RETVAL

void
erase_at(self,line,col,len,pen=NULL)
  Tickit::RenderBuffer self
  int line
  int col
  int len
  Tickit::Pen pen
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_erase_at(self, line, col, len);
    if(pen)
      tickit_renderbuffer_restore(self);

void
erase(self,len,pen=NULL)
  Tickit::RenderBuffer self
  int len
  Tickit::Pen pen
  CODE:
    if(!tickit_renderbuffer_has_cursorpos(self))
      croak("Cannot ->erase without a virtual cursor position");

    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_erase(self, len);
    if(pen)
      tickit_renderbuffer_restore(self);

void
erase_to(self,col,pen=NULL)
  Tickit::RenderBuffer self
  int col
  Tickit::Pen pen
  CODE:
    if(!tickit_renderbuffer_has_cursorpos(self))
      croak("Cannot ->erase_to without a virtual cursor position");

    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_erase_to(self, col);
    if(pen)
      tickit_renderbuffer_restore(self);

void
eraserect(self,rect,pen=NULL)
  Tickit::RenderBuffer self
  Tickit::Rect rect
  Tickit::Pen pen
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_eraserect(self, rect);
    if(pen)
      tickit_renderbuffer_restore(self);

void
char_at(self,line,col,codepoint,pen=NULL)
  Tickit::RenderBuffer self
  int line
  int col
  int codepoint
  Tickit::Pen pen
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_char_at(self, line, col, codepoint);
    if(pen)
      tickit_renderbuffer_restore(self);

void
char(self,codepoint,pen=NULL)
  Tickit::RenderBuffer self
  int codepoint
  Tickit::Pen pen
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_char(self, codepoint);
    if(pen)
      tickit_renderbuffer_restore(self);

void
hline_at(self,line,startcol,endcol,style,pen=NULL,caps=0)
  Tickit::RenderBuffer self
  int line
  int startcol
  int endcol
  int style
  Tickit::Pen pen
  int caps
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_hline_at(self, line, startcol, endcol, style, caps);
    if(pen)
      tickit_renderbuffer_restore(self);

void
vline_at(self,startline,endline,col,style,pen=NULL,caps=0)
  Tickit::RenderBuffer self
  int startline
  int endline
  int col
  int style
  Tickit::Pen pen
  int caps
  CODE:
    if(pen) {
      tickit_renderbuffer_savepen(self);
      tickit_renderbuffer_setpen(self, pen);
    }
    tickit_renderbuffer_vline_at(self, startline, endline, col, style, caps);
    if(pen)
      tickit_renderbuffer_restore(self);

void
flush_to_term(self,term)
  Tickit::RenderBuffer self
  Tickit::Term term
  CODE:
    tickit_renderbuffer_flush_to_term(self, term);

MODULE = Tickit             PACKAGE = Tickit::StringPos

SV *
zero(package)
  char *package;
  INIT:
    TickitStringPos *pos;
  CODE:
    pos = new_stringpos(&RETVAL);
    tickit_stringpos_zero(pos);
  OUTPUT:
    RETVAL

SV *
limit_bytes(package,bytes)
  char *package;
  size_t bytes;
  INIT:
    TickitStringPos *pos;
  CODE:
    pos = new_stringpos(&RETVAL);
    tickit_stringpos_limit_bytes(pos, bytes);
  OUTPUT:
    RETVAL

SV *
limit_codepoints(package,codepoints)
  char *package;
  int codepoints;
  INIT:
    TickitStringPos *pos;
  CODE:
    pos = new_stringpos(&RETVAL);
    tickit_stringpos_limit_codepoints(pos, codepoints);
  OUTPUT:
    RETVAL

SV *
limit_graphemes(package,graphemes)
  char *package;
  int graphemes;
  INIT:
    TickitStringPos *pos;
  CODE:
    pos = new_stringpos(&RETVAL);
    tickit_stringpos_limit_graphemes(pos, graphemes);
  OUTPUT:
    RETVAL

SV *
limit_columns(package,columns)
  char *package;
  int columns;
  INIT:
    TickitStringPos *pos;
  CODE:
    pos = new_stringpos(&RETVAL);
    tickit_stringpos_limit_columns(pos, columns);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::StringPos self
  CODE:
    Safefree(self);

size_t
bytes(self)
  Tickit::StringPos self;
  CODE:
    RETVAL = self->bytes;
  OUTPUT:
    RETVAL

int
codepoints(self)
  Tickit::StringPos self;
  CODE:
    RETVAL = self->codepoints;
  OUTPUT:
    RETVAL

int
graphemes(self)
  Tickit::StringPos self;
  CODE:
    RETVAL = self->graphemes;
  OUTPUT:
    RETVAL

int
columns(self)
  Tickit::StringPos self;
  CODE:
    RETVAL = self->columns;
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Term

SV *
_new(package,termtype)
  char *package;
  char *termtype;
  INIT:
    Tickit__Term  self;
    TickitTerm   *tt;
  CODE:
    tt = tickit_term_new_for_termtype(termtype);
    if(!tt)
      XSRETURN_UNDEF;

    RETVAL = newSVterm_noinc(tt, package);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::Term  self
  CODE:
    /*
     * destroy TickitTerm first in case it's still using output_handle/func
     */
    tickit_term_unref(self);

int
get_input_fd(self)
  Tickit::Term  self
  CODE:
    RETVAL = tickit_term_get_input_fd(self);
  OUTPUT:
    RETVAL

void
set_input_handle(self,handle)
  Tickit::Term  self
  SV           *handle
  CODE:
    tickit_term_set_input_fd(self, PerlIO_fileno(IoIFP(sv_2io(handle))));

int
get_output_fd(self)
  Tickit::Term  self
  CODE:
    RETVAL = tickit_term_get_output_fd(self);
  OUTPUT:
    RETVAL

void
set_output_handle(self,handle)
  Tickit::Term  self
  SV           *handle
  CODE:
    tickit_term_set_output_fd(self, PerlIO_fileno(IoIFP(sv_2io(handle))));

void
set_output_func(self,func)
  Tickit::Term  self
  CV           *func
  CODE:
    tickit_term_set_output_func(self, term_output_fn, SvREFCNT_inc(func));

void
await_started(self,timeout)
  Tickit::Term  self
  double        timeout
  CODE:
    tickit_term_await_started_msec(self, timeout * 1000);

void
flush(self)
  Tickit::Term  self
  CODE:
    tickit_term_flush(self);

void
set_output_buffer(self,len)
  Tickit::Term  self
  size_t        len
  CODE:
    tickit_term_set_output_buffer(self, len);

void
set_utf8(self,utf8)
  Tickit::Term  self
  int           utf8;
  CODE:
    tickit_term_set_utf8(self, utf8);

void
get_size(self)
  Tickit::Term  self
  INIT:
    int lines, cols;
  PPCODE:
    tickit_term_get_size(self, &lines, &cols);
    EXTEND(SP, 2);
    mPUSHi(lines);
    mPUSHi(cols);
    XSRETURN(2);

void
set_size(self,lines,cols)
  Tickit::Term  self
  int           lines
  int           cols
  CODE:
    tickit_term_set_size(self, lines, cols);

void
refresh_size(self)
  Tickit::Term  self
  CODE:
    tickit_term_refresh_size(self);

int
_bind_event(self,ev,flags,code,data = &PL_sv_undef)
  Tickit::Term  self
  char         *ev
  int           flags
  CV           *code
  SV           *data
  INIT:
    TickitEventType ev_e;
    struct GenericEventData *user;
  CODE:
    ev_e = tickit_name2ev(ev);
    if(ev_e == -1)
      croak("Unrecognised event name '%s'", ev);

    Newx(user, 1, struct GenericEventData);
    user->self = newSVsv(ST(0));
    user->code = (CV*)SvREFCNT_inc(code);
    user->data = newSVsv(data);

    sv_rvweaken(user->self);

    RETVAL = tickit_term_bind_event(self, ev_e|TICKIT_EV_UNBIND, flags, term_userevent_fn, user);
  OUTPUT:
    RETVAL

void
unbind_event_id(self,id)
  Tickit::Term  self
  int           id
  CODE:
    tickit_term_unbind_event_id(self, id);

void
input_push_bytes(self,bytes)
  Tickit::Term  self
  SV           *bytes
  INIT:
    char   *str;
    STRLEN  len;
  CODE:
    str = SvPV(bytes, len);
    tickit_term_input_push_bytes(self, str, len);

void
input_readable(self)
  Tickit::Term  self
  CODE:
    tickit_term_input_readable(self);

void
input_wait(self,timeout=&PL_sv_undef)
  Tickit::Term  self
  SV           *timeout
  CODE:
    if(SvIsNumeric(timeout))
      tickit_term_input_wait_msec(self, SvNV(timeout) * 1000);
    else
      tickit_term_input_wait_msec(self, -1);


SV *
check_timeout(self)
  Tickit::Term  self
  INIT:
    int msec;
  CODE:
    msec = tickit_term_input_check_timeout_msec(self);
    RETVAL = newSV(0);
    if(msec >= 0)
      sv_setnv(RETVAL, msec / 1000.0);
  OUTPUT:
    RETVAL

bool
goto(self,line,col)
  Tickit::Term  self
  SV           *line
  SV           *col
  CODE:
    RETVAL = tickit_term_goto(self, SvOK(line) ? SvIV(line) : -1, SvOK(col) ? SvIV(col) : -1);
  OUTPUT:
    RETVAL

void
move(self,downward,rightward)
  Tickit::Term  self
  SV           *downward
  SV           *rightward
  CODE:
    tickit_term_move(self, SvOK(downward) ? SvIV(downward) : 0, SvOK(rightward) ? SvIV(rightward) : 0);

int
scrollrect(self,top,left,lines,cols,downward,rightward)
  Tickit::Term  self
  int           top
  int           left
  int           lines
  int           cols
  int           downward
  int           rightward
  INIT:
    TickitRect rect;
  CODE:
    rect.top   = top;
    rect.left  = left;
    rect.lines = lines;
    rect.cols  = cols;
    RETVAL = tickit_term_scrollrect(self, rect, downward, rightward);
  OUTPUT:
    RETVAL

void
chpen(self,...)
  Tickit::Term  self
  INIT:
    TickitPen *pen;
    int        pen_temp = 0;
  CODE:
    if(items == 2 && SvROK(ST(1)) && sv_derived_from(ST(1), "Tickit::Pen")) {
      IV tmp = SvIV((SV*)SvRV(ST(1)));
      Tickit__Pen self = INT2PTR(Tickit__Pen, tmp);
      pen = self;
    }
    else {
      pen = pen_from_args(SP-items+2, items-1);
      pen_temp = 1;
    }
    tickit_term_chpen(self, pen);
    if(pen_temp)
      tickit_pen_unref(pen);

void
setpen(self,...)
  Tickit::Term  self
  INIT:
    TickitPen *pen;
    int        pen_temp = 0;
  CODE:
    if(items == 2 && SvROK(ST(1)) && sv_derived_from(ST(1), "Tickit::Pen")) {
      IV tmp = SvIV((SV*)SvRV(ST(1)));
      Tickit__Pen self = INT2PTR(Tickit__Pen, tmp);
      pen = self;
    }
    else {
      pen = pen_from_args(SP-items+2, items-1);
      pen_temp = 1;
    }
    tickit_term_setpen(self, pen);
    if(pen_temp)
      tickit_pen_unref(pen);

void
print(self,text,pen=NULL)
  Tickit::Term  self
  SV           *text
  Tickit::Pen   pen
  INIT:
    char  *utf8;
    STRLEN len;
  CODE:
    if(pen)
      tickit_term_setpen(self, pen);
    utf8 = SvPVutf8(text, len);
    tickit_term_printn(self, utf8, len);

void
clear(self,pen=NULL)
  Tickit::Term  self
  Tickit::Pen   pen
  CODE:
    if(pen)
      tickit_term_setpen(self, pen);
    tickit_term_clear(self);

void
erasech(self,count,moveend,pen=NULL)
  Tickit::Term  self
  int           count
  SV           *moveend
  Tickit::Pen   pen
  CODE:
    if(pen)
      tickit_term_setpen(self, pen);
    tickit_term_erasech(self, count, SvOK(moveend) ? SvIV(moveend) : -1);

int
getctl_int(self,ctl)
  Tickit::Term self
  SV          *ctl
  INIT:
    TickitTermCtl ctl_e;
  CODE:
    if(SvPOK(ctl)) {
      ctl_e = term_name2ctl(SvPV_nolen(ctl));
      if(ctl_e == -1)
        croak("Unrecognised 'ctl' name '%s'", SvPV_nolen(ctl));
    }
    else if(SvIOK(ctl))
      ctl_e = SvIV(ctl);
    else
      croak("Expected 'ctl' to be an integer or string");

    if(!tickit_term_getctl_int(self, ctl_e, &RETVAL))
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

void
setctl_int(self,ctl,value)
  Tickit::Term self
  SV          *ctl
  int          value
  INIT:
    TickitTermCtl ctl_e;
  PPCODE:
    if(SvPOK(ctl)) {
      ctl_e = term_name2ctl(SvPV_nolen(ctl));
      if(ctl_e == -1)
        croak("Unrecognised 'ctl' name '%s'", SvPV_nolen(ctl));
    }
    else if(SvIOK(ctl))
      ctl_e = SvIV(ctl);
    else
      croak("Expected 'ctl' to be an integer or string");

    if(tickit_term_setctl_int(self, ctl_e, value))
      XSRETURN_YES;
    else
      XSRETURN_NO;

int
setctl_str(self,ctl,value)
  Tickit::Term self
  SV          *ctl
  char        *value
  INIT:
    TickitTermCtl ctl_e;
  CODE:
    if(SvPOK(ctl)) {
      ctl_e = term_name2ctl(SvPV_nolen(ctl));
      if(ctl_e == -1)
        croak("Unrecognised 'ctl' name '%s'", SvPV_nolen(ctl));
    }
    else if(SvIOK(ctl))
      ctl_e = SvIV(ctl);
    else
      croak("Expected 'ctl' to be an integer or string");
    RETVAL = tickit_term_setctl_str(self, ctl_e, value);
  OUTPUT:
    RETVAL

void
_emit_key(self,info)
  Tickit::Term       self
  Tickit::Event::Key info
  CODE:
    tickit_term_emit_key(self, info);

void
_emit_mouse(self,info)
  Tickit::Term         self
  Tickit::Event::Mouse info
  CODE:
    tickit_term_emit_mouse(self, info);

MODULE = Tickit::Test::MockTerm    PACKAGE = Tickit::Test::MockTerm

SV *
_new_mocking(package,lines,cols)
  char *package
  int   lines
  int   cols
  INIT:
    TickitMockTerm *mt;
  CODE:
    mt = tickit_mockterm_new(lines, cols);
    if(!mt)
      XSRETURN_UNDEF;

    RETVAL = newSVterm_noinc((TickitTerm *)mt, "Tickit::Test::MockTerm");
  OUTPUT:
    RETVAL

void
get_methodlog(self)
  Tickit::Term self
  INIT:
    TickitMockTerm *mt;
    int loglen;
    int i;
  PPCODE:
    mt = (TickitMockTerm *)self;

    EXTEND(SP, (loglen = tickit_mockterm_loglen(mt)));
    for(i = 0; i < loglen; i++) {
      TickitMockTermLogEntry *entry = tickit_mockterm_peeklog(mt, i);
      AV *ret = newAV();
      switch(entry->type) {
      case LOG_GOTO:
        av_push(ret, newSVpv("goto", 0));
        av_push(ret, newSViv(entry->val1)); // line
        av_push(ret, newSViv(entry->val2)); // col
        break;
      case LOG_PRINT:
        av_push(ret, newSVpv("print", 0));
        av_push(ret, newSVpvn_utf8(entry->str, entry->val1, 1));
        break;
      case LOG_ERASECH:
        av_push(ret, newSVpv("erasech", 0));
        av_push(ret, newSViv(entry->val1)); // count
        av_push(ret, newSViv(entry->val2 == 1 ? 1 : 0)); // moveend
        break;
      case LOG_CLEAR:
        av_push(ret, newSVpv("clear", 0));
        break;
      case LOG_SCROLLRECT:
        av_push(ret, newSVpv("scrollrect", 0));
        av_push(ret, newSViv(entry->rect.top));
        av_push(ret, newSViv(entry->rect.left));
        av_push(ret, newSViv(entry->rect.lines));
        av_push(ret, newSViv(entry->rect.cols));
        av_push(ret, newSViv(entry->val1)); // downward
        av_push(ret, newSViv(entry->val2)); // rightward
        break;
      case LOG_SETPEN:
        {
          HV *penattrs = newHV();
          TickitPenAttr attr;

          for(attr = 0; attr < TICKIT_N_PEN_ATTRS; attr++) {
            const char *attrname = tickit_pen_attrname(attr);
            int value;
            if(!tickit_pen_nondefault_attr(entry->pen, attr))
              continue;

            switch(tickit_pen_attrtype(attr)) {
            case TICKIT_PENTYPE_BOOL:
              value = tickit_pen_get_bool_attr(entry->pen, attr); break;
            case TICKIT_PENTYPE_INT:
              value = tickit_pen_get_int_attr(entry->pen, attr); break;
            case TICKIT_PENTYPE_COLOUR:
              value = tickit_pen_get_colour_attr(entry->pen, attr); break;
            }

            sv_setiv(*hv_fetch(penattrs, attrname, strlen(attrname), 1), value);
          }

          av_push(ret, newSVpv("setpen", 0));
          av_push(ret, newRV_noinc((SV *)penattrs));
        }
        break;
      }
      mPUSHs(newRV_noinc((SV *)ret));
    }

    tickit_mockterm_clearlog(mt);

    XSRETURN(i);

SV *
get_display_text(self,line,col,width)
  Tickit::Term self
  int line
  int col
  int width
  INIT:
    STRLEN len;
  CODE:
    len = tickit_mockterm_get_display_text((TickitMockTerm *)self, NULL, 0, line, col, width);

    RETVAL = newSV(len+1);

    tickit_mockterm_get_display_text((TickitMockTerm *)self, SvPVX(RETVAL), len, line, col, width);

    SvPOK_on(RETVAL);
    SvUTF8_on(RETVAL);
    SvCUR_set(RETVAL, len);
  OUTPUT:
    RETVAL

SV *
get_display_pen(self,line,col)
  Tickit::Term self
  int line
  int col
  INIT:
    TickitPen *pen;
    HV *penattrs;
    TickitPenAttr attr;
  CODE:
    pen = tickit_mockterm_get_display_pen((TickitMockTerm *)self, line, col);

    penattrs = newHV();
    for(attr = 0; attr < TICKIT_N_PEN_ATTRS; attr++) {
      const char *attrname;
      if(!tickit_pen_nondefault_attr(pen, attr))
        continue;

      attrname = tickit_pen_attrname(attr);
      hv_store(penattrs, attrname, strlen(attrname), pen_get_attr(pen, attr), 0);
    }

    RETVAL = newRV_noinc((SV *)penattrs);
  OUTPUT:
    RETVAL

void
resize(self,newlines,newcols)
  Tickit::Term self
  int newlines
  int newcols
  CODE:
    tickit_mockterm_resize((TickitMockTerm *)self, newlines, newcols);

int
line(self)
  Tickit::Term self
  ALIAS:
    line        = 0
    col         = 1
    cursorvis   = 2
    cursorshape = 3
  INIT:
    TickitMockTerm *mt;
  CODE:
    mt = (TickitMockTerm *)self;
    switch(ix) {
      case 0: tickit_mockterm_get_position(mt, &RETVAL, NULL); break;
      case 1: tickit_mockterm_get_position(mt, NULL, &RETVAL); break;
      case 2: tickit_term_getctl_int(self, TICKIT_TERMCTL_CURSORVIS, &RETVAL); break;
      case 3: tickit_term_getctl_int(self, TICKIT_TERMCTL_CURSORSHAPE, &RETVAL); break;
    }
  OUTPUT:
    RETVAL

MODULE = Tickit             PACKAGE = Tickit::Utils

size_t
string_count(str,pos,limit=NULL)
    SV *str
    Tickit::StringPos pos
    Tickit::StringPos limit
  INIT:
    char *s;
    STRLEN len;
  CODE:
    if(!SvUTF8(str)) {
      str = sv_mortalcopy(str);
      sv_utf8_upgrade(str);
    }

    s = SvPVutf8(str, len);
    RETVAL = tickit_string_ncount(s, len, pos, limit);
    if(RETVAL == -1)
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

size_t
string_countmore(str,pos,limit=NULL)
    SV *str
    Tickit::StringPos pos
    Tickit::StringPos limit
  INIT:
    char *s;
    STRLEN len;
  CODE:
    if(!SvUTF8(str)) {
      str = sv_mortalcopy(str);
      sv_utf8_upgrade(str);
    }

    s = SvPVutf8(str, len);
    RETVAL = tickit_string_ncountmore(s, len, pos, limit);
    if(RETVAL == -1)
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

int textwidth(str)
    SV *str
  INIT:
    STRLEN len;
    const char *s;
    TickitStringPos pos, limit = INIT_TICKIT_STRINGPOS_LIMIT_NONE;

  CODE:
    RETVAL = 0;

    if(!SvUTF8(str)) {
      str = sv_mortalcopy(str);
      sv_utf8_upgrade(str);
    }

    s = SvPVutf8(str, len);
    if(tickit_string_ncount(s, len, &pos, &limit) == -1)
      XSRETURN_UNDEF;

    RETVAL = pos.columns;

  OUTPUT:
    RETVAL

void chars2cols(str,...)
    SV *str;
  INIT:
    STRLEN len;
    const char *s;
    int i;
    TickitStringPos pos, limit;
    size_t bytes;

  PPCODE:
    if(!SvUTF8(str)) {
      str = sv_mortalcopy(str);
      sv_utf8_upgrade(str);
    }

    s = SvPVutf8(str, len);

    EXTEND(SP, items - 1);

    tickit_stringpos_zero(&pos);
    tickit_stringpos_limit_bytes(&limit, len);

    for(i = 1; i < items; i++ ) {
      limit.codepoints = SvUV(ST(i));
      if(limit.codepoints < pos.codepoints)
        croak("chars2cols requires a monotonically-increasing list of character numbers; %d is not greater than %d\n",
          limit.codepoints, pos.codepoints);

      bytes = tickit_string_ncountmore(s, len, &pos, &limit);
      if(bytes == -1)
        XSRETURN_UNDEF;

      mPUSHu(pos.columns);

      if(GIMME_V != G_ARRAY)
        XSRETURN(1);
    }

    XSRETURN(items - 1);

void cols2chars(str,...)
    SV *str;
  INIT:
    STRLEN len;
    const char *s;
    int i;
    TickitStringPos pos, limit;
    size_t bytes;

  PPCODE:
    if(!SvUTF8(str)) {
      str = sv_mortalcopy(str);
      sv_utf8_upgrade(str);
    }

    s = SvPVutf8(str, len);

    EXTEND(SP, items - 1);

    tickit_stringpos_zero(&pos);
    tickit_stringpos_limit_bytes(&limit, len);

    for(i = 1; i < items; i++ ) {
      limit.columns = SvUV(ST(i));
      if(limit.columns < pos.columns)
        croak("cols2chars requires a monotonically-increasing list of column numbers; %d is not greater than %d\n",
          limit.columns, pos.columns);

      bytes = tickit_string_ncountmore(s, len, &pos, &limit);
      if(bytes == -1)
        XSRETURN_UNDEF;

      mPUSHu(pos.codepoints);

      if(GIMME_V != G_ARRAY)
        XSRETURN(1);
    }

    XSRETURN(items - 1);

MODULE = Tickit  PACKAGE = Tickit::Window

SV *
_new_root(package,tt,tickit)
  char         *package
  Tickit::Term  tt
  SV           *tickit
  INIT:
    Tickit__Window  self;
    TickitWindow   *win;
  CODE:
    win = tickit_window_new_root(tt);
    if(!win)
      XSRETURN_UNDEF;

    RETVAL = newSVwin_noinc(win);
    self = INT2PTR(struct Tickit__Window *, SvIV(SvRV(RETVAL)));

    self->tickit = newSVsv(tickit);
    sv_rvweaken(self->tickit);
  OUTPUT:
    RETVAL

SV *
_make_sub(win,top,left,lines,cols,flags)
  Tickit::Window win;
  int            top;
  int            left;
  int            lines;
  int            cols;
  int            flags;
  INIT:
    TickitRect rect;
    TickitWindow *subwin;
    Tickit__Window self;
  CODE:
    rect.top   = top;
    rect.left  = left;
    rect.lines = lines;
    rect.cols  = cols;
    subwin = tickit_window_new(win->win, rect, flags);
    if(!subwin)
      XSRETURN_UNDEF;

    /* parent window holds a reference, we have another */
    RETVAL = newSVwin(subwin);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Tickit::Window self
  CODE:
    tickit_window_unref(self->win);
    self->win = NULL;

void
close(self)
  Tickit::Window self
  CODE:
    tickit_window_close(self->win);

int
top(self)
  Tickit::Window self
  CODE:
    RETVAL = tickit_window_top(self->win);
  OUTPUT:
    RETVAL

int
left(self)
  Tickit::Window self
  CODE:
    RETVAL = tickit_window_left(self->win);
  OUTPUT:
    RETVAL

int
lines(self)
  Tickit::Window self
  CODE:
    RETVAL = tickit_window_lines(self->win);
  OUTPUT:
    RETVAL

int
cols(self)
  Tickit::Window self
  CODE:
    RETVAL = tickit_window_cols(self->win);
  OUTPUT:
    RETVAL

int
abs_top(self)
  Tickit::Window self
  CODE:
    RETVAL = tickit_window_get_abs_geometry(self->win).top;
  OUTPUT:
    RETVAL

int
abs_left(self)
  Tickit::Window self
  CODE:
    RETVAL = tickit_window_get_abs_geometry(self->win).left;
  OUTPUT:
    RETVAL

SV *
root(self)
  Tickit::Window self
  ALIAS:
    root   = 0
    parent = 1
    term   = 2
    _tickit = 3
  CODE:
    switch(ix) {
      case 0: RETVAL = newSVwin(tickit_window_root(self->win)); break;
      case 1: {
        TickitWindow *parent = tickit_window_parent(self->win);
        RETVAL = parent ? newSVwin(parent) : &PL_sv_undef;
        break;
      }
      case 2: RETVAL = newSVterm(tickit_window_get_term(self->win), "Tickit::Term"); break;
      case 3: {
        RETVAL = self->tickit ? newSVsv(self->tickit) : &PL_sv_undef;
        break;
      }
    }
  OUTPUT:
    RETVAL

void
subwindows(self)
  Tickit::Window self
  INIT:
    size_t n;
    TickitWindow **children;
    size_t i;
  PPCODE:
    n = tickit_window_children(self->win);

    if(GIMME_V != G_ARRAY) {
      mPUSHi(n);
      XSRETURN(1);
    }

    Newx(children, n, TickitWindow *);
    tickit_window_get_children(self->win, children, n);

    EXTEND(SP, n);
    for(i = 0; i < n; i++) {
      mPUSHs(newSVwin(children[i]));
    }

    Safefree(children);

    XSRETURN(n);

int
_bind_event(self,ev,flags,code,data = &PL_sv_undef)
  Tickit::Window  self
  char           *ev
  int             flags
  CV             *code
  SV             *data
  INIT:
    TickitEventType ev_e;
    struct GenericEventData *user;
  CODE:
    ev_e = tickit_name2ev(ev);
    if(ev_e == -1)
      croak("Unrecognised event name '%s'", ev);

    Newx(user, 1, struct GenericEventData);
    user->self = newSVsv(ST(0));
    user->code = (CV*)SvREFCNT_inc(code);
    user->data = newSVsv(data);

    sv_rvweaken(user->self);

    RETVAL = tickit_window_bind_event(self->win, ev_e|TICKIT_EV_UNBIND, flags, window_userevent_fn, user);
  OUTPUT:
    RETVAL

void
unbind_event_id(self,id)
  Tickit::Window self
  int            id
  CODE:
    tickit_window_unbind_event_id(self->win, id);

void
flush(self)
  Tickit::Window  self
  CODE:
    tickit_window_flush(self->win);

void
expose(self,rect = NULL)
  Tickit::Window     self
  Tickit::Rect_MAYBE rect
  CODE:
    tickit_window_expose(self->win, rect);

void
hide(self)
  Tickit::Window  self
  CODE:
    tickit_window_hide(self->win);

void
show(self)
  Tickit::Window  self
  CODE:
    tickit_window_show(self->win);

void
resize(self,lines,cols)
  Tickit::Window self
  int            lines
  int            cols
  CODE:
    tickit_window_resize(self->win, lines, cols);

void
reposition(self,top,left)
  Tickit::Window self
  int            top
  int            left
  CODE:
    tickit_window_reposition(self->win, top, left);

void
change_geometry(self,top,left,lines,cols)
  Tickit::Window  self
  int             top
  int             left
  int             lines
  int             cols
  INIT:
    TickitRect rect;
  CODE:
    rect.top   = top;
    rect.left  = left;
    rect.lines = lines;
    rect.cols  = cols;
    tickit_window_set_geometry(self->win, rect);

bool
is_visible(self)
  Tickit::Window  self
  CODE:
    RETVAL = tickit_window_is_visible(self->win);
  OUTPUT:
    RETVAL

SV *
pen(self)
  Tickit::Window  self
  CODE:
    RETVAL = newSVpen(tickit_window_get_pen(self->win), "Tickit::Pen::Mutable");
  OUTPUT:
    RETVAL

void
set_pen(self,pen)
  Tickit::Window  self
  Tickit::Pen     pen
  CODE:
    tickit_window_set_pen(self->win, pen);

void
raise(self)
  Tickit::Window self
  ALIAS:
    raise = 0
    lower = 1
    raise_to_front = 2
    lower_to_back  = 3
  CODE:
    switch(ix) {
      case 0: tickit_window_raise(self->win); break;
      case 1: tickit_window_lower(self->win); break;
      case 2: tickit_window_raise_to_front(self->win); break;
      case 3: tickit_window_lower_to_back(self->win); break;
    }

bool
_scrollrect(self,rect,downward,rightward,pen)
  Tickit::Window self
  Tickit::Rect   rect
  int            downward
  int            rightward
  Tickit::Pen    pen
  CODE:
    RETVAL = tickit_window_scrollrect(self->win, rect, downward, rightward, pen);
  OUTPUT:
    RETVAL

bool
_scroll_with_children(self,downward,rightward)
  Tickit::Window self
  int            downward
  int            rightward
  CODE:
    RETVAL = tickit_window_scroll_with_children(self->win, downward, rightward);
  OUTPUT:
    RETVAL

bool
is_focused(self)
  Tickit::Window  self
  CODE:
    RETVAL = tickit_window_is_focused(self->win);
  OUTPUT:
    RETVAL

void
take_focus(self)
  Tickit::Window  self
  CODE:
    tickit_window_take_focus(self->win);

void
set_focus_child_notify(self,notify)
  Tickit::Window  self
  bool            notify
  CODE:
    tickit_window_set_focus_child_notify(self->win, notify);

void
set_cursor_position(self,line,col)
  Tickit::Window  self
  int             line
  int             col
  CODE:
    tickit_window_set_cursor_position(self->win, line, col);

void
set_cursor_visible(self,visible)
  Tickit::Window  self
  bool            visible
  CODE:
    tickit_window_set_cursor_visible(self->win, visible);

void
set_cursor_shape(self,shape)
  Tickit::Window  self
  int             shape
  CODE:
    tickit_window_set_cursor_shape(self->win, shape);

bool
is_steal_input(self)
  Tickit::Window  self
  CODE:
    RETVAL = tickit_window_is_steal_input(self->win);
  OUTPUT:
    RETVAL

void
set_steal_input(self,steal)
  Tickit::Window  self
  bool            steal
  CODE:
    tickit_window_set_steal_input(self->win, steal);

MODULE = Tickit  PACKAGE = Tickit

BOOT:
  setup_constants();
