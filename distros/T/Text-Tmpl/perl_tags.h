#include <context.h>

#ifndef __PERL_TAGS_H
#define __PERL_TAGS_H

#define TEMPLATE_PACKAGE          "Text::Tmpl"
#define PERL_TAGS_SIMPLE_TAG_HASH "Text::Tmpl::simple_tags"
#define PERL_TAGS_TAG_PAIR_HASH   "Text::Tmpl::tag_pairs"

void perl_simple_tag(context_p ctx, char **output, int argc, char **argv);
void perl_tag_pair(context_p ctx, int argc, char **argv);

#endif /* __PERL_TAGS_H */
