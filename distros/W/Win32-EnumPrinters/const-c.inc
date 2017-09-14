static SV*
attribute_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef PRINTER_ATTRIBUTE_DIRECT
    case PRINTER_ATTRIBUTE_DIRECT:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_DIRECT, "direct");
#endif
#ifdef PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST
    case PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST, "do_complete_first");
#endif
#ifdef PRINTER_ATTRIBUTE_ENABLE_DEVQ
    case PRINTER_ATTRIBUTE_ENABLE_DEVQ:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_ENABLE_DEVQ, "enable_devq");
#endif
#ifdef PRINTER_ATTRIBUTE_HIDDEN
    case PRINTER_ATTRIBUTE_HIDDEN:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_HIDDEN, "hidden");
#endif
#ifdef PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS
    case PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS, "keepprintedjobs");
#endif
#ifdef PRINTER_ATTRIBUTE_LOCAL
    case PRINTER_ATTRIBUTE_LOCAL:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_LOCAL, "local");
#endif
#ifdef PRINTER_ATTRIBUTE_NETWORK
    case PRINTER_ATTRIBUTE_NETWORK:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_NETWORK, "network");
#endif
#ifdef PRINTER_ATTRIBUTE_PUBLISHED
    case PRINTER_ATTRIBUTE_PUBLISHED:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_PUBLISHED, "published");
#endif
#ifdef PRINTER_ATTRIBUTE_QUEUED
    case PRINTER_ATTRIBUTE_QUEUED:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_QUEUED, "queued");
#endif
#ifdef PRINTER_ATTRIBUTE_RAW_ONLY
    case PRINTER_ATTRIBUTE_RAW_ONLY:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_RAW_ONLY, "raw_only");
#endif
#ifdef PRINTER_ATTRIBUTE_SHARED
    case PRINTER_ATTRIBUTE_SHARED:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_SHARED, "shared");
#endif
#ifdef PRINTER_ATTRIBUTE_FAX
    case PRINTER_ATTRIBUTE_FAX:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_FAX, "fax");
#endif
#ifdef PRINTER_ATTRIBUTE_FRIENDLY_NAME
    case PRINTER_ATTRIBUTE_FRIENDLY_NAME:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_FRIENDLY_NAME, "friendly_name");
#endif
#ifdef PRINTER_ATTRIBUTE_MACHINE
    case PRINTER_ATTRIBUTE_MACHINE:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_MACHINE, "machine");
#endif
#ifdef PRINTER_ATTRIBUTE_PUSHED_USER
    case PRINTER_ATTRIBUTE_PUSHED_USER:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_PUSHED_USER, "pushed_user");
#endif
#ifdef PRINTER_ATTRIBUTE_PUSHED_MACHINE
    case PRINTER_ATTRIBUTE_PUSHED_MACHINE:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_PUSHED_MACHINE, "pushed_machine");
