/* #define YAML_IS_JSON 1 */
#include "perl_common.h"

#define YAML_IS_JSON 1
#include "perl_syck.h"

#undef YAML_IS_JSON
#include "perl_syck.h"

typedef PerlIO * OutputStream;

MODULE = YAML::Syck		PACKAGE = YAML::Syck		

PROTOTYPES: DISABLE

SV *
LoadYAML (s)
	char *	s

SV *
DumpYAML (sv)
	SV *	sv

int
DumpYAMLInto (in, out)
        SV *    in
        SV *    out

int
DumpYAMLFile (in, out)
        SV *    in
        OutputStream out


SV *
LoadJSON (s)
	char *	s

SV *
DumpJSON (sv)
	SV *	sv

int
DumpJSONInto (in, out)
        SV *    in
        SV *    out

int
DumpJSONFile (in, out)
        SV *    in
        OutputStream out

