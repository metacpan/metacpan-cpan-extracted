#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"
#include <yaml.h>

#define SCALAR_STYLE_PLAIN ":"
#define SCALAR_STYLE_DOUBLEQUOTED "\""
#define SCALAR_STYLE_SINGLEQUOTED "'"
#define SCALAR_STYLE_LITERAL "|"
#define SCALAR_STYLE_FOLDED ">"

char *
parser_error_msg(yaml_parser_t *parser, char *problem)
{
    char *msg;
    if (!problem)
        problem = (char *)parser->problem;
    msg = form(
        "YAML::PP::LibYAML Error: %swas found at ",
        (problem ? form("The problem:\n\n    %s\n\n", problem) : "A problem ")
    );
    if (
        parser->problem_mark.line ||
        parser->problem_mark.column
    )
        msg = form("%s, line: %lu, column: %lu\n",
            msg,
            (unsigned long)parser->problem_mark.line + 1,
            (unsigned long)parser->problem_mark.column + 1
        );
    else
        msg = form("%s\n", msg);
    if (parser->context)
        msg = form("%s%s at line: %lu, column: %lu\n",
            msg,
            parser->context,
            (unsigned long)parser->context_mark.line + 1,
            (unsigned long)parser->context_mark.column + 1
        );

    return msg;
}

HV *
libyaml_to_perl_event(yaml_event_t *event)
{
    dTHX;
    HV *perl_event;
    HV *perl_version_directive;
    AV *perl_tag_directives;
    HV *perl_tag_directive;
    HV *perl_start_mark;
    HV *perl_end_mark;
    yaml_event_type_t type;
    char *perl_event_anchor;
    char *perl_event_tag;
    char *perl_event_type;
    yaml_mark_t start_mark;
    yaml_mark_t end_mark;
    SV *hash_ref_start;
    SV *hash_ref_end;
    SV *scalar_value;
    yaml_tag_directive_t *tag_directive;

    perl_event = newHV();
    type = event->type;

    perl_event_anchor = NULL;
    perl_event_tag = NULL;
    if (type == YAML_NO_EVENT)
        croak("%s", "Unexpected event YAML_NO_EVENT");
    else if (type == YAML_STREAM_START_EVENT)
        perl_event_type = "stream_start_event";
    else if (type == YAML_STREAM_END_EVENT)
        perl_event_type = "stream_end_event";
    else if (type == YAML_DOCUMENT_START_EVENT) {
        perl_event_type = "document_start_event";
        if (event->data.document_start.implicit)
            hv_store(
                perl_event, "implicit", 8,
                newSViv( 1 ), 0
            );
        if (event->data.document_start.version_directive) {
            perl_version_directive = newHV();
            hv_store(
                perl_version_directive, "major", 5,
                newSViv( event->data.document_start.version_directive->major ), 0
            );
            hv_store(
                perl_version_directive, "minor", 5,
                newSViv( event->data.document_start.version_directive->minor ), 0
            );
            hv_store(
                perl_event, "version_directive", 17,
                newRV_noinc((SV *)perl_version_directive), 0
            );
        }
        if (event->data.document_start.tag_directives.start) {
            perl_tag_directives = newAV();
            for (tag_directive = event->data.document_start.tag_directives.start;
                    tag_directive != event->data.document_start.tag_directives.end;
                    tag_directive ++) {
                perl_tag_directive = newHV();

                hv_store(
                    perl_tag_directive, "handle", 6,
                    newSVpv( (char *)tag_directive->handle, strlen((char *)tag_directive->handle)), 0
                );
                hv_store(
                    perl_tag_directive, "prefix", 6,
                    newSVpv( (char *)tag_directive->prefix, strlen((char *)tag_directive->prefix)), 0
                );
                av_push(perl_tag_directives, newRV_noinc((SV *)perl_tag_directive));
            }
            hv_store(
                perl_event, "tag_directives", 14,
                newRV_noinc((SV *)perl_tag_directives), 0
            );
        }
    }
    else if (type == YAML_DOCUMENT_END_EVENT) {
        perl_event_type = "document_end_event";
        if (event->data.document_end.implicit)
            hv_store(
                perl_event, "implicit", 8,
                newSViv( 1 ), 0
            );
    }
    else if (type == YAML_MAPPING_START_EVENT) {
        perl_event_type = "mapping_start_event";
        if (event->data.mapping_start.anchor)
            perl_event_anchor = event->data.mapping_start.anchor;
        if (event->data.mapping_start.tag)
            perl_event_tag = event->data.mapping_start.tag;
        hv_store(
            perl_event, "style", 5,
            newSViv( event->data.mapping_start.style ), 0
        );
    }
    else if (type == YAML_MAPPING_END_EVENT)
        perl_event_type = "mapping_end_event";
    else if (type == YAML_SEQUENCE_START_EVENT) {
        perl_event_type = "sequence_start_event";
        if (event->data.sequence_start.anchor)
            perl_event_anchor = event->data.sequence_start.anchor;
        if (event->data.sequence_start.tag)
            perl_event_tag = event->data.sequence_start.tag;
        hv_store(
            perl_event, "style", 5,
            newSViv( event->data.sequence_start.style ), 0
        );
    }
    else if (type == YAML_SEQUENCE_END_EVENT)
        perl_event_type = "sequence_end_event";
    else if (type == YAML_SCALAR_EVENT) {
        perl_event_type = "scalar_event";
        if (event->data.scalar.anchor)
            perl_event_anchor = event->data.scalar.anchor;
        if (event->data.scalar.tag)
            perl_event_tag = event->data.scalar.tag;

        switch (event->data.scalar.style) {
        case YAML_ANY_SCALAR_STYLE:
            abort();
        }
        hv_store(
            perl_event, "style", 5,
            newSViv( event->data.scalar.style ),
            0
        );
        scalar_value = newSVpv( event->data.scalar.value, event->data.scalar.length );
        (void)sv_utf8_decode(scalar_value);
        hv_store( perl_event, "value", 5, scalar_value, 0 );
    }
    else if (type == YAML_ALIAS_EVENT) {
        perl_event_type = "alias_event";
        hv_store(
            perl_event, "value", 5,
            newSVpv( event->data.alias.anchor, strlen(event->data.alias.anchor) ),
            0
        );
    }
    else
        abort();

    hv_store(
        perl_event, "name", 4,
        newSVpv( perl_event_type, strlen(perl_event_type) ),
        0
    );

    if (perl_event_anchor) {
        hv_store(
            perl_event, "anchor", 6,
            newSVpv( perl_event_anchor, strlen(perl_event_anchor) ),
            0
        );
    }
    if (perl_event_tag) {
        hv_store(
            perl_event, "tag", 3,
            newSVpv( perl_event_tag, strlen(perl_event_tag) ),
            0
        );
    }

    start_mark = event->start_mark;
    end_mark = event->end_mark;
    perl_start_mark = newHV();
    perl_end_mark = newHV();

    hv_store( perl_start_mark, "line", 4, newSViv( start_mark.line ), 0 );
    hv_store( perl_start_mark, "column", 6, newSViv( start_mark.column ), 0 );

    hash_ref_start = newRV_noinc((SV *)perl_start_mark);
    hv_store( perl_event, "start", 5, hash_ref_start, 0 );


    hv_store( perl_end_mark, "line", 4, newSViv( end_mark.line ), 0 );
    hv_store( perl_end_mark, "column", 6, newSViv( end_mark.column ), 0 );

    hash_ref_end = newRV_noinc((SV *)perl_end_mark);
    hv_store( perl_event, "end", 3, hash_ref_end, 0 );

    return perl_event;
}

