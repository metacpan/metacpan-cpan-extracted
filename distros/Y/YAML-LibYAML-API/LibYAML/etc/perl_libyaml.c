#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <yaml.h>

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
    HV *perl_event;
    HV *perl_start_mark;
    HV *perl_end_mark;
    yaml_event_type_t type;
    char *perl_event_anchor;
    char *perl_event_tag;
    char *perl_event_type;
    char *scalar_style;
    yaml_mark_t start_mark;
    yaml_mark_t end_mark;
    SV *hash_ref_start;
    SV *hash_ref_end;

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
            }
            else if (type == YAML_MAPPING_END_EVENT)
                perl_event_type = "mapping_end_event";
            else if (type == YAML_SEQUENCE_START_EVENT) {
                perl_event_type = "sequence_start_event";
                if (event->data.sequence_start.anchor)
                    perl_event_anchor = event->data.sequence_start.anchor;
                if (event->data.sequence_start.tag)
                    perl_event_tag = event->data.sequence_start.tag;
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
                case YAML_PLAIN_SCALAR_STYLE:
                    scalar_style = ":";
                    break;
                case YAML_SINGLE_QUOTED_SCALAR_STYLE:
                    scalar_style = "'";
                    break;
                case YAML_DOUBLE_QUOTED_SCALAR_STYLE:
                    scalar_style = "\"";
                    break;
                case YAML_LITERAL_SCALAR_STYLE:
                    scalar_style = "|";
                    break;
                case YAML_FOLDED_SCALAR_STYLE:
                    scalar_style = ">";
                    break;
                case YAML_ANY_SCALAR_STYLE:
                    abort();
                }
                hv_store(
                    perl_event, "style", 5,
                    newSVpv( scalar_style, strlen(scalar_style) ),
                    0
                );
                hv_store(
                    perl_event, "value", 5,
                    newSVpv( event->data.scalar.value, event->data.scalar.length ),
                    0
                );
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