#endif
#ifdef PRINTER_ATTRIBUTE_TS
    case PRINTER_ATTRIBUTE_TS:
        return newSVdual(aTHX_ PRINTER_ATTRIBUTE_TS, "ts");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_attribute(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'd':
#ifdef PRINTER_ATTRIBUTE_DIRECT
                if (len == 6 && strnEQ("direct", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_DIRECT);
#endif
                    return PRINTER_ATTRIBUTE_DIRECT;
                }
#endif

#ifdef PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST
                if (len == 17 && strnEQ("do_complete_first", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST);
#endif
                    return PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST;
                }
#endif

                break;
            case 'e':
#ifdef PRINTER_ATTRIBUTE_ENABLE_DEVQ
                if (len == 11 && strnEQ("enable_devq", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_ENABLE_DEVQ);
#endif
                    return PRINTER_ATTRIBUTE_ENABLE_DEVQ;
                }
#endif

                break;
            case 'f':
#ifdef PRINTER_ATTRIBUTE_FAX
                if (len == 3 && strnEQ("fax", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_FAX);
#endif
                    return PRINTER_ATTRIBUTE_FAX;
                }
#endif

#ifdef PRINTER_ATTRIBUTE_FRIENDLY_NAME
                if (len == 13 && strnEQ("friendly_name", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_FRIENDLY_NAME);
#endif
                    return PRINTER_ATTRIBUTE_FRIENDLY_NAME;
                }
#endif

                break;
            case 'h':
#ifdef PRINTER_ATTRIBUTE_HIDDEN
                if (len == 6 && strnEQ("hidden", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_HIDDEN);
#endif
                    return PRINTER_ATTRIBUTE_HIDDEN;
                }
#endif

                break;
            case 'k':
#ifdef PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS
                if (len == 15 && strnEQ("keepprintedjobs", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS);
#endif
                    return PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS;
                }
#endif

                break;
            case 'l':
#ifdef PRINTER_ATTRIBUTE_LOCAL
                if (len == 5 && strnEQ("local", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_LOCAL);
#endif
                    return PRINTER_ATTRIBUTE_LOCAL;
                }
#endif

                break;
            case 'm':
#ifdef PRINTER_ATTRIBUTE_MACHINE
                if (len == 7 && strnEQ("machine", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_MACHINE);
#endif
                    return PRINTER_ATTRIBUTE_MACHINE;
                }
#endif

                break;
            case 'n':
#ifdef PRINTER_ATTRIBUTE_NETWORK
                if (len == 7 && strnEQ("network", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_NETWORK);
#endif
                    return PRINTER_ATTRIBUTE_NETWORK;
                }
#endif

                break;
            case 'p':
#ifdef PRINTER_ATTRIBUTE_PUBLISHED
                if (len == 9 && strnEQ("published", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_PUBLISHED);
#endif
                    return PRINTER_ATTRIBUTE_PUBLISHED;
                }
#endif

#ifdef PRINTER_ATTRIBUTE_PUSHED_USER
                if (len == 11 && strnEQ("pushed_user", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_PUSHED_USER);
#endif
                    return PRINTER_ATTRIBUTE_PUSHED_USER;
                }
#endif

#ifdef PRINTER_ATTRIBUTE_PUSHED_MACHINE
                if (len == 14 && strnEQ("pushed_machine", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_PUSHED_MACHINE);
#endif
                    return PRINTER_ATTRIBUTE_PUSHED_MACHINE;
                }
#endif

                break;
            case 'q':
#ifdef PRINTER_ATTRIBUTE_QUEUED
                if (len == 6 && strnEQ("queued", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_QUEUED);
#endif
                    return PRINTER_ATTRIBUTE_QUEUED;
                }
#endif

                break;
            case 'r':
#ifdef PRINTER_ATTRIBUTE_RAW_ONLY
                if (len == 8 && strnEQ("raw_only", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_RAW_ONLY);
#endif
                    return PRINTER_ATTRIBUTE_RAW_ONLY;
                }
#endif

                break;
            case 's':
#ifdef PRINTER_ATTRIBUTE_SHARED
                if (len == 6 && strnEQ("shared", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_SHARED);
#endif
                    return PRINTER_ATTRIBUTE_SHARED;
                }
#endif

                break;
            case 't':
#ifdef PRINTER_ATTRIBUTE_TS
                if (len == 2 && strnEQ("ts", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "attribute", pv, PRINTER_ATTRIBUTE_TS);
#endif
                    return PRINTER_ATTRIBUTE_TS;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmbin_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMBIN_AUTO
    case DMBIN_AUTO:
        return newSVdual(aTHX_ DMBIN_AUTO, "auto");
#endif
#ifdef DMBIN_CASSETTE
    case DMBIN_CASSETTE:
        return newSVdual(aTHX_ DMBIN_CASSETTE, "cassette");
#endif
#ifdef DMBIN_ENVELOPE
    case DMBIN_ENVELOPE:
        return newSVdual(aTHX_ DMBIN_ENVELOPE, "envelope");
#endif
#ifdef DMBIN_ENVMANUAL
    case DMBIN_ENVMANUAL:
        return newSVdual(aTHX_ DMBIN_ENVMANUAL, "envmanual");
#endif
#ifdef DMBIN_FIRST
    case DMBIN_FIRST:
        return newSVdual(aTHX_ DMBIN_FIRST, "first");
#endif
#ifdef DMBIN_LARGECAPACITY
    case DMBIN_LARGECAPACITY:
        return newSVdual(aTHX_ DMBIN_LARGECAPACITY, "largecapacity");
#endif
#ifdef DMBIN_LARGEFMT
    case DMBIN_LARGEFMT:
        return newSVdual(aTHX_ DMBIN_LARGEFMT, "largefmt");
#endif
#ifdef DMBIN_LAST
    case DMBIN_LAST:
        return newSVdual(aTHX_ DMBIN_LAST, "last");
#endif
#ifdef DMBIN_LOWER
    case DMBIN_LOWER:
        return newSVdual(aTHX_ DMBIN_LOWER, "lower");
#endif
#ifdef DMBIN_MANUAL
    case DMBIN_MANUAL:
        return newSVdual(aTHX_ DMBIN_MANUAL, "manual");
#endif
#ifdef DMBIN_MIDDLE
    case DMBIN_MIDDLE:
        return newSVdual(aTHX_ DMBIN_MIDDLE, "middle");
#endif
#ifdef DMBIN_TRACTOR
    case DMBIN_TRACTOR:
        return newSVdual(aTHX_ DMBIN_TRACTOR, "tractor");
#endif
#ifdef DMBIN_SMALLFMT
    case DMBIN_SMALLFMT:
        return newSVdual(aTHX_ DMBIN_SMALLFMT, "smallfmt");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmbin(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'a':
#ifdef DMBIN_AUTO
                if (len == 4 && strnEQ("auto", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_AUTO);
#endif
                    return DMBIN_AUTO;
                }
#endif

                break;
            case 'c':
#ifdef DMBIN_CASSETTE
                if (len == 8 && strnEQ("cassette", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_CASSETTE);
#endif
                    return DMBIN_CASSETTE;
                }
#endif

                break;
            case 'e':
#ifdef DMBIN_ENVELOPE
                if (len == 8 && strnEQ("envelope", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_ENVELOPE);
#endif
                    return DMBIN_ENVELOPE;
                }
#endif

#ifdef DMBIN_ENVMANUAL
                if (len == 9 && strnEQ("envmanual", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_ENVMANUAL);
#endif
                    return DMBIN_ENVMANUAL;
                }
#endif

                break;
            case 'f':
#ifdef DMBIN_FIRST
                if (len == 5 && strnEQ("first", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_FIRST);
#endif
                    return DMBIN_FIRST;
                }
#endif

#ifdef DMBIN_FORMSOURCE
                if (len == 10 && strnEQ("formsource", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_FORMSOURCE);
#endif
                    return DMBIN_FORMSOURCE;
                }
#endif

                break;
            case 'l':
#ifdef DMBIN_LARGECAPACITY
                if (len == 13 && strnEQ("largecapacity", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_LARGECAPACITY);
#endif
                    return DMBIN_LARGECAPACITY;
                }
#endif

#ifdef DMBIN_LARGEFMT
                if (len == 8 && strnEQ("largefmt", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_LARGEFMT);
#endif
                    return DMBIN_LARGEFMT;
                }
#endif

#ifdef DMBIN_LAST
                if (len == 4 && strnEQ("last", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_LAST);
#endif
                    return DMBIN_LAST;
                }
#endif

#ifdef DMBIN_LOWER
                if (len == 5 && strnEQ("lower", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_LOWER);
#endif
                    return DMBIN_LOWER;
                }
#endif

                break;
            case 'm':
#ifdef DMBIN_MANUAL
                if (len == 6 && strnEQ("manual", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_MANUAL);
#endif
                    return DMBIN_MANUAL;
                }
#endif

#ifdef DMBIN_MIDDLE
                if (len == 6 && strnEQ("middle", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_MIDDLE);
#endif
                    return DMBIN_MIDDLE;
                }
#endif

                break;
            case 'o':
#ifdef DMBIN_ONLYONE
                if (len == 7 && strnEQ("onlyone", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_ONLYONE);
#endif
                    return DMBIN_ONLYONE;
                }
#endif

                break;
            case 's':
#ifdef DMBIN_SMALLFMT
                if (len == 8 && strnEQ("smallfmt", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_SMALLFMT);
#endif
                    return DMBIN_SMALLFMT;
                }
#endif

                break;
            case 't':
#ifdef DMBIN_TRACTOR
                if (len == 7 && strnEQ("tractor", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_TRACTOR);
#endif
                    return DMBIN_TRACTOR;
                }
#endif

                break;
            case 'u':
#ifdef DMBIN_UPPER
                if (len == 5 && strnEQ("upper", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmbin", pv, DMBIN_UPPER);
#endif
                    return DMBIN_UPPER;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmcollate_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMCOLLATE_TRUE
    case DMCOLLATE_TRUE:
        return newSVdual(aTHX_ DMCOLLATE_TRUE, "true");
#endif
#ifdef DMCOLLATE_FALSE
    case DMCOLLATE_FALSE:
        return newSVdual(aTHX_ DMCOLLATE_FALSE, "false");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmcollate(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'f':
#ifdef DMCOLLATE_FALSE
                if (len == 5 && strnEQ("false", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmcollate", pv, DMCOLLATE_FALSE);
#endif
                    return DMCOLLATE_FALSE;
                }
#endif

                break;
            case 't':
#ifdef DMCOLLATE_TRUE
                if (len == 4 && strnEQ("true", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmcollate", pv, DMCOLLATE_TRUE);
#endif
                    return DMCOLLATE_TRUE;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmcolor_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMCOLOR_COLOR
    case DMCOLOR_COLOR:
        return newSVdual(aTHX_ DMCOLOR_COLOR, "color");
#endif
#ifdef DMCOLOR_MONOCHROME
    case DMCOLOR_MONOCHROME:
        return newSVdual(aTHX_ DMCOLOR_MONOCHROME, "monochrome");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmcolor(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'c':
#ifdef DMCOLOR_COLOR
                if (len == 5 && strnEQ("color", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmcolor", pv, DMCOLOR_COLOR);
#endif
                    return DMCOLOR_COLOR;
                }
#endif

                break;
            case 'm':
#ifdef DMCOLOR_MONOCHROME
                if (len == 10 && strnEQ("monochrome", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmcolor", pv, DMCOLOR_MONOCHROME);
#endif
                    return DMCOLOR_MONOCHROME;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmdfo_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMDFO_DEFAULT
    case DMDFO_DEFAULT:
        return newSVdual(aTHX_ DMDFO_DEFAULT, "default");
#endif
#ifdef DMDFO_CENTER
    case DMDFO_CENTER:
        return newSVdual(aTHX_ DMDFO_CENTER, "center");
#endif
#ifdef DMDFO_STRETCH
    case DMDFO_STRETCH:
        return newSVdual(aTHX_ DMDFO_STRETCH, "stretch");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmdfo(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'c':
#ifdef DMDFO_CENTER
                if (len == 6 && strnEQ("center", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdfo", pv, DMDFO_CENTER);
#endif
                    return DMDFO_CENTER;
                }
#endif

                break;
            case 'd':
#ifdef DMDFO_DEFAULT
                if (len == 7 && strnEQ("default", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdfo", pv, DMDFO_DEFAULT);
#endif
                    return DMDFO_DEFAULT;
                }
#endif

                break;
            case 's':
#ifdef DMDFO_STRETCH
                if (len == 7 && strnEQ("stretch", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdfo", pv, DMDFO_STRETCH);
#endif
                    return DMDFO_STRETCH;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmdisplayflags_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DM_GRAYSCALE
    case DM_GRAYSCALE:
        return newSVdual(aTHX_ DM_GRAYSCALE, "grayscale");
#endif
#ifdef DM_INTERLACED
    case DM_INTERLACED:
        return newSVdual(aTHX_ DM_INTERLACED, "interlaced");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmdisplayflags(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'g':
#ifdef DM_GRAYSCALE
                if (len == 9 && strnEQ("grayscale", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdisplayflags", pv, DM_GRAYSCALE);
#endif
                    return DM_GRAYSCALE;
                }
#endif

                break;
            case 'i':
#ifdef DM_INTERLACED
                if (len == 10 && strnEQ("interlaced", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdisplayflags", pv, DM_INTERLACED);
#endif
                    return DM_INTERLACED;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmdither_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMDITHER_NONE
    case DMDITHER_NONE:
        return newSVdual(aTHX_ DMDITHER_NONE, "none");
#endif
#ifdef DMDITHER_COARSE
    case DMDITHER_COARSE:
        return newSVdual(aTHX_ DMDITHER_COARSE, "coarse");
#endif
#ifdef DMDITHER_FINE
    case DMDITHER_FINE:
        return newSVdual(aTHX_ DMDITHER_FINE, "fine");
#endif
#ifdef DMDITHER_LINEART
    case DMDITHER_LINEART:
        return newSVdual(aTHX_ DMDITHER_LINEART, "lineart");
#endif
#ifdef DMDITHER_GRAYSCALE
    case DMDITHER_GRAYSCALE:
        return newSVdual(aTHX_ DMDITHER_GRAYSCALE, "grayscale");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmdither(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'c':
#ifdef DMDITHER_COARSE
                if (len == 6 && strnEQ("coarse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdither", pv, DMDITHER_COARSE);
#endif
                    return DMDITHER_COARSE;
                }
#endif

                break;
            case 'f':
#ifdef DMDITHER_FINE
                if (len == 4 && strnEQ("fine", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdither", pv, DMDITHER_FINE);
#endif
                    return DMDITHER_FINE;
                }
#endif

                break;
            case 'g':
#ifdef DMDITHER_GRAYSCALE
                if (len == 9 && strnEQ("grayscale", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdither", pv, DMDITHER_GRAYSCALE);
#endif
                    return DMDITHER_GRAYSCALE;
                }
#endif

                break;
            case 'l':
#ifdef DMDITHER_LINEART
                if (len == 7 && strnEQ("lineart", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdither", pv, DMDITHER_LINEART);
#endif
                    return DMDITHER_LINEART;
                }
#endif

                break;
            case 'n':
#ifdef DMDITHER_NONE
                if (len == 4 && strnEQ("none", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdither", pv, DMDITHER_NONE);
#endif
                    return DMDITHER_NONE;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmdo_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMDO_DEFAULT
    case DMDO_DEFAULT:
        return newSVdual(aTHX_ DMDO_DEFAULT, "default");
#endif
#ifdef DMDO_90
    case DMDO_90:
        return newSVdual(aTHX_ DMDO_90, "90");
#endif
#ifdef DMDO_180
    case DMDO_180:
        return newSVdual(aTHX_ DMDO_180, "180");
#endif
#ifdef DMDO_270
    case DMDO_270:
        return newSVdual(aTHX_ DMDO_270, "270");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmdo(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case '1':
#ifdef DMDO_180
                if (len == 3 && strnEQ("180", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdo", pv, DMDO_180);
#endif
                    return DMDO_180;
                }
#endif

                break;
            case '2':
#ifdef DMDO_270
                if (len == 3 && strnEQ("270", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdo", pv, DMDO_270);
#endif
                    return DMDO_270;
                }
#endif

                break;
            case '9':
#ifdef DMDO_90
                if (len == 2 && strnEQ("90", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdo", pv, DMDO_90);
#endif
                    return DMDO_90;
                }
#endif

                break;
            case 'd':
#ifdef DMDO_DEFAULT
                if (len == 7 && strnEQ("default", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdo", pv, DMDO_DEFAULT);
#endif
                    return DMDO_DEFAULT;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmdup_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMDUP_SIMPLEX
    case DMDUP_SIMPLEX:
        return newSVdual(aTHX_ DMDUP_SIMPLEX, "simplex");
#endif
#ifdef DMDUP_HORIZONTAL
    case DMDUP_HORIZONTAL:
        return newSVdual(aTHX_ DMDUP_HORIZONTAL, "horizontal");
#endif
#ifdef DMDUP_VERTICAL
    case DMDUP_VERTICAL:
        return newSVdual(aTHX_ DMDUP_VERTICAL, "vertical");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmdup(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'h':
#ifdef DMDUP_HORIZONTAL
                if (len == 10 && strnEQ("horizontal", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdup", pv, DMDUP_HORIZONTAL);
#endif
                    return DMDUP_HORIZONTAL;
                }
#endif

                break;
            case 's':
#ifdef DMDUP_SIMPLEX
                if (len == 7 && strnEQ("simplex", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdup", pv, DMDUP_SIMPLEX);
#endif
                    return DMDUP_SIMPLEX;
                }
#endif

                break;
            case 'v':
#ifdef DMDUP_VERTICAL
                if (len == 8 && strnEQ("vertical", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmdup", pv, DMDUP_VERTICAL);
#endif
                    return DMDUP_VERTICAL;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmfield_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DM_ORIENTATION
    case DM_ORIENTATION:
        return newSVdual(aTHX_ DM_ORIENTATION, "orientation");
#endif
#ifdef DM_PAPERSIZE
    case DM_PAPERSIZE:
        return newSVdual(aTHX_ DM_PAPERSIZE, "papersize");
#endif
#ifdef DM_PAPERLENGTH
    case DM_PAPERLENGTH:
        return newSVdual(aTHX_ DM_PAPERLENGTH, "paperlength");
#endif
#ifdef DM_PAPERWIDTH
    case DM_PAPERWIDTH:
        return newSVdual(aTHX_ DM_PAPERWIDTH, "paperwidth");
#endif
#ifdef DM_SCALE
    case DM_SCALE:
        return newSVdual(aTHX_ DM_SCALE, "scale");
#endif
#ifdef DM_COPIES
    case DM_COPIES:
        return newSVdual(aTHX_ DM_COPIES, "copies");
#endif
#ifdef DM_DEFAULTSOURCE
    case DM_DEFAULTSOURCE:
        return newSVdual(aTHX_ DM_DEFAULTSOURCE, "defaultsource");
#endif
#ifdef DM_PRINTQUALITY
    case DM_PRINTQUALITY:
        return newSVdual(aTHX_ DM_PRINTQUALITY, "printquality");
#endif
#ifdef DM_POSITION
    case DM_POSITION:
        return newSVdual(aTHX_ DM_POSITION, "position");
#endif
#ifdef DM_DISPLAYORIENTATION
    case DM_DISPLAYORIENTATION:
        return newSVdual(aTHX_ DM_DISPLAYORIENTATION, "displayorientation");
#endif
#ifdef DM_DISPLAYFIXEDOUTPUT
    case DM_DISPLAYFIXEDOUTPUT:
        return newSVdual(aTHX_ DM_DISPLAYFIXEDOUTPUT, "displayfixedoutput");
#endif
#ifdef DM_COLOR
    case DM_COLOR:
        return newSVdual(aTHX_ DM_COLOR, "color");
#endif
#ifdef DM_DUPLEX
    case DM_DUPLEX:
        return newSVdual(aTHX_ DM_DUPLEX, "duplex");
#endif
#ifdef DM_YRESOLUTION
    case DM_YRESOLUTION:
        return newSVdual(aTHX_ DM_YRESOLUTION, "yresolution");
#endif
#ifdef DM_TTOPTION
    case DM_TTOPTION:
        return newSVdual(aTHX_ DM_TTOPTION, "ttoption");
#endif
#ifdef DM_COLLATE
    case DM_COLLATE:
        return newSVdual(aTHX_ DM_COLLATE, "collate");
#endif
#ifdef DM_FORMNAME
    case DM_FORMNAME:
        return newSVdual(aTHX_ DM_FORMNAME, "formname");
#endif
#ifdef DM_LOGPIXELS
    case DM_LOGPIXELS:
        return newSVdual(aTHX_ DM_LOGPIXELS, "logpixels");
#endif
#ifdef DM_BITSPERPEL
    case DM_BITSPERPEL:
        return newSVdual(aTHX_ DM_BITSPERPEL, "bitsperpel");
#endif
#ifdef DM_PELSWIDTH
    case DM_PELSWIDTH:
        return newSVdual(aTHX_ DM_PELSWIDTH, "pelswidth");
#endif
#ifdef DM_PELSHEIGHT
    case DM_PELSHEIGHT:
        return newSVdual(aTHX_ DM_PELSHEIGHT, "pelsheight");
#endif
#ifdef DM_DISPLAYFLAGS
    case DM_DISPLAYFLAGS:
        return newSVdual(aTHX_ DM_DISPLAYFLAGS, "displayflags");
#endif
#ifdef DM_NUP
    case DM_NUP:
        return newSVdual(aTHX_ DM_NUP, "nup");
#endif
#ifdef DM_DISPLAYFREQUENCY
    case DM_DISPLAYFREQUENCY:
        return newSVdual(aTHX_ DM_DISPLAYFREQUENCY, "displayfrequency");
#endif
#ifdef DM_ICMMETHOD
    case DM_ICMMETHOD:
        return newSVdual(aTHX_ DM_ICMMETHOD, "icmmethod");
#endif
#ifdef DM_ICMINTENT
    case DM_ICMINTENT:
        return newSVdual(aTHX_ DM_ICMINTENT, "icmintent");
#endif
#ifdef DM_MEDIATYPE
    case DM_MEDIATYPE:
        return newSVdual(aTHX_ DM_MEDIATYPE, "mediatype");
#endif
#ifdef DM_DITHERTYPE
    case DM_DITHERTYPE:
        return newSVdual(aTHX_ DM_DITHERTYPE, "dithertype");
#endif
#ifdef DM_PANNINGWIDTH
    case DM_PANNINGWIDTH:
        return newSVdual(aTHX_ DM_PANNINGWIDTH, "panningwidth");
#endif
#ifdef DM_PANNINGHEIGHT
    case DM_PANNINGHEIGHT:
        return newSVdual(aTHX_ DM_PANNINGHEIGHT, "panningheight");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmfield(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'b':
#ifdef DM_BITSPERPEL
                if (len == 10 && strnEQ("bitsperpel", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_BITSPERPEL);
#endif
                    return DM_BITSPERPEL;
                }
#endif

                break;
            case 'c':
#ifdef DM_COPIES
                if (len == 6 && strnEQ("copies", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_COPIES);
#endif
                    return DM_COPIES;
                }
#endif

#ifdef DM_COLOR
                if (len == 5 && strnEQ("color", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_COLOR);
#endif
                    return DM_COLOR;
                }
#endif

#ifdef DM_COLLATE
                if (len == 7 && strnEQ("collate", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_COLLATE);
#endif
                    return DM_COLLATE;
                }
#endif

                break;
            case 'd':
#ifdef DM_DEFAULTSOURCE
                if (len == 13 && strnEQ("defaultsource", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DEFAULTSOURCE);
#endif
                    return DM_DEFAULTSOURCE;
                }
#endif

#ifdef DM_DISPLAYORIENTATION
                if (len == 18 && strnEQ("displayorientation", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DISPLAYORIENTATION);
#endif
                    return DM_DISPLAYORIENTATION;
                }
#endif

#ifdef DM_DISPLAYFIXEDOUTPUT
                if (len == 18 && strnEQ("displayfixedoutput", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DISPLAYFIXEDOUTPUT);
#endif
                    return DM_DISPLAYFIXEDOUTPUT;
                }
#endif

#ifdef DM_DUPLEX
                if (len == 6 && strnEQ("duplex", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DUPLEX);
#endif
                    return DM_DUPLEX;
                }
#endif

#ifdef DM_DISPLAYFLAGS
                if (len == 12 && strnEQ("displayflags", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DISPLAYFLAGS);
#endif
                    return DM_DISPLAYFLAGS;
                }
#endif

#ifdef DM_DISPLAYFREQUENCY
                if (len == 16 && strnEQ("displayfrequency", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DISPLAYFREQUENCY);
#endif
                    return DM_DISPLAYFREQUENCY;
                }
#endif

#ifdef DM_DITHERTYPE
                if (len == 10 && strnEQ("dithertype", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_DITHERTYPE);
#endif
                    return DM_DITHERTYPE;
                }
#endif

                break;
            case 'f':
#ifdef DM_FORMNAME
                if (len == 8 && strnEQ("formname", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_FORMNAME);
#endif
                    return DM_FORMNAME;
                }
#endif

                break;
            case 'i':
#ifdef DM_ICMMETHOD
                if (len == 9 && strnEQ("icmmethod", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_ICMMETHOD);
#endif
                    return DM_ICMMETHOD;
                }
#endif

#ifdef DM_ICMINTENT
                if (len == 9 && strnEQ("icmintent", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_ICMINTENT);
#endif
                    return DM_ICMINTENT;
                }
#endif

                break;
            case 'l':
#ifdef DM_LOGPIXELS
                if (len == 9 && strnEQ("logpixels", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_LOGPIXELS);
#endif
                    return DM_LOGPIXELS;
                }
#endif

                break;
            case 'm':
#ifdef DM_MEDIATYPE
                if (len == 9 && strnEQ("mediatype", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_MEDIATYPE);
#endif
                    return DM_MEDIATYPE;
                }
#endif

                break;
            case 'n':
#ifdef DM_NUP
                if (len == 3 && strnEQ("nup", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_NUP);
#endif
                    return DM_NUP;
                }
#endif

                break;
            case 'o':
#ifdef DM_ORIENTATION
                if (len == 11 && strnEQ("orientation", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_ORIENTATION);
#endif
                    return DM_ORIENTATION;
                }
#endif

                break;
            case 'p':
#ifdef DM_PAPERSIZE
                if (len == 9 && strnEQ("papersize", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PAPERSIZE);
#endif
                    return DM_PAPERSIZE;
                }
#endif

#ifdef DM_PAPERLENGTH
                if (len == 11 && strnEQ("paperlength", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PAPERLENGTH);
#endif
                    return DM_PAPERLENGTH;
                }
#endif

#ifdef DM_PAPERWIDTH
                if (len == 10 && strnEQ("paperwidth", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PAPERWIDTH);
#endif
                    return DM_PAPERWIDTH;
                }
#endif

#ifdef DM_PRINTQUALITY
                if (len == 12 && strnEQ("printquality", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PRINTQUALITY);
#endif
                    return DM_PRINTQUALITY;
                }
#endif

#ifdef DM_POSITION
                if (len == 8 && strnEQ("position", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_POSITION);
#endif
                    return DM_POSITION;
                }
#endif

#ifdef DM_PELSWIDTH
                if (len == 9 && strnEQ("pelswidth", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PELSWIDTH);
#endif
                    return DM_PELSWIDTH;
                }
#endif

#ifdef DM_PELSHEIGHT
                if (len == 10 && strnEQ("pelsheight", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PELSHEIGHT);
#endif
                    return DM_PELSHEIGHT;
                }
#endif

#ifdef DM_PANNINGWIDTH
                if (len == 12 && strnEQ("panningwidth", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PANNINGWIDTH);
#endif
                    return DM_PANNINGWIDTH;
                }
#endif

#ifdef DM_PANNINGHEIGHT
                if (len == 13 && strnEQ("panningheight", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_PANNINGHEIGHT);
#endif
                    return DM_PANNINGHEIGHT;
                }
#endif

                break;
            case 's':
#ifdef DM_SCALE
                if (len == 5 && strnEQ("scale", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_SCALE);
#endif
                    return DM_SCALE;
                }
#endif

                break;
            case 't':
#ifdef DM_TTOPTION
                if (len == 8 && strnEQ("ttoption", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_TTOPTION);
#endif
                    return DM_TTOPTION;
                }
#endif

                break;
            case 'y':
#ifdef DM_YRESOLUTION
                if (len == 11 && strnEQ("yresolution", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmfield", pv, DM_YRESOLUTION);
#endif
                    return DM_YRESOLUTION;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmicm_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMICM_ABS_COLORIMETRIC
    case DMICM_ABS_COLORIMETRIC:
        return newSVdual(aTHX_ DMICM_ABS_COLORIMETRIC, "abs_colorimetric");
#endif
#ifdef DMICM_COLORIMETRIC
    case DMICM_COLORIMETRIC:
        return newSVdual(aTHX_ DMICM_COLORIMETRIC, "colorimetric");
#endif
#ifdef DMICM_CONTRAST
    case DMICM_CONTRAST:
        return newSVdual(aTHX_ DMICM_CONTRAST, "contrast");
#endif
#ifdef DMICM_SATURATE
    case DMICM_SATURATE:
        return newSVdual(aTHX_ DMICM_SATURATE, "saturate");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmicm(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'a':
#ifdef DMICM_ABS_COLORIMETRIC
                if (len == 16 && strnEQ("abs_colorimetric", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicm", pv, DMICM_ABS_COLORIMETRIC);
#endif
                    return DMICM_ABS_COLORIMETRIC;
                }
#endif

                break;
            case 'c':
#ifdef DMICM_COLORIMETRIC
                if (len == 12 && strnEQ("colorimetric", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicm", pv, DMICM_COLORIMETRIC);
#endif
                    return DMICM_COLORIMETRIC;
                }
#endif

#ifdef DMICM_CONTRAST
                if (len == 8 && strnEQ("contrast", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicm", pv, DMICM_CONTRAST);
#endif
                    return DMICM_CONTRAST;
                }
#endif

                break;
            case 's':
#ifdef DMICM_SATURATE
                if (len == 8 && strnEQ("saturate", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicm", pv, DMICM_SATURATE);
#endif
                    return DMICM_SATURATE;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmicmethod_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMICMMETHOD_NONE
    case DMICMMETHOD_NONE:
        return newSVdual(aTHX_ DMICMMETHOD_NONE, "none");
#endif
#ifdef DMICMMETHOD_SYSTEM
    case DMICMMETHOD_SYSTEM:
        return newSVdual(aTHX_ DMICMMETHOD_SYSTEM, "system");
#endif
#ifdef DMICMMETHOD_DRIVER
    case DMICMMETHOD_DRIVER:
        return newSVdual(aTHX_ DMICMMETHOD_DRIVER, "driver");
#endif
#ifdef DMICMMETHOD_DEVICE
    case DMICMMETHOD_DEVICE:
        return newSVdual(aTHX_ DMICMMETHOD_DEVICE, "device");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmicmethod(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'd':
#ifdef DMICMMETHOD_DRIVER
                if (len == 6 && strnEQ("driver", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicmethod", pv, DMICMMETHOD_DRIVER);
#endif
                    return DMICMMETHOD_DRIVER;
                }
#endif

#ifdef DMICMMETHOD_DEVICE
                if (len == 6 && strnEQ("device", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicmethod", pv, DMICMMETHOD_DEVICE);
#endif
                    return DMICMMETHOD_DEVICE;
                }
#endif

                break;
            case 'n':
#ifdef DMICMMETHOD_NONE
                if (len == 4 && strnEQ("none", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicmethod", pv, DMICMMETHOD_NONE);
#endif
                    return DMICMMETHOD_NONE;
                }
#endif

                break;
            case 's':
#ifdef DMICMMETHOD_SYSTEM
                if (len == 6 && strnEQ("system", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmicmethod", pv, DMICMMETHOD_SYSTEM);
#endif
                    return DMICMMETHOD_SYSTEM;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmmedia_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMMEDIA_STANDARD
    case DMMEDIA_STANDARD:
        return newSVdual(aTHX_ DMMEDIA_STANDARD, "standard");
#endif
#ifdef DMMEDIA_GLOSSY
    case DMMEDIA_GLOSSY:
        return newSVdual(aTHX_ DMMEDIA_GLOSSY, "glossy");
#endif
#ifdef DMMEDIA_TRANSPARENCY
    case DMMEDIA_TRANSPARENCY:
        return newSVdual(aTHX_ DMMEDIA_TRANSPARENCY, "transparency");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmmedia(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'g':
#ifdef DMMEDIA_GLOSSY
                if (len == 6 && strnEQ("glossy", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmmedia", pv, DMMEDIA_GLOSSY);
#endif
                    return DMMEDIA_GLOSSY;
                }
#endif

                break;
            case 's':
#ifdef DMMEDIA_STANDARD
                if (len == 8 && strnEQ("standard", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmmedia", pv, DMMEDIA_STANDARD);
#endif
                    return DMMEDIA_STANDARD;
                }
#endif

                break;
            case 't':
#ifdef DMMEDIA_TRANSPARENCY
                if (len == 12 && strnEQ("transparency", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmmedia", pv, DMMEDIA_TRANSPARENCY);
#endif
                    return DMMEDIA_TRANSPARENCY;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmnup_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMNUP_SYSTEM
    case DMNUP_SYSTEM:
        return newSVdual(aTHX_ DMNUP_SYSTEM, "system");
#endif
#ifdef DMNUP_ONEUP
    case DMNUP_ONEUP:
        return newSVdual(aTHX_ DMNUP_ONEUP, "oneup");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmnup(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'o':
#ifdef DMNUP_ONEUP
                if (len == 5 && strnEQ("oneup", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmnup", pv, DMNUP_ONEUP);
#endif
                    return DMNUP_ONEUP;
                }
#endif

                break;
            case 's':
#ifdef DMNUP_SYSTEM
                if (len == 6 && strnEQ("system", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmnup", pv, DMNUP_SYSTEM);
#endif
                    return DMNUP_SYSTEM;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmpaper_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMPAPER_LETTER
    case DMPAPER_LETTER:
        return newSVdual(aTHX_ DMPAPER_LETTER, "letter");
#endif
#ifdef DMPAPER_LEGAL
    case DMPAPER_LEGAL:
        return newSVdual(aTHX_ DMPAPER_LEGAL, "legal");
#endif
#ifdef DMPAPER_9X11
    case DMPAPER_9X11:
        return newSVdual(aTHX_ DMPAPER_9X11, "9x11");
#endif
#ifdef DMPAPER_10X11
    case DMPAPER_10X11:
        return newSVdual(aTHX_ DMPAPER_10X11, "10x11");
#endif
#ifdef DMPAPER_10X14
    case DMPAPER_10X14:
        return newSVdual(aTHX_ DMPAPER_10X14, "10x14");
#endif
#ifdef DMPAPER_15X11
    case DMPAPER_15X11:
        return newSVdual(aTHX_ DMPAPER_15X11, "15x11");
#endif
#ifdef DMPAPER_11X17
    case DMPAPER_11X17:
        return newSVdual(aTHX_ DMPAPER_11X17, "11x17");
#endif
#ifdef DMPAPER_12X11
    case DMPAPER_12X11:
        return newSVdual(aTHX_ DMPAPER_12X11, "12x11");
#endif
#ifdef DMPAPER_A2
    case DMPAPER_A2:
        return newSVdual(aTHX_ DMPAPER_A2, "a2");
#endif
#ifdef DMPAPER_A3
    case DMPAPER_A3:
        return newSVdual(aTHX_ DMPAPER_A3, "a3");
#endif
#ifdef DMPAPER_A3_EXTRA
    case DMPAPER_A3_EXTRA:
        return newSVdual(aTHX_ DMPAPER_A3_EXTRA, "a3_extra");
#endif
#ifdef DMPAPER_A3_EXTRA_TRAVERSE
    case DMPAPER_A3_EXTRA_TRAVERSE:
        return newSVdual(aTHX_ DMPAPER_A3_EXTRA_TRAVERSE, "a3_extra_traverse");
#endif
#ifdef DMPAPER_A3_ROTATED
    case DMPAPER_A3_ROTATED:
        return newSVdual(aTHX_ DMPAPER_A3_ROTATED, "a3_rotated");
#endif
#ifdef DMPAPER_A3_TRAVERSE
    case DMPAPER_A3_TRAVERSE:
        return newSVdual(aTHX_ DMPAPER_A3_TRAVERSE, "a3_traverse");
#endif
#ifdef DMPAPER_A4
    case DMPAPER_A4:
        return newSVdual(aTHX_ DMPAPER_A4, "a4");
#endif
#ifdef DMPAPER_A4_EXTRA
    case DMPAPER_A4_EXTRA:
        return newSVdual(aTHX_ DMPAPER_A4_EXTRA, "a4_extra");
#endif
#ifdef DMPAPER_A4_PLUS
    case DMPAPER_A4_PLUS:
        return newSVdual(aTHX_ DMPAPER_A4_PLUS, "a4_plus");
#endif
#ifdef DMPAPER_A4_ROTATED
    case DMPAPER_A4_ROTATED:
        return newSVdual(aTHX_ DMPAPER_A4_ROTATED, "a4_rotated");
#endif
#ifdef DMPAPER_A4SMALL
    case DMPAPER_A4SMALL:
        return newSVdual(aTHX_ DMPAPER_A4SMALL, "a4small");
#endif
#ifdef DMPAPER_A4_TRANSVERSE
    case DMPAPER_A4_TRANSVERSE:
        return newSVdual(aTHX_ DMPAPER_A4_TRANSVERSE, "a4_transverse");
#endif
#ifdef DMPAPER_A5
    case DMPAPER_A5:
        return newSVdual(aTHX_ DMPAPER_A5, "a5");
#endif
#ifdef DMPAPER_A5_EXTRA
    case DMPAPER_A5_EXTRA:
        return newSVdual(aTHX_ DMPAPER_A5_EXTRA, "a5_extra");
#endif
#ifdef DMPAPER_A5_ROTATED
    case DMPAPER_A5_ROTATED:
        return newSVdual(aTHX_ DMPAPER_A5_ROTATED, "a5_rotated");
#endif
#ifdef DMPAPER_A5_TRANSVERSE
    case DMPAPER_A5_TRANSVERSE:
        return newSVdual(aTHX_ DMPAPER_A5_TRANSVERSE, "a5_transverse");
#endif
#ifdef DMPAPER_A6
    case DMPAPER_A6:
        return newSVdual(aTHX_ DMPAPER_A6, "a6");
#endif
#ifdef DMPAPER_A6_ROTATED
    case DMPAPER_A6_ROTATED:
        return newSVdual(aTHX_ DMPAPER_A6_ROTATED, "a6_rotated");
#endif
#ifdef DMPAPER_A_PLUS
    case DMPAPER_A_PLUS:
        return newSVdual(aTHX_ DMPAPER_A_PLUS, "a_plus");
#endif
#ifdef DMPAPER_B4
    case DMPAPER_B4:
        return newSVdual(aTHX_ DMPAPER_B4, "b4");
#endif
#ifdef DMPAPER_B4_JIS_ROTATED
    case DMPAPER_B4_JIS_ROTATED:
        return newSVdual(aTHX_ DMPAPER_B4_JIS_ROTATED, "b4_jis_rotated");
#endif
#ifdef DMPAPER_B5
    case DMPAPER_B5:
        return newSVdual(aTHX_ DMPAPER_B5, "b5");
#endif
#ifdef DMPAPER_B5_EXTRA
    case DMPAPER_B5_EXTRA:
        return newSVdual(aTHX_ DMPAPER_B5_EXTRA, "b5_extra");
#endif
#ifdef DMPAPER_B5_JIS_ROTATED
    case DMPAPER_B5_JIS_ROTATED:
        return newSVdual(aTHX_ DMPAPER_B5_JIS_ROTATED, "b5_jis_rotated");
#endif
#ifdef DMPAPER_B6_JIS
    case DMPAPER_B6_JIS:
        return newSVdual(aTHX_ DMPAPER_B6_JIS, "b6_jis");
#endif
#ifdef DMPAPER_B6_JIS_ROTATED
    case DMPAPER_B6_JIS_ROTATED:
        return newSVdual(aTHX_ DMPAPER_B6_JIS_ROTATED, "b6_jis_rotated");
#endif
#ifdef DMPAPER_B_PLUS
    case DMPAPER_B_PLUS:
        return newSVdual(aTHX_ DMPAPER_B_PLUS, "b_plus");
#endif
#ifdef DMPAPER_CSHEET
    case DMPAPER_CSHEET:
        return newSVdual(aTHX_ DMPAPER_CSHEET, "csheet");
#endif
#ifdef DMPAPER_DBL_JAPANESE_POSTCARD
    case DMPAPER_DBL_JAPANESE_POSTCARD:
        return newSVdual(aTHX_ DMPAPER_DBL_JAPANESE_POSTCARD, "dbl_japanese_postcard");
#endif
#ifdef DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED
    case DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED:
        return newSVdual(aTHX_ DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED, "dbl_japanese_postcard_rotated");
#endif
#ifdef DMPAPER_DSHEET
    case DMPAPER_DSHEET:
        return newSVdual(aTHX_ DMPAPER_DSHEET, "dsheet");
#endif
#ifdef DMPAPER_ENV_9
    case DMPAPER_ENV_9:
        return newSVdual(aTHX_ DMPAPER_ENV_9, "env_9");
#endif
#ifdef DMPAPER_ENV_10
    case DMPAPER_ENV_10:
        return newSVdual(aTHX_ DMPAPER_ENV_10, "env_10");
#endif
#ifdef DMPAPER_ENV_11
    case DMPAPER_ENV_11:
        return newSVdual(aTHX_ DMPAPER_ENV_11, "env_11");
#endif
#ifdef DMPAPER_ENV_12
    case DMPAPER_ENV_12:
        return newSVdual(aTHX_ DMPAPER_ENV_12, "env_12");
#endif
#ifdef DMPAPER_ENV_14
    case DMPAPER_ENV_14:
        return newSVdual(aTHX_ DMPAPER_ENV_14, "env_14");
#endif
#ifdef DMPAPER_ENV_C5
    case DMPAPER_ENV_C5:
        return newSVdual(aTHX_ DMPAPER_ENV_C5, "env_c5");
#endif
#ifdef DMPAPER_ENV_C3
    case DMPAPER_ENV_C3:
        return newSVdual(aTHX_ DMPAPER_ENV_C3, "env_c3");
#endif
#ifdef DMPAPER_ENV_C4
    case DMPAPER_ENV_C4:
        return newSVdual(aTHX_ DMPAPER_ENV_C4, "env_c4");
#endif
#ifdef DMPAPER_ENV_C6
    case DMPAPER_ENV_C6:
        return newSVdual(aTHX_ DMPAPER_ENV_C6, "env_c6");
#endif
#ifdef DMPAPER_ENV_C65
    case DMPAPER_ENV_C65:
        return newSVdual(aTHX_ DMPAPER_ENV_C65, "env_c65");
#endif
#ifdef DMPAPER_ENV_B4
    case DMPAPER_ENV_B4:
        return newSVdual(aTHX_ DMPAPER_ENV_B4, "env_b4");
#endif
#ifdef DMPAPER_ENV_B5
    case DMPAPER_ENV_B5:
        return newSVdual(aTHX_ DMPAPER_ENV_B5, "env_b5");
#endif
#ifdef DMPAPER_ENV_B6
    case DMPAPER_ENV_B6:
        return newSVdual(aTHX_ DMPAPER_ENV_B6, "env_b6");
#endif
#ifdef DMPAPER_ENV_DL
    case DMPAPER_ENV_DL:
        return newSVdual(aTHX_ DMPAPER_ENV_DL, "env_dl");
#endif
#ifdef DMPAPER_ENV_INVITE
    case DMPAPER_ENV_INVITE:
        return newSVdual(aTHX_ DMPAPER_ENV_INVITE, "env_invite");
#endif
#ifdef DMPAPER_ENV_ITALY
    case DMPAPER_ENV_ITALY:
        return newSVdual(aTHX_ DMPAPER_ENV_ITALY, "env_italy");
#endif
#ifdef DMPAPER_ENV_MONARCH
    case DMPAPER_ENV_MONARCH:
        return newSVdual(aTHX_ DMPAPER_ENV_MONARCH, "env_monarch");
#endif
#ifdef DMPAPER_ENV_PERSONAL
    case DMPAPER_ENV_PERSONAL:
        return newSVdual(aTHX_ DMPAPER_ENV_PERSONAL, "env_personal");
#endif
#ifdef DMPAPER_ESHEET
    case DMPAPER_ESHEET:
        return newSVdual(aTHX_ DMPAPER_ESHEET, "esheet");
#endif
#ifdef DMPAPER_EXECUTIVE
    case DMPAPER_EXECUTIVE:
        return newSVdual(aTHX_ DMPAPER_EXECUTIVE, "executive");
#endif
#ifdef DMPAPER_FANFOLD_US
    case DMPAPER_FANFOLD_US:
        return newSVdual(aTHX_ DMPAPER_FANFOLD_US, "fanfold_us");
#endif
#ifdef DMPAPER_FANFOLD_STD_GERMAN
    case DMPAPER_FANFOLD_STD_GERMAN:
        return newSVdual(aTHX_ DMPAPER_FANFOLD_STD_GERMAN, "fanfold_std_german");
#endif
#ifdef DMPAPER_FANFOLD_LGL_GERMAN
    case DMPAPER_FANFOLD_LGL_GERMAN:
        return newSVdual(aTHX_ DMPAPER_FANFOLD_LGL_GERMAN, "fanfold_lgl_german");
#endif
#ifdef DMPAPER_FOLIO
    case DMPAPER_FOLIO:
        return newSVdual(aTHX_ DMPAPER_FOLIO, "folio");
#endif
#ifdef DMPAPER_ISO_B4
    case DMPAPER_ISO_B4:
        return newSVdual(aTHX_ DMPAPER_ISO_B4, "iso_b4");
#endif
#ifdef DMPAPER_JAPANESE_POSTCARD
    case DMPAPER_JAPANESE_POSTCARD:
        return newSVdual(aTHX_ DMPAPER_JAPANESE_POSTCARD, "japanese_postcard");
#endif
#ifdef DMPAPER_JAPANESE_POSTCARD_ROTATED
    case DMPAPER_JAPANESE_POSTCARD_ROTATED:
        return newSVdual(aTHX_ DMPAPER_JAPANESE_POSTCARD_ROTATED, "japanese_postcard_rotated");
#endif
#ifdef DMPAPER_JENV_CHOU3
    case DMPAPER_JENV_CHOU3:
        return newSVdual(aTHX_ DMPAPER_JENV_CHOU3, "jenv_chou3");
#endif
#ifdef DMPAPER_JENV_CHOU3_ROTATED
    case DMPAPER_JENV_CHOU3_ROTATED:
        return newSVdual(aTHX_ DMPAPER_JENV_CHOU3_ROTATED, "jenv_chou3_rotated");
#endif
#ifdef DMPAPER_JENV_CHOU4
    case DMPAPER_JENV_CHOU4:
        return newSVdual(aTHX_ DMPAPER_JENV_CHOU4, "jenv_chou4");
#endif
#ifdef DMPAPER_JENV_CHOU4_ROTATED
    case DMPAPER_JENV_CHOU4_ROTATED:
        return newSVdual(aTHX_ DMPAPER_JENV_CHOU4_ROTATED, "jenv_chou4_rotated");
#endif
#ifdef DMPAPER_JENV_KAKU2
    case DMPAPER_JENV_KAKU2:
        return newSVdual(aTHX_ DMPAPER_JENV_KAKU2, "jenv_kaku2");
#endif
#ifdef DMPAPER_JENV_KAKU2_ROTATED
    case DMPAPER_JENV_KAKU2_ROTATED:
        return newSVdual(aTHX_ DMPAPER_JENV_KAKU2_ROTATED, "jenv_kaku2_rotated");
#endif
#ifdef DMPAPER_JENV_KAKU3
    case DMPAPER_JENV_KAKU3:
        return newSVdual(aTHX_ DMPAPER_JENV_KAKU3, "jenv_kaku3");
#endif
#ifdef DMPAPER_JENV_KAKU3_ROTATED
    case DMPAPER_JENV_KAKU3_ROTATED:
        return newSVdual(aTHX_ DMPAPER_JENV_KAKU3_ROTATED, "jenv_kaku3_rotated");
#endif
#ifdef DMPAPER_JENV_YOU4
    case DMPAPER_JENV_YOU4:
        return newSVdual(aTHX_ DMPAPER_JENV_YOU4, "jenv_you4");
#endif
#ifdef DMPAPER_JENV_YOU4_ROTATED
    case DMPAPER_JENV_YOU4_ROTATED:
        return newSVdual(aTHX_ DMPAPER_JENV_YOU4_ROTATED, "jenv_you4_rotated");
#endif
#ifdef DMPAPER_LAST
    case DMPAPER_LAST:
        return newSVdual(aTHX_ DMPAPER_LAST, "last");
#endif
#ifdef DMPAPER_LEDGER
    case DMPAPER_LEDGER:
        return newSVdual(aTHX_ DMPAPER_LEDGER, "ledger");
#endif
#ifdef DMPAPER_LEGAL_EXTRA
    case DMPAPER_LEGAL_EXTRA:
        return newSVdual(aTHX_ DMPAPER_LEGAL_EXTRA, "legal_extra");
#endif
#ifdef DMPAPER_LETTER_EXTRA
    case DMPAPER_LETTER_EXTRA:
        return newSVdual(aTHX_ DMPAPER_LETTER_EXTRA, "letter_extra");
#endif
#ifdef DMPAPER_LETTER_EXTRA_TRANSVERSE
    case DMPAPER_LETTER_EXTRA_TRANSVERSE:
        return newSVdual(aTHX_ DMPAPER_LETTER_EXTRA_TRANSVERSE, "letter_extra_transverse");
#endif
#ifdef DMPAPER_LETTER_ROTATED
    case DMPAPER_LETTER_ROTATED:
        return newSVdual(aTHX_ DMPAPER_LETTER_ROTATED, "letter_rotated");
#endif
#ifdef DMPAPER_LETTERSMALL
    case DMPAPER_LETTERSMALL:
        return newSVdual(aTHX_ DMPAPER_LETTERSMALL, "lettersmall");
#endif
#ifdef DMPAPER_LETTER_TRANSVERSE
    case DMPAPER_LETTER_TRANSVERSE:
        return newSVdual(aTHX_ DMPAPER_LETTER_TRANSVERSE, "letter_transverse");
#endif
#ifdef DMPAPER_NOTE
    case DMPAPER_NOTE:
        return newSVdual(aTHX_ DMPAPER_NOTE, "note");
#endif
#ifdef DMPAPER_P16K
    case DMPAPER_P16K:
        return newSVdual(aTHX_ DMPAPER_P16K, "p16k");
#endif
#ifdef DMPAPER_P16K_ROTATED
    case DMPAPER_P16K_ROTATED:
        return newSVdual(aTHX_ DMPAPER_P16K_ROTATED, "p16k_rotated");
#endif
#ifdef DMPAPER_P32K
    case DMPAPER_P32K:
        return newSVdual(aTHX_ DMPAPER_P32K, "p32k");
#endif
#ifdef DMPAPER_P32K_ROTATED
    case DMPAPER_P32K_ROTATED:
        return newSVdual(aTHX_ DMPAPER_P32K_ROTATED, "p32k_rotated");
#endif
#ifdef DMPAPER_P32KBIG
    case DMPAPER_P32KBIG:
        return newSVdual(aTHX_ DMPAPER_P32KBIG, "p32kbig");
#endif
#ifdef DMPAPER_P32KBIG_ROTATED
    case DMPAPER_P32KBIG_ROTATED:
        return newSVdual(aTHX_ DMPAPER_P32KBIG_ROTATED, "p32kbig_rotated");
#endif
#ifdef DMPAPER_PENV_1
    case DMPAPER_PENV_1:
        return newSVdual(aTHX_ DMPAPER_PENV_1, "penv_1");
#endif
#ifdef DMPAPER_PENV_1_ROTATED
    case DMPAPER_PENV_1_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_1_ROTATED, "penv_1_rotated");
#endif
#ifdef DMPAPER_PENV_2
    case DMPAPER_PENV_2:
        return newSVdual(aTHX_ DMPAPER_PENV_2, "penv_2");
#endif
#ifdef DMPAPER_PENV_2_ROTATED
    case DMPAPER_PENV_2_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_2_ROTATED, "penv_2_rotated");
#endif
#ifdef DMPAPER_PENV_3
    case DMPAPER_PENV_3:
        return newSVdual(aTHX_ DMPAPER_PENV_3, "penv_3");
#endif
#ifdef DMPAPER_PENV_3_ROTATED
    case DMPAPER_PENV_3_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_3_ROTATED, "penv_3_rotated");
#endif
#ifdef DMPAPER_PENV_4
    case DMPAPER_PENV_4:
        return newSVdual(aTHX_ DMPAPER_PENV_4, "penv_4");
#endif
#ifdef DMPAPER_PENV_4_ROTATED
    case DMPAPER_PENV_4_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_4_ROTATED, "penv_4_rotated");
#endif
#ifdef DMPAPER_PENV_5
    case DMPAPER_PENV_5:
        return newSVdual(aTHX_ DMPAPER_PENV_5, "penv_5");
#endif
#ifdef DMPAPER_PENV_5_ROTATED
    case DMPAPER_PENV_5_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_5_ROTATED, "penv_5_rotated");
#endif
#ifdef DMPAPER_PENV_6
    case DMPAPER_PENV_6:
        return newSVdual(aTHX_ DMPAPER_PENV_6, "penv_6");
#endif
#ifdef DMPAPER_PENV_6_ROTATED
    case DMPAPER_PENV_6_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_6_ROTATED, "penv_6_rotated");
#endif
#ifdef DMPAPER_PENV_7
    case DMPAPER_PENV_7:
        return newSVdual(aTHX_ DMPAPER_PENV_7, "penv_7");
#endif
#ifdef DMPAPER_PENV_7_ROTATED
    case DMPAPER_PENV_7_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_7_ROTATED, "penv_7_rotated");
#endif
#ifdef DMPAPER_PENV_8
    case DMPAPER_PENV_8:
        return newSVdual(aTHX_ DMPAPER_PENV_8, "penv_8");
#endif
#ifdef DMPAPER_PENV_8_ROTATED
    case DMPAPER_PENV_8_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_8_ROTATED, "penv_8_rotated");
#endif
#ifdef DMPAPER_PENV_9
    case DMPAPER_PENV_9:
        return newSVdual(aTHX_ DMPAPER_PENV_9, "penv_9");
#endif
#ifdef DMPAPER_PENV_9_ROTATED
    case DMPAPER_PENV_9_ROTATED:
        return newSVdual(aTHX_ DMPAPER_PENV_9_ROTATED, "penv_9_rotated");
#endif
#ifdef DMPAPER_PENV_10
    case DMPAPER_PENV_10:
        return newSVdual(aTHX_ DMPAPER_PENV_10, "penv_10");
#endif
#ifdef DMPAPER_QUARTO
    case DMPAPER_QUARTO:
        return newSVdual(aTHX_ DMPAPER_QUARTO, "quarto");
#endif
#ifdef DMPAPER_STATEMENT
    case DMPAPER_STATEMENT:
        return newSVdual(aTHX_ DMPAPER_STATEMENT, "statement");
#endif
#ifdef DMPAPER_TABLOID
    case DMPAPER_TABLOID:
        return newSVdual(aTHX_ DMPAPER_TABLOID, "tabloid");
#endif
#ifdef DMPAPER_TABLOID_EXTRA
    case DMPAPER_TABLOID_EXTRA:
        return newSVdual(aTHX_ DMPAPER_TABLOID_EXTRA, "tabloid_extra");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmpaper(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case '1':
#ifdef DMPAPER_10X11
                if (len == 5 && strnEQ("10x11", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_10X11);
#endif
                    return DMPAPER_10X11;
                }
#endif

#ifdef DMPAPER_10X14
                if (len == 5 && strnEQ("10x14", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_10X14);
#endif
                    return DMPAPER_10X14;
                }
#endif

#ifdef DMPAPER_15X11
                if (len == 5 && strnEQ("15x11", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_15X11);
#endif
                    return DMPAPER_15X11;
                }
#endif

#ifdef DMPAPER_11X17
                if (len == 5 && strnEQ("11x17", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_11X17);
#endif
                    return DMPAPER_11X17;
                }
#endif

#ifdef DMPAPER_12X11
                if (len == 5 && strnEQ("12x11", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_12X11);
#endif
                    return DMPAPER_12X11;
                }
#endif

                break;
            case '9':
#ifdef DMPAPER_9X11
                if (len == 4 && strnEQ("9x11", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_9X11);
#endif
                    return DMPAPER_9X11;
                }
#endif

                break;
            case 'a':
#ifdef DMPAPER_A2
                if (len == 2 && strnEQ("a2", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A2);
#endif
                    return DMPAPER_A2;
                }
#endif

#ifdef DMPAPER_A3
                if (len == 2 && strnEQ("a3", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A3);
#endif
                    return DMPAPER_A3;
                }
#endif

#ifdef DMPAPER_A3_EXTRA
                if (len == 8 && strnEQ("a3_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A3_EXTRA);
#endif
                    return DMPAPER_A3_EXTRA;
                }
#endif

#ifdef DMPAPER_A3_EXTRA_TRAVERSE
                if (len == 17 && strnEQ("a3_extra_traverse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A3_EXTRA_TRAVERSE);
#endif
                    return DMPAPER_A3_EXTRA_TRAVERSE;
                }
#endif

#ifdef DMPAPER_A3_ROTATED
                if (len == 10 && strnEQ("a3_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A3_ROTATED);
#endif
                    return DMPAPER_A3_ROTATED;
                }
#endif

#ifdef DMPAPER_A3_TRAVERSE
                if (len == 11 && strnEQ("a3_traverse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A3_TRAVERSE);
#endif
                    return DMPAPER_A3_TRAVERSE;
                }
#endif

#ifdef DMPAPER_A4
                if (len == 2 && strnEQ("a4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A4);
#endif
                    return DMPAPER_A4;
                }
#endif

#ifdef DMPAPER_A4_EXTRA
                if (len == 8 && strnEQ("a4_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A4_EXTRA);
#endif
                    return DMPAPER_A4_EXTRA;
                }
#endif

#ifdef DMPAPER_A4_PLUS
                if (len == 7 && strnEQ("a4_plus", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A4_PLUS);
#endif
                    return DMPAPER_A4_PLUS;
                }
#endif

#ifdef DMPAPER_A4_ROTATED
                if (len == 10 && strnEQ("a4_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A4_ROTATED);
#endif
                    return DMPAPER_A4_ROTATED;
                }
#endif

#ifdef DMPAPER_A4SMALL
                if (len == 7 && strnEQ("a4small", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A4SMALL);
#endif
                    return DMPAPER_A4SMALL;
                }
#endif

#ifdef DMPAPER_A4_TRANSVERSE
                if (len == 13 && strnEQ("a4_transverse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A4_TRANSVERSE);
#endif
                    return DMPAPER_A4_TRANSVERSE;
                }
#endif

#ifdef DMPAPER_A5
                if (len == 2 && strnEQ("a5", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A5);
#endif
                    return DMPAPER_A5;
                }
#endif

#ifdef DMPAPER_A5_EXTRA
                if (len == 8 && strnEQ("a5_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A5_EXTRA);
#endif
                    return DMPAPER_A5_EXTRA;
                }
#endif

#ifdef DMPAPER_A5_ROTATED
                if (len == 10 && strnEQ("a5_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A5_ROTATED);
#endif
                    return DMPAPER_A5_ROTATED;
                }
#endif

#ifdef DMPAPER_A5_TRANSVERSE
                if (len == 13 && strnEQ("a5_transverse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A5_TRANSVERSE);
#endif
                    return DMPAPER_A5_TRANSVERSE;
                }
#endif

#ifdef DMPAPER_A6
                if (len == 2 && strnEQ("a6", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A6);
#endif
                    return DMPAPER_A6;
                }
#endif

#ifdef DMPAPER_A6_ROTATED
                if (len == 10 && strnEQ("a6_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A6_ROTATED);
#endif
                    return DMPAPER_A6_ROTATED;
                }
#endif

#ifdef DMPAPER_A_PLUS
                if (len == 6 && strnEQ("a_plus", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_A_PLUS);
#endif
                    return DMPAPER_A_PLUS;
                }
#endif

                break;
            case 'b':
#ifdef DMPAPER_B4
                if (len == 2 && strnEQ("b4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B4);
#endif
                    return DMPAPER_B4;
                }
#endif

#ifdef DMPAPER_B4_JIS_ROTATED
                if (len == 14 && strnEQ("b4_jis_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B4_JIS_ROTATED);
#endif
                    return DMPAPER_B4_JIS_ROTATED;
                }
#endif

#ifdef DMPAPER_B5
                if (len == 2 && strnEQ("b5", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B5);
#endif
                    return DMPAPER_B5;
                }
#endif

#ifdef DMPAPER_B5_EXTRA
                if (len == 8 && strnEQ("b5_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B5_EXTRA);
#endif
                    return DMPAPER_B5_EXTRA;
                }
#endif

#ifdef DMPAPER_B5_JIS_ROTATED
                if (len == 14 && strnEQ("b5_jis_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B5_JIS_ROTATED);
#endif
                    return DMPAPER_B5_JIS_ROTATED;
                }
#endif

#ifdef DMPAPER_B6_JIS
                if (len == 6 && strnEQ("b6_jis", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B6_JIS);
#endif
                    return DMPAPER_B6_JIS;
                }
#endif

#ifdef DMPAPER_B6_JIS_ROTATED
                if (len == 14 && strnEQ("b6_jis_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B6_JIS_ROTATED);
#endif
                    return DMPAPER_B6_JIS_ROTATED;
                }
#endif

#ifdef DMPAPER_B_PLUS
                if (len == 6 && strnEQ("b_plus", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_B_PLUS);
#endif
                    return DMPAPER_B_PLUS;
                }
#endif

                break;
            case 'c':
#ifdef DMPAPER_CSHEET
                if (len == 6 && strnEQ("csheet", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_CSHEET);
#endif
                    return DMPAPER_CSHEET;
                }
#endif

                break;
            case 'd':
#ifdef DMPAPER_DBL_JAPANESE_POSTCARD
                if (len == 21 && strnEQ("dbl_japanese_postcard", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_DBL_JAPANESE_POSTCARD);
#endif
                    return DMPAPER_DBL_JAPANESE_POSTCARD;
                }
#endif

#ifdef DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED
                if (len == 29 && strnEQ("dbl_japanese_postcard_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED);
#endif
                    return DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED;
                }
#endif

#ifdef DMPAPER_DSHEET
                if (len == 6 && strnEQ("dsheet", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_DSHEET);
#endif
                    return DMPAPER_DSHEET;
                }
#endif

                break;
            case 'e':
#ifdef DMPAPER_ENV_9
                if (len == 5 && strnEQ("env_9", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_9);
#endif
                    return DMPAPER_ENV_9;
                }
#endif

#ifdef DMPAPER_ENV_10
                if (len == 6 && strnEQ("env_10", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_10);
#endif
                    return DMPAPER_ENV_10;
                }
#endif

#ifdef DMPAPER_ENV_11
                if (len == 6 && strnEQ("env_11", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_11);
#endif
                    return DMPAPER_ENV_11;
                }
#endif

#ifdef DMPAPER_ENV_12
                if (len == 6 && strnEQ("env_12", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_12);
#endif
                    return DMPAPER_ENV_12;
                }
#endif

#ifdef DMPAPER_ENV_14
                if (len == 6 && strnEQ("env_14", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_14);
#endif
                    return DMPAPER_ENV_14;
                }
#endif

#ifdef DMPAPER_ENV_C5
                if (len == 6 && strnEQ("env_c5", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_C5);
#endif
                    return DMPAPER_ENV_C5;
                }
#endif

#ifdef DMPAPER_ENV_C3
                if (len == 6 && strnEQ("env_c3", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_C3);
#endif
                    return DMPAPER_ENV_C3;
                }
#endif

#ifdef DMPAPER_ENV_C4
                if (len == 6 && strnEQ("env_c4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_C4);
#endif
                    return DMPAPER_ENV_C4;
                }
#endif

#ifdef DMPAPER_ENV_C6
                if (len == 6 && strnEQ("env_c6", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_C6);
#endif
                    return DMPAPER_ENV_C6;
                }
#endif

#ifdef DMPAPER_ENV_C65
                if (len == 7 && strnEQ("env_c65", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_C65);
#endif
                    return DMPAPER_ENV_C65;
                }
#endif

#ifdef DMPAPER_ENV_B4
                if (len == 6 && strnEQ("env_b4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_B4);
#endif
                    return DMPAPER_ENV_B4;
                }
#endif

#ifdef DMPAPER_ENV_B5
                if (len == 6 && strnEQ("env_b5", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_B5);
#endif
                    return DMPAPER_ENV_B5;
                }
#endif

#ifdef DMPAPER_ENV_B6
                if (len == 6 && strnEQ("env_b6", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_B6);
#endif
                    return DMPAPER_ENV_B6;
                }
#endif

#ifdef DMPAPER_ENV_DL
                if (len == 6 && strnEQ("env_dl", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_DL);
#endif
                    return DMPAPER_ENV_DL;
                }
#endif

#ifdef DMPAPER_ENV_INVITE
                if (len == 10 && strnEQ("env_invite", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_INVITE);
#endif
                    return DMPAPER_ENV_INVITE;
                }
#endif

#ifdef DMPAPER_ENV_ITALY
                if (len == 9 && strnEQ("env_italy", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_ITALY);
#endif
                    return DMPAPER_ENV_ITALY;
                }
#endif

#ifdef DMPAPER_ENV_MONARCH
                if (len == 11 && strnEQ("env_monarch", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_MONARCH);
#endif
                    return DMPAPER_ENV_MONARCH;
                }
#endif

#ifdef DMPAPER_ENV_PERSONAL
                if (len == 12 && strnEQ("env_personal", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ENV_PERSONAL);
#endif
                    return DMPAPER_ENV_PERSONAL;
                }
#endif

#ifdef DMPAPER_ESHEET
                if (len == 6 && strnEQ("esheet", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ESHEET);
#endif
                    return DMPAPER_ESHEET;
                }
#endif

#ifdef DMPAPER_EXECUTIVE
                if (len == 9 && strnEQ("executive", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_EXECUTIVE);
#endif
                    return DMPAPER_EXECUTIVE;
                }
#endif

                break;
            case 'f':
#ifdef DMPAPER_FANFOLD_US
                if (len == 10 && strnEQ("fanfold_us", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_FANFOLD_US);
#endif
                    return DMPAPER_FANFOLD_US;
                }
#endif

#ifdef DMPAPER_FANFOLD_STD_GERMAN
                if (len == 18 && strnEQ("fanfold_std_german", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_FANFOLD_STD_GERMAN);
#endif
                    return DMPAPER_FANFOLD_STD_GERMAN;
                }
#endif

#ifdef DMPAPER_FANFOLD_LGL_GERMAN
                if (len == 18 && strnEQ("fanfold_lgl_german", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_FANFOLD_LGL_GERMAN);
#endif
                    return DMPAPER_FANFOLD_LGL_GERMAN;
                }
#endif

#ifdef DMPAPER_FOLIO
                if (len == 5 && strnEQ("folio", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_FOLIO);
#endif
                    return DMPAPER_FOLIO;
                }
#endif

                break;
            case 'i':
#ifdef DMPAPER_ISO_B4
                if (len == 6 && strnEQ("iso_b4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_ISO_B4);
#endif
                    return DMPAPER_ISO_B4;
                }
#endif

                break;
            case 'j':
#ifdef DMPAPER_JAPANESE_POSTCARD
                if (len == 17 && strnEQ("japanese_postcard", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JAPANESE_POSTCARD);
#endif
                    return DMPAPER_JAPANESE_POSTCARD;
                }
#endif

#ifdef DMPAPER_JAPANESE_POSTCARD_ROTATED
                if (len == 25 && strnEQ("japanese_postcard_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JAPANESE_POSTCARD_ROTATED);
#endif
                    return DMPAPER_JAPANESE_POSTCARD_ROTATED;
                }
#endif

#ifdef DMPAPER_JENV_CHOU3
                if (len == 10 && strnEQ("jenv_chou3", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_CHOU3);
#endif
                    return DMPAPER_JENV_CHOU3;
                }
#endif

#ifdef DMPAPER_JENV_CHOU3_ROTATED
                if (len == 18 && strnEQ("jenv_chou3_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_CHOU3_ROTATED);
#endif
                    return DMPAPER_JENV_CHOU3_ROTATED;
                }
#endif

#ifdef DMPAPER_JENV_CHOU4
                if (len == 10 && strnEQ("jenv_chou4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_CHOU4);
#endif
                    return DMPAPER_JENV_CHOU4;
                }
#endif

#ifdef DMPAPER_JENV_CHOU4_ROTATED
                if (len == 18 && strnEQ("jenv_chou4_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_CHOU4_ROTATED);
#endif
                    return DMPAPER_JENV_CHOU4_ROTATED;
                }
#endif

#ifdef DMPAPER_JENV_KAKU2
                if (len == 10 && strnEQ("jenv_kaku2", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_KAKU2);
#endif
                    return DMPAPER_JENV_KAKU2;
                }
#endif

#ifdef DMPAPER_JENV_KAKU2_ROTATED
                if (len == 18 && strnEQ("jenv_kaku2_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_KAKU2_ROTATED);
#endif
                    return DMPAPER_JENV_KAKU2_ROTATED;
                }
#endif

#ifdef DMPAPER_JENV_KAKU3
                if (len == 10 && strnEQ("jenv_kaku3", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_KAKU3);
#endif
                    return DMPAPER_JENV_KAKU3;
                }
#endif

#ifdef DMPAPER_JENV_KAKU3_ROTATED
                if (len == 18 && strnEQ("jenv_kaku3_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_KAKU3_ROTATED);
#endif
                    return DMPAPER_JENV_KAKU3_ROTATED;
                }
#endif

#ifdef DMPAPER_JENV_YOU4
                if (len == 9 && strnEQ("jenv_you4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_YOU4);
#endif
                    return DMPAPER_JENV_YOU4;
                }
#endif

#ifdef DMPAPER_JENV_YOU4_ROTATED
                if (len == 17 && strnEQ("jenv_you4_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_JENV_YOU4_ROTATED);
#endif
                    return DMPAPER_JENV_YOU4_ROTATED;
                }
#endif

                break;
            case 'l':
#ifdef DMPAPER_LETTER
                if (len == 6 && strnEQ("letter", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LETTER);
#endif
                    return DMPAPER_LETTER;
                }
#endif

#ifdef DMPAPER_LEGAL
                if (len == 5 && strnEQ("legal", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LEGAL);
#endif
                    return DMPAPER_LEGAL;
                }
#endif

#ifdef DMPAPER_LAST
                if (len == 4 && strnEQ("last", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LAST);
#endif
                    return DMPAPER_LAST;
                }
#endif

#ifdef DMPAPER_LEDGER
                if (len == 6 && strnEQ("ledger", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LEDGER);
#endif
                    return DMPAPER_LEDGER;
                }
#endif

#ifdef DMPAPER_LEGAL_EXTRA
                if (len == 11 && strnEQ("legal_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LEGAL_EXTRA);
#endif
                    return DMPAPER_LEGAL_EXTRA;
                }
#endif

#ifdef DMPAPER_LETTER_EXTRA
                if (len == 12 && strnEQ("letter_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LETTER_EXTRA);
#endif
                    return DMPAPER_LETTER_EXTRA;
                }
#endif

#ifdef DMPAPER_LETTER_EXTRA_TRANSVERSE
                if (len == 23 && strnEQ("letter_extra_transverse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LETTER_EXTRA_TRANSVERSE);
#endif
                    return DMPAPER_LETTER_EXTRA_TRANSVERSE;
                }
#endif

#ifdef DMPAPER_LETTER_ROTATED
                if (len == 14 && strnEQ("letter_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LETTER_ROTATED);
#endif
                    return DMPAPER_LETTER_ROTATED;
                }
#endif

#ifdef DMPAPER_LETTERSMALL
                if (len == 11 && strnEQ("lettersmall", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LETTERSMALL);
#endif
                    return DMPAPER_LETTERSMALL;
                }
#endif

#ifdef DMPAPER_LETTER_TRANSVERSE
                if (len == 17 && strnEQ("letter_transverse", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_LETTER_TRANSVERSE);
#endif
                    return DMPAPER_LETTER_TRANSVERSE;
                }
#endif

                break;
            case 'n':
#ifdef DMPAPER_NOTE
                if (len == 4 && strnEQ("note", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_NOTE);
#endif
                    return DMPAPER_NOTE;
                }
#endif

                break;
            case 'p':
#ifdef DMPAPER_P16K
                if (len == 4 && strnEQ("p16k", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_P16K);
#endif
                    return DMPAPER_P16K;
                }
#endif

#ifdef DMPAPER_P16K_ROTATED
                if (len == 12 && strnEQ("p16k_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_P16K_ROTATED);
#endif
                    return DMPAPER_P16K_ROTATED;
                }
#endif

#ifdef DMPAPER_P32K
                if (len == 4 && strnEQ("p32k", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_P32K);
#endif
                    return DMPAPER_P32K;
                }
#endif

#ifdef DMPAPER_P32K_ROTATED
                if (len == 12 && strnEQ("p32k_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_P32K_ROTATED);
#endif
                    return DMPAPER_P32K_ROTATED;
                }
#endif

#ifdef DMPAPER_P32KBIG
                if (len == 7 && strnEQ("p32kbig", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_P32KBIG);
#endif
                    return DMPAPER_P32KBIG;
                }
#endif

#ifdef DMPAPER_P32KBIG_ROTATED
                if (len == 15 && strnEQ("p32kbig_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_P32KBIG_ROTATED);
#endif
                    return DMPAPER_P32KBIG_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_1
                if (len == 6 && strnEQ("penv_1", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_1);
#endif
                    return DMPAPER_PENV_1;
                }
#endif

#ifdef DMPAPER_PENV_1_ROTATED
                if (len == 14 && strnEQ("penv_1_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_1_ROTATED);
#endif
                    return DMPAPER_PENV_1_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_2
                if (len == 6 && strnEQ("penv_2", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_2);
#endif
                    return DMPAPER_PENV_2;
                }
#endif

#ifdef DMPAPER_PENV_2_ROTATED
                if (len == 14 && strnEQ("penv_2_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_2_ROTATED);
#endif
                    return DMPAPER_PENV_2_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_3
                if (len == 6 && strnEQ("penv_3", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_3);
#endif
                    return DMPAPER_PENV_3;
                }
#endif

#ifdef DMPAPER_PENV_3_ROTATED
                if (len == 14 && strnEQ("penv_3_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_3_ROTATED);
#endif
                    return DMPAPER_PENV_3_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_4
                if (len == 6 && strnEQ("penv_4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_4);
#endif
                    return DMPAPER_PENV_4;
                }
#endif

#ifdef DMPAPER_PENV_4_ROTATED
                if (len == 14 && strnEQ("penv_4_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_4_ROTATED);
#endif
                    return DMPAPER_PENV_4_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_5
                if (len == 6 && strnEQ("penv_5", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_5);
#endif
                    return DMPAPER_PENV_5;
                }
#endif

#ifdef DMPAPER_PENV_5_ROTATED
                if (len == 14 && strnEQ("penv_5_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_5_ROTATED);
#endif
                    return DMPAPER_PENV_5_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_6
                if (len == 6 && strnEQ("penv_6", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_6);
#endif
                    return DMPAPER_PENV_6;
                }
#endif

#ifdef DMPAPER_PENV_6_ROTATED
                if (len == 14 && strnEQ("penv_6_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_6_ROTATED);
#endif
                    return DMPAPER_PENV_6_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_7
                if (len == 6 && strnEQ("penv_7", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_7);
#endif
                    return DMPAPER_PENV_7;
                }
#endif

#ifdef DMPAPER_PENV_7_ROTATED
                if (len == 14 && strnEQ("penv_7_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_7_ROTATED);
#endif
                    return DMPAPER_PENV_7_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_8
                if (len == 6 && strnEQ("penv_8", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_8);
#endif
                    return DMPAPER_PENV_8;
                }
#endif

#ifdef DMPAPER_PENV_8_ROTATED
                if (len == 14 && strnEQ("penv_8_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_8_ROTATED);
#endif
                    return DMPAPER_PENV_8_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_9
                if (len == 6 && strnEQ("penv_9", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_9);
#endif
                    return DMPAPER_PENV_9;
                }
#endif

#ifdef DMPAPER_PENV_9_ROTATED
                if (len == 14 && strnEQ("penv_9_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_9_ROTATED);
#endif
                    return DMPAPER_PENV_9_ROTATED;
                }
#endif

#ifdef DMPAPER_PENV_10
                if (len == 7 && strnEQ("penv_10", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_10);
#endif
                    return DMPAPER_PENV_10;
                }
#endif

#ifdef DMPAPER_PENV_10_ROTATED
                if (len == 15 && strnEQ("penv_10_rotated", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_PENV_10_ROTATED);
#endif
                    return DMPAPER_PENV_10_ROTATED;
                }
#endif

                break;
            case 'q':
#ifdef DMPAPER_QUARTO
                if (len == 6 && strnEQ("quarto", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_QUARTO);
#endif
                    return DMPAPER_QUARTO;
                }
#endif

                break;
            case 's':
#ifdef DMPAPER_STATEMENT
                if (len == 9 && strnEQ("statement", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_STATEMENT);
#endif
                    return DMPAPER_STATEMENT;
                }
#endif

                break;
            case 't':
#ifdef DMPAPER_TABLOID
                if (len == 7 && strnEQ("tabloid", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_TABLOID);
#endif
                    return DMPAPER_TABLOID;
                }
#endif

#ifdef DMPAPER_TABLOID_EXTRA
                if (len == 13 && strnEQ("tabloid_extra", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmpaper", pv, DMPAPER_TABLOID_EXTRA);
#endif
                    return DMPAPER_TABLOID_EXTRA;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmres_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMRES_HIGH
    case DMRES_HIGH:
        return newSVdual(aTHX_ DMRES_HIGH, "high");
#endif
#ifdef DMRES_MEDIUM
    case DMRES_MEDIUM:
        return newSVdual(aTHX_ DMRES_MEDIUM, "medium");
#endif
#ifdef DMRES_LOW
    case DMRES_LOW:
        return newSVdual(aTHX_ DMRES_LOW, "low");
#endif
#ifdef DMRES_DRAFT
    case DMRES_DRAFT:
        return newSVdual(aTHX_ DMRES_DRAFT, "draft");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmres(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'd':
#ifdef DMRES_DRAFT
                if (len == 5 && strnEQ("draft", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmres", pv, DMRES_DRAFT);
#endif
                    return DMRES_DRAFT;
                }
#endif

                break;
            case 'h':
#ifdef DMRES_HIGH
                if (len == 4 && strnEQ("high", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmres", pv, DMRES_HIGH);
#endif
                    return DMRES_HIGH;
                }
#endif

                break;
            case 'l':
#ifdef DMRES_LOW
                if (len == 3 && strnEQ("low", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmres", pv, DMRES_LOW);
#endif
                    return DMRES_LOW;
                }
#endif

                break;
            case 'm':
#ifdef DMRES_MEDIUM
                if (len == 6 && strnEQ("medium", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmres", pv, DMRES_MEDIUM);
#endif
                    return DMRES_MEDIUM;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
dmtt_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef DMTT_BITMAP
    case DMTT_BITMAP:
        return newSVdual(aTHX_ DMTT_BITMAP, "bitmap");
#endif
#ifdef DMTT_DOWNLOAD
    case DMTT_DOWNLOAD:
        return newSVdual(aTHX_ DMTT_DOWNLOAD, "download");
#endif
#ifdef DMTT_DOWNLOAD_OUTLINE
    case DMTT_DOWNLOAD_OUTLINE:
        return newSVdual(aTHX_ DMTT_DOWNLOAD_OUTLINE, "download_outline");
#endif
#ifdef DMTT_SUBDEV
    case DMTT_SUBDEV:
        return newSVdual(aTHX_ DMTT_SUBDEV, "subdev");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_dmtt(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'b':
#ifdef DMTT_BITMAP
                if (len == 6 && strnEQ("bitmap", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmtt", pv, DMTT_BITMAP);
#endif
                    return DMTT_BITMAP;
                }
#endif

                break;
            case 'd':
#ifdef DMTT_DOWNLOAD
                if (len == 8 && strnEQ("download", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmtt", pv, DMTT_DOWNLOAD);
#endif
                    return DMTT_DOWNLOAD;
                }
#endif

#ifdef DMTT_DOWNLOAD_OUTLINE
                if (len == 16 && strnEQ("download_outline", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmtt", pv, DMTT_DOWNLOAD_OUTLINE);
#endif
                    return DMTT_DOWNLOAD_OUTLINE;
                }
#endif

                break;
            case 's':
#ifdef DMTT_SUBDEV
                if (len == 6 && strnEQ("subdev", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "dmtt", pv, DMTT_SUBDEV);
#endif
                    return DMTT_SUBDEV;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
enum_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef PRINTER_ENUM_LOCAL
    case PRINTER_ENUM_LOCAL:
        return newSVdual(aTHX_ PRINTER_ENUM_LOCAL, "local");
#endif
#ifdef PRINTER_ENUM_NAME
    case PRINTER_ENUM_NAME:
        return newSVdual(aTHX_ PRINTER_ENUM_NAME, "name");
#endif
#ifdef PRINTER_ENUM_SHARED
    case PRINTER_ENUM_SHARED:
        return newSVdual(aTHX_ PRINTER_ENUM_SHARED, "shared");
#endif
#ifdef PRINTER_ENUM_CONNECTIONS
    case PRINTER_ENUM_CONNECTIONS:
        return newSVdual(aTHX_ PRINTER_ENUM_CONNECTIONS, "connections");
#endif
#ifdef PRINTER_ENUM_NETWORK
    case PRINTER_ENUM_NETWORK:
        return newSVdual(aTHX_ PRINTER_ENUM_NETWORK, "network");
#endif
#ifdef PRINTER_ENUM_REMOTE
    case PRINTER_ENUM_REMOTE:
        return newSVdual(aTHX_ PRINTER_ENUM_REMOTE, "remote");
#endif
#ifdef PRINTER_ENUM_CATEGORY_3D
    case PRINTER_ENUM_CATEGORY_3D:
        return newSVdual(aTHX_ PRINTER_ENUM_CATEGORY_3D, "category_3d");
#endif
#ifdef PRINTER_ENUM_CATEGORY_ALL
    case PRINTER_ENUM_CATEGORY_ALL:
        return newSVdual(aTHX_ PRINTER_ENUM_CATEGORY_ALL, "category_all");
#endif
#ifdef PRINTER_ENUM_EXPAND
    case PRINTER_ENUM_EXPAND:
        return newSVdual(aTHX_ PRINTER_ENUM_EXPAND, "expand");
#endif
#ifdef PRINTER_ENUM_CONTAINER
    case PRINTER_ENUM_CONTAINER:
        return newSVdual(aTHX_ PRINTER_ENUM_CONTAINER, "container");
#endif
#ifdef PRINTER_ENUM_ICON1
    case PRINTER_ENUM_ICON1:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON1, "icon1");
#endif
#ifdef PRINTER_ENUM_ICON2
    case PRINTER_ENUM_ICON2:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON2, "icon2");
#endif
#ifdef PRINTER_ENUM_ICON3
    case PRINTER_ENUM_ICON3:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON3, "icon3");
#endif
#ifdef PRINTER_ENUM_ICON4
    case PRINTER_ENUM_ICON4:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON4, "icon4");
#endif
#ifdef PRINTER_ENUM_ICON5
    case PRINTER_ENUM_ICON5:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON5, "icon5");
#endif
#ifdef PRINTER_ENUM_ICON6
    case PRINTER_ENUM_ICON6:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON6, "icon6");
#endif
#ifdef PRINTER_ENUM_ICON7
    case PRINTER_ENUM_ICON7:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON7, "icon7");
#endif
#ifdef PRINTER_ENUM_ICON8
    case PRINTER_ENUM_ICON8:
        return newSVdual(aTHX_ PRINTER_ENUM_ICON8, "icon8");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_enum(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'c':
#ifdef PRINTER_ENUM_CONNECTIONS
                if (len == 11 && strnEQ("connections", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_CONNECTIONS);
#endif
                    return PRINTER_ENUM_CONNECTIONS;
                }
#endif

#ifdef PRINTER_ENUM_CATEGORY_3D
                if (len == 11 && strnEQ("category_3d", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_CATEGORY_3D);
#endif
                    return PRINTER_ENUM_CATEGORY_3D;
                }
#endif

#ifdef PRINTER_ENUM_CATEGORY_ALL
                if (len == 12 && strnEQ("category_all", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_CATEGORY_ALL);
#endif
                    return PRINTER_ENUM_CATEGORY_ALL;
                }
#endif

#ifdef PRINTER_ENUM_CONTAINER
                if (len == 9 && strnEQ("container", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_CONTAINER);
#endif
                    return PRINTER_ENUM_CONTAINER;
                }
#endif

                break;
            case 'e':
#ifdef PRINTER_ENUM_EXPAND
                if (len == 6 && strnEQ("expand", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_EXPAND);
#endif
                    return PRINTER_ENUM_EXPAND;
                }
#endif

                break;
            case 'i':
#ifdef PRINTER_ENUM_ICON1
                if (len == 5 && strnEQ("icon1", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON1);
#endif
                    return PRINTER_ENUM_ICON1;
                }
#endif

#ifdef PRINTER_ENUM_ICON2
                if (len == 5 && strnEQ("icon2", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON2);
#endif
                    return PRINTER_ENUM_ICON2;
                }
#endif

#ifdef PRINTER_ENUM_ICON3
                if (len == 5 && strnEQ("icon3", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON3);
#endif
                    return PRINTER_ENUM_ICON3;
                }
#endif

#ifdef PRINTER_ENUM_ICON4
                if (len == 5 && strnEQ("icon4", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON4);
#endif
                    return PRINTER_ENUM_ICON4;
                }
#endif

#ifdef PRINTER_ENUM_ICON5
                if (len == 5 && strnEQ("icon5", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON5);
#endif
                    return PRINTER_ENUM_ICON5;
                }
#endif

#ifdef PRINTER_ENUM_ICON6
                if (len == 5 && strnEQ("icon6", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON6);
#endif
                    return PRINTER_ENUM_ICON6;
                }
#endif

#ifdef PRINTER_ENUM_ICON7
                if (len == 5 && strnEQ("icon7", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON7);
#endif
                    return PRINTER_ENUM_ICON7;
                }
#endif

#ifdef PRINTER_ENUM_ICON8
                if (len == 5 && strnEQ("icon8", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_ICON8);
#endif
                    return PRINTER_ENUM_ICON8;
                }
#endif

                break;
            case 'l':
#ifdef PRINTER_ENUM_LOCAL
                if (len == 5 && strnEQ("local", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_LOCAL);
#endif
                    return PRINTER_ENUM_LOCAL;
                }
#endif

                break;
            case 'n':
#ifdef PRINTER_ENUM_NAME
                if (len == 4 && strnEQ("name", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_NAME);
#endif
                    return PRINTER_ENUM_NAME;
                }
#endif

#ifdef PRINTER_ENUM_NETWORK
                if (len == 7 && strnEQ("network", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_NETWORK);
#endif
                    return PRINTER_ENUM_NETWORK;
                }
#endif

                break;
            case 'r':
#ifdef PRINTER_ENUM_REMOTE
                if (len == 6 && strnEQ("remote", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_REMOTE);
#endif
                    return PRINTER_ENUM_REMOTE;
                }
#endif

                break;
            case 's':
#ifdef PRINTER_ENUM_SHARED
                if (len == 6 && strnEQ("shared", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "enum", pv, PRINTER_ENUM_SHARED);
#endif
                    return PRINTER_ENUM_SHARED;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
formflag_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef FORM_USER
    case FORM_USER:
        return newSVdual(aTHX_ FORM_USER, "user");
#endif
#ifdef FORM_BUILTIN
    case FORM_BUILTIN:
        return newSVdual(aTHX_ FORM_BUILTIN, "builtin");
#endif
#ifdef FORM_PRINTER
    case FORM_PRINTER:
        return newSVdual(aTHX_ FORM_PRINTER, "printer");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_formflag(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'b':
#ifdef FORM_BUILTIN
                if (len == 7 && strnEQ("builtin", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "formflag", pv, FORM_BUILTIN);
#endif
                    return FORM_BUILTIN;
                }
#endif

                break;
            case 'p':
#ifdef FORM_PRINTER
                if (len == 7 && strnEQ("printer", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "formflag", pv, FORM_PRINTER);
#endif
                    return FORM_PRINTER;
                }
#endif

                break;
            case 'u':
#ifdef FORM_USER
                if (len == 4 && strnEQ("user", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "formflag", pv, FORM_USER);
#endif
                    return FORM_USER;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
status_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef PRINTER_STATUS_BUSY
    case PRINTER_STATUS_BUSY:
        return newSVdual(aTHX_ PRINTER_STATUS_BUSY, "busy");
#endif
#ifdef PRINTER_STATUS_DOOR_OPEN
    case PRINTER_STATUS_DOOR_OPEN:
        return newSVdual(aTHX_ PRINTER_STATUS_DOOR_OPEN, "door_open");
#endif
#ifdef PRINTER_STATUS_ERROR
    case PRINTER_STATUS_ERROR:
        return newSVdual(aTHX_ PRINTER_STATUS_ERROR, "error");
#endif
#ifdef PRINTER_STATUS_INITIALIZING
    case PRINTER_STATUS_INITIALIZING:
        return newSVdual(aTHX_ PRINTER_STATUS_INITIALIZING, "initializing");
#endif
#ifdef PRINTER_STATUS_IO_ACTIVE
    case PRINTER_STATUS_IO_ACTIVE:
        return newSVdual(aTHX_ PRINTER_STATUS_IO_ACTIVE, "io_active");
#endif
#ifdef PRINTER_STATUS_MANUAL_FEED
    case PRINTER_STATUS_MANUAL_FEED:
        return newSVdual(aTHX_ PRINTER_STATUS_MANUAL_FEED, "manual_feed");
#endif
#ifdef PRINTER_STATUS_NO_TONER
    case PRINTER_STATUS_NO_TONER:
        return newSVdual(aTHX_ PRINTER_STATUS_NO_TONER, "no_toner");
#endif
#ifdef PRINTER_STATUS_NOT_AVAILABLE
    case PRINTER_STATUS_NOT_AVAILABLE:
        return newSVdual(aTHX_ PRINTER_STATUS_NOT_AVAILABLE, "not_available");
#endif
#ifdef PRINTER_STATUS_OFFLINE
    case PRINTER_STATUS_OFFLINE:
        return newSVdual(aTHX_ PRINTER_STATUS_OFFLINE, "offline");
#endif
#ifdef PRINTER_STATUS_OUT_OF_MEMORY
    case PRINTER_STATUS_OUT_OF_MEMORY:
        return newSVdual(aTHX_ PRINTER_STATUS_OUT_OF_MEMORY, "out_of_memory");
#endif
#ifdef PRINTER_STATUS_OUTPUT_BIN_FULL
    case PRINTER_STATUS_OUTPUT_BIN_FULL:
        return newSVdual(aTHX_ PRINTER_STATUS_OUTPUT_BIN_FULL, "output_bin_full");
#endif
#ifdef PRINTER_STATUS_PAGE_PUNT
    case PRINTER_STATUS_PAGE_PUNT:
        return newSVdual(aTHX_ PRINTER_STATUS_PAGE_PUNT, "page_punt");
#endif
#ifdef PRINTER_STATUS_PAPER_JAM
    case PRINTER_STATUS_PAPER_JAM:
        return newSVdual(aTHX_ PRINTER_STATUS_PAPER_JAM, "paper_jam");
#endif
#ifdef PRINTER_STATUS_PAPER_OUT
    case PRINTER_STATUS_PAPER_OUT:
        return newSVdual(aTHX_ PRINTER_STATUS_PAPER_OUT, "paper_out");
#endif
#ifdef PRINTER_STATUS_PAPER_PROBLEM
    case PRINTER_STATUS_PAPER_PROBLEM:
        return newSVdual(aTHX_ PRINTER_STATUS_PAPER_PROBLEM, "paper_problem");
#endif
#ifdef PRINTER_STATUS_PAUSED
    case PRINTER_STATUS_PAUSED:
        return newSVdual(aTHX_ PRINTER_STATUS_PAUSED, "paused");
#endif
#ifdef PRINTER_STATUS_PENDING_DELETION
    case PRINTER_STATUS_PENDING_DELETION:
        return newSVdual(aTHX_ PRINTER_STATUS_PENDING_DELETION, "pending_deletion");
#endif
#ifdef PRINTER_STATUS_POWER_SAVE
    case PRINTER_STATUS_POWER_SAVE:
        return newSVdual(aTHX_ PRINTER_STATUS_POWER_SAVE, "power_save");
#endif
#ifdef PRINTER_STATUS_PRINTING
    case PRINTER_STATUS_PRINTING:
        return newSVdual(aTHX_ PRINTER_STATUS_PRINTING, "printing");
#endif
#ifdef PRINTER_STATUS_PROCESSING
    case PRINTER_STATUS_PROCESSING:
        return newSVdual(aTHX_ PRINTER_STATUS_PROCESSING, "processing");
#endif
#ifdef PRINTER_STATUS_SERVER_UNKNOWN
    case PRINTER_STATUS_SERVER_UNKNOWN:
        return newSVdual(aTHX_ PRINTER_STATUS_SERVER_UNKNOWN, "server_unknown");
#endif
#ifdef PRINTER_STATUS_TONER_LOW
    case PRINTER_STATUS_TONER_LOW:
        return newSVdual(aTHX_ PRINTER_STATUS_TONER_LOW, "toner_low");
#endif
#ifdef PRINTER_STATUS_USER_INTERVENTION
    case PRINTER_STATUS_USER_INTERVENTION:
        return newSVdual(aTHX_ PRINTER_STATUS_USER_INTERVENTION, "user_intervention");
#endif
#ifdef PRINTER_STATUS_WAITING
    case PRINTER_STATUS_WAITING:
        return newSVdual(aTHX_ PRINTER_STATUS_WAITING, "waiting");
#endif
#ifdef PRINTER_STATUS_WARMING_UP
    case PRINTER_STATUS_WARMING_UP:
        return newSVdual(aTHX_ PRINTER_STATUS_WARMING_UP, "warming_up");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_status(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'b':
#ifdef PRINTER_STATUS_BUSY
                if (len == 4 && strnEQ("busy", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_BUSY);
#endif
                    return PRINTER_STATUS_BUSY;
                }
#endif

                break;
            case 'd':
#ifdef PRINTER_STATUS_DOOR_OPEN
                if (len == 9 && strnEQ("door_open", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_DOOR_OPEN);
#endif
                    return PRINTER_STATUS_DOOR_OPEN;
                }
#endif

                break;
            case 'e':
#ifdef PRINTER_STATUS_ERROR
                if (len == 5 && strnEQ("error", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_ERROR);
#endif
                    return PRINTER_STATUS_ERROR;
                }
#endif

                break;
            case 'i':
#ifdef PRINTER_STATUS_INITIALIZING
                if (len == 12 && strnEQ("initializing", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_INITIALIZING);
#endif
                    return PRINTER_STATUS_INITIALIZING;
                }
#endif

#ifdef PRINTER_STATUS_IO_ACTIVE
                if (len == 9 && strnEQ("io_active", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_IO_ACTIVE);
#endif
                    return PRINTER_STATUS_IO_ACTIVE;
                }
#endif

                break;
            case 'm':
#ifdef PRINTER_STATUS_MANUAL_FEED
                if (len == 11 && strnEQ("manual_feed", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_MANUAL_FEED);
#endif
                    return PRINTER_STATUS_MANUAL_FEED;
                }
#endif

                break;
            case 'n':
#ifdef PRINTER_STATUS_NO_TONER
                if (len == 8 && strnEQ("no_toner", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_NO_TONER);
#endif
                    return PRINTER_STATUS_NO_TONER;
                }
#endif

#ifdef PRINTER_STATUS_NOT_AVAILABLE
                if (len == 13 && strnEQ("not_available", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_NOT_AVAILABLE);
#endif
                    return PRINTER_STATUS_NOT_AVAILABLE;
                }
#endif

                break;
            case 'o':
#ifdef PRINTER_STATUS_OFFLINE
                if (len == 7 && strnEQ("offline", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_OFFLINE);
#endif
                    return PRINTER_STATUS_OFFLINE;
                }
#endif

#ifdef PRINTER_STATUS_OUT_OF_MEMORY
                if (len == 13 && strnEQ("out_of_memory", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_OUT_OF_MEMORY);
#endif
                    return PRINTER_STATUS_OUT_OF_MEMORY;
                }
#endif

#ifdef PRINTER_STATUS_OUTPUT_BIN_FULL
                if (len == 15 && strnEQ("output_bin_full", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_OUTPUT_BIN_FULL);
#endif
                    return PRINTER_STATUS_OUTPUT_BIN_FULL;
                }
#endif

                break;
            case 'p':
#ifdef PRINTER_STATUS_PAGE_PUNT
                if (len == 9 && strnEQ("page_punt", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PAGE_PUNT);
#endif
                    return PRINTER_STATUS_PAGE_PUNT;
                }
#endif

#ifdef PRINTER_STATUS_PAPER_JAM
                if (len == 9 && strnEQ("paper_jam", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PAPER_JAM);
#endif
                    return PRINTER_STATUS_PAPER_JAM;
                }
#endif

#ifdef PRINTER_STATUS_PAPER_OUT
                if (len == 9 && strnEQ("paper_out", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PAPER_OUT);
#endif
                    return PRINTER_STATUS_PAPER_OUT;
                }
#endif

#ifdef PRINTER_STATUS_PAPER_PROBLEM
                if (len == 13 && strnEQ("paper_problem", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PAPER_PROBLEM);
#endif
                    return PRINTER_STATUS_PAPER_PROBLEM;
                }
#endif

#ifdef PRINTER_STATUS_PAUSED
                if (len == 6 && strnEQ("paused", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PAUSED);
#endif
                    return PRINTER_STATUS_PAUSED;
                }
#endif

#ifdef PRINTER_STATUS_PENDING_DELETION
                if (len == 16 && strnEQ("pending_deletion", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PENDING_DELETION);
#endif
                    return PRINTER_STATUS_PENDING_DELETION;
                }
#endif

#ifdef PRINTER_STATUS_POWER_SAVE
                if (len == 10 && strnEQ("power_save", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_POWER_SAVE);
#endif
                    return PRINTER_STATUS_POWER_SAVE;
                }
#endif

#ifdef PRINTER_STATUS_PRINTING
                if (len == 8 && strnEQ("printing", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PRINTING);
#endif
                    return PRINTER_STATUS_PRINTING;
                }
#endif

#ifdef PRINTER_STATUS_PROCESSING
                if (len == 10 && strnEQ("processing", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_PROCESSING);
#endif
                    return PRINTER_STATUS_PROCESSING;
                }
#endif

                break;
            case 's':
#ifdef PRINTER_STATUS_SERVER_UNKNOWN
                if (len == 14 && strnEQ("server_unknown", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_SERVER_UNKNOWN);
#endif
                    return PRINTER_STATUS_SERVER_UNKNOWN;
                }
#endif

                break;
            case 't':
#ifdef PRINTER_STATUS_TONER_LOW
                if (len == 9 && strnEQ("toner_low", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_TONER_LOW);
#endif
                    return PRINTER_STATUS_TONER_LOW;
                }
#endif

                break;
            case 'u':
#ifdef PRINTER_STATUS_USER_INTERVENTION
                if (len == 17 && strnEQ("user_intervention", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_USER_INTERVENTION);
#endif
                    return PRINTER_STATUS_USER_INTERVENTION;
                }
#endif

                break;
            case 'w':
#ifdef PRINTER_STATUS_WAITING
                if (len == 7 && strnEQ("waiting", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_WAITING);
#endif
                    return PRINTER_STATUS_WAITING;
                }
#endif

#ifdef PRINTER_STATUS_WARMING_UP
                if (len == 10 && strnEQ("warming_up", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "status", pv, PRINTER_STATUS_WARMING_UP);
#endif
                    return PRINTER_STATUS_WARMING_UP;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static SV*
stringtype_to_sv(pTHX_ IV val) {
    switch(val) {
#ifdef STRING_NONE
    case STRING_NONE:
        return newSVdual(aTHX_ STRING_NONE, "none");
#endif
#ifdef STRING_MUIDLL
    case STRING_MUIDLL:
        return newSVdual(aTHX_ STRING_MUIDLL, "muidll");
#endif
#ifdef STRING_LANGPAIR
    case STRING_LANGPAIR:
        return newSVdual(aTHX_ STRING_LANGPAIR, "langpair");
#endif
    default:
        return newSViv(val);
    }
}

static IV
sv_to_stringtype(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
            case 'l':
#ifdef STRING_LANGPAIR
                if (len == 8 && strnEQ("langpair", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "stringtype", pv, STRING_LANGPAIR);
#endif
                    return STRING_LANGPAIR;
                }
#endif

                break;
            case 'm':
#ifdef STRING_MUIDLL
                if (len == 6 && strnEQ("muidll", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "stringtype", pv, STRING_MUIDLL);
#endif
                    return STRING_MUIDLL;
                }
#endif

                break;
            case 'n':
#ifdef STRING_NONE
                if (len == 4 && strnEQ("none", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "stringtype", pv, STRING_NONE);
#endif
                    return STRING_NONE;
                }
#endif

                break;
            }
        }
    }
    return SvIV(sv);
}

static void
boot_constants(pTHX) {
    HV *stash = gv_stashpvs("Win32::EnumPrinters", 1);
#ifdef PRINTER_ATTRIBUTE_DIRECT
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_DIRECT", newSVdual(aTHX_ PRINTER_ATTRIBUTE_DIRECT, "direct"));
#endif
#ifdef PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST", newSVdual(aTHX_ PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST, "do_complete_first"));
#endif
#ifdef PRINTER_ATTRIBUTE_ENABLE_DEVQ
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_ENABLE_DEVQ", newSVdual(aTHX_ PRINTER_ATTRIBUTE_ENABLE_DEVQ, "enable_devq"));
#endif
#ifdef PRINTER_ATTRIBUTE_HIDDEN
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_HIDDEN", newSVdual(aTHX_ PRINTER_ATTRIBUTE_HIDDEN, "hidden"));
#endif
#ifdef PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS", newSVdual(aTHX_ PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS, "keepprintedjobs"));
#endif
#ifdef PRINTER_ATTRIBUTE_LOCAL
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_LOCAL", newSVdual(aTHX_ PRINTER_ATTRIBUTE_LOCAL, "local"));
#endif
#ifdef PRINTER_ATTRIBUTE_NETWORK
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_NETWORK", newSVdual(aTHX_ PRINTER_ATTRIBUTE_NETWORK, "network"));
#endif
#ifdef PRINTER_ATTRIBUTE_PUBLISHED
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_PUBLISHED", newSVdual(aTHX_ PRINTER_ATTRIBUTE_PUBLISHED, "published"));
#endif
#ifdef PRINTER_ATTRIBUTE_QUEUED
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_QUEUED", newSVdual(aTHX_ PRINTER_ATTRIBUTE_QUEUED, "queued"));
#endif
#ifdef PRINTER_ATTRIBUTE_RAW_ONLY
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_RAW_ONLY", newSVdual(aTHX_ PRINTER_ATTRIBUTE_RAW_ONLY, "raw_only"));
#endif
#ifdef PRINTER_ATTRIBUTE_SHARED
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_SHARED", newSVdual(aTHX_ PRINTER_ATTRIBUTE_SHARED, "shared"));
#endif
#ifdef PRINTER_ATTRIBUTE_FAX
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_FAX", newSVdual(aTHX_ PRINTER_ATTRIBUTE_FAX, "fax"));
#endif
#ifdef PRINTER_ATTRIBUTE_FRIENDLY_NAME
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_FRIENDLY_NAME", newSVdual(aTHX_ PRINTER_ATTRIBUTE_FRIENDLY_NAME, "friendly_name"));
#endif
#ifdef PRINTER_ATTRIBUTE_MACHINE
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_MACHINE", newSVdual(aTHX_ PRINTER_ATTRIBUTE_MACHINE, "machine"));
#endif
#ifdef PRINTER_ATTRIBUTE_PUSHED_USER
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_PUSHED_USER", newSVdual(aTHX_ PRINTER_ATTRIBUTE_PUSHED_USER, "pushed_user"));
#endif
#ifdef PRINTER_ATTRIBUTE_PUSHED_MACHINE
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_PUSHED_MACHINE", newSVdual(aTHX_ PRINTER_ATTRIBUTE_PUSHED_MACHINE, "pushed_machine"));
#endif
#ifdef PRINTER_ATTRIBUTE_TS
    newCONSTSUB(stash, "PRINTER_ATTRIBUTE_TS", newSVdual(aTHX_ PRINTER_ATTRIBUTE_TS, "ts"));
#endif
#ifdef DMBIN_AUTO
    newCONSTSUB(stash, "DMBIN_AUTO", newSVdual(aTHX_ DMBIN_AUTO, "auto"));
#endif
#ifdef DMBIN_CASSETTE
    newCONSTSUB(stash, "DMBIN_CASSETTE", newSVdual(aTHX_ DMBIN_CASSETTE, "cassette"));
#endif
#ifdef DMBIN_ENVELOPE
    newCONSTSUB(stash, "DMBIN_ENVELOPE", newSVdual(aTHX_ DMBIN_ENVELOPE, "envelope"));
#endif
#ifdef DMBIN_ENVMANUAL
    newCONSTSUB(stash, "DMBIN_ENVMANUAL", newSVdual(aTHX_ DMBIN_ENVMANUAL, "envmanual"));
#endif
#ifdef DMBIN_FIRST
    newCONSTSUB(stash, "DMBIN_FIRST", newSVdual(aTHX_ DMBIN_FIRST, "first"));
#endif
#ifdef DMBIN_LARGECAPACITY
    newCONSTSUB(stash, "DMBIN_LARGECAPACITY", newSVdual(aTHX_ DMBIN_LARGECAPACITY, "largecapacity"));
#endif
#ifdef DMBIN_LARGEFMT
    newCONSTSUB(stash, "DMBIN_LARGEFMT", newSVdual(aTHX_ DMBIN_LARGEFMT, "largefmt"));
#endif
#ifdef DMBIN_LAST
    newCONSTSUB(stash, "DMBIN_LAST", newSVdual(aTHX_ DMBIN_LAST, "last"));
#endif
#ifdef DMBIN_LOWER
    newCONSTSUB(stash, "DMBIN_LOWER", newSVdual(aTHX_ DMBIN_LOWER, "lower"));
#endif
#ifdef DMBIN_MANUAL
    newCONSTSUB(stash, "DMBIN_MANUAL", newSVdual(aTHX_ DMBIN_MANUAL, "manual"));
#endif
#ifdef DMBIN_MIDDLE
    newCONSTSUB(stash, "DMBIN_MIDDLE", newSVdual(aTHX_ DMBIN_MIDDLE, "middle"));
#endif
#ifdef DMBIN_TRACTOR
    newCONSTSUB(stash, "DMBIN_TRACTOR", newSVdual(aTHX_ DMBIN_TRACTOR, "tractor"));
#endif
#ifdef DMBIN_SMALLFMT
    newCONSTSUB(stash, "DMBIN_SMALLFMT", newSVdual(aTHX_ DMBIN_SMALLFMT, "smallfmt"));
#endif
#ifdef DMCOLLATE_TRUE
    newCONSTSUB(stash, "DMCOLLATE_TRUE", newSVdual(aTHX_ DMCOLLATE_TRUE, "true"));
#endif
#ifdef DMCOLLATE_FALSE
    newCONSTSUB(stash, "DMCOLLATE_FALSE", newSVdual(aTHX_ DMCOLLATE_FALSE, "false"));
#endif
#ifdef DMCOLOR_COLOR
    newCONSTSUB(stash, "DMCOLOR_COLOR", newSVdual(aTHX_ DMCOLOR_COLOR, "color"));
#endif
#ifdef DMCOLOR_MONOCHROME
    newCONSTSUB(stash, "DMCOLOR_MONOCHROME", newSVdual(aTHX_ DMCOLOR_MONOCHROME, "monochrome"));
#endif
#ifdef DMDFO_DEFAULT
    newCONSTSUB(stash, "DMDFO_DEFAULT", newSVdual(aTHX_ DMDFO_DEFAULT, "default"));
#endif
#ifdef DMDFO_CENTER
    newCONSTSUB(stash, "DMDFO_CENTER", newSVdual(aTHX_ DMDFO_CENTER, "center"));
#endif
#ifdef DMDFO_STRETCH
    newCONSTSUB(stash, "DMDFO_STRETCH", newSVdual(aTHX_ DMDFO_STRETCH, "stretch"));
#endif
#ifdef DM_GRAYSCALE
    newCONSTSUB(stash, "DM_GRAYSCALE", newSVdual(aTHX_ DM_GRAYSCALE, "grayscale"));
#endif
#ifdef DM_INTERLACED
    newCONSTSUB(stash, "DM_INTERLACED", newSVdual(aTHX_ DM_INTERLACED, "interlaced"));
#endif
#ifdef DMDITHER_NONE
    newCONSTSUB(stash, "DMDITHER_NONE", newSVdual(aTHX_ DMDITHER_NONE, "none"));
#endif
#ifdef DMDITHER_COARSE
    newCONSTSUB(stash, "DMDITHER_COARSE", newSVdual(aTHX_ DMDITHER_COARSE, "coarse"));
#endif
#ifdef DMDITHER_FINE
    newCONSTSUB(stash, "DMDITHER_FINE", newSVdual(aTHX_ DMDITHER_FINE, "fine"));
#endif
#ifdef DMDITHER_LINEART
    newCONSTSUB(stash, "DMDITHER_LINEART", newSVdual(aTHX_ DMDITHER_LINEART, "lineart"));
#endif
#ifdef DMDITHER_GRAYSCALE
    newCONSTSUB(stash, "DMDITHER_GRAYSCALE", newSVdual(aTHX_ DMDITHER_GRAYSCALE, "grayscale"));
#endif
#ifdef DMDO_DEFAULT
    newCONSTSUB(stash, "DMDO_DEFAULT", newSVdual(aTHX_ DMDO_DEFAULT, "default"));
#endif
#ifdef DMDO_90
    newCONSTSUB(stash, "DMDO_90", newSVdual(aTHX_ DMDO_90, "90"));
#endif
#ifdef DMDO_180
    newCONSTSUB(stash, "DMDO_180", newSVdual(aTHX_ DMDO_180, "180"));
#endif
#ifdef DMDO_270
    newCONSTSUB(stash, "DMDO_270", newSVdual(aTHX_ DMDO_270, "270"));
#endif
#ifdef DMDUP_SIMPLEX
    newCONSTSUB(stash, "DMDUP_SIMPLEX", newSVdual(aTHX_ DMDUP_SIMPLEX, "simplex"));
#endif
#ifdef DMDUP_HORIZONTAL
    newCONSTSUB(stash, "DMDUP_HORIZONTAL", newSVdual(aTHX_ DMDUP_HORIZONTAL, "horizontal"));
#endif
#ifdef DMDUP_VERTICAL
    newCONSTSUB(stash, "DMDUP_VERTICAL", newSVdual(aTHX_ DMDUP_VERTICAL, "vertical"));
#endif
#ifdef DM_ORIENTATION
    newCONSTSUB(stash, "DM_ORIENTATION", newSVdual(aTHX_ DM_ORIENTATION, "orientation"));
#endif
#ifdef DM_PAPERSIZE
    newCONSTSUB(stash, "DM_PAPERSIZE", newSVdual(aTHX_ DM_PAPERSIZE, "papersize"));
#endif
#ifdef DM_PAPERLENGTH
    newCONSTSUB(stash, "DM_PAPERLENGTH", newSVdual(aTHX_ DM_PAPERLENGTH, "paperlength"));
#endif
#ifdef DM_PAPERWIDTH
    newCONSTSUB(stash, "DM_PAPERWIDTH", newSVdual(aTHX_ DM_PAPERWIDTH, "paperwidth"));
#endif
#ifdef DM_SCALE
    newCONSTSUB(stash, "DM_SCALE", newSVdual(aTHX_ DM_SCALE, "scale"));
#endif
#ifdef DM_COPIES
    newCONSTSUB(stash, "DM_COPIES", newSVdual(aTHX_ DM_COPIES, "copies"));
#endif
#ifdef DM_DEFAULTSOURCE
    newCONSTSUB(stash, "DM_DEFAULTSOURCE", newSVdual(aTHX_ DM_DEFAULTSOURCE, "defaultsource"));
#endif
#ifdef DM_PRINTQUALITY
    newCONSTSUB(stash, "DM_PRINTQUALITY", newSVdual(aTHX_ DM_PRINTQUALITY, "printquality"));
#endif
#ifdef DM_POSITION
    newCONSTSUB(stash, "DM_POSITION", newSVdual(aTHX_ DM_POSITION, "position"));
#endif
#ifdef DM_DISPLAYORIENTATION
    newCONSTSUB(stash, "DM_DISPLAYORIENTATION", newSVdual(aTHX_ DM_DISPLAYORIENTATION, "displayorientation"));
#endif
#ifdef DM_DISPLAYFIXEDOUTPUT
    newCONSTSUB(stash, "DM_DISPLAYFIXEDOUTPUT", newSVdual(aTHX_ DM_DISPLAYFIXEDOUTPUT, "displayfixedoutput"));
#endif
#ifdef DM_COLOR
    newCONSTSUB(stash, "DM_COLOR", newSVdual(aTHX_ DM_COLOR, "color"));
#endif
#ifdef DM_DUPLEX
    newCONSTSUB(stash, "DM_DUPLEX", newSVdual(aTHX_ DM_DUPLEX, "duplex"));
#endif
#ifdef DM_YRESOLUTION
    newCONSTSUB(stash, "DM_YRESOLUTION", newSVdual(aTHX_ DM_YRESOLUTION, "yresolution"));
#endif
#ifdef DM_TTOPTION
    newCONSTSUB(stash, "DM_TTOPTION", newSVdual(aTHX_ DM_TTOPTION, "ttoption"));
#endif
#ifdef DM_COLLATE
    newCONSTSUB(stash, "DM_COLLATE", newSVdual(aTHX_ DM_COLLATE, "collate"));
#endif
#ifdef DM_FORMNAME
    newCONSTSUB(stash, "DM_FORMNAME", newSVdual(aTHX_ DM_FORMNAME, "formname"));
#endif
#ifdef DM_LOGPIXELS
    newCONSTSUB(stash, "DM_LOGPIXELS", newSVdual(aTHX_ DM_LOGPIXELS, "logpixels"));
#endif
#ifdef DM_BITSPERPEL
    newCONSTSUB(stash, "DM_BITSPERPEL", newSVdual(aTHX_ DM_BITSPERPEL, "bitsperpel"));
#endif
#ifdef DM_PELSWIDTH
    newCONSTSUB(stash, "DM_PELSWIDTH", newSVdual(aTHX_ DM_PELSWIDTH, "pelswidth"));
#endif
#ifdef DM_PELSHEIGHT
    newCONSTSUB(stash, "DM_PELSHEIGHT", newSVdual(aTHX_ DM_PELSHEIGHT, "pelsheight"));
#endif
#ifdef DM_DISPLAYFLAGS
    newCONSTSUB(stash, "DM_DISPLAYFLAGS", newSVdual(aTHX_ DM_DISPLAYFLAGS, "displayflags"));
#endif
#ifdef DM_NUP
    newCONSTSUB(stash, "DM_NUP", newSVdual(aTHX_ DM_NUP, "nup"));
#endif
#ifdef DM_DISPLAYFREQUENCY
    newCONSTSUB(stash, "DM_DISPLAYFREQUENCY", newSVdual(aTHX_ DM_DISPLAYFREQUENCY, "displayfrequency"));
#endif
#ifdef DM_ICMMETHOD
    newCONSTSUB(stash, "DM_ICMMETHOD", newSVdual(aTHX_ DM_ICMMETHOD, "icmmethod"));
#endif
#ifdef DM_ICMINTENT
    newCONSTSUB(stash, "DM_ICMINTENT", newSVdual(aTHX_ DM_ICMINTENT, "icmintent"));
#endif
#ifdef DM_MEDIATYPE
    newCONSTSUB(stash, "DM_MEDIATYPE", newSVdual(aTHX_ DM_MEDIATYPE, "mediatype"));
#endif
#ifdef DM_DITHERTYPE
    newCONSTSUB(stash, "DM_DITHERTYPE", newSVdual(aTHX_ DM_DITHERTYPE, "dithertype"));
#endif
#ifdef DM_PANNINGWIDTH
    newCONSTSUB(stash, "DM_PANNINGWIDTH", newSVdual(aTHX_ DM_PANNINGWIDTH, "panningwidth"));
#endif
#ifdef DM_PANNINGHEIGHT
    newCONSTSUB(stash, "DM_PANNINGHEIGHT", newSVdual(aTHX_ DM_PANNINGHEIGHT, "panningheight"));
#endif
#ifdef DMICM_ABS_COLORIMETRIC
    newCONSTSUB(stash, "DMICM_ABS_COLORIMETRIC", newSVdual(aTHX_ DMICM_ABS_COLORIMETRIC, "abs_colorimetric"));
#endif
#ifdef DMICM_COLORIMETRIC
    newCONSTSUB(stash, "DMICM_COLORIMETRIC", newSVdual(aTHX_ DMICM_COLORIMETRIC, "colorimetric"));
#endif
#ifdef DMICM_CONTRAST
    newCONSTSUB(stash, "DMICM_CONTRAST", newSVdual(aTHX_ DMICM_CONTRAST, "contrast"));
#endif
#ifdef DMICM_SATURATE
    newCONSTSUB(stash, "DMICM_SATURATE", newSVdual(aTHX_ DMICM_SATURATE, "saturate"));
#endif
#ifdef DMICMMETHOD_NONE
    newCONSTSUB(stash, "DMICMMETHOD_NONE", newSVdual(aTHX_ DMICMMETHOD_NONE, "none"));
#endif
#ifdef DMICMMETHOD_SYSTEM
    newCONSTSUB(stash, "DMICMMETHOD_SYSTEM", newSVdual(aTHX_ DMICMMETHOD_SYSTEM, "system"));
#endif
#ifdef DMICMMETHOD_DRIVER
    newCONSTSUB(stash, "DMICMMETHOD_DRIVER", newSVdual(aTHX_ DMICMMETHOD_DRIVER, "driver"));
#endif
#ifdef DMICMMETHOD_DEVICE
    newCONSTSUB(stash, "DMICMMETHOD_DEVICE", newSVdual(aTHX_ DMICMMETHOD_DEVICE, "device"));
#endif
#ifdef DMMEDIA_STANDARD
    newCONSTSUB(stash, "DMMEDIA_STANDARD", newSVdual(aTHX_ DMMEDIA_STANDARD, "standard"));
#endif
#ifdef DMMEDIA_GLOSSY
    newCONSTSUB(stash, "DMMEDIA_GLOSSY", newSVdual(aTHX_ DMMEDIA_GLOSSY, "glossy"));
#endif
#ifdef DMMEDIA_TRANSPARENCY
    newCONSTSUB(stash, "DMMEDIA_TRANSPARENCY", newSVdual(aTHX_ DMMEDIA_TRANSPARENCY, "transparency"));
#endif
#ifdef DMNUP_SYSTEM
    newCONSTSUB(stash, "DMNUP_SYSTEM", newSVdual(aTHX_ DMNUP_SYSTEM, "system"));
#endif
#ifdef DMNUP_ONEUP
    newCONSTSUB(stash, "DMNUP_ONEUP", newSVdual(aTHX_ DMNUP_ONEUP, "oneup"));
#endif
#ifdef DMPAPER_LETTER
    newCONSTSUB(stash, "DMPAPER_LETTER", newSVdual(aTHX_ DMPAPER_LETTER, "letter"));
#endif
#ifdef DMPAPER_LEGAL
    newCONSTSUB(stash, "DMPAPER_LEGAL", newSVdual(aTHX_ DMPAPER_LEGAL, "legal"));
#endif
#ifdef DMPAPER_9X11
    newCONSTSUB(stash, "DMPAPER_9X11", newSVdual(aTHX_ DMPAPER_9X11, "9x11"));
#endif
#ifdef DMPAPER_10X11
    newCONSTSUB(stash, "DMPAPER_10X11", newSVdual(aTHX_ DMPAPER_10X11, "10x11"));
#endif
#ifdef DMPAPER_10X14
    newCONSTSUB(stash, "DMPAPER_10X14", newSVdual(aTHX_ DMPAPER_10X14, "10x14"));
#endif
#ifdef DMPAPER_15X11
    newCONSTSUB(stash, "DMPAPER_15X11", newSVdual(aTHX_ DMPAPER_15X11, "15x11"));
#endif
#ifdef DMPAPER_11X17
    newCONSTSUB(stash, "DMPAPER_11X17", newSVdual(aTHX_ DMPAPER_11X17, "11x17"));
#endif
#ifdef DMPAPER_12X11
    newCONSTSUB(stash, "DMPAPER_12X11", newSVdual(aTHX_ DMPAPER_12X11, "12x11"));
#endif
#ifdef DMPAPER_A2
    newCONSTSUB(stash, "DMPAPER_A2", newSVdual(aTHX_ DMPAPER_A2, "a2"));
#endif
#ifdef DMPAPER_A3
    newCONSTSUB(stash, "DMPAPER_A3", newSVdual(aTHX_ DMPAPER_A3, "a3"));
#endif
#ifdef DMPAPER_A3_EXTRA
    newCONSTSUB(stash, "DMPAPER_A3_EXTRA", newSVdual(aTHX_ DMPAPER_A3_EXTRA, "a3_extra"));
#endif
#ifdef DMPAPER_A3_EXTRA_TRAVERSE
    newCONSTSUB(stash, "DMPAPER_A3_EXTRA_TRAVERSE", newSVdual(aTHX_ DMPAPER_A3_EXTRA_TRAVERSE, "a3_extra_traverse"));
#endif
#ifdef DMPAPER_A3_ROTATED
    newCONSTSUB(stash, "DMPAPER_A3_ROTATED", newSVdual(aTHX_ DMPAPER_A3_ROTATED, "a3_rotated"));
#endif
#ifdef DMPAPER_A3_TRAVERSE
    newCONSTSUB(stash, "DMPAPER_A3_TRAVERSE", newSVdual(aTHX_ DMPAPER_A3_TRAVERSE, "a3_traverse"));
#endif
#ifdef DMPAPER_A4
    newCONSTSUB(stash, "DMPAPER_A4", newSVdual(aTHX_ DMPAPER_A4, "a4"));
#endif
#ifdef DMPAPER_A4_EXTRA
    newCONSTSUB(stash, "DMPAPER_A4_EXTRA", newSVdual(aTHX_ DMPAPER_A4_EXTRA, "a4_extra"));
#endif
#ifdef DMPAPER_A4_PLUS
    newCONSTSUB(stash, "DMPAPER_A4_PLUS", newSVdual(aTHX_ DMPAPER_A4_PLUS, "a4_plus"));
#endif
#ifdef DMPAPER_A4_ROTATED
    newCONSTSUB(stash, "DMPAPER_A4_ROTATED", newSVdual(aTHX_ DMPAPER_A4_ROTATED, "a4_rotated"));
#endif
#ifdef DMPAPER_A4SMALL
    newCONSTSUB(stash, "DMPAPER_A4SMALL", newSVdual(aTHX_ DMPAPER_A4SMALL, "a4small"));
#endif
#ifdef DMPAPER_A4_TRANSVERSE
    newCONSTSUB(stash, "DMPAPER_A4_TRANSVERSE", newSVdual(aTHX_ DMPAPER_A4_TRANSVERSE, "a4_transverse"));
#endif
#ifdef DMPAPER_A5
    newCONSTSUB(stash, "DMPAPER_A5", newSVdual(aTHX_ DMPAPER_A5, "a5"));
#endif
#ifdef DMPAPER_A5_EXTRA
    newCONSTSUB(stash, "DMPAPER_A5_EXTRA", newSVdual(aTHX_ DMPAPER_A5_EXTRA, "a5_extra"));
#endif
#ifdef DMPAPER_A5_ROTATED
    newCONSTSUB(stash, "DMPAPER_A5_ROTATED", newSVdual(aTHX_ DMPAPER_A5_ROTATED, "a5_rotated"));
#endif
#ifdef DMPAPER_A5_TRANSVERSE
    newCONSTSUB(stash, "DMPAPER_A5_TRANSVERSE", newSVdual(aTHX_ DMPAPER_A5_TRANSVERSE, "a5_transverse"));
#endif
#ifdef DMPAPER_A6
    newCONSTSUB(stash, "DMPAPER_A6", newSVdual(aTHX_ DMPAPER_A6, "a6"));
#endif
#ifdef DMPAPER_A6_ROTATED
    newCONSTSUB(stash, "DMPAPER_A6_ROTATED", newSVdual(aTHX_ DMPAPER_A6_ROTATED, "a6_rotated"));
#endif
#ifdef DMPAPER_A_PLUS
    newCONSTSUB(stash, "DMPAPER_A_PLUS", newSVdual(aTHX_ DMPAPER_A_PLUS, "a_plus"));
#endif
#ifdef DMPAPER_B4
    newCONSTSUB(stash, "DMPAPER_B4", newSVdual(aTHX_ DMPAPER_B4, "b4"));
#endif
#ifdef DMPAPER_B4_JIS_ROTATED
    newCONSTSUB(stash, "DMPAPER_B4_JIS_ROTATED", newSVdual(aTHX_ DMPAPER_B4_JIS_ROTATED, "b4_jis_rotated"));
#endif
#ifdef DMPAPER_B5
    newCONSTSUB(stash, "DMPAPER_B5", newSVdual(aTHX_ DMPAPER_B5, "b5"));
#endif
#ifdef DMPAPER_B5_EXTRA
    newCONSTSUB(stash, "DMPAPER_B5_EXTRA", newSVdual(aTHX_ DMPAPER_B5_EXTRA, "b5_extra"));
#endif
#ifdef DMPAPER_B5_JIS_ROTATED
    newCONSTSUB(stash, "DMPAPER_B5_JIS_ROTATED", newSVdual(aTHX_ DMPAPER_B5_JIS_ROTATED, "b5_jis_rotated"));
#endif
#ifdef DMPAPER_B6_JIS
    newCONSTSUB(stash, "DMPAPER_B6_JIS", newSVdual(aTHX_ DMPAPER_B6_JIS, "b6_jis"));
#endif
#ifdef DMPAPER_B6_JIS_ROTATED
    newCONSTSUB(stash, "DMPAPER_B6_JIS_ROTATED", newSVdual(aTHX_ DMPAPER_B6_JIS_ROTATED, "b6_jis_rotated"));
#endif
#ifdef DMPAPER_B_PLUS
    newCONSTSUB(stash, "DMPAPER_B_PLUS", newSVdual(aTHX_ DMPAPER_B_PLUS, "b_plus"));
#endif
#ifdef DMPAPER_CSHEET
    newCONSTSUB(stash, "DMPAPER_CSHEET", newSVdual(aTHX_ DMPAPER_CSHEET, "csheet"));
#endif
#ifdef DMPAPER_DBL_JAPANESE_POSTCARD
    newCONSTSUB(stash, "DMPAPER_DBL_JAPANESE_POSTCARD", newSVdual(aTHX_ DMPAPER_DBL_JAPANESE_POSTCARD, "dbl_japanese_postcard"));
#endif
#ifdef DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED
    newCONSTSUB(stash, "DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED", newSVdual(aTHX_ DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED, "dbl_japanese_postcard_rotated"));
#endif
#ifdef DMPAPER_DSHEET
    newCONSTSUB(stash, "DMPAPER_DSHEET", newSVdual(aTHX_ DMPAPER_DSHEET, "dsheet"));
#endif
#ifdef DMPAPER_ENV_9
    newCONSTSUB(stash, "DMPAPER_ENV_9", newSVdual(aTHX_ DMPAPER_ENV_9, "env_9"));
#endif
#ifdef DMPAPER_ENV_10
    newCONSTSUB(stash, "DMPAPER_ENV_10", newSVdual(aTHX_ DMPAPER_ENV_10, "env_10"));
#endif
#ifdef DMPAPER_ENV_11
    newCONSTSUB(stash, "DMPAPER_ENV_11", newSVdual(aTHX_ DMPAPER_ENV_11, "env_11"));
#endif
#ifdef DMPAPER_ENV_12
    newCONSTSUB(stash, "DMPAPER_ENV_12", newSVdual(aTHX_ DMPAPER_ENV_12, "env_12"));
#endif
#ifdef DMPAPER_ENV_14
    newCONSTSUB(stash, "DMPAPER_ENV_14", newSVdual(aTHX_ DMPAPER_ENV_14, "env_14"));
#endif
#ifdef DMPAPER_ENV_C5
    newCONSTSUB(stash, "DMPAPER_ENV_C5", newSVdual(aTHX_ DMPAPER_ENV_C5, "env_c5"));
#endif
#ifdef DMPAPER_ENV_C3
    newCONSTSUB(stash, "DMPAPER_ENV_C3", newSVdual(aTHX_ DMPAPER_ENV_C3, "env_c3"));
#endif
#ifdef DMPAPER_ENV_C4
    newCONSTSUB(stash, "DMPAPER_ENV_C4", newSVdual(aTHX_ DMPAPER_ENV_C4, "env_c4"));
#endif
#ifdef DMPAPER_ENV_C6
    newCONSTSUB(stash, "DMPAPER_ENV_C6", newSVdual(aTHX_ DMPAPER_ENV_C6, "env_c6"));
#endif
#ifdef DMPAPER_ENV_C65
    newCONSTSUB(stash, "DMPAPER_ENV_C65", newSVdual(aTHX_ DMPAPER_ENV_C65, "env_c65"));
#endif
#ifdef DMPAPER_ENV_B4
    newCONSTSUB(stash, "DMPAPER_ENV_B4", newSVdual(aTHX_ DMPAPER_ENV_B4, "env_b4"));
#endif
#ifdef DMPAPER_ENV_B5
    newCONSTSUB(stash, "DMPAPER_ENV_B5", newSVdual(aTHX_ DMPAPER_ENV_B5, "env_b5"));
#endif
#ifdef DMPAPER_ENV_B6
    newCONSTSUB(stash, "DMPAPER_ENV_B6", newSVdual(aTHX_ DMPAPER_ENV_B6, "env_b6"));
#endif
#ifdef DMPAPER_ENV_DL
    newCONSTSUB(stash, "DMPAPER_ENV_DL", newSVdual(aTHX_ DMPAPER_ENV_DL, "env_dl"));
#endif
#ifdef DMPAPER_ENV_INVITE
    newCONSTSUB(stash, "DMPAPER_ENV_INVITE", newSVdual(aTHX_ DMPAPER_ENV_INVITE, "env_invite"));
#endif
#ifdef DMPAPER_ENV_ITALY
    newCONSTSUB(stash, "DMPAPER_ENV_ITALY", newSVdual(aTHX_ DMPAPER_ENV_ITALY, "env_italy"));
#endif
#ifdef DMPAPER_ENV_MONARCH
    newCONSTSUB(stash, "DMPAPER_ENV_MONARCH", newSVdual(aTHX_ DMPAPER_ENV_MONARCH, "env_monarch"));
#endif
#ifdef DMPAPER_ENV_PERSONAL
    newCONSTSUB(stash, "DMPAPER_ENV_PERSONAL", newSVdual(aTHX_ DMPAPER_ENV_PERSONAL, "env_personal"));
#endif
#ifdef DMPAPER_ESHEET
    newCONSTSUB(stash, "DMPAPER_ESHEET", newSVdual(aTHX_ DMPAPER_ESHEET, "esheet"));
#endif
#ifdef DMPAPER_EXECUTIVE
    newCONSTSUB(stash, "DMPAPER_EXECUTIVE", newSVdual(aTHX_ DMPAPER_EXECUTIVE, "executive"));
#endif
#ifdef DMPAPER_FANFOLD_US
    newCONSTSUB(stash, "DMPAPER_FANFOLD_US", newSVdual(aTHX_ DMPAPER_FANFOLD_US, "fanfold_us"));
#endif
#ifdef DMPAPER_FANFOLD_STD_GERMAN
    newCONSTSUB(stash, "DMPAPER_FANFOLD_STD_GERMAN", newSVdual(aTHX_ DMPAPER_FANFOLD_STD_GERMAN, "fanfold_std_german"));
#endif
#ifdef DMPAPER_FANFOLD_LGL_GERMAN
    newCONSTSUB(stash, "DMPAPER_FANFOLD_LGL_GERMAN", newSVdual(aTHX_ DMPAPER_FANFOLD_LGL_GERMAN, "fanfold_lgl_german"));
#endif
#ifdef DMPAPER_FOLIO
    newCONSTSUB(stash, "DMPAPER_FOLIO", newSVdual(aTHX_ DMPAPER_FOLIO, "folio"));
#endif
#ifdef DMPAPER_ISO_B4
    newCONSTSUB(stash, "DMPAPER_ISO_B4", newSVdual(aTHX_ DMPAPER_ISO_B4, "iso_b4"));
#endif
#ifdef DMPAPER_JAPANESE_POSTCARD
    newCONSTSUB(stash, "DMPAPER_JAPANESE_POSTCARD", newSVdual(aTHX_ DMPAPER_JAPANESE_POSTCARD, "japanese_postcard"));
#endif
#ifdef DMPAPER_JAPANESE_POSTCARD_ROTATED
    newCONSTSUB(stash, "DMPAPER_JAPANESE_POSTCARD_ROTATED", newSVdual(aTHX_ DMPAPER_JAPANESE_POSTCARD_ROTATED, "japanese_postcard_rotated"));
#endif
#ifdef DMPAPER_JENV_CHOU3
    newCONSTSUB(stash, "DMPAPER_JENV_CHOU3", newSVdual(aTHX_ DMPAPER_JENV_CHOU3, "jenv_chou3"));
#endif
#ifdef DMPAPER_JENV_CHOU3_ROTATED
    newCONSTSUB(stash, "DMPAPER_JENV_CHOU3_ROTATED", newSVdual(aTHX_ DMPAPER_JENV_CHOU3_ROTATED, "jenv_chou3_rotated"));
#endif
#ifdef DMPAPER_JENV_CHOU4
    newCONSTSUB(stash, "DMPAPER_JENV_CHOU4", newSVdual(aTHX_ DMPAPER_JENV_CHOU4, "jenv_chou4"));
#endif
#ifdef DMPAPER_JENV_CHOU4_ROTATED
    newCONSTSUB(stash, "DMPAPER_JENV_CHOU4_ROTATED", newSVdual(aTHX_ DMPAPER_JENV_CHOU4_ROTATED, "jenv_chou4_rotated"));
#endif
#ifdef DMPAPER_JENV_KAKU2
    newCONSTSUB(stash, "DMPAPER_JENV_KAKU2", newSVdual(aTHX_ DMPAPER_JENV_KAKU2, "jenv_kaku2"));
#endif
#ifdef DMPAPER_JENV_KAKU2_ROTATED
    newCONSTSUB(stash, "DMPAPER_JENV_KAKU2_ROTATED", newSVdual(aTHX_ DMPAPER_JENV_KAKU2_ROTATED, "jenv_kaku2_rotated"));
#endif
#ifdef DMPAPER_JENV_KAKU3
    newCONSTSUB(stash, "DMPAPER_JENV_KAKU3", newSVdual(aTHX_ DMPAPER_JENV_KAKU3, "jenv_kaku3"));
#endif
#ifdef DMPAPER_JENV_KAKU3_ROTATED
    newCONSTSUB(stash, "DMPAPER_JENV_KAKU3_ROTATED", newSVdual(aTHX_ DMPAPER_JENV_KAKU3_ROTATED, "jenv_kaku3_rotated"));
#endif
#ifdef DMPAPER_JENV_YOU4
    newCONSTSUB(stash, "DMPAPER_JENV_YOU4", newSVdual(aTHX_ DMPAPER_JENV_YOU4, "jenv_you4"));
#endif
#ifdef DMPAPER_JENV_YOU4_ROTATED
    newCONSTSUB(stash, "DMPAPER_JENV_YOU4_ROTATED", newSVdual(aTHX_ DMPAPER_JENV_YOU4_ROTATED, "jenv_you4_rotated"));
#endif
#ifdef DMPAPER_LAST
    newCONSTSUB(stash, "DMPAPER_LAST", newSVdual(aTHX_ DMPAPER_LAST, "last"));
#endif
#ifdef DMPAPER_LEDGER
    newCONSTSUB(stash, "DMPAPER_LEDGER", newSVdual(aTHX_ DMPAPER_LEDGER, "ledger"));
#endif
#ifdef DMPAPER_LEGAL_EXTRA
    newCONSTSUB(stash, "DMPAPER_LEGAL_EXTRA", newSVdual(aTHX_ DMPAPER_LEGAL_EXTRA, "legal_extra"));
#endif
#ifdef DMPAPER_LETTER_EXTRA
    newCONSTSUB(stash, "DMPAPER_LETTER_EXTRA", newSVdual(aTHX_ DMPAPER_LETTER_EXTRA, "letter_extra"));
#endif
#ifdef DMPAPER_LETTER_EXTRA_TRANSVERSE
    newCONSTSUB(stash, "DMPAPER_LETTER_EXTRA_TRANSVERSE", newSVdual(aTHX_ DMPAPER_LETTER_EXTRA_TRANSVERSE, "letter_extra_transverse"));
#endif
#ifdef DMPAPER_LETTER_ROTATED
    newCONSTSUB(stash, "DMPAPER_LETTER_ROTATED", newSVdual(aTHX_ DMPAPER_LETTER_ROTATED, "letter_rotated"));
#endif
#ifdef DMPAPER_LETTERSMALL
    newCONSTSUB(stash, "DMPAPER_LETTERSMALL", newSVdual(aTHX_ DMPAPER_LETTERSMALL, "lettersmall"));
#endif
#ifdef DMPAPER_LETTER_TRANSVERSE
    newCONSTSUB(stash, "DMPAPER_LETTER_TRANSVERSE", newSVdual(aTHX_ DMPAPER_LETTER_TRANSVERSE, "letter_transverse"));
#endif
#ifdef DMPAPER_NOTE
    newCONSTSUB(stash, "DMPAPER_NOTE", newSVdual(aTHX_ DMPAPER_NOTE, "note"));
#endif
#ifdef DMPAPER_P16K
    newCONSTSUB(stash, "DMPAPER_P16K", newSVdual(aTHX_ DMPAPER_P16K, "p16k"));
#endif
#ifdef DMPAPER_P16K_ROTATED
    newCONSTSUB(stash, "DMPAPER_P16K_ROTATED", newSVdual(aTHX_ DMPAPER_P16K_ROTATED, "p16k_rotated"));
#endif
#ifdef DMPAPER_P32K
    newCONSTSUB(stash, "DMPAPER_P32K", newSVdual(aTHX_ DMPAPER_P32K, "p32k"));
#endif
#ifdef DMPAPER_P32K_ROTATED
    newCONSTSUB(stash, "DMPAPER_P32K_ROTATED", newSVdual(aTHX_ DMPAPER_P32K_ROTATED, "p32k_rotated"));
#endif
#ifdef DMPAPER_P32KBIG
    newCONSTSUB(stash, "DMPAPER_P32KBIG", newSVdual(aTHX_ DMPAPER_P32KBIG, "p32kbig"));
#endif
#ifdef DMPAPER_P32KBIG_ROTATED
    newCONSTSUB(stash, "DMPAPER_P32KBIG_ROTATED", newSVdual(aTHX_ DMPAPER_P32KBIG_ROTATED, "p32kbig_rotated"));
#endif
#ifdef DMPAPER_PENV_1
    newCONSTSUB(stash, "DMPAPER_PENV_1", newSVdual(aTHX_ DMPAPER_PENV_1, "penv_1"));
#endif
#ifdef DMPAPER_PENV_1_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_1_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_1_ROTATED, "penv_1_rotated"));
#endif
#ifdef DMPAPER_PENV_2
    newCONSTSUB(stash, "DMPAPER_PENV_2", newSVdual(aTHX_ DMPAPER_PENV_2, "penv_2"));
#endif
#ifdef DMPAPER_PENV_2_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_2_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_2_ROTATED, "penv_2_rotated"));
#endif
#ifdef DMPAPER_PENV_3
    newCONSTSUB(stash, "DMPAPER_PENV_3", newSVdual(aTHX_ DMPAPER_PENV_3, "penv_3"));
#endif
#ifdef DMPAPER_PENV_3_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_3_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_3_ROTATED, "penv_3_rotated"));
#endif
#ifdef DMPAPER_PENV_4
    newCONSTSUB(stash, "DMPAPER_PENV_4", newSVdual(aTHX_ DMPAPER_PENV_4, "penv_4"));
#endif
#ifdef DMPAPER_PENV_4_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_4_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_4_ROTATED, "penv_4_rotated"));
#endif
#ifdef DMPAPER_PENV_5
    newCONSTSUB(stash, "DMPAPER_PENV_5", newSVdual(aTHX_ DMPAPER_PENV_5, "penv_5"));
#endif
#ifdef DMPAPER_PENV_5_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_5_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_5_ROTATED, "penv_5_rotated"));
#endif
#ifdef DMPAPER_PENV_6
    newCONSTSUB(stash, "DMPAPER_PENV_6", newSVdual(aTHX_ DMPAPER_PENV_6, "penv_6"));
#endif
#ifdef DMPAPER_PENV_6_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_6_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_6_ROTATED, "penv_6_rotated"));
#endif
#ifdef DMPAPER_PENV_7
    newCONSTSUB(stash, "DMPAPER_PENV_7", newSVdual(aTHX_ DMPAPER_PENV_7, "penv_7"));
#endif
#ifdef DMPAPER_PENV_7_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_7_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_7_ROTATED, "penv_7_rotated"));
#endif
#ifdef DMPAPER_PENV_8
    newCONSTSUB(stash, "DMPAPER_PENV_8", newSVdual(aTHX_ DMPAPER_PENV_8, "penv_8"));
#endif
#ifdef DMPAPER_PENV_8_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_8_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_8_ROTATED, "penv_8_rotated"));
#endif
#ifdef DMPAPER_PENV_9
    newCONSTSUB(stash, "DMPAPER_PENV_9", newSVdual(aTHX_ DMPAPER_PENV_9, "penv_9"));
#endif
#ifdef DMPAPER_PENV_9_ROTATED
    newCONSTSUB(stash, "DMPAPER_PENV_9_ROTATED", newSVdual(aTHX_ DMPAPER_PENV_9_ROTATED, "penv_9_rotated"));
#endif
#ifdef DMPAPER_PENV_10
    newCONSTSUB(stash, "DMPAPER_PENV_10", newSVdual(aTHX_ DMPAPER_PENV_10, "penv_10"));
#endif
#ifdef DMPAPER_QUARTO
    newCONSTSUB(stash, "DMPAPER_QUARTO", newSVdual(aTHX_ DMPAPER_QUARTO, "quarto"));
#endif
#ifdef DMPAPER_STATEMENT
    newCONSTSUB(stash, "DMPAPER_STATEMENT", newSVdual(aTHX_ DMPAPER_STATEMENT, "statement"));
#endif
#ifdef DMPAPER_TABLOID
    newCONSTSUB(stash, "DMPAPER_TABLOID", newSVdual(aTHX_ DMPAPER_TABLOID, "tabloid"));
#endif
#ifdef DMPAPER_TABLOID_EXTRA
    newCONSTSUB(stash, "DMPAPER_TABLOID_EXTRA", newSVdual(aTHX_ DMPAPER_TABLOID_EXTRA, "tabloid_extra"));
#endif
#ifdef DMRES_HIGH
    newCONSTSUB(stash, "DMRES_HIGH", newSVdual(aTHX_ DMRES_HIGH, "high"));
#endif
#ifdef DMRES_MEDIUM
    newCONSTSUB(stash, "DMRES_MEDIUM", newSVdual(aTHX_ DMRES_MEDIUM, "medium"));
#endif
#ifdef DMRES_LOW
    newCONSTSUB(stash, "DMRES_LOW", newSVdual(aTHX_ DMRES_LOW, "low"));
#endif
#ifdef DMRES_DRAFT
    newCONSTSUB(stash, "DMRES_DRAFT", newSVdual(aTHX_ DMRES_DRAFT, "draft"));
#endif
#ifdef DMTT_BITMAP
    newCONSTSUB(stash, "DMTT_BITMAP", newSVdual(aTHX_ DMTT_BITMAP, "bitmap"));
#endif
#ifdef DMTT_DOWNLOAD
    newCONSTSUB(stash, "DMTT_DOWNLOAD", newSVdual(aTHX_ DMTT_DOWNLOAD, "download"));
#endif
#ifdef DMTT_DOWNLOAD_OUTLINE
    newCONSTSUB(stash, "DMTT_DOWNLOAD_OUTLINE", newSVdual(aTHX_ DMTT_DOWNLOAD_OUTLINE, "download_outline"));
#endif
#ifdef DMTT_SUBDEV
    newCONSTSUB(stash, "DMTT_SUBDEV", newSVdual(aTHX_ DMTT_SUBDEV, "subdev"));
#endif
#ifdef PRINTER_ENUM_LOCAL
    newCONSTSUB(stash, "PRINTER_ENUM_LOCAL", newSVdual(aTHX_ PRINTER_ENUM_LOCAL, "local"));
#endif
#ifdef PRINTER_ENUM_NAME
    newCONSTSUB(stash, "PRINTER_ENUM_NAME", newSVdual(aTHX_ PRINTER_ENUM_NAME, "name"));
#endif
#ifdef PRINTER_ENUM_SHARED
    newCONSTSUB(stash, "PRINTER_ENUM_SHARED", newSVdual(aTHX_ PRINTER_ENUM_SHARED, "shared"));
#endif
#ifdef PRINTER_ENUM_CONNECTIONS
    newCONSTSUB(stash, "PRINTER_ENUM_CONNECTIONS", newSVdual(aTHX_ PRINTER_ENUM_CONNECTIONS, "connections"));
#endif
#ifdef PRINTER_ENUM_NETWORK
    newCONSTSUB(stash, "PRINTER_ENUM_NETWORK", newSVdual(aTHX_ PRINTER_ENUM_NETWORK, "network"));
#endif
#ifdef PRINTER_ENUM_REMOTE
    newCONSTSUB(stash, "PRINTER_ENUM_REMOTE", newSVdual(aTHX_ PRINTER_ENUM_REMOTE, "remote"));
#endif
#ifdef PRINTER_ENUM_CATEGORY_3D
    newCONSTSUB(stash, "PRINTER_ENUM_CATEGORY_3D", newSVdual(aTHX_ PRINTER_ENUM_CATEGORY_3D, "category_3d"));
#endif
#ifdef PRINTER_ENUM_CATEGORY_ALL
    newCONSTSUB(stash, "PRINTER_ENUM_CATEGORY_ALL", newSVdual(aTHX_ PRINTER_ENUM_CATEGORY_ALL, "category_all"));
#endif
#ifdef PRINTER_ENUM_EXPAND
    newCONSTSUB(stash, "PRINTER_ENUM_EXPAND", newSVdual(aTHX_ PRINTER_ENUM_EXPAND, "expand"));
#endif
#ifdef PRINTER_ENUM_CONTAINER
    newCONSTSUB(stash, "PRINTER_ENUM_CONTAINER", newSVdual(aTHX_ PRINTER_ENUM_CONTAINER, "container"));
#endif
#ifdef PRINTER_ENUM_ICON1
    newCONSTSUB(stash, "PRINTER_ENUM_ICON1", newSVdual(aTHX_ PRINTER_ENUM_ICON1, "icon1"));
#endif
#ifdef PRINTER_ENUM_ICON2
    newCONSTSUB(stash, "PRINTER_ENUM_ICON2", newSVdual(aTHX_ PRINTER_ENUM_ICON2, "icon2"));
#endif
#ifdef PRINTER_ENUM_ICON3
    newCONSTSUB(stash, "PRINTER_ENUM_ICON3", newSVdual(aTHX_ PRINTER_ENUM_ICON3, "icon3"));
#endif
#ifdef PRINTER_ENUM_ICON4
    newCONSTSUB(stash, "PRINTER_ENUM_ICON4", newSVdual(aTHX_ PRINTER_ENUM_ICON4, "icon4"));
#endif
#ifdef PRINTER_ENUM_ICON5
    newCONSTSUB(stash, "PRINTER_ENUM_ICON5", newSVdual(aTHX_ PRINTER_ENUM_ICON5, "icon5"));
#endif
#ifdef PRINTER_ENUM_ICON6
    newCONSTSUB(stash, "PRINTER_ENUM_ICON6", newSVdual(aTHX_ PRINTER_ENUM_ICON6, "icon6"));
#endif
#ifdef PRINTER_ENUM_ICON7
    newCONSTSUB(stash, "PRINTER_ENUM_ICON7", newSVdual(aTHX_ PRINTER_ENUM_ICON7, "icon7"));
#endif
#ifdef PRINTER_ENUM_ICON8
    newCONSTSUB(stash, "PRINTER_ENUM_ICON8", newSVdual(aTHX_ PRINTER_ENUM_ICON8, "icon8"));
#endif
#ifdef FORM_USER
    newCONSTSUB(stash, "FORM_USER", newSVdual(aTHX_ FORM_USER, "user"));
#endif
#ifdef FORM_BUILTIN
    newCONSTSUB(stash, "FORM_BUILTIN", newSVdual(aTHX_ FORM_BUILTIN, "builtin"));
#endif
#ifdef FORM_PRINTER
    newCONSTSUB(stash, "FORM_PRINTER", newSVdual(aTHX_ FORM_PRINTER, "printer"));
#endif
#ifdef PRINTER_STATUS_BUSY
    newCONSTSUB(stash, "PRINTER_STATUS_BUSY", newSVdual(aTHX_ PRINTER_STATUS_BUSY, "busy"));
#endif
#ifdef PRINTER_STATUS_DOOR_OPEN
    newCONSTSUB(stash, "PRINTER_STATUS_DOOR_OPEN", newSVdual(aTHX_ PRINTER_STATUS_DOOR_OPEN, "door_open"));
#endif
#ifdef PRINTER_STATUS_ERROR
    newCONSTSUB(stash, "PRINTER_STATUS_ERROR", newSVdual(aTHX_ PRINTER_STATUS_ERROR, "error"));
#endif
#ifdef PRINTER_STATUS_INITIALIZING
    newCONSTSUB(stash, "PRINTER_STATUS_INITIALIZING", newSVdual(aTHX_ PRINTER_STATUS_INITIALIZING, "initializing"));
#endif
#ifdef PRINTER_STATUS_IO_ACTIVE
    newCONSTSUB(stash, "PRINTER_STATUS_IO_ACTIVE", newSVdual(aTHX_ PRINTER_STATUS_IO_ACTIVE, "io_active"));
#endif
#ifdef PRINTER_STATUS_MANUAL_FEED
    newCONSTSUB(stash, "PRINTER_STATUS_MANUAL_FEED", newSVdual(aTHX_ PRINTER_STATUS_MANUAL_FEED, "manual_feed"));
#endif
#ifdef PRINTER_STATUS_NO_TONER
    newCONSTSUB(stash, "PRINTER_STATUS_NO_TONER", newSVdual(aTHX_ PRINTER_STATUS_NO_TONER, "no_toner"));
#endif
#ifdef PRINTER_STATUS_NOT_AVAILABLE
    newCONSTSUB(stash, "PRINTER_STATUS_NOT_AVAILABLE", newSVdual(aTHX_ PRINTER_STATUS_NOT_AVAILABLE, "not_available"));
#endif
#ifdef PRINTER_STATUS_OFFLINE
    newCONSTSUB(stash, "PRINTER_STATUS_OFFLINE", newSVdual(aTHX_ PRINTER_STATUS_OFFLINE, "offline"));
#endif
#ifdef PRINTER_STATUS_OUT_OF_MEMORY
    newCONSTSUB(stash, "PRINTER_STATUS_OUT_OF_MEMORY", newSVdual(aTHX_ PRINTER_STATUS_OUT_OF_MEMORY, "out_of_memory"));
#endif
#ifdef PRINTER_STATUS_OUTPUT_BIN_FULL
    newCONSTSUB(stash, "PRINTER_STATUS_OUTPUT_BIN_FULL", newSVdual(aTHX_ PRINTER_STATUS_OUTPUT_BIN_FULL, "output_bin_full"));
#endif
#ifdef PRINTER_STATUS_PAGE_PUNT
    newCONSTSUB(stash, "PRINTER_STATUS_PAGE_PUNT", newSVdual(aTHX_ PRINTER_STATUS_PAGE_PUNT, "page_punt"));
#endif
#ifdef PRINTER_STATUS_PAPER_JAM
    newCONSTSUB(stash, "PRINTER_STATUS_PAPER_JAM", newSVdual(aTHX_ PRINTER_STATUS_PAPER_JAM, "paper_jam"));
#endif
#ifdef PRINTER_STATUS_PAPER_OUT
    newCONSTSUB(stash, "PRINTER_STATUS_PAPER_OUT", newSVdual(aTHX_ PRINTER_STATUS_PAPER_OUT, "paper_out"));
#endif
#ifdef PRINTER_STATUS_PAPER_PROBLEM
    newCONSTSUB(stash, "PRINTER_STATUS_PAPER_PROBLEM", newSVdual(aTHX_ PRINTER_STATUS_PAPER_PROBLEM, "paper_problem"));
#endif
#ifdef PRINTER_STATUS_PAUSED
    newCONSTSUB(stash, "PRINTER_STATUS_PAUSED", newSVdual(aTHX_ PRINTER_STATUS_PAUSED, "paused"));
#endif
#ifdef PRINTER_STATUS_PENDING_DELETION
    newCONSTSUB(stash, "PRINTER_STATUS_PENDING_DELETION", newSVdual(aTHX_ PRINTER_STATUS_PENDING_DELETION, "pending_deletion"));
#endif
#ifdef PRINTER_STATUS_POWER_SAVE
    newCONSTSUB(stash, "PRINTER_STATUS_POWER_SAVE", newSVdual(aTHX_ PRINTER_STATUS_POWER_SAVE, "power_save"));
#endif
#ifdef PRINTER_STATUS_PRINTING
    newCONSTSUB(stash, "PRINTER_STATUS_PRINTING", newSVdual(aTHX_ PRINTER_STATUS_PRINTING, "printing"));
#endif
#ifdef PRINTER_STATUS_PROCESSING
    newCONSTSUB(stash, "PRINTER_STATUS_PROCESSING", newSVdual(aTHX_ PRINTER_STATUS_PROCESSING, "processing"));
#endif
#ifdef PRINTER_STATUS_SERVER_UNKNOWN
    newCONSTSUB(stash, "PRINTER_STATUS_SERVER_UNKNOWN", newSVdual(aTHX_ PRINTER_STATUS_SERVER_UNKNOWN, "server_unknown"));
#endif
#ifdef PRINTER_STATUS_TONER_LOW
    newCONSTSUB(stash, "PRINTER_STATUS_TONER_LOW", newSVdual(aTHX_ PRINTER_STATUS_TONER_LOW, "toner_low"));
#endif
#ifdef PRINTER_STATUS_USER_INTERVENTION
    newCONSTSUB(stash, "PRINTER_STATUS_USER_INTERVENTION", newSVdual(aTHX_ PRINTER_STATUS_USER_INTERVENTION, "user_intervention"));
#endif
#ifdef PRINTER_STATUS_WAITING
    newCONSTSUB(stash, "PRINTER_STATUS_WAITING", newSVdual(aTHX_ PRINTER_STATUS_WAITING, "waiting"));
#endif
#ifdef PRINTER_STATUS_WARMING_UP
    newCONSTSUB(stash, "PRINTER_STATUS_WARMING_UP", newSVdual(aTHX_ PRINTER_STATUS_WARMING_UP, "warming_up"));
#endif
#ifdef STRING_NONE
    newCONSTSUB(stash, "STRING_NONE", newSVdual(aTHX_ STRING_NONE, "none"));
#endif
#ifdef STRING_MUIDLL
    newCONSTSUB(stash, "STRING_MUIDLL", newSVdual(aTHX_ STRING_MUIDLL, "muidll"));
#endif
#ifdef STRING_LANGPAIR
    newCONSTSUB(stash, "STRING_LANGPAIR", newSVdual(aTHX_ STRING_LANGPAIR, "langpair"));
#endif

}