int
parse_events(yaml_parser_t *parser, AV *perl_events)
{

    dTHX;
    dXCPT;
    yaml_event_t event;
    HV *perl_event;
    yaml_event_type_t type;

    XCPT_TRY_START
    {

        while (1) {
            if (!yaml_parser_parse(parser, &event)) {
                croak("%s", parser_error_msg(parser, NULL));
            }
            type = event.type;

            perl_event = libyaml_to_perl_event(&event);

            av_push(perl_events, newRV_noinc( (SV *)perl_event));

            yaml_event_delete(&event);

            if (type == YAML_STREAM_END_EVENT)
                break;
        }

    } XCPT_TRY_END

    XCPT_CATCH
    {
        yaml_parser_delete(parser);
        yaml_event_delete(&event);
        XCPT_RETHROW;
    }
    return 1;
}

int
perl_to_libyaml_event(yaml_emitter_t *emitter, HV *perl_event)
{
    dTHX;
    dXCPT;
    yaml_event_t event;
    HV *perl_version_directive;
    SV **event_hashref;
    int ok;
    SV *perl_type;
    char *type;
    SV **val;
    int plain_implicit, quoted_implicit;
    STRLEN len;
    char *scalar_value;
    char *anchor_name;
    char *tag_name;
    yaml_scalar_style_t style = YAML_ANY_SCALAR_STYLE;
    int major = 0;
    int minor = 0;
    int implicit;
    yaml_version_directive_t *version_directive;

    implicit = 0;
    plain_implicit = quoted_implicit = 1;
    style = YAML_ANY_SCALAR_STYLE;
    tag_name = NULL;
    anchor_name = NULL;

    XCPT_TRY_START
    {

        val = hv_fetch(perl_event, "name", 4, TRUE);
        if (val && SvOK(*val) && SvPOK( *val )) {
            type = SvPV(*val, len);
        }
        else {
            croak("%s\n", "event name not defined");
        }

        val = hv_fetch(perl_event, "anchor", 6, TRUE);
        if (val && SvOK(*val) && (SvPOK( *val ) || SvIOK( *val ))) {
            anchor_name = SvPV(*val, len);
        }

        val = hv_fetch(perl_event, "tag", 3, TRUE);
        if (val && SvOK(*val) && SvPOK( *val )) {
            tag_name = SvPV(*val, len);
            plain_implicit = quoted_implicit = 0;
        }

        val = hv_fetch(perl_event, "style", 5, TRUE);
        if (val && SvOK(*val) && SvIOK( *val )) {
            style = SvIV(*val);
        }

        if (strEQ(type, "stream_start_event")) {
            ok = yaml_stream_start_event_initialize(&event, YAML_UTF8_ENCODING);
        }
        else if (strEQ(type, "stream_end_event")) {
            ok = yaml_stream_end_event_initialize(&event);
        }
        else if (strEQ(type, "document_start_event")) {
            version_directive = NULL;
            val = hv_fetch(perl_event, "version_directive", 17, TRUE);
            if (val && SvOK(*val) && SvROK( *val )) {
                perl_version_directive = (HV *)SvRV(*val);

                val = hv_fetch(perl_version_directive, "major", 5, TRUE);
                if (val && SvOK(*val) && (SvIOK( *val ) || SvPOK( *val )) ) {
                    major = SvIV(*val);
                }
                val = hv_fetch(perl_version_directive, "minor", 5, TRUE);
                if (val && SvOK(*val) && (SvIOK( *val ) || SvPOK( *val )) ) {
                    minor = SvIV(*val);
                }
                if (major && minor) {
                    version_directive = Perl_malloc(sizeof(yaml_version_directive_t));
                    version_directive->major = major;
                    version_directive->minor = minor;
                }
            }

            val = hv_fetch(perl_event, "implicit", 8, TRUE);
            if (val && SvOK(*val) && SvIOK( *val )) {
                implicit = SvIV(*val);
            }
            ok = yaml_document_start_event_initialize(&event, version_directive, NULL, NULL, implicit);
        }
        else if (strEQ(type, "document_end_event")) {
            val = hv_fetch(perl_event, "implicit", 8, TRUE);
            if (val && SvOK(*val) && SvIOK( *val )) {
                implicit = SvIV(*val);
            }
            ok = yaml_document_end_event_initialize(&event, implicit);
        }
        else if (strEQ(type, "mapping_start_event")) {
            ok = yaml_mapping_start_event_initialize(
                &event, anchor_name, tag_name, 0, style);
        }
        else if (strEQ(type, "mapping_end_event")) {
            ok = yaml_mapping_end_event_initialize(&event);
        }
        else if (strEQ(type, "sequence_start_event")) {
            ok = yaml_sequence_start_event_initialize(
                &event, anchor_name, tag_name, 0, style);
        }
        else if (strEQ(type, "sequence_end_event")) {
            ok = yaml_sequence_end_event_initialize(&event);
        }
        else if (strEQ(type, "scalar_event")) {
            val = hv_fetch(perl_event, "value", 5, TRUE);
            if (val && SvOK(*val) && SvPOK( *val )) {
                scalar_value = SvPVutf8(*val, len);
            }
            else {
                croak("%s\n", "scalar value not defined");
            }
            ok = yaml_scalar_event_initialize(
                &event, anchor_name, tag_name,
                (unsigned char *) scalar_value, strlen(scalar_value), plain_implicit, quoted_implicit, style);
        }
        else if (strEQ(type, "alias_event")) {
            val = hv_fetch(perl_event, "value", 5, TRUE);
            if (val && SvOK(*val) && (SvPOK( *val ) || SvIOK( *val ))) {
                scalar_value = SvPV(*val, len);
            }
            else {
                croak("%s\n", "alias name not defined");
            }
            ok = yaml_alias_event_initialize(&event, scalar_value);
        }

        if (!ok)
            croak("%s at %s: %s\n", "ERROR creating event", type, emitter->problem);
        if (!yaml_emitter_emit(emitter, &event))
            croak("%s at %s: %s\n", "ERROR", type, emitter->problem);

    } XCPT_TRY_END

    XCPT_CATCH
    {
        yaml_emitter_delete(emitter);
        yaml_event_delete(&event);
        XCPT_RETHROW;
    }

    return 1;

}

int
emit_events(yaml_emitter_t *emitter, AV *perl_events)
{

    dTHX;
    dXCPT;
    HV *perl_event;
    SV **event_hashref;
    int i;

    XCPT_TRY_START
    {

        for (i = 0; i <= av_len(perl_events); i++) {
            event_hashref = av_fetch(perl_events, i, 0);
            perl_event = (HV *)SvRV(*event_hashref);

            perl_to_libyaml_event(emitter, perl_event);
        }

        yaml_emitter_delete(emitter);
    } XCPT_TRY_END

    XCPT_CATCH
    {
        yaml_emitter_delete(emitter);
        XCPT_RETHROW;
    }
    return 1;
}

int
append_output(void *yaml, unsigned char *buffer, size_t size)
{
    dTHX;
    sv_catpvn((SV *)yaml, (const char *)buffer, (STRLEN)size);
    return 1;
}
