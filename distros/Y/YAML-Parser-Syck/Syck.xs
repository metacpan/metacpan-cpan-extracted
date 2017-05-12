#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* #include "ppport.h" */
#include <syck.h>

SYMID perl_syck_handler(SyckParser *p, SyckNode *n) {
    SYMID obj;
    SV *sv, *scalar, *entry, *key, *value;
    AV *seq;
    HV *map;
    long i;

    switch (n->kind) {
        case syck_str_kind:
            sv = newSVpv(n->data.str->ptr, n->data.str->len);
        break;

        case syck_seq_kind:
            seq = newAV();
            for (i = 0; i < n->data.list->idx; i++) {
                obj = syck_seq_read(n, i);
                syck_lookup_sym(p, obj, (char**)&entry);
                av_push(seq, entry);
            }
            sv = newRV_inc((SV*)seq);
        break;

        case syck_map_kind:
            map = newHV();
            for (i = 0; i < n->data.pairs->idx; i++) {
                obj = syck_map_read( n, map_key, i);
                syck_lookup_sym(p, obj, (char**)&key);
                obj = syck_map_read(n, map_value, i);
                syck_lookup_sym(p, obj, (char**)&value);
                hv_store_ent(map, key, value, 0);
            }
            sv = newRV_inc((SV*)map);
        break;
    }
    obj = syck_add_sym(p, (char *)sv);
    return obj;
}

static SV * Parse(char *s) {
    SV *obj;
    SYMID v;
    SyckParser *parser = syck_new_parser();
    syck_parser_str_auto(parser, s, NULL);
    syck_parser_handler(parser, perl_syck_handler);
    syck_parser_error_handler(parser, NULL);
    syck_parser_implicit_typing(parser, 1);
    syck_parser_taguri_expansion(parser, 0);
    v = syck_parse(parser);
    syck_lookup_sym(parser, v, (char **)&obj);
    syck_free_parser(parser);
    return obj;
}

MODULE = YAML::Parser::Syck		PACKAGE = YAML::Parser::Syck		

PROTOTYPES: DISABLE

SV *
Parse (s)
	char *	s
