#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"
#include "ppport.h"
#include <yaml.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "etc/perl_libyaml.c"

/* C functions */

MODULE = YAML::LibYAML::API::XS      PACKAGE = YAML::LibYAML::API::XS


# XS code

SV *
parse_events(const char *input, AV *perl_events)
    CODE:
    {
        dXCPT;

        yaml_parser_t parser;
        yaml_event_t event;
        yaml_event_type_t type;
        HV *perl_event;
        SV* event_hashref;

        XCPT_TRY_START
        {
            if (!yaml_parser_initialize(&parser)) {
                croak("%s\n", "Could not initialize the parser object");
            }
            yaml_parser_set_input_string(&parser, input, strlen(input));


            while (1) {
                if (!yaml_parser_parse(&parser, &event)) {
                    croak("%s", parser_error_msg(&parser, NULL));
                }

                perl_event = libyaml_to_perl_event(&event);
                type = event.type;

                event_hashref = newRV_noinc( (SV *)perl_event );
                av_push(perl_events, event_hashref);

                yaml_event_delete(&event);

                if (type == YAML_STREAM_END_EVENT)
                    break;
            }

            yaml_parser_delete(&parser);

        } XCPT_TRY_END

        XCPT_CATCH
        {
            yaml_parser_delete(&parser);
            yaml_event_delete(&event);
            XCPT_RETHROW;
        }

    }
    OUTPUT: RETVAL

SV *
libyaml_version()
    CODE:
    {
        const char *v = yaml_get_version_string();
        SV* version = newSVpv(v, strlen(v));
        RETVAL = version;

    }
    OUTPUT: RETVAL
