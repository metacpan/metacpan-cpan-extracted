/* Implementation-specific variables */
#undef PACKAGE_NAME
#undef NULL_LITERAL
#undef NULL_LITERAL_LENGTH
#undef SCALAR_NUMBER
#undef SCALAR_STRING
#undef SCALAR_QUOTED
#undef SCALAR_UTF8
#undef SEQ_NONE
#undef MAP_NONE
#undef IS_UTF8
#undef TYPE_IS_NULL
#undef OBJOF
#undef PERL_SYCK_PARSER_HANDLER
#undef PERL_SYCK_EMITTER_HANDLER
#undef PERL_SYCK_INDENT_LEVEL
#undef PERL_SYCK_MARK_EMITTER
#undef PERL_SYCK_EMITTER_MARK_NODE_FLAGS

#ifdef YAML_IS_JSON
#  define PACKAGE_NAME  "JSON::Syck"
#  define NULL_LITERAL  "null"
#  define NULL_LITERAL_LENGTH 4
#  define SCALAR_NUMBER scalar_none
#  define PERL_SYCK_EMITTER_MARK_NODE_FLAGS EMITTER_MARK_NODE_FLAG_PERMIT_DUPLICATE_NODES
int json_max_depth = 512;
char json_quote_char = '"';
static enum scalar_style json_quote_style = scalar_2quote;
#  define SCALAR_STRING json_quote_style
#  define SCALAR_QUOTED json_quote_style
#  define SCALAR_UTF8   scalar_fold
#  define SEQ_NONE      seq_inline
#  define MAP_NONE      map_inline
#  define IS_UTF8(x)    TRUE
#  define TYPE_IS_NULL(x) ((x == NULL) || strEQ( x, "str" ))
#  define OBJOF(a)        (a)
#  define PERL_SYCK_PARSER_HANDLER json_syck_parser_handler
#  define PERL_SYCK_EMITTER_HANDLER json_syck_emitter_handler
#  define PERL_SYCK_MARK_EMITTER json_syck_mark_emitter
#  define PERL_SYCK_INDENT_LEVEL 0
#else
#  define PACKAGE_NAME  "YAML::Syck"
#  define REGEXP_LITERAL  "REGEXP"
#  define REGEXP_LITERAL_LENGTH 6
#  define REF_LITERAL  "="
#  define REF_LITERAL_LENGTH 1
#  define NULL_LITERAL  "~"
#  define NULL_LITERAL_LENGTH 1
#  define SCALAR_NUMBER scalar_none
#  define PERL_SYCK_EMITTER_MARK_NODE_FLAGS 0
static enum scalar_style yaml_quote_style = scalar_none;
#  define SCALAR_STRING yaml_quote_style
#  define SCALAR_QUOTED scalar_1quote
#  define SCALAR_UTF8   scalar_fold
#  define SEQ_NONE      seq_none
#  define MAP_NONE      map_none
#ifdef SvUTF8
#  define IS_UTF8(x)    (SvUTF8(sv))
#else
#  define IS_UTF8(x)    (FALSE)
#endif
#  define TYPE_IS_NULL(x) ((x == NULL) || strEQ( x, "str" ))
#  define OBJOF(a)        (*tag ? tag : a)
#  define PERL_SYCK_PARSER_HANDLER yaml_syck_parser_handler
#  define PERL_SYCK_EMITTER_HANDLER yaml_syck_emitter_handler
#  define PERL_SYCK_MARK_EMITTER yaml_syck_mark_emitter
#  define PERL_SYCK_INDENT_LEVEL 2
#endif

#define TRACK_OBJECT(sv) (av_push(((struct parser_xtra *)p->bonus)->objects, sv))
#define USE_OBJECT(sv) (SvREFCNT_inc(sv))

#ifndef YAML_IS_JSON

#ifndef SvRV_set        /* prior to 5.8.7; thx charsbar! */
#define SvRV_set(sv, val) \
    STMT_START { \
        (SvRV(sv) = (val)); } STMT_END
#endif

static const char *
is_bad_alias_object( SV *sv ) {
    SV *hv, **psv;

    if (! sv_isobject(sv))
        return NULL;

    hv = SvRV(sv);
    if (! strnEQ(sv_reftype(hv, 1), "YAML::Syck::BadAlias", 20-1))
        return NULL;

    psv = hv_fetch((HV *) hv, "name", 4, 0);
    if (! psv)
        return NULL;

    return SvPVX(*psv);
}

static void
register_bad_alias( SyckParser *p, const char *anchor, SV *sv ) {
    HV *map;
    SV **pref_av, *new_rvav;
    AV *rvs;

    map = ((struct parser_xtra *)p->bonus)->bad_anchors;
    pref_av = hv_fetch(map, anchor, strlen(anchor), 0);
    if (! pref_av) {
        new_rvav = newRV_noinc((SV *) newAV());
        hv_store(map, anchor, strlen(anchor), new_rvav, 0);
        pref_av = &new_rvav;
    }
    rvs = (AV *) SvRV(*pref_av);

    SvREFCNT_inc(sv);
    av_push(rvs, sv);
}

static void
resolve_bad_alias( SyckParser *p, const char *anchor, SV *sv ) {
    HV *map;
    SV **pref_av, *entity;
    AV *rvs;
    I32 len, i;

    entity = SvRV(sv);

    map = ((struct parser_xtra *)p->bonus)->bad_anchors;
    pref_av = hv_fetch(map, anchor, strlen(anchor), 0);
    if (! pref_av)
        return;

    rvs = (AV *) SvRV(*pref_av);
    len = av_len(rvs)+1;
    for (i = 0; i < len; i ++) {
        SV **prv = av_fetch(rvs, i, 0);
        if (prv) {
            SvREFCNT_dec(SvRV(*prv));
            SvRV_set(*prv, entity);
            SvREFCNT_inc(entity);
        }
    }
    av_clear(rvs);
}

#endif

SYMID
#ifdef YAML_IS_JSON
json_syck_parser_handler
#else
yaml_syck_parser_handler
#endif
(SyckParser *p, SyckNode *n) {
    SV *sv = NULL;
    AV *seq;
    HV *map;
    long i;
    char *id = n->type_id;
#ifndef YAML_IS_JSON
    struct parser_xtra *bonus = (struct parser_xtra *)p->bonus;
    bool load_code = bonus->load_code;
    bool load_blessed = bonus->load_blessed;
#endif

    while (id && (*id == '!')) { id++; }

    switch (n->kind) {
        case syck_str_kind:
            if (TYPE_IS_NULL(id)) {
                if (strnEQ( n->data.str->ptr, NULL_LITERAL, 1+NULL_LITERAL_LENGTH)
                    && (n->data.str->style == scalar_plain)) {
                    sv = newSV(0);
                }
                else {
                    sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                    CHECK_UTF8;
                }
            } else if (strEQ( id, "null" )) {
                sv = newSV(0);
            } else if (strEQ( id, "bool#yes" )) {
                sv = newSVsv(&PL_sv_yes);
            } else if (strEQ( id, "bool#no" )) {
                sv = newSVsv(&PL_sv_no);
            } else if (strEQ( id, "default" )) {
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                CHECK_UTF8;
            } else if (strEQ( id, "float#base60" )) {
                char *ptr, *end;
                UV sixty = 1;
                NV total = 0.0;
                syck_str_blow_away_commas( n );
                ptr = n->data.str->ptr;
                end = n->data.str->ptr + n->data.str->len;
                while ( end > ptr )
                {
                    NV bnum = 0;
                    char *colon = end - 1;
                    while ( colon > ptr && *colon != ':' )
                    {
                        colon--;
                    }
                    if ( *colon == ':' ) {
                        *colon = '\0';
                        bnum = Atof( colon + 1 );
                        end = colon;
                    } else {
                        bnum = Atof( ptr );
                        end = ptr;
                    }
                    total += bnum * sixty;
                    sixty *= 60;
                }
                sv = newSVnv(total);
#ifdef NV_NAN
            } else if (strEQ( id, "float#nan" )) {
                sv = newSVnv(NV_NAN);
#endif
#ifdef NV_INF
            } else if (strEQ( id, "float#inf" )) {
                sv = newSVnv(NV_INF);
            } else if (strEQ( id, "float#neginf" )) {
                sv = newSVnv(-NV_INF);
#endif
            } else if (strnEQ( id, "float", 5 )) {
                NV f;
                syck_str_blow_away_commas( n );
                f = Atof( n->data.str->ptr );
                sv = newSVnv( f );
            } else if (strEQ( id, "int#base60" )) {
                char *ptr, *end;
                UV sixty = 1;
                UV total = 0;
                int is_neg;
                syck_str_blow_away_commas( n );
                ptr = n->data.str->ptr;
                is_neg = (*ptr == '-');
                if (is_neg) ptr++;
                end = n->data.str->ptr + n->data.str->len;
                while ( end > ptr )
                {
                    long bnum = 0;
                    char *colon = end - 1;
                    while ( colon > ptr && *colon != ':' )
                    {
                        colon--;
                    }
                    if ( *colon == ':' ) {
                        *colon = '\0';
                        bnum = strtol( colon + 1, NULL, 10 );
                        end = colon;
                    } else {
                        bnum = strtol( ptr, NULL, 10 );
                        end = ptr;
                    }
                    total += bnum * sixty;
                    sixty *= 60;
                }
                if (is_neg)
                    sv = newSViv(-(IV)total);
                else
                    sv = newSVuv(total);
            } else if (strEQ( id, "int#hex" )) {
                I32 flags = 0;
                char *ptr = n->data.str->ptr;
                STRLEN len = n->data.str->len;
                int is_neg = (*ptr == '-');
                syck_str_blow_away_commas( n );
                if (is_neg) { ptr++; len--; }
                UV uv = grok_hex( ptr, &len, &flags, NULL);
                if (is_neg)
                    sv = newSViv(-(IV)uv);
                else
                    sv = newSVuv(uv);
            } else if (strEQ( id, "int#oct" )) {
                I32 flags = 0;
                char *ptr = n->data.str->ptr;
                STRLEN len = n->data.str->len;
                int is_neg = (*ptr == '-');
                syck_str_blow_away_commas( n );
                if (is_neg) { ptr++; len--; }
                UV uv = grok_oct( ptr, &len, &flags, NULL);
                if (is_neg)
                    sv = newSViv(-(IV)uv);
                else
                    sv = newSVuv(uv);
            } else if (strEQ( id, "int" ) ) {
                UV uv;
                int flags;

                syck_str_blow_away_commas( n );
                flags = grok_number( n->data.str->ptr, n->data.str->len, &uv);

                if (flags == IS_NUMBER_IN_UV) {
                    if (uv <= IV_MAX) {
                        sv = newSViv(uv);
                    }
                    else {
                        sv = newSVuv(uv);
                    }
                }
                else if ((flags == (IS_NUMBER_IN_UV | IS_NUMBER_NEG)) && (uv <= (UV) IV_MIN)) {
                    sv = newSViv(-(IV)uv);
                }
                else {
                    sv = newSVnv(Atof( n->data.str->ptr ));
                }
            } else if (strEQ( id, "binary" )) {
                long len = 0;
                char *blob = syck_base64dec(n->data.str->ptr, n->data.str->len, &len);
                sv = newSVpv(blob, len);
#ifndef YAML_IS_JSON
#ifdef PERL_LOADMOD_NOIMPORT
            } else if (strEQ(id, "perl/code") || strnEQ(id, "perl/code:", 10)) {
                SV *cv;
                SV *sub;
                char *pkg = id + 10;

                if (load_code) {
                    SV *text;

                    /* This code is copypasted from Storable.xs */

                    /*
                     * prepend "sub " to the source
                     */

                    text = newSVpvn(n->data.str->ptr, n->data.str->len);

                    sub = newSVpvn("sub ", 4);
                    sv_catpv(sub, SvPV_nolen(text)); /* XXX no sv_catsv! */
                    SvREFCNT_dec(text);
                } else {
                    sub = newSVpvn("sub {}", 6);
                }

                ENTER;
                SAVETMPS;

                sv_2mortal(sub);

                cv = eval_pv(SvPV_nolen(sub), FALSE);

                if (SvTRUE(ERRSV)) {
                    FREETMPS;
                    LEAVE;
                    croak("code %s did not evaluate to a subroutine reference\n", SvPV_nolen(ERRSV));
                }

                if (cv && SvROK(cv) && SvTYPE(SvRV(cv)) == SVt_PVCV) {
                    sv = cv;
                }
                else {
                    FREETMPS;
                    LEAVE;
                    croak("code %s did not evaluate to a subroutine reference\n", SvPV_nolen(sub));
                }

                SvREFCNT_inc(sv); /* prevent FREETMPS from freeing the mortal cv */

                FREETMPS;
                LEAVE;

                if ( load_blessed && (*(pkg - 1) != '\0') && (*pkg != '\0') ) {
                    sv_bless(sv, gv_stashpv(pkg, TRUE));
                }

                /* END Storable */

            } else if (strnEQ( n->data.str->ptr, REF_LITERAL, 1+REF_LITERAL_LENGTH)) {
                /* type tag in a scalar ref */
                char *id_copy = savepv(id);
                char *lang = id_copy;
                char *type = strpbrk(id_copy, "/:");
                if (type != NULL) { *type = '\0'; type++; if (*type == '\0') type = NULL; }

                if (lang == NULL || (strEQ(lang, "perl"))) {
                    if (type != NULL) {
                        sv = newSVpv(type, 0);
                    } else {
                        /* Tag has no type component (e.g. "!perl =") —
                         * fall back to raw scalar content */
                        sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                        CHECK_UTF8;
                    }
                }
                else {
                    sv = newSVpv((type == NULL) ? lang : form("%s::%s", lang, type), 0);
                }
                Safefree(id_copy);
            } else if ( strEQ( id, "perl/scalar" ) || strnEQ( id, "perl/scalar:", 12 ) ) {
                char *pkg = id + 12;

                if (strnEQ( n->data.str->ptr, NULL_LITERAL, 1+NULL_LITERAL_LENGTH)
                    && (n->data.str->style == scalar_plain)) {
                    sv = newSV(0);
                }
                else {
                    sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                    CHECK_UTF8;
                }

                sv = newRV_noinc(sv);

                if ( load_blessed && (*(pkg - 1) != '\0') && (*pkg != '\0') ) {
                    sv_bless(sv, gv_stashpv(id + 12, TRUE));
                }

            } else if ( (strEQ(id, "perl/regexp") || strnEQ( id, "perl/regexp:", 12 ) ) ) {
                dSP;
                SV *val = newSVpvn(n->data.str->ptr, n->data.str->len);
                char *id_copy = savepv(id);
                char *lang = id_copy;
                char *type = strpbrk(id_copy, "/:");
                if (type != NULL) { *type = '\0'; type++; if (*type == '\0') type = NULL; }

                ENTER;
                SAVETMPS;
                PUSHMARK(sp);
                XPUSHs(val);
                PUTBACK;
                call_pv("YAML::Syck::__qr_helper", G_SCALAR);
                SPAGAIN;

                sv = newSVsv(POPs);

                PUTBACK;
                FREETMPS;
                LEAVE;

                /* bless it if necessary */
                if ( type != NULL && strnEQ(type, "regexp:", 7)) {
                    /* !perl/regexp:Foo::Bar blesses into Foo::Bar */
                    type += 7;
                }

                if ( load_blessed ) {
					if (lang == NULL || (strEQ(lang, "perl"))) {
						/* !perl/regexp on it's own causes no blessing */
						if ( (type != NULL) && strNE(type, "regexp") && (*type != '\0')) {
							sv_bless(sv, gv_stashpv(type, TRUE));
						}
					}
					else {
						sv_bless(sv, gv_stashpv((type == NULL) ? lang : form("%s::%s", lang, type), TRUE));
					}
                }
                Safefree(id_copy);
#endif /* PERL_LOADMOD_NOIMPORT */
#endif /* !YAML_IS_JSON */
            } else {
                /* croak("unknown node type: %s", id); */
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                CHECK_UTF8;
            }
        break;

        case syck_seq_kind:
            /* load the seq into a new AV and place a ref to it in the SV */
            seq = newAV();
            for (i = 0; i < n->data.list->idx; i++) {
                SV *a = perl_syck_lookup_sym(p, syck_seq_read(n, i));
#ifndef YAML_IS_JSON
                const char *forward_anchor;

                a = sv_2mortal(newSVsv(a));
                forward_anchor = is_bad_alias_object(a);
                if (forward_anchor)
                    register_bad_alias(p, forward_anchor, a);
#endif
                av_push(seq, a);
                USE_OBJECT(a);
            }
            /* create the ref to the new array in the sv */
            sv = newRV_noinc((SV*)seq);
#ifndef YAML_IS_JSON

            if (id) {
                /* bless it if necessary */
                char *id_copy = savepv(id);
                char *lang = id_copy;
                char *type = strpbrk(id_copy, "/:");
                if (type != NULL) { *type = '\0'; type++; if (*type == '\0') type = NULL; }

                if ( type != NULL ) {
                    if (strnEQ(type, "array:", 6)) {
                        /* !perl/array:Foo::Bar blesses into Foo::Bar */
                        type += 6;
                    }

                    /* FIXME deprecated - here compatibility with @Foo::Bar style blessing */
                    while ( *type == '@' ) { type++; }
                }

                if (load_blessed) {
                	if (lang == NULL || (strEQ(lang, "perl"))) {
                		/* !perl/array on it's own causes no blessing */
                		if ( (type != NULL) && strNE(type, "array") && *type != '\0' ) {
                			sv_bless(sv, gv_stashpv(type, TRUE));
                		}
                	}
                	else {
                		sv_bless(sv, gv_stashpv((type == NULL) ? lang : form("%s::%s", lang, type), TRUE));
                	}
                }
                Safefree(id_copy);
            }
#endif
        break;

        case syck_map_kind:
#ifndef YAML_IS_JSON
            if ( (id != NULL) && (strEQ(id, "perl/ref") || strnEQ( id, "perl/ref:", 9 ) ) ) {
                /* handle scalar references, that are a weird type of mappings */
                SV* key = perl_syck_lookup_sym(p, syck_map_read(n, map_key, 0));
                SV* val = perl_syck_lookup_sym(p, syck_map_read(n, map_value, 0));
                char *ref_type = SvPVX(key);
#if 0 /* need not to duplicate scalar reference */
                const char *forward_anchor;

                val = sv_2mortal(newSVsv(val));
                forward_anchor = is_bad_alias_object(val);
                if (forward_anchor)
                    register_bad_alias(p, forward_anchor, val);
#endif
                sv = newRV_noinc(val);
                USE_OBJECT(val);

                if ( load_blessed ) {
					if ( strnNE(ref_type, REF_LITERAL, REF_LITERAL_LENGTH+1)) {
						/* handle the weird audrey scalar ref stuff */
						sv_bless(sv, gv_stashpv(ref_type, TRUE));
					}
					else {
						/* bless it if necessary */
						char *id_copy = savepv(id);
						char *lang = id_copy;
						char *type = strpbrk(id_copy, "/:");
						if (type != NULL) { *type = '\0'; type++; if (*type == '\0') type = NULL; }

						if ( type != NULL && strnEQ(type, "ref:", 4)) {
							/* !perl/ref:Foo::Bar blesses into Foo::Bar */
							type += 4;
						}
							if (lang == NULL || (strEQ(lang, "perl"))) {
								/* !perl/ref on it's own causes no blessing */
								if ( (type != NULL) && strNE(type, "ref") && (*type != '\0')) {
									sv_bless(sv, gv_stashpv(type, TRUE));
								}
							}
							else {
								sv_bless(sv, gv_stashpv((type == NULL) ? lang : form("%s::%s", lang, type), TRUE));
							}
						Safefree(id_copy);
					}
                }
            }
            else if ( (id != NULL) && (strEQ(id, "perl/regexp") || strnEQ( id, "perl/regexp:", 12 ) ) ) {
                /* handle regexp references, that are a weird type of mappings */
                dSP;
                SV* key = perl_syck_lookup_sym(p, syck_map_read(n, map_key, 0));
                SV* val = perl_syck_lookup_sym(p, syck_map_read(n, map_value, 0));
                char *ref_type = SvPVX(key);

                ENTER;
                SAVETMPS;
                PUSHMARK(sp);
                XPUSHs(val);
                PUTBACK;
                call_pv("YAML::Syck::__qr_helper", G_SCALAR);
                SPAGAIN;

                sv = newSVsv(POPs);

                PUTBACK;
                FREETMPS;
                LEAVE;

                if ( load_blessed ) {
					if (strnNE(ref_type, REGEXP_LITERAL, REGEXP_LITERAL_LENGTH+1)) {
						/* handle the weird audrey scalar ref stuff */
						sv_bless(sv, gv_stashpv(ref_type, TRUE));
					}
					else {
						/* bless it if necessary */
						char *id_copy = savepv(id);
						char *lang = id_copy;
						char *type = strpbrk(id_copy, "/:");
						if (type != NULL) { *type = '\0'; type++; if (*type == '\0') type = NULL; }

						if ( type != NULL && strnEQ(type, "regexp:", 7)) {
							/* !perl/regexp:Foo::Bar blesses into Foo::Bar */
							type += 7;
						}

						if (lang == NULL || (strEQ(lang, "perl"))) {
							/* !perl/regexp on it's own causes no blessing */
							if ( (type != NULL) && strNE(type, "regexp") && (*type != '\0')) {
								sv_bless(sv, gv_stashpv(type, TRUE));
							}
						}
						else {
							sv_bless(sv, gv_stashpv((type == NULL) ? lang : form("%s::%s", lang, type), TRUE));
						}
						Safefree(id_copy);
					}
                }
            }
            else if (id && strnEQ(id, "perl:YAML::Syck::BadAlias", 25-1)) {
                SV* key = (SV *) syck_map_read(n, map_key, 0);
                SV* val = (SV *) syck_map_read(n, map_value, 0);
                map = newHV();
                if (hv_store_ent(map, key, val, 0) != NULL)
                    USE_OBJECT(val);
                sv = newRV_noinc((SV*)map);
                sv_bless(sv, gv_stashpv("YAML::Syck::BadAlias", TRUE));
            }
            else
#endif
            {
                /* load the map into a new HV and place a ref to it in the SV */
#ifndef YAML_IS_JSON
                AV *merge_values = NULL;
#endif
                map = newHV();
                for (i = 0; i < n->data.pairs->idx; i++) {
                    SV* key = perl_syck_lookup_sym(p, syck_map_read(n, map_key, i));
                    SV* val = perl_syck_lookup_sym(p, syck_map_read(n, map_value, i));
#ifndef YAML_IS_JSON
                    const char *forward_anchor;

                    val = sv_2mortal(newSVsv(val));
                    forward_anchor = is_bad_alias_object(val);
                    if (forward_anchor)
                        register_bad_alias(p, forward_anchor, val);

                    /* YAML merge key (<<): defer merge processing until
                     * all explicit keys are stored, so explicit keys
                     * always take precedence over merged keys. */
                    if (p->implicit_typing) {
                        STRLEN klen;
                        const char *kpv = SvPV(key, klen);
                        if (klen == 2 && kpv[0] == '<' && kpv[1] == '<') {
                            if (!merge_values)
                                merge_values = newAV();
                            SvREFCNT_inc(val);
                            av_push(merge_values, val);
                            continue;
                        }
                    }
#endif
                    if (hv_store_ent(map, key, val, 0) != NULL)
                       USE_OBJECT(val);
                }
#ifndef YAML_IS_JSON
                /* Apply merge keys: copy entries from referenced mappings
                 * into the parent hash, skipping keys that already exist. */
                if (merge_values) {
                    long mi;
                    for (mi = 0; mi <= av_len(merge_values); mi++) {
                        SV **pmerge = av_fetch(merge_values, mi, 0);
                        if (!pmerge) continue;
                        if (SvROK(*pmerge) && SvTYPE(SvRV(*pmerge)) == SVt_PVHV) {
                            /* <<: *alias (single mapping) */
                            HV *merge_hv = (HV *)SvRV(*pmerge);
                            HE *he;
                            hv_iterinit(merge_hv);
                            while ((he = hv_iternext(merge_hv))) {
                                SV *hkey = hv_iterkeysv(he);
                                if (!hv_exists_ent(map, hkey, 0)) {
                                    SV *hval = hv_iterval(merge_hv, he);
                                    SvREFCNT_inc(hval);
                                    if (hv_store_ent(map, hkey, hval, 0) == NULL)
                                        SvREFCNT_dec(hval);
                                }
                            }
                        }
                        else if (SvROK(*pmerge) && SvTYPE(SvRV(*pmerge)) == SVt_PVAV) {
                            /* <<: [*a, *b] (sequence of mappings) */
                            AV *merge_av = (AV *)SvRV(*pmerge);
                            long ai;
                            for (ai = 0; ai <= av_len(merge_av); ai++) {
                                SV **pelem = av_fetch(merge_av, ai, 0);
                                HV *elem_hv;
                                HE *he;
                                if (!pelem || !SvROK(*pelem) || SvTYPE(SvRV(*pelem)) != SVt_PVHV)
                                    continue;
                                elem_hv = (HV *)SvRV(*pelem);
                                hv_iterinit(elem_hv);
                                while ((he = hv_iternext(elem_hv))) {
                                    SV *hkey = hv_iterkeysv(he);
                                    if (!hv_exists_ent(map, hkey, 0)) {
                                        SV *hval = hv_iterval(elem_hv, he);
                                        SvREFCNT_inc(hval);
                                        if (hv_store_ent(map, hkey, hval, 0) == NULL)
                                            SvREFCNT_dec(hval);
                                    }
                                }
                            }
                        }
                    }
                    SvREFCNT_dec((SV *)merge_values);
                }
#endif
                sv = newRV_noinc((SV*)map);
#ifndef YAML_IS_JSON
                if (id)  {
                    /* bless it if necessary */
                    char *id_copy = savepv(id);
                    char *lang = id_copy;
                    char *type = strpbrk(id_copy, "/:");
                    if (type != NULL) { *type = '\0'; type++; if (*type == '\0') type = NULL; }

                    if ( type != NULL ) {
                        if (strnEQ(type, "hash:", 5)) {
                            /* !perl/hash:Foo::Bar blesses into Foo::Bar */
                            type += 5;
                        }

                        /* FIXME deprecated - here compatibility with %Foo::Bar style blessing */
                        while ( *type == '%' ) { type++; }
                    }

                    if (load_blessed) {
						if (lang == NULL || (strEQ(lang, "perl"))) {
							/* !perl/hash on it's own causes no blessing */
							if ( (type != NULL) && strNE(type, "hash") && *type != '\0' ) {
								sv_bless(sv, gv_stashpv(type, TRUE));
							}
						} else {
							sv_bless(sv, gv_stashpv((type == NULL) ? lang : form("%s::%s", lang, type), TRUE));
						}
                    }
                    Safefree(id_copy);
                }
#endif
            }
        break;
    }

#ifndef YAML_IS_JSON
    /* Fix bad anchors using sv_setsv */
    if (n->id) {
        if (n->anchor)
            resolve_bad_alias(p, n->anchor, sv);

        sv_setsv( perl_syck_lookup_sym(p, n->id), sv );
    }
#endif

    TRACK_OBJECT(sv);

    return syck_add_sym(p, (char *)sv);
}

#ifdef YAML_IS_JSON
static char* perl_json_preprocess(char *s) {
    STRLEN i;
    char *out;
    char ch;
    char in_string = '\0';
    bool in_quote  = 0;
    char *pos;
    STRLEN len = strlen(s);

    New(2006, out, len*2+1, char);
    pos = out;

    for (i = 0; i < len; i++) {
        ch = *(s+i);
        *pos++ = ch;
        if (in_quote) {
            in_quote = !in_quote;
            if (ch == '\'' && json_quote_char == '\'') {
                /* JSON single-quote mode: \' is an escaped quote.
                 * Since we convert delimiters to " for YAML double-quote
                 * parsing, a literal ' needs no backslash inside "..." */
                pos -= 2;
                *pos++ = '\'';
            }
            else if (ch == '\'') {
                *(pos - 2) = '\'';
            }
        }
        else if (ch == '\\') {
            in_quote = 1;
        }
        else if (in_string == '\0') {
            switch (ch) {
                case ':':  { *pos++ = ' '; break; }
                case ',':  { *pos++ = ' '; break; }
                case '"':  { in_string = '"'; break; }
                case '\'': {
                    in_string = '\'';
                    if (json_quote_char == '\'') {
                        /* Convert ' delimiter to " so YAML double-quote
                         * parser handles escape sequences (\b, \n, etc.) */
                        *(pos - 1) = '"';
                    }
                    break;
                }
            }
        }
        else if (ch == in_string) {
            in_string = '\0';
            if (ch == '\'' && json_quote_char == '\'') {
                *(pos - 1) = '"';
            }
        }
        else if (ch == '"' && json_quote_char == '\'' && in_string == '\'') {
            /* Unescaped " inside a single-quoted JSON string needs escaping
             * because we converted the delimiters to " for YAML parsing */
            *(pos - 1) = '\\';
            *pos++ = '"';
        }
    }

    *pos = '\0';
    return out;
}

void perl_json_postprocess(SV *sv) {
    STRLEN i;
    char ch;
    bool in_string = 0;
    bool in_quote  = 0;
    char *pos;
    char *s = SvPVX(sv);
    STRLEN len = sv_len(sv);
    STRLEN final_len = len;

    pos = s;

    /* Horrible kluge if your quote char does not match what's wrapping this line */
    if ( (json_quote_char == '\'') && (len > 1) && (*s == '\"') && (*(s+len-2) == '\"') ) {
        *s = '\'';
        *(s+len-2) = '\'';
    }

    /* Strip spaces after ':' and ',' outside quoted strings to produce
     * compact JSON.  The C-level emitter outputs "key": "value", ... with
     * spaces; this in-place compaction removes them.  See t/json-postprocess.t.
     */
    for (i = 0; i < len; i++) {
        ch = *(s+i);
        *pos++ = ch;
        if (in_quote) {
            in_quote = !in_quote;
        }
        else if (ch == '\\') {
            in_quote = 1;
        }
        else if (ch == json_quote_char) {
            in_string = !in_string;
        }
        else if ((ch == ':' || ch == ',') && !in_string) {
            i++; /* has to be a space afterwards */
            final_len--;
        }
    }

    /* Remove the trailing newline */
    if (final_len > 0) {
        final_len--; pos--;
    }
    *pos = '\0';
    SvCUR_set(sv, final_len);
}
#endif

#ifdef YAML_IS_JSON
static SV * LoadJSON (char *s) {
#else
static SV * LoadYAML (char *s) {
#endif
    SYMID v;
    SyckParser *parser;
    struct parser_xtra bonus;

    SV *obj              = &PL_sv_undef;
    SV *use_code         = GvSV(gv_fetchpv(form("%s::UseCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *load_code        = GvSV(gv_fetchpv(form("%s::LoadCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *implicit_typing  = GvSV(gv_fetchpv(form("%s::ImplicitTyping", PACKAGE_NAME), TRUE, SVt_PV));
    SV *implicit_unicode = GvSV(gv_fetchpv(form("%s::ImplicitUnicode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *singlequote      = GvSV(gv_fetchpv(form("%s::SingleQuote", PACKAGE_NAME), TRUE, SVt_PV));
    SV *load_blessed     = GvSV(gv_fetchpv(form("%s::LoadBlessed", PACKAGE_NAME), TRUE, SVt_PV));
    json_quote_char      = (SvTRUE(singlequote) ? '\'' : '"' );

    ENTER; SAVETMPS;

    /* Don't even bother if the string is empty. */
    if (*s == '\0') { FREETMPS; LEAVE; return &PL_sv_undef; }

#ifdef YAML_IS_JSON
    s = perl_json_preprocess(s);
#else
    /* Special preprocessing to maintain compat with YAML.pm <= 0.35 */
    if (strnEQ( s, "--- #YAML:1.0", 13)) {
        s[4] = '%';
    }
#endif

    parser = syck_new_parser();
    syck_parser_str_auto(parser, s, NULL);
    syck_parser_handler(parser, PERL_SYCK_PARSER_HANDLER);
    syck_parser_error_handler(parser, perl_syck_error_handler);
    syck_parser_bad_anchor_handler( parser, perl_syck_bad_anchor_handler );
    syck_parser_implicit_typing(parser, SvTRUE(implicit_typing));
    syck_parser_taguri_expansion(parser, 0);

    bonus.objects          = (AV*)sv_2mortal((SV*)newAV());
    bonus.implicit_unicode = SvTRUE(implicit_unicode);
    bonus.load_code        = SvTRUE(use_code) || SvTRUE(load_code);
    bonus.load_blessed     = SvTRUE(load_blessed);
    parser->bonus          = &bonus;

#ifndef YAML_IS_JSON
    bonus.bad_anchors = (HV*)sv_2mortal((SV*)newHV());

    if (GIMME_V == G_ARRAY) {
        SYMID prev_v = 0;

        obj = (SV*)newAV();
        while ((v = syck_parse(parser)) && (v != prev_v)) {
            SV *cur = &PL_sv_undef;
            if (!syck_lookup_sym(parser, v, (char **)&cur)) {
                break;
            }

            av_push((AV*)obj, cur);
            USE_OBJECT(cur);

            prev_v = v;
        }
        obj = newRV_noinc(obj);
    }
    else
#endif
    {
        v = syck_parse(parser);
        if (syck_lookup_sym(parser, v, (char **)&obj)) {
            USE_OBJECT(obj);
        }
    }

    syck_free_parser(parser);

#ifdef YAML_IS_JSON
    Safefree(s);
#endif

    FREETMPS; LEAVE;

    return obj;
}

void
#ifdef YAML_IS_JSON
json_syck_mark_emitter
#else
yaml_syck_mark_emitter
#endif
(SyckEmitter *e, SV *sv) {
    e->depth++;

    if (syck_emitter_mark_node(e, (st_data_t)sv, PERL_SYCK_EMITTER_MARK_NODE_FLAGS) == 0) {
        e->depth--;
        return;
    }

    if (e->depth >= e->max_depth) {
#ifdef YAML_IS_JSON
        croak("Dumping circular structures is not supported with JSON::Syck, consider increasing $JSON::Syck::MaxDepth higher then %d.", e->max_depth);
#else
        croak("Structure is nested deeper than $YAML::Syck::MaxDepth (%d); increase $YAML::Syck::MaxDepth to dump deeper structures.", e->max_depth);
#endif
    }

    if (SvROK(sv)) {
        PERL_SYCK_MARK_EMITTER(e, SvRV(sv));
#ifdef YAML_IS_JSON
        st_insert(e->markers, (st_data_t)sv, 0);
#endif
        e->depth--;
        return;
    }

    switch (SvTYPE(sv)) {
        case SVt_PVAV: {
            I32 len, i;
            len = av_len((AV*)sv) + 1;
            for (i = 0; i < len; i++) {
                SV** sav = av_fetch((AV*)sv, i, 0);
                if (sav != NULL) {
                    PERL_SYCK_MARK_EMITTER( e, *sav );
                }
            }
            break;
        }
        case SVt_PVHV: {
            HE *he;
            hv_iterinit((HV*)sv);
#ifdef HV_ITERNEXT_WANTPLACEHOLDERS
            while ((he = hv_iternext_flags((HV*)sv, HV_ITERNEXT_WANTPLACEHOLDERS)) != NULL) {
#else
            while ((he = hv_iternext((HV*)sv)) != NULL) {
#endif
                SV *val = hv_iterval((HV*)sv, he);
                PERL_SYCK_MARK_EMITTER( e, val );
            }
            break;
        }
        default:
            break;
    }

#ifdef YAML_IS_JSON
    st_insert(e->markers, (st_data_t)sv, 0);
#endif
    --e->depth;
}


void
#ifdef YAML_IS_JSON
json_syck_emitter_handler
#else
yaml_syck_emitter_handler
#endif
(SyckEmitter *e, st_data_t data) {
    I32  len, i;
    SV*  sv                    = (SV*)data;
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    char* tag                  = bonus->tag;
    svtype ty                  = SvTYPE(sv);
#ifndef YAML_IS_JSON
    char dump_code             = bonus->dump_code;
    char implicit_binary       = bonus->implicit_binary;
    char* ref                  = NULL;
    char* ref_orig             = NULL;
#endif

#define OBJECT_TAG     "tag:!perl:"
    
    if (SvMAGICAL(sv)) {
        mg_get(sv);
    }

#ifndef YAML_IS_JSON

    /* Handle blessing into the right class */
    if (sv_isobject(sv)) {
        ref = savepv(sv_reftype(SvRV(sv), TRUE));
        ref_orig = ref;
        bonus->cur_ref = ref;  /* track for cleanup on croak */
        *tag = '\0';
        strcat(tag, OBJECT_TAG);

        switch (SvTYPE(SvRV(sv))) {
            case SVt_PVAV: { strcat(tag, "array:");  break; }
            case SVt_PVHV: { strcat(tag, "hash:");   break; }
            case SVt_PVCV: { strcat(tag, "code:");   break; }
            case SVt_PVGV: { strcat(tag, "glob:");   break; }
#if PERL_VERSION > 10
            case SVt_REGEXP: {
                if (strEQ(ref, "Regexp")) {
                    strcat(tag, "regexp");
                    ref += 6; /* empty string */
                } else {
                    strcat(tag, "regexp:");
                }
                break;
            }
#endif

            /* flatten scalar ref objects so that they dump as !perl/scalar:Foo::Bar foo */
            case SVt_PVMG: {
                if ( SvROK(SvRV(sv)) ) {
                    strcat(tag, "ref:");
                    break;
                }
#if PERL_VERSION > 10
                else {
                    strcat(tag, "scalar:");
                    sv = SvRV(sv);
                    ty = SvTYPE(sv);
                    break;
                }
#else
                else {
                    MAGIC *mg;
                    if ( (mg = mg_find(SvRV(sv), PERL_MAGIC_qr) ) ) {
                        if (strEQ(ref, "Regexp")) {
                            strcat(tag, "regexp");
                            ref += 6; /* empty string */
                        }
                        else {
                            strcat(tag, "regexp:");
                        }
                        sv = newSVpvn(SvPV_nolen(sv), sv_len(sv));
                        ty = SvTYPE(sv);
                    }
                    else {
                        strcat(tag, "scalar:");
                        sv = SvRV(sv);
                        ty = SvTYPE(sv);
                    }
                    break;
                }
#endif
            }
            default:
                break;
        }
        {
            /* Grow tag buffer if ref won't fit (prevents heap overflow) */
            STRLEN need = strlen(tag) + strlen(ref) + 1;
            if (need > bonus->tag_len) {
                Renew(bonus->tag, need, char);
                bonus->tag_len = need;
                tag = bonus->tag;
            }
        }
        strcat(tag, ref);
    }
#endif

    /*
     * For blessed scalar refs that were flattened (sv = SvRV(sv) in SVt_PVMG
     * above), the inner scalar may have an anchor from the marking pass.
     * Since we emit it via syck_emit_scalar() (not syck_emit()), we must
     * handle anchors/aliases manually here.
     */
#ifndef YAML_IS_JSON
    if (ref_orig != NULL && !SvROK(sv)) {
        st_data_t oid;
        char *anchor_name = NULL;
        if (e->anchors != NULL &&
            st_lookup(e->markers, (st_data_t)sv, &oid) &&
            st_lookup(e->anchors, (st_data_t)oid, (st_data_t *)&anchor_name))
        {
            if (e->anchored == NULL) {
                e->anchored = st_init_numtable();
            }
            if (!st_lookup(e->anchored, (st_data_t)anchor_name, 0)) {
                /* First occurrence: write &N before the tag+scalar */
                char *an = S_ALLOC_N(char, strlen(anchor_name) + 3);
                sprintf(an, "&%s ", anchor_name);
                syck_emitter_write(e, an, strlen(anchor_name) + 2);
                S_FREE(an);
                st_insert(e->anchored, (st_data_t)anchor_name, 0);
            }
            else {
                /* Already emitted: write *N alias and return */
                char *an = S_ALLOC_N(char, strlen(anchor_name) + 2);
                sprintf(an, "*%s", anchor_name);
                syck_emitter_write(e, an, strlen(anchor_name) + 1);
                S_FREE(an);
                Safefree(ref_orig);
                bonus->cur_ref = NULL;
                return;
            }
        }
    }
#endif

    if (SvROK(sv)) {
        /* emit a scalar ref */
#ifdef YAML_IS_JSON
        PERL_SYCK_EMITTER_HANDLER(e, (st_data_t)SvRV(sv));
#else
        switch (SvTYPE(SvRV(sv))) {
            case SVt_PVAV:
            case SVt_PVHV:
            case SVt_PVCV: {
                /* Arrays, hashes and code values are inlined, and will be wrapped by a ref in the undumping */
                e->indent = 0;
                syck_emit_item(e, (st_data_t)SvRV(sv));
                e->indent = PERL_SYCK_INDENT_LEVEL;
                break;
            }
#if PERL_VERSION > 10
            case SVt_REGEXP: {
                STRLEN len = sv_len(sv);
                syck_emit_scalar( e, OBJOF("tag:!perl:regexp"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), len );
                syck_emit_end(e);
                break;
            }
#endif
            default: {
                SV *ref_sv;
                syck_emit_map(e, OBJOF("tag:!perl:ref"), MAP_NONE);
                *tag = '\0';
                ref_sv = newSVpvn_share(REF_LITERAL, REF_LITERAL_LENGTH, 0);
                syck_emit_item( e, (st_data_t)ref_sv );
                SvREFCNT_dec(ref_sv);
                syck_emit_item( e, (st_data_t)SvRV(sv) );
                syck_emit_end(e);
            }
        }
#endif
    }
    else if (ty == SVt_NULL) {
        /* emit an undef */
        syck_emit_scalar(e, "str", scalar_plain, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
    }
    else if ((ty == SVt_PVMG) && !SvOK(sv)) {
        /* emit an undef (typically pointed from a blesed SvRV) */
        syck_emit_scalar(e, OBJOF("str"), scalar_plain, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
    }
    else if (SvPOK(sv) && ty != SVt_PVCV) {
        /* emit a string (exclude CVs: prototyped subs have SvPOK set for the
         * prototype string, but must go through the SVt_PVCV case below for
         * proper B::Deparse handling) */
        STRLEN len = sv_len(sv);

/* JSON should preserve quotes even on simple integers ("0" is true in javascript) */
#ifndef YAML_IS_JSON
        if (looks_like_number(sv)) {
        	if(syck_str_is_unquotable_integer(SvPV_nolen(sv), sv_len(sv))) {
        		/* emit an unquoted number only if it's a very basic integer. /^-?[1-9][0-9]*$/ */
        		syck_emit_scalar(e, OBJOF("str"), SCALAR_NUMBER, 0, 0, 0, SvPV_nolen(sv), len);
        	}
        	else {
        		/* Even though it looks like a number, quote it or it won't round trip correctly. */
        		syck_emit_scalar(e, OBJOF("str"), SCALAR_QUOTED, 0, 0, 0, SvPV_nolen(sv), len);
        	}
        }
        else
#endif
        	if (len == 0) {
            syck_emit_scalar(e, OBJOF("str"), SCALAR_QUOTED, 0, 0, 0, "", 0);
        }
        else if (IS_UTF8(sv)) {
            /* if we support UTF8 and the string contains UTF8 */
            enum scalar_style old_s = e->style;
            e->style = SCALAR_UTF8;
            syck_emit_scalar(e, OBJOF("str"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), len);
            e->style = old_s;
        }
#ifndef YAML_IS_JSON
        else if (implicit_binary) {
            /* scan string for high-bits in the SV */
            bool is_ascii = TRUE;
            char *str = SvPV_nolen(sv);
            STRLEN bin_len = sv_len(sv);
            STRLEN bi;

            for (bi = 0; bi < bin_len; bi++) {
                if (*(str + bi) & 0x80) {
                    /* Binary here */
                    char *base64 = syck_base64enc( str, bin_len );
                    syck_emit_scalar(e, "tag:yaml.org,2002:binary", SCALAR_STRING, 0, 0, 0, base64, strlen(base64));
                    is_ascii = FALSE;
                    break;
                }
            }

            if (is_ascii) {
                syck_emit_scalar(e, OBJOF("str"), SCALAR_STRING, 0, 0, 0, str, bin_len);
            }
        }
#endif
        else {
            syck_emit_scalar(e, OBJOF("str"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), len);
        }
    }
    else if (SvNIOK(sv)) {
    	/* Stringify the sv, being careful not to overwrite its PV part */
    	SV *sv2 = newSVsv(sv);
    	STRLEN len;
    	char *str = SvPV(sv2, len);
    	if (SvIOK(sv) /* original SV was an int */
    	    && syck_str_is_unquotable_integer(str, len)) /* small enough to safely round-trip */
    	{
    		syck_emit_scalar(e, OBJOF("str"), SCALAR_NUMBER, 0, 0, 0, str, len);
        } else {
    		/* We need to quote it */
    		syck_emit_scalar(e, OBJOF("str"), SCALAR_QUOTED, 0, 0, 0, str, len);
        }
        SvREFCNT_dec(sv2);
    }
    else {
        switch (ty) {
            case SVt_PVAV: { /* array */
                syck_emit_seq(e, OBJOF("array"), SEQ_NONE);
                e->indent = PERL_SYCK_INDENT_LEVEL;

                *tag = '\0';
                len = av_len((AV*)sv) + 1;
                for (i = 0; i < len; i++) {
                    SV** sav = av_fetch((AV*)sv, i, 0);
                    if (sav == NULL) {
                        syck_emit_item( e, (st_data_t)(&PL_sv_undef) );
                    }
                    else {
                        syck_emit_item( e, (st_data_t)(*sav) );
                    }
                }
                syck_emit_end(e);
                return;
            }
            case SVt_PVHV: { /* hash */
                HV *hv = (HV*)sv;
                HE *he;
                syck_emit_map(e, OBJOF("hash"), MAP_NONE);
                e->indent = PERL_SYCK_INDENT_LEVEL;

                *tag = '\0';
                hv_iterinit((HV*)sv);

                if (e->sort_keys) {
                    AV *av = (AV*)sv_2mortal((SV*)newAV());
#ifdef HV_ITERNEXT_WANTPLACEHOLDERS
                    while ((he = hv_iternext_flags(hv, HV_ITERNEXT_WANTPLACEHOLDERS)) != NULL) {
#else
                    while ((he = hv_iternext(hv)) != NULL) {
#endif
                        SV *key = hv_iterkeysv(he);
                        av_store(av, AvFILLp(av)+1, key); /* av_push(), really */
                    }
                    len = av_len(av) + 1;
                    STORE_HASH_SORT;
                    for (i = 0; i < len; i++) {
                        SV *key = av_shift(av);
                        HE *he  = hv_fetch_ent(hv, key, 0, 0);
                        SV *val = he ? HeVAL(he) : &PL_sv_undef;
                        if (val == NULL) { val = &PL_sv_undef; }
                        syck_emit_item( e, (st_data_t)key );
                        syck_emit_item( e, (st_data_t)val );
                    }
                }
                else {
#ifdef HV_ITERNEXT_WANTPLACEHOLDERS
                    while ((he = hv_iternext_flags(hv, HV_ITERNEXT_WANTPLACEHOLDERS)) != NULL) {
#else
                    while ((he = hv_iternext(hv)) != NULL) {
#endif
                        SV *key = hv_iterkeysv(he);
                        SV *val = hv_iterval(hv, he);
                        syck_emit_item( e, (st_data_t)key );
                        syck_emit_item( e, (st_data_t)val );
                    }
                }
                /* reset the hash pointer */
                hv_iterinit(hv);
                syck_emit_end(e);
                return;
            }
            case SVt_PVCV: { /* code */
#ifdef YAML_IS_JSON
                syck_emit_scalar(e, "str", scalar_plain, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
#else

                /* This following code is mostly copypasted from Storable */

#if PERL_VERSION < 8
		syck_emit_scalar(e, OBJOF("tag:!perl:code:"), SCALAR_QUOTED, 0, 0, 0, "{ \"DUMMY\" }", 11);
#else
                if ( !dump_code ) {
                    syck_emit_scalar(e, OBJOF("tag:!perl:code:"), SCALAR_QUOTED, 0, 0, 0, "{ \"DUMMY\" }", 11);
                }
                else {
                    dSP;
                    int count, reallen;
                    SV *text;
                    CV *cv = (CV*)sv;
                    SV *bdeparse = GvSV(gv_fetchpv(form("%s::DeparseObject", PACKAGE_NAME), TRUE, SVt_PV));

                    if (!SvTRUE(bdeparse)) {
                        croak("B::Deparse initialization failed -- cannot dump code object");
                    }

                    ENTER;
                    SAVETMPS;

                    /*
                     * call the coderef2text method
                     */

                    PUSHMARK(sp);
                    XPUSHs(bdeparse); /* XXX is this already mortal? */
                    XPUSHs(sv_2mortal(newRV_inc((SV*)cv)));
                    PUTBACK;
                    count = call_method("coderef2text", G_SCALAR);
                    SPAGAIN;
                    if (count != 1) {
                        croak("Unexpected return value from B::Deparse::coderef2text\n");
                    }

                    text = POPs;
                    reallen = strlen(SvPV_nolen(text));

                    /*
                     * Empty code references or XS functions are deparsed as
                     * "(prototype) ;" or ";".
                     */

                    if (reallen == 0 || *(SvPV_nolen(text)+reallen-1) == ';') {
                        croak("The result of B::Deparse::coderef2text was empty - maybe you're trying to serialize an XS function?\n");
                    }

                    /*
                     * Now store the source code.
                     */

                    syck_emit_scalar(e, OBJOF("tag:!perl:code:"), SCALAR_UTF8, 0, 0, 0, SvPV_nolen(text), reallen);

                    FREETMPS;
                    LEAVE;

                    /* END Storable */
                }
#endif
#endif
                *tag = '\0';
                break;
            }
            case SVt_PVGV:   /* glob (not a filehandle, a symbol table entry) */
            case SVt_PVFM: { /* format */
                /* XXX TODO XXX */
                syck_emit_scalar(e, OBJOF("str"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
                break;
            }
            case SVt_PVIO: { /* filehandle */
                syck_emit_scalar(e, OBJOF("str"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
                break;
            }
            default: {
                syck_emit_scalar(e, "str", scalar_plain, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
            }
        }
    }
/* cleanup: */
    *tag = '\0';
#ifndef YAML_IS_JSON
    if (ref_orig != NULL) {
        Safefree(ref_orig);
        bonus->cur_ref = NULL;  /* already freed — prevent double-free in destructor */
    }
#endif
}

/* Destructor for SAVEDESTRUCTOR_X: frees emitter and tag buffer on croak.
 * Registered after allocation so Perl's scope unwinding handles cleanup
 * even when a croak() longjmps past the normal return path.
 * Guarded because perl_syck.h is included twice (YAML and JSON modes). */
#ifndef CLEANUP_EMITTER_BONUS_DEFINED
#define CLEANUP_EMITTER_BONUS_DEFINED
static void
cleanup_emitter_bonus(pTHX_ void *p) {
    struct emitter_xtra *bonus = (struct emitter_xtra *)p;
    if (bonus->cur_ref != NULL) {
        Safefree(bonus->cur_ref);
        bonus->cur_ref = NULL;
    }
    if (bonus->emitter != NULL) {
        syck_free_emitter((SyckEmitter *)bonus->emitter);
        bonus->emitter = NULL;
    }
    if (bonus->tag != NULL) {
        Safefree(bonus->tag);
        bonus->tag = NULL;
    }
}
#endif

void
#ifdef YAML_IS_JSON
DumpJSONImpl
#else
DumpYAMLImpl
#endif
(SV *sv, struct emitter_xtra *bonus, SyckOutputHandler output_handler) {
    SyckEmitter *emitter;
    SV *headless         = GvSV(gv_fetchpv(form("%s::Headless", PACKAGE_NAME), TRUE, SVt_PV));
    SV *implicit_binary  = GvSV(gv_fetchpv(form("%s::ImplicitBinary", PACKAGE_NAME), TRUE, SVt_PV));
    SV *use_code         = GvSV(gv_fetchpv(form("%s::UseCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *dump_code        = GvSV(gv_fetchpv(form("%s::DumpCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *sortkeys         = GvSV(gv_fetchpv(form("%s::SortKeys", PACKAGE_NAME), TRUE, SVt_PV));
    SV *max_depth        = GvSV(gv_fetchpv(form("%s::MaxDepth", PACKAGE_NAME), TRUE, SVt_PV));
#ifdef YAML_IS_JSON
    SV *singlequote      = GvSV(gv_fetchpv(form("%s::SingleQuote", PACKAGE_NAME), TRUE, SVt_PV));
    json_quote_char      = (SvTRUE(singlequote) ? '\'' : '"' );
    json_quote_style     = (SvTRUE(singlequote) ? scalar_2quote_1 : scalar_2quote );
#else
    SV *singlequote      = GvSV(gv_fetchpv(form("%s::SingleQuote", PACKAGE_NAME), TRUE, SVt_PV));
    yaml_quote_style     = (SvTRUE(singlequote) ? scalar_1quote : scalar_none);
#endif

    ENTER; SAVETMPS;

    /* Initialize B::Deparse BEFORE allocating the emitter, so that if
     * eval_pv croaks (longjmp) we don't leak the SyckEmitter. */
#ifndef YAML_IS_JSON
    if (SvTRUE(use_code) || SvTRUE(dump_code)) {
        SV *bdeparse = GvSV(gv_fetchpv(form("%s::DeparseObject", PACKAGE_NAME), TRUE, SVt_PV));

        if (!SvTRUE(bdeparse)) {
            eval_pv(form(
                "local $@; require B::Deparse; $%s::DeparseObject = B::Deparse->new",
                PACKAGE_NAME
            ), 1);
        }
    }
#endif

    emitter = syck_new_emitter();

    if (SvIOK(max_depth))
        emitter->max_depth = SvIV(max_depth);
#ifdef YAML_IS_JSON
    else
        emitter->max_depth = json_max_depth;
    emitter->indent      = PERL_SYCK_INDENT_LEVEL;
    emitter->json_mode   = 1;
#endif

    emitter->headless = SvTRUE(headless);
    emitter->sort_keys = SvTRUE(sortkeys);
    emitter->anchor_format = "%d";

    New(801, bonus->tag, 512, char);
    bonus->tag_len = 512;
    *(bonus->tag) = '\0';
    bonus->dump_code = SvTRUE(use_code) || SvTRUE(dump_code);
    bonus->implicit_binary = SvTRUE(implicit_binary);
    bonus->emitter = emitter;
    bonus->cur_ref = NULL;
    emitter->bonus = bonus;

    /* Register destructor so croak() in callbacks (mark_emitter,
     * emitter_handler) won't leak the emitter or tag buffer. */
    SAVEDESTRUCTOR_X(cleanup_emitter_bonus, bonus);

    syck_emitter_handler( emitter, PERL_SYCK_EMITTER_HANDLER );
    syck_output_handler( emitter, output_handler );

    PERL_SYCK_MARK_EMITTER( emitter, sv );

#ifdef YAML_IS_JSON
    st_free_table(emitter->markers);
    emitter->markers = st_init_numtable();
#endif

    syck_emit( emitter, (st_data_t)sv );
    syck_emitter_flush( emitter, 0 );

    /* Normal path: clean up now and NULL the pointers so the
     * SAVEDESTRUCTOR_X callback (at LEAVE) becomes a no-op. */
    syck_free_emitter( emitter );
    bonus->emitter = NULL;
    Safefree(bonus->tag);
    bonus->tag = NULL;

    FREETMPS; LEAVE;

    return;
}


SV*
#ifdef YAML_IS_JSON
DumpJSON
#else
DumpYAML
#endif
(SV *sv) {
    SV *implicit_unicode = GvSV(gv_fetchpv(form("%s::ImplicitUnicode", PACKAGE_NAME), TRUE, SVt_PV));
    struct emitter_xtra bonus;
    /* Mortalize so croak inside DumpImpl won't leak the SV.
     * SvREFCNT_inc before return counteracts the XS wrapper's sv_2mortal. */
    SV *out = sv_2mortal(newSVpvn("", 0));
    bonus.out.outsv = out;
#ifdef YAML_IS_JSON
    DumpJSONImpl(sv, &bonus, perl_syck_output_handler_pv);
    if (SvCUR(out) > 0) {
        perl_json_postprocess(out);
    }
#else
    DumpYAMLImpl(sv, &bonus, perl_syck_output_handler_pv);
#endif
#ifdef SvUTF8_on
    if (SvTRUE(implicit_unicode)) {
        SvUTF8_on(out);
    }
#endif
    SvREFCNT_inc_simple_void(out);
    return out;
}

int
#ifdef YAML_IS_JSON
DumpJSONFile
#else
DumpYAMLFile
#endif
(SV *sv, PerlIO *out) {
    struct emitter_xtra bonus;
    bonus.out.outio = out;
    bonus.ioerror = 0;
#ifdef YAML_IS_JSON
    {
        /* Buffer into an SV so we can apply perl_json_postprocess(),
         * then write the postprocessed result to the file handle.
         * Mortalize buf so croak inside DumpJSONImpl won't leak it. */
        SV *buf = sv_2mortal(newSVpvn("", 0));
        STRLEN len;
        char *s;
        bonus.out.outsv = buf;
        DumpJSONImpl(sv, &bonus, perl_syck_output_handler_pv);
        if (SvCUR(buf) > 0) {
            perl_json_postprocess(buf);
        }
        s = SvPV(buf, len);
        if (len > 0) {
            if (PerlIO_write(out, s, len) != (SSize_t)len) {
                bonus.ioerror = errno;
            }
        }
    }
#else
    DumpYAMLImpl(sv, &bonus, perl_syck_output_handler_io);
#endif
    return bonus.ioerror;
}

int
#ifdef YAML_IS_JSON
DumpJSONInto
#else
DumpYAMLInto
#endif
(SV *sv, SV *out) {
    SV *implicit_unicode = GvSV(gv_fetchpv(form("%s::ImplicitUnicode", PACKAGE_NAME), TRUE, SVt_PV));
    struct emitter_xtra bonus;
    if (SvROK(out)) {
        out = SvRV(out);
        if (! SvPOK(out)) {
            sv_setpv(out, "");
        }
    } else {
        return 0; /* perl wrapper should die for us */
    }
    bonus.out.outsv = out;
#ifdef YAML_IS_JSON
    DumpJSONImpl(sv, &bonus, perl_syck_output_handler_mg);
    if (SvCUR(out) > 0) { /* XXX: needs to handle magic? */
        perl_json_postprocess(out);
    }
#else
    DumpYAMLImpl(sv, &bonus, perl_syck_output_handler_mg);
#endif
#ifdef SvUTF8_on
    if (SvTRUE(implicit_unicode)) {
        SvUTF8_on(out); /* XXX: needs to handle magic? */
    }
#endif
    return 1;
}

