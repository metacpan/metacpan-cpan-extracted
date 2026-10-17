# Doors onto the compiled tables, for the tests only. The engine that
# answers questions from them is Phase 04.

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

SV *
_tzdata_version()
    CODE:
        RETVAL = newSVpvs(TKZ_TZDATA_VERSION);
    OUTPUT:
        RETVAL

# (zones, links, lookup entries, types, transitions, footers, Windows names)
void
_counts()
    PPCODE:
        EXTEND(SP, 7);
        mPUSHu(TKZ_ZONE_COUNT);
        mPUSHu(TKZ_LINK_COUNT);
        mPUSHu(TKZ_LOOKUP_COUNT);
        mPUSHu(TKZ_TYPE_COUNT);
        mPUSHu(TKZ_TRANS_COUNT);
        mPUSHu(TKZ_FOOTER_COUNT);
        mPUSHu(TKZ_WINDOWS_COUNT);

# Every name in lookup order, as (name, canonical zone, is a link) triples.
void
_lookup_table()
    PREINIT:
        int i;
    PPCODE:
        EXTEND(SP, TKZ_LOOKUP_COUNT * 3);
        for (i = 0; i < TKZ_LOOKUP_COUNT; i++) {
            const tkz_lookup_entry *e = &tkz_lookup[i];
            mPUSHp(tkz_names + e->name, strlen(tkz_names + e->name));
            mPUSHp(tkz_names + tkz_zones[e->zone].name, strlen(tkz_names + tkz_zones[e->zone].name));
            mPUSHu(e->is_link);
        }

# (Windows name, zone) pairs.
void
_windows_table()
    PREINIT:
        int i;
    PPCODE:
        EXTEND(SP, TKZ_WINDOWS_COUNT * 2);
        for (i = 0; i < TKZ_WINDOWS_COUNT; i++) {
            const tkz_windows_entry *w = &tkz_windows[i];
            mPUSHp(tkz_windows_names + w->name, strlen(tkz_windows_names + w->name));
            mPUSHp(tkz_names + tkz_zones[w->zone].name, strlen(tkz_names + tkz_zones[w->zone].name));
        }

# One canonical zone, by its exact name, as a hash: its initial type, its
# transitions and its footer. undef for a name that is not a zone.
SV *
_zone_dump(name)
        const char *name
    PREINIT:
        int i, z = -1;
        uint32_t t;
        HV *hv;
        AV *trans;
        const tkz_zone *zone;
    CODE:
        for (i = 0; i < TKZ_ZONE_COUNT; i++)
            if (strEQ(tkz_names + tkz_zones[i].name, name)) { z = i; break; }
        if (z < 0)
            XSRETURN_UNDEF;
        zone = &tkz_zones[z];
        hv = newHV();
        (void)hv_stores(hv, "name", newSVpv(tkz_names + zone->name, 0));
        (void)hv_stores(hv, "initial", tkz_type_av(aTHX_ zone->initial_type));
        trans = newAV();
        for (t = 0; t < zone->n_trans; t++) {
            AV *row = (AV *)SvRV(tkz_type_av(aTHX_ tkz_trans_type[zone->first_trans + t]));
            av_unshift(row, 1);
            av_store(row, 0, tkz_newSVi64(aTHX_ tkz_trans_at[zone->first_trans + t]));
            av_push(trans, newRV_noinc((SV *)row));
        }
        (void)hv_stores(hv, "transitions", newRV_noinc((SV *)trans));
        if (zone->footer != TKZ_NO_FOOTER) {
            const tkz_footer *f = &tkz_footers[zone->footer];
            HV *fh = newHV();
            (void)hv_stores(fh, "text", newSVpv(tkz_footer_text + f->text, 0));
            (void)hv_stores(fh, "std_utoff", newSViv(f->std_utoff));
            (void)hv_stores(fh, "dst_utoff", newSViv(f->dst_utoff));
            (void)hv_stores(fh, "std", tkz_type_av(aTHX_ f->std_type));
            if (f->dst_type != 0xFFFF) {
                (void)hv_stores(fh, "dst", tkz_type_av(aTHX_ f->dst_type));
                (void)hv_stores(fh, "start", tkz_rule_hv(aTHX_ &f->start));
                (void)hv_stores(fh, "end", tkz_rule_hv(aTHX_ &f->end));
            }
            (void)hv_stores(hv, "footer", newRV_noinc((SV *)fh));
        }
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL
