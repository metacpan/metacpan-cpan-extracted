#ifndef  __DEFAULT_TAGS_H
#define  __DEFAULT_TAGS_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

void simple_tag_echo(context_p ctx, char **output, int argc, char **argv);
void simple_tag_include(context_p ctx, char **output, int argc, char **argv);

void tag_pair_debug(context_p ctx, int argc, char **argv);
void tag_pair_comment(context_p ctx, int argc, char **argv);
void tag_pair_loop(context_p ctx, int argc, char **argv);
void tag_pair_if(context_p ctx, int argc, char **argv);
void tag_pair_ifn(context_p ctx, int argc, char **argv);

char string_truth(char *input);
void dump_context(context_p ctx, context_p dump_ctx, int number);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __DEFAULT_TAGS_H */
